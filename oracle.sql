/* Course section effiency analysis to identify opportunities for section collapsing. */

select
so.*
,loc.building,
loc.BUILDING_DESC,
loc.room,
loc.room_capacity,
loc.max_room_capacity
  from (
      /* non-cross listed courses */
    select
      ACADEMIC_YEAR_DESC,
      ACADEMIC_PERIOD,
      ACADEMIC_PERIOD_DESC,
      case when substr(ACADEMIC_PERIOD,5,2) = '40' then 'Fall' when substr(ACADEMIC_PERIOD,5,2) = '20' then 'Spring' end as Term,
      CAMPUS,
      CAMPUS_DESC,
      COLLEGE,
      COLLEGE_DESC,
      DEPARTMENT,
      DEPARTMENT_DESC,
      SUBJECT,
      SUBJECT_DESC,
      COURSE_NUMBER,
      case when COURSE_NUMBER < '500' then 'UG' else 'GR' end as course_level,
      SUBJECT || COURSE_NUMBER as COURSE,
      TITLE_SHORT_DESC,
      COURSE_REFERENCE_NUMBER,
      SECTION_CROSS_LIST,
      SCHEDULE,
      SCHEDULE_DESC,
      INSTRUCTION_METHOD,
      INSTRUCTION_METHOD_DESC,
      STATUS_DESC,
      MAXIMUM_ENROLLMENT,
      CENSUS_ENROLLMENT1,
      1 as row_id
    from schedule_offering
    where academic_period >= '201540'
          and academic_period <= '201820'
          and substr(academic_period, 5, 2) in ('40', '20')
          and CAMPUS = 'M'
          and STATUS = 'A'
          and SECTION_CROSS_LIST IS NULL
          and CENSUS_ENROLLMENT1 > 0

    union
      
    /* combining cross-listed courses */  
    select
      ACADEMIC_YEAR_DESC,
      ACADEMIC_PERIOD,
      ACADEMIC_PERIOD_DESC,
      case when substr(ACADEMIC_PERIOD,5,2) = '40' then 'Fall' when substr(ACADEMIC_PERIOD,5,2) = '20' then 'Spring' end as Term,
      CAMPUS,
      CAMPUS_DESC,
      COLLEGE,
      COLLEGE_DESC,
      DEPARTMENT,
      DEPARTMENT_DESC,
      SUBJECT,
      SUBJECT_DESC,
      COURSE_NUMBER,
      case when COURSE_NUMBER < '500' then 'UG' else 'GR' end as course_level,
      SUBJECT || COURSE_NUMBER as COURSE,
      TITLE_SHORT_DESC,
      COURSE_REFERENCE_NUMBER,
      SECTION_CROSS_LIST,
      SCHEDULE,
      SCHEDULE_DESC,
      INSTRUCTION_METHOD,
      INSTRUCTION_METHOD_DESC,
      STATUS_DESC,
      MAXIMUM_ENROLLMENT,
      sum(CENSUS_ENROLLMENT1)
      over (
        partition by ACADEMIC_PERIOD, SECTION_CROSS_LIST )  CENSUS_ENROLLMENT1,
      row_number()
      over (
        partition by ACADEMIC_PERIOD, SECTION_CROSS_LIST
        order by COURSE_REFERENCE_NUMBER )               as row_id
    from schedule_offering
    where academic_period >= '201540'
          and academic_period <= '201820'
          and substr(academic_period, 5, 2) in ('40', '20')
          and CAMPUS = 'M'
          and STATUS = 'A'
          and SECTION_CROSS_LIST IS NOT NULL
          and CENSUS_ENROLLMENT1 > 0
  ) so
left join ( /* capture primary room assignment */
    select *
  from (
      select
          academic_period,
          course_reference_number,
          course_identification || SUBSTR(SCHEDULE, 1, 1) AS COURSE,
          building,
          BUILDING_DESC,
          room,
          case when SLBRDEF_CAPACITY = '999' then null else SLBRDEF_CAPACITY end as room_capacity,
          case when SLBRDEF_MAXIMUM_CAPACITY = '999' then null else SLBRDEF_MAXIMUM_CAPACITY end as max_room_capacity,
          rank()
          over (
              partition by academic_period, course_reference_number
              order by SLBRDEF_MAXIMUM_CAPACITY ) as max_cap_rank,
          row_number() over ( partition by academic_period, course_reference_number, building, room
              order by SLBRDEF_MAXIMUM_CAPACITY ) as row_id
      from meeting_time mt
          left join slbrdef b
              on mt.building = b.slbrdef_bldg_code
                 and mt.room = b.slbrdef_room_number
      where academic_period >= '201540'
            and academic_period <= '201820'
            and substr(academic_period, 5, 2) in ('40', '20')
            and meeting_type = 'CLAS'
    )
      where max_cap_rank = 1
      and row_id = 1
) loc
on so.academic_period = loc.academic_period
  and so.course_reference_number = loc.course_reference_number

where so.row_id = 1

;


/*  Course section planning for highest enrolled courses among first time undergraduate students. */

with a as (
    /* initial term courses for first time undergraduate students */
    select
    scr.academic_year_desc
    ,scr.academic_period
    ,scr.course_identification
    ,scr.course_title_short
    ,scr.course_reference_number
    ,so.CAMPUS_DESC
    ,so.COLLEGE
    ,so.MAXIMUM_ENROLLMENT
    ,so.census_enrollment1
    ,scr.id
    ,rank() over (partition by scr.id order by scr.academic_period) as term_seq
    from student_course scr
    left join schedule_offering so
        on scr.academic_period = so.academic_period
        and scr.course_reference_number = so.course_reference_number
    left join cipe_student s
        on scr.id = s.id
        and scr.academic_period = s.academic_period
    where scr.academic_period >= '201540'
        and scr.academic_period <= '201740'
        and substr(scr.academic_period,5,2) = '40'
        and scr.transfer_course_ind = 'N'
        and scr.register_census_date1_ind = 'Y'
        and scr.course_level = 'UG'
        and so.schedule = 'L'
        and scr.campus = 'M'
        and s.student_population = 'F'
        and s.student_classification_boap = 'FR'
    )
    , e as (
        /* room assignment capacity */
    select
    mt.academic_period 
    ,mt.COURSE_REFERENCE_NUMBER
    ,SLBRDEF_BLDG_CODE as building
    ,BUILDING_DESC
    ,SLBRDEF_ROOM_NUMBER as room
    ,SLBRDEF_CAPACITY as capacity
    ,SLBRDEF_MAXIMUM_CAPACITY as max_capacity
    ,max(meeting_hours)
    from meeting_time mt
    left join slbrdef b
        on mt.building = b.slbrdef_bldg_code 
        and mt.room = b.slbrdef_room_number
    where mt.academic_period >= '201540'
        and mt.academic_period <= '201740'
        and substr(mt.academic_period,5,2) = '40'
    group by mt.academic_period, mt.COURSE_REFERENCE_NUMBER, SLBRDEF_BLDG_CODE, BUILDING_DESC, SLBRDEF_ROOM_NUMBER, SLBRDEF_CAPACITY
    ,SLBRDEF_MAXIMUM_CAPACITY
    )
/* top 20 courses for cohort proportion enrolled in  and calculate  */    
select
a.academic_year_desc
,a.academic_period
,a.campus_desc
,a.course_identification
,a.course_title_short
,a.college
,a.course_reference_number
,b.enrollment_rank
,d.pop_course_enrollment
,c.cohort_pop
,round(d.pop_course_enrollment / c.cohort_pop,4) as ""1_population_pct_of_cohort""
,round(avg(d.pop_course_enrollment / c.cohort_pop) over (partition by a.course_identification),4) as ""1_fall_2015-2017_avg""
,a.census_enrollment1 as total_class_enrollment
,round(d.pop_course_enrollment / a.census_enrollment1,4) as ""2_pop_pct_of_class_enrollment""
,round(avg(d.pop_course_enrollment / a.census_enrollment1) over (partition by a.course_identification),4) as ""2_fall_2015-2017_avg""
,a.maximum_enrollment as sched_max_enrollment
,round(d.pop_course_enrollment / nullif(a.maximum_enrollment,0),4) as ""3_enrollment_pct_of_max""
,round(avg(d.pop_course_enrollment / nullif(a.maximum_enrollment,0)) over (partition by a.course_identification),4) as ""3_fall_2015-2017_avg""
,e.building
,e.room
,e.capacity
,round(d.pop_course_enrollment / e.capacity,4) as ""4_enrollment_pct_of_capacity""
,round(avg(d.pop_course_enrollment / e.capacity) over (partition by a.course_identification),4) as ""4_fall_2015-2017_avg""
,e.max_capacity
,round(d.pop_course_enrollment / e.max_capacity,4) as ""5_enrollment_pct_of_max_cap""
,round(avg(d.pop_course_enrollment / e.max_capacity) over (partition by a.course_identification),4) as ""5_fall_2015-2017_avg""
 from a 
left join ( /* cohort population */
        select academic_period, count(distinct id) as cohort_pop
        from a where term_seq = 1
        group by academic_period
        ) c
    on a.academic_period = c.academic_period
left join ( /* cohort course enrollment */
        select academic_period, course_identification, course_reference_number, count(id) as pop_course_enrollment
        from a where term_seq = 1
        group by academic_period, course_identification, course_reference_number
        ) d
    on a.academic_period = d.academic_period
    and a.course_reference_number = d.course_reference_number
left join ( /* course enrollment ranking for population */
    select course_identification
        ,rank() over (order by sum(pop_course_enrollment) desc) enrollment_rank  
        from (select academic_period, course_identification, course_reference_number, count(id) as pop_course_enrollment
            from a where term_seq = 1
            group by academic_period, course_identification, course_reference_number
            )
        group by course_identification
        ) b
    on a.course_identification = b.course_identification
left join e
    on a.academic_period = e.academic_period
    and a.course_reference_number = e.course_reference_number
where a.term_seq = 1
and b.enrollment_rank <= 20
order by academic_year_desc, a.academic_period, enrollment_rank
