use base_ex;
/*
某公司员工信息表及员工培训信息表如下：

【表1：员工信息表 staff_tb】
字段：staff_id-员工id，staff_name-员工姓名，staff_gender-员工性别，post-员工岗位职务，department-员工所在部门
数据如下：
1 Angus male Financial dep1
2 Cathy female Director dep1
3 Miki female Director dep2
4 Lawson male Engineer dep1
5 Earl male Engineer dep2
6 Ben male Engineer dep1
7 Nura female Director dep2

【表2：员工培训信息表 cultivate_tb】
字段：info_id-培训信息id，staff_id-员工id，course-培训课程
注：该员工只培训了一门课程，该列只写课程名称；多门培训的话，互相用逗号分隔（含有空格）。
数据如下：
101 1 course1, course2
102 2 course2
103 3 course1, course3
104 4 course1, course2, course3
105 5 course3
106 6 NULL
107 7 course1, course2

【问题】
请查询培训课程带 course3 的员工信息？
输出列：staff_id，staff_name
排序要求：按 staff_id 升序排列

【示例数据结果如下】
staff_id  staff_name
3         Miki
4         Lawson
5         Earl

解释：有员工3、4、5培训了course3课程，故结果如上。
*/

WITH staff_tb AS (
    SELECT 1 AS staff_id, 'Angus' AS staff_name, 'male' AS staff_gender, 'Financial' AS post, 'dep1' AS department UNION ALL
    SELECT 2 AS staff_id, 'Cathy' AS staff_name, 'female' AS staff_gender, 'Director' AS post, 'dep1' AS department UNION ALL
    SELECT 3 AS staff_id, 'Miki' AS staff_name, 'female' AS staff_gender, 'Director' AS post, 'dep2' AS department UNION ALL
    SELECT 4 AS staff_id, 'Lawson' AS staff_name, 'male' AS staff_gender, 'Engineer' AS post, 'dep1' AS department UNION ALL
    SELECT 5 AS staff_id, 'Earl' AS staff_name, 'male' AS staff_gender, 'Engineer' AS post, 'dep2' AS department UNION ALL
    SELECT 6 AS staff_id, 'Ben' AS staff_name, 'male' AS staff_gender, 'Engineer' AS post, 'dep1' AS department UNION ALL
    SELECT 7 AS staff_id, 'Nura' AS staff_name, 'female' AS staff_gender, 'Director' AS post, 'dep2' AS department
),
     cultivate_tb AS (
         SELECT 101 AS info_id, 1 AS staff_id, 'course1, course2' AS course UNION ALL
         SELECT 102 AS info_id, 2 AS staff_id, 'course2' AS course UNION ALL
         SELECT 103 AS info_id, 3 AS staff_id, 'course1, course3' AS course UNION ALL
         SELECT 104 AS info_id, 4 AS staff_id, 'course1, course2, course3' AS course UNION ALL
         SELECT 105 AS info_id, 5 AS staff_id, 'course3' AS course UNION ALL
         SELECT 106 AS info_id, 6 AS staff_id, NULL AS course UNION ALL
         SELECT 107 AS info_id, 7 AS staff_id, 'course1, course2' AS course
     )
-- ==========================================
-- 请在此处往下编写你的解答SQL
-- 下方为参考答案，为防止剧透你可以先遮挡下方代码
-- ==========================================
-- 培训表中转化为数组；inner join；去重
select
    distinct
    t2.staff_id,
    t2.staff_name
from cultivate_tb t1
         inner join staff_tb t2
                    on array_contains(split(t1.course,',\\s+'),'course3') and t1.staff_id = t2.staff_id
order by t2.staff_id;
