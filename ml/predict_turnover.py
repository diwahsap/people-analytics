"""
Employee Turnover Prediction Model
This script builds a machine learning model to predict employee turnover risk.
"""

import pandas as pd
import numpy as np
import os
import joblib
from sqlalchemy import create_engine
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, roc_auc_score

# Database connection parameters
DB_USER = "postgres"
DB_PASSWORD = "postgres"
DB_HOST = "postgres"  # Use container name instead of localhost
DB_PORT = "5432"
DB_NAME = "people_analytics"

# Set up output paths
MODEL_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(MODEL_DIR, "turnover_model.pkl")
METRICS_PATH = os.path.join(MODEL_DIR, "model_metrics.txt")
PREDICTIONS_TABLE = "ml_turnover_predictions"

def connect_to_db():
    """Create a database connection."""
    connection_string = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    engine = create_engine(connection_string)
    return engine

def load_data():
    """Load data from the database."""
    engine = connect_to_db()
    
    # Load the employee 360 data mart which has all the features we need
    query = """
    SELECT * FROM employee_360
    """
    df = pd.read_sql(query, engine)
    print(f"Loaded {len(df)} records from the database")
    return df

def preprocess_data(df):
    """Prepare data for machine learning."""
    print("Preprocessing data for modeling...")
    
    # Filter for current and past employees only
    df = df[~df['employee_id'].isna()]
    
    # Create target variable - is_turnover is already defined in our data model
    y = df['is_turnover']
    
    # Select features for modeling
    features = [
        'tenure_years', 'age', 'performance_score_numeric', 'current_rating',
        'engagement_score', 'satisfaction_score', 'work_life_balance_score',
        'total_trainings', 'training_success_rate', 'days_since_last_training',
        'employee_type', 'pay_zone', 'gender', 'department_type', 'division'
    ]
    
    # Filter to only include columns that exist in the dataframe
    features = [f for f in features if f in df.columns]
    
    # Select the features from the dataframe
    X = df[features]
    
    # Also keep the employee_id for later use
    ids = df['employee_id']
    
    # Return features, target, employee IDs, and the list of feature names
    return X, y, ids, features

def build_model_pipeline(categorical_features, numeric_features):
    """Build a scikit-learn pipeline with preprocessing and model."""
    # Define preprocessing for numeric features
    numeric_transformer = Pipeline(steps=[
        ('scaler', StandardScaler())
    ])
    
    # Define preprocessing for categorical features
    categorical_transformer = Pipeline(steps=[
        ('onehot', OneHotEncoder(handle_unknown='ignore'))
    ])
    
    # Combine preprocessing steps
    preprocessor = ColumnTransformer(
        transformers=[
            ('num', numeric_transformer, numeric_features),
            ('cat', categorical_transformer, categorical_features)
        ])
    
    # Create the modeling pipeline
    pipeline = Pipeline(steps=[
        ('preprocessor', preprocessor),
        ('classifier', RandomForestClassifier(
            n_estimators=100, 
            max_depth=10, 
            random_state=42,
            class_weight='balanced'
        ))
    ])
    
    return pipeline

def train_and_evaluate_model(X, y, ids):
    """Train the model and evaluate its performance."""
    print("Training and evaluating model...")
    
    # Identify categorical and numeric features
    categorical_features = X.select_dtypes(include=['object', 'category']).columns.tolist()
    numeric_features = X.select_dtypes(include=['int64', 'float64']).columns.tolist()
    
    # Split the data
    X_train, X_test, y_train, y_test, ids_train, ids_test = train_test_split(
        X, y, ids, test_size=0.2, random_state=42, stratify=y
    )
    
    # Create and train the model
    model = build_model_pipeline(categorical_features, numeric_features)
    model.fit(X_train, y_train)
    
    # Make predictions
    y_pred = model.predict(X_test)
    y_prob = model.predict_proba(X_test)[:, 1]  # Probability of turnover
    
    # Calculate metrics
    accuracy = accuracy_score(y_test, y_pred)
    class_report = classification_report(y_test, y_pred)
    conf_matrix = confusion_matrix(y_test, y_pred)
    roc_auc = roc_auc_score(y_test, y_prob)
    
    # Create a summary of metrics
    metrics_summary = f"""
    Model Performance Metrics:
    -------------------------
    Accuracy: {accuracy:.4f}
    ROC-AUC Score: {roc_auc:.4f}
    
    Classification Report:
    {class_report}
    
    Confusion Matrix:
    {conf_matrix}
    """
    
    # Save the metrics
    with open(METRICS_PATH, 'w') as f:
        f.write(metrics_summary)
    
    print(metrics_summary)
    
    # Save the model
    joblib.dump(model, MODEL_PATH)
    print(f"Model saved to {MODEL_PATH}")
    
    # Prepare predictions for saving
    predictions_df = pd.DataFrame({
        'employee_id': ids_test,
        'actual_turnover': y_test,
        'predicted_turnover': y_pred,
        'turnover_probability': y_prob
    })
    
    return model, predictions_df

def predict_turnover_risk(model, X, ids):
    """Predict turnover risk for all employees."""
    print("Predicting turnover risk for all employees...")
    
    # Make predictions
    turnover_prob = model.predict_proba(X)[:, 1]  # Probability of turnover
    
    # Create risk levels based on probability thresholds
    risk_levels = pd.cut(
        turnover_prob, 
        bins=[0, 0.3, 0.6, 1], 
        labels=['Low Risk', 'Medium Risk', 'High Risk']
    )
    
    # Prepare predictions dataframe
    predictions_df = pd.DataFrame({
        'employee_id': ids,
        'turnover_probability': turnover_prob,
        'risk_level': risk_levels
    })
    
    return predictions_df

def save_predictions_to_db(predictions_df):
    """Save the predictions to the database."""
    print("Saving predictions to database...")
    
    engine = connect_to_db()
    predictions_df.to_sql(PREDICTIONS_TABLE, engine, if_exists='replace', index=False)
    print(f"Saved {len(predictions_df)} predictions to {PREDICTIONS_TABLE} table")

def main():
    """Main function to run the turnover prediction pipeline."""
    print("Starting turnover prediction modeling...")
    
    # Load data
    df = load_data()
    
    # Preprocess data
    X, y, ids, feature_names = preprocess_data(df)
    
    # Train and evaluate model
    model, test_predictions = train_and_evaluate_model(X, y, ids)
    
    # Generate predictions for all employees
    all_predictions = predict_turnover_risk(model, X, ids)
    
    # Save predictions to database
    save_predictions_to_db(all_predictions)
    
    print("Turnover prediction modeling completed successfully!")

if __name__ == "__main__":
    main()
