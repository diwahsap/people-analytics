{{ config(
    materialized='view'
) }}

with source as (
    select * from {{ source('raw', 'training_data') }}
),

renamed as (
    select
        "Employee ID" as employee_id,
        "Training Date" as training_date,
        "Training Program Name" as program_name,
        "Training Type" as training_type,
        "Training Outcome" as outcome,
        "Location" as location,
        "Trainer" as trainer,
        "Training Duration(Days)" as duration_days,
        "Training Cost" as cost
    from source
),

transformed as (
    select
        *,
        -- Binary success indicator
        case 
            when outcome in ('Completed', 'Passed') then 1
            else 0
        end as is_successful,
        
        -- Cost per day
        cost / nullif(duration_days, 0) as cost_per_day,
        
        -- Extract year and quarter for time-based analysis
        extract(year from training_date) as training_year,
        extract(quarter from training_date) as training_quarter,
        
        -- Training category grouping
        case
            when lower(program_name) like '%technical%' or lower(program_name) like '%skill%' then 'Technical'
            when lower(program_name) like '%leadership%' or lower(program_name) like '%management%' then 'Leadership'
            when lower(program_name) like '%customer%' or lower(program_name) like '%service%' then 'Customer Service'
            when lower(program_name) like '%communication%' then 'Communication'
            when lower(program_name) like '%project%' then 'Project Management'
            else 'Other'
        end as training_category
    from renamed
)

select * from transformed
