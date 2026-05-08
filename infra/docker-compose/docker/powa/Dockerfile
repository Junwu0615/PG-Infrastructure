ARG POWA_POSTGRES_VERSION=16
FROM postgres:${POWA_POSTGRES_VERSION}

RUN apt-get update \
 && apt-get install -y \
    postgresql-16-powa \
    postgresql-16-pg-stat-kcache \
    postgresql-16-hypopg \
 && rm -rf /var/lib/apt/lists/*