{{ config(
    materialized='view'
) }}

with source as (
    select * from {{ source('raw', 'employee_data') }}
),

renamed as (
    select
        "EmpID" as employee_id,
        "FirstName" as first_name,
        "LastName" as last_name,
        "StartDate" as start_date,
        "ExitDate" as exit_date,
        "Title" as job_title,
        "Supervisor" as supervisor_name,
        "ADEmail" as email,
        "BusinessUnit" as business_unit,
        "EmployeeStatus" as employee_status,
        "EmployeeType" as employee_type,
        "PayZone" as pay_zone,
        "EmployeeClassificationType" as classification_type,
        "TerminationType" as termination_type,
        "TerminationDescription" as termination_description,
        "DepartmentType" as department_type,
        "Division" as division,
        "DOB" as date_of_birth,
        "State" as state,
        "JobFunctionDescription" as job_function,
        "GenderCode" as gender,
        "LocationCode" as location_code,
        "RaceDesc" as race_ethnicity,
        "MaritalDesc" as marital_status,
        "Performance Score" as performance_score,
        "Current Employee Rating" as current_rating
    from source
),

transformed as (
    select
        *,
        -- Calculate age
        date_part('year', age(current_date, date_of_birth)) as age,
        
        -- Calculate tenure in years
        case 
            when exit_date is not null then
                date_part('year', age(exit_date, start_date))
            else
                date_part('year', age(current_date, start_date))
        end as tenure_years,
        
        -- Create tenure buckets
        case 
            when date_part('year', age(coalesce(exit_date, current_date), start_date)) < 1 then '0-1 years'
            when date_part('year', age(coalesce(exit_date, current_date), start_date)) < 3 then '1-3 years'
            else '3+ years'
        end as tenure_bucket,
        
        -- Create binary turnover indicator
        case when exit_date is not null then 1 else 0 end as is_turnover
    from renamed
)

select * from transformed
