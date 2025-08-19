/*
表: `Users`
```
+----------------+---------+
| Column Name    | Type    |
+----------------+---------+
| user_id        | int     |
| join_date      | date    |
| favorite_brand | varchar |
+----------------+---------+
```
`user_id` 是该表的主键(具有唯一值的列)。
表中包含一位在线购物网站用户的个人信息，用户可以在该网站出售和购买商品。

表: `Orders`
```
+------------+---------+
| Column Name| Type    |
+------------+---------+
| order_id   | int     |
| order_date | date    |
| item_id    | int     |
| buyer_id   | int     |
| seller_id  | int     |
+------------+---------+
```
`order_id` 是该表的主键(具有唯一值的列)。
`item_id` 是 `Items` 表的外键(reference 列)。
`buyer_id` 和 `seller_id` 是 `Users` 表的外键。

表: `Items`
```
+------------+---------+
| Column Name| Type    |
+------------+---------+
| item_id    | int     |
| item_brand | varchar |
+------------+---------+
```
`item_id` 是该表的主键(具有唯一值的列)。

编写一个解决方案，为每个用户找出他们出售的第二件商品(按日期)的品牌是否是他们最喜欢的品牌。
如果用户售出的商品少于两件，则该用户的结果为否。保证卖家不会在一天内卖出一件以上的商品。

以 任意顺序 返回结果表。
返回结果格式如下例所示:

示例 1:

输入:
`Users table`:
```
+---------+------------+----------------+
| user_id | join_date  | favorite_brand |
+---------+------------+----------------+
| 1       | 2019-01-01 | Lenovo         |
| 2       | 2019-02-09 | Samsung        |
| 3       | 2019-01-19 | LG             |
| 4       | 2019-05-21 | HP             |
+---------+------------+----------------+
```
`Orders table`:
```
+----------+------------+---------+----------+-----------+
| order_id | order_date | item_id | buyer_id | seller_id |
+----------+------------+---------+----------+-----------+
| 1        | 2019-08-01 | 4       | 1        | 2         |
| 2        | 2019-08-02 | 2       | 1        | 3         |
| 3        | 2019-08-03 | 3       | 2        | 3         |
| 4        | 2019-08-04 | 1       | 4        | 2         |
| 5        | 2019-08-04 | 1       | 3        | 4         |
| 6        | 2019-08-05 | 2       | 2        | 4         |
+----------+------------+---------+----------+-----------+
```
`Items table`:
```
+---------+------------+
| item_id | item_brand |
+---------+------------+
| 1       | Samsung    |
| 2       | Lenovo     |
| 3       | LG         |
| 4       | HP         |
+---------+------------+
```
输出:
```
+-----------+--------------------+
| seller_id | 2nd_item_fav_brand |
+-----------+--------------------+
| 1         | no                 |
| 2         | yes                |
| 3         | yes                |
| 4         | no                 |
+-----------+--------------------+
```
解释:
id为 1 的用户的查询结果是 no, 因为他什么也没有卖出
id为 2 和 3 的用户的查询结果是 yes, 因为他们卖出的第二件商品的品牌是他们最喜爱的品牌
id为 4 的用户的查询结果是 no, 因为他卖出的第二件商品的品牌不是他最喜爱的品牌
*/

WITH
-- 1. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, CAST('2019-01-01' AS DATE) AS join_date, 'Lenovo' AS favorite_brand UNION ALL
    SELECT 2, CAST('2019-02-09' AS DATE), 'Samsung' UNION ALL
    SELECT 3, CAST('2019-01-19' AS DATE), 'LG' UNION ALL
    SELECT 4, CAST('2019-05-21' AS DATE), 'HP'
),

-- 2. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, CAST('2019-08-01' AS DATE) AS order_date, 4 AS item_id, 1 AS buyer_id, 2 AS seller_id UNION ALL
    SELECT 2, CAST('2019-08-02' AS DATE), 2, 1, 3 UNION ALL
    SELECT 3, CAST('2019-08-03' AS DATE), 3, 2, 3 UNION ALL
    SELECT 4, CAST('2019-08-04' AS DATE), 1, 4, 2 UNION ALL
    SELECT 5, CAST('2019-08-04' AS DATE), 1, 3, 4 UNION ALL
    SELECT 6, CAST('2019-08-05' AS DATE), 2, 2, 4
),

-- 3. 模拟 Items 表
Items AS (
    SELECT 1 AS item_id, 'Samsung' AS item_brand UNION ALL
    SELECT 2, 'Lenovo' UNION ALL
    SELECT 3, 'LG' UNION ALL
    SELECT 4, 'HP'
)
select
    t3.user_id,
    if(t4.item_brand is not null , 'yes','no') 2nd_item_fav_brand
from Users t3
         left join (
    select
        t0.seller_id,
        t0.order_date,
        t1.item_brand,
        row_number() over (partition by t0.seller_id order by t0.order_date) sell_number
    from Orders t0
             left join Items t1
                       on t0.item_id = t1.item_id
) t4
                   on t3.user_id = t4.seller_id and t4.sell_number = 2 and t3.favorite_brand = t4.item_brand
