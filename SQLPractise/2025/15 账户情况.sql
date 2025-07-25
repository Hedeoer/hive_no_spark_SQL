
/*
账户情况
表: `Accounts`
```
+-------------+---------+
| 列名        | 类型    |
+-------------+---------+
| account_id  | int     |
| income      | int     |
+-------------+---------+
```
在 SQL 中, `account_id` 是这个表的主键。
每一行都包含一个银行帐户的月收入的信息。
查询每个工资类别的银行账户数量。工资类别如下:
- "Low Salary": 所有工资 严格低于 20000 美元。
- "Average Salary": 包含 范围内的所有工资 [\$20000, \$50000] 。
- "High Salary": 所有工资 严格大于 50000 美元。
结果表 必须 包含所有三个类别。 如果某个类别中没有帐户，则报告 0 。
按 任意顺序 返回结果表。
查询结果格式如下示例。

示例 1:

输入:
`Accounts` 表:
```
+-------------+--------+
| account_id  | income |
+-------------+--------+
| 3           | 108939 |
| 2           | 12747  |
| 8           | 87709  |
| 6           | 91796  |
+-------------+--------+
```
输出:
```
+----------------+----------------+
| category       | accounts_count |
+----------------+----------------+
| Low Salary     | 1              |
| Average Salary | 0              |
| High Salary    | 3              |
+----------------+----------------+
```
解释:
低薪: 有一个账户 2.
中等薪水: 没有.
高薪: 有三个账户, 他们是 3, 6和 8.
*/
WITH
-- 1. 模拟 Accounts 表
Accounts AS (
    SELECT 3 AS account_id, 108939 AS income UNION ALL
    SELECT 2, 12747  UNION ALL
    SELECT 8, 87709  UNION ALL
    SELECT 6, 91796
)
select
    t1.category,
    nvl(t2.accounts_count, 0) as accounts_count
from (
         select explode(`array`('Low Salary', 'Average Salary','High Salary')) category
     ) t1
         left join (
    select
        case
            when t1.income < 20000 then 'Low Salary'
            when t1.income >= 20000 and t1.income <= 50000 then 'Average Salary'
            when t1.income > 50000 then 'High Salary'
            end as category,
        count(t1.account_id) as accounts_count
    from Accounts t1
    group by
        case
            when t1.income < 20000 then 'Low Salary'
            when t1.income >= 20000 and t1.income <= 50000 then 'Average Salary'
            when t1.income > 50000 then 'High Salary'
            end
) t2
                   on t1.category = t2.category;