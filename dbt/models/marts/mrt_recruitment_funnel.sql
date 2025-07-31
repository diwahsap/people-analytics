{{ config(
    materialized='table'
) }}

with recruitment as (
    select * from {{ ref('stg_recruitment') }}
),

recruitment_summary as (
    select
        job_title,
        education_level,
        count(*) as total_applicants,
        avg(years_experience) as avg_years_experience,
        avg(desired_salary) as avg_desired_salary,
        
        -- Application funnel metrics
        count(case when status = 'In Review' then 1 end) as in_review_count,
        count(case when status = 'Interviewing' then 1 end) as interviewing_count,
        count(case when status = 'Offered' then 1 end) as offered_count,
        count(case when status = 'Rejected' then 1 end) as rejected_count,
        
        -- Calculate conversion rates
        (count(case when status = 'Interviewing' then 1 end)::float / 
         nullif(count(*), 0)) as review_to_interview_rate,
        
        (count(case when status = 'Offered' then 1 end)::float / 
         nullif(count(case when status = 'Interviewing' then 1 end), 0)) as interview_to_offer_rate,
        
        -- Overall success rate
        (count(case when status = 'Offered' then 1 end)::float / 
         nullif(count(*), 0)) as overall_success_rate,
        
        -- Time dimensions for trend analysis
        application_year,
        application_quarter
    from recruitment
    group by job_title, education_level, application_year, application_quarter
)

select * from recruitment_summary
