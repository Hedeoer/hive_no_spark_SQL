/*
员工表: `Employees`
```
+----------------+---------+
| Column Name    | Type    |
+----------------+---------+
| employee_id    | int     |
| employee_name  | varchar |
| manager_id     | int     |
+----------------+---------+
```
`employee_id` 是这个表具有唯一值的列。
这个表中每一行中, `employee_id` 表示职工的 ID, `employee_name` 表示职工的名字, `manager_id` 表示该职工汇报工作的直属经理。
这个公司 CEO 是 `employee_id = 1` 的人。

编写解决方案，找出所有直接或间接向公司 CEO 汇报工作的职工的 `employee_id` 。
由于公司规模较小，经理之间的间接关系 不超过 `3` 个经理。
可以以 任何顺序 返回无重复项的结果。
返回结果示例如下。

示例 1:

输入:
`Employees table`:
```
+-------------+---------------+------------+
| employee_id | employee_name | manager_id |
+-------------+---------------+------------+
| 1           | Boss          | 1          |
| 3           | Alice         | 1          |
| 2           | Bob           | 1          |
| 4           | Daniel        | 2          |
| 7           | Luis          | 4          |
| 8           | Jhon          | 3          |
| 9           | Angela        | 8          |
| 77          | Robert        | 1          |
+-------------+---------------+------------+
```
输出:
```
+-------------+
| employee_id |
+-------------+
| 77           |
| 2          |
| 3           |
| 8           |
| 4           |
+-------------+
```
解释:
公司 CEO 的 `employee_id` 是 1。
*/

WITH
-- 1. 模拟 Employees 表
Employees AS (
    SELECT 1 AS employee_id, 'Boss' AS employee_name, 1 AS manager_id UNION ALL
    SELECT 3, 'Alice', 1 UNION ALL
    SELECT 2, 'Bob', 1 UNION ALL
    SELECT 4, 'Daniel', 2 UNION ALL
    SELECT 7, 'Luis', 4 UNION ALL
    SELECT 8, 'Jhon', 3 UNION ALL
    SELECT 9, 'Angela', 8 UNION ALL
    SELECT 77, 'Robert', 1
),
-- 解法题目描述有出入
ceo as (
    select
        employee_id,
        concat('/',employee_id) path
    from Employees
    where manager_id = employee_id
),
level_1 as (
    select
        t2.employee_id,
        concat(t1.path,'/',t2.employee_id) path
    from ceo t1
             left join  Employees t2
                        on t1.employee_id = t2.manager_id and t1.employee_id != t2.employee_id
),
level_2 as (
    select
        t2.employee_id,
        concat(t1.path,'/',t2.employee_id) path
    from level_1 t1
             left join  Employees t2
                        on t1.employee_id = t2.manager_id
    where t2.employee_id is not null
),
level_3 as (
    select
        t2.employee_id,
        concat(t1.path,'/',t2.employee_id) path
    from level_2 t1
             left join  Employees t2
                        on t1.employee_id = t2.manager_id
    where t2.employee_id is not null
)
select
    employee_id
from (
         select * from ceo
         union all
         select * from level_1
         union all
         select * from level_2
         union all
         select * from level_3
     )
where size(split(path,'/')) > 2 and size(split(path,'/')) <= 4