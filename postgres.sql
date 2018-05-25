/* get aggregate by hierarchy using windowing function */
select
	department, last_name, salary
	,avg(trunc(salary)) over (partition by department)
from
	staff
;

select
	company_regions, last_name, salary
	,min(salary) over (partition by company_regions)
from
	staff_div_reg
;

/* compare aggregate to first value of hierarchy grouping */

select
	department, last_name, salary
	, first_value(salary) over (partition by department order by salary desc)
from
	staff
;

/* assign rank value to hierarchy grouping */

select
	department, last_name, salary
	,rank() over (partition by department order by salary desc)
from 
	staff
;

/* LAG and LEAD to get prior or next value of hierarcy grouping*/

select
	department, last_name, salary
	,lag(salary) over (partition by department order by salary desc)
from
	staff
;

select
	department, last_name, salary
	,lead(salary) over (partition by department order by salary desc)
from
	staff
;

/* NTILE can be used to group by bucket */

select
	department, last_name, salary
	,ntile(4) over (partition by department order by salary desc)
from
	staff
;

/* subquery in SELECT clause */

select
	s1.last_name
	,s1.salary
	,s1.department
	,(select round(avg(salary)) from staff s2 where s2.department = s1.department)
from 
	staff s1
;

/* subquery in FROM clause */

select
	s1.department
	,round(avg(s1.salary))
from
	(select
		department
		,salary
	from
		staff
	where
		salary > 100000
	) s1
group by 
	s1.department
;

/* subquery in WHERE clause */

select
	department
from
	staff s1
where
	s1.salary = (select max(s2.salary) from staff s2)
;

/* review all records of left table without a corresponding field in the right table */
select
	s.last_name
	,s.department
	,cd.company_division
from
	staff s left join company_divisions cd
on
	s.department = cd.department
where
	cd.company_division is null
;

/* using a view to reference multiple tables and improve query performance */
create view staff_div_reg as (
	select
		s.*, cd.company_division, cr.company_regions
	from staff s
	left join 
		company_divisions cd
	on s.department = cd.department
	left join
		company_regions cr
	on 	s.region_id = cr.region_id
	)
;

select
	company_division
	,company_regions
	,gender
	,count(*)
from
	staff_div_reg
group by
	grouping sets (company_division, company_regions, gender)
order by
	company_regions, company_division, gender
;

drop view staff_div_reg
;

/* hierarcical subtotals using ROLLUP */

select
	company_regions, country, count(*)
from 
	staff_div_reg_country
group by
 	rollup(country, company_regions)
order by
	country, company_regions
;

/* subtotals for all hierachy combinations using CUBE */

select
	company_division, company_regions,  count(*)
from 
	staff_div_reg_country
group by
 	cube(company_division, company_regions)
order by
	company_division, company_regions
;

/* select top results using FETCH FIRST */

select
	company_division, count(*)
from
	staff_div_reg_country
group by
	company_division
order by
	count(*) desc
fetch first 5 rows only
;

/* working with strings */
select
	job_title, (lower(job_title) like '%assistant%') as is_assist
from
	staff
;

/* overlay or inserting text into a string */

select
	overlay(job_title placing 'Asst.' from 1 for length('assistant'))
from
	staff
where
	job_title similar to '%Assistant I_'
;

/* Regular expressions */

select
	job_title
from
	staff
where
	job_title similar to '[EPS]%'
;

/* summary statistics */

select
    department
	, sum(salary) as salary_total
	, round(avg(salary)) as salary_avg /* ceil - rounds up ; trunc - removes decimals */
	, round(var_pop(salary)) as salary_var 
	, round(stddev_pop(salary)) as salary_stddev
from 
	staff
group by
	department    
;

/*	These query samples provide an overview of the essential SQL commands required to perform intial data ETL tasks 
for further data analysis. Exercises modified from: https://www.linkedin.com/learning/advanced-sql-for-data-scientists/ */
