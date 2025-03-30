/*
# 题目32 雇员系列题2

```sql
表: Candidates
+---------------+------+
| Column Name   | Type |
+---------------+------+
| employee_id   | int  |
| experience    | enum |
| salary        | int  |
+---------------+------+
employee_id 是该表中具有唯一值的列。
经验是一个枚举，其中包含一个值 ("高级"，"初级")。
此表的每一行都显示候选人的id, 月薪和经验。
每个候选人的工资保证是 独一的。

一家公司想雇用新员工, 公司的工资预算是 $70000 , 公司的招聘标准是:
1.雇用尽可能多的高级候选人。
2.在剩余的预算中雇用尽可能多的初级候选人。

用解下的预算雇用薪水最低的初级候选人。
继续以最低的工资雇佣初级候选人，直到不能再雇佣更多的初级职员。
编写一个解决方案，查找根据上述条件雇用的职员的 ID。
按 ID 降序排序 返回结果。

返回结果格式如下例所示:

示例 1:
输入:
Candidates table:
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

输出:
+-------------+
| employee_id |
+-------------+
| 11          |
| 2           |
| 1           |
| 9           |
+-------------+

解释:
我们可以雇佣3名有经验的ID (11,2) 的高级员工，由于预算是7万美元，他们的工资总额是:$16,000 + $20,000 + $50,000 = $86,000 > $70,000, 我们只有3.6万美元，但他们不足以雇佣ID为 13 的高级员工。
我们可以雇佣2名ID为 (1,9) 的初级员工，由于剩余预算为3.4万美元，他们的工资总额为:1.0万美元 + 1.5万美元 = 2.5万美元，我们还有9000美元，但他们不足以雇佣ID为 4 的初级员工。

示例 2:
输入:
Candidates table:
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

输出:
+-------------+
| employee_id |
+-------------+
| 9           |
| 1           |
| 4           |
+-------------+

解释:
我们不能用目前的预算雇佣任何高级员工，因为我们需要至少 $80000 美元来雇佣一名高级员工。
我们可以用所有的预算雇佣所有三名初级员工。
```

*/

-- 方式1
with Candidates as (
  select 1 as employee_id, 'Junior' as experience, 25000 as salary union all
  select 9 as employee_id, 'Junior' as experience, 10000 as salary union all
  select 2 as employee_id, 'Senior' as experience, 85000 as salary union all
  select 11 as employee_id, 'Senior' as experience, 80000 as salary union all
  select 13 as employee_id, 'Senior' as experience, 90000 as salary union all
  select 4 as employee_id, 'Junior' as experience, 30000 as salary
),
    senior_list as (
        select employee_id,
               experience,
               salary,
               current_cost,
               current_amount,
               row_number() over (order by current_amount ) rn,
               1 flag
        from (
            select employee_id,
                   experience,
                   salary,
                   sum(salary) over (order by salary ) current_cost,
                   70000 - sum(salary) over (order by salary ) current_amount
            from Candidates
            where experience = 'Senior'
             ) t1
        where current_amount > 0
    ),
    availiable_amount as (
        select
            coalesce(b.current_amount, a.amount) amount
        from (
            select
            1 flag,
            70000 amount) a
        left join senior_list b
        on a.flag = b.flag and b.rn = 1
    ),
    junior_list as (
        select employee_id,
               experience,
               salary,
               current_cost,
               current_amount
        from (
            select employee_id,
                   experience,
                   salary,
                   sum(salary) over (order by salary ) current_cost,
                   availiable_amount.amount - sum(salary) over (order by salary ) current_amount
            from Candidates, availiable_amount
            where experience = 'Junior'
             ) t1
        where current_amount > 0
    )
select employee_id
from senior_list
union all
select employee_id
from junior_list;


-- 方式2
with Candidates as (
  select 1 as employee_id, 'Junior' as experience, 25000 as salary union all
  select 9 as employee_id, 'Junior' as experience, 10000 as salary union all
  select 2 as employee_id, 'Senior' as experience, 85000 as salary union all
  select 11 as employee_id, 'Senior' as experience, 80000 as salary union all
  select 13 as employee_id, 'Senior' as experience, 90000 as salary union all
  select 4 as employee_id, 'Junior' as experience, 30000 as salary
)
select employee_id
from
(select *,70000-sum(salary) over(order by experience_rk,salary) as sum_salary2
from
(select *,70000-sum(salary) over(partition by experience order by salary) as sum_salary,if(experience='Senior',1,2) as experience_rk
from candidates) t
where t.sum_salary>=0) t2
where t2.sum_salary2>=0
