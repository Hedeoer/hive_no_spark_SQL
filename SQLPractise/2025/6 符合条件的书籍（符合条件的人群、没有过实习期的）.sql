
/*
书籍表 `Books`:
```
+------------------+---------+
| Column Name      | Type    |
+------------------+---------+
| book_id          | int     |
| name             | varchar |
| available_from   | date    |
+------------------+---------+
```
`book_id` 是这个表的主键 (具有唯一值的列) 。

订单表 `Orders`:
```
+----------------+---------+
| Column Name    | Type    |
+----------------+---------+
| order_id       | int     |
| book_id        | int     |
| quantity       | int     |
| dispatch_date  | date    |
+----------------+---------+
```
`order_id` 是这个表的主键 (具有唯一值的列) 。
`book_id` 是 `Books` 表的外键 (reference 列) 。

编写解决方案，筛选出过去一年中订单总量 少于 `10` 本 的书籍, 并且 不考虑 上架距今销售 不满一个月 的书籍。
假设今天是 `2019-06-23` 。
返回结果表 无顺序要求 。
结果格式如下所示。

示例 1:

输入:
`Books` 表:
```
+---------+--------------------+----------------+
| book_id | name               | available_from |
+---------+--------------------+----------------+
| 1       | "Kalila And Demna" | 2010-01-01     |
| 2       | "28 Letters"       | 2012-05-12     |
| 3       | "The Hobbit"       | 2019-06-10     |
| 4       | "13 Reasons Why"   | 2019-06-01     |
| 5       | "The Hunger Games" | 2008-09-21     |
+---------+--------------------+----------------+
```
`Orders` 表:
```
+----------+---------+----------+----------------+
| order_id | book_id | quantity | dispatch_date  |
+----------+---------+----------+----------------+
| 1        | 1       | 2        | 2018-07-26     |
| 2        | 1       | 1        | 2018-11-05     |
| 3        | 3       | 8        | 2019-06-11     |
| 4        | 4       | 6        | 2019-06-05     |
| 5        | 4       | 5        | 2019-06-20     |
| 6        | 5       | 9        | 2009-02-02     |
| 7        | 5       | 8        | 2010-04-13     |
+----------+---------+----------+----------------+
```
输出:
```
+---------+--------------------+
| book_id | name               |
+---------+--------------------+
| 1       | "Kalila And Demna" |
| 2       | "28 Letters"       |
| 5       | "The Hunger Games" |
+---------+--------------------+
```

*/

WITH
-- 1. 模拟 Books 表
Books AS (
    SELECT 1 AS book_id, 'Kalila And Demna' AS name, CAST('2010-01-01' AS DATE) AS available_from UNION ALL
    SELECT 2, '28 Letters',       CAST('2012-05-12' AS DATE) UNION ALL
    SELECT 3, 'The Hobbit',       CAST('2019-06-10' AS DATE) UNION ALL
    SELECT 4, '13 Reasons Why',   CAST('2019-06-01' AS DATE) UNION ALL
    SELECT 5, 'The Hunger Games', CAST('2008-09-21' AS DATE)
),

-- 2. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, 1 AS book_id, 2 AS quantity, CAST('2018-07-26' AS DATE) AS dispatch_date UNION ALL
    SELECT 2, 1, 1, CAST('2018-11-05' AS DATE) UNION ALL
    SELECT 3, 3, 8, CAST('2019-06-11' AS DATE) UNION ALL
    SELECT 4, 4, 6, CAST('2019-06-05' AS DATE) UNION ALL
    SELECT 5, 4, 5, CAST('2019-06-20' AS DATE) UNION ALL
    SELECT 6, 5, 9, CAST('2009-02-02' AS DATE) UNION ALL
    SELECT 7, 5, 8, CAST('2010-04-13' AS DATE)
)

select
    t3.book_id,
    t3.name
from (
         select book_id,
                sum(nvl(quantity,0)) as total_quantity
         from Orders t1
         where dispatch_date >= add_months('2019-06-23', -12) and dispatch_date <= '2019-06-23'
         group by book_id
         having sum(nvl(quantity,0)) < 10
     ) t2
         right join Books t3 on t2.book_id = t3.book_id
where t3.available_from <= add_months('2019-06-23', -1);

