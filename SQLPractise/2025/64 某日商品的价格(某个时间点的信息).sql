/*
产品数据表: `Products`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| product_id   | int     |
| new_price    | int     |
| change_date  | date    |
+--------------+---------+
```
(product_id, change_date) 是此表的主键 (具有唯一值的列组合)。
这张表的每一行分别记录了 某产品 在某个日期 更改后 的新价格。一开始，所有产品价格都为 10。
编写一个解决方案，找出在 `2019-08-16`所有产品的价格。
以 任意顺序 返回结果表。
结果格式如下例所示。

示例 1:

输入:
`Products` 表:
```
+------------+-----------+-------------+
| product_id | new_price | change_date |
+------------+-----------+-------------+
| 1          | 20        | 2019-08-14  |
| 2          | 50        | 2019-08-14  |
| 1          | 30        | 2019-08-15  |
| 1          | 35        | 2019-08-16  |
| 2          | 65        | 2019-08-17  |
| 3          | 20        | 2019-08-18  |
+------------+-----------+-------------+
```
输出:
```
+------------+-------+
| product_id | price |
+------------+-------+
| 2          | 50    |
| 1          | 35    |
| 3          | 10    |
+------------+-------+
```

*/
WITH
-- 1. 模拟 Products 表
Products AS (
    SELECT 1 AS product_id, 20 AS new_price, CAST('2019-08-14' AS DATE) AS change_date UNION ALL
    SELECT 2, 50, CAST('2019-08-14' AS DATE) UNION ALL
    SELECT 1, 30, CAST('2019-08-15' AS DATE) UNION ALL
    SELECT 1, 35, CAST('2019-08-16' AS DATE) UNION ALL
    SELECT 2, 65, CAST('2019-08-17' AS DATE) UNION ALL
    SELECT 3, 20, CAST('2019-08-18' AS DATE)
),
-- 利用距离最近的价格即为最新的价格
conditon_prices as (
    select product_id,
           new_price,
           change_date,
           datediff,
           row_number() over (partition by product_id order by datediff ) lasted_number
    from (
             select product_id,
                    new_price,
                    change_date,
                    datediff(to_date('2019-08-16'),change_date) datediff
             from Products t0
             where change_date <= to_date('2019-08-16')
         ) t1
),
dim_product as (
    select
        product_id
    from Products
    group by  product_id
)
select
    t0.product_id,
    nvl(t1.new_price,10) price
from dim_product t0
         left join conditon_prices t1
                   on t0.product_id = t1.product_id and t1.lasted_number = 1




