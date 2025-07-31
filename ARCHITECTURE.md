# People Analytics Portfolio Project - Architecture Overview

This document provides a detailed technical overview of the People Analytics Portfolio Project architecture, designed to showcase data engineering and analytics skills for a People Analytics Officer position.

## Architecture Diagram

```
┌───────────────┐     ┌──────────────────┐     ┌──────────────────┐     ┌───────────────┐
│               │     │                  │     │                  │     │               │
│  Source Data  │────▶│  dbt Seeds       │────▶│  dbt Transform   │────▶│  PostgreSQL   │
│  (CSV Files)  │     │  (Raw Tables)    │     │  (SQL Models)    │     │  Database     │
│               │     │                  │     │                  │     │               │
└───────────────┘     └──────────────────┘     └──────────────────┘     └───────┬───────┘
                                                                                │
                                                                                ▼
┌───────────────┐     ┌──────────────────┐                         ┌───────────────────┐
│               │     │                  │                         │                   │
│  PowerBI      │◀────│  Machine Learning│◀────────────────────────│  Analytics Marts  │
│  Documentation│     │  Models (Python) │                         │  (SQL Views)      │
│               │     │                  │                         │                   │
└───────────────┘     └──────────────────┘                         └───────────────────┘
                            ▲
                            │
┌───────────────┐           │
│               │           │
│  Jupyter      │───────────┘
│  Notebooks    │
│               │
└───────────────┘
```

## Component Details

### 1. Source Data (CSV Files)

The project uses synthetic HR data in CSV format:

- `employee_data.csv`: Core employee information and demographics
- `employee_engagement_survey_data.csv`: Employee engagement survey results
- `training_and_development_data.csv`: Training program participation and outcomes
- `recruitment_data.csv`: Candidate and hiring process data

### 2. Data Ingestion (dbt Seeds)

The project uses dbt's seed functionality to load raw data:

- CSV files are stored in the `dbt/seeds/` directory
- Data types are specified in the `seeds.yml` configuration
- Seeds are loaded directly into PostgreSQL database tables
- Version-controlled data loading process
- Supports data reloading with `dbt seed --full-refresh`

Additional data processing can be performed using Python scripts in `scripts/` directory.

### 3. Data Transformation (dbt)

The dbt (data build tool) component provides:

- SQL-based transformation models organized in layers:
  - **Staging** (`stg_`): Basic cleaning and standardization of raw data
  - **Intermediate** (`int_`): Business logic and calculated metrics
  - **Marts** (`mrt_`): Final analytics-ready data models
- Version-controlled data transformations
- Data documentation and lineage tracking
- Consistent naming conventions and modeling patterns

### 4. PostgreSQL Database

A PostgreSQL database serves as the data warehouse:

- Storage for raw and transformed data
- Relational data model with proper constraints
- Support for SQL analytics functions
- Dockerized for easy deployment

### 5. Machine Learning Models (Python)

Python ML scripts for predictive analytics:

- Employee turnover prediction model using RandomForest
- Feature engineering from HR data
- Model evaluation and performance metrics
- Prediction storage for visualization and analysis

### 6. PowerBI Dashboards

Interactive data visualization dashboards:

- Executive HR overview
- Detailed turnover analysis and risk assessment
- Recruitment funnel and efficiency metrics
- Training effectiveness and ROI analysis

## Data Flow Process

1. **Data Ingestion**:
   - Raw CSV files are stored in `data/raw/` directory
   - Files are copied to `dbt/seeds/` directory
   - dbt seed command loads these files into PostgreSQL tables
   - Data types are defined in `seeds.yml` configuration
   - Raw data tables are created with prefix `raw_`

2. **Data Transformation (dbt)**:
   - Staging models (`stg_`) clean and standardize raw data
   - Intermediate models (`int_`) calculate metrics and features
   - Final data marts (`mrt_`) aggregate information for analysis

3. **Machine Learning**:
   - Python scripts read from transformed data tables
   - Features are engineered and models are trained
   - Models are saved as `turnover_model.pkl`
   - Predictions are stored back in the database
   - Performance metrics are documented in `model_metrics.txt`

4. **Visualization**:
   - PowerBI connects to the PostgreSQL database
   - Dashboards visualize insights from data marts and ML predictions
   - Reports are organized by business domain (turnover, recruitment, etc.)

## Technical Stack

- **Programming Languages**: Python, SQL
- **Database**: PostgreSQL
- **Data Transformation**: dbt (data build tool)
- **Machine Learning**: scikit-learn, pandas
- **Containerization**: Docker
- **Visualization**: PowerBI

## Deployment

The project uses Docker Compose for easy deployment with three main services:

- **postgres**: PostgreSQL database container for data storage
  - Exposes port 5432
  - Uses persistent volume for data storage
  
- **dbt**: dbt container for data transformations
  - Built from custom Dockerfile (docker/dbt.Dockerfile)
  - Mounts the dbt project directory and profiles
  - Depends on the postgres service
  
- **ml**: Python environment for machine learning and data processing
  - Built from custom Dockerfile (docker/ml.Dockerfile)
  - Mounts ml, scripts, and data directories
  - Depends on the postgres service

All services are connected through a dedicated network (`people-analytics-network`)


## Scaling Considerations

This architecture is designed to scale for larger HR datasets:

- dbt models can handle growing data volumes
- PostgreSQL can be scaled with larger instances
- Data pipelines can be scheduled for regular updates
- ML models can be retrained automatically

## Security Considerations

While this is a portfolio project, in a production environment:

- Data would be encrypted at rest and in transit
- Access control would be implemented for database and dashboards
- Sensitive HR data would be masked or tokenized
- Authentication would be required for all system components
