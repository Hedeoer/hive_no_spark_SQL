/*
`Customer` 表:
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| customer_id | int     |
| product_key | int     |
+-------------+---------+
```
该表可能包含重复的行。
`customer_id` 不为 `NULL`。
`product_key` 是 `Product` 表的外键(reference 列)。

`Product` 表:
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| product_key | int     |
+-------------+---------+
```
`product_key` 是这张表的主键 (具有唯一值的列) 。

编写解决方案，报告 `Customer` 表中购买了 `Product` 表中所有产品的客户的 `id`。
返回结果表 无顺序要求。
返回结果格式如下所示。

示例 1:

输入:
`Customer` 表:
```
+-------------+-------------+
| customer_id | product_key |
+-------------+-------------+
| 1           | 5           |
| 2           | 6           |
| 3           | 5           |
| 3           | 6           |
| 1           | 6           |
+-------------+-------------+
```
`Product` 表:
```
+-------------+
| product_key |
+-------------+
| 5           |
| 6           |
+-------------+
```
输出:
```
+-------------+
| customer_id |
+-------------+
| 1           |
| 3           |
+-------------+
```

*/

WITH
-- 1. 模拟 Customer 表
Customer AS (
    SELECT 1 AS customer_id, 5 AS product_key UNION ALL
    SELECT 2, 6 UNION ALL
    SELECT 3, 5 UNION ALL
    SELECT 3, 6 UNION ALL
    SELECT 1, 6
),

-- 2. 模拟 Product 表
Product AS (
    SELECT 5 AS product_key UNION ALL
    SELECT 6
)
select
    t1.customer_id
from Customer t1
         left join Product t2
                   on t1.product_key = t2.product_key
         cross join (select count(1) total_products from Product) t3
group by t1.customer_id,t3.total_products
having count(distinct t2.product_key) = t3.total_products;