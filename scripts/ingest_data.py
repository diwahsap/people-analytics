#!/usr/bin/env python3
"""
Data Ingestion Script for People Analytics Project.
This script reads CSV data files and loads them into PostgreSQL database.
"""

import os
import pandas as pd
import time
from sqlalchemy import create_engine, text

# Database connection parameters
DB_USER = "postgres"
DB_PASSWORD = "postgres"
DB_HOST = "postgres" 
DB_PORT = "5432"
DB_NAME = "people_analytics"

# Data file paths - Adjusted for Docker volume mounting
DATA_DIR = "/usr/app/data/raw"
EMPLOYEE_DATA_FILE = os.path.join(DATA_DIR, "employee_data.csv")
ENGAGEMENT_DATA_FILE = os.path.join(DATA_DIR, "employee_engagement_survey_data.csv")
TRAINING_DATA_FILE = os.path.join(DATA_DIR, "training_and_development_data.csv")
RECRUITMENT_DATA_FILE = os.path.join(DATA_DIR, "recruitment_data.csv")


def create_db_connection():
    """Create a database connection with retry logic."""
    connection_string = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    
    max_retries = 30
    retry_delay = 2
    
    for attempt in range(max_retries):
        try:
            print(f"Attempting to connect to database (attempt {attempt + 1}/{max_retries})...")
            engine = create_engine(connection_string)
            # Test the connection
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            print("Successfully connected to database!")
            return engine
        except Exception as e:
            print(f"Connection failed: {e}")
            if attempt < max_retries - 1:
                print(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
            else:
                print("Max retries reached. Unable to connect to database.")
                raise


def ingest_employee_data(engine):
    """Ingest employee data into the database."""
    print("Ingesting employee data...")
    df = pd.read_csv(EMPLOYEE_DATA_FILE)
    
    # Convert date columns to proper format
    date_columns = ["StartDate", "ExitDate"]
    for col in date_columns:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], format="%d-%b-%y", errors="coerce")
    
    # 07-10-1969
    df["DOB"] = pd.to_datetime(df["DOB"], format="%d-%m-%Y", errors="coerce")

    # Then write to database
    df.to_sql("raw_employee_data", engine, if_exists="fail", index=False)
    print(f"Successfully ingested {len(df)} employee records")


def ingest_engagement_data(engine):
    """Ingest employee engagement survey data into the database."""
    print("Ingesting engagement survey data...")
    df = pd.read_csv(ENGAGEMENT_DATA_FILE)
    
    # Convert date columns
    if "Survey Date" in df.columns:
        df["Survey Date"] = pd.to_datetime(df["Survey Date"], format="%d-%m-%Y", errors="coerce")
    
    # Then write to database
    df.to_sql("raw_engagement_data", engine, if_exists="fail", index=False)
    print(f"Successfully ingested {len(df)} engagement survey records")


def ingest_training_data(engine):
    """Ingest training and development data into the database."""
    print("Ingesting training and development data...")
    df = pd.read_csv(TRAINING_DATA_FILE)
    
    # Convert date columns
    if "Training Date" in df.columns:
        df["Training Date"] = pd.to_datetime(df["Training Date"], format="%d-%b-%y", errors="coerce")
    
    # Then write to database
    df.to_sql("raw_training_data", engine, if_exists="fail", index=False)
    print(f"Successfully ingested {len(df)} training records")


def ingest_recruitment_data(engine):
    """Ingest recruitment data into the database."""
    print("Ingesting recruitment data...")
    df = pd.read_csv(RECRUITMENT_DATA_FILE)
    
    # Convert date columns
    df["Application Date"] = pd.to_datetime(df["Application Date"], format="%d-%b-%y", errors="coerce")
    # 07-10-1969
    df["Date of Birth"] = pd.to_datetime(df["Date of Birth"], format="%d-%m-%Y", errors="coerce")
    
    # Then write to database
    df.to_sql("raw_recruitment_data", engine, if_exists="fail", index=False)
    print(f"Successfully ingested {len(df)} recruitment records")


def main():
    """Main function to run the ingestion process."""
    print("Starting data ingestion process...")
    engine = create_db_connection()
    
    # Now ingest fresh data
    ingest_employee_data(engine)
    ingest_engagement_data(engine)
    ingest_training_data(engine)
    ingest_recruitment_data(engine)
    
    print("Data ingestion complete!")


if __name__ == "__main__":
    main()
