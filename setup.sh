#!/bin/bash

echo "Starting setup for People Analytics Portfolio Project..."

# Clean up any existing containers to start fresh
echo "Cleaning up any existing containers..."
docker compose down 2>/dev/null || true

# Start the PostgreSQL container
echo "Starting PostgreSQL database container..."
docker compose up -d postgres

# Build all containers first
echo "Building containers..."
docker compose build

# Wait for PostgreSQL to be ready with proper health check
echo "Waiting for PostgreSQL to be ready..."
until docker compose exec postgres pg_isready -U postgres -d people_analytics; do
    echo "PostgreSQL is not ready yet... waiting 2 seconds"
    sleep 2
done
echo "PostgreSQL is ready!"

# run dbt seeds to load CSV data with proper types
echo "Running dbt seeds to load CSV data with specified data types..."
docker compose run --rm dbt dbt seed --full-refresh --profiles-dir=/usr/app/dbt/profiles

# Run dbt models
echo "Running dbt models to transform data..."
docker compose run --rm dbt dbt run --profiles-dir=/usr/app/dbt/profiles

# Run dbt tests
echo "Running dbt tests..."
docker compose run --rm dbt dbt test --profiles-dir=/usr/app/dbt/profiles

# Run ML prediction
echo "Training machine learning model and generating predictions..."
docker compose run --rm ml python /usr/app/ml/predict_turnover.py

echo ""
echo "Setup completed!"
echo ""
echo "Next steps:"
echo "1. Connect to the database using:"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   User: postgres"
echo "   Password: postgres"
echo "   Database: people_analytics"
echo ""
echo "2. Open PowerBI and connect to the PostgreSQL database"
echo "3. Import the provided dashboard templates from the powerbi/ directory"
echo ""
echo "Happy analyzing!"
