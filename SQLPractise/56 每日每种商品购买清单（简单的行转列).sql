
/*
每日每种商品购买清单（简单的行转列)


表: `Orders`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| order_id    | int     |
| customer_id | int     |
| order_date  | date    |
| item_id     | varchar |
| quantity    | int     |
+-------------+---------+
```
(order_id, item_id) 是该表主键(具有唯一值的列的组合)
该表包含了订单信息
order_date 是id为 item_id 的商品被id为 customer_id 的消费者订购的日期。

表: `Items`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| item_id       | varchar |
| item_name     | varchar |
| item_category | varchar |
+---------------+---------+
```
item_id 是该表主键(具有唯一值的列)
item_name 是商品的的名字
item_category 是商品的类别

你是企业主，想要获得分类商品和周内每天的销售报告。
编写解决方案，报告 周内每天 每个商品类别下订购了多少单位。
返回结果表 按商品类别排序。
结果格式如下例所示。

示例 1:

输入:
`Orders` 表:
```
+----------+-------------+------------+---------+----------+
| order_id | customer_id | order_date | item_id | quantity |
+----------+-------------+------------+---------+----------+
| 1        | 1           | 2020-06-01 | 1       | 10       |
| 2        | 1           | 2020-06-08 | 2       | 10       |
| 3        | 2           | 2020-06-02 | 1       | 5        |
| 4        | 3           | 2020-06-03 | 3       | 5        |
| 5        | 4           | 2020-06-04 | 4       | 1        |
| 6        | 4           | 2020-06-05 | 5       | 5        |
| 7        | 5           | 2020-06-05 | 1       | 10       |
| 8        | 5           | 2020-06-14 | 4       | 5        |
| 9        | 5           | 2020-06-21 | 3       | 5        |
+----------+-------------+------------+---------+----------+
```
`Items` 表:
```
+---------+-----------------+---------------+
| item_id | item_name       | item_category |
+---------+-----------------+---------------+
| 1       | LC Alg. Book    | Book          |
| 2       | LC DB. Book     | Book          |
| 3       | LC SmarthPhone  | Phone         |
| 4       | LC Phone        | Phone         |
| 5       | LC SmartGlass   | Glasses       |
| 6       | LC T-Shirt XL   | T-Shirt       |
+---------+-----------------+---------------+
```
输出:
```
+----------+--------+---------+-----------+----------+--------+----------+--------+
| Category | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday | Sunday |
+----------+--------+---------+-----------+----------+--------+----------+--------+
| Book     | 20     | 5       | 0         | 0        | 10     | 0        | 0      |
| Glasses  | 0      | 0       | 0         | 0        | 5      | 0        | 0      |
| Phone    | 0      | 0       | 5         | 1        | 0      | 0        | 10     |
| T-Shirt  | 0      | 0       | 0         | 0        | 0      | 0        | 0      |
+----------+--------+---------+-----------+----------+--------+----------+--------+
```
解释:
在周一(2020-06-01, 2020-06-08), Book分类(ids: 1, 2)下，总共销售了20个单位(10 + 10)
在周二(2020-06-02), Book分类(ids: 1, 2)下，总共销售了5个单位
在周三(2020-06-03), Phone分类(ids: 3, 4)下，总共销售了5个单位
在周四(2020-06-04), Phone分类(ids: 3, 4)下，总共销售了1个单位
在周五(2020-06-05), Book分类(ids: 1, 2)下, 总共销售了10个单位, Glasses分类(ids: 5)下，总共销售了5个单位
在周六, 没有商品销售
在周天(2020-06-14, 2020-06-21), Phone分类(ids: 3, 4)下，总共销售了10个单位(5 + 5)
没有销售 T-Shirt 类别的商品

*/

WITH
-- 1. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, 1 AS customer_id, CAST('2020-06-01' AS DATE) AS order_date, '1' AS item_id, 10 AS quantity UNION ALL
    SELECT 2, 1, CAST('2020-06-08' AS DATE), '2', 10 UNION ALL
    SELECT 3, 2, CAST('2020-06-02' AS DATE), '1', 5  UNION ALL
    SELECT 4, 3, CAST('2020-06-03' AS DATE), '3', 5  UNION ALL
    SELECT 5, 4, CAST('2020-06-04' AS DATE), '4', 1  UNION ALL
    SELECT 6, 4, CAST('2020-06-05' AS DATE), '5', 5  UNION ALL
    SELECT 7, 5, CAST('2020-06-05' AS DATE), '1', 10 UNION ALL
    SELECT 8, 5, CAST('2020-06-14' AS DATE), '4', 5  UNION ALL
    SELECT 9, 5, CAST('2020-06-21' AS DATE), '3', 5
),

-- 2. 模拟 Items 表
Items AS (
    SELECT '1' AS item_id, 'LC Alg. Book' AS item_name, 'Book' AS item_category UNION ALL
    SELECT '2', 'LC DB. Book', 'Book' UNION ALL
    SELECT '3', 'LC SmarthPhone', 'Phone' UNION ALL
    SELECT '4', 'LC Phone', 'Phone' UNION ALL
    SELECT '5', 'LC SmartGlass', 'Glasses' UNION ALL
    SELECT '6', 'LC T-Shirt XL', 'T-Shirt'
),
-- 商品类别维度表
dim_item_category AS (
    SELECT DISTINCT item_category
    FROM Items
),
weekly_quantity as (
--  行转列
    select
        t1.item_category,
        sum(case weekday when 1 then weekday_quantity else 0 end) monday,
        sum(case weekday when 2 then weekday_quantity else 0 end) tuesday,
        sum(case weekday when 3 then weekday_quantity else 0 end) wesdnesday,
        sum(case weekday when 4 then weekday_quantity else 0 end) thursday,
        sum(case weekday when 5 then weekday_quantity else 0 end) friday,
        sum(case weekday when 6 then weekday_quantity else 0 end) saturday,
        sum(case weekday when 7 then weekday_quantity else 0 end) sunday
    from (
             -- 计算每个商品类别在每个星期几的销售数量
             select
                 t2.item_category,
                 date_format(t1.order_date,'u') weekday,
                 sum(coalesce(t1.quantity,0)) weekday_quantity
             from Orders t1
                      left join Items t2
                                on t1.item_id = t2.item_id
             group by t2.item_category,date_format(t1.order_date,'u')

         ) t1
    group by t1.item_category
)
select
    t1.item_category,
    coalesce(t2.monday,0) monday,
    coalesce(t2.tuesday,0) tuesday,
    coalesce(t2.wesdnesday,0) wesdnesday,
    coalesce(t2.thursday,0) thursday,
    coalesce(t2.friday,0) friday,
    coalesce(t2.saturday,0) saturday,
    coalesce(t2.sunday,0) sunday
from dim_item_category t1
         left join weekly_quantity t2
                   on t1.item_category = t2.item_category
order by t1.item_category;


-- 根据date_format函数的用法，可以使用 date_format(date，'EEEE') 来获取星期几的名称
-- 例如，date_format('2020-06-01', 'EEEE') 返回 'Monday'
select date_format('2020-06-01', 'EEEE');