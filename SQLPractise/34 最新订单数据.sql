/*

题目50 商品最新订单

**Customers**

| Column Name | Type     |
|-------------|----------|
| customer_id | int      |
| customer_name| varchar  |

* customer_id 是该表的主键。
* 该表包含顾客的 ID 和姓名。

**Orders**

| Column Name | Type     |
|-------------|----------|
| order_id    | int      |
| order_date  | date     |
| customer_id | int      |
| product_id  | int      |

* order_id 是该表的主键。
* 该表包含顾客的订单信息。
* customer_id 是 Customers 表的外键。
* product_id 是 Products 表的外键。

**Products**

| Column Name | Type     |
|-------------|----------|
| product_id  | int      |
| product_name| varchar  |
| price       | int      |

* product_id 是该表的主键。
* 该表包含产品信息。

编写一个 SQL 查询，查找每个产品的最新订单的顾客 ID 和顾客姓名。
“最新”订单定义为具有最大 `order_date` 的订单。
如果两个或多个产品具有相同的最大 `order_date`，则考虑具有最大 `order_id` 的订单。
以任何顺序返回结果表。

查询结果格式如下例所示。

**示例 1**

**输入：**
**Customers 表：**
| customer_id | customer_name |
|-------------|---------------|
| 1           | Winston       |
| 2           | Jonathan      |
| 3           | Annabelle     |
| 4           | Marwan        |

**Orders 表：**
| order_id | order_date | customer_id | product_id |
|----------|------------|-------------|------------|
| 1        | 2020-07-31 | 1           | 1          |
| 2        | 2020-07-01 | 2           | 2          |
| 3        | 2020-08-30 | 4           | 3          |
| 4        | 2020-09-30 | 3           | 1          |
| 5        | 2020-08-03 | 3           | 2          |
| 6        | 2020-10-25 | 1           | 3          |
| 7        | 2020-12-15 | 1           | 2          |
| 8        | 2020-01-20 | 1           | 3          |
| 9        | 2020-03-03 | 3           | 3          |
| 10       | 2020-07-27 | 4           | 1          |
| 11       | 2020-08-01 | 2           | 1          |

**Products 表：**
| product_id | product_name | price |
|------------|--------------|-------|
| 1          | keyboard     | 120   |
| 2          | mouse        | 80    |
| 3          | hard disk    | 180   |

**输出：**
| product_name | product_id | order_id | order_date | customer_id | customer_name |
|--------------|------------|----------|------------|-------------|---------------|
| keyboard     | 1          | 4        | 2020-09-30 | 3           | Annabelle     |
| mouse        | 2          | 7        | 2020-12-15 | 1           | Winston       |
| hard disk    | 3          | 6        | 2020-10-25 | 1           | Winston       |

**解释：**
* keyboard 的最新订单是 2020-09-30 下的订单。
* mouse 的最新订单是 2020-12-15 下的订单。
* hard disk 的最新订单是 2020-10-25 下的订单。

**SQL:**
```sql
SELECT
    product_name,
    Products.product_id,
    order_id,
    order_date,
    Customers.customer_id,
    customer_name
FROM Products
JOIN Orders USING(product_id)
JOIN Customers USING(customer_id)
WHERE (product_id, order_date) IN (
    SELECT product_id, MAX(order_date)
    FROM Orders
    GROUP BY product_id
)
ORDER BY
    product_name,
    order_id;*/


WITH Customers AS (
    SELECT 1 AS customer_id, 'Winston' AS customer_name
    UNION ALL
    SELECT 2, 'Jonathan'
    UNION ALL
    SELECT 3, 'Annabelle'
    UNION ALL
    SELECT 4, 'Marwan'
),
Orders AS (
    SELECT 1 AS order_id, '2020-07-31' AS order_date, 1 AS customer_id, 1 AS product_id
    UNION ALL
    SELECT 2, '2020-07-01', 2, 2
    UNION ALL
    SELECT 3, '2020-08-30', 4, 3
    UNION ALL
    SELECT 4, '2020-09-30', 3, 1
    UNION ALL
    SELECT 5, '2020-08-03', 3, 2
    UNION ALL
    SELECT 6, '2020-10-25', 1, 3
    UNION ALL
    SELECT 7, '2020-12-15', 1, 2
    UNION ALL
    SELECT 8, '2020-01-20', 1, 3
    UNION ALL
    SELECT 9, '2020-03-03', 3, 3
    UNION ALL
    SELECT 10, '2020-07-27', 4, 1
    UNION ALL
    SELECT 11, '2020-08-01', 2, 1
),
Products AS (
    SELECT 1 AS product_id, 'keyboard' AS product_name, 120 AS price
    UNION ALL
    SELECT 2, 'mouse', 80
    UNION ALL
    SELECT 3, 'hard disk', 180
),
    lasted_order AS (
        select order_id,
               order_date,
               customer_id,
               product_id
        from (
            select order_id,
               order_date,
               customer_id,
               product_id,
               row_number() over (partition by product_id order by order_date desc, order_id desc) as rn
        from Orders t1
             ) t2
        where rn = 1
            )
select t1.product_id,
       t1.product_name,
       -- 可能product就没有订单，所以这里需要使用coalesce
       coalesce(t2.order_id,null) order_id,
       coalesce(t2.order_date,null) order_date,
       coalesce(t2.customer_id,null) customer_id,
       coalesce(t3.customer_name,null) customer_name
from Products t1
left join lasted_order t2
on t1.product_id = t2.product_id
left join Customers t3
on t2.customer_id = t3.customer_id;
