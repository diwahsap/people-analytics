{{ config(
    materialized='view'
) }}

with source as (
    select * from {{ ref('raw_recruitment_data') }}
),

renamed as (
    select
        "Applicant ID" as applicant_id,
        -- Convert application date from DD-Mon-YY format
        case 
            when "Application Date" is not null and "Application Date" != '' 
            then to_date("Application Date", 'DD-Mon-YY')
            else null 
        end as application_date,
        "First Name" as first_name,
        "Last Name" as last_name,
        "Gender" as gender,
        -- Convert date of birth from DD-MM-YYYY format
        case 
            when "Date of Birth" is not null and "Date of Birth" != '' 
            then to_date("Date of Birth", 'DD-MM-YYYY')
            else null 
        end as date_of_birth,
        "Phone Number" as phone,
        "Email" as email,
        "City" as city,
        "State" as state,
        "Country" as country,
        "Education Level" as education_level,
        "Years of Experience" as years_experience,
        "Desired Salary" as desired_salary,
        "Job Title" as job_title,
        "Status" as status
    from source
),

transformed as (
    select
        *,
        
        -- Standardize phone number by removing '+1' and all non-digits
        NULLIF(
            regexp_replace(
                CASE
                    WHEN phone LIKE '+1%' THEN substring(phone from 3)
                    ELSE phone
                END,
                '[^0-9]', -- Match any character that is not a digit
                '',       -- Replace with an empty string
                'g'       -- Apply globally across the string
            ),
            '' -- Convert empty results to NULL
        ) as phone_standardized,

        -- Calculate age of applicant
        date_part('year', age(current_date, date_of_birth)) as age,
        
        -- Education level ordinal
        case 
            when education_level = 'High School' then 1
            when education_level = 'Associate''s Degree' then 2
            when education_level = 'Bachelor''s Degree' then 3
            when education_level = 'Master''s Degree' then 4
            when education_level = 'PhD' then 5
            else 0
        end as education_level_ordinal,
        
        -- Binary indicator for hired status
        case when status = 'Offered' then 1 else 0 end as is_offered,
        
        -- Application status grouping
        case
            when status in ('Offered', 'Accepted') then 'Successful'
            when status in ('Rejected', 'Declined') then 'Unsuccessful'
            else 'In Progress'
        end as application_outcome,
        
        -- Extract year and quarter for time-based analysis
        extract(year from application_date) as application_year,
        extract(quarter from application_date) as application_quarter
    from renamed
)

-- Select all required columns explicitly, excluding the original 'phone' column
select
    applicant_id,
    application_date,
    first_name,
    last_name,
    gender,
    date_of_birth,
    email,
    city,
    state,
    country,
    education_level,
    years_experience,
    desired_salary,
    job_title,
    status,
    -- New and calculated columns
    phone_standardized as phone,
    age,
    education_level_ordinal,
    is_offered,
    application_outcome,
    application_year,
    application_quarter
from transformed