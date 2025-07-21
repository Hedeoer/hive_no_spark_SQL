/*
销售表 `Sales`:
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| sale_id     | int     |
| product_id  | int     |
| year        | int     |
| quantity    | int     |
| price       | int     |
+-------------+---------+
```
(sale_id, year) 是这张表的主键 (具有唯一值的列的组合) 。
`product_id` 是产品表的外键 (reference 列) 。
这张表的每一行都表示: 编号 `product_id` 的产品在某一年的销售额。
请注意，价格是按每单位计的。

产品表 `Product`:
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| product_id   | int     |
| product_name | varchar |
+--------------+---------+
```
`product_id` 是这张表的主键 (具有唯一值的列) 。
这张表的每一行都标识: 每个产品的 `id` 和 产品名称。

编写解决方案，选出每个售出过的产品 第一年 销售的 产品 `id`、年份、数量 和 价格。
结果表中的条目可以按 任意顺序 排列。
结果格式如下例所示:

示例 1:

输入:
`Sales` 表:
```
+---------+------------+------+----------+-------+
| sale_id | product_id | year | quantity | price |
+---------+------------+------+----------+-------+
| 1       | 100        | 2008 | 10       | 5000  |
| 2       | 100        | 2009 | 12       | 5000  |
| 7       | 200        | 2011 | 15       | 9000  |
+---------+------------+------+----------+-------+
```
`Product` 表:
```
+------------+--------------+
| product_id | product_name |
+------------+--------------+
| 100        | Nokia        |
| 200        | Apple        |
| 300        | Samsung      |
+------------+--------------+
```
输出:
```
+------------+------------+----------+-------+
| product_id | first_year | quantity | price |
+------------+------------+----------+-------+
| 100        | 2008       | 10       | 5000  |
| 200        | 2011       | 15       | 9000  |
+------------+------------+----------+-------+
```

*/

WITH
-- 1. 模拟 Sales 表
Sales AS (
    SELECT 1 AS sale_id, 100 AS product_id, 2008 AS year, 10 AS quantity, 5000 AS price UNION ALL
    SELECT 2, 100, 2009, 12, 5000 UNION ALL
    SELECT 7, 200, 2011, 15, 9000
),

-- 2. 模拟 Product 表 (此题解法中无需使用该表，但为完整性而定义)
Product AS (
    SELECT 100 AS product_id, 'Nokia' AS product_name UNION ALL
    SELECT 200, 'Apple' UNION ALL
    SELECT 300, 'Samsung'
)
/*select product_id,
       year,
       quantity,
       price

from (
         select
             product_id,
             quantity,
             year,
             price,
             row_number() over (partition by product_id order by year) as order_number
         from Sales t1

     ) t2
where order_number = 1;*/

-- 方式2
select
    t1.product_id,
    t1.year,
    t1.quantity,
    t1.price
from Sales t1
         inner join (
    select
        product_id, min(year) as first_year
    from Sales
    group by product_id
) t2
on t1.product_id = t2.product_id and t1.year = t2.first_year;