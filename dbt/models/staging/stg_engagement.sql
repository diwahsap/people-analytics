{{ config(
    materialized='view'
) }}

with source as (
    select * from {{ ref('raw_employee_engagement_survey_data') }}
),

renamed as (
    select
        "Employee ID" as employee_id,
        -- Convert survey date from DD-MM-YYYY format
        case 
            when "Survey Date" is not null and "Survey Date" != '' 
            then to_date("Survey Date", 'DD-MM-YYYY')
            else null 
        end as survey_date,
        "Engagement Score" as engagement_score,
        "Satisfaction Score" as satisfaction_score,
        "Work-Life Balance Score" as work_life_balance_score
    from source
),

transformed as (
    select
        *,
        -- Categorize engagement level
        case 
            when engagement_score >= 4 then 'High'
            when engagement_score >= 2 then 'Medium'
            else 'Low'
        end as engagement_level,
        
        -- Categorize satisfaction level
        case 
            when satisfaction_score >= 4 then 'High'
            when satisfaction_score >= 2 then 'Medium'
            else 'Low'
        end as satisfaction_level,
        
        -- Categorize work-life balance level
        case 
            when work_life_balance_score >= 4 then 'High'
            when work_life_balance_score >= 2 then 'Medium'
            else 'Low'
        end as work_life_balance_level,
        
        -- Calculate overall wellbeing score (average of all scores)
        ((engagement_score + satisfaction_score + work_life_balance_score) / 3.0)::float as overall_wellbeing_score
    from renamed
)

select * from transformed
