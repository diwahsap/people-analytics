{{ config(
    materialized='view'
) }}

with engagement as (
    select * from {{ ref('stg_engagement') }}
),

latest_engagement as (
    select
        e.*,
        -- Get latest survey result per employee
        row_number() over(partition by employee_id order by survey_date desc) as survey_rank
    from engagement e
),

engagement_metrics as (
    select
        employee_id,
        survey_date,
        engagement_score,
        satisfaction_score,
        work_life_balance_score,
        overall_wellbeing_score,
        engagement_level,
        satisfaction_level,
        work_life_balance_level,
        
        -- Calculate risk flags based on low scores
        case when engagement_score <= 2 then 1 else 0 end as low_engagement_flag,
        case when satisfaction_score <= 2 then 1 else 0 end as low_satisfaction_flag,
        case when work_life_balance_score <= 2 then 1 else 0 end as low_work_life_balance_flag,
        
        -- Overall risk score (sum of all risk flags)
        case when engagement_score <= 2 then 1 else 0 end + 
        case when satisfaction_score <= 2 then 1 else 0 end + 
        case when work_life_balance_score <= 2 then 1 else 0 end as engagement_risk_score,
        
        -- Risk level categorization
        case 
            when (engagement_score <= 2 and satisfaction_score <= 2) or 
                 (engagement_score <= 2 and work_life_balance_score <= 2) or
                 (satisfaction_score <= 2 and work_life_balance_score <= 2)
                 then 'High Risk'
            when engagement_score <= 2 or satisfaction_score <= 2 or work_life_balance_score <= 2
                 then 'Medium Risk'
            else 'Low Risk'
        end as engagement_risk_level
    from latest_engagement
    where survey_rank = 1  -- Only get the most recent survey for each employee
)

select * from engagement_metrics
