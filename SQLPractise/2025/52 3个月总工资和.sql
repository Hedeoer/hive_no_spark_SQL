/*
表: `Employee`
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| id          | int  |
| month       | int  |
| salary      | int  |
+-------------+------+
```
(id, month) 是该表的主键(具有唯一值的列的组合)。
表中的每一行表示 2020 年期间员工一个月的工资。
编写一个解决方案，在一个统一的表中计算出每个员工的 累计工资汇总。
员工的 累计工资汇总 可以计算如下:

对于该员工工作的每个月，将 该月 和 前两个月 的工资 加 起来。这是他们当月的 3 个月总工资和。如果员工在前几个月没有为公司工作，那么他们在前几个月的有效工资为 `0`。
不要 在摘要中包括员工 最近一个月的 3 个月总工资和。
不要 包括雇员 没有工作 的任何一个月的 3 个月总工资和。
返回按 `id` 升序排序 的结果表。如果 `id` 相等，请按 `month` 降序排序。
结果格式如下所示。

示例 1:
输入:
`Employee table`:
```
+----+-------+--------+
| id | month | salary |
+----+-------+--------+
| 1  | 1     | 20     |
| 2  | 1     | 20     |
| 1  | 2     | 30     |
| 2  | 2     | 30     |
| 3  | 2     | 40     |
| 1  | 3     | 40     |
| 3  | 3     | 60     |
| 1  | 4     | 60     |
| 3  | 4     | 70     |
| 1  | 7     | 90     |
| 1  | 8     | 90     |
+----+-------+--------+
```
输出:
```
+----+-------+--------+
| id | month | Salary |
+----+-------+--------+
| 1  | 7     | 90     |
| 1  | 4     | 130    |
| 1  | 3     | 90     |
| 1  | 2     | 50     |
| 1  | 1     | 20     |
| 2  | 1     | 20     |
| 3  | 3     | 100    |
| 3  | 2     | 40     |
+----+-------+--------+
```
解释:
员工 “1” 有 5 条工资记录，不包括最近一个月的“8”:
- 第 ‘7’ 个月为 90。
- 第 ‘4’ 个月为 60。
- 第 ‘3’ 个月是 40。
- 第 ‘2’ 个月为 30。
- 第 ‘1’ 个月为 20。
因此, 该员工的累计工资汇总为:
```
+----+-------+--------+
| id | month | salary |
+----+-------+--------+
| 1  | 7     | 90     | (90 + 0 + 0)
| 1  | 4     | 130    | (60 + 40 + 30)
| 1  | 3     | 90     | (40 + 30 + 20)
| 1  | 2     | 50     | (30 + 20 + 0)
| 1  | 1     | 20     | (20 + 0 + 0)
+----+-------+--------+
```
请注意，‘7’ 月的 3 个月的总和是 90, 因为他们没有在 ‘6’ 月或 ‘5’ 月工作。

员工 ‘2’ 只有一个工资记录(‘1’ 月)，不包括最近的 ‘2’ 月。
```
+----+-------+--------+
| id | month | salary |
+----+-------+--------+
| 2  | 1     | 20     | (20 + 0 + 0)
+----+-------+--------+
```
员工 ‘3’ 有两个工资记录，不包括最近一个月的 ‘4’ 月:
- 第 ‘3’ 个月为 60。
- 第 ‘2’ 个月是 40。
因此, 该员工的累计工资汇总为:
```
+----+-------+--------+
| id | month | salary |
+----+-------+--------+
| 3  | 3     | 100    | (60 + 40 + 0)
| 3  | 2     | 40     | (40 + 0 + 0)
+----+-------+--------+
```
*/

WITH
-- 1. 模拟 Employee 表数据
Employee AS (
    SELECT 1 AS id, 1 AS month, 20 AS salary UNION ALL
    SELECT 2, 1, 20 UNION ALL
    SELECT 1, 2, 30 UNION ALL
    SELECT 2, 2, 30 UNION ALL
    SELECT 3, 2, 40 UNION ALL
    SELECT 1, 3, 40 UNION ALL
    SELECT 3, 3, 60 UNION ALL
    SELECT 1, 4, 60 UNION ALL
    SELECT 3, 4, 70 UNION ALL
    SELECT 1, 7, 90 UNION ALL
    SELECT 1, 8, 90
)
select
    id,
    month,
    salary + if(previous_month + 1 = month,previous_salary,0) + if(pre_previous_month + 1= previous_month,pre_previous_salary,0) salary
from (
         select id,
                month,
                salary,
                lag(salary,1,0) over(partition by id order by month) previous_salary,
                lag(month,1) over(partition by id order by month) previous_month,
                lag(salary,2,0) over(partition by id order by month) pre_previous_salary,
                lag(month,2) over(partition by id order by month) pre_previous_month,
                lead(salary,1) over(partition by id order by month) next_salary
         from Employee t1
     ) t2
where next_salary is not null

