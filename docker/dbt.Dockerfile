FROM python:3.9-slim

WORKDIR /usr/app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        libpq-dev \
        gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    dbt-core==1.5.0 \
    dbt-postgres==1.5.0

WORKDIR /usr/app/dbt

CMD ["bash"]
