
/*
-- Customers 表
CREATE TABLE Customers (
    customer_id INT,
    customer_name VARCHAR(255)
);

-- Orders 表
CREATE TABLE Orders (
    order_id INT,
    customer_id INT,
    product_name VARCHAR(255)
);
order_id 是这张表中具有唯一值的列。
customer_id 是购买了名为“product_name"产品顾客的id。
请你编写解决方案，报告购买了产品"A"，"B"但没有购买产品"c"的客户的customer_id和
customer_name，因为我们想推荐他们购买这样的产品。
返回按customer_id 排序的结果表。
返回结果格式如下所示。
示例1:
输入：
-- 插入 Customers 表数据
INSERT INTO Customers (customer_id, customer_name) VALUES
(1, 'Daniel'),
(2, 'Diana'),
(3, 'Elizabeth'),
(4, 'John');

-- 插入 Orders 表数据
INSERT INTO Orders (order_id, customer_id, product_name) VALUES
(10, 1, 'A'),
(20, 1, 'B'),
(30, 2, 'C'),
(40, 3, 'A'),
(50, 3, 'C'),
(60, 3, 'D'),
(70, 4, 'B'),
(80, 4, 'E');

输出：
| customer_id | customer_name
|3 |Elizabeth |
解释：
只有customer_id为3的顾客购买了产品A和产品B，却没有购买产品C

-- 查询购买了产品 "A" 和 "C" 的客户的 customer_id 和 customer_name
*/

-- 使用array_contains函数处理
WITH Customers AS (
    SELECT 1 AS customer_id, 'Daniel' AS customer_name
    UNION ALL
    SELECT 2, 'Diana'
    UNION ALL
    SELECT 3, 'Elizabeth'
    UNION ALL
    SELECT 4, 'John'
),
Orders AS (
    SELECT 10 AS order_id, 1 AS customer_id, 'A' AS product_name
    UNION ALL
    SELECT 20, 1, 'B'
    UNION ALL
    SELECT 30, 2, 'C'
    UNION ALL
    SELECT 40, 3, 'A'
    UNION ALL
    SELECT 50, 3, 'C'
    UNION ALL
    SELECT 60, 3, 'D'
    UNION ALL
    SELECT 70, 4, 'B'
    UNION ALL
    SELECT 80, 4, 'E'
)
select
    t3.customer_id,
    t4.customer_name
from (
    select
        customer_id
    from (
        select
            t1.customer_id,
            collect_set(product_name) as product_names
        from Orders t1
        group by t1.customer_id
         ) t2
    where array_contains(product_names, 'A')
    and array_contains(product_names, 'B')
    and not array_contains(product_names, 'C')
     ) t3
left join Customers t4
on t3.customer_id = t4.customer_id;
