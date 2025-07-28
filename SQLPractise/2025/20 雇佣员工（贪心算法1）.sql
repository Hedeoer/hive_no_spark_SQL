/*
表: `Candidates`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| employee_id | int      |
| experience  | enum     |
| salary      | int      |
+-------------+----------+
```
`employee_id`是此表的主键列。
经验是包含一个值 (“高级”、“初级”) 的枚举类型。
此表的每一行都显示候选人的id、月薪和经验。

一家公司想雇佣新员工。公司的工资预算是 `70000` 美元。公司的招聘标准是:
在雇佣最多的高级员工后，使用剩余预算雇佣最多的初级员工。
编写一个SQL查询，查找根据上述标准雇佣的高级员工和初级员工的数量。
按 任意顺序 返回结果表。
查询结果格式如下例所示。

示例 1:
输入:
`Candidates table`:
```
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 10000  |
| 9           | Junior     | 10000  |
| 2           | Senior     | 20000  |
| 11          | Senior     | 20000  |
| 13          | Senior     | 50000  |
| 4           | Junior     | 40000  |
+-------------+------------+--------+
```
输出:
```
+------------+-----------------------+
| experience | accepted_candidates   |
+------------+-----------------------+
| Senior     | 2                     |
| Junior     | 2                     |
+------------+-----------------------+
```
说明:
我们可以雇佣2名ID为 `(2,11)` 的高级员工。由于预算是7万美元，他们的工资总额是4万美元，我们还有3万美元，但他们不足以雇佣ID为`13`的高级员工。
我们可以雇佣2名ID为 `(1,9)` 的初级员工。由于剩下的预算是3万美元，他们的工资总额是2万美元，我们还有1万美元，但他们不足以雇佣ID为`4`的初级员工。

示例 2:
输入:
`Candidates table`:
```
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 10000  |
| 9           | Junior     | 10000  |
| 2           | Senior     | 80000  |
| 11          | Senior     | 80000  |
| 13          | Senior     | 80000  |
| 4           | Junior     | 40000  |
+-------------+------------+--------+
```
输出:
```
+------------+-----------------------+
| experience | accepted_candidates   |
+------------+-----------------------+
| Senior     | 0                     |
| Junior     | 3                     |
+------------+-----------------------+
```
解释:
我们不能用目前的预算雇佣任何高级员工，因为我们需要至少80000美元来雇佣一名高级员工。
我们可以用剩下的预算雇佣三名初级员工。
*/

WITH
-- 1. 模拟 Candidates 表
/*Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 10000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 20000 UNION ALL
    SELECT 11, 'Senior', 20000 UNION ALL
    SELECT 13, 'Senior', 50000 UNION ALL
    SELECT 4, 'Junior', 40000
),*/
Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 10000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 80000 UNION ALL
    SELECT 11, 'Senior', 80000 UNION ALL
    SELECT 13, 'Senior', 80000 UNION ALL
    SELECT 4, 'Junior', 40000
),
-- 获取所有经验级别
levels as (
    select
        distinct experience
    from Candidates
),
-- 计算高级候选人的当前余额
senior_candidates AS (
    select
        employee_id,
        current_balance
    from (
             SELECT employee_id, salary,
                    70000 - sum(salary) OVER (ORDER BY salary) AS current_balance
             FROM Candidates
             WHERE experience = 'Senior'
             ORDER BY salary
         ) t1
    where current_balance >= 0
),
-- 计算高级候选人的当前余额，如果没有高级候选人，则设置最小余额为70000
balance as (
    select
        nvl(min(current_balance),70000) as min_balance
    from senior_candidates
),
-- 计算初级候选人的当前余额
junior_candidates AS (
    select
        employee_id,
        current_balance
    from (
             SELECT employee_id, salary,
                    balance.min_balance - sum(salary) OVER (ORDER BY salary) AS current_balance
             FROM Candidates,balance
             WHERE experience = 'Junior'
             ORDER BY salary
         ) t1
    where current_balance >= 0
)
-- 最终查询，统计每个经验级别的候选人数量
select
    tt.experience,
    nvl(t1.accepted_candidates, 0) as accepted_candidates
from levels tt
         left join (
    select
        'Senior' as experience,
        count(*) as accepted_candidates
    from senior_candidates
    union all
    select
        'Junior' as experience,
        count(*) as accepted_candidates
    from junior_candidates
) t1 on tt.experience = t1.experience;

