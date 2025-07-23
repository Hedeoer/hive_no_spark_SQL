
/*

表: `Student`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| student_id    | int     |
| student_name  | varchar |
+---------------+---------+
```
`student_id` 是该表主键(具有唯一值的列)。
`student_name` 学生名字。

表: `Exam`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| exam_id     | int     |
| student_id  | int     |
| score       | int     |
+-------------+---------+
```
(exam_id, student_id) 是该表主键(具有唯一值的列的组合)。
学生 `student_id` 在测验 `exam_id` 中得分为 `score`。

成绩处于中游的学生是指至少参加了一次测验，且得分既不是最高分也不是最低分的学生。

编写解决方案，找出在 所有 测验中都处于中游的学生 (`student_id`, `student_name`)。不要返回从来没有参加过测验的学生。
返回结果表按照 `student_id` 排序。
结果格式如下。

示例 1:

输入:
`Student` 表:
```
+------------+--------------+
| student_id | student_name |
+------------+--------------+
| 1          | Daniel       |
| 2          | Jade         |
| 3          | Stella       |
| 4          | Jonathan     |
| 5          | Will         |
+------------+--------------+
```
`Exam` 表:
```
+---------+------------+-------+
| exam_id | student_id | score |
+---------+------------+-------+
| 10      | 1          | 70    |
| 10      | 2          | 80    |
| 10      | 3          | 90    |
| 20      | 1          | 80    |
| 30      | 1          | 70    |
| 30      | 3          | 80    |
| 30      | 4          | 90    |
| 40      | 1          | 60    |
| 40      | 2          | 70    |
| 40      | 4          | 80    |
+---------+------------+-------+
```
输出:
```
+------------+--------------+
| student_id | student_name |
+------------+--------------+
| 2          | Jade         |
+------------+--------------+
```
解释:
对于测验 1: 学生 1 和 3 分别获得了最低分和最高分。
对于测验 2: 学生 1 既获得了最高分，也获得了最低分。
对于测验 3 和 4: 学生 1 和 4 分别获得了最低分和最高分。
学生 2 和 5 没有在任一场测验中获得了最高分或者最低分。
因为学生 5 从来没有参加过任何测验，所以他被排除于结果表。
由此，我们仅仅返回学生 2 的信息。

*/

WITH
-- 1. 模拟 Student 表
Student AS (
    SELECT 1 AS student_id, 'Daniel' AS student_name UNION ALL
    SELECT 2, 'Jade' UNION ALL
    SELECT 3, 'Stella' UNION ALL
    SELECT 4, 'Jonathan' UNION ALL
    SELECT 5, 'Will'
),

-- 2. 模拟 Exam 表
Exam AS (
    SELECT 10 AS exam_id, 1 AS student_id, 70 AS score UNION ALL
    SELECT 10, 2, 80 UNION ALL
    SELECT 10, 3, 90 UNION ALL
    SELECT 20, 1, 80 UNION ALL
    SELECT 30, 1, 70 UNION ALL
    SELECT 30, 3, 80 UNION ALL
    SELECT 30, 4, 90 UNION ALL
    SELECT 40, 1, 60 UNION ALL
    SELECT 40, 2, 70 UNION ALL
    SELECT 40, 4, 80
)

select
    distinct
    t3.student_id,
    t4.student_name
from Student t4  left join (
    select
        exam_id,
        student_id,
        score_rank
    from (
             -- 计算每个学生在每次考试中的得分排名
             select
                 exam_id,
                 student_id,
                 dense_rank() over (partition by exam_id order by score) score_rank,
                 max(dense_rank() over (partition by exam_id order by score)) over (partition by exam_id) max_score_rank
             from Exam t1
         ) t2
    -- 过滤出得分既不是最高分也不是最低分的学生
    where max_score_rank >= 3 and t2.score_rank > 1 and t2.score_rank < max_score_rank
) t3
                           on t4.student_id = t3.student_id
-- 过滤掉从来没有参加过测验的学生
where t3.student_id is not null
order by t3.student_id;
