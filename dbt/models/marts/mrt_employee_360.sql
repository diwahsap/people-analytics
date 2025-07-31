{{ config(
    materialized='table'
) }}

with employee_metrics as (
    select * from {{ ref('int_employee_metrics') }}
),

engagement_metrics as (
    select * from {{ ref('int_engagement_metrics') }}
),

training_summary as (
    select * from {{ ref('int_training_summary') }}
),

employee_complete as (
    select
        e.*,
        
        -- Engagement metrics
        coalesce(eng.engagement_score, 0) as engagement_score,
        coalesce(eng.satisfaction_score, 0) as satisfaction_score,
        coalesce(eng.work_life_balance_score, 0) as work_life_balance_score,
        coalesce(eng.overall_wellbeing_score, 0) as overall_wellbeing_score,
        coalesce(eng.engagement_level, 'Unknown') as engagement_level,
        coalesce(eng.satisfaction_level, 'Unknown') as satisfaction_level,
        coalesce(eng.work_life_balance_level, 'Unknown') as work_life_balance_level,
        coalesce(eng.engagement_risk_score, 0) as engagement_risk_score,
        coalesce(eng.engagement_risk_level, 'Unknown') as engagement_risk_level,
        
        -- Training metrics
        coalesce(t.total_trainings, 0) as total_trainings,
        coalesce(t.total_training_days, 0) as total_training_days,
        coalesce(t.total_training_cost, 0) as total_training_cost,
        coalesce(t.training_success_rate, 0) as training_success_rate,
        coalesce(t.technical_trainings, 0) as technical_trainings,
        coalesce(t.leadership_trainings, 0) as leadership_trainings,
        coalesce(t.days_since_last_training, 999) as days_since_last_training
        
    from employee_metrics e
    left join engagement_metrics eng on e.employee_id = eng.employee_id
    left join training_summary t on e.employee_id = t.employee_id
)

select * from employee_complete
