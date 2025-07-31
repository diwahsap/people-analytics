{{ config(
    materialized='view'
) }}

with source as (
    select * from {{ ref('raw_employee_data') }}
),

renamed as (
    select
        "EmpID" as employee_id,
        "FirstName" as first_name,
        "LastName" as last_name,
        -- Convert date strings to proper dates
        case 
            when "StartDate" is not null and "StartDate" != '' 
            then to_date("StartDate", 'DD-Mon-YY')
            else null 
        end as start_date,
        case 
            when "ExitDate" is not null and "ExitDate" != '' 
            then to_date("ExitDate", 'DD-Mon-YY')
            else null 
        end as exit_date,
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
        -- Convert DOB from DD-MM-YYYY format
        case 
            when "DOB" is not null and "DOB" != '' 
            then to_date("DOB", 'DD-MM-YYYY')
            else null 
        end as date_of_birth,
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
        date_part('year', age(current_date, date_of_birth))::integer as age,
        
        -- Calculate tenure in years
        (case 
            when exit_date is not null then
                date_part('year', age(exit_date, start_date))
            else
                date_part('year', age(current_date, start_date))
        end)::integer as tenure_years,

        -- Calculate tenure in days (total days)
        (case 
            when exit_date is not null then
                (exit_date - start_date)
            else
                (current_date - start_date)
        end)::integer as tenure_days,
        
        -- Create tenure buckets
        (case 
            when date_part('year', age(coalesce(exit_date, current_date), start_date)) < 1 then '0-1 years'
            when date_part('year', age(coalesce(exit_date, current_date), start_date)) < 3 then '1-3 years'
            else '3+ years'
        end)::varchar as tenure_bucket,
        
        -- Create binary turnover indicator
        (case when exit_date is not null then 1 else 0 end)::boolean as is_turnover
    from renamed
)

select * from transformed
