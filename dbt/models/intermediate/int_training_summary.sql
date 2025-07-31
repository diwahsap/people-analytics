{{ config(
    materialized='view'
) }}

with training as (
    select * from {{ ref('stg_training') }}
),

training_summary as (
    select
        employee_id,
        count(*) as total_trainings,
        sum(duration_days) as total_training_days,
        sum(cost) as total_training_cost,
        avg(cost) as avg_training_cost,
        sum(is_successful) as successful_trainings,
        
        -- Calculate training success rate
        sum(is_successful)::float / nullif(count(*), 0) as training_success_rate,
        
        -- Training type distribution
        count(case when training_type = 'Internal' then 1 end) as internal_trainings,
        count(case when training_type = 'External' then 1 end) as external_trainings,
        
        -- Training category distribution
        count(case when training_category = 'Technical' then 1 end) as technical_trainings,
        count(case when training_category = 'Leadership' then 1 end) as leadership_trainings,
        count(case when training_category = 'Customer Service' then 1 end) as customer_service_trainings,
        count(case when training_category = 'Communication' then 1 end) as communication_trainings,
        count(case when training_category = 'Project Management' then 1 end) as project_management_trainings,
        
        -- Most recent training
        max(training_date)::date as most_recent_training_date,
        
        -- Days since last training
        (date_part('day', current_date - max(training_date)))::integer as days_since_last_training
    from training
    group by 1
)

select * from training_summary
