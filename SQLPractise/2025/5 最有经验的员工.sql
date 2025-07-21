/*

项目表 `Project`:
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| project_id   | int     |
| employee_id  | int     |
+--------------+---------+
```
(project_id, employee_id) 是这个表的主键 (具有唯一值的列的组合)
`employee_id` 是员工表 `Employee` 的外键 (reference 列)
该表的每一行都表明具有 `employee_id` 的雇员正在处理具有 `project_id` 的项目。

员工表 `Employee`:
```
+------------------+---------+
| Column Name      | Type    |
+------------------+---------+
| employee_id      | int     |
| name             | varchar |
| experience_years | int     |
+------------------+---------+
```
`employee_id` 是这个表的主键 (具有唯一值的列)
该表的每一行都包含一名雇员的信息。

编写解决方案，报告在每一个项目中 经验最丰富 的雇员是谁。如果出现经验年数相同的情况，请报告所有具有最大经验年数的员工。
返回结果表 无顺序要求。
结果格式如下示例所示。

示例 1:

输入:
`Project` 表:
```
+-------------+-------------+
| project_id  | employee_id |
+-------------+-------------+
| 1           | 1           |
| 1           | 2           |
| 1           | 3           |
| 2           | 1           |
| 2           | 4           |
+-------------+-------------+
```
`Employee` 表:
```
+-------------+--------+------------------+
| employee_id | name   | experience_years |
+-------------+--------+------------------+
| 1           | Khaled | 3                |
| 2           | Ali    | 2                |
| 3           | John   | 3                |
| 4           | Doe    | 2                |
+-------------+--------+------------------+
```
输出:
```
+-------------+-------------+
| project_id  | employee_id |
+-------------+-------------+
| 1           | 1           |
| 1           | 3           |
| 2           | 1           |
+-------------+-------------+
```
解释: `employee_id` 为 1 和 3 的员工在 `project_id` 为 1 的项目中拥有最丰富的经验。在 `project_id` 为 2 的项目中，`employee_id` 为 1 的员工拥有最丰富的经验。*/

WITH
-- 1. 模拟 Project 表
Project AS (
    SELECT 1 AS project_id, 1 AS employee_id UNION ALL
    SELECT 1, 2 UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 2, 1 UNION ALL
    SELECT 2, 4
),

-- 2. 模拟 Employee 表
Employee AS (
    SELECT 1 AS employee_id, 'Khaled' AS name, 3 AS experience_years UNION ALL
    SELECT 2, 'Ali',    2 UNION ALL
    SELECT 3, 'John',   3 UNION ALL
    SELECT 4, 'Doe',    2
)
select
    project_id,
    employee_id
from (
         select
             t1.project_id,
             t1.employee_id,
             t2.experience_years,
             dense_rank() over (partition by t1.project_id order by t2.experience_years desc) as order_number
         from Project t1
                  left join Employee t2
                            on t1.employee_id = t2.employee_id
     ) t3
where order_number = 1;