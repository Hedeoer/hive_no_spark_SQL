
/*
表: `Employees`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| employee_id   | int     |
| employee_name | varchar |
| manager_id    | int     |
| salary        | int     |
| department    | varchar |
+---------------+---------+
```
`employee_id` 是这张表的唯一主键。
每一行包含关于一名员工的信息，包括他们的 ID, 姓名, 他们经理的 ID, 薪水和部门。
顶级经理 (CEO) 的 `manager_id` 是空的。

编写一个解决方案来分析组织层级并回答下列问题:
*   **层级:** 对于每名员工，确定他们在组织中的层级 (CEO 层级为 1, CEO 的直接下属员工层级为 2, 以此类推)。
*   **团队大小:** 对于每个是经理的员工，计算他们手下的 (直接或间接下属) 总员工数。
*   **薪资预算:** 对于每个经理，计算他们控制的总薪资预算 (所有手下员工的工资总和，包括间接下属，加上自己的工资)。

返回结果表以 `层级` 升序 排序, 然后以`预算` 降序 排序, 最后以 `employee_name` 升序 排序。
结果格式如下所示。

示例:
输入:
`Employees` 表:
```
+-------------+---------------+------------+--------+--------------+
| employee_id | employee_name | manager_id | salary | department   |
+-------------+---------------+------------+--------+--------------+
| 1           | Alice         | null       | 12000  | Executive    |
| 2           | Bob           | 1          | 10000  | Sales        |
| 3           | Charlie       | 1          | 10000  | Engineering  |
| 4           | David         | 2          | 7500   | Sales        |
| 5           | Eva           | 2          | 7500   | Sales        |
| 6           | Frank         | 3          | 9000   | Engineering  |
| 7           | Grace         | 3          | 8500   | Engineering  |
| 8           | Hank          | 4          | 6000   | Sales        |
| 9           | Ivy           | 6          | 7000   | Engineering  |
| 10          | Judy          | 6          | 7000   | Engineering  |
+-------------+---------------+------------+--------+--------------+
```
输出:
```
+-------------+---------------+-------+-----------+--------+
| employee_id | employee_name | level | team_size | budget |
+-------------+---------------+-------+-----------+--------+
| 1           | Alice         | 1     | 9         | 84500  |
| 3           | Charlie       | 2     | 4         | 41500  |
| 2           | Bob           | 2     | 3         | 31000  |
| 6           | Frank         | 3     | 2         | 23000  |
| 4           | David         | 3     | 1         | 13500  |
| 7           | Grace         | 3     | 0         | 8500   |
| 5           | Eva           | 3     | 0         | 7500   |
| 9           | Ivy           | 4     | 0         | 7000   |
| 10          | Judy          | 4     | 0         | 7000   |
| 8           | Hank          | 4     | 0         | 6000   |
+-------------+---------------+-------+-----------+--------+
```
解释:
组织结构: Alice (ID: 1) 是 CEO (层级 1) 没有经理。
Bob (ID: 2) 和 Charlie (ID: 3) 是 Alice 的直接下属 (层级 2)
David (ID: 4), Eva (ID: 5) 从属于 Bob, 而 Frank (ID: 6) 和 Grace (ID: 7) 从属于 Charlie (层级 3)
Hank (ID: 8) 从属于 David, 而 Ivy (ID: 9) 和 Judy (ID: 10) 从属于 Frank (层级 4)

层级计算: CEO (Alice) 层级为 1
每个后续的管理层级都会使层级数加 1

团队大小计算: Alice 手下有 9 个员工 (除她以外的整个公司)
Bob 手下有 3 个员工 (David, Eva 和 Hank)
Charlie 手下有 4 个员工 (Frank, Grace, Ivy 和 Judy)
Frank 手下有 2 个员工 (Ivy 和 Judy)
David 手下有 1 个员工 (Hank)
Eva, Grace, Hank, Ivy 和 Judy 没有直接下属 (team_size = 0)

预算计算: Alice 的预算: 她的工资 (12000) + 所有员工的工资 (72500) = 84500
Charlie 的预算: 他的工资 (10000) + Frank 的预算 (23000) + Grace 的工资 (8500) = 41500
Bob 的预算: 他的工资 (10000) + David 的预算 (13500) + Eva 的工资 (7500) = 31000
Frank 的预算: 他的工资 (9000) + Ivy 的工资 (7000) + Judy 的工资 (7000) = 23000
David 的预算: 他的工资 (7500) + Hank 的工资 (6000) = 13500
没有直接下属的员工的预算等于他们自己的工资。

注意:
结果先以层级升序排序
在同一层级内，员工按预算降序排序，然后按姓名升序排序
*/


/*
思路：
1. hive不支持递归查询，使用多层级的自连接来模拟递归，每家公司的层级是固定的。比如此处最高层级是4
2. 找出第一层，比如CEO层级， employeed_id, level, path(001,1,/001/)
2. 找出第二层，连接第一层的结果，得到 employeed_id, level, path(002,2,/001/002/)，以此类推
3. 将所有层级的结果合并成一个完整的层级信息表，比如

| employee_id | employee_name | Level | path         | salary |
|:------------|:--------------|:------|:-------------|:-------|
| 1           | Alice         | 1     | /1/          | 12000  |
| 2           | Bob           | 2     | /1/2/        | 10000  |
| 3           | Charlie       | 2     | /1/3/        | 10000  |
| 5           | Eva           | 3     | /1/2/5/      | 7500   |
| 4           | David         | 3     | /1/2/4/      | 7500   |
| 7           | Grace         | 3     | /1/3/7/      | 8500   |
| 6           | Frank         | 3     | /1/3/6/      | 9000   |
| 8           | Hank          | 4     | /1/2/4/8/    | 6000   |
| 10          | Judy          | 4     | /1/3/6/10/   | 7000   |
| 9           | Ivy           | 4     | /1/3/6/9/    | 7000   |

4. 补充薪水等信息，连接员工表和层级表， 比如 ceo的所有下属员工

| manager_id | manager_name | manager_level | manager_path | manager_salary | employee_id | employee_path |
|:-----------|:-------------|:--------------|:-------------|:---------------|:------------|:--------------|
| 1          | Alice        | 1             | /1/          | 12000          | 2           | /1/2/         |
| 1          | Alice        | 1             | /1/          | 12000          | 3           | /1/3/         |
| 1          | Alice        | 1             | /1/          | 12000          | 4           | /1/2/4/       |
| 1          | Alice        | 1             | /1/          | 12000          | 5           | /1/2/5/       |
| 1          | Alice        | 1             | /1/          | 12000          | 6           | /1/3/6/       |
| 1          | Alice        | 1             | /1/          | 12000          | 7           | /1/3/7/       |
| 1          | Alice        | 1             | /1/          | 12000          | 8           | /1/2/4/8/     |
| 1          | Alice        | 1             | /1/          | 12000          | 9           | /1/3/6/9/     |
| 1          | Alice        | 1             | /1/          | 12000          | 10          | /1/3/6/10/    |

5. 分组聚合 按照层级升序，预算降序，姓名升序排序输出结果

*/
WITH
-- 1. 模拟 Employees 表
Employees AS (
    SELECT 2 AS employee_id, 'Bob' AS employee_name, 1 AS manager_id, 10000 AS salary, 'Sales' AS department UNION ALL
    SELECT 1 AS employee_id, 'Alice' AS employee_name, null AS manager_id, 12000 AS salary, 'Executive' AS department UNION ALL
    SELECT 3, 'Charlie', 1, 10000, 'Engineering' UNION ALL
    SELECT 4, 'David', 2, 7500, 'Sales' UNION ALL
    SELECT 5, 'Eva', 2, 7500, 'Sales' UNION ALL
    SELECT 6, 'Frank', 3, 9000, 'Engineering' UNION ALL
    SELECT 7, 'Grace', 3, 8500, 'Engineering' UNION ALL
    SELECT 8, 'Hank', 4, 6000, 'Sales' UNION ALL
    SELECT 9, 'Ivy', 6, 7000, 'Engineering' UNION ALL
    SELECT 10, 'Judy', 6, 7000, 'Engineering'
),
level1 as (
    select
        employee_id,
        employee_name,
        1 as level,
        concat('/', employee_id, '/') as path,
        salary
    from Employees
    where manager_id is null
),
level2 as (
    select
        e.employee_id,
        e.employee_name,
        2 as level,
        concat(l1.path, e.employee_id, '/') as path,
        e.salary
    from Employees e
             join level1 l1 on e.manager_id = l1.employee_id
),
level3 as (
    select
        e.employee_id,
        e.employee_name,
        3 as level,
        concat(l2.path, e.employee_id, '/') as path,
        e.salary
    from Employees e
             join level2 l2 on e.manager_id = l2.employee_id
),
level4 as (
    select
        e.employee_id,
        e.employee_name,
        4 as level,
        concat(l3.path, e.employee_id, '/') as path,
        e.salary
    from Employees e
             join level3 l3 on e.manager_id = l3.employee_id
),
full_hierarchy as (
    select * from level1 union all
    select * from level2 union all
    select * from level3 union all
    select * from level4
)

select
    t2.employee_id,
    t2.employee_name,
    t2.level,
    -- team_size: 计算下属数量 (直接+间接)
    count(t3.employee_id) as team_size,
    -- budget: 计算薪资预算 (所有手下员工的工资总和，包括间接下属，加上自己的工资)
    nvl(sum(t3.salary),0) + t2.salary as budget
from full_hierarchy t2
         -- 获取每个职员的直接下属
         left join full_hierarchy t3 on t3.path like concat(t2.path, '%') and t2.employee_id != t3.employee_id
group by t2.employee_id,
         t2.employee_name,
         t2.salary,
         t2.level
order by t2.level asc,
         budget desc,
         t2.employee_name asc;

