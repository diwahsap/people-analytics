"""
Employee Turnover Prediction Model
This script builds a simple logistic regression model to predict employee turnover risk.
Based on analysis showing that a simple model with tenure as predictor performs very well.
"""

import pandas as pd
import numpy as np
import os
import joblib
from sqlalchemy import create_engine
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, roc_auc_score
import statsmodels.api as sm
import statsmodels.formula.api as smf

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
    SELECT * FROM mrt_employee_360
    """
    df = pd.read_sql(query, engine)
    print(f"Loaded {len(df)} records from the database")
    return df

def preprocess_data(df):
    """Prepare data for machine learning using simple logistic regression."""
    print("Preprocessing data for modeling...")
    
    # Filter for current and past employees only
    df = df[~df['employee_id'].isna()]
    
    # Create target variable - is_turnover is already defined in our data model
    y = df['is_turnover']
    
    # Convert boolean to int for statsmodels
    df['is_turnover_int'] = df['is_turnover'].astype(int)
    
    # Based on notebook analysis, tenure_days is the most significant predictor
    # Select only this feature for our simple logistic regression model
    features = ['tenure_days']
    
    # Filter to only include columns that exist in the dataframe
    features = [f for f in features if f in df.columns]
    
    # Select the features from the dataframe
    X = df[features]
    
    # Also keep the employee_id for later use
    ids = df['employee_id']
    
    # Return processed dataframe, features, target, and employee IDs
    return df, X, y, ids, features

def build_logistic_model(df, features):
    """Build a simple logistic regression model using statsmodels."""
    print("Building logistic regression model...")
    
    # Build formula string for statsmodels
    # The model will predict is_turnover_int based on tenure_days
    formula = 'is_turnover_int ~ ' + ' + '.join(features)
    
    # Fit the logistic regression model
    model = smf.logit(formula=formula, data=df).fit()
    
    # Print model summary
    print(model.summary())
    
    # Print odds ratio interpretation
    params = model.params
    odds_ratio_day = np.exp(params['tenure_days'])
    print(f"Each additional day of tenure reduces turnover odds by a factor of {odds_ratio_day:.3f}")
    print(f"This is a {(1 - odds_ratio_day) * 100:.1f}% reduction in odds per day")
    
    # More meaningful interpretation (per 30 days)
    odds_ratio_30days = odds_ratio_day ** 30
    print(f"After 30 days, odds of leaving are {odds_ratio_30days:.3f} times the original")
    print(f"This corresponds to a {(1 - odds_ratio_30days) * 100:.1f}% decrease in odds")
    
    return model

def train_and_evaluate_model(df, X, y, ids, features):
    """Train the model and evaluate its performance using logistic regression."""
    print("Training and evaluating model...")
    
    # Create stratified train/test split for evaluation
    X_train, X_test, y_train, y_test, ids_train, ids_test, df_train, df_test = train_test_split(
        X, y, ids, df[features + ['is_turnover_int']], 
        test_size=0.2, random_state=42, stratify=y
    )
    
    # Build logistic regression model
    model = build_logistic_model(df, features)
    
    # Make predictions on test set
    y_prob = model.predict(df_test)
    y_pred = (y_prob > 0.5).astype(int)
    
    # Calculate metrics
    accuracy = accuracy_score(y_test, y_pred)
    class_report = classification_report(y_test, y_pred)
    conf_matrix = confusion_matrix(y_test, y_pred)
    roc_auc = roc_auc_score(y_test, y_prob)
    
    # Create a summary of metrics
    metrics_summary = f"""
    Simple Logistic Regression Model Performance Metrics:
    ---------------------------------------------------
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
    
    # Save the model using joblib for compatibility with existing code
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

def predict_turnover_risk(model, df, ids):
    """Predict turnover risk for all employees using the logistic model."""
    print("Predicting turnover risk for all employees...")
    
    # Make predictions using statsmodels
    turnover_prob = model.predict(df)
    
    # Create risk levels based on probability thresholds
    # Based on notebook, using 0.3 and 0.7 as thresholds
    risk_levels = pd.cut(
        turnover_prob, 
        bins=[0, 0.3, 0.7, 1], 
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
    """Main function to run the simple logistic regression turnover prediction pipeline."""
    print("Starting turnover prediction modeling using simple logistic regression...")
    
    # Load data
    df = load_data()
    
    # Preprocess data
    df_processed, X, y, ids, feature_names = preprocess_data(df)
    
    # Train and evaluate model
    model, test_predictions = train_and_evaluate_model(df_processed, X, y, ids, feature_names)
    
    # Generate predictions for all employees
    all_predictions = predict_turnover_risk(model, df_processed, ids)
    
    # Save predictions to database
    save_predictions_to_db(all_predictions)
    
    print("Turnover prediction modeling with simple logistic regression completed successfully!")

if __name__ == "__main__":
    main()
