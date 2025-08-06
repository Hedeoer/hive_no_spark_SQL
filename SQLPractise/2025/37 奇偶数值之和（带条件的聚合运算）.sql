/*
表: `transactions`
```
+------------------+------+
| Column Name      | Type |
+------------------+------+
| transaction_id   | int  |
| amount           | int  |
| transaction_date | date |
+------------------+------+
```
`transactions_id` 唯一标识了表中的每一行。
这张表的每一行包含交易 id, 金额总和和交易日期。

编写一个解决方案来查找每天 `奇数` 交易金额和 `偶数` 交易金额的 总和。如果某天没有奇数或偶数交易，显示为 `0`。
返回结果表以 `transaction_date` 升序 排序。
结果格式如下所示。

示例:
输入:
`transactions` 表:
```
+----------------+--------+------------------+
| transaction_id | amount | transaction_date |
+----------------+--------+------------------+
| 1              | 150    | 2024-07-01       |
| 2              | 200    | 2024-07-01       |
| 3              | 75     | 2024-07-01       |
| 4              | 300    | 2024-07-02       |
| 5              | 50     | 2024-07-02       |
| 6              | 120    | 2024-07-03       |
+----------------+--------+------------------+
```
输出:
```
+------------------+----------+-----------+
| transaction_date | odd_sum  | even_sum  |
+------------------+----------+-----------+
| 2024-07-01       | 75       | 350       |
| 2024-07-02       | 0        | 350       |
| 2024-07-03       | 0        | 120       |
+------------------+----------+-----------+
```
解释:
对于交易日期: 2024-07-01: 奇数交易金额总和: 75
偶数交易金额总和: 150 + 200 = 350
2024-07-02: 奇数交易金额总和: 0
偶数交易金额总和: 300 + 50 = 350
2024-07-03: 奇数交易金额总和: 0
偶数交易金额总和: 120
注意: 输出表以 `transaction_date` 升序排序。
*/

WITH
-- 1. 模拟 transactions 表
transactions AS (
    SELECT 1 AS transaction_id, 150 AS amount, CAST('2024-07-01' AS DATE) AS transaction_date UNION ALL
    SELECT 2, 200, CAST('2024-07-01' AS DATE) UNION ALL
    SELECT 3, 75,  CAST('2024-07-01' AS DATE) UNION ALL
    SELECT 4, 300, CAST('2024-07-02' AS DATE) UNION ALL
    SELECT 5, 50,  CAST('2024-07-02' AS DATE) UNION ALL
    SELECT 6, 120, CAST('2024-07-03' AS DATE)
)
select
    transaction_date,
    sum(if(amount % 2 = 1, amount, 0)) as odd_sum,
    sum(if(amount % 2 = 0, amount, 0)) as even_sum
from transactions  t1
group by transaction_date
