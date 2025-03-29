/*
# 题目35 发票信息

```sql
表: Products

| Column Name | Type |
+--------------+------+
| product_id | int |
| price | int |
+--------------+------+
product_id 是该表的主键。
该表中的每一行描述了一个产品的 ID 和一个单位的价格。

表: Purchases

| Column Name | Type |
+--------------+------+
| invoice_id | int |
| product_id | int |
| quantity | int |
+--------------+------+
(invoice_id, product_id) 是该表的主键（具有唯一值的列的组合）。
该表中的每一行都显示了小张单中的一种产品订购的数量。
编写解决方案，展示价格最高的发票的详细信息。如果最高价签发了多个发票且有相同的价格，则返回 invoice_id 最小的发票的详细信息。

以 任意顺序 返回结果表。
结果格式示例如下。

示例 1:

输入:
Products 表:
+--------------+-------+
| product_id | price |
+--------------+-------+
| 1 | 100 |
| 2 | 200 |
+--------------+-------+
Purchases 表:
+------------+--------------+----------+
| invoice_id | product_id | quantity |
+------------+--------------+----------+
| 1 | 1 | 2 |
| 2 | 2 | 1 |
| 4 | 1 | 10 |
+------------+--------------+----------+
输出:
+--------------+----------+-------+
| product_id | quantity | price |
+--------------+----------+-------+
| 2 | 3 | 600 |
| 1 | 4 | 400 |
+--------------+----------+-------+
解释:
发票 1: price = (2 * 100) = $200
发票 2: price = (4 * 100) + (3 * 200) = $1000
发票 3: price = (1 * 200) = $200

最高价格是 1000 美元，最高价格的发票是 2 和 4。我们返回 ID 最小的发票 2 的详细信息。
```

*/
WITH Products AS (
    SELECT 1 AS product_id, 100 AS price
    UNION ALL
    SELECT 2, 200
),
Purchases AS (
    SELECT 1 AS invoice_id, 1 AS product_id, 2 AS quantity
    UNION ALL
    SELECT 2, 2, 1
    UNION ALL
    SELECT 4, 1, 10
),
    aimed_pur as (
        select
            t1.invoice_id,
            sum(t1.quantity * t2.price) amounts
        from Purchases t1
        left join Products t2
        on t1.product_id = t2.product_id
        group by t1.invoice_id
        order by amounts desc, invoice_id asc
        limit 1
    )
select
    t2.product_id,
    t1.quantity,
    t2.price
from Purchases t1
left join Products t2
on t1.product_id = t2.product_id
left join aimed_pur t3
on t1.invoice_id = t3.invoice_id
where t3.invoice_id is not null;
