/*
1.  **给四张表:**
    *   用户表`customers`: id (用户id), name (用户名), member_level (会员等级)
    *   订单表`orders`: id (订单id), customer_id (用户id), amount (订单金额), order_date (订单日期 yyyy-MM-dd)
    *   订单商品表`orders_items`: id, order_id (订单id), product_id (商品id), quantity (数量), price (单价)
    *   商品表`products`: id (商品id), name (名称), category (种类)

**题目要求:** 求出2024年份订单数量大于3的用户的
*   名字
*   会员等级
*   订单总金额
*   购买商品的总数量
*   购买次数最多的商品种类 (确保只有一种，不会重复)

按照订单总金额进行倒序排序
+---------+--------------+--------------+----------------+------------------------+
| name    | member_level | total_amount | total_quantity | top_purchased_category |
+---------+--------------+--------------+----------------+------------------------+
| Alice   | Gold         | 480.00       | 6              | Electronics            |
| Charlie | Gold         | 190.00       | 6              | Books                  |
+---------+--------------+--------------+----------------+------------------------+
*/

WITH

-- 1. 模拟数据表
customers AS (
    SELECT 1 AS id, 'Alice' AS name, 'Gold' AS member_level UNION ALL
    SELECT 2, 'Bob', 'Silver' UNION ALL
    SELECT 3, 'Charlie', 'Gold' UNION ALL
    SELECT 4, 'David', 'Bronze'
),
orders AS (
    -- Alice: 4 orders in 2024
    SELECT 101 AS id, 1 AS customer_id, 150.00 AS amount, CAST('2024-01-15' AS DATE) AS order_date UNION ALL
    SELECT 102, 1, 200.00, CAST('2024-02-20' AS DATE) UNION ALL
    SELECT 103, 1, 50.00,  CAST('2024-03-10' AS DATE) UNION ALL
    SELECT 104, 1, 80.00,  CAST('2024-04-05' AS DATE) UNION ALL
    -- Bob: 2 orders in 2024 (will be filtered out)
    SELECT 201, 2, 90.00,  CAST('2024-01-20' AS DATE) UNION ALL
    SELECT 202, 2, 120.00, CAST('2024-03-15' AS DATE) UNION ALL
    -- Charlie: 5 orders in 2024
    SELECT 301, 3, 30.00,  CAST('2024-01-05' AS DATE) UNION ALL
    SELECT 302, 3, 35.00,  CAST('2024-02-10' AS DATE) UNION ALL
    SELECT 303, 3, 40.00,  CAST('2024-03-18' AS DATE) UNION ALL
    SELECT 304, 3, 25.00,  CAST('2024-04-22' AS DATE) UNION ALL
    SELECT 305, 3, 60.00,  CAST('2024-05-30' AS DATE) UNION ALL
    -- David: 1 order in 2023 (will be filtered out)
    SELECT 401, 4, 100.00, CAST('2023-12-10' AS DATE)
),
products AS (
    SELECT 1 AS id, 'Laptop' AS name, 'Electronics' AS category UNION ALL
    SELECT 2, 'Keyboard', 'Electronics' UNION ALL
    SELECT 3, 'SQL Book', 'Books' UNION ALL
    SELECT 4, 'Desk Chair', 'Home Goods' UNION ALL
    SELECT 5, 'Coffee Mug', 'Home Goods'
),
-- 【修正部分】orders_items 表现在严格遵循5列的定义
orders_items AS (
    -- Alice's items
    SELECT 1 AS id, 101 AS order_id, 1 AS product_id, 1 AS quantity, 150.00 AS price UNION ALL
    SELECT 2, 102, 2, 1, 100.00 UNION ALL
    SELECT 3, 102, 3, 2, 50.00  UNION ALL
    SELECT 4, 103, 4, 1, 50.00  UNION ALL
    SELECT 5, 104, 2, 1, 80.00  UNION ALL
    -- Bob's items
    SELECT 6, 201, 3, 3, 30.00  UNION ALL
    SELECT 7, 202, 4, 1, 120.00 UNION ALL
    -- Charlie's items
    SELECT 8, 301, 3, 1, 30.00  UNION ALL
    SELECT 9, 302, 3, 1, 35.00  UNION ALL
    SELECT 10, 303, 3, 1, 40.00 UNION ALL
    SELECT 11, 304, 4, 1, 25.00 UNION ALL
    SELECT 12, 305, 5, 2, 30.00 UNION ALL
    -- David's items
    SELECT 13, 401, 1, 1, 100.00
),
-- 2024年订单数超过3单的用户购买情况
orders_items_details as (
    select customer_id,
           name,
           member_level,
           order_id,
           order_amount,
           order_date,
           product_id,
           category,
           quantity,
           price
    from (
             select
                 t2.customer_id,
                 t4.name,
                 t4.member_level,
                 t2.id order_id,
                 t2.amount order_amount,
                 t2.order_date,
                 t1.product_id,
                 t3.category,
                 t1.quantity,
                 t1.price,
                 count(distinct t2.id) over(partition by t2.customer_id) 2024_total_orders
             from orders_items t1
                      left join orders t2
                                on t1.order_id = t2.id
                      left join products t3
                                on t1.product_id = t3.id
                      left join customers t4
                                on t2.customer_id = t4.id
             where year(t2.order_date) = 2024
         ) tt
    where 2024_total_orders > 3
),
-- 计算每个用户2024年的总消费和总购买数量
result1 as (
    select
        t1.customer_id,
        t1.name,
        t1.member_level,
        sum(t1.price * t1.quantity) as total_spent,
        sum(t1.quantity) as total_quantity
    from orders_items_details t1
    group by
        t1.customer_id,
        t1.name,
        t1.member_level
),
-- 计算每个用户2024年购买次数最多的商品种类
result2 as (
    select
        customer_id,
        category
    from (
             select
                 t1.customer_id,
                 t1.category,
                 count(distinct t1.order_id) as order_count,
                 row_number() over (partition by t1.customer_id order by count(distinct t1.order_id) desc) rn
             from orders_items_details t1
             group by t1.customer_id, t1.category
         ) t2
    where rn = 1
)
-- 结果拼接
select t1.customer_id,
       t1.name,
       t1.member_level,
       t1.total_spent,
       t1.total_quantity,
       t2.category
from result1 t1
         join result2 t2
              on t1.customer_id = t2.customer_id
order by t1.total_spent desc;
