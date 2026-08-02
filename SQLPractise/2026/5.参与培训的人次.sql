/*
某公司员工培训信息数据如下：

【表：员工培训信息表 cultivate_tb】
字段：info_id-信息id，staff_id-员工id，course-培训课程
注：该公司共开设了三门课程，员工可自愿参加任意门课程，每门课程每人可培训1次。
数据如下：
101 1 course1,course2
102 2 course2
103 3 course1,course3
104 4 course1,course2,course3
105 5 course3
106 6 NULL
107 7 course1,course2

【问题】
请统计该公司所有课程参加培训人次？

【示例数据结果如下】
staff_nums
11

解释：
course1课程共有员工1、3、4、7共4名员工培训；
course2课程共有员工1、2、4、7共4名员工培训；
course3课程共有员工3、4、5共3名员工培训；
共计 4+4+3=11 人次。
*/


WITH cultivate_tb AS (
    SELECT 101 AS info_id, 1 AS staff_id, 'course1,course2' AS course UNION ALL
    SELECT 102 AS info_id, 2 AS staff_id, 'course2' AS course UNION ALL
    SELECT 103 AS info_id, 3 AS staff_id, 'course1,course3' AS course UNION ALL
    SELECT 104 AS info_id, 4 AS staff_id, 'course1,course2,course3' AS course UNION ALL
    SELECT 105 AS info_id, 5 AS staff_id, 'course3' AS course UNION ALL
    SELECT 106 AS info_id, 6 AS staff_id, NULL AS course UNION ALL
    SELECT 107 AS info_id, 7 AS staff_id, 'course1,course2' AS course
)
-- ==========================================
-- 请在此处往下编写你的解答SQL
-- ==========================================

/*select
    count(distinct t2.staff_id,t2.inner_course)
from (
         select
             staff_id,
             course,
             pos_courses.inner_course
         from cultivate_tb t1
                  lateral view explode(split(t1.course,',')) pos_courses as inner_course
     ) t2;*/


select
    sum(array_size(staff_course_set))
from (

         select
             staff_id,
             array_distinct(flatten(collect_list(split(course,',')))) staff_course_set
         from cultivate_tb t1
         group by staff_id
     ) t2
;
