-- 安裝 extensions
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS hypopg;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS powa;

-- -- 建立登入帳號
-- CREATE ROLE powa LOGIN PASSWORD 'powa';
--
-- -- 重要：必須 superuser
-- ALTER ROLE powa WITH SUPERUSER;
--
-- -- 給予權限
-- GRANT ALL PRIVILEGES ON DATABASE powa TO powa;

-- 初始化 powa_servers (手動 insert)
INSERT INTO powa_servers(
    hostname,
    alias,
    port,
    username,
    password,
    dbname,
    allow_ui_connection
) VALUES (
    'powa-postgres',  -- Docker service name
    'powa-db',            -- UI 顯示的 Server 名稱
    5432,
    'powa',
    'powa',
    'powa',
    TRUE
)
ON CONFLICT (id) DO NOTHING; -- 避免重複執行