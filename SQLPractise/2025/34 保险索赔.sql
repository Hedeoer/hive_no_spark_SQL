/*
表: `Fraud`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| policy_id   | int     |
| state       | varchar |
| fraud_score | int     |
+-------------+---------+
```
policy_id 是这张表中具有不同值的列。
这张表包含 policy id, state 和 fraud score。
Leetcode 保险公司开发了一个 ML 驱动的 预测模型 来检测欺诈索赔的 可能性。因此，他们分配了经验最丰富的理赔员来处理前 `5%` 被标记 的索赔。

编写一个解决方案来找出 每个州 索赔的前 5 百分位数。
返回结果表，以 state 升序 排序, fraud_score 降序 排序, policy_id 升序 排序。
结果格式如下所示。

示例 1:

输入:
`Fraud` 表:
```
+-----------+-------------+-------------+
| policy_id | state       | fraud_score |
+-----------+-------------+-------------+
| 1         | California  | 0.92        |
| 2         | California  | 0.68        |
| 3         | California  | 0.17        |
| 4         | New York    | 0.94        |
| 5         | New York    | 0.81        |
| 6         | New York    | 0.77        |
| 7         | Texas       | 0.98        |
| 8         | Texas       | 0.97        |
| 9         | Texas       | 0.96        |
| 10        | Florida     | 0.97        |
| 11        | Florida     | 0.98        |
| 12        | Florida     | 0.78        |
| 13        | Florida     | 0.88        |
| 14        | Florida     | 0.66        |
+-----------+-------------+-------------+
```
输出:
```
+-----------+------------+-------------+
| policy_id | state      | fraud_score |
+-----------+------------+-------------+
| 1         | California | 0.92        |
| 11        | Florida    | 0.98        |
| 4         | New York   | 0.94        |
| 7         | Texas      | 0.98        |
+-----------+------------+-------------+```
解释:
- 对于 California 州, 只有 ID 为 1 的保单的欺诈分数为 0.92, 属于该州的前 5%.
- 对于 Florida 州, 只有 ID 为 11 的保单的欺诈分数为 0.98, 属于该州的前 5%.
- 对于 New York 州, 只有 ID 为 4 的保单的欺诈分数为 0.94, 属于该州的前 5%.
- 对于 Texas 州, 只有 ID 为 7 的保单的欺诈分数为 0.98, 属于该州的前 5%.
- 输出表以 state 升序排序, fraud_score 降序排序, policy_id 升序排序。


*/

WITH
-- 1. 模拟 Fraud 表
Fraud AS (
    SELECT 1 AS policy_id, 'California' AS state, 0.92 AS fraud_score UNION ALL
    SELECT 2, 'California', 0.68 UNION ALL
    SELECT 3, 'California', 0.17 UNION ALL
    SELECT 4, 'New York',   0.94 UNION ALL
    SELECT 5, 'New York',   0.81 UNION ALL
    SELECT 6, 'New York',   0.77 UNION ALL
    SELECT 7, 'Texas',      0.98 UNION ALL
    SELECT 8, 'Texas',      0.97 UNION ALL
    SELECT 9, 'Texas',      0.96 UNION ALL
    SELECT 10, 'Florida',    0.97 UNION ALL
    SELECT 11, 'Florida',    0.98 UNION ALL
    SELECT 12, 'Florida',    0.78 UNION ALL
    SELECT 13, 'Florida',    0.88 UNION ALL
    SELECT 14, 'Florida',    0.66
)
-- 方式1
/*
select
    policy_id,
    state,
    fraud_score
from (
         select policy_id,
                state,
                fraud_score,
                count(1) over(partition by state) as total_num,
                rank() over (partition by state order by fraud_score desc) order_num,
                0.05 * count(1) over(partition by state) limit_num
         from Fraud t1
     ) t2
-- 2. 计算每个州的总数, 排名和前 5% 的限制,如果limit_num为小数，则找到排名最靠前的那一个
where order_num <= `ceil`(limit_num) or order_num = 1
order by state asc, fraud_score desc, policy_id asc;

*/
-- 方式2
select policy_id,
       state,
       fraud_score
from (
         select policy_id,
                state,
                fraud_score,
                -- 计算每个州的 fraud_score 的累积分布
                cume_dist() over(partition by state order by fraud_score asc) as cume_dist
         from Fraud t1
     ) t2
where cume_dist >= 0.95
order by state asc, fraud_score desc, policy_id asc;