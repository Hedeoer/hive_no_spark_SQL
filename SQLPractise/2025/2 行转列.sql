

/*

表: `student`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| name      | varchar |
| continent | varchar |
+-----------+---------+
```
该表可能包含重复的行。
该表的每一行表示学生的名字和他们来自的大陆。
一所学校有来自亚洲、欧洲和美洲的学生。
编写解决方案实现对大洲 (continent) 列的 透视表 操作，使得每个学生按照姓名的字母顺序依次排列在对应的大洲下面。输出的标题应依次为美洲 (America)、亚洲 (Asia) 和欧洲 (Europe)。
测试用例的生成保证来自美国的学生人数不少于亚洲或欧洲的学生人数。
返回结果格式如下所示。

示例 1:

输入:
`Student table`:
```
+--------+-----------+
| name   | continent |
+--------+-----------+
| Jane   | America   |
| Pascal | Europe    |
| Xi     | Asia      |
| Jack   | America   |
+--------+-----------+
```
输出:
```
+---------+------+--------+
| America | Asia | Europe |
+---------+------+--------+
| Jack    | Xi   | Pascal |
| Jane    | null | null   |
+---------+------+--------+
```


*/

WITH
-- 1. 模拟 student 表
Student AS (
    SELECT 'Jane' AS name, 'America' AS continent UNION ALL
    SELECT 'Pascal', 'Europe' UNION ALL
    SELECT 'Xi', 'Asia' UNION ALL
    SELECT 'Jack', 'America'
)
/*
    -- 方式1， join方式
    rn as (
        select name,
               continent,
               row_number() over (partition by continent order by name) as rn
        from Student t1
    ),
    america_student as (
        select
            *
        from rn t2
        where continent = 'America'
    ),
    asia_student as (
        select
            *
        from rn t2
        where continent = 'Asia'
    ),
    europe_student as (
        select
            *
        from rn t2
        where continent = 'Europe'
    )
select
    t1.name as America,
    t2.name as Asia,
    t3.name as Europe
from america_student t1
left join asia_student t2
on t1.rn = t2.rn
left join europe_student t3
on t1.rn = t3.rn;

*/

-- 方式2，group by方式
select
    max(case when continent = 'America' then name end) as America,
    max(case when continent = 'Asia' then name end) as Asia,
    max(case when continent = 'Europe' then name end) as Europe
from (
         select
             name,
             continent,
             row_number() over (partition by continent order by name) as rn
         from Student t1
     ) t2
group by rn;

