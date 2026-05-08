-- ==========================================================
-- * 安裝擴充功能 (Extensions)
-- ==========================================================

-- 追蹤所有 SQL 的執行統計 (次數、耗時、I/O)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 強化約束能力，支援複合索引與排除約束
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 虛擬索引工具：在不實際建立索引(不鎖表/不耗空間)的情況下測試優化效果
CREATE EXTENSION IF NOT EXISTS hypopg;

-- 針對 32 核高併發環境，採樣並診斷「鎖等待 (Wait Events)」的來源
CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;

\echo '--- [FINISH] 安裝擴充功能 ---'

-- ==========================================================
-- * 建立 Schema Mode
-- ==========================================================

-- 建立 Schema Mode：oltp 用於交易系統
CREATE SCHEMA IF NOT EXISTS oltp;

-- 建立 Schema Mode：olap 用於分析系統
CREATE SCHEMA IF NOT EXISTS olap;

\echo '--- [FINISH] 建立 Schema Mode ---'

-- ==========================================================
-- * 建立帳號
-- ==========================================================
DO $$
BEGIN
    -- 監控專用帳號： postgres_exporter ( Grafana/Prometheus )
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'postgres_exporter') THEN
        CREATE USER postgres_exporter WITH PASSWORD 'exporter';
    END IF;

    -- oltp_owner: 擁有者權限 + 不允許登入
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'oltp_owner') THEN
        CREATE ROLE oltp_owner NOLOGIN;
    END IF;

    -- oltp_user: 讀/寫權限
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'oltp_user') THEN
        CREATE ROLE oltp_user LOGIN PASSWORD 'oltp_pwd';
    END IF;

    -- olap_owner: 擁有者權限 + 不允許登入
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'olap_owner') THEN
        CREATE ROLE olap_owner NOLOGIN;
    END IF;

    -- olap_user: 只讀權限
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'olap_user') THEN
        CREATE ROLE olap_user LOGIN PASSWORD 'olap_pwd';
    END IF;

    -- migration_user: 允許使用 owner 權限
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'migration_user') THEN
        CREATE ROLE migration_user LOGIN PASSWORD 'migration_pwd';
    END IF;
END
$$;

\echo '--- [FINISH] 建立帳號 ---'

-- ==========================================================
-- * 設定 Schema 權限
-- ==========================================================
-- * 授予 pg_monitor 核心權限：使其能讀取 pg_stat_statements 與系統活動狀態，而不需超級用戶權限
GRANT pg_monitor TO postgres_exporter;

\echo '--- [FINISH] 授予 pg_monitor TO postgres_exporter 核心權限 ---'


-- * 針對 oltp Schema 的權限設定：
-- 1. 確保 oltp_owner 為 oltp schema 擁有者
ALTER SCHEMA oltp OWNER TO oltp_owner;

-- 2. 確保 oltp_user 只能在 oltp schema 讀/寫資料，但不能改結構
GRANT USAGE ON SCHEMA oltp TO oltp_user;
-- 針對表格
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA oltp TO oltp_user;
-- 針對序號
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA oltp TO oltp_user;

-- 3. 設定未來新建表格的預設權限
-- 針對表格： 確保以後新創的表, oltp_user 都能讀寫
ALTER DEFAULT PRIVILEGES FOR ROLE oltp_owner IN SCHEMA oltp
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO oltp_user;
-- 針對序號： 確保以後新創的自增 ID, oltp_user 都能使用
ALTER DEFAULT PRIVILEGES FOR ROLE oltp_owner IN SCHEMA oltp
GRANT USAGE, SELECT ON SEQUENCES TO oltp_user;

\echo '--- [FINISH] 授予 OLTP Role 權限 ---'


-- * 針對 olap Schema 的權限設定：
-- 1. 確保 olap_owner 為 olap schema 擁有者
ALTER SCHEMA olap OWNER TO olap_owner;

-- 2. 確保 olap_user 只能在 olap schema 讀/寫資料，但不能改結構
GRANT USAGE ON SCHEMA olap TO olap_user;
-- 針對表格
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA olap TO olap_user;
-- 針對序號
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA olap TO olap_user;

-- 3. 設定未來新建物件的預設權限
-- 針對表格： 確保以後新創的表, olap_user 都能讀寫
ALTER DEFAULT PRIVILEGES FOR ROLE olap_owner IN SCHEMA olap
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO olap_user;
-- 針對序號： 確保以後新創的自增 ID, olap_user 都能使用
ALTER DEFAULT PRIVILEGES FOR ROLE olap_owner IN SCHEMA olap
GRANT USAGE, SELECT ON SEQUENCES TO olap_user;

-- 4. 確保 olap_user 只能在 oltp schema 讀取資料
GRANT USAGE ON SCHEMA oltp TO olap_user;
GRANT SELECT ON ALL TABLES IN SCHEMA oltp TO olap_user;

ALTER DEFAULT PRIVILEGES FOR ROLE oltp_owner IN SCHEMA oltp
GRANT SELECT ON TABLES TO olap_user;

\echo '--- [FINISH] 授予 OLAP Role 權限 ---'


-- * Migration Role 權限設定：
-- 1. 角色關係與繼承
GRANT oltp_owner TO migration_user;
GRANT olap_owner TO migration_user;

-- 2. Schema 權限
GRANT USAGE, CREATE ON SCHEMA oltp TO oltp_owner;
GRANT USAGE, CREATE ON SCHEMA olap TO olap_owner;
GRANT USAGE, CREATE ON SCHEMA oltp TO migration_user;
GRANT USAGE, CREATE ON SCHEMA olap TO migration_user;

-- 3. 修正「舊表」的所有權 ( 若原本是 superuser 建的 ) 把整個 Schema 的擁有者直接改掉
ALTER SCHEMA oltp OWNER TO oltp_owner;
ALTER SCHEMA olap OWNER TO olap_owner;

-- 4. 設定預設權限 : 確保 migration_user 進去建立的表，自動讓 owner 擁有完整權限
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA oltp
GRANT ALL ON TABLES TO oltp_owner;
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA oltp
GRANT ALL ON SEQUENCES TO oltp_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA oltp
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO oltp_user;
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA oltp
GRANT USAGE, SELECT ON SEQUENCES TO oltp_user;

ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA olap
GRANT ALL ON TABLES TO olap_owner;
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA olap
GRANT ALL ON SEQUENCES TO olap_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA olap
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO olap_user;
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA olap
GRANT USAGE, SELECT ON SEQUENCES TO olap_user;

-- 確保 migration_user 在 oltp 建表, oltp_user 能讀取
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA oltp
GRANT SELECT ON TABLES TO olap_user;

\echo '--- [FINISH] 授予 Migration Role 權限 ---'


-- * Remove 預設權限：撤銷 PUBLIC 角色在 schema 上的權限，確保只有特定角色能存取
REVOKE ALL ON SCHEMA oltp FROM PUBLIC;
REVOKE ALL ON SCHEMA olap FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC; -- 怕有用戶亂塞東西進來

\echo '--- [FINISH] Remove Public Role ---'


-- * 設定 Default Schema
ALTER ROLE oltp_owner
SET search_path = oltp;

ALTER ROLE oltp_user
SET search_path = oltp;

ALTER ROLE olap_owner
SET search_path = olap;

ALTER ROLE olap_user
SET search_path = olap;

\echo '--- [FINISH] 設定 Default Schema ---'


-- * 設定使用時區
-- 1. 任何連線進來的用戶，如果沒有額外設定，則顯示+8
ALTER DATABASE pgdatabase SET timezone TO 'Asia/Taipei';

-- 2. 確保特定用戶登入時一定是+8
ALTER ROLE pguser SET timezone TO 'Asia/Taipei';
ALTER ROLE migration_user SET timezone TO 'Asia/Taipei';
ALTER ROLE oltp_owner SET timezone TO 'Asia/Taipei';
ALTER ROLE olap_owner SET timezone TO 'Asia/Taipei';
ALTER ROLE oltp_user SET timezone TO 'Asia/Taipei';
ALTER ROLE olap_user SET timezone TO 'Asia/Taipei';

\echo '--- [FINISH] 設定使用時區 ---'


-- * 設定資源使用上限
-- 1. Query 執行時間限制
ALTER ROLE oltp_user
SET statement_timeout = '10s';

ALTER ROLE olap_user
SET statement_timeout = '60s';


-- 2. Query planning 限制
ALTER ROLE oltp_user
SET lock_timeout = '3s';

ALTER ROLE olap_user
SET lock_timeout = '10s';


-- 3. idle 連線限制
ALTER ROLE oltp_user
SET idle_in_transaction_session_timeout = '30s';

ALTER ROLE olap_user
SET idle_in_transaction_session_timeout = '60s';


-- 4. Memory 限制
ALTER ROLE oltp_user
SET work_mem = '8MB';

ALTER ROLE olap_user
SET work_mem = '64MB';


-- 5. Parallel query 限制
ALTER ROLE oltp_user
SET max_parallel_workers_per_gather = 0;

ALTER ROLE olap_user
SET max_parallel_workers_per_gather = 4;


-- 6. 連線數限制
ALTER ROLE oltp_user
CONNECTION LIMIT 100;

ALTER ROLE olap_user
CONNECTION LIMIT 5;


-- 7. temp file 限制
ALTER ROLE oltp_user
SET temp_file_limit = '0.5GB';

ALTER ROLE olap_user
SET temp_file_limit = '2GB';

\echo '--- [FINISH] 設定資源使用上限 ---'