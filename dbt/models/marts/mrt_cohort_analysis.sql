{{ config(
    materialized='table'
) }}

with employee_cohorts as (
    select 
        hire_year,
        hire_quarter,
        employee_type,
        department_type,
        business_unit,
        pay_zone,
        
        -- Total employees in cohort
        count(*) as total_employees,
        
        -- Employees who left
        sum(case when is_turnover = 'true' then 1 else 0 end) as turnover_count,
        
        -- Employees still active
        sum(case when is_turnover = 'false' then 1 else 0 end) as active_count,
        
        -- Turnover rate for the cohort
        round(
            (sum(case when is_turnover = 'true' then 1 else 0 end) * 100.0) / count(*), 
            2
        ) as cohort_turnover_rate,
        
        -- Average tenure of the cohort
        round(avg(tenure_years), 2) as avg_tenure_years,
        
        -- Performance distribution
        round(avg(performance_score_numeric), 2) as avg_performance_score,
        
        -- Engagement metrics (if available)
        round(avg(engagement_score), 2) as avg_engagement_score
        
    from {{ ref('mrt_employee_360') }}
    group by 
        hire_year,
        hire_quarter, 
        employee_type,
        department_type,
        business_unit,
        pay_zone
),

yearly_cohorts as (
    select 
        hire_year,
        employee_type,
        
        -- Aggregate across all quarters and departments for yearly view
        sum(total_employees) as total_employees,
        sum(turnover_count) as turnover_count,
        sum(active_count) as active_count,
        
        -- Recalculate turnover rate at year level
        round(
            (sum(turnover_count) * 100.0) / sum(total_employees), 
            2
        ) as yearly_turnover_rate,
        
        -- Weighted averages
        round(
            sum(avg_tenure_years * total_employees) / sum(total_employees), 
            2
        ) as weighted_avg_tenure,
        
        round(
            sum(avg_performance_score * total_employees) / sum(total_employees), 
            2
        ) as weighted_avg_performance

    from employee_cohorts
    group by hire_year, employee_type
)

-- Union detailed and summary views
select 
    'detailed' as analysis_level,
    hire_year,
    hire_quarter,
    employee_type,
    department_type,
    business_unit,
    pay_zone,
    total_employees,
    turnover_count,
    active_count,
    cohort_turnover_rate as turnover_rate,
    avg_tenure_years,
    avg_performance_score,
    avg_engagement_score
from employee_cohorts

union all

select 
    'yearly_summary' as analysis_level,
    hire_year,
    null as hire_quarter,
    employee_type,
    'All Departments' as department_type,
    'All Business Units' as business_unit,
    'All Pay Zones' as pay_zone,
    total_employees,
    turnover_count,
    active_count,
    yearly_turnover_rate as turnover_rate,
    weighted_avg_tenure as avg_tenure_years,
    weighted_avg_performance as avg_performance_score,
    null as avg_engagement_score
from yearly_cohorts

order by hire_year desc, analysis_level, employee_type