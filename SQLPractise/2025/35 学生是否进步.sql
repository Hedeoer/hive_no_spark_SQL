/*
表: `Scores`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| student_id  | int     |
| subject     | varchar |
| score       | int     |
| exam_date   | varchar |
+-------------+---------+
```
(student_id, subject, exam_date) 是这张表的主键。
每一行包含有关学生在特定考试日期特定科目成绩的信息。分数范围从 0 到 100 (包括边界)。
编写一个解决方案来查找 进步的 学生。如果 同时 满足以下两个条件，则该学生被认为是进步的:
在 同一科目 至少参加过两个不同日期的考试。
他们在该学科 最近的分数 比他们 第一次 该学科考试的分数更高。
返回结果表以 student_id, subject 升序 排序。
结果格式如下所示。

示例:
输入:
`Scores` 表:
```
+------------+---------+-------+------------+
| student_id | subject | score | exam_date  |
+------------+---------+-------+------------+
| 101        | Math    | 70    | 2023-01-15 |
| 101        | Math    | 85    | 2023-02-15 |
| 101        | Physics | 65    | 2023-01-15 |
| 101        | Physics | 60    | 2023-02-15 |
| 102        | Math    | 80    | 2023-01-15 |
| 103        | Math    | 90    | 2023-01-15 |
| 104        | Physics | 75    | 2023-01-15 |
| 104        | Physics | 85    | 2023-02-15 |
+------------+---------+-------+------------+
```
输出:
```
+------------+---------+-------------+--------------+
| student_id | subject | first_score | latest_score |
+------------+---------+-------------+--------------+
| 101        | Math    | 70          | 85           |
| 104        | Physics | 75          | 85           |
+------------+---------+-------------+--------------+
```
解释:
学生 101 的数学: 从 70 分进步到 85 分。
学生 101 的物理: 没有进步 (从 65 分退步到 60分)
学生 103 的数学: 只有一次考试, 不符合资格。
学生 104 的物理: 从 75 分进步到 85 分。
结果表以 student_id, subject 升序排序。
*/

-- 方式1 ：错误解法，只考虑了最近一次考试成绩相比第一次考试成绩的情况，没有考虑到可能存在多次考试的情况。
WITH
-- 1. 模拟 Scores 表
Scores AS (
    SELECT 101 AS student_id, 'Math' AS subject, 70 AS score, CAST('2023-01-15' AS DATE) AS exam_date UNION ALL
    SELECT 101, 'Math',    85, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 65, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 60, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 102, 'Math',    80, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 103, 'Math',    90, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 75, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 85, CAST('2023-02-15' AS DATE)
)
select student_id,
       subject,
       first_score,
       latest_score
from (
         select
             student_id,
             subject,
             first_score,
             latest_score

         from (
                  select student_id,
                         subject,
                         score,
                         exam_date,
                         count(1) over(partition by student_id ,subject) per_num,
                         first_value(score) over(partition by student_id,subject order by exam_date) first_score,
                         first_value(score) over(partition by student_id,subject order by exam_date desc) latest_score
                  from Scores t1

              ) t2
         where per_num > 1 and latest_score > first_score
     ) t3
group by student_id,subject,first_score,latest_score
order by student_id,subject;

-- 方式2: 使用自连接
WITH
-- 1. 模拟 Scores 表
Scores AS (
    SELECT 101 AS student_id, 'Math' AS subject, 70 AS score, CAST('2023-01-15' AS DATE) AS exam_date UNION ALL
    SELECT 101, 'Math',    85, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 65, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 60, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 102, 'Math',    80, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 103, 'Math',    90, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 75, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 85, CAST('2023-02-15' AS DATE)
)
select
    t1.student_id,
    t1.subject,
    t1.score as first_score,
    t2.score as latest_score
from Scores t1
         inner join Scores t2
                    on t1.student_id = t2.student_id
                        and t1.subject = t2.subject
                        and t1.exam_date < t2.exam_date
                        and t1.score < t2.score
order by t1.student_id, t1.subject;

