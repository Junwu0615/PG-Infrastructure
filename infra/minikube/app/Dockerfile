# 使用輕量化 Python 鏡像
FROM python:3.9-slim

# 安裝編譯 psycopg2 所需的系統套件
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 安裝 Python 依賴
RUN pip install --no-cache-dir psycopg2-binary

# 複製腳本
COPY app.py .

# 執行腳本
CMD ["python", "app.py"]