
/*

 顾客订单分析

 数据表结构

 Customers 表
sql
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| customer_id | int     |
| name        | varchar |
+-------------+---------+

- `customer_id` 是该表的唯一标识列。
- 该表包含所有顾客的信息。

 Orders 表
sql
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| order_id    | int     |
| order_date  | date    |
| customer_id | int     |
| product_id  | int     |
+-------------+---------+

- `order_id` 是该表的唯一标识列。
- 该表包含每个 `customer_id` 的订单信息。
- 没有顾客会在一天内订购相同的商品多于一次

 Products 表
sql
+--------------+-------------+
| Column Name  | Type        |
+--------------+-------------+
| product_id   | int         |
| product_name | varchar     |
| price        | int         |
+--------------+-------------+

- `product_id` 是该表的唯一标识列。
- 该表包含所有商品的信息。
- 目标是找到每个顾客最常购买的商品。

---

 查询需求
-写一个解决方案，找到每一个顾客最经常订购的商品。
结果表单应该有每一位至少下过一次单的顾客customer_id，他最经常订购的商品的product_id 和
product_name.
---

 示例数据

 Customers 表
sql
+-------------+------+
| customer_id | name |
+-------------+------+
| 1           | Alice  |
| 2           | Bob    |
| 3           | Jerry  |
| 4           | Tom    |
| 5           | John   |
+-------------+------+


 Orders 表
sql
+----------+------------+-------------+-----------+
| order_id | order_date | customer_id | product_id |
+----------+------------+-------------+-----------+
| 1        | 2020-07-31 | 1           | 2         |
| 2        | 2020-07-31 | 1           | 1         |
| 3        | 2020-08-01 | 2           | 2         |
| 4        | 2020-08-01 | 2           | 2         |
| 5        | 2020-08-01 | 3           | 3         |
| 6        | 2020-08-01 | 3           | 3         |
| 7        | 2020-08-01 | 3           | 3         |
| 8        | 2020-08-07 | 2           | 3         |
| 9        | 2020-08-07 | 2           | 2         |
| 10       | 2020-08-15 | 1           | 2         |
+----------+------------+-------------+-----------+


 Products 表
sql
+------------+--------------+-------+
| product_id | product_name | price |
+------------+--------------+-------+
| 1          | keyboard     | 120   |
| 2          | mouse        | 80    |
| 3          | screen       | 600   |
| 4          | hard disk    | 450   |
+------------+--------------+-------+


---

这是一个查询结果输出和解释说明，我来格式化一下内容：

customer_id | product_id | product_name
1 | 2 | mouse
2 | 1 | keyboard
2 | 2 | mouse
2 | 3 | screen
3 | 3 | screen
4 | 1 | keyboard


解释：
1. Alice (customer 1) 三次订购商品，一次订购鼠标，所以显示是 Alice 最经常订购的商品。
2. Bob (customer 2) 一次订购键盘，一次订购鼠标，一次订购显示器，所以这些都是 Bob 最经常订购的商品。
3. Tom (customer 3) 只购买订购显示器，所以显示器是 Tom 最经常订购的商品。
4. Jerry (customer 4) 只一次订购键盘，所以键盘是 Jerry 最经常订购的商品。
5. John (customer 5) 没有订购过商品，所以数据中没有把 John 包含在输出结果中。

*/

WITH Customers AS (
    SELECT 1 AS customer_id, 'Alice' AS name
    UNION ALL
    SELECT 2, 'Bob'
    UNION ALL
    SELECT 3, 'Jerry'
    UNION ALL
    SELECT 4, 'Tom'
    UNION ALL
    SELECT 5, 'John'
),
Orders AS (
    SELECT 1 AS order_id, '2020-07-31' AS order_date, 1 AS customer_id, 2 AS product_id
    UNION ALL
    SELECT 2, '2020-07-31', 1, 1
    UNION ALL
    SELECT 3, '2020-08-01', 2, 2
    UNION ALL
    SELECT 4, '2020-08-01', 2, 2
    UNION ALL
    SELECT 5, '2020-08-01', 3, 3
    UNION ALL
    SELECT 6, '2020-08-01', 3, 3
    UNION ALL
    SELECT 7, '2020-08-01', 3, 3
    UNION ALL
    SELECT 8, '2020-08-07', 2, 3
    UNION ALL
    SELECT 9, '2020-08-07', 2, 2
    UNION ALL
    SELECT 10, '2020-08-15', 1, 2
),
Products AS (
    SELECT 1 AS product_id, 'keyboard' AS product_name, 120 AS price
    UNION ALL
    SELECT 2, 'mouse', 80
    UNION ALL
    SELECT 3, 'screen', 600
    UNION ALL
    SELECT 4, 'hard disk', 450
),
    purchase AS (
        select customer_id,
               product_id,
               pruchase_times,
               rank() over (partition by customer_id order by pruchase_times desc) as rk
        from (
            select
                t1.customer_id,
                t1.product_id,
                count(1)  pruchase_times
            from Orders t1
            group by t1.customer_id, t1.product_id
             ) t2
    )
select
    t1.customer_id,
    t1.product_id,
    t2.product_name
from purchase t1
left join Products t2
on t1.product_id = t2.product_id
where t1.rk = 1
;

-- 方式二，简化方式一写法
WITH Customers AS (
    SELECT 1 AS customer_id, 'Alice' AS name
    UNION ALL
    SELECT 2, 'Bob'
    UNION ALL
    SELECT 3, 'Jerry'
    UNION ALL
    SELECT 4, 'Tom'
    UNION ALL
    SELECT 5, 'John'
),
Orders AS (
    SELECT 1 AS order_id, '2020-07-31' AS order_date, 1 AS customer_id, 2 AS product_id
    UNION ALL
    SELECT 2, '2020-07-31', 1, 1
    UNION ALL
    SELECT 3, '2020-08-01', 2, 2
    UNION ALL
    SELECT 4, '2020-08-01', 2, 2
    UNION ALL
    SELECT 5, '2020-08-01', 3, 3
    UNION ALL
    SELECT 6, '2020-08-01', 3, 3
    UNION ALL
    SELECT 7, '2020-08-01', 3, 3
    UNION ALL
    SELECT 8, '2020-08-07', 2, 3
    UNION ALL
    SELECT 9, '2020-08-07', 2, 2
    UNION ALL
    SELECT 10, '2020-08-15', 1, 2
),
Products AS (
    SELECT 1 AS product_id, 'keyboard' AS product_name, 120 AS price
    UNION ALL
    SELECT 2, 'mouse', 80
    UNION ALL
    SELECT 3, 'screen', 600
    UNION ALL
    SELECT 4, 'hard disk', 450
)
select
    t1.customer_id,
    t1.product_id,
    t2.product_name
from (
    select
        t1.customer_id,
        t1.product_id,
        rank() over(partition by t1.customer_id order by count(product_id) desc) as rk
    from Orders t1
    group by t1.customer_id, t1.product_id

     ) t1
left join Products t2
on t1.product_id = t2.product_id
where t1.rk = 1
;