/*

表: Project
+--------------------+
| Column Name | Type |
+--------------------+
| project_id | int |
| employee_id | int |
| workload | int |
+--------------------+
employee_id 是这张表的主键 (有不同值的列)。
employee_id 是 Employee 表的外键 (引用列)。
这张表的每一行表示 employee_id 所指的员工在 project_id 所指的项目上工作，以及项目的工作量。

表: Employees
+--------------------+
| Column Name | Type |
+--------------------+
| employee_id | int |
| name | varchar |
| team | varchar |
+--------------------+
employee_id 是这张表的主键 (有不同值的列)。
这张表的每一行包含一个员工的信息。
考虑一个方案，找出分配给项目工作量 超过各自团队 所有员工 平均工作量 的 员工，
返回结果集，以 employee_id, project_id 开序 排序。
结果格式如下所示。

示例 1:
输入:
Project 表:
+------------+-------------+----------+
| project_id | employee_id | workload |
+------------+-------------+----------+
| 1 | 1 | 45 |
| 1 | 2 | 90 |
| 2 | 3 | 12 |
| 2 | 4 | 68 |
+------------+-------------+----------+
Employees 表:
+-------------+-------+------+
| employee_id | name | team |
+-------------+-------+------+
| 1 | Khaled | A |
| 2 | Ali | B |
| 3 | John | B |
| 4 | Doe | A |
+-------------+-------+------+
输出:
+-------------+------------+--------------+------------------+
| employee_id | project_id | employee_name | project_workload |
+-------------+------------+--------------+------------------+
| 2 | 1 | Ali | 90 |
| 4 | 2 | Doe | 68 |
+-------------+------------+--------------+------------------+
解释:
- ID 为 1 的员工项目工作为 45 并属于 Team A, 其中均工作量为 56.50，因为该个项目工作量没有超过小组的平均工作量，他被排除。
- ID 为 2 的员工项目工作为 90 并属于 Team B, 其中均工作量为 51.00，因为该个项目工作量超过小组的平均工作量，他将包含在结果中。
- ID 为 3 的员工项目工作为 12 并属于 Team B, 其中均工作量为 51.00，因为该个项目工作量没有超过小组的平均工作量，他被排除。
- ID 为 4 的员工项目工作为 68 并属于 Team A, 其中均工作量为 56.50，因为该个项目工作量超过小组的平均工作量，他将包含在结果中。
结果按(employee_id, project_id) 开序排序。
*/


WITH Project AS (
    SELECT 1 as project_id, 1 as employee_id, 45 as workload UNION ALL
    SELECT 1, 2, 90 UNION ALL
    SELECT 2, 3, 12 UNION ALL
    SELECT 2, 4, 68
),
Employees AS (
    SELECT 1 as employee_id, 'Khaled' as name, 'A' as team UNION ALL
    SELECT 2, 'Ali', 'B' UNION ALL
    SELECT 3, 'John', 'B' UNION ALL
    SELECT 4, 'Doe', 'A'
),
    avg_siuattion as (
        select team,
               project_id,
               employee_id,
               employee_name,
               total_workload,
               avg(total_workload) over(partition by team) team_avg_workload
        from (
            SELECT
                t1.team,
                t2.project_id,
                t1.employee_id,
                t1.name employee_name,
                sum(coalesce(t2.workload, 0)) total_workload
            from Employees t1
            left join Project t2
            on t1.employee_id = t2.employee_id
            group by t1.team , t2. project_id, t1.employee_id, t1.name

             ) t1
    )
select
    employee_id,
    project_id,
    employee_name,
    total_workload
from avg_siuattion
where total_workload > team_avg_workload
order by employee_id,project_id;