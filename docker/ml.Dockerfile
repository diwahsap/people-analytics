FROM python:3.9-slim

WORKDIR /usr/app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libpq-dev \
        gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY ml/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy scripts directory
COPY scripts /usr/app/scripts

WORKDIR /usr/app/ml

CMD ["bash"]
