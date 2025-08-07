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
每一行包含有关学生在特定考试日期特定科目成绩的信息。分数范围从 `0` 到 `100` (包括边界)。

编写一个解决方案来查找 `进步的`学生。如果 同时 满足以下两个条件，则该学生被认为是进步的:
*   在 同一科目 至少参加过两个不同日期的考试。
*   他们在该学科 最近的分数 比他们 第一次该学科考试的分数更高。

返回结果表以 `student_id`, `subject` 升序 排序。
结果格式如下所示。

示例:

输入:
`Scores` 表:
```
+------------+----------+-------+------------+
| student_id | subject  | score | exam_date  |
+------------+----------+-------+------------+
| 101        | Math     | 70    | 2023-01-15 |
| 101        | Math     | 85    | 2023-02-15 |
| 101        | Physics  | 65    | 2023-01-15 |
| 101        | Physics  | 60    | 2023-02-15 |
| 102        | Math     | 80    | 2023-01-15 |
| 102        | Math     | 85    | 2023-02-15 |
| 103        | Math     | 90    | 2023-01-15 |
| 104        | Physics  | 75    | 2023-01-15 |
| 104        | Physics  | 85    | 2023-02-15 |
+------------+----------+-------+------------+
```
输出:
```
+------------+----------+-------------+--------------+
| student_id | subject  | first_score | latest_score |
+------------+----------+-------------+--------------+
| 101        | Math     | 70          | 85           |
| 102        | Math     | 80          | 85           |
| 104        | Physics  | 75          | 85           |
+------------+----------+-------------+--------------+
```
解释:
学生 101 的数学: 从 70 分进步到 85 分。
学生 101 的物理: 没有进步 (从 65 分退步到 60分)
学生 102 的数学: 从 80 进步到 85 分。
学生 103 的数学: 只有一次考试，不符合资格。
学生 104 的物理: 从 75 分进步到 85 分。
结果表以 student_id, subject 升序排序。

*/


WITH
-- 1. 模拟 Scores 表
Scores AS (
    SELECT 101 AS student_id, 'Math' AS subject, 70 AS score, '2023-01-15' AS exam_date UNION ALL
    SELECT 101, 'Math',     85, '2023-02-15' UNION ALL
    SELECT 101, 'Physics',  65, '2023-01-15' UNION ALL
    SELECT 101, 'Physics',  60, '2023-02-15' UNION ALL
    SELECT 102, 'Math',     80, '2023-01-15' UNION ALL
    SELECT 102, 'Math',     85, '2023-02-15' UNION ALL
    SELECT 103, 'Math',     90, '2023-01-15' UNION ALL
    SELECT 104, 'Physics',  75, '2023-01-15' UNION ALL
    SELECT 104, 'Physics',  85, '2023-02-15'
)
-- 方式1
/*select
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
where t1.exam_date = (select min(exam_date) from Scores where student_id = t1.student_id and subject = t1.subject)
  and t2.exam_date = (select max(exam_date) from Scores where student_id = t2.student_id and subject = t2.subject)*/

-- 方式2
select student_id,
       subject,
       first_score,
       last_score
from (
         select
             t1.student_id,
             t1.subject,
             count(distinct t1.exam_date) over(partition by t1.student_id, t1.subject) as exam_count,
             first_value(t1.score) over(partition by t1.student_id, t1.subject order by t1.exam_date) as first_score,
             first_value(t1.score) over(partition by t1.student_id, t1.subject order by t1.exam_date desc) as last_score
         from Scores t1

     )t2
where t2.exam_count >= 2
  and t2.first_score < t2.last_score
group by t2.student_id,t2.subject,first_score,last_score
order by t2.student_id, t2.subject;

