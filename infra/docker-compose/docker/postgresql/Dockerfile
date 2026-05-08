ARG POSTGRES_VERSION=16.2-alpine
FROM postgres:${POSTGRES_VERSION}

# 安裝編譯與下載工具
RUN apk add --no-cache --virtual .build-deps \
    git \
    make \
    gcc \
    clang15 \
    llvm15-dev \
    musl-dev \
    icu-dev \
    && apk add --no-cache icu-data-full

# pg_wait_sampling : 下載並安裝擴充功能
RUN git clone https://github.com/postgrespro/pg_wait_sampling.git /tmp/pg_wait_sampling \
    && cd /tmp/pg_wait_sampling \
    && make USE_PGXS=1 install \
    && rm -rf /tmp/pg_wait_sampling

# hypopg : 下載並安裝擴充功能
RUN git clone https://github.com/HypoPG/hypopg.git /tmp/hypopg \
    && cd /tmp/hypopg \
    && make USE_PGXS=1 install \
    && rm -rf /tmp/hypopg

# 清理編譯工具
RUN apk del .build-deps

# 設定語系環境變數避免警告
ENV LANG en_US.utf8