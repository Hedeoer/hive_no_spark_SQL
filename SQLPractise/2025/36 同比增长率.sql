
/*
表: `user_transactions`
```
+--------------------+----------+
| Column Name        | Type     |
+--------------------+----------+
| transaction_id     | integer  |
| product_id         | integer  |
| spend              | decimal  |
| transaction_date   | datetime |
+--------------------+----------+
```
`transaction_id` 唯一标识了表中的每一列。
这张表的每一行含有交易 ID，产品 ID, 总花费以及交易日期。

编写一个解决方案来计算 每个产品 总支出的 同比增长率。
结果表应该包含以下列:
*   `year`: 交易的年份。
*   `product_id`: 产品的 ID。
*   `curr_year_spend`: 当年的总支出。
*   `prev_year_spend`: 上一年的总支出。
*   `yoy_rate`: 同比增速百分比, 四舍五入至小数点后 2 位。

返回结果表以 `product_id`, `year` 升序 排序。
结果格式如下所示。

示例:
输入:
`user_transactions` 表:
```
+----------------+------------+---------+---------------------+
| transaction_id | product_id | spend   | transaction_date    |
+----------------+------------+---------+---------------------+
| 1341           | 123424     | 1500.60 | 2019-12-31 12:00:00 |
| 1423           | 123424     | 1000.20 | 2020-12-31 12:00:00 |
| 1623           | 123424     | 1246.44 | 2021-12-31 12:00:00 |
| 1322           | 123424     | 2145.32 | 2022-12-31 12:00:00 |
+----------------+------------+---------+---------------------+
```
输出:
```
+------+------------+-----------------+-----------------+----------+
| year | product_id | curr_year_spend | prev_year_spend | yoy_rate |
+------+------------+-----------------+-----------------+----------+
| 2019 | 123424     | 1500.60         | NULL            | NULL     |
| 2020 | 123424     | 1000.20         | 1500.60         | -33.35   |
| 2021 | 123424     | 1246.44         | 1000.20         | 24.62    |
| 2022 | 123424     | 2145.32         | 1246.44         | 72.12    |
+------+------------+-----------------+-----------------+----------+
```
解释:
对于产品 ID 123424:在 2019: 当年的支出是 1500.60
没有上一年支出的记录
同比增长率: NULL

在 2020: 当年的支出是 1000.20
上一年的支出是 1500.60
同比增长率: ((1000.20 - 1500.60) / 1500.60) * 100 = -33.35%

在 2021: 当年的支出是 1246.44
上一年的支出是 1000.20
同比增长率: ((1246.44 - 1000.20) / 1000.20) * 100 = 24.62%

在 2022: 当年的支出是 2145.32
上一年的支出是 1246.44
同比增长率: ((2145.32 - 1246.44) / 1246.44) * 100 = 72.12%

注意: 输出表以 `product_id` 和 `year` 升序排序。

*/

WITH
-- 1. 模拟 user_transactions 表
user_transactions AS (
    SELECT 1341 AS transaction_id, 123424 AS product_id, CAST(1500.60 AS DECIMAL(10,2)) AS spend, CAST('2019-12-31 12:00:00' AS TIMESTAMP) AS transaction_date UNION ALL
    SELECT 1423, 123424, CAST(1000.20 AS DECIMAL(10,2)), CAST('2020-12-31 12:00:00' AS TIMESTAMP) UNION ALL
    SELECT 1623, 123424, CAST(1246.44 AS DECIMAL(10,2)), CAST('2021-12-31 12:00:00' AS TIMESTAMP) UNION ALL
    SELECT 1322, 123424, CAST(2145.32 AS DECIMAL(10,2)), CAST('2022-12-31 12:00:00' AS TIMESTAMP)
)
select product_id,
       year,
       curr_year_spend,
       prev_year_spend,
       round(((curr_year_spend - prev_year_spend) / prev_year_spend) * 100, 2)  as yoy_rate
from (
         select
             product_id , year(transaction_date) year,
             sum(spend) as curr_year_spend,
             lag(sum(spend)) over (partition by product_id order by year(transaction_date)) as prev_year_spend
         from user_transactions t1
         group by product_id , year(transaction_date)
     ) t2
order by product_id, year;