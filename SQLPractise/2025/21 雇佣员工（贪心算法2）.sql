/*
表: `Candidates`
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| employee_id | int  |
| experience  | enum |
| salary      | int  |
+-------------+------+
```
`employee_id` 是该表中具有唯一值的列。
经验是一个枚举，其中包含一个值 ("高级"、"初级")。
此表的每一行都显示候选人的id、月薪和经验。
每个候选人的工资保证是唯一的。

一家公司想雇佣新员工。公司的工资预算是 `$70000`。公司的招聘标准是:
- 继续雇佣薪水最低的高级职员，直到你不能再雇佣更多的高级职员。
- 用剩下的预算雇佣薪水最低的初级职员。
- 继续以最低的工资雇佣初级职员，直到你不能再雇佣更多的初级职员。

编写一个解决方案，查找根据上述条件雇佣职员的 ID。
按 任意顺序 返回结果表。
返回结果格式如下例所示。

示例 1:
输入:
`Candidates table`:
```
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 10000  |
| 9           | Junior     | 15000  |
| 2           | Senior     | 20000  |
| 11          | Senior     | 16000  |
| 13          | Senior     | 50000  |
| 4           | Junior     | 40000  |
+-------------+------------+--------+
```
输出:
```
+-------------+
| employee_id |
+-------------+
| 11          |
| 2           |
| 1           |
| 9           |
+-------------+
```
解释:
我们可以雇佣2名具有ID (11,2) 的高级员工。由于预算是7万美元, 他们的工资总额是3.6万美元, 我们还有3.4万美元, 但他们不足以雇佣ID为 13 的高级职员。
我们可以雇佣2名ID为 (1,9) 的初级员工。由于剩余预算为3.4万美元, 他们的工资总额为2.5万美元, 我们还有9000美元, 但他们不足以雇佣ID为 4 的初级员工。

示例 2:
输入:
`Candidates table`:
```
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 25000  |
| 9           | Junior     | 10000  |
| 2           | Senior     | 85000  |
| 11          | Senior     | 80000  |
| 13          | Senior     | 90000  |
| 4           | Junior     | 30000  |
+-------------+------------+--------+
```
输出:
```
+-------------+
| employee_id |
+-------------+
| 9           |
| 1           |
| 4           |
+-------------+
```
解释:
我们不能用目前的预算雇佣任何高级员工，因为我们需要至少 80000 美元来雇佣一名高级员工。
我们可以用剩下的预算雇佣三名初级员工。

*/

WITH
-- 1. 模拟 Candidates 表数据
-- Candidates AS (
--     SELECT 1 AS employee_id, 'Junior' AS experience, 10000 AS salary UNION ALL
--     SELECT 9, 'Junior', 15000 UNION ALL
--     SELECT 2, 'Senior', 20000 UNION ALL
--     SELECT 11, 'Senior', 16000 UNION ALL
--     SELECT 13, 'Senior', 50000 UNION ALL
--     SELECT 4, 'Junior', 40000
-- ),
Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 25000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 85000 UNION ALL
    SELECT 11, 'Senior', 80000 UNION ALL
    SELECT 13, 'Senior', 90000 UNION ALL
    SELECT 4, 'Junior', 30000
),


hired_seniors as (
    select
        employee_id,
        cost
    from (
             select
                 employee_id,
                 sum(salary) over(order by salary) cost
             from Candidates t1
             where experience = 'Senior'
         ) t2
    where cost <= 70000
),
hired_juniors as (
    select
        employee_id,
        cost
    from (
             select
                 employee_id
                  , sum(salary) over(order by salary) cost
             from Candidates
             where experience = 'Junior'
         ) t1
    where cost <= 70000 - (select nvl(max(cost),0) from hired_seniors)
)
select
    employee_id
from hired_juniors
union  all
select
    employee_id
from hired_seniors;

-- 方式2
WITH
-- 1. 使用 WITH 子句模拟您提供的 Candidates 表数据
Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 25000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 85000 UNION ALL
    SELECT 11, 'Senior', 80000 UNION ALL
    SELECT 13, 'Senior', 90000 UNION ALL
    SELECT 4, 'Junior', 30000
)

/**
第一次SUM OVER(PARTITION BY ...)，在各自组内进行“预演”，淘汰掉那些仅靠本组力量都无法入围的候选人。
第二次SUM OVER()，在全局范围内，按我们之前创建的优先级 experience_rk 排序，如果优先级相同（即都是高级或都是初级），则再按薪资 salary 排序。
  这完美地实现了**“先按薪资从低到高排列所有（备选的）高级员工，然后紧接着按薪资从低到高排列所有（备选的）初级员工”**这一最终雇佣顺序。
 */
SELECT
    employee_id
FROM
    (
        SELECT
            *,
            70000 - SUM(salary) OVER(ORDER BY experience_rk, salary) AS sum_salary2
        FROM
            (
                SELECT
                    *,
                    70000 - SUM(salary) OVER(PARTITION BY experience ORDER BY salary) AS sum_salary,
                    IF(experience = 'Senior', 1, 2) AS experience_rk
                FROM
                    Candidates
            ) t
        WHERE t.sum_salary >= 0
    ) t2
WHERE t2.sum_salary2 >= 0;