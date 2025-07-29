{{ config(
    materialized='table'
) }}

with employee_metrics as (
    select * from {{ ref('int_employee_metrics') }}
),

engagement_metrics as (
    select * from {{ ref('int_engagement_metrics') }}
),

turnover_metrics as (
    select
        employee_id,
        first_name,
        last_name,
        job_title,
        business_unit,
        department_type,
        division,
        state,
        supervisor_name,
        employee_type,
        pay_zone,
        gender,
        race_ethnicity,
        marital_status,
        age,
        tenure_years,
        tenure_bucket,
        performance_score,
        current_rating,
        is_turnover,
        
        -- If employee left, add termination information
        case when is_turnover = 1 then termination_type else 'Active' end as exit_type,
        case when is_turnover = 1 then termination_description else null end as exit_reason
    from employee_metrics
),

turnover_with_engagement as (
    select
        t.*,
        -- Engagement metrics if available
        e.engagement_score,
        e.satisfaction_score,
        e.work_life_balance_score,
        e.overall_wellbeing_score,
        e.engagement_risk_level
    from turnover_metrics t
    left join engagement_metrics e on t.employee_id = e.employee_id
)

select * from turnover_with_engagement
