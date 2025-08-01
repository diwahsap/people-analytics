{{ config(
    materialized='view'
) }}

with employees as (
    select * from {{ ref('stg_employees') }}
),

employee_metrics as (
    select
        employee_id,
        first_name,
        last_name,
        email,
        job_title,
        business_unit,
        department_type,
        division,
        state,
        supervisor_name,
        employee_status,
        employee_type,
        pay_zone,
        classification_type,
        termination_type,
        termination_description,
        performance_score,
        current_rating,
        gender,
        race_ethnicity,
        marital_status,
        age,
        start_date,
        tenure_days,
        tenure_years,
        tenure_bucket,
        is_turnover,
        
        -- Additional calculated fields
        extract(year from start_date)::integer as hire_year,
        extract(quarter from start_date)::integer as hire_quarter,
        
        -- Performance metrics
        case 
            when performance_score = 'Exceeds' then 3
            when performance_score = 'Fully Meets' then 2
            when performance_score = 'Partially Meets' then 1
            else 0
        end as performance_score_numeric,
        
        case when current_rating >= 4 then 1 else 0 end as is_high_performer,
        case when current_rating <= 2 then 1 else 0 end as is_low_performer
    from employees
)

select * from employee_metrics
