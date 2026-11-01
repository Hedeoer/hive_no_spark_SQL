---
private: true
title: spark SQL例题
category: SQL练习
pathname: __gh__111
author: 
copyright: 
top: 0
updatedAt: 2026-04-10T09:14:55.634Z
createdAt: 2025-07-22T02:46:50.000Z
hidden: false
password: 
---




# 2025年

##  1. 两点之间的最短距离

~~~sql

/*
两点之间直线最短

`Point2D` 表:
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| x           | int  |
| y           | int  |
+-------------+------+
```
(x, y) 是该表的主键列(具有唯一值的列的组合)。
这张表的每一行表示 x-y 平面上的一个点的位置
p1(x1, y1) 和 p2(x2, y2) 这两点之间的距离是 `sqrt((x2 - x1)2 + (y2 - y1)2)` 。
编写解决方案，报告 `Point2D` 表中任意两点之间的最短距离。保留 `2` 位小数。
返回结果格式如下例所示。

示例 1:

输入:
`Point2D table`:
```
+----+----+
| x  | y  |
+----+----+
| -1 | -1 |
| 0  | 0  |
| -1 | -2 |
+----+----+
```
输出:
```
+-----------+
| shortest  |
+-----------+
| 1.00      |
+-----------+
```
解释: 最短距离是 1.00，从点 (-1, -1) 到点 (-1, -2)。

*/

WITH
-- 1. 模拟 Point2D 表
Point2D AS (
    SELECT -1 as x, -1 as y UNION ALL
    SELECT 0,  0  UNION ALL
    SELECT -1, -2
)
select
    min(distance)
from (
         select
             round(sqrt((pow(t1.x - t2.x,2) + pow(t1.y - t2.y,2)) * 1.0),2) distance
         from Point2D t1
                  cross join Point2D t2
                             on t1.x <> t2.x or t1.y <> t2.y
     ) tt;


~~~





## 2. 行转列

~~~sql


/*

表: `student`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| name      | varchar |
| continent | varchar |
+-----------+---------+
```
该表可能包含重复的行。
该表的每一行表示学生的名字和他们来自的大陆。
一所学校有来自亚洲、欧洲和美洲的学生。
编写解决方案实现对大洲 (continent) 列的 透视表 操作，使得每个学生按照姓名的字母顺序依次排列在对应的大洲下面。输出的标题应依次为美洲 (America)、亚洲 (Asia) 和欧洲 (Europe)。
测试用例的生成保证来自美国的学生人数不少于亚洲或欧洲的学生人数。
返回结果格式如下所示。

示例 1:

输入:
`Student table`:
```
+--------+-----------+
| name   | continent |
+--------+-----------+
| Jane   | America   |
| Pascal | Europe    |
| Xi     | Asia      |
| Jack   | America   |
+--------+-----------+
```
输出:
```
+---------+------+--------+
| America | Asia | Europe |
+---------+------+--------+
| Jack    | Xi   | Pascal |
| Jane    | null | null   |
+---------+------+--------+
```


*/

WITH
-- 1. 模拟 student 表
Student AS (
    SELECT 'Jane' AS name, 'America' AS continent UNION ALL
    SELECT 'Pascal', 'Europe' UNION ALL
    SELECT 'Xi', 'Asia' UNION ALL
    SELECT 'Jack', 'America'
)
/*
    -- 方式1， join方式
    rn as (
        select name,
               continent,
               row_number() over (partition by continent order by name) as rn
        from Student t1
    ),
    america_student as (
        select
            *
        from rn t2
        where continent = 'America'
    ),
    asia_student as (
        select
            *
        from rn t2
        where continent = 'Asia'
    ),
    europe_student as (
        select
            *
        from rn t2
        where continent = 'Europe'
    )
select
    t1.name as America,
    t2.name as Asia,
    t3.name as Europe
from america_student t1
left join asia_student t2
on t1.rn = t2.rn
left join europe_student t3
on t1.rn = t3.rn;

*/

-- 方式2，group by方式
select
    max(case when continent = 'America' then name end) as America,
    max(case when continent = 'Asia' then name end) as Asia,
    max(case when continent = 'Europe' then name end) as Europe
from (
         select
             name,
             continent,
             row_number() over (partition by continent order by name) as rn
         from Student t1
     ) t2
group by rn;


~~~



## 3.购买了所有商品的客户（符合所有条件的员工）

~~~sql
/*
`Customer` 表:
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| customer_id | int     |
| product_key | int     |
+-------------+---------+
```
该表可能包含重复的行。
`customer_id` 不为 `NULL`。
`product_key` 是 `Product` 表的外键(reference 列)。

`Product` 表:
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| product_key | int     |
+-------------+---------+
```
`product_key` 是这张表的主键 (具有唯一值的列) 。

编写解决方案，报告 `Customer` 表中购买了 `Product` 表中所有产品的客户的 `id`。
返回结果表 无顺序要求。
返回结果格式如下所示。

示例 1:

输入:
`Customer` 表:
```
+-------------+-------------+
| customer_id | product_key |
+-------------+-------------+
| 1           | 5           |
| 2           | 6           |
| 3           | 5           |
| 3           | 6           |
| 1           | 6           |
+-------------+-------------+
```
`Product` 表:
```
+-------------+
| product_key |
+-------------+
| 5           |
| 6           |
+-------------+
```
输出:
```
+-------------+
| customer_id |
+-------------+
| 1           |
| 3           |
+-------------+
```

*/

WITH
-- 1. 模拟 Customer 表
Customer AS (
    SELECT 1 AS customer_id, 5 AS product_key UNION ALL
    SELECT 2, 6 UNION ALL
    SELECT 3, 5 UNION ALL
    SELECT 3, 6 UNION ALL
    SELECT 1, 6
),

-- 2. 模拟 Product 表
Product AS (
    SELECT 5 AS product_key UNION ALL
    SELECT 6
)
select
    t1.customer_id
from Customer t1
left join Product t2
on t1.product_key = t2.product_key
cross join (select count(1) total_products from Product) t3
group by t1.customer_id,t3.total_products
having count(distinct t2.product_key) = t3.total_products;
~~~



## 4. 每一个商品的第一笔销售明细

~~~sql
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
~~~





## 5. 最有经验的员工

~~~sql
/*
项目表 `Project`:
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| project_id   | int     |
| employee_id  | int     |
+--------------+---------+
```
(project_id, employee_id) 是这个表的主键 (具有唯一值的列的组合)
`employee_id` 是员工表 `Employee` 的外键 (reference 列)
该表的每一行都表明具有 `employee_id` 的雇员正在处理具有 `project_id` 的项目。

员工表 `Employee`:
```
+------------------+---------+
| Column Name      | Type    |
+------------------+---------+
| employee_id      | int     |
| name             | varchar |
| experience_years | int     |
+------------------+---------+
```
`employee_id` 是这个表的主键 (具有唯一值的列)
该表的每一行都包含一名雇员的信息。

编写解决方案，报告在每一个项目中 经验最丰富 的雇员是谁。如果出现经验年数相同的情况，请报告所有具有最大经验年数的员工。
返回结果表 无顺序要求。
结果格式如下示例所示。

示例 1:

输入:
`Project` 表:
```
+-------------+-------------+
| project_id  | employee_id |
+-------------+-------------+
| 1           | 1           |
| 1           | 2           |
| 1           | 3           |
| 2           | 1           |
| 2           | 4           |
+-------------+-------------+
```
`Employee` 表:
```
+-------------+--------+------------------+
| employee_id | name   | experience_years |
+-------------+--------+------------------+
| 1           | Khaled | 3                |
| 2           | Ali    | 2                |
| 3           | John   | 3                |
| 4           | Doe    | 2                |
+-------------+--------+------------------+
```
输出:
```
+-------------+-------------+
| project_id  | employee_id |
+-------------+-------------+
| 1           | 1           |
| 1           | 3           |
| 2           | 1           |
+-------------+-------------+
```
解释: `employee_id` 为 1 和 3 的员工在 `project_id` 为 1 的项目中拥有最丰富的经验。在 `project_id` 为 2 的项目中，`employee_id` 为 1 的员工拥有最丰富的经验。*/

WITH
-- 1. 模拟 Project 表
Project AS (
    SELECT 1 AS project_id, 1 AS employee_id UNION ALL
    SELECT 1, 2 UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 2, 1 UNION ALL
    SELECT 2, 4
),

-- 2. 模拟 Employee 表
Employee AS (
    SELECT 1 AS employee_id, 'Khaled' AS name, 3 AS experience_years UNION ALL
    SELECT 2, 'Ali',    2 UNION ALL
    SELECT 3, 'John',   3 UNION ALL
    SELECT 4, 'Doe',    2
)
select
    project_id,
    employee_id
from (
         select
             t1.project_id,
             t1.employee_id,
             t2.experience_years,
             dense_rank() over (partition by t1.project_id order by t2.experience_years desc) as order_number
         from Project t1
                  left join Employee t2
                            on t1.employee_id = t2.employee_id
     ) t3
where order_number = 1;
~~~



## 6. 符合条件的书籍（符合条件的人群、没有过实习期的）

![image-20250722104650943](https://5201969.xyz/api/public/img/0888a5e665fd82f2dfacd96fccac0fdf)

~~~sql

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
left join Books t3 on t2.book_id = t3.book_id
where t3.available_from <= add_months('2019-06-23', -1);


~~~



## 7. 第二件商品（第二主责）

~~~sql
/*
表: `Users`
```
+-----------------+---------+
| Column Name     | Type    |
+-----------------+---------+
| user_id         | int     |
| join_date       | date    |
| favorite_brand  | varchar |
+-----------------+---------+
```
`user_id` 是该表的主键(具有唯一值的列)。
表中包含一位在线购物网站用户的个人信息，用户可以在该网站出售和购买商品。

表: `Orders`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| order_id    | int     |
| order_date  | date    |
| item_id     | int     |
| buyer_id    | int     |
| seller_id   | int     |
+-------------+---------+
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

编写一个解决方案, 为每个用户找出他们出售的第二件商品(按日期)的品牌是否是他们最喜欢的品牌。如果用户售出的商品少于两件, 则该用户的结果为否。
保证卖家不会在一天内卖出一件以上的商品。
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
+-----------+----------------------+
| seller_id | 2nd_item_fav_brand   |
+-----------+----------------------+
| 1         | no                   |
| 2         | yes                  |
| 3         | yes                  |
| 4         | no                   |
+-----------+----------------------+
```
解释:
id 为 1 的用户的查询结果是 no, 因为他什么也没有卖出
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
    t4.user_id,
    if(t5.item_brand is null ,'no','yes') as 2nd_item_fav_brand
from Users t4 left join  (
    -- 获取每个卖家的第二件商品
    select
        t3.seller_id,
        t3.item_id,
        t3.item_brand,
        t3.seller_rn
    from (
             select
                 t1.seller_id, t1.order_date, t2.item_brand, t1.item_id,
                 row_number() over (partition by t1.seller_id order by t1.order_date) seller_rn
             from Orders t1
                      left join Items t2
                                on t1.item_id = t2.item_id
         ) t3
    where seller_rn = 2
) t5
on t4.favorite_brand = t5.item_brand and t4.user_id = t5.seller_id;
~~~



## 8.处于中游的学生（处于得过且过的人群）

~~~sql

/*

表: `Student`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| student_id    | int     |
| student_name  | varchar |
+---------------+---------+
```
`student_id` 是该表主键(具有唯一值的列)。
`student_name` 学生名字。

表: `Exam`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| exam_id     | int     |
| student_id  | int     |
| score       | int     |
+-------------+---------+
```
(exam_id, student_id) 是该表主键(具有唯一值的列的组合)。
学生 `student_id` 在测验 `exam_id` 中得分为 `score`。

成绩处于中游的学生是指至少参加了一次测验，且得分既不是最高分也不是最低分的学生。

编写解决方案，找出在 所有 测验中都处于中游的学生 (`student_id`, `student_name`)。不要返回从来没有参加过测验的学生。
返回结果表按照 `student_id` 排序。
结果格式如下。

示例 1:

输入:
`Student` 表:
```
+------------+--------------+
| student_id | student_name |
+------------+--------------+
| 1          | Daniel       |
| 2          | Jade         |
| 3          | Stella       |
| 4          | Jonathan     |
| 5          | Will         |
+------------+--------------+
```
`Exam` 表:
```
+---------+------------+-------+
| exam_id | student_id | score |
+---------+------------+-------+
| 10      | 1          | 70    |
| 10      | 2          | 80    |
| 10      | 3          | 90    |
| 20      | 1          | 80    |
| 30      | 1          | 70    |
| 30      | 3          | 80    |
| 30      | 4          | 90    |
| 40      | 1          | 60    |
| 40      | 2          | 70    |
| 40      | 4          | 80    |
+---------+------------+-------+
```
输出:
```
+------------+--------------+
| student_id | student_name |
+------------+--------------+
| 2          | Jade         |
+------------+--------------+
```
解释:
对于测验 1: 学生 1 和 3 分别获得了最低分和最高分。
对于测验 2: 学生 1 既获得了最高分，也获得了最低分。
对于测验 3 和 4: 学生 1 和 4 分别获得了最低分和最高分。
学生 2 和 5 没有在任一场测验中获得了最高分或者最低分。
因为学生 5 从来没有参加过任何测验，所以他被排除于结果表。
由此，我们仅仅返回学生 2 的信息。

*/

WITH
-- 1. 模拟 Student 表
Student AS (
    SELECT 1 AS student_id, 'Daniel' AS student_name UNION ALL
    SELECT 2, 'Jade' UNION ALL
    SELECT 3, 'Stella' UNION ALL
    SELECT 4, 'Jonathan' UNION ALL
    SELECT 5, 'Will'
),

-- 2. 模拟 Exam 表
Exam AS (
    SELECT 10 AS exam_id, 1 AS student_id, 70 AS score UNION ALL
    SELECT 10, 2, 80 UNION ALL
    SELECT 10, 3, 90 UNION ALL
    SELECT 20, 1, 80 UNION ALL
    SELECT 30, 1, 70 UNION ALL
    SELECT 30, 3, 80 UNION ALL
    SELECT 30, 4, 90 UNION ALL
    SELECT 40, 1, 60 UNION ALL
    SELECT 40, 2, 70 UNION ALL
    SELECT 40, 4, 80
)

select
    distinct
    t3.student_id,
    t4.student_name
from Student t4  left join (
    select
        exam_id,
        student_id,
        score_rank
    from (
             -- 计算每个学生在每次考试中的得分排名
             select
                 exam_id,
                 student_id,
                 dense_rank() over (partition by exam_id order by score) score_rank,
                 max(dense_rank() over (partition by exam_id order by score)) over (partition by exam_id) max_score_rank
             from Exam t1
         ) t2
    -- 过滤出得分既不是最高分也不是最低分的学生
    where max_score_rank >= 3 and t2.score_rank > 1 and t2.score_rank < max_score_rank
) t3
                           on t4.student_id = t3.student_id
-- 过滤掉从来没有参加过测验的学生
where t3.student_id is not null
order by t3.student_id;

~~~



## 9.判断条件(打分相关，画像相关，人群划分)

~~~sql

/*
表 `Variables`:
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| name        | varchar |
| value       | int     |
+-------------+---------+
```
在 SQL 中，`name` 是该表主键。
该表包含了存储的变量及其对应的值。

表 `Expressions`:
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| left_operand  | varchar |
| operator      | enum    |
| right_operand | varchar |
+---------------+---------+
```
在 SQL 中，`(left_operand, operator, right_operand)` 是该表主键。
该表包含了需要计算的布尔表达式。
`operator` 是枚举类型，取值于(`'<', '>', '=')`
`left_operand` 和 `right_operand` 的值保证存在于 `Variables` 表单中。

计算表 `Expressions` 中的布尔表达式。
返回的结果表 无顺序要求。
结果格式如下例所示。

示例 1:

输入:
`Variables` 表:
```
+------+-------+
| name | value |
+------+-------+
| x    | 66    |
| y    | 77    |
+------+-------+
```
`Expressions` 表:
```
+--------------+----------+---------------+
| left_operand | operator | right_operand |
+--------------+----------+---------------+
| x            | >        | y             |
| x            | <        | y             |
| x            | =        | y             |
| y            | >        | x             |
| y            | <        | x             |
| x            | =        | x             |
+--------------+----------+---------------+
```
输出:
```
+--------------+----------+---------------+-------+
| left_operand | operator | right_operand | value |
+--------------+----------+---------------+-------+
| x            | >        | y             | false |
| x            | <        | y             | true  |
| x            | =        | y             | false |
| y            | >        | x             | true  |
| y            | <        | x             | false |
| x            | =        | x             | true  |
+--------------+----------+---------------+-------+
```
解释:
如上所示，你需要通过使用 `Variables` 表来找到 `Expressions` 表中的每一个布尔表达式的值。

*/

WITH
-- 1. 模拟 Variables 表
Variables AS (
    SELECT 'x' AS name, 66 AS value UNION ALL
    SELECT 'y', 77
),

-- 2. 模拟 Expressions 表
Expressions AS (
    SELECT 'x' AS left_operand, '>' AS operator, 'y' AS right_operand
    UNION ALL
    SELECT 'x', '<', 'y' UNION ALL
    SELECT 'x', '=', 'y' UNION ALL
    SELECT 'y', '>', 'x' UNION ALL
    SELECT 'y', '<', 'x' UNION ALL
    SELECT 'x', '=', 'x'
)
select
    left_operand,
    operator,
    right_operand,
    -- 嵌套case 语句来计算布尔表达式的值
    case operator
        when '>' then case when left_value > right_value then 'true' else 'false' end
        when '<' then case when left_value < right_value then 'true' else 'false' end
        when '=' then case when left_value = right_value then 'true' else 'false' end
        end as value
from (
         -- 将 Expressions 表中的操作数与 Variables 表中的值进行关联获取变量的值
         select t1.left_operand,
                t1.operator,
                t1.right_operand,
                t2.value left_value,
                t3.value right_value
         from Expressions t1
                  -- 左连接 Variables 表两次,Variables变量唯一，不会导致数据膨胀
                  left join Variables t2
                            on t1.left_operand = t2.name
                  left join Variables t3
                            on t1.right_operand = t3.name
     ) t4;

~~~



## 10 以投资的国家(部门有效工时大于公司有效工时)

~~~sql
/*

表 `Person`:
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| id           | int     |
| name         | varchar |
| phone_number | varchar |
+--------------+---------+
```
id 是该表具有唯一值的列。
该表每一行包含一个人的名字和电话号码。
电话号码的格式是：'xxx-yyyyyyy'，其中 xxx 是国家码(3 个字符)，yyyyyyy 是电话号码(7 个字符)，x 和 y 都表示数字。同时，国家码和电话号码都可以包含前导 0。

表 `Country`:
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| name         | varchar |
| country_code | varchar |
+--------------+---------+
```
country_code 是该表具有唯一值的列。
该表每一行包含国家名和国家码。country_code 的格式是 'xxx'，x 是数字。

表 `Calls`:
```
+-----------+---------+
| Column Name | Type  |
+-----------+---------+
| caller_id | int     |
| callee_id | int     |
| duration  | int     |
+-----------+---------+
```
该表无主键，可能包含重复行。
每一行包含呼叫方 id，被呼叫方 id 和以分钟为单位的通话时长。caller_id != callee_id
一家电信公司想要投资新的国家。该公司想要投资的国家是： 该国的平均通话时长要严格地大于全球平均通话时长。
写一个解决方案，找到所有该公司可以投资的国家。
返回的结果表 无顺序要求。
结果格式如下例所示。

示例 1:

输入:
`Person` 表:
```
+----+----------+--------------+
| id | name     | phone_number |
+----+----------+--------------+
| 3  | Jonathan | 051-1234567  |
| 12 | Elvis    | 051-7654321  |
| 1  | Moncef   | 212-1234567  |
| 2  | Maroua   | 212-6523651  |
| 7  | Meir     | 972-1234567  |
| 9  | Rachel   | 972-0011100  |
+----+----------+--------------+
```
`Country` 表:
```
+---------+--------------+
| name    | country_code |
+---------+--------------+
| Peru    | 051          |
| Israel  | 972          |
| Morocco | 212          |
| Germany | 049          |
| Ethiopia| 251          |
+---------+--------------+
```
`Calls` 表:
```
+-----------+-----------+----------+
| caller_id | callee_id | duration |
+-----------+-----------+----------+
| 1         | 9         | 33       |
| 2         | 9         | 4        |
| 1         | 2         | 59       |
| 3         | 12        | 102      |
| 3         | 12        | 330      |
| 12        | 3         | 5        |
| 7         | 9         | 13       |
| 7         | 1         | 3        |
| 9         | 7         | 1        |
| 1         | 7         | 7        |
+-----------+-----------+----------+
```
输出:
```
+---------+
| country |
+---------+
| Peru    |
+---------+
```
解释:
国家 Peru 的平均通话时长是 (102 + 102 + 330 + 330 + 5 + 5) / 6 = 145.666667
国家 Israel 的平均通话时长是 (33 + 4 + 13 + 13 + 3 + 1 + 1 + 7) / 8 = 9.37500
国家 Morocco 的平均通话时长是 (33 + 4 + 59 + 59 + 3 + 7) / 6 = 27.5000
全球平均通话时长 = (2 * (33 + 4 + 59 + 102 + 330 + 5 + 13 + 3 + 1 + 7)) / 20 = 55.70000
所以，Peru 是唯一的平均通话时长大于全球平均通话时长的国家，也是唯一的推荐投资的国家。
*/

WITH
-- 1. 模拟 Person 表
Person AS (
    SELECT 3 AS id, 'Jonathan' AS name, '051-1234567' AS phone_number UNION ALL
    SELECT 12, 'Elvis', '051-7654321' UNION ALL
    SELECT 1, 'Moncef', '212-1234567' UNION ALL
    SELECT 2, 'Maroua', '212-6523651' UNION ALL
    SELECT 7, 'Meir', '972-1234567' UNION ALL
    SELECT 9, 'Rachel', '972-0011100'
),

-- 2. 模拟 Country 表
Country AS (
    SELECT 'Peru' AS name, '051' AS country_code UNION ALL
    SELECT 'Israel', '972' UNION ALL
    SELECT 'Morocco', '212' UNION ALL
    SELECT 'Germany', '049' UNION ALL
    SELECT 'Ethiopia', '251'
),

-- 3. 模拟 Calls 表
Calls AS (
    SELECT 1 AS caller_id, 9 AS callee_id, 33 AS duration UNION ALL
    SELECT 2, 9, 4 UNION ALL
    SELECT 1, 2, 59 UNION ALL
    SELECT 3, 12, 102 UNION ALL
    SELECT 3, 12, 330 UNION ALL
    SELECT 12, 3, 5 UNION ALL
    SELECT 7, 9, 13 UNION ALL
    SELECT 7, 1, 3 UNION ALL
    SELECT 9, 7, 1 UNION ALL
    SELECT 1, 7, 7
)
/*

-- 方式1
select name,
       average_country_duration,
       avg(average_country_duration) over () as average_global_duration
from (
         select
             '0' as gloabal_flag,
             t3.name,
             avg(t1.duration) as average_country_duration
         from Calls t1
                  left join Person t2
                            on t1.caller_id = t2.id
                  left join Country t3
                            on substr(t2.phone_number,0,3) = t3.country_code
         group by t3.name
     ) t4
*/


-- 方式2
select
    name
from (
         -- 每个国家的平均通话时长 和 全局的平均通话时长
         select name,
                average_country_duration,
                avg(average_country_duration) over () as average_global_duration
         from (
                  -- 计算每个国家的平均通话时长
                  select
                      t3.name,
                      avg(t1.duration) as average_country_duration
                  from Calls t1
                           left join Person t2
                                     on t1.caller_id = t2.id
                           left join Country t3
                                     on substr(t2.phone_number,0,3) = t3.country_code
                  group by t3.name
              ) t4

     ) t5
where average_country_duration > average_global_duration;

~~~



## 11 检查银行账户是否透支（假期和工作量恒定）

~~~sql
/*
用户表: `Users`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| user_id   | int     |
| user_name | varchar |
| credit    | int     |
+-----------+---------+
```
`user_id` 是这个表的主键 (具有唯一值的列)。
表中的每一列包含每一个用户当前的额度信息。

交易表: `Transactions`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| trans_id      | int     |
| paid_by       | int     |
| paid_to       | int     |
| amount        | int     |
| transacted_on | date    |
+---------------+---------+
```
`trans_id` 是这个表的主键 (具有唯一值的列)。
表中的每一列包含银行的交易信息。
ID 为 `paid_by` 的用户给 ID 为 `paid_to` 的用户转账。
力扣银行 (LCB) 帮助程序员们完成虚拟支付。我们的银行在表 Transaction 中记录每条交易信息，我们要查询每个用户的当前余额，并检查他们是否已透支 (当前额度小于 0) 。

编写解决方案报告:
`user_id` 用户 ID
`user_name` 用户名
`credit` 完成交易后的余额
`credit_limit_breached` 检查是否透支 ("Yes" 或 "No")
以任意顺序返回结果表。
结果格式见如下所示。

示例 1:

输入:
`Users` 表:
```
+---------+-----------+---------+
| user_id | user_name | credit  |
+---------+-----------+---------+
| 1       | Moustafa  | 100     |
| 2       | Jonathan  | 200     |
| 3       | Winston   | 10000   |
| 4       | Luis      | 800     |
+---------+-----------+---------+
```
`Transactions` 表:
```
+----------+---------+---------+--------+---------------+
| trans_id | paid_by | paid_to | amount | transacted_on |
+----------+---------+---------+--------+---------------+
| 1        | 1       | 3       | 400    | 2020-08-01    |
| 2        | 3       | 2       | 500    | 2020-08-02    |
| 3        | 2       | 1       | 200    | 2020-08-03    |
+----------+---------+---------+--------+---------------+
```
输出:
```
+---------+-----------+--------+-----------------------+
| user_id | user_name | credit | credit_limit_breached |
+---------+-----------+--------+-----------------------+
| 1       | Moustafa  | -100   | Yes                   |
| 2       | Jonathan  | 500    | No                    |
| 3       | Winston   | 9900   | No                    |
| 4       | Luis      | 800    | No                    |
+---------+-----------+--------+-----------------------+
```
Moustafa 在 "2020-08-01" 支付了 `$400` 并在 "2020-08-03" 收到了 `$200`，当前额度 (100 -400 +200) = -$100
Jonathan 在 "2020-08-02" 收到了 `$500` 并在 "2020-08-08" 支付了 `$200`，当前额度 (200 +500 -200) = $500
Winston 在 "2020-08-01" 收到了 `$400` 并在 "2020-08-03" 支付了 `$500`，当前额度 (10000 +400 -500) = $9900
Luis 未收到任何转账信息，额度 = $800
*/


WITH
-- 1. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, 'Moustafa' AS user_name, 100 AS credit UNION ALL
    SELECT 2, 'Jonathan', 200 UNION ALL
    SELECT 3, 'Winston', 10000 UNION ALL
    SELECT 4, 'Luis', 800
),

-- 2. 模拟 Transactions 表
Transactions AS (
    SELECT 1 AS trans_id, 1 AS paid_by, 3 AS paid_to, 400 AS amount, CAST('2020-08-01' AS DATE) AS transacted_on UNION ALL
    SELECT 2, 3, 2, 500, CAST('2020-08-02' AS DATE) UNION ALL
    SELECT 3, 2, 1, 200, CAST('2020-08-03' AS DATE)
)
select
    users.user_id,
    users.user_name,
    users.credit + coalesce(t4.current_cost_credit,0) as credit,
    case
        when users.credit + coalesce(t4.current_cost_credit,0) < 0
            then 'Yes'
            else 'No'
    end as credit_limit_breached
from Users users left join (
         -- 计算每个用户的当前成本信用,并对交易日期倒序取目前最新的记录
         select
             user_id,
             transacted_on,
             sum(amount) over(partition by user_id order by transacted_on) as current_cost_credit,
             row_number() over (partition by user_id order by transacted_on desc) rn
         from (
                  -- 将 paid_by 和 paid_to 的金额分别处理为负和正
                  select
                      paid_by as user_id,
                      -amount as amount,
                      transacted_on
                  from Transactions t1
                  union all
                  select
                      paid_to,
                      amount,
                      transacted_on
                  from Transactions t2

              ) t3
     ) t4
on t4.user_id = users.user_id and t4.rn = 1;

~~~



## 12 用户之间的通话次数和时长

~~~sql
/*
表: `Calls`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| from_id     | int     |
| to_id       | int     |
| duration    | int     |
+-------------+---------+
```
该表没有主键(具有唯一值的列)，它可能包含重复项。
该表包含 `from_id` 与 `to_id` 间的一次电话的时长。
`from_id != to_id`

编写解决方案，统计每一对用户 (person1, person2) 之间的通话次数和通话总时长，其中 `person1 < person2` 。

以任意顺序返回结果表。
返回结果格式如下示例所示。

示例 1:

输入:
`Calls` 表:
```
+---------+-------+----------+
| from_id | to_id | duration |
+---------+-------+----------+
| 1       | 2     | 59       |
| 2       | 1     | 11       |
| 1       | 3     | 20       |
| 3       | 4     | 100      |
| 3       | 4     | 200      |
| 3       | 4     | 200      |
| 4       | 3     | 499      |
+---------+-------+----------+
```
输出:
```
+---------+---------+-------------+----------------+
| person1 | person2 | call_count  | total_duration |
+---------+---------+-------------+----------------+
| 1       | 2       | 2           | 70             |
| 1       | 3       | 1           | 20             |
| 3       | 4       | 4           | 999            |
+---------+---------+-------------+----------------+
```
解释:
用户 1 和 2 打过 2 次电话, 总时长为 70 (59 + 11)。
用户 1 和 3 打过 1 次电话, 总时长为 20。
用户 3 和 4 打过 4 次电话, 总时长为 999 (100 + 200 + 200 + 499)。


*/
WITH
-- 1. 模拟 Calls 表
Calls AS (
    SELECT 1 AS from_id, 2 AS to_id, 59 AS duration UNION ALL
    SELECT 2, 1, 11 UNION ALL
    SELECT 1, 3, 20 UNION ALL
    SELECT 3, 4, 100 UNION ALL
    SELECT 3, 4, 200 UNION ALL
    SELECT 3, 4, 200 UNION ALL
    SELECT 4, 3, 499
)
/*select
    if(t1.from_id < t1.to_id, t1.from_id, t1.to_id) as person1,
    if(t1.from_id < t1.to_id, t1.to_id, t1.from_id) as person2,
    count(1) as call_count,
    sum(t1.duration) as total_duration
from Calls t1
group by if(t1.from_id < t1.to_id, t1.from_id, t1.to_id),
         if(t1.from_id < t1.to_id, t1.to_id, t1.from_id);*/

-- 方式2
select
    least(t1.from_id,t1.to_id),
    greatest(t1.from_id,t1.to_id),
    count(*) as call_count,
    sum(t1.duration) as total_duration
from Calls t1
group by  least(t1.from_id,t1.to_id),
          greatest(t1.from_id,t1.to_id);
~~~





## 13 子任务是否被执行

~~~sql
/*
表: `Tasks`
```
+-----------------+---------+
| Column Name     | Type    |
+-----------------+---------+
| task_id         | int     |
| subtasks_count  | int     |
+-----------------+---------+
```
`task_id` 具有唯一值的列。
`task_id` 表示的为主任务的id, 每一个`task_id`被分为了多个子任务(subtasks), `subtasks_count`表示为子任务的个数(n), 它的值表示了子任务的索引从1到n。
本表保证`2 <= subtasks_count<= 20`。

表: `Executed`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| task_id     | int     |
| subtask_id  | int     |
+-------------+---------+
```
`(task_id, subtask_id)` 是该表中具有唯一值的组合。
每一行表示标记为`task_id`的主任务与标记为`subtask_id`的子任务被成功执行。
本表 保证，对于每一个`task_id`, `subtask_id <= subtasks_count`。

编写解决方案报告没有被执行的 (主任务，子任务) 对，即没有被执行的 `(task_id, subtask_id)` 。
以 任何顺序 返回即可。
查询结果格式如下。

示例 1:

输入:
`Tasks` 表:
```
+---------+----------------+
| task_id | subtasks_count |
+---------+----------------+
| 1       | 3              |
| 2       | 2              |
| 3       | 4              |
+---------+----------------+
```
`Executed` 表:
```
+---------+------------+
| task_id | subtask_id |
+---------+------------+
| 1       | 2          |
| 3       | 1          |
| 3       | 2          |
| 3       | 3          |
| 3       | 4          |
+---------+------------+
```
输出:
```
+---------+------------+
| task_id | subtask_id |
+---------+------------+
| 1       | 1          |
| 1       | 3          |
| 2       | 1          |
| 2       | 2          |
+---------+------------+
```
解释:
Task 1 被分成了 3 subtasks (1, 2, 3)。只有 subtask 2 被成功执行, 所以我们返回 (1, 1) 和 (1, 3) 这两个主任务子任务对。
Task 2 被分成了 2 subtasks (1, 2)。没有一个subtask被成功执行, 因此我们返回(2, 1)和(2, 2)。
Task 3 被分成了 4 subtasks (1, 2, 3, 4)。所有的subtask都被成功执行, 因此对于Task 3,我们不返回任何值。
*/

WITH
-- 1. 模拟 Tasks 表
Tasks AS (
    SELECT 1 AS task_id, 3 AS subtasks_count UNION ALL
    SELECT 2, 2 UNION ALL
    SELECT 3, 4
),

-- 2. 模拟 Executed 表
Executed AS (
    SELECT 1 AS task_id, 2 AS subtask_id UNION ALL
    SELECT 3, 1 UNION ALL
    SELECT 3, 2 UNION ALL
    SELECT 3, 3 UNION ALL
    SELECT 3, 4
)
select
    t2.task_id,
    t2.subtask_id
from (
         select
             t1.task_id,
             t2.pos + 1 as subtask_id
         from Tasks t1
             lateral view posexplode(split(repeat(',',t1.subtasks_count - 1), ',')) t2 as pos, task
     ) t2
         left join Executed t3
                   on t2.task_id = t3.task_id and t2.subtask_id = t3.subtask_id
where t3.task_id is null



~~~



##  14 推荐页面

~~~sql
/*
 推荐页面
表: `Friendship`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| user1_id  | int     |
| user2_id  | int     |
+-----------+---------+
```
(user1_id, user2_id) 是 Friendship 表的主键(具有唯一值的列的组合)。
该表的每一行表示用户user1_id和user2_id是好友。

表: `Likes`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| user_id   | int     |
| page_id   | int     |
+-----------+---------+
```
(user_id, page_id) 是 Likes 表的主键(具有唯一值的列)。
该表的每一行表示user_id喜欢page_id。

您正在为一个社交媒体网站实施一个页面推荐系统。如果页面被user_id的 至少一个朋友喜欢，而 不被user_id喜欢，你的系统将 推荐 一个页面到user_id。

编写一个解决方案来查找针对每个用户的所有可能的 页面建议。每个建议应该在结果表中显示为一行，包含以下列：
- `user_id`: 系统向其提出建议的用户的ID。
- `page_id`: 推荐为 `user_id` 的页面ID。
- `friends_likes`: `user_id` 对应 `page_id` 的好友数。

以 任意顺序 返回结果表。
返回结果格式示例如下。

示例 1:
输入:
`Friendship` 表:
```
+----------+----------+
| user1_id | user2_id |
+----------+----------+
| 1        | 2        |
| 1        | 3        |
| 1        | 4        |
| 2        | 3        |
| 2        | 4        |
| 2        | 5        |
| 6        | 1        |
+----------+----------+
```
`Likes` 表:
```
+---------+---------+
| user_id | page_id |
+---------+---------+
| 1       | 88      |
| 2       | 23      |
| 3       | 24      |
| 4       | 56      |
| 5       | 11      |
| 6       | 33      |
| 2       | 77      |
| 3       | 77      |
| 6       | 88      |
+---------+---------+
```
输出:
```
+---------+---------+---------------+
| user_id | page_id | friends_likes |
+---------+---------+---------------+
| 1       | 77      | 2             |
| 1       | 23      | 1             |
| 1       | 24      | 1             |
| 1       | 56      | 1             |
| 1       | 33      | 1             |
| 2       | 24      | 1             |
| 2       | 56      | 1             |
| 2       | 11      | 1             |
| 2       | 88      | 1             |
| 3       | 88      | 1             |
| 3       | 23      | 1             |
| 4       | 88      | 1             |
| 4       | 77      | 1             |
| 4       | 23      | 1             |
| 5       | 77      | 1             |
| 5       | 23      | 1             |
+---------+---------+---------------+
```
解释:
以用户1为例:
- 用户1是用户2、3、4、6的好友。
- 推荐页面有23(用户2喜欢), 24(用户3喜欢), 56(用户4喜欢), 33(用户6喜欢), 77(用户2和用户3喜欢)。
- 请注意，第88页不推荐，因为用户1已经喜欢它。

另一个例子是用户6:
- 用户6是用户1的好友。
- 用户1只喜欢了88页，但用户6已经喜欢了。因此，用户6没有推荐。

您可以使用者类似的过程为用户2、3、4和5推荐页面。
*/
WITH
-- 1. 模拟 Friendship 表
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 1, 4 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 2, 5 UNION ALL
    SELECT 6, 1
),

-- 2. 模拟 Likes 表
Likes AS (
    SELECT 1 AS user_id, 88 AS page_id UNION ALL
    SELECT 2, 23 UNION ALL
    SELECT 3, 24 UNION ALL
    SELECT 4, 56 UNION ALL
    SELECT 5, 11 UNION ALL
    SELECT 6, 33 UNION ALL
    SELECT 2, 77 UNION ALL
    SELECT 3, 77 UNION ALL
    SELECT 6, 88
),
    -- 3. 获取所有好友关系
    all_friends AS (
        SELECT DISTINCT user1_id AS user_id, user2_id AS friend_id FROM Friendship
        UNION
        SELECT DISTINCT user2_id AS user_id, user1_id AS friend_id FROM Friendship
    ),
    -- 4. 获取用户和好友喜欢的页面情况
    page_like_sutuation as (
        select
            t1.user_id,
            t2.page_id user_like_page_id,
            t1.friend_id,
            t3.page_id friend_like_page_id
        from all_friends t1
                 left join Likes t2
                           on t1.user_id = t2.user_id
                 left join Likes t3
                           on t1.friend_id = t3.user_id
    )
select
    user_id,
    friend_like_page_id as page_id,
    -- 统计有多少好友喜欢了这个页面
    count(distinct friend_id) as friends_likes
from page_like_sutuation t1
-- 过滤掉用户自己喜欢的页面
where user_like_page_id <> friend_like_page_id
-- 对所有用户和好友喜欢的页面进行分组
group by user_id,friend_like_page_id;
~~~



## 15 账户情况

~~~sql

/*
账户情况
表: `Accounts`
```
+-------------+---------+
| 列名        | 类型    |
+-------------+---------+
| account_id  | int     |
| income      | int     |
+-------------+---------+
```
在 SQL 中, `account_id` 是这个表的主键。
每一行都包含一个银行帐户的月收入的信息。
查询每个工资类别的银行账户数量。工资类别如下:
- "Low Salary": 所有工资 严格低于 20000 美元。
- "Average Salary": 包含 范围内的所有工资 [\$20000, \$50000] 。
- "High Salary": 所有工资 严格大于 50000 美元。
结果表 必须 包含所有三个类别。 如果某个类别中没有帐户，则报告 0 。
按 任意顺序 返回结果表。
查询结果格式如下示例。

示例 1:

输入:
`Accounts` 表:
```
+-------------+--------+
| account_id  | income |
+-------------+--------+
| 3           | 108939 |
| 2           | 12747  |
| 8           | 87709  |
| 6           | 91796  |
+-------------+--------+
```
输出:
```
+----------------+----------------+
| category       | accounts_count |
+----------------+----------------+
| Low Salary     | 1              |
| Average Salary | 0              |
| High Salary    | 3              |
+----------------+----------------+
```
解释:
低薪: 有一个账户 2.
中等薪水: 没有.
高薪: 有三个账户, 他们是 3, 6和 8.
*/
WITH
-- 1. 模拟 Accounts 表
Accounts AS (
    SELECT 3 AS account_id, 108939 AS income UNION ALL
    SELECT 2, 12747  UNION ALL
    SELECT 8, 87709  UNION ALL
    SELECT 6, 91796
)
select
    t1.category,
    nvl(t2.accounts_count, 0) as accounts_count
from (
    select explode(`array`('Low Salary', 'Average Salary','High Salary')) category
     ) t1
left join (
    select
        case
            when t1.income < 20000 then 'Low Salary'
            when t1.income >= 20000 and t1.income <= 50000 then 'Average Salary'
            when t1.income > 50000 then 'High Salary'
            end as category,
        count(t1.account_id) as accounts_count
    from Accounts t1
    group by
        case
            when t1.income < 20000 then 'Low Salary'
            when t1.income >= 20000 and t1.income <= 50000 then 'Average Salary'
            when t1.income > 50000 then 'High Salary'
            end
) t2
on t1.category = t2.category;
~~~



## 16 推荐歌曲(查找共同点)

~~~sql
/*
表: `Listens`
```
+-----------+---------+
| Column Name | Type  |
+-----------+---------+
| user_id   | int     |
| song_id   | int     |
| day       | date    |
+-----------+---------+
```
这个表没有主键，可能存在重复项。
表中的每一行表示用户 `user_id` 在 `day` 这一天收听的歌曲 `song_id`。

表: `Friendship`
```
+-----------+---------+
| Column Name | Type  |
+-----------+---------+
| user1_id  | int     |
| user2_id  | int     |
+-----------+---------+
```
(user1_id, user2_id) 是这个表的主键。
表中的每一行表示 `user1_id` 和 `user2_id` 是好友。
注意，`user1_id < user2_id`。

写出 SQL 语句，为 Leetcodify 用户推荐好友。我们将符合下列条件的用户 `x` 推荐给用户 `y`：
用户 `x` 和 `y` 不是好友，且
用户 `x` 和 `y` 在同一天收听了相同的三首或更多不同歌曲。
注意，好友推荐是单向的，这意味着如果用户 `x` 和用户 `y` 需要互相推荐给对方，结果表需要将用户 `x` 推荐给用户 `y` 并将用户 `y` 推荐给用户 `x`。另外，结果表不得出现重复项（即，用户 `y` 不可多次推荐给用户 `x`）。
按任意顺序返回结果表。

查询格式如下示例所示:

示例 1:

输入:
`Listens` 表:
```
+---------+---------+------------+
| user_id | song_id | day        |
+---------+---------+------------+
| 1       | 10      | 2021-03-15 |
| 1       | 11      | 2021-03-15 |
| 1       | 12      | 2021-03-15 |
| 2       | 10      | 2021-03-15 |
| 2       | 11      | 2021-03-15 |
| 2       | 12      | 2021-03-15 |
| 3       | 10      | 2021-03-15 |
| 3       | 11      | 2021-03-15 |
| 3       | 12      | 2021-03-15 |
| 4       | 10      | 2021-03-15 |
| 4       | 11      | 2021-03-15 |
| 4       | 13      | 2021-03-15 |
| 5       | 10      | 2021-03-16 |
| 5       | 11      | 2021-03-16 |
| 5       | 12      | 2021-03-16 |
+---------+---------+------------+
```
`Friendship` 表:
```
+----------+----------+
| user1_id | user2_id |
+----------+----------+
| 1        | 2        |
+----------+----------+
```
输出:
```
+---------+----------------+
| user_id | recommended_id |
+---------+----------------+
| 1       | 3              |
| 2       | 3              |
| 3       | 1              |
| 3       | 2              |
+---------+----------------+
```
解释
用户 `1` 和 `2` 在同一天收听了歌曲 `10`、`11` 和 `12`，但他们已经是好友了。
用户 `1` 和 `3` 在同一天收听了歌曲 `10`、`11` 和 `12`。由于他们不是好友，所以我们给他们互相推荐为好友。
用户 `1` 和 `4` 没有收听三首相同的歌曲。
用户 `1` 和 `5` 收听了歌曲 `10`、`11` 和 `12`，但不是在同一天收听的。

类似地，我们可以发现用户 `2` 和 `3` 在同一天收听了歌曲 `10`、`11` 和 `12`，且他们不是好友，所以我们给他们互相推荐为好友。


*/



WITH
-- 1. 模拟 Listens 表
Listens AS (
    SELECT 1 AS user_id, 10 AS song_id, CAST('2021-03-15' AS DATE) AS day UNION ALL
    SELECT 1, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 1, 12, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 2, 10, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 2, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 2, 12, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 3, 10, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 3, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 3, 12, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 4, 10, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 4, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 4, 13, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 5, 10, CAST('2021-03-16' AS DATE) UNION ALL
    SELECT 5, 11, CAST('2021-03-16' AS DATE) UNION ALL
    SELECT 5, 12, CAST('2021-03-16' AS DATE)
),

-- 2. 模拟 Friendship 表
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id
),
-- 3. 计算每个用户在每一天收听的歌曲数量在3首或以上的用户对
user_limit as (
    select user_id,
           song_id,
           day
    from (
             select user_id,
                    song_id,
                    day,
                    count(distinct song_id) over (partition by user_id, day) as song_count
             from Listens t1

         ) t2
    where song_count >= 3
    group by song_id, user_id, day
),
distinct_user_pair as (
    select
        user_id,
        recommended_id
    from (
             select
                 t1.user_id,
                 t2.user_id as recommended_id,
                 t1.song_id,
                 t1.day,
                 -- 计算不为好友的用户对在同一天收听相同歌曲的数量
                 count(distinct t1.song_id) over(partition by t1.user_id, t2.user_id, t1.day) as song_count
             from user_limit t1
                      -- 选择不同的用户对,对于同一天和同一首歌
                      inner join user_limit t2
                 -- 减少重复计算，比如《用户1 和用户2》，《用户2 和 用户1》是相同的
                                 on t1.user_id < t2.user_id
                                     and t1.day = t2.day
                                     and t1.song_id = t2.song_id
                 -- 排除已经是好友的用户对
                      left join Friendship t3
                                on t1.user_id = t3.user1_id
                                    and t2.user_id = t3.user2_id
             where t3.user1_id is null
         ) t4
    where song_count >= 3
    group by user_id,
             recommended_id
)
-- 4. 返回单向推荐的用户对
select user_id,recommended_id from distinct_user_pair
union  all
select recommended_id,user_id from distinct_user_pair;

-- 第二种简化写法
/*
WITH L AS(
    SELECT user_id, song_id, day
    FROM Listens
    GROUP BY user_id, song_id, day
),
T AS(
    SELECT L1.user_id AS u1_id, L2.user_id AS u2_id, L1.day, L1.song_id
    FROM L L1, L L2
    WHERE L1.day = L2.day AND L1.song_id = L2.song_id AND L1.user_id < L2.user_id
),
D AS(
    SELECT u1_id, u2_id, day
    FROM T
    GROUP BY u1_id, u2_id, day HAVING COUNT(*) >= 3
),
ANS AS(
    SELECT u1_id, u2_id
    FROM D
    GROUP BY u1_id, u2_id
    EXCEPT
    SELECT * FROM Friendship
)
SELECT u1_id AS user_id, u2_id AS recommended_id FROM ANS
UNION
SELECT u2_id, u1_id FROM ANS
EXCEPT
SELECT user2_id, user1_id FROM Friendship
*/
~~~



## 17 坚定的友谊

~~~sql
/*
表名: `Friendship`
```
+-----------+---------+
| 列名      | 类型    |
+-----------+---------+
| user1_id  | int     |
| user2_id  | int     |
+-----------+---------+
```
(user1_id, user2_id) 是这个表的主键 (具有唯一值的列的组合)。
这张表的每一行都表示用户 user1_id 和 user2_id 是朋友。
请注意, user1_id < user2_id。

如果 x 和 y 为朋友 且他们 至少 有三个共同的朋友，那么 x 和 y 之间的友谊就是 坚定的。
写一个解决方案来找到所有的 坚定的友谊。
注意, 结果表不应该包含重复的行, 并且 user1_id < user2_id。
以 任何顺序 返回结果表。
返回结果格式如下所示。

示例 1:
输入:
`Friendship table`:
```
+----------+----------+
| user1_id | user2_id |
+----------+----------+
| 1        | 2        |
| 1        | 3        |
| 2        | 3        |
| 1        | 4        |
| 2        | 4        |
| 1        | 5        |
| 2        | 5        |
| 1        | 7        |
| 3        | 7        |
| 1        | 6        |
| 3        | 6        |
| 2        | 6        |
+----------+----------+
```
输出:
```
+----------+----------+-----------------+
| user1_id | user2_id | common_friend   |
+----------+----------+-----------------+
| 1        | 2        | 4               |
| 1        | 3        | 3               |
+----------+----------+-----------------+
```
解释:
用户 1 和 2 有 4 个共同的朋友 (3, 4, 5, 和 6)。
用户 1 和 3 有 3 个共同的朋友 (2, 6, 和 7)。
但这里不包括用户 2 和 3 的友谊, 因为他们只有两个共同的朋友 (1 和 6)。

*/

WITH
-- 1. 模拟 Friendship 表数据
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 1, 4 UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 1, 5 UNION ALL
    SELECT 2, 5 UNION ALL
    SELECT 1, 7 UNION ALL
    SELECT 3, 7 UNION ALL
    SELECT 1, 6 UNION ALL
    SELECT 3, 6 UNION ALL
    SELECT 2, 6
),
    -- 2. 获取所有用户的好友对
    all_pairs AS (
        select user1_id as user_id, user2_id as friend_id from Friendship t1
        union all
        select user2_id, user1_id from Friendship t1
    )
select
    user_id user1_id,
    friend_id user2_id,
    count(distinct recommended_id1) as common_friend
from (
         select
             t1.user1_id user_id,
             t1.user2_id friend_id,
             t2.friend_id as recommended_id1,
             t3.friend_id as recommended_id2
         from Friendship t1
                  left join all_pairs t2
             -- 查询各个用户的好友，
                            on t1.user1_id = t2.user_id
                  left join all_pairs t3
             -- 查询各个用户的好友的好友
                            on t1.user2_id = t3.user_id
         where t2.friend_id = t3.friend_id
     ) t3
group by
    user_id,
    friend_id
having count(distinct recommended_id1) >= 3
~~~



##  18 用户满意度

````sql
/*
表: `Signups`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| user_id     | int      |
| time_stamp  | datetime |
+-------------+----------+
```
`User_id`是该表的主键。
每一行都包含 ID 为`user_id`的用户的注册时间信息。

表: `Confirmations`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| user_id     | int      |
| time_stamp  | datetime |
| action      | ENUM     |
+-------------+----------+
```
`(user_id, time_stamp)`是该表的主键。
`user_id`是一个引用到注册表的外键。
`action`是类型为`('confirmed', 'timeout')`的ENUM
该表的每一行都表示ID为`user_id`的用户在`time_stamp`请求了一条确认消息，该确认消息要么被确认(`'confirmed'`)，要么被过期(`'timeout'`)。

用户的确认率是 `'confirmed'` 消息的数量除以请求的确认消息的总数。没有请求任何确认消息的用户的确认率为 `0`。确认率四舍五入到小数点后两位。
编写一个SQL查询来查找每个用户的确认率。

以任意顺序返回结果表。

查询结果格式如下所示。

示例1:
输入:
`Signups` 表:
```
+---------+---------------------+
| user_id | time_stamp          |
+---------+---------------------+
| 3       | 2020-03-21 10:16:13 |
| 7       | 2020-01-04 13:57:59 |
| 2       | 2020-07-29 23:09:44 |
| 6       | 2020-12-09 10:39:37 |
+---------+---------------------+
```
`Confirmations` 表:
```
+---------+---------------------+-----------+
| user_id | time_stamp          | action    |
+---------+---------------------+-----------+
| 3       | 2021-01-06 03:30:46 | timeout   |
| 3       | 2021-07-14 14:00:00 | timeout   |
| 7       | 2021-06-12 11:57:29 | confirmed |
| 7       | 2021-06-13 12:58:28 | confirmed |
| 7       | 2021-06-14 13:59:27 | confirmed |
| 2       | 2021-01-22 00:00:00 | confirmed |
| 2       | 2021-02-28 23:59:59 | timeout   |
+---------+---------------------+-----------+
```
输出:
```
+---------+-------------------+
| user_id | confirmation_rate |
+---------+-------------------+
| 6       | 0.00              |
| 3       | 0.00              |
| 7       | 1.00              |
| 2       | 0.50              |
+---------+-------------------+
```
解释:
用户 `6` 没有请求任何确认消息。确认率为 `0`。
用户 `3` 进行了 `2` 次请求，都超时了。确认率为 `0`。
用户 `7` 提出了 `3` 个请求，所有请求都得到了确认。确认率为 `1`。
用户 `2` 做了 `2` 个请求，其中一个被确认，另一个超时。确认率为 `1 / 2 = 0.5`。
*/

WITH
-- 1. 模拟 Signups 表
Signups AS (
    SELECT 3 AS user_id, CAST('2020-03-21 10:16:13' AS TIMESTAMP) AS time_stamp UNION ALL
    SELECT 7, CAST('2020-01-04 13:57:59' AS TIMESTAMP) UNION ALL
    SELECT 2, CAST('2020-07-29 23:09:44' AS TIMESTAMP) UNION ALL
    SELECT 6, CAST('2020-12-09 10:39:37' AS TIMESTAMP)
),

-- 2. 模拟 Confirmations 表
Confirmations AS (
    SELECT 3 AS user_id, CAST('2021-01-06 03:30:46' AS TIMESTAMP) AS time_stamp, 'timeout' AS action UNION ALL
    SELECT 3, CAST('2021-07-14 14:00:00' AS TIMESTAMP), 'timeout' UNION ALL
    SELECT 7, CAST('2021-06-12 11:57:29' AS TIMESTAMP), 'confirmed' UNION ALL
    SELECT 7, CAST('2021-06-13 12:58:28' AS TIMESTAMP), 'confirmed' UNION ALL
    SELECT 7, CAST('2021-06-14 13:59:27' AS TIMESTAMP), 'confirmed' UNION ALL
    SELECT 2, CAST('2021-01-22 00:00:00' AS TIMESTAMP), 'confirmed' UNION ALL
    SELECT 2, CAST('2021-02-28 23:59:59' AS TIMESTAMP), 'timeout'
)
select
    t1.user_id,
    round(coalesce(t2.confirmation_rate, 0.00), 2) as confirmation_rate
from Signups t1
         left join (
    select
        user_id,
        count(if(action = 'confirmed', 1, null)) / count(*) as confirmation_rate
    from Confirmations t1
    group by user_id
) t2
                   on t1.user_id = t2.user_id
````



## 19 第一个和最后一个是同一人

~~~sql
/*
表: `Calls`
```
+----------------+----------+
| Column Name    | Type     |
+----------------+----------+
| caller_id      | int      |
| recipient_id   | int      |
| call_time      | datetime |
+----------------+----------+
```
`(caller_id, recipient_id, call_time)` 是这个表的主键。
每一行所含的时间信息都是关于`caller_id` 和`recipient_id`的。

编写一个 SQL 查询来找出那些ID们在任意一天的第一个电话和最后一个电话都是和同一个人。这些电话不论是拨打者还是接收者都会被记录。
结果请放在一个任意次序约定的表中。
查询结果格式如下所示:

输入:
`Calls table`:
```
+-----------+--------------+---------------------+
| caller_id | recipient_id | call_time           |
+-----------+--------------+---------------------+
| 8         | 4            | 2021-08-24 17:46:07 |
| 4         | 8            | 2021-08-24 19:57:13 |
| 5         | 1            | 2021-08-11 05:28:44 |
| 8         | 3            | 2021-08-17 04:04:15 |
| 11        | 3            | 2021-08-17 13:07:00 |
| 8         | 11           | 2021-08-17 22:22:22 |
+-----------+--------------+---------------------+
```
输出:
```
+---------+
| user_id |
+---------+
| 1       |
| 4       |
| 5       |
| 8       |
+---------+
```
解释:
在 2021-08-24, 这天的第一个电话和最后一个电话都是在user 8和user 4之间。user8应该被包含在答案中。
同样的，user 4在2021-08-24的第一个电话和最后一个电话都是和user 8的。user 4也应该被包含在答案中。
在 2021-08-11, user 1和5有一个电话。这个电话是他们彼此当天的唯一一个电话。因此这个电话是他们当天的第一个电话也是最后一个电话，他们都应该被包含在答案中。


-- 窗口函数中使用了 ORDER BY，Hive 会启用一个默认的窗口框架（Window Frame），这个框架是 RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

*/
WITH
-- 1. 模拟 Calls 表
Calls AS (
    SELECT 8 AS caller_id, 4 AS recipient_id, CAST('2021-08-24 17:46:07' AS TIMESTAMP) AS call_time UNION ALL
    SELECT 4, 8, CAST('2021-08-24 19:57:13' AS TIMESTAMP) UNION ALL
    SELECT 5, 1, CAST('2021-08-11 05:28:44' AS TIMESTAMP) UNION ALL
    SELECT 8, 3, CAST('2021-08-17 04:04:15' AS TIMESTAMP) UNION ALL
    SELECT 11, 3, CAST('2021-08-17 13:07:00' AS TIMESTAMP) UNION ALL
    SELECT 8, 11, CAST('2021-08-17 22:22:22' AS TIMESTAMP)
),
    user_pairs as (
        select
            user1_id,
            user2_id
        from (
                 select
                     user1_id,
                     user2_id,
                     call_time,
                     call_date,
                     first_value(hash_value) over(partition by call_date order by call_time) as first_hash,
                     first_value(hash_value) over(partition by call_date order by call_time desc) as last_hash
                 from (
                          select
                              least(caller_id,recipient_id) user1_id,
                              greatest(caller_id,recipient_id) user2_id,
                              hash(concat(least(caller_id,recipient_id),'-', greatest(caller_id,recipient_id))) as hash_value,
                              to_date(call_time) call_date,
                              call_time
                          from Calls t1

                      ) t2
             ) t3
        where first_hash = last_hash
        group by user1_id,user2_id
    )
-- select user1_id from user_pairs
-- union all
-- select user2_id from user_pairs;

select
    case
        when idx = 1 then user1_id
        else user2_id
    end as user_id
from user_pairs t1
lateral view explode(array(1,2)) t as idx
~~~



## 20 雇佣员工（贪心算法1）

~~~sql
/*
表: `Candidates`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| employee_id | int      |
| experience  | enum     |
| salary      | int      |
+-------------+----------+
```
`employee_id`是此表的主键列。
经验是包含一个值 (“高级”、“初级”) 的枚举类型。
此表的每一行都显示候选人的id、月薪和经验。

一家公司想雇佣新员工。公司的工资预算是 `70000` 美元。公司的招聘标准是:
在雇佣最多的高级员工后，使用剩余预算雇佣最多的初级员工。
编写一个SQL查询，查找根据上述标准雇佣的高级员工和初级员工的数量。
按 任意顺序 返回结果表。
查询结果格式如下例所示。

示例 1:
输入:
`Candidates table`:
```
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 10000  |
| 9           | Junior     | 10000  |
| 2           | Senior     | 20000  |
| 11          | Senior     | 20000  |
| 13          | Senior     | 50000  |
| 4           | Junior     | 40000  |
+-------------+------------+--------+
```
输出:
```
+------------+-----------------------+
| experience | accepted_candidates   |
+------------+-----------------------+
| Senior     | 2                     |
| Junior     | 2                     |
+------------+-----------------------+
```
说明:
我们可以雇佣2名ID为 `(2,11)` 的高级员工。由于预算是7万美元，他们的工资总额是4万美元，我们还有3万美元，但他们不足以雇佣ID为`13`的高级员工。
我们可以雇佣2名ID为 `(1,9)` 的初级员工。由于剩下的预算是3万美元，他们的工资总额是2万美元，我们还有1万美元，但他们不足以雇佣ID为`4`的初级员工。

示例 2:
输入:
`Candidates table`:
```
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 10000  |
| 9           | Junior     | 10000  |
| 2           | Senior     | 80000  |
| 11          | Senior     | 80000  |
| 13          | Senior     | 80000  |
| 4           | Junior     | 40000  |
+-------------+------------+--------+
```
输出:
```
+------------+-----------------------+
| experience | accepted_candidates   |
+------------+-----------------------+
| Senior     | 0                     |
| Junior     | 3                     |
+------------+-----------------------+
```
解释:
我们不能用目前的预算雇佣任何高级员工，因为我们需要至少80000美元来雇佣一名高级员工。
我们可以用剩下的预算雇佣三名初级员工。
*/

WITH
-- 1. 模拟 Candidates 表
/*Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 10000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 20000 UNION ALL
    SELECT 11, 'Senior', 20000 UNION ALL
    SELECT 13, 'Senior', 50000 UNION ALL
    SELECT 4, 'Junior', 40000
),*/
Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 10000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 80000 UNION ALL
    SELECT 11, 'Senior', 80000 UNION ALL
    SELECT 13, 'Senior', 80000 UNION ALL
    SELECT 4, 'Junior', 40000
),
    -- 获取所有经验级别
    levels as (
        select
            distinct experience
        from Candidates
    ),
    -- 计算高级候选人的当前余额
    senior_candidates AS (
        select
            employee_id,
            current_balance
        from (
                 SELECT employee_id, salary,
                        70000 - sum(salary) OVER (ORDER BY salary) AS current_balance
                 FROM Candidates
                 WHERE experience = 'Senior'
                 ORDER BY salary
             ) t1
        where current_balance >= 0
    ),
    -- 计算高级候选人的当前余额，如果没有高级候选人，则设置最小余额为70000
    balance as (
        select
            nvl(min(current_balance),70000) as min_balance
        from senior_candidates
    ),
    -- 计算初级候选人的当前余额
    junior_candidates AS (
        select
            employee_id,
            current_balance
        from (
                 SELECT employee_id, salary,
                        balance.min_balance - sum(salary) OVER (ORDER BY salary) AS current_balance
                 FROM Candidates,balance
                 WHERE experience = 'Junior'
                 ORDER BY salary
             ) t1
        where current_balance >= 0
    )
-- 最终查询，统计每个经验级别的候选人数量
select
    tt.experience,
    nvl(t1.accepted_candidates, 0) as accepted_candidates
from levels tt
left join (
    select
        'Senior' as experience,
        count(*) as accepted_candidates
    from senior_candidates
    union all
    select
        'Junior' as experience,
        count(*) as accepted_candidates
    from junior_candidates
) t1 on tt.experience = t1.experience;


~~~



## 21 雇佣员工（贪心算法2）

~~~sql
/*
表: `Candidates`
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| employee_id | int  |
| experience  | enum |
| salary      | int  |
+-------------+------+
```
`employee_id` 是该表中具有唯一值的列。
经验是一个枚举，其中包含一个值 ("高级"、"初级")。
此表的每一行都显示候选人的id、月薪和经验。
每个候选人的工资保证是唯一的。

一家公司想雇佣新员工。公司的工资预算是 `$70000`。公司的招聘标准是:
- 继续雇佣薪水最低的高级职员，直到你不能再雇佣更多的高级职员。
- 用剩下的预算雇佣薪水最低的初级职员。
- 继续以最低的工资雇佣初级职员，直到你不能再雇佣更多的初级职员。

编写一个解决方案，查找根据上述条件雇佣职员的 ID。
按 任意顺序 返回结果表。
返回结果格式如下例所示。

示例 1:
输入:
`Candidates table`:
```
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 10000  |
| 9           | Junior     | 15000  |
| 2           | Senior     | 20000  |
| 11          | Senior     | 16000  |
| 13          | Senior     | 50000  |
| 4           | Junior     | 40000  |
+-------------+------------+--------+
```
输出:
```
+-------------+
| employee_id |
+-------------+
| 11          |
| 2           |
| 1           |
| 9           |
+-------------+
```
解释:
我们可以雇佣2名具有ID (11,2) 的高级员工。由于预算是7万美元, 他们的工资总额是3.6万美元, 我们还有3.4万美元, 但他们不足以雇佣ID为 13 的高级职员。
我们可以雇佣2名ID为 (1,9) 的初级员工。由于剩余预算为3.4万美元, 他们的工资总额为2.5万美元, 我们还有9000美元, 但他们不足以雇佣ID为 4 的初级员工。

示例 2:
输入:
`Candidates table`:
```
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 25000  |
| 9           | Junior     | 10000  |
| 2           | Senior     | 85000  |
| 11          | Senior     | 80000  |
| 13          | Senior     | 90000  |
| 4           | Junior     | 30000  |
+-------------+------------+--------+
```
输出:
```
+-------------+
| employee_id |
+-------------+
| 9           |
| 1           |
| 4           |
+-------------+
```
解释:
我们不能用目前的预算雇佣任何高级员工，因为我们需要至少 80000 美元来雇佣一名高级员工。
我们可以用剩下的预算雇佣三名初级员工。

*/

WITH
-- 1. 模拟 Candidates 表数据
-- Candidates AS (
--     SELECT 1 AS employee_id, 'Junior' AS experience, 10000 AS salary UNION ALL
--     SELECT 9, 'Junior', 15000 UNION ALL
--     SELECT 2, 'Senior', 20000 UNION ALL
--     SELECT 11, 'Senior', 16000 UNION ALL
--     SELECT 13, 'Senior', 50000 UNION ALL
--     SELECT 4, 'Junior', 40000
-- ),
Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 25000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 85000 UNION ALL
    SELECT 11, 'Senior', 80000 UNION ALL
    SELECT 13, 'Senior', 90000 UNION ALL
    SELECT 4, 'Junior', 30000
),


hired_seniors as (
    select
        employee_id,
        cost
    from (
             select
                 employee_id,
                 sum(salary) over(order by salary) cost
             from Candidates t1
             where experience = 'Senior'
         ) t2
    where cost <= 70000
),
hired_juniors as (
    select
        employee_id,
        cost
    from (
             select
                 employee_id
                  , sum(salary) over(order by salary) cost
             from Candidates
             where experience = 'Junior'
         ) t1
    where cost <= 70000 - (select nvl(max(cost),0) from hired_seniors)
)
select
    employee_id
from hired_juniors
union  all
select
    employee_id
from hired_seniors;

-- 方式2
WITH
-- 1. 使用 WITH 子句模拟您提供的 Candidates 表数据
Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 25000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 85000 UNION ALL
    SELECT 11, 'Senior', 80000 UNION ALL
    SELECT 13, 'Senior', 90000 UNION ALL
    SELECT 4, 'Junior', 30000
)

/**
第一次SUM OVER(PARTITION BY ...)，在各自组内进行“预演”，淘汰掉那些仅靠本组力量都无法入围的候选人。
第二次SUM OVER()，在全局范围内，按我们之前创建的优先级 experience_rk 排序，如果优先级相同（即都是高级或都是初级），则再按薪资 salary 排序。
  这完美地实现了**“先按薪资从低到高排列所有（备选的）高级员工，然后紧接着按薪资从低到高排列所有（备选的）初级员工”**这一最终雇佣顺序。
 */
SELECT
    employee_id
FROM
    (
        SELECT
            *,
            70000 - SUM(salary) OVER(ORDER BY experience_rk, salary) AS sum_salary2
        FROM
            (
                SELECT
                    *,
                    70000 - SUM(salary) OVER(PARTITION BY experience ORDER BY salary) AS sum_salary,
                    IF(experience = 'Senior', 1, 2) AS experience_rk
                FROM
                    Candidates
            ) t
        WHERE t.sum_salary >= 0
    ) t2
WHERE t2.sum_salary2 >= 0;
~~~



## 22 选择合适的面试候选人

~~~sql
/*
表: `Contests`
```
+--------------+------+
| Column Name  | Type |
+--------------+------+
| contest_id   | int  |
| gold_medal   | int  |
| silver_medal | int  |
| bronze_medal | int  |
+--------------+------+
```
`contest_id` 是该表的主键。
该表包含LeetCode竞赛的ID和该场比赛中金牌、银牌、铜牌的用户id。
可以保证，所有连续的比赛都有连续的ID，没有ID被跳过。

Table: `Users`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| user_id   | int     |
| mail      | varchar |
| name      | varchar |
+-----------+---------+
```
`user_id` 是该表的主键。
该表包含用户信息。

编写 SQL 语句来返回 所有面试候选人 的姓名 `name` 和邮件 `mail`。当用户满足以下两个要求中的 **任意一条**，其成为 面试候选人：
- 该用户在 **连续三场及更多** 比赛中赢得 **任意** 奖牌。
- 该用户在 **三场及更多不同**的 比赛中赢得 **金牌** (这些比赛可以不是连续的)

可以以 任何顺序 返回结果。
查询结果格式如下例所示。

示例 1:
输入:
`Contests`表:
```
+------------+------------+--------------+--------------+
| contest_id | gold_medal | silver_medal | bronze_medal |
+------------+------------+--------------+--------------+
| 190        | 1          | 5            | 2            |
| 191        | 2          | 3            | 5            |
| 192        | 5          | 2            | 3            |
| 193        | 1          | 3            | 5            |
| 194        | 4          | 5            | 2            |
| 195        | 4          | 2            | 1            |
| 196        | 1          | 5            | 2            |
+------------+------------+--------------+--------------+
```
`Users`表:
```
+---------+--------------------+--------+
| user_id | mail               | name   |
+---------+--------------------+--------+
| 1       | sarah@leetcode.com | Sarah  |
| 2       | bob@leetcode.com   | Bob    |
| 3       | alice@leetcode.com | Alice  |
| 4       | hercy@leetcode.com | Hercy  |
| 5       | quarz@leetcode.com | Quarz  |
+---------+--------------------+--------+
```
输出:
```
+--------+--------------------+
| name   | mail               |
+--------+--------------------+
| Sarah  | sarah@leetcode.com |
| Bob    | bob@leetcode.com   |
| Alice  | alice@leetcode.com |
| Quarz  | quarz@leetcode.com |
+--------+--------------------+
```
解释:
- Sarah 赢得了3块金牌 (190, 193, and 196), 所以我们将她列入结果表。
- Bob在连续3场竞赛中赢得了奖牌(190, 191, and 192), 所以我们将他列入结果表。
  - 注意他在另外的连续3场竞赛中也赢得了奖牌(194, 195, and 196).
- Alice在连续3场竞赛中赢得了奖牌(191, 192, and 193), 所以我们将她列入结果表。
- Quarz在连续5场竞赛中赢得了奖牌(190, 191, 192, 193, and 194), 所以我们将他列入结果表。


*/

WITH
-- 1. 模拟 Contests 表
Contests AS (
    SELECT 190 AS contest_id, 1 AS gold_medal, 5 AS silver_medal, 2 AS bronze_medal UNION ALL
    SELECT 191, 2, 3, 5 UNION ALL
    SELECT 192, 5, 2, 3 UNION ALL
    SELECT 193, 1, 3, 5 UNION ALL
    SELECT 194, 4, 5, 2 UNION ALL
    SELECT 195, 4, 2, 1 UNION ALL
    SELECT 196, 1, 5, 2
),

-- 2. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, 'sarah@leetcode.com' AS mail, 'Sarah' AS name UNION ALL
    SELECT 2, 'bob@leetcode.com', 'Bob' UNION ALL
    SELECT 3, 'alice@leetcode.com', 'Alice' UNION ALL
    SELECT 4, 'hercy@leetcode.com', 'Hercy' UNION ALL
    SELECT 5, 'quarz@leetcode.com', 'Quarz'
),
-- 获取连续三场及以上比赛获奖的用户，不区分奖牌类型
contious_three_medals_users as (
    select
        user_id
    from (
             select
                 user_id
             from (

                      select contest_id,
                             case idx
                                 when 1 then gold_medal
                                 when 2 then silver_medal
                                 else bronze_medal
                                 end as user_id,
                             -- 构建一个分组标识符，用于区分连续的比赛
                             contest_id - row_number() over (partition by case idx
                                                                              when 1 then gold_medal
                                                                              when 2 then silver_medal
                                                                              else bronze_medal
                                 end
                                 order by contest_id) as contest_group
                      from Contests t1
                           -- 将金银铜牌的用户ID展开
                          lateral view explode(array(1,2,3)) t as idx
                  ) t1
             -- 统计每个用户在连续比赛组中的获奖次数
             group by user_id, contest_group
             -- 筛选出满足连续三场及以上比赛获奖的用户，不区分奖牌类型
             having count(1) >= 3
         ) t2
-- 去重用户
    group by user_id
),
-- 获取三次及以上金牌的用户
gold_three_medals_users as (
    select
        distinct gold_medal as user_id
    from (
             select
                 gold_medal
             from Contests
             group by gold_medal
             having count(*) >= 3
         ) t1
)
select
    name,
    mail
from Users t1
         inner join (
    select user_id from contious_three_medals_users
    union
    select user_id from gold_three_medals_users
) t2
                    on t1.user_id = t2.user_id;
~~~



## 23 函数处理

~~~sql

/*
表: `Terms`
```
+--------+--------+
| Column Name | Type |
+--------+--------+
| power  | int    |
| factor | int    |
+--------+--------+
```
`power` 是该表具有唯一值的列。
该表的每一行包含关于方程的一项的信息。
`power` 是范围为 `[0, 100]` 的整数。
`factor` 是范围为 `[-100,100]` 的整数，且不能为零。
你有一个非常强大的程序，可以解决世界上任何单变量的方程。传递给程序的方程必须格式化如下:
左边 (LHS) 应该包含所有的术语。
右边 (RHS) 应该是零。
LHS 的每一项应遵循 `"<sign><fact>X^<pow>"` 的格式, 其中:`<sign>` 是 `"+"` 或者 `"-"`。
`<fact>` 是 `factor` 的 绝对值。
`<pow>` 是 `power` 的值。
如果幂是 `1`，不要加上 `^<pow>`。例如, 如果 `power = 1` 并且 `factor = 3`, 将有 `"+3X"`。
如果幂是 `0`，不要加上 `"X"` 和 `^<pow>`。例如, 如果 `power = 0` 并且 `factor = -3`, 将有 `"-3"`。
LHS 中的幂应该按 降序排序。
编写一个解决方案来构建方程。
结果格式如下所示。

示例 1:

输入:
`Terms` 表:
```
+-------+--------+
| power | factor |
+-------+--------+
| 2     | 1      |
| 1     | -4     |
| 0     | 2      |
+-------+--------+
```
输出:
```
+----------------+
| equation       |
+----------------+
| +1X^2-4X+2=0   |
+----------------+
```
示例 2:

输入:
`Terms` 表:
```
+-------+--------+
| power | factor |
+-------+--------+
| 4     | -4     |
| 2     | 1      |
| 1     | -1     |
+-------+--------+
```
输出:
```
+------------------+
| equation         |
+------------------+
| -4X^4+1X^2-1X=0  |
+------------------+
```

*/

-- 方式1 使用 CONCAT_WS() 和 COLLECT_LIST()
WITH
-- 1. 模拟 Terms 表 (使用示例1的数据)
Terms AS (
    SELECT 2 AS power, 1 AS factor UNION ALL
    SELECT 1, -4 UNION ALL
    SELECT 0, 2
)
select
    concat(concat_ws('',collect_list(term)), '=0') as equation
from (
         select power,
                factor,
                concat(
                        if(factor > 0, '+', '-'),
                        case when power = 0 then abs(factor)
                             when power = 1 then concat(abs(factor),'X')
                             else concat(abs(factor),'X^',power) end
                ) as term

         from Terms t1
         -- 全局排序
         order by power desc
     ) t2;


-- 方式2 使用窗口函数 COLLECT_LIST() OVER()
WITH
-- 1. 模拟 Terms 表
Terms AS (
    SELECT 2 AS power, 1 AS factor UNION ALL
    SELECT 1, -4 UNION ALL
    SELECT 0, 2
),

-- 2. 格式化每一项并使用窗口函数
CumulativeList AS (
    SELECT
        -- 使用窗口函数生成一个累积的、有序的列表
        collect_list(
                CONCAT(
                        CASE WHEN factor > 0 THEN '+' ELSE '-' END,
                        ABS(factor),
                        CASE
                            WHEN power = 0 THEN ''
                            WHEN power = 1 THEN 'X'
                            ELSE CONCAT('X^', power)
                            END
                )
        ) OVER (ORDER BY power DESC) AS term_list,
        -- 使用 row_number 标记最后一行
        row_number() OVER (ORDER BY power ASC) as rn_asc
    FROM
        Terms
)

-- 3. 筛选出最后一行并拼接
SELECT
    CONCAT(concat_ws('', term_list), '=0') AS equation
FROM
    CumulativeList
WHERE
    -- 最后一行 (按 power 升序的第一行) 包含了完整的列表
    rn_asc = 1;






~~~



## 24 每个客户年销售额（每个组员年成绩）

~~~sql
/*
表: `Orders`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| order_id     | int     |
| customer_id  | int     |
| order_date   | date    |
| price        | int     |
+--------------+---------+
```
order_id 是该表的主键。
每行包含订单的 id、订购该订单的客户 id、订单日期和价格。

编写一个 SQL 查询，报告 总购买量 每年严格增加的客户 id。

客户在一年内的 总购买量 是该年订单价格的总和。如果某一年客户没有任何订单，我们认为总购买量为 0。
对于每个客户，要考虑的第一个年是他第一次下单 的年份。
对于每个客户，要考虑的最后一年是他们 最后一次下单 的年份。

以 任意顺序 返回结果表。
查询结果格式如下所示。

示例 1:

输入:
`Orders` 表:
```
+----------+-------------+------------+-------+
| order_id | customer_id | order_date | price |
+----------+-------------+------------+-------+
| 1        | 1           | 2019-07-01 | 1100  |
| 2        | 1           | 2019-11-01 | 1200  |
| 3        | 1           | 2020-05-26 | 3000  |
| 4        | 1           | 2021-08-31 | 3100  |
| 5        | 1           | 2022-12-07 | 4700  |
| 6        | 2           | 2015-01-01 | 700   |
| 7        | 2           | 2017-11-07 | 1000  |
| 8        | 3           | 2017-01-01 | 900   |
| 9        | 3           | 2018-11-07 | 900   |
+----------+-------------+------------+-------+
```
输出:
```
+-------------+
| customer_id |
+-------------+
| 1           |
+-------------+
```
解释:
客户 1: 第一年是 2019 年, 最后一年是 2022 年
- 2019: 1100 + 1200 = 2300
- 2020: 3000
- 2021: 3100
- 2022: 4700
我们可以看到总购买量每年都在严格增加,所以我们在答案中包含了客户 1。

客户 2: 第一年是2015年, 最后一年是2017年
- 2015: 700
- 2016: 0
- 2017: 1000
我们没有把客户 2 包括在答案中, 因为总的购买量并没有严格地增加。请注意, 客户 2 在 2016 年没有购买任何物品。

客户 3: 第一年是 2017 年, 最后一年是 2018 年
- 2017: 900
- 2018: 900

*/



WITH
-- 1. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, 1 AS customer_id, CAST('2019-07-01' AS DATE) AS order_date, 1100 AS price UNION ALL
    SELECT 2, 1, CAST('2019-11-01' AS DATE), 1200 UNION ALL
    SELECT 3, 1, CAST('2020-05-26' AS DATE), 3000 UNION ALL
    SELECT 4, 1, CAST('2021-08-31' AS DATE), 3100 UNION ALL
    SELECT 5, 1, CAST('2022-12-07' AS DATE), 4700 UNION ALL
    SELECT 6, 2, CAST('2015-01-01' AS DATE), 700  UNION ALL
    SELECT 7, 2, CAST('2017-11-07' AS DATE), 1000 UNION ALL
    SELECT 8, 3, CAST('2017-01-01' AS DATE), 900  UNION ALL
    SELECT 9, 3, CAST('2018-11-07' AS DATE), 900
),
-- 1. 计算每个客户每年的总购买量
customer_yearly_totals AS (
    select
        customer_id, year(order_date) as date_year,
        sum(price) as year_cost
    from Orders t1
    group by customer_id, year(order_date)
),
-- 2. 计算每个客户的购买年份
dim_custome_years as (
    select
        t1.customer_id,
        first_year + t.idx cost_year
    from (
             select
                 customer_id,
                 min(date_year) as first_year,
                 max(date_year) as last_year
             from customer_yearly_totals
             group by customer_id
         ) t1
    LATERAL VIEW posexplode(split(space(t1.last_year - t1.first_year), ' ')) t AS idx, val
    )
select
    customer_id
from (

         select customer_id,
                cost_year,
                year_cost,
                -- 构建连续递增组
                sum(if( year_cost - previous_year_cost > 0,0,1))  over(partition by customer_id order by cost_year) as consecutive_increase_group,
                -- 计算用户购买总年数
                count(1) over(partition by customer_id) as total_years
         from (
                  -- 计算每个客户每年的总购买量和前一年总购买量
                  select
                      t1.customer_id,
                      t1.cost_year,
                      nvl(t2.year_cost, 0) as year_cost,
                      lag(nvl(t2.year_cost, 0), 1, 0) over (partition by t1.customer_id order by cost_year) as previous_year_cost
                  from dim_custome_years t1
                           left join customer_yearly_totals t2
                                     on t1.customer_id = t2.customer_id and t1.cost_year = t2.date_year
              ) t3

     ) t4
-- 连续递增，则只考虑具有2年及以上的客户
where total_years > 1
group by customer_id, total_years,  consecutive_increase_group
-- 所有年都严格递增
having count(1) = total_years

~~~

## 25 同一个大厅举办的重叠活动

~~~sql
/*
表: `HallEvents`
```
+-----------+------+
| Column Name| Type |
+-----------+------+
| hall_id   | int  |
| start_day | date |
| end_day   | date |
+-----------+------+
```
该表可能包含重复字段。
该表的每一行表示活动的开始日期和结束日期，以及活动举行的大厅。

编写解决方案，合并在 同一个大厅举行的 所有重叠活动。如果两个活动 至少有一天 相同，那么它们就是重叠的。
以任意顺序返回结果表。
结果格式如下所示。

示例 1:

输入:
`HallEvents` 表:
```
+---------+------------+------------+
| hall_id | start_day  | end_day    |
+---------+------------+------------+
| 1       | 2023-01-13 | 2023-01-14 |
| 1       | 2023-01-14 | 2023-01-17 |
| 1       | 2023-01-18 | 2023-01-25 |
| 2       | 2022-12-09 | 2022-12-23 |
| 2       | 2022-12-13 | 2022-12-17 |
| 3       | 2022-12-01 | 2023-01-30 |
+---------+------------+------------+
```
输出:
```
+---------+------------+------------+
| hall_id | start_day  | end_day    |
+---------+------------+------------+
| 1       | 2023-01-13 | 2023-01-17 |
| 1       | 2023-01-18 | 2023-01-25 |
| 2       | 2022-12-09 | 2022-12-23 |
| 3       | 2022-12-01 | 2023-01-30 |
+---------+------------+------------+
```
解释: 有三个大厅。
大厅 1:
- 两个活动 `["2023-01-13", "2023-01-14"]` 和 `["2023-01-14", "2023-01-17"]` 重叠。我们将它们合并到一个个活动中 `["2023-01-13", "2023-01-17"]`。
- 活动 `["2023-01-18", "2023-01-25"]` 不与任何其他活动重叠，所以我们保持原样。
大厅 2:
- 两个活动 `["2022-12-09", "2022-12-23"]` 和 `["2022-12-13", "2022-12-17"]` 重叠。我们将它们合并到一个个活动中 `["2022-12-09", "2022-12-23"]`。
大厅 3:
- 大厅只有...一个活动，所以我们返回它。请注意，我们只分别考虑每个大厅的活动。


这个问题的核心是合并重叠的日期区间，这是一个经典的 "gaps-and-islands" 问题。下面的查询通过三个步骤解决它：
1.  **`MarkedStarts`**: 识别出每个不间断活动序列的起始事件。如果一个事件的开始日期晚于它所在大厅之前所有事件的最晚结束日期，那么它就是一个新的活动序列的开始。
2.  **`GroupedEvents`**: 利用上一步的标记，为每个连续的活动序列分配一个唯一的组ID。
3.  **最终查询**: 按组ID进行分组，找出每个组的最早开始日期和最晚结束日期，从而得到合并后的活动区间。


*/

WITH
-- 1. 模拟 HallEvents 表
HallEvents AS (
    SELECT 1 AS hall_id, CAST('2023-01-13' AS DATE) AS start_day, CAST('2023-01-14' AS DATE) AS end_day UNION ALL
    SELECT 1, CAST('2023-01-14' AS DATE), CAST('2023-01-17' AS DATE) UNION ALL
    SELECT 1, CAST('2023-01-18' AS DATE), CAST('2023-01-25' AS DATE) UNION ALL
    SELECT 2, CAST('2022-12-09' AS DATE), CAST('2022-12-23' AS DATE) UNION ALL
    SELECT 2, CAST('2022-12-13' AS DATE), CAST('2022-12-17' AS DATE) UNION ALL
    SELECT 3, CAST('2022-12-01' AS DATE), CAST('2023-01-30' AS DATE)
),
overlap_events_group as (
    select
        hall_id,
        start_day,
        end_day,
        -- 使用累计求和的方式来标记新的重叠活动窗口开始
        sum(is_new_flag) over (partition by hall_id order by start_day, end_day) as group_id
    from (
             -- 判断是否日期重叠 datediff 和 lag 函数实现
             select hall_id,
                    start_day,
                    end_day,
                    lag(end_day,1,start_day) over (partition by hall_id order by start_day,end_day) as previous_end_day,
                    datediff(lag(end_day,1,start_day) over (partition by hall_id order by start_day,end_day),start_day) as diff,
                    `if`(datediff(lag(end_day,1,start_day) over (partition by hall_id order by start_day,end_day),start_day) >= 0, 0, 1) as is_new_flag
             from (
                      -- 去重数据
                      select hall_id,
                             start_day,
                             end_day
                      from HallEvents t1
                      group by hall_id, start_day, end_day
                  ) t1
         ) t2

)
-- 每个重叠活动窗口的开始和结束日期
select
    hall_id,
    min(start_day) as start_day,
    max(end_day) as end_day
from overlap_events_group t1
group by hall_id,group_id

~~~

## 26 候选人排名

~~~sql
/*
表: `Votes`
```
+-----------+---------+
| Column Name| Type    |
+-----------+---------+
| voter     | varchar |
| candidate | varchar |
+-----------+---------+
```
`(voter, candidate)` 是该表的主键 (具有唯一值的列)。
该表的每一行都包含选民及其候选人的姓名。

选举在一个城市进行，每个人都可以投票给 一个或多个 候选人, 也可以选择 不 投票。每个人都有 `1` 票，所以如果他们投票给多个候选人，他们的选票会被平均分配。例如，如果一个人投票给 `2` 个候选人，这些候选人每人获得 `0.5` 张选票。

编写一个解决方案来查找获得最多选票并赢得选举的候选人 `candidate` 。输出 候选人 的姓名，或者如果多个候选人的票数 相等，则输出所有候选人的姓名。
返回按 `candidate` 升序排序 的结果表。
查询结果格式如下所示。

示例 1:

输入:
`Votes table`:
```
+----------+------------+
| voter    | candidate  |
+----------+------------+
| Kathy    | null       |
| Charles  | Ryan       |
| Charles  | Christine  |
| Charles  | Kathy      |
| Benjamin | Christine  |
| Anthony  | Ryan       |
| Edward   | Ryan       |
| Terry    | null       |
| Evelyn   | Kathy      |
| Arthur   | Christine  |
+----------+------------+
```
输出:
```
+-----------+
| candidate |
+-----------+
| Christine |
| Ryan      |
+-----------+
```
解释:
- Kathy 和 Terry 选择不投票, 导致他们的投票被记录为 `0`。 Charles 将他的选票分配给了三位候选人, 相当于每位候选人得到 `0.33` 票。另一方面, Benjamin, Arthur, Anthony, Edward, 和 Evely 各自把票投给了一位候选人。
- Ryan 和 Christine 总共获得了`2.33`票, 而 Kathy 总共获得了 `1.33` 票。
由于 Ryan 和 Christine 获得的票数相等, 我们将按升序显示他们的名字。
*/

WITH
-- 1. 模拟 Votes 表
Votes AS (
    SELECT 'Kathy' AS voter, CAST(null AS STRING) AS candidate UNION ALL
    SELECT 'Charles', 'Ryan' UNION ALL
    SELECT 'Charles', 'Christine' UNION ALL
    SELECT 'Charles', 'Kathy' UNION ALL
    SELECT 'Benjamin', 'Christine' UNION ALL
    SELECT 'Anthony', 'Ryan' UNION ALL
    SELECT 'Edward', 'Ryan' UNION ALL
    SELECT 'Terry', CAST(null AS STRING) UNION ALL
    SELECT 'Evelyn', 'Kathy' UNION ALL
    SELECT 'Arthur', 'Christine'
)
select
    candidate
from (
         -- 排序
         select
             *,
             rank() over (order by total_vote_share desc) as rnk
         from (
                  -- 计算每个候选人的总投票份额
                  select
                      candidate,
                      sum(vote_share) as total_vote_share
                  from (
                           -- 计算每个候选人的投票份额
                           select voter,
                                  candidate,
                                  if(candidate is null , 0, 1) / count(*) over (partition by voter) as vote_share
                           from Votes t1
                       ) t2
                  group by  candidate

              ) t3
     ) t4
where rnk = 1;

~~~

## 27 航班是否满员

~~~sql

/*
表: `Flights`
```
+------------+---------+
| 列名       | 类型    |
+------------+---------+
| flight_id  | int     |
| capacity   | int     |
+------------+---------+
```
`flight_id` 列包含不同的值。
每行包含航班 id 和座位容量。

表: `Passengers`
```
+----------------+----------+
| 列名           | 类型     |
+----------------+----------+
| passenger_id   | int      |
| flight_id      | int      |
| booking_time   | datetime |
+----------------+----------+
```
`passenger_id` 包含不同的值。
`booking_time` 包含不同的值。
每行包含乘客 id、预订时间和所预订的航班 id。
乘客提前预订航班机票。如果乘客预订了一张航班机票，并且航班上还有空座位，则乘客的机票将 得到确认 。然而，如果航班已经满员，乘客将被列入 等候名单 。

编写解决方案来确定每个乘客航班机票的当前状态。
按 `passenger_id` 升序排序 返回结果表。
查询结果的格式如下所示。

示例 1:
输入:
`Flights` 表:
```
+-----------+----------+
| flight_id | capacity |
+-----------+----------+
| 1         | 2        |
| 2         | 2        |
| 3         | 1        |
+-----------+----------+
```
`Passengers` 表:
```
+--------------+-----------+---------------------+
| passenger_id | flight_id | booking_time        |
+--------------+-----------+---------------------+
| 101          | 1         | 2023-07-10 16:30:00 |
| 102          | 1         | 2023-07-10 17:45:00 |
| 103          | 1         | 2023-07-10 12:00:00 |
| 104          | 2         | 2023-07-05 13:23:00 |
| 105          | 2         | 2023-07-05 09:00:00 |
| 106          | 3         | 2023-07-08 11:10:00 |
| 107          | 3         | 2023-07-08 09:10:00 |
+--------------+-----------+---------------------+
```
输出:
```
+--------------+-----------+
| passenger_id | Status    |
+--------------+-----------+
| 101          | Confirmed |
| 102          | Waitlist  |
| 103          | Confirmed |
| 104          | Confirmed |
| 105          | Confirmed |
| 106          | Waitlist  |
| 107          | Confirmed |
+--------------+-----------+
```
解释:
- 航班 1 的容量为 2 位乘客。乘客 101 和乘客 103 是最先预订机票的，已经确认他们的预订。然而，乘客 102 是第三位预订该航班的乘客，这意味着没有更多的可用座位。乘客 102 现在被列入等候名单。
- 航班 2 的容量为 2 位乘客，已经有两位乘客预订了机票，乘客 104 和乘客 105。由于预订机票的乘客数与可用座位数相符，这两个预订都得到了确认。
- 航班 3 的容量为 1 位乘客，乘客 107 先预订并获得了唯一的可用座位，确认了他们的预订。预订时间在乘客 107 之后的乘客 106 被列入等候名单。

*/

WITH
-- 1. 模拟 Flights 表
Flights AS (
    SELECT 1 AS flight_id, 2 AS capacity UNION ALL
    SELECT 2, 2 UNION ALL
    SELECT 3, 1
),

-- 2. 模拟 Passengers 表
Passengers AS (
    SELECT 101 AS passenger_id, 1 AS flight_id, CAST('2023-07-10 16:30:00' AS TIMESTAMP) AS booking_time UNION ALL
    SELECT 102, 1, CAST('2023-07-10 17:45:00' AS TIMESTAMP) UNION ALL
    SELECT 103, 1, CAST('2023-07-10 12:00:00' AS TIMESTAMP) UNION ALL
    SELECT 104, 2, CAST('2023-07-05 13:23:00' AS TIMESTAMP) UNION ALL
    SELECT 105, 2, CAST('2023-07-05 09:00:00' AS TIMESTAMP) UNION ALL
    SELECT 106, 3, CAST('2023-07-08 11:10:00' AS TIMESTAMP) UNION ALL
    SELECT 107, 3, CAST('2023-07-08 09:10:00' AS TIMESTAMP)
)
Select
    t1.passenger_id,
    if(
            t2.capacity >=
            count(1) over(partition by t1.flight_id order by t1.booking_time),'Confirmed','Waitlist') status
from Passengers t1
         left join Flights t2
                   on t1.flight_id = t2.flight_id
~~~



## 28 指定区间内的订单数

~~~sql
/*
表: `Orders`
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| minute      | int  |
| order_count | int  |
+-------------+------+
```
`minute` 是该表的主键。
该表的每一行包含分钟数以及在特定分钟数内收到的订单数量。总行数将是 `6` 的倍数。编写一个查询，计算每个 区间 内的总订单数量。 每个区间被定义为 `6` 分钟的组合。

`1` 到 `6` 分钟属于第 `1` 个区间，而 `7` 到 `12` 分钟属于第 `2` 个区间，以此类推。
按 升序顺序 返回结果表，按 `interval_no` 排序。
结果表的格式如下示例所示。

示例 1:

输入:
`Orders table`:
```
+---------+-------------+
| minute  | order_count |
+---------+-------------+
| 1       | 0           |
| 2       | 2           |
| 3       | 4           |
| 4       | 6           |
| 5       | 1           |
| 6       | 4           |
| 7       | 1           |
| 8       | 2           |
| 9       | 4           |
| 10      | 1           |
| 11      | 4           |
| 12      | 6           |
+---------+-------------+
```
输出:
```
+--------------+--------------+
| interval_no  | total_orders |
+--------------+--------------+
| 1            | 17           |
| 2            | 18           |
+--------------+--------------+
```
解释:
- 区间号 `1` 包括从 `1` 到 `6` 分钟的时间。这 `6` 分钟内的总订单数量为 `(0 + 2 + 4 + 6 + 1 + 4) = 17`。
- 区间号 `2` 包括从 `7` 到 `12` 分钟的时间。这 `6` 分钟内的总订单数量为 `(1 + 2 + 4 + 1 + 4 + 6) = 18`。
按升序顺序返回结果表，按 `interval_no` 排序。
*/

WITH
-- 1. 模拟 Orders 表
Orders AS (
    SELECT 1 AS minute, 0 AS order_count UNION ALL
    SELECT 2, 2 UNION ALL
    SELECT 3, 4 UNION ALL
    SELECT 4, 6 UNION ALL
    SELECT 5, 1 UNION ALL
    SELECT 6, 4 UNION ALL
    SELECT 7, 1 UNION ALL
    SELECT 8, 2 UNION ALL
    SELECT 9, 4 UNION ALL
    SELECT 10, 1 UNION ALL
    SELECT 11, 4 UNION ALL
    SELECT 12, 6
)
select
    -- 计算区间号
    `floor`((minute - 1) / 6) + 1 as interval_no,
    sum(order_count) total_orders
from Orders t1
group by `floor`((minute - 1) / 6) + 1

~~~

## 29 单词出现频次（非wordcount)

~~~sql
/*
表: `Files`
```
+-------------+---------+
| 列名        | 类型    |
+-------------+---------+
| file_name   | varchar |
| content     | text    |
+-------------+---------+
```
`file_name` 为该表的主键 (具有唯一值的列) 。
每行包含 `file_name` 和该文件的内容。

编写解决方案，找出单词 `'bull'` 和 `'bear'` 作为 `独立词` 有出现的文件数量，不考虑任何它出现在两侧没有空格的情况 (例如, `'bullet'`, `'bears'`, `'bull.'`, 或者 `'bear'` 在句首或句尾 不会 被考虑) 。
返回单词 `'bull'` 和 `'bear'` 以及它们对应的出现文件数量，顺序没有限制 。
结果的格式如下所示:

示例 1:

输入:
`Files` 表:
```
+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| file_name   | content                                                                                                                                                                                                                                                                           |
+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| draft1.txt  | The stock exchange predicts a bull market which would make many investors happy.                                                                                                                                                                                                  |
| draft2.txt  | The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market.                                                                                             |
| draft3.txt  | The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market. As always predicting the future market is an uncertain game and all investors should follow their instincts and best practices. |
+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```
输出:
```
+------+-------+
| word | count |
+------+-------+
| bull | 3     |
| bear | 2     |
+------+-------+
```
解释:
- 单词 "bull" 在 "draft1.txt" 中出现1次, 在 "draft2.txt" 中出现 1 次, 在 "draft3.txt" 中出现 1 次。因此, 单词 "bull" 出现在 3 个文件中。
- 单词 "bear" 在 "draft2.txt" 中出现1次, 在 "draft3.txt" 中出现 1 次。因此, 单词 "bear" 出现在 2 个文件中。
*/
WITH
-- 1. 模拟 Files 表
    Files AS (
        SELECT 'draft1.txt' AS file_name, 'The stock exchange predicts a bull market which would make many investors happy.' AS content UNION ALL
        SELECT 'draft2.txt', 'The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market.' UNION ALL
        SELECT 'draft3.txt', 'The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market. As always predicting the future market is an uncertain game and all investors should follow their instincts and best practices.'
    ),words as (
    select file_name,
           content,
--                 content regexp ' bull| bull |bull ' exists_flag1,
--                 content regexp ' bear| bear |bear ' exists_flag2
           content like '% bull %' as exists_flag1,
           content like '% bear %' as exists_flag2

    from Files t1
)
select
    'bull' as word,
    count(distinct if(exists_flag1 = 1, file_name, null)) as count
from words

union all

select
    'bear' as word,
    count(distinct if(exists_flag2 = 1, file_name, null)) as count
from words

~~~



## 30 是否排班重叠1

~~~sql
/*
表: `EmployeeShifts`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| employee_id  | int     |
| start_time   | time    |
| end_time     | time    |
+--------------+---------+
```
(employee_id, start_time) 是此表的唯一主键。
这张表包含员工的排班工作，包括特定日期的开始和结束时间。
编写一个解决方案来为每个员工计算 重叠排班 的数量。如果一个排班的 end_time 比另一个排班的 start_time 更晚 则认为两个排班重叠。
返回结果表以 employee_id 升序 排序。
查询结果格式如下所示。

示例：
输入:
`EmployeeShifts` 表:
```
+-------------+------------+-----------+
| employee_id | start_time | end_time  |
+-------------+------------+-----------+
| 1           | 08:00:00   | 12:00:00  |
| 1           | 11:00:00   | 15:00:00  |
| 1           | 14:00:00   | 18:00:00  |
| 2           | 09:00:00   | 17:00:00  |
| 2           | 16:00:00   | 20:00:00  |
| 3           | 10:00:00   | 12:00:00  |
| 3           | 13:00:00   | 15:00:00  |
| 3           | 16:00:00   | 18:00:00  |
| 4           | 08:00:00   | 10:00:00  |
| 4           | 09:00:00   | 11:00:00  |
+-------------+------------+-----------+
```
输出:
```
+-------------+--------------------+
| employee_id | overlapping_shifts |
+-------------+--------------------+
| 1           | 2                  |
| 2           | 1                  |
| 4           | 1                  |
+-------------+--------------------+
```
解释:
员工 1 有 3 个排班: 08:00:00 到 12:00:00
11:00:00 到 15:00:00
14:00:00 到 18:00:00
第一个排班与第二个排班重叠，第二个排班与第三个排班重叠，因此有 2 个重叠排班。
员工 2 有 2 个排班: 09:00:00 到 17:00:00
16:00:00 到 20:00:00
这些排班彼此重叠，因此有 1 个重叠排班。
员工 3 有 3 个排班: 10:00:00 到 12:00:00
13:00:00 到 15:00:00
16:00:00 到 18:00:00
这些排班没有重叠，所以员工 3 不包含在输出中。
员工 4 有 2 个排班: 08:00:00 到 10:00:00
09:00:00 到 11:00:00
这些排班彼此重叠，因此有 1 个重叠排班。
输出展示了 employee_id 和至少有一个重叠排班的员工的重叠排班的数量，以 employee_id 升序排序。


*/

WITH
-- 1. 模拟 EmployeeShifts 表
EmployeeShifts AS (
    SELECT 1 AS employee_id, '08:00:00' AS start_time, '12:00:00' AS end_time UNION ALL
    SELECT 1, '11:00:00', '15:00:00' UNION ALL
    SELECT 1, '14:00:00', '18:00:00' UNION ALL
    SELECT 2, '09:00:00', '17:00:00' UNION ALL
    SELECT 2, '16:00:00', '20:00:00' UNION ALL
    SELECT 3, '10:00:00', '12:00:00' UNION ALL
    SELECT 3, '13:00:00', '15:00:00' UNION ALL
    SELECT 3, '16:00:00', '18:00:00' UNION ALL
    SELECT 4, '08:00:00', '10:00:00' UNION ALL
    SELECT 4, '09:00:00', '11:00:00'
)

select
    employee_id,
    count(*) as overlapping_shifts
from (
         select
             employee_id,
             start_time,
             lag(end_time,1) over(partition by employee_id order by start_time, end_time) previous_end_time
         from EmployeeShifts t1
     ) t2
where unix_timestamp(previous_end_time,'HH:mm:ss') - unix_timestamp(start_time,'HH:mm:ss') >= 0
group by employee_id

~~~



## 31 是否排班重叠2

~~~sql
/*
表: `EmployeeShifts`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| employee_id | int      |
| start_time  | datetime |
| end_time    | datetime |
+-------------+----------+
```
(employee_id, start_time) 是此表的唯一主键。
这张表包含员工的排班工作，包括特定日期的开始和结束时间。
编写一个解决方案来为每个员工分析重叠排班。如果两个排班在 同一天 且一个排班的 end_time 比另一个排班的 start_time 更晚 则认为两个排班重叠。
对于 每个员工, 计算如下内容:
任何 给定时间 的 最多重叠 班次数。
所有重叠班次的总持续时间, 以分钟为单位。
返回结果表以 employee_id 升序 排序。
查询结果格式如下所示。

示例：
输入:
`EmployeeShifts` 表:
```
+-------------+---------------------+---------------------+
| employee_id | start_time          | end_time            |
+-------------+---------------------+---------------------+
| 1           | 2023-10-01 09:00:00 | 2023-10-01 17:00:00 |
| 1           | 2023-10-01 15:00:00 | 2023-10-01 23:00:00 |
| 1           | 2023-10-01 16:00:00 | 2023-10-02 00:00:00 |
| 2           | 2023-10-01 09:00:00 | 2023-10-01 17:00:00 |
| 2           | 2023-10-01 11:00:00 | 2023-10-01 19:00:00 |
| 3           | 2023-10-01 09:00:00 | 2023-10-01 17:00:00 |
+-------------+---------------------+---------------------+
```
输出:
```
+-------------+----------------------+--------------------------+
| employee_id | max_overlapping_shifts | total_overlap_duration   |
+-------------+----------------------+--------------------------+
| 1           | 3                    | 600                      |
| 2           | 2                    | 360                      |
| 3           | 1                    | 0                        |
+-------------+----------------------+--------------------------+
```
解释:
-- “任何 给定时间 的 最多重叠 班次数 ”解释
让我们把员工1的三个班次画在时间轴上，看看并发数是如何变化的：
班次 1: 09:00 —————— 17:00
班次 2: 　　　 15:00 —————— 23:00
班次 3: 　　　　 16:00 —————————— (次日)00:00
现在我们沿着时间轴走一遍，数一数每个时间段有多少个班次在“进行中”：
09:00 - 15:00 之前: 只有 1 个班次（班次1）。
15:00 - 16:00 之前: 班次2开始了，现在有 2 个班次在同时进行（班次1 和 班次2）。
16:00 - 17:00 之前: 班次3也开始了，现在有 3 个班次在同时进行（班次1、班次2 和 班次3）。
17:00 - 23:00 之前: 班次1结束了，只剩下 2 个班次在同时进行（班次2 和 班次3）。
23:00 - 00:00 之前: 班次2结束了，只剩下 1 个班次（班次3）。
我们把整个过程中的并发数量列出来：1, 2, 3, 2, 1。
这个数列中的最大值是多少？是 3。\

-- “所有重叠班次的总持续时间” 解释
找出每一对相互重叠的班次，计算它们各自重叠了多长时间，然后把所有这些重叠时间加起来

员工 1 有 3 个排班: 2023-10-01 09:00:00 到 2023-10-01 17:00:00
2023-10-01 15:00:00 到 2023-10-01 23:00:00
2023-10-01 16:00:00 到 2023-10-02 00:00:00
最大重叠班次数量为 3 (from 16:00 to 17:00)。重叠班次的总持续时间为: 第 1 个和第 2 个排班之间的 2 小时 (15:00-17:00) + 第 1 个和第 3 个排班之间的 1 小时 (16:00-17:00) + 第 2 个和第 3 个排班之间的 7 小时 (16:00-23:00)，总共: 10 小时 = 600 分钟
员工 2 有 2 个排班: 2023-10-01 09:00:00 到 2023-10-01 17:00:00
2023-10-01 11:00:00 到 2023-10-01 19:00:00
最大重叠班次数量为 2。重叠班次的总持续时间为 6 小时 (11:00

*/

WITH
-- 1. 模拟 EmployeeShifts 表，使用 TIMESTAMP 类型代替 datetime
EmployeeShifts AS (
    SELECT 1 AS employee_id, CAST('2023-10-01 09:00:00' AS TIMESTAMP) AS start_time, CAST('2023-10-01 17:00:00' AS TIMESTAMP) AS end_time UNION ALL
    SELECT 1, CAST('2023-10-01 15:00:00' AS TIMESTAMP), CAST('2023-10-01 23:00:00' AS TIMESTAMP) UNION ALL
    SELECT 1, CAST('2023-10-01 16:00:00' AS TIMESTAMP), CAST('2023-10-02 00:00:00' AS TIMESTAMP) UNION ALL
    SELECT 2, CAST('2023-10-01 09:00:00' AS TIMESTAMP), CAST('2023-10-01 17:00:00' AS TIMESTAMP) UNION ALL
    SELECT 2, CAST('2023-10-01 11:00:00' AS TIMESTAMP), CAST('2023-10-01 19:00:00' AS TIMESTAMP) UNION ALL
    SELECT 3, CAST('2023-10-01 09:00:00' AS TIMESTAMP), CAST('2023-10-01 17:00:00' AS TIMESTAMP)
),

-- Part 1: 计算最大并发班次数
-- 2. 将每个班次拆分为开始(+1)和结束(-1)两个事件点
TimePoints AS (
    SELECT employee_id, start_time AS event_time, 1 AS event_type FROM EmployeeShifts
    UNION ALL
    SELECT employee_id, end_time AS event_time, -1 AS event_type FROM EmployeeShifts
),
-- 3. 使用窗口函数计算每个时间点的并发班次数
RunningCounts AS (
    SELECT
        employee_id,
        -- 按时间排序，计算事件的累积和，即为并发数
        -- 如果一个“开始”事件和一个“结束”事件发生在同一时刻，我们总是先处理“开始”事件，再处理“结束”事件，这样才能准确反应重叠班次的峰值
        SUM(event_type) OVER (PARTITION BY employee_id ORDER BY event_time, event_type DESC) AS concurrent_shifts
    FROM TimePoints
),
-- 4. 找到每个员工的最大并发数
MaxOverlapCalc AS (
    SELECT
        employee_id,
        COALESCE(MAX(concurrent_shifts), 0) AS max_overlapping_shifts
    FROM RunningCounts
    GROUP BY employee_id
),

-- Part 2: 计算总重叠时长
-- 5. 自连接，找到所有在同一天开始且有重叠的班次对，并计算其重叠时长
DurationOverlapCalc AS (
    SELECT
        e1.employee_id,
        -- 计算所有成对重叠的总分钟数
        SUM(
                (unix_timestamp(LEAST(e1.end_time, e2.end_time)) - unix_timestamp(e2.start_time)) / 60
        ) AS total_overlap_duration
    FROM
        EmployeeShifts e1
            JOIN
        EmployeeShifts e2 ON e1.employee_id = e2.employee_id
            -- 比较不同的班次
            AND e1.start_time < e2.start_time
            -- 必须在同一天开始
            AND to_date(e1.start_time) = to_date(e2.start_time)
    -- 重叠条件: 第一个班次的结束时间晚于第二个的开始时间
    WHERE e1.end_time > e2.start_time
    GROUP BY
        e1.employee_id
)

-- 6. 最终合并结果
SELECT
    m.employee_id,
    m.max_overlapping_shifts,
    CAST(COALESCE(d.total_overlap_duration, 0) AS BIGINT) AS total_overlap_duration
FROM
    MaxOverlapCalc m
        LEFT JOIN
    DurationOverlapCalc d ON m.employee_id = d.employee_id
ORDER BY
    m.employee_id;
~~~

## 32 2024年订单数

```sql
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

```

## 33 json解析

```sql
/*
种怎么解析出来upc、poiCoverIds、activityStatus、childActivityId这四个字段
*/
-- 方式1 ，如果json结构固定，使用from_json函数
WITH raw_data AS (
    SELECT '[{"upc":"4891214699106","groupNumber":2,"poiCoverIds":[27328289,27177717,27641161,27273825,27397427,27143163,27286728,27202288,27380897,27270871,27410428,27531096,27181919,27622791,27473153,27364924,27665032,27428734,27661498,27250113],"productName":"自然派 蜜汁猪肉条 65克/袋","subsidyType":"GOODS_RETURN","activityInfo":[{"activityStatus":"CREATE_DRAFT","childActivityId":63623316},{"activityStatus":"CREATE_DRAFT","childActivityId":63220296}],"subsidyDetail":"单品补贴额每单件1.2元"},{"upc":"6924509900767","groupNumber":3,"poiCoverIds":[27328289,27177717,27641161,27273825,27397427,27143163,27286728,27202288,27380897,27270871,27410428,27531096,27181919,27622791,27473153,27364924,27665032,27428734,27661498,27250113],"productName":"准盐 海藻碘食用盐 400g/袋","subsidyType":"GOODS_RETURN","activityInfo":[{"activityStatus":"CREATE_DRAFT","childActivityId":63625381},{"activityStatus":"CREATE_DRAFT","childActivityId":63220296}],"subsidyDetail":"单品补贴额每单件3元"}]'
               AS json_string
)
SELECT
    -- 从第一层展开的结构体中直接获取 upc
    t1_product.upc,
    -- 从第二层展开中获取 poiCoverIds (这是一个基本类型，不是结构体)
    t2_poi AS poiCoverIds,
    -- 从第三层展开的结构体中获取 activityStatus 和 childActivityId
    t3_activity.activityStatus,
    t3_activity.childActivityId
FROM
    raw_data

        -- 步骤1: 使用 from_json 和 schema 将整个字符串解析成一个 Hive 数组结构，并展开
        LATERAL VIEW explode(
            from_json(
                    json_string,
                    'ARRAY<STRUCT<upc:STRING, groupNumber:INT, poiCoverIds:ARRAY<BIGINT>, productName:STRING, subsidyType:STRING, activityInfo:ARRAY<STRUCT<activityStatus:STRING, childActivityId:BIGINT>>, subsidyDetail:STRING>>'
            )
                     ) t1 AS t1_product

        -- 步骤2: 展开每个产品结构体中的 poiCoverIds 数组
        LATERAL VIEW explode(t1_product.poiCoverIds) t2 AS t2_poi

        -- 步骤3: 展开每个产品结构体中的 activityInfo 数组
        LATERAL VIEW explode(t1_product.activityInfo) t3 AS t3_activity
;

-- 方式2，直接解析

select
    GET_JSON_OBJECT(a3,'$.upc') as upc,
    GET_JSON_OBJECT(a3,'$.poiCoverIds') as poiCoverIds,
    GET_JSON_OBJECT(a4,'$.activityStatus') as activityStatus,
    GET_JSON_OBJECT(a4,'$.childActivityId') as childActivityId
from (
         select
             a3,
             if(a4 is null, lead(a4,1) over(ORDER BY 1) ,a4) as a4
         from (
                  select
                      -- If the chunk contains "upc", it's the main object.
                      -- The split mangles the start/end brackets, so we replace '[{' with '{' and '}]' with '}' to make it a valid JSON object again.
                      if(a2 like '%upc%', replace(replace(a2, '[{', '{'), '}]', '}'), null) as a3,

                      -- If the chunk does NOT contain "upc", it's an activity object.
                      -- These chunks are missing the surrounding braces after the split, so we add them back with concat.
                      if(a2 not like '%upc%', concat('{', a2, '}'), null) as a4
                  from
                      (
                          select '[{"upc": "4891214699106", "groupNumber": 2, "poiCoverIds": [27328289, 27177717, 27641161, 27273825, 27397427, 27143163, 27286728, 27202288, 27380897, 27270871, 27410428, 27531096, 27181919, 27622791, 27473153, 27364924, 27665032, 27428734, 27661498, 27250113], "productName": "自然派 蜜汁猪肉条 65克/袋", "subsidyType": "GOODS_RETURN", "activityInfo": [{"activityStatus": "CREATE_DRAFT", "childActivityId": 63623316}, {"activityStatus": "CREATE_DRAFT", "childActivityId": 63220296}], "subsidyDetail": "单品补贴额每单件1.2元"}, {"upc": "6924509900767", "groupNumber": 3, "poiCoverIds": [27328289, 27177717, 27641161, 27273825, 27397427, 27143163, 27286728, 27202288, 27380897, 27270871, 27410428, 27531096, 27181919, 27622791, 27473153, 27364924, 27665032, 27428734, 27661498, 27250113], "productName": "淮盐 海藻碘食用盐 400g/袋", "subsidyType": "GOODS_RETURN", "activityInfo": [{"activityStatus": "CREATE_DRAFT", "childActivityId": 63625381}, {"activityStatus": "CREATE_DRAFT", "childActivityId": 63220296}], "subsidyDetail": "单品补贴额每单件3元"}]' as a
                      ) t1
                          lateral view explode(split(a,'},')) t2 as a2
              ) t3
     ) t4
where t4.a3 is not null;
```



## 34 保险索赔

~~~sql
/*
表: `Fraud`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| policy_id   | int     |
| state       | varchar |
| fraud_score | int     |
+-------------+---------+
```
policy_id 是这张表中具有不同值的列。
这张表包含 policy id, state 和 fraud score。
Leetcode 保险公司开发了一个 ML 驱动的 预测模型 来检测欺诈索赔的 可能性。因此，他们分配了经验最丰富的理赔员来处理前 `5%` 被标记 的索赔。

编写一个解决方案来找出 每个州 索赔的前 5 百分位数。
返回结果表，以 state 升序 排序, fraud_score 降序 排序, policy_id 升序 排序。
结果格式如下所示。

示例 1:

输入:
`Fraud` 表:
```
+-----------+-------------+-------------+
| policy_id | state       | fraud_score |
+-----------+-------------+-------------+
| 1         | California  | 0.92        |
| 2         | California  | 0.68        |
| 3         | California  | 0.17        |
| 4         | New York    | 0.94        |
| 5         | New York    | 0.81        |
| 6         | New York    | 0.77        |
| 7         | Texas       | 0.98        |
| 8         | Texas       | 0.97        |
| 9         | Texas       | 0.96        |
| 10        | Florida     | 0.97        |
| 11        | Florida     | 0.98        |
| 12        | Florida     | 0.78        |
| 13        | Florida     | 0.88        |
| 14        | Florida     | 0.66        |
+-----------+-------------+-------------+
```
输出:
```
+-----------+------------+-------------+
| policy_id | state      | fraud_score |
+-----------+------------+-------------+
| 1         | California | 0.92        |
| 11        | Florida    | 0.98        |
| 4         | New York   | 0.94        |
| 7         | Texas      | 0.98        |
+-----------+------------+-------------+```
解释:
- 对于 California 州, 只有 ID 为 1 的保单的欺诈分数为 0.92, 属于该州的前 5%.
- 对于 Florida 州, 只有 ID 为 11 的保单的欺诈分数为 0.98, 属于该州的前 5%.
- 对于 New York 州, 只有 ID 为 4 的保单的欺诈分数为 0.94, 属于该州的前 5%.
- 对于 Texas 州, 只有 ID 为 7 的保单的欺诈分数为 0.98, 属于该州的前 5%.
- 输出表以 state 升序排序, fraud_score 降序排序, policy_id 升序排序。


*/

WITH
-- 1. 模拟 Fraud 表
Fraud AS (
    SELECT 1 AS policy_id, 'California' AS state, 0.92 AS fraud_score UNION ALL
    SELECT 2, 'California', 0.68 UNION ALL
    SELECT 3, 'California', 0.17 UNION ALL
    SELECT 4, 'New York',   0.94 UNION ALL
    SELECT 5, 'New York',   0.81 UNION ALL
    SELECT 6, 'New York',   0.77 UNION ALL
    SELECT 7, 'Texas',      0.98 UNION ALL
    SELECT 8, 'Texas',      0.97 UNION ALL
    SELECT 9, 'Texas',      0.96 UNION ALL
    SELECT 10, 'Florida',    0.97 UNION ALL
    SELECT 11, 'Florida',    0.98 UNION ALL
    SELECT 12, 'Florida',    0.78 UNION ALL
    SELECT 13, 'Florida',    0.88 UNION ALL
    SELECT 14, 'Florida',    0.66
)
-- 方式1
/*
select
    policy_id,
    state,
    fraud_score
from (
         select policy_id,
                state,
                fraud_score,
                count(1) over(partition by state) as total_num,
                rank() over (partition by state order by fraud_score desc) order_num,
                0.05 * count(1) over(partition by state) limit_num
         from Fraud t1
     ) t2
-- 2. 计算每个州的总数, 排名和前 5% 的限制,如果limit_num为小数，则找到排名最靠前的那一个
where order_num <= `ceil`(limit_num) or order_num = 1
order by state asc, fraud_score desc, policy_id asc;

*/
-- 方式2
select policy_id,
       state,
       fraud_score
from (
         select policy_id,
                state,
                fraud_score,
                -- 计算每个州的 fraud_score 的累积分布
                cume_dist() over(partition by state order by fraud_score asc) as cume_dist
         from Fraud t1
     ) t2
where cume_dist >= 0.95
order by state asc, fraud_score desc, policy_id asc;
~~~

a. `CUME_DIST()` - 累积分布
*   **作用**：计算一个值在一组值中的累积分布。通俗讲，它回答的问题是：“**当前行的值小于或等于当前分区中所有值的百分之多少？**”
*   **返回值**：`Double` 类型，范围在 `(0, 1]` 之间。
*   **计算公式**：`分区内小于等于当前值的行数 / 分区内总行数`。
*   **使用场景**：非常适合用于筛选“前 N%”或“后 N%”的场景，就像您上一个问题中筛选“前 5 百分位数”（即累积分布 >= 0.95）的场景。

b. `PERCENT_RANK()` - 百分比排名
*   **作用**：与 `CUME_DIST()` 非常相似，但计算方式略有不同。它回答的问题是：“**当前行的排名百分比是多少？**”
*   **返回值**：`Double` 类型，范围在 `[0, 1]` 之间。
*   **计算公式**：`(分区内当前行的排名 - 1) / (分区内总行数 - 1)`。其中排名由 `RANK()` 函数确定。
*   **与 `CUME_DIST()` 的关键区别**：
    *   `PERCENT_RANK` 的最大值总是 1，最小值总是 0。
    *   `CUME_DIST` 的最小值永远大于 0。
    *   对于处理并列值，两者结果也不同。`PERCENT_RANK` 更关注“排名”的百分比位置。

c. `NTILE(n)` - 分桶/分位数
*   **作用**：将每个分区中的有序行分配到指定数量（`n`）的桶（group）中，并为每一行返回其所在的桶编号。
*   **返回值**：`Integer` 类型，范围在 `[1, n]` 之间。
*   **使用场景**：用于将数据进行等分。
    *   `NTILE(4)`：计算**四分位数** (Quartiles)。
    *   `NTILE(10)`：计算**十分位数** (Deciles)。
    *   `NTILE(100)`：计算**百分位数** (Percentiles)，返回每一行属于第几个百分位数组。
*   **注意**：如果分区内的行数不能被 `n` 整除，`NTILE` 会尽量让前面的桶比后面的桶多一个成员。

percentile_approx(col, percentage, [accuracy])
作用：计算指定列在给定百分比处的近似值。它回答的问题是：“在这个数据集中，排在第 N 百分位的数值是多少？”
参数：
col: 要计算的列。
percentage: 一个或一组百分比，可以是单个 Double 值（如 0.5）或一个数组（如 array(0.25, 0.5, 0.75)）。
accuracy (可选): 一个控制近似精度的整数，值越大越精确，但消耗的内存也越多。默认为 10000。
使用场景：用于概括性统计，例如计算薪水的中位数（50%百分位）、P95（95%百分位）等。
别名：PERCENTILE 和 APPX_PERCENTILE 都是 PERCENTILE_APPROX 的别名。

```sql
WITH employees AS (
    SELECT 'Sales' as dept, 'Alice' as name, 90000 as salary UNION ALL
    SELECT 'Sales', 'Bob', 85000 UNION ALL
    SELECT 'Sales', 'Charlie', 85000 UNION ALL
    SELECT 'Sales', 'David', 70000 UNION ALL
    SELECT 'HR', 'Eve', 60000 UNION ALL
    SELECT 'HR', 'Frank', 50000
)
SELECT
    dept,
    name,
    salary,
    -- 按薪水升序排序
    CUME_DIST() OVER (PARTITION BY dept ORDER BY salary) as cume_dist,
    PERCENT_RANK() OVER (PARTITION BY dept ORDER BY salary) as percent_rank,
    NTILE(4) OVER (PARTITION BY dept ORDER BY salary) as quartile
FROM
    employees
ORDER BY
    dept, salary DESC;

```

![image-20250804084121678](https://5201969.xyz/api/public/img/183f8522215025f6c89f41d561d0eb0c)

```sql
WITH employees AS (
    SELECT 'Sales' as dept, 'Alice' as name, 90000 as salary UNION ALL
    SELECT 'Sales', 'Bob', 85000 UNION ALL
    SELECT 'Sales', 'Charlie', 85000 UNION ALL
    SELECT 'Sales', 'David', 70000
)
SELECT
    dept,
    -- 计算第50个百分位数（中位数）
    percentile_approx(salary, 0.5) as median_salary,
    -- 同时计算多个百分位数
    percentile_approx(salary, array(0.25, 0.75, 0.95)) as percentiles
FROM
    employees
GROUP BY
    dept;
```

![image-20250804084211678](https://5201969.xyz/api/public/img/4daeeda1329d7a3ddb86cbbcfd103a34)



## 35 学生是否进步

~~~sql
/*
表: `Scores`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| student_id  | int     |
| subject     | varchar |
| score       | int     |
| exam_date   | varchar |
+-------------+---------+
```
(student_id, subject, exam_date) 是这张表的主键。
每一行包含有关学生在特定考试日期特定科目成绩的信息。分数范围从 0 到 100 (包括边界)。
编写一个解决方案来查找 进步的 学生。如果 同时 满足以下两个条件，则该学生被认为是进步的:
在 同一科目 至少参加过两个不同日期的考试。
他们在该学科 最近的分数 比他们 第一次 该学科考试的分数更高。
返回结果表以 student_id, subject 升序 排序。
结果格式如下所示。

示例:
输入:
`Scores` 表:
```
+------------+---------+-------+------------+
| student_id | subject | score | exam_date  |
+------------+---------+-------+------------+
| 101        | Math    | 70    | 2023-01-15 |
| 101        | Math    | 85    | 2023-02-15 |
| 101        | Physics | 65    | 2023-01-15 |
| 101        | Physics | 60    | 2023-02-15 |
| 102        | Math    | 80    | 2023-01-15 |
| 103        | Math    | 90    | 2023-01-15 |
| 104        | Physics | 75    | 2023-01-15 |
| 104        | Physics | 85    | 2023-02-15 |
+------------+---------+-------+------------+
```
输出:
```
+------------+---------+-------------+--------------+
| student_id | subject | first_score | latest_score |
+------------+---------+-------------+--------------+
| 101        | Math    | 70          | 85           |
| 104        | Physics | 75          | 85           |
+------------+---------+-------------+--------------+
```
解释:
学生 101 的数学: 从 70 分进步到 85 分。
学生 101 的物理: 没有进步 (从 65 分退步到 60分)
学生 103 的数学: 只有一次考试, 不符合资格。
学生 104 的物理: 从 75 分进步到 85 分。
结果表以 student_id, subject 升序排序。
*/

-- 方式1 ：错误解法，只考虑了最近一次考试成绩相比第一次考试成绩的情况，没有考虑到可能存在多次考试的情况。
WITH
-- 1. 模拟 Scores 表
Scores AS (
    SELECT 101 AS student_id, 'Math' AS subject, 70 AS score, CAST('2023-01-15' AS DATE) AS exam_date UNION ALL
    SELECT 101, 'Math',    85, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 65, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 60, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 102, 'Math',    80, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 103, 'Math',    90, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 75, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 85, CAST('2023-02-15' AS DATE)
)
select student_id,
       subject,
       first_score,
       latest_score
from (
         select
             student_id,
             subject,
             first_score,
             latest_score

         from (
                  select student_id,
                         subject,
                         score,
                         exam_date,
                         count(1) over(partition by student_id ,subject) per_num,
                         first_value(score) over(partition by student_id,subject order by exam_date) first_score,
                         first_value(score) over(partition by student_id,subject order by exam_date desc) latest_score
                  from Scores t1

              ) t2
         where per_num > 1 and latest_score > first_score
     ) t3
group by student_id,subject,first_score,latest_score
order by student_id,subject;

-- 方式2: 使用自连接
WITH
-- 1. 模拟 Scores 表
Scores AS (
    SELECT 101 AS student_id, 'Math' AS subject, 70 AS score, CAST('2023-01-15' AS DATE) AS exam_date UNION ALL
    SELECT 101, 'Math',    85, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 65, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 60, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 102, 'Math',    80, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 103, 'Math',    90, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 75, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 85, CAST('2023-02-15' AS DATE)
)
select
    t1.student_id,
    t1.subject,
    t1.score as first_score,
    t2.score as latest_score
from Scores t1
inner join Scores t2
on t1.student_id = t2.student_id
   and t1.subject = t2.subject
   and t1.exam_date < t2.exam_date
   and t1.score < t2.score
order by t1.student_id, t1.subject;


~~~



## 36 同比增长率

~~~sql

/*
表: `user_transactions`
```
+--------------------+----------+
| Column Name        | Type     |
+--------------------+----------+
| transaction_id     | integer  |
| product_id         | integer  |
| spend              | decimal  |
| transaction_date   | datetime |
+--------------------+----------+
```
`transaction_id` 唯一标识了表中的每一列。
这张表的每一行含有交易 ID，产品 ID, 总花费以及交易日期。

编写一个解决方案来计算 每个产品 总支出的 同比增长率。
结果表应该包含以下列:
*   `year`: 交易的年份。
*   `product_id`: 产品的 ID。
*   `curr_year_spend`: 当年的总支出。
*   `prev_year_spend`: 上一年的总支出。
*   `yoy_rate`: 同比增速百分比, 四舍五入至小数点后 2 位。

返回结果表以 `product_id`, `year` 升序 排序。
结果格式如下所示。

示例:
输入:
`user_transactions` 表:
```
+----------------+------------+---------+---------------------+
| transaction_id | product_id | spend   | transaction_date    |
+----------------+------------+---------+---------------------+
| 1341           | 123424     | 1500.60 | 2019-12-31 12:00:00 |
| 1423           | 123424     | 1000.20 | 2020-12-31 12:00:00 |
| 1623           | 123424     | 1246.44 | 2021-12-31 12:00:00 |
| 1322           | 123424     | 2145.32 | 2022-12-31 12:00:00 |
+----------------+------------+---------+---------------------+
```
输出:
```
+------+------------+-----------------+-----------------+----------+
| year | product_id | curr_year_spend | prev_year_spend | yoy_rate |
+------+------------+-----------------+-----------------+----------+
| 2019 | 123424     | 1500.60         | NULL            | NULL     |
| 2020 | 123424     | 1000.20         | 1500.60         | -33.35   |
| 2021 | 123424     | 1246.44         | 1000.20         | 24.62    |
| 2022 | 123424     | 2145.32         | 1246.44         | 72.12    |
+------+------------+-----------------+-----------------+----------+
```
解释:
对于产品 ID 123424:在 2019: 当年的支出是 1500.60
没有上一年支出的记录
同比增长率: NULL

在 2020: 当年的支出是 1000.20
上一年的支出是 1500.60
同比增长率: ((1000.20 - 1500.60) / 1500.60) * 100 = -33.35%

在 2021: 当年的支出是 1246.44
上一年的支出是 1000.20
同比增长率: ((1246.44 - 1000.20) / 1000.20) * 100 = 24.62%

在 2022: 当年的支出是 2145.32
上一年的支出是 1246.44
同比增长率: ((2145.32 - 1246.44) / 1246.44) * 100 = 72.12%

注意: 输出表以 `product_id` 和 `year` 升序排序。

*/

WITH
-- 1. 模拟 user_transactions 表
user_transactions AS (
    SELECT 1341 AS transaction_id, 123424 AS product_id, CAST(1500.60 AS DECIMAL(10,2)) AS spend, CAST('2019-12-31 12:00:00' AS TIMESTAMP) AS transaction_date UNION ALL
    SELECT 1423, 123424, CAST(1000.20 AS DECIMAL(10,2)), CAST('2020-12-31 12:00:00' AS TIMESTAMP) UNION ALL
    SELECT 1623, 123424, CAST(1246.44 AS DECIMAL(10,2)), CAST('2021-12-31 12:00:00' AS TIMESTAMP) UNION ALL
    SELECT 1322, 123424, CAST(2145.32 AS DECIMAL(10,2)), CAST('2022-12-31 12:00:00' AS TIMESTAMP)
)
select product_id,
       year,
       curr_year_spend,
       prev_year_spend,
       round(((curr_year_spend - prev_year_spend) / prev_year_spend) * 100, 2)  as yoy_rate
from (
         select
             product_id , year(transaction_date) year,
             sum(spend) as curr_year_spend,
             lag(sum(spend)) over (partition by product_id order by year(transaction_date)) as prev_year_spend
         from user_transactions t1
         group by product_id , year(transaction_date)
     ) t2
order by product_id, year;
~~~



## 37 奇偶数值之和（带条件的聚合运算）

~~~sql
/*
表: `transactions`
```
+------------------+------+
| Column Name      | Type |
+------------------+------+
| transaction_id   | int  |
| amount           | int  |
| transaction_date | date |
+------------------+------+
```
`transactions_id` 唯一标识了表中的每一行。
这张表的每一行包含交易 id, 金额总和和交易日期。

编写一个解决方案来查找每天 `奇数` 交易金额和 `偶数` 交易金额的 总和。如果某天没有奇数或偶数交易，显示为 `0`。
返回结果表以 `transaction_date` 升序 排序。
结果格式如下所示。

示例:
输入:
`transactions` 表:
```
+----------------+--------+------------------+
| transaction_id | amount | transaction_date |
+----------------+--------+------------------+
| 1              | 150    | 2024-07-01       |
| 2              | 200    | 2024-07-01       |
| 3              | 75     | 2024-07-01       |
| 4              | 300    | 2024-07-02       |
| 5              | 50     | 2024-07-02       |
| 6              | 120    | 2024-07-03       |
+----------------+--------+------------------+
```
输出:
```
+------------------+----------+-----------+
| transaction_date | odd_sum  | even_sum  |
+------------------+----------+-----------+
| 2024-07-01       | 75       | 350       |
| 2024-07-02       | 0        | 350       |
| 2024-07-03       | 0        | 120       |
+------------------+----------+-----------+
```
解释:
对于交易日期: 2024-07-01: 奇数交易金额总和: 75
偶数交易金额总和: 150 + 200 = 350
2024-07-02: 奇数交易金额总和: 0
偶数交易金额总和: 300 + 50 = 350
2024-07-03: 奇数交易金额总和: 0
偶数交易金额总和: 120
注意: 输出表以 `transaction_date` 升序排序。
*/

WITH
-- 1. 模拟 transactions 表
transactions AS (
    SELECT 1 AS transaction_id, 150 AS amount, CAST('2024-07-01' AS DATE) AS transaction_date UNION ALL
    SELECT 2, 200, CAST('2024-07-01' AS DATE) UNION ALL
    SELECT 3, 75,  CAST('2024-07-01' AS DATE) UNION ALL
    SELECT 4, 300, CAST('2024-07-02' AS DATE) UNION ALL
    SELECT 5, 50,  CAST('2024-07-02' AS DATE) UNION ALL
    SELECT 6, 120, CAST('2024-07-03' AS DATE)
)
select
    transaction_date,
    sum(if(amount % 2 = 1, amount, 0)) as odd_sum,
    sum(if(amount % 2 = 0, amount, 0)) as even_sum
from transactions  t1
group by transaction_date

~~~



## 38 带条件的判断

~~~sql
/*
表: `Teams`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| player_id   | int     |
| team_name   | varchar |
+-------------+---------+
```
`player_id` 是这张表的唯一主键。
每一行包含队员的唯一标识以及在该场比赛中参赛的某支队伍的名称。

表: `Passes`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| pass_from   | int     |
| time_stamp  | varchar |
| pass_to     | int     |
+-------------+---------+
```
`(pass_from, time_stamp)` 是这张表的主键。
`pass_from` 是指向 `Teams` 表 `player_id` 字段的外键。
每一行代表比赛期间的一次传球，`time_stamp` 表示传球发生的分钟时间 (`00:00-90:00`)，`pass_to` 表示 `player_id` 对应队员接球。

编写一个解决方案来计算每支球队 在上半场的优势得分。规则如下:
一场比赛分为两个半场: 上半场 (`00:00-45:00` 分钟) 和 下半场 (`45:01-90:00` 分钟)
优势得分是根据成功和截获的传球来计算的: 当 `pass_to` 是 同球队 的队员: `+1` 分
当 `pass_to` 是 对方球队 的队员 (截获) : `-1` 分
更高的优势得分表明传球表现更好
返回结果表以 `team_name` 和 `half_number` 升序 排序。
结果格式如下所示。

示例:
输入:
`Teams` 表:
```
+-----------+-----------+
| player_id | team_name |
+-----------+-----------+
| 1         | Arsenal   |
| 2         | Arsenal   |
| 3         | Arsenal   |
| 4         | Chelsea   |
| 5         | Chelsea   |
| 6         | Chelsea   |
+-----------+-----------+
```
`Passes` 表:
```
+-----------+------------+---------+
| pass_from | time_stamp | pass_to |
+-----------+------------+---------+
| 1         | 00:15      | 2       |
| 2         | 00:45      | 3       |
| 3         | 01:15      | 1       |
| 4         | 00:30      | 1       |
| 2         | 46:00      | 3       |
| 3         | 46:15      | 4       |
| 1         | 46:45      | 2       |
| 5         | 46:30      | 6       |
+-----------+------------+---------+
```
输出:
```
+-----------+-------------+-----------+
| team_name | half_number | dominance |
+-----------+-------------+-----------+
| Arsenal   | 1           | 3         |
| Arsenal   | 2           | 1         |
| Chelsea   | 1           | -1        |
| Chelsea   | 2           | 1         |
+-----------+-------------+-----------+
```
解释:
前半场 (00:00-45:00) : 阿森纳的传球: 1 -> 2 (00:15): 成功传球 (+1)
2 -> 3 (00:45): 成功传球 (+1)
3 -> 1 (01:15): 成功传球 (+1)
切尔西的传球: 4 -> 1 (00:30): 被阿森纳截获 (-1)
下半场 (45:01-90:00) : 阿森纳的传球: 2 -> 3 (46:00): 成功传球 (+1)
3 -> 4 (46:15): 被切尔西截获 (-1)
1 -> 2 (46:45): 成功传球 (+1)
切尔西的传球: 5 -> 6 (46:30): 成功传球 (+1)
结果以 `team_name` 和 `half_number` 升序排序
*/

/*
1. 如何判断上下场？
2. 需求分析，按照正常的业务场景，一次传球只会有一个获胜方；比如同队球员传球一次，该队可以计1分；A对球员传球被B对球员截断一次，B队可以计1分，A队不计分。
回到题目的需求，A对球员传球被B对球员截断一次，B队可以计1分，A队计-1分；A对球员传球被A队球员一次，A队计1分，B队计0分，可能出现球队得分为负数的情况。
*/
WITH
-- 1. 模拟 Teams 表
Teams AS (
    SELECT 1 AS player_id, 'Arsenal' AS team_name UNION ALL
    SELECT 2, 'Arsenal' UNION ALL
    SELECT 3, 'Arsenal' UNION ALL
    SELECT 4, 'Chelsea' UNION ALL
    SELECT 5, 'Chelsea' UNION ALL
    SELECT 6, 'Chelsea'
),

-- 2. 模拟 Passes 表
Passes AS (
    SELECT 1 AS pass_from, '00:15' AS time_stamp, 2 AS pass_to UNION ALL
    SELECT 2, '00:45', 3 UNION ALL
    SELECT 3, '01:15', 1 UNION ALL
    SELECT 4, '00:30', 1 UNION ALL
    SELECT 2, '46:00', 3 UNION ALL
    SELECT 3, '46:15', 4 UNION ALL
    SELECT 1, '46:45', 2 UNION ALL
    SELECT 5, '46:30', 6
),
/*
    -- 正常的业务场景处理，一次传球只会有一个获胜方
    team_states as (
        select
            t2.team_name as first_team ,
            t1.time_stamp,
            t3.team_name as second_team,
            if(t2.team_name = t3.team_name, t2.team_name, t3.team_name) as winner_team
        from Passes t1
                 left join Teams t2
                           on t1.pass_from  = t2.player_id
                 left join Teams t3
                           on t1.pass_to = t3.player_id

    )
select
    team_name,
    if(time_stamp <= '45:00', 1, 2) half_number,
    sum(score) as dominance
from (
         select
             team_name,
             time_stamp,
             score
         from (
                  select first_team as team_name,time_stamp,if(first_team != winner_team, 0,1) as  score from team_states t1
                  union all
                  select second_team,time_stamp,if(second_team != winner_team, 0,1) from team_states t2
              ) t3
         group by team_name,time_stamp,score
     ) t4
group by team_name,
         if(time_stamp <= '45:00', 1, 2)
order by team_name,half_number;*/

    -- 按照 题目需求处理，一次传球可能会有一个获胜方和一个失败方
team_states as (
    select
        t2.team_name as first_team ,
        t1.time_stamp,
        t3.team_name as second_team,
        if(t2.team_name = t3.team_name, t2.team_name, t3.team_name) as winner_team
    from Passes t1
             left join Teams t2
                       on t1.pass_from  = t2.player_id
             left join Teams t3
                       on t1.pass_to = t3.player_id
)
select
    team_name,
    if(time_stamp <= '45:00', 1, 2) half_number,
    sum(score) as dominance
from (
         select
             team_name,
             time_stamp,
             score
         from (
                  select first_team as team_name,time_stamp,if(first_team != winner_team, -1,1) as  score from team_states t1
                  union all
                  select second_team,time_stamp,if(second_team != winner_team, -1,1) from team_states t2
              ) t3
         group by team_name,time_stamp,score
     ) t4
group by team_name,
         if(time_stamp <= '45:00', 1, 2)
order by team_name,half_number;



~~~



## 39 近一次和第一次的比较

~~~sql
/*
表: `Scores`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| student_id  | int     |
| subject     | varchar |
| score       | int     |
| exam_date   | varchar |
+-------------+---------+
```
(student_id, subject, exam_date) 是这张表的主键。
每一行包含有关学生在特定考试日期特定科目成绩的信息。分数范围从 `0` 到 `100` (包括边界)。

编写一个解决方案来查找 `进步的`学生。如果 同时 满足以下两个条件，则该学生被认为是进步的:
*   在 同一科目 至少参加过两个不同日期的考试。
*   他们在该学科 最近的分数 比他们 第一次该学科考试的分数更高。

返回结果表以 `student_id`, `subject` 升序 排序。
结果格式如下所示。

示例:

输入:
`Scores` 表:
```
+------------+----------+-------+------------+
| student_id | subject  | score | exam_date  |
+------------+----------+-------+------------+
| 101        | Math     | 70    | 2023-01-15 |
| 101        | Math     | 85    | 2023-02-15 |
| 101        | Physics  | 65    | 2023-01-15 |
| 101        | Physics  | 60    | 2023-02-15 |
| 102        | Math     | 80    | 2023-01-15 |
| 102        | Math     | 85    | 2023-02-15 |
| 103        | Math     | 90    | 2023-01-15 |
| 104        | Physics  | 75    | 2023-01-15 |
| 104        | Physics  | 85    | 2023-02-15 |
+------------+----------+-------+------------+
```
输出:
```
+------------+----------+-------------+--------------+
| student_id | subject  | first_score | latest_score |
+------------+----------+-------------+--------------+
| 101        | Math     | 70          | 85           |
| 102        | Math     | 80          | 85           |
| 104        | Physics  | 75          | 85           |
+------------+----------+-------------+--------------+
```
解释:
学生 101 的数学: 从 70 分进步到 85 分。
学生 101 的物理: 没有进步 (从 65 分退步到 60分)
学生 102 的数学: 从 80 进步到 85 分。
学生 103 的数学: 只有一次考试，不符合资格。
学生 104 的物理: 从 75 分进步到 85 分。
结果表以 student_id, subject 升序排序。

*/


WITH
-- 1. 模拟 Scores 表
Scores AS (
  SELECT 101 AS student_id, 'Math' AS subject, 70 AS score, '2023-01-15' AS exam_date UNION ALL
  SELECT 101, 'Math',     85, '2023-02-15' UNION ALL
  SELECT 101, 'Physics',  65, '2023-01-15' UNION ALL
  SELECT 101, 'Physics',  60, '2023-02-15' UNION ALL
  SELECT 102, 'Math',     80, '2023-01-15' UNION ALL
  SELECT 102, 'Math',     85, '2023-02-15' UNION ALL
  SELECT 103, 'Math',     90, '2023-01-15' UNION ALL
  SELECT 104, 'Physics',  75, '2023-01-15' UNION ALL
  SELECT 104, 'Physics',  85, '2023-02-15'
)
-- 方式1
/*select
    t1.student_id,
    t1.subject,
    t1.score as first_score,
    t2.score as latest_score
from Scores t1
inner join Scores t2
    on t1.student_id = t2.student_id
    and t1.subject = t2.subject
    and t1.exam_date < t2.exam_date
    and t1.score < t2.score
where t1.exam_date = (select min(exam_date) from Scores where student_id = t1.student_id and subject = t1.subject)
  and t2.exam_date = (select max(exam_date) from Scores where student_id = t2.student_id and subject = t2.subject)*/

-- 方式2
select student_id,
       subject,
       first_score,
       last_score
from (
         select
             t1.student_id,
             t1.subject,
             count(distinct t1.exam_date) over(partition by t1.student_id, t1.subject) as exam_count,
             first_value(t1.score) over(partition by t1.student_id, t1.subject order by t1.exam_date) as first_score,
             first_value(t1.score) over(partition by t1.student_id, t1.subject order by t1.exam_date desc) as last_score
         from Scores t1

     )t2
where t2.exam_count >= 2
  and t2.first_score < t2.last_score
group by t2.student_id,t2.subject,first_score,last_score
order by t2.student_id, t2.subject;


~~~



## 40 ip校验

~~~sql

/*

表: `logs`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| log_id      | int     |
| ip          | varchar |
| status_code | int     |
+-------------+---------+
```
`log_id` 是这张表的唯一主键。
每一行包含服务器访问日志信息，包括 IP 地址和 HTTP 状态码。

编写一个解决方案来查找 `无效的` IP 地址。一个 IPv4 地址如果满足以下任何条件之一，则无效:
*   任何 8 位字节中包含大于 `255` 的数字
*   任何 8 位字节中含有 前导零 (如 `01.02.03.04`)
*   少于或多于 4 个 8 位字节

返回结果表分别以 `invalid_count`, `ip` 降序 排序。
结果格式如下所示。

示例:

输入:
`logs` 表:
```
+--------+---------------+-------------+
| log_id | ip            | status_code |
+--------+---------------+-------------+
| 1      | 192.168.1.1   | 200         |
| 2      | 256.1.2.3     | 404         |
| 3      | 192.168.001.1 | 200         |
| 4      | 192.168.1.1   | 200         |
| 5      | 192.168.1     | 500         |
| 6      | 256.1.2.3     | 404         |
| 7      | 192.168.001.1 | 200         |
+--------+---------------+-------------+
```
输出:
```
+---------------+----------------+
| ip            | invalid_count  |
+---------------+----------------+
| 256.1.2.3     | 2              |
| 192.168.001.1 | 2              |
| 192.168.1     | 1              |
+---------------+----------------+
```
解释:
`256.1.2.3` 是无效的, 因为 `256 > 255`
`192.168.001.1` 是无效的, 因为有前导零
`192.168.1` 是非法的, 因为只有 3 个 8 位字节
输出表分别以 `invalid_count`, `ip` 降序排序。


*/

WITH
-- 1. 模拟 Logs 表
Logs AS (
    SELECT 1 AS log_id, '192.168.1.1' AS ip, 200 AS status_code UNION ALL
    SELECT 2, '256.1.2.3', 404 UNION ALL
    SELECT 3, '192.168.001.1', 200 UNION ALL
    SELECT 4, '192.168.1.1', 200 UNION ALL
    SELECT 5, '192.168.1', 500 UNION ALL
    SELECT 6, '256.1.2.3', 404 UNION ALL
    SELECT 7, '192.168.001.1', 200
)
select
    ip,
    count(distinct log_id) invalid_count
from Logs t1
lateral view explode(split(t1.ip, '\\.')) t2 as bit_number
where
    -- 2. 检查每个 8 位字节是否大于 255
    cast(bit_number as int) > 255
    or
    -- 3. 检查是否有前导零
    bit_number like '0%'
    or
    -- 4. 检查是否有少于或多于 4 个 8 位字节
    size(split(t1.ip, '\\.')) != 4
group by t1.ip
order by invalid_count desc;

/*
hive中并未直接提供ip地址处理相关的系统内置函数
*/

~~~



## 41 模式匹配

~~~sql
/*
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| sample_id    | int     |
| dna_sequence | varchar |
| species      | varchar |
+--------------+---------+
```
`sample_id` 是这张表的唯一主键。
每一行包含一个 DNA 序列——以字符 (A, T, G, C) 组成的字符串表示以及它所采集自的物种。
生物学家正在研究 DNA 序列中的基本模式。编写一个解决方案以识别别具有以下模式的 `sample_id`:

*   以 `ATG` 开头的序列 (一个常见的 起始密码子)
*   以 `TAA`, `TAG` 或 `TGA` 结尾的序列 (终止密码子)
*   包含基序 `ATAT` 的序列 (一个简单重复模式)
*   有 至少 `3` 个连续 `G` 的序列 (如 `GGG` 或 `GGGG`)

返回结果表以 `sample_id` 升序 排序。
结果格式如下所示。

示例:

输入:
`Samples` 表:
```
+-----------+-------------------+-----------+
| sample_id | dna_sequence      | species   |
+-----------+-------------------+-----------+
| 1         | ATGCTAGCTAGCTAA   | Human     |
| 2         | GGGTCAATCATC      | Human     |
| 3         | ATATATCGTAGCTA    | Human     |
| 4         | ATGGGGTCAТСАТАА   | Mouse     |
| 5         | TCAGTCAGTCAG      | Mouse     |
| 6         | ATATCGCGCTAG      | Zebrafish |
| 7         | CGTATGCGTGTA      | Zebrafish |
+-----------+-------------------+-----------+
```
输出:
```
+-----------+-------------------+-----------+-----------+----------+----------+----------+
| sample_id | dna_sequence      | species   | has_start | has_stop | has_atat | has_ggg  |
+-----------+-------------------+-----------+-----------+----------+----------+----------+
| 1         | ATGCTAGCTAGCTAA   | Human     | 1         | 1        | 0        | 0        |
| 2         | GGGTCAATCATC      | Human     | 0         | 0        | 0        | 1        |
| 3         | ATATATCGTAGCTA    | Human     | 0         | 0        | 1        | 0        |
| 4         | ATGGGGTCAТСАТАА   | Mouse     | 1         | 1        | 0        | 1        |
| 5         | TCAGTCAGTCAG      | Mouse     | 0         | 0        | 0        | 0        |
| 6         | ATATCGCGCTAG      | Zebrafish | 0         | 1        | 1        | 0        |
| 7         | CGTATGCGTGTA      | Zebrafish | 0         | 0        | 0        | 0        |
+-----------+-------------------+-----------+-----------+----------+----------+----------+
```
解释:
*   样本 1 (ATGCTAGCTAGCTAA) : 以 ATG 开头 (has_start = 1)
    以 TAA 结尾 (has_stop = 1)
    不包含 ATAT (has_atat = 0)
    不包含至少 3 个连续 'G' (has_ggg = 0)
*   样本 2 (GGGTCAATCATC) : 不以 ATG 开头 (has_start = 0)
    不以 TAA, TAG 或 TGA 结尾 (has_stop = 0)
    不包含 ATAT (has_atat = 0)
    包含 GGG (has_ggg = 1)
*   样本 3 (ATATATCGTAGCTA) : 不以 ATG 开头 (has_start = 0)
    不以 TAA, TAG 或 TGA 结尾 (has_stop = 0)
    包含 ATAT (has_atat = 1)
    不包含至少 3 个连续 'G' (has_ggg = 0)
*   样本 4 (ATGGGGTCAТСАТАА) : 以 ATG 开头 (has_start = 1)
    以 TAA 结尾 (has_stop = 1)
    不包含 ATAT (has_atat = 0)
    包含 GGGG (has_ggg = 1)
*   样本 5 (TCAGTCAGTCAG) : 不匹配任何模式 (所有字段 = 0)
*   样本 6 (ATATCGCGCTAG) : 不以 ATG 开头 (has_start = 0)
    以 TAG 结尾 (has_stop = 1)
    包含 ATAT (has_atat = 1)
    不包含至少 3 个连续 'G' (has_ggg = 0)
*   样本 7 (CGTATGCGTGTA) : 不以 ATG 开头 (has_start = 0)
    不以 TAA, TAG 或 TGA 结尾 (has_stop = 0)
    不包含 ATAT (has_atat = 0)
    不包含至少 3 个连续 'G' (has_ggg = 0)

注意:
结果以 sample_id 升序排序
对于每个模式, 1 表示该模式存在, 0 表示不存在


*/


WITH
-- 1. 模拟 Samples 表
Samples AS (SELECT 1 AS sample_id, 'ATGCTAGCTAGCTAA' AS dna_sequence, 'Human' AS species
            UNION ALL
            SELECT 2, 'GGGTCAATCATC', 'Human'
            UNION ALL
            SELECT 3, 'ATATATCGTAGCTA', 'Human'
            UNION ALL
            SELECT 4, 'ATGGGGTCAТСАТАА', 'Mouse'
            UNION ALL
            SELECT 5, 'TCAGTCAGTCAG', 'Mouse'
            UNION ALL
            SELECT 6, 'ATATCGCGCTAG', 'Zebrafish'
            UNION ALL
            SELECT 7, 'CGTATGCGTGTA', 'Zebrafish')
-- 场景1
select sample_id,
       dna_sequence,
       species,
       case when dna_sequence regexp '^ATG' then 1 else 0 end           as has_start,
       case when dna_sequence regexp 'TAA$|TAG$|TGA$' then 1 else 0 end as has_stop,
       case when dna_sequence regexp 'ATAT' then 1 else 0 end           as has_atat,
       case when dna_sequence regexp 'G{3,}' then 1 else 0 end          as has_ggg
from Samples t1
order by sample_id;

/* 结果：
| sample_id | dna_sequence   | species   | has_start | has_stop | has_atat | has_ggg |
|:----------|:---------------|:----------|:----------|:---------|:---------|:--------|
| 1         | ATGCTAGCTAA    | Human     | 1         | 1        | 0        | 0       |
| 2         | GGGTCAATCATC   | Human     | 0         | 0        | 0        | 1       |
| 3         | ATATATCGTAGCTA | Human     | 0         | 0        | 1        | 0       |
| 4         | ATGGGTCATCATA  | Mouse     | 1         | 0        | 0        | 1       |
| 5         | TCAGTCAGTCAG   | Mouse     | 0         | 0        | 0        | 0       |
| 6         | ATATCGCGCTAG   | Zebrafish | 0         | 1        | 1        | 0       |
| 7         | CGTATGCGTGTA   | Zebrafish | 0         | 0        | 0        | 0       |
*/


-- 场景2 ， 查询每个dns序列符合特定序列的次数
WITH
-- 1. 模拟 Samples 表
Samples AS (
    SELECT 1 AS sample_id, 'ATGCTAGCTAGCTAA' AS dna_sequence, 'Human' AS species UNION ALL
    SELECT 2, 'GGGTCAATCATC',    'Human'     UNION ALL
    SELECT 3, 'ATATATCGTAGCTA',  'Human'     UNION ALL
    SELECT 4, 'ATGGGGTCAТСАТАА', 'Mouse'     UNION ALL
    SELECT 5, 'TCAGTCAGTCAG',    'Mouse'     UNION ALL
    SELECT 6, 'ATATCGCGCTAG',    'Zebrafish' UNION ALL
    -- 添加一个用于演示重叠计数的例子
    SELECT 8, 'GGGATATATGGG',    'Test'
),
    explode_sequence as (
        select t1.sample_id,
               t1.dna_sequence,
               t1.species,
               t2.pos
        -- 使用 posexplode 和 split 函数将 dna_sequence 分割成单个字符,取每个字符的位置
        from Samples t1
                 lateral view posexplode(split(space(length(t1.dna_sequence) - 1), ' ')) t2 AS pos, val
    )
select t1.sample_id,
       t1.dna_sequence,
       t1.species,
       -- 使用 substring 函数和条件聚合来计算每个模式的出现次数
        sum(case when substring(t1.dna_sequence,t2.pos,3) = 'ATG' and t2.pos = 0 then 1 else 0 end)           as start_ATG_count,
        sum(case when substring(t1.dna_sequence,t2.pos,3) in ('TAA', 'TAG', 'TGA') and t2.pos = length(t1.dna_sequence) - 2 then 1 else 0 end) as stop_count,
        sum(case when substring(t1.dna_sequence,t2.pos,4) = 'ATAT' then 1 else 0 end)           as atat_count,
        sum(case when substring(t1.dna_sequence,t2.pos,3) = 'GGG' then 1 else 0 end)          as ggg_count

from Samples t1
left join explode_sequence t2
on t1.sample_id  = t2.sample_id
group by  t1.sample_id,
          t1.dna_sequence,
          t1.species
order by t1.sample_id;

/*结果
| sample_id | dna_sequence   | species   | start_count | stop_count | atat_count | ggg_count |
|:----------|:---------------|:----------|:------------|:-----------|:-----------|:----------|
| 1         | ATGCTAGCTAA    | Human     | 1           | 1          | 1          | 0         |
| 2         | GGGTCAATCATC   | Human     | 0           | 0          | 0          | 2         |
| 3         | ATATATCGTAGCTA | Human     | 0           | 0          | 3          | 0         |
| 4         | ATGGGTCATCATA  | Mouse     | 1           | 0          | 0          | 2         |
| 5         | TCAGTCAGTCAG   | Mouse     | 0           | 0          | 0          | 0         |
| 6         | ATATGCGGCTAG   | Zebrafish | 0           | 1          | 2          | 0         |
| 8         | GGGATATATGGG   | Test      | 0           | 0          | 2          | 3         |
*/

~~~



## 42 员工按照职级排序

~~~sql

/*
表: `Employees`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| employee_id   | int     |
| employee_name | varchar |
| manager_id    | int     |
| salary        | int     |
| department    | varchar |
+---------------+---------+
```
`employee_id` 是这张表的唯一主键。
每一行包含关于一名员工的信息，包括他们的 ID, 姓名, 他们经理的 ID, 薪水和部门。
顶级经理 (CEO) 的 `manager_id` 是空的。

编写一个解决方案来分析组织层级并回答下列问题:
*   **层级:** 对于每名员工，确定他们在组织中的层级 (CEO 层级为 1, CEO 的直接下属员工层级为 2, 以此类推)。
*   **团队大小:** 对于每个是经理的员工，计算他们手下的 (直接或间接下属) 总员工数。
*   **薪资预算:** 对于每个经理，计算他们控制的总薪资预算 (所有手下员工的工资总和，包括间接下属，加上自己的工资)。

返回结果表以 `层级` 升序 排序, 然后以`预算` 降序 排序, 最后以 `employee_name` 升序 排序。
结果格式如下所示。

示例:
输入:
`Employees` 表:
```
+-------------+---------------+------------+--------+--------------+
| employee_id | employee_name | manager_id | salary | department   |
+-------------+---------------+------------+--------+--------------+
| 1           | Alice         | null       | 12000  | Executive    |
| 2           | Bob           | 1          | 10000  | Sales        |
| 3           | Charlie       | 1          | 10000  | Engineering  |
| 4           | David         | 2          | 7500   | Sales        |
| 5           | Eva           | 2          | 7500   | Sales        |
| 6           | Frank         | 3          | 9000   | Engineering  |
| 7           | Grace         | 3          | 8500   | Engineering  |
| 8           | Hank          | 4          | 6000   | Sales        |
| 9           | Ivy           | 6          | 7000   | Engineering  |
| 10          | Judy          | 6          | 7000   | Engineering  |
+-------------+---------------+------------+--------+--------------+
```
输出:
```
+-------------+---------------+-------+-----------+--------+
| employee_id | employee_name | level | team_size | budget |
+-------------+---------------+-------+-----------+--------+
| 1           | Alice         | 1     | 9         | 84500  |
| 3           | Charlie       | 2     | 4         | 41500  |
| 2           | Bob           | 2     | 3         | 31000  |
| 6           | Frank         | 3     | 2         | 23000  |
| 4           | David         | 3     | 1         | 13500  |
| 7           | Grace         | 3     | 0         | 8500   |
| 5           | Eva           | 3     | 0         | 7500   |
| 9           | Ivy           | 4     | 0         | 7000   |
| 10          | Judy          | 4     | 0         | 7000   |
| 8           | Hank          | 4     | 0         | 6000   |
+-------------+---------------+-------+-----------+--------+
```
解释:
组织结构: Alice (ID: 1) 是 CEO (层级 1) 没有经理。
Bob (ID: 2) 和 Charlie (ID: 3) 是 Alice 的直接下属 (层级 2)
David (ID: 4), Eva (ID: 5) 从属于 Bob, 而 Frank (ID: 6) 和 Grace (ID: 7) 从属于 Charlie (层级 3)
Hank (ID: 8) 从属于 David, 而 Ivy (ID: 9) 和 Judy (ID: 10) 从属于 Frank (层级 4)

层级计算: CEO (Alice) 层级为 1
每个后续的管理层级都会使层级数加 1

团队大小计算: Alice 手下有 9 个员工 (除她以外的整个公司)
Bob 手下有 3 个员工 (David, Eva 和 Hank)
Charlie 手下有 4 个员工 (Frank, Grace, Ivy 和 Judy)
Frank 手下有 2 个员工 (Ivy 和 Judy)
David 手下有 1 个员工 (Hank)
Eva, Grace, Hank, Ivy 和 Judy 没有直接下属 (team_size = 0)

预算计算: Alice 的预算: 她的工资 (12000) + 所有员工的工资 (72500) = 84500
Charlie 的预算: 他的工资 (10000) + Frank 的预算 (23000) + Grace 的工资 (8500) = 41500
Bob 的预算: 他的工资 (10000) + David 的预算 (13500) + Eva 的工资 (7500) = 31000
Frank 的预算: 他的工资 (9000) + Ivy 的工资 (7000) + Judy 的工资 (7000) = 23000
David 的预算: 他的工资 (7500) + Hank 的工资 (6000) = 13500
没有直接下属的员工的预算等于他们自己的工资。

注意:
结果先以层级升序排序
在同一层级内，员工按预算降序排序，然后按姓名升序排序
*/


/*
思路：
1. hive不支持递归查询，使用多层级的自连接来模拟递归，每家公司的层级是固定的。比如此处最高层级是4
2. 找出第一层，比如CEO层级， employeed_id, level, path(001,1,/001/)
2. 找出第二层，连接第一层的结果，得到 employeed_id, level, path(002,2,/001/002/)，以此类推
3. 将所有层级的结果合并成一个完整的层级信息表，比如

| employee_id | employee_name | Level | path         | salary |
|:------------|:--------------|:------|:-------------|:-------|
| 1           | Alice         | 1     | /1/          | 12000  |
| 2           | Bob           | 2     | /1/2/        | 10000  |
| 3           | Charlie       | 2     | /1/3/        | 10000  |
| 5           | Eva           | 3     | /1/2/5/      | 7500   |
| 4           | David         | 3     | /1/2/4/      | 7500   |
| 7           | Grace         | 3     | /1/3/7/      | 8500   |
| 6           | Frank         | 3     | /1/3/6/      | 9000   |
| 8           | Hank          | 4     | /1/2/4/8/    | 6000   |
| 10          | Judy          | 4     | /1/3/6/10/   | 7000   |
| 9           | Ivy           | 4     | /1/3/6/9/    | 7000   |

4. 补充薪水等信息，连接员工表和层级表， 比如 ceo的所有下属员工

| manager_id | manager_name | manager_level | manager_path | manager_salary | employee_id | employee_path |
|:-----------|:-------------|:--------------|:-------------|:---------------|:------------|:--------------|
| 1          | Alice        | 1             | /1/          | 12000          | 2           | /1/2/         |
| 1          | Alice        | 1             | /1/          | 12000          | 3           | /1/3/         |
| 1          | Alice        | 1             | /1/          | 12000          | 4           | /1/2/4/       |
| 1          | Alice        | 1             | /1/          | 12000          | 5           | /1/2/5/       |
| 1          | Alice        | 1             | /1/          | 12000          | 6           | /1/3/6/       |
| 1          | Alice        | 1             | /1/          | 12000          | 7           | /1/3/7/       |
| 1          | Alice        | 1             | /1/          | 12000          | 8           | /1/2/4/8/     |
| 1          | Alice        | 1             | /1/          | 12000          | 9           | /1/3/6/9/     |
| 1          | Alice        | 1             | /1/          | 12000          | 10          | /1/3/6/10/    |

5. 分组聚合 按照层级升序，预算降序，姓名升序排序输出结果

*/
WITH
-- 1. 模拟 Employees 表
Employees AS (
    SELECT 2 AS employee_id, 'Bob' AS employee_name, 1 AS manager_id, 10000 AS salary, 'Sales' AS department UNION ALL
    SELECT 1 AS employee_id, 'Alice' AS employee_name, null AS manager_id, 12000 AS salary, 'Executive' AS department UNION ALL
    SELECT 3, 'Charlie', 1, 10000, 'Engineering' UNION ALL
    SELECT 4, 'David', 2, 7500, 'Sales' UNION ALL
    SELECT 5, 'Eva', 2, 7500, 'Sales' UNION ALL
    SELECT 6, 'Frank', 3, 9000, 'Engineering' UNION ALL
    SELECT 7, 'Grace', 3, 8500, 'Engineering' UNION ALL
    SELECT 8, 'Hank', 4, 6000, 'Sales' UNION ALL
    SELECT 9, 'Ivy', 6, 7000, 'Engineering' UNION ALL
    SELECT 10, 'Judy', 6, 7000, 'Engineering'
),
    level1 as (
        select
            employee_id,
            employee_name,
            1 as level,
            concat('/', employee_id, '/') as path,
            salary
        from Employees
        where manager_id is null
    ),
    level2 as (
        select
            e.employee_id,
            e.employee_name,
            2 as level,
            concat(l1.path, e.employee_id, '/') as path,
            e.salary
        from Employees e
                 join level1 l1 on e.manager_id = l1.employee_id
    ),
    level3 as (
        select
            e.employee_id,
            e.employee_name,
            3 as level,
            concat(l2.path, e.employee_id, '/') as path,
            e.salary
        from Employees e
                 join level2 l2 on e.manager_id = l2.employee_id
    ),
    level4 as (
        select
            e.employee_id,
            e.employee_name,
            4 as level,
            concat(l3.path, e.employee_id, '/') as path,
            e.salary
        from Employees e
                 join level3 l3 on e.manager_id = l3.employee_id
    ),
    full_hierarchy as (
        select * from level1 union all
        select * from level2 union all
        select * from level3 union all
        select * from level4
    )

select
    t2.employee_id,
    t2.employee_name,
    t2.level,
    -- team_size: 计算下属数量 (直接+间接)
    count(t3.employee_id) as team_size,
    -- budget: 计算薪资预算 (所有手下员工的工资总和，包括间接下属，加上自己的工资)
    nvl(sum(t3.salary),0) + t2.salary as budget
from full_hierarchy t2
    -- 获取每个职员的直接下属
left join full_hierarchy t3 on t3.path like concat(t2.path, '%') and t2.employee_id != t3.employee_id
group by t2.employee_id,
         t2.employee_name,
         t2.salary,
         t2.level
order by t2.level asc,
         budget desc,
         t2.employee_name asc;


~~~



## 43 连续出现的数字

~~~sql
/*
表: `Logs`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| id          | int      |
| num         | varchar  |
+-------------+----------+
```
在 SQL 中, id 是该表的主键。
id 是一个自增列。

找出所有至少连续出现三次的数字。
返回的结果表中的数据可以按 任意顺序 排列。
结果格式如下面的例子所示:

示例 1:

输入:
`Logs` 表:
```
+----+-----+
| id | num |
+----+-----+
| 1  | 1   |
| 2  | 1   |
| 3  | 1   |
| 4  | 2   |
| 5  | 1   |
| 6  | 2   |
| 7  | 2   |
+----+-----+
```
输出:
`Result` 表:
```
+-----------------+
| ConsecutiveNums |
+-----------------+
| 1               |
+-----------------+
```
解释: 1 是唯一连续出现至少三次的数字。
*/
WITH
-- 1. 模拟 Logs 表
Logs AS (
    SELECT 1 AS id, '1' AS num UNION ALL
    SELECT 2, '1' UNION ALL
    SELECT 3, '1' UNION ALL
    SELECT 4, '2' UNION ALL
    SELECT 5, '1' UNION ALL
    SELECT 6, '2' UNION ALL
    SELECT 7, '2'
)
select
    distinct num
from (
         select
             id,
             num,
             row_number() over (partition by  num order by id  ) row_number
         from Logs t1
     ) t2
group by id - row_number, num
having count(1) >= 3

~~~



## 44 取消率

~~~sql
/*
表: `Trips`
```
+-------------+-------------------------------------------------+
| Column Name | Type                                            |
+-------------+-------------------------------------------------+
| id          | int                                             |
| client_id   | int                                             |
| driver_id   | int                                             |
| city_id     | int                                             |
| status      | enum                                            |
| request_at  | varchar                                         |
+-------------+-------------------------------------------------+
```
`id` 是这张表的主键 (具有唯一值的列) 。
这张表中存有所有出租车的行程信息。每段行程有唯一 `id` ，其中 `client_id` 和 `driver_id` 是 `Users` 表中 `users_id` 的外键。
`status` 是一个表示行程状态的枚举类型，枚举成员为(`'completed'`, `'cancelled_by_driver'`, `'cancelled_by_client'`) 。

表: `Users`
```
+-------------+----------------------------------+
| Column Name | Type                             |
+-------------+----------------------------------+
| users_id    | int                              |
| banned      | enum                             |
| role        | enum                             |
+-------------+----------------------------------+
```
`users_id` 是这张表的主键 (具有唯一值的列)。
这张表中存有所有用户，每个用户都有一个唯一的 `users_id` ，`role` 是一个表示用户身份的枚举类型，枚举成员为 (`'client'`, `'driver'`, `'partner'`)。
`banned` 是一个表示用户是否被禁止的枚举类型，枚举成员为 (`'Yes'`, `'No'`) 。

取消率的计算方式如下: (被司机或乘客取消的非禁止用户生成的订单数量) / (非禁止用户生成的订单总数)。
编写解决方案找出 "2013-10-01" 至 "2013-10-03" 期间有 至少一次行程的非禁止用户 (乘客和司机都必须未被禁止) 的取消率。非禁止用户即 `banned` 为 `No` 的用户，禁止用户即 `banned` 为 `Yes` 的用户。其中取消率 `Cancellation Rate` 需要四舍五入保留 两位小数。
返回结果表中的数据 无顺序要求。
结果格式如下例所示。

示例 1:

输入:
`Trips` 表:
```
+----+-----------+-----------+---------+------------------------+------------+
| id | client_id | driver_id | city_id | status                 | request_at |
+----+-----------+-----------+---------+------------------------+------------+
| 1  | 1         | 10        | 1       | completed              | 2013-10-01 |
| 2  | 2         | 11        | 1       | cancelled_by_driver    | 2013-10-01 |
| 3  | 3         | 12        | 6       | completed              | 2013-10-01 |
| 4  | 4         | 13        | 6       | cancelled_by_client    | 2013-10-01 |
| 5  | 1         | 10        | 1       | completed              | 2013-10-02 |
| 6  | 2         | 11        | 6       | completed              | 2013-10-02 |
| 7  | 3         | 12        | 6       | completed              | 2013-10-02 |
| 8  | 2         | 12        | 12      | completed              | 2013-10-03 |
| 9  | 3         | 10        | 12      | completed              | 2013-10-03 |
| 10 | 4         | 13        | 12      | cancelled_by_driver    | 2013-10-03 |
+----+-----------+-----------+---------+------------------------+------------+
```
`Users` 表:
```
+----------+--------+---------+
| users_id | banned | role    |
+----------+--------+---------+
| 1        | No     | client  |
| 2        | Yes    | client  |
| 3        | No     | client  |
| 4        | No     | client  |
| 10       | No     | driver  |
| 11       | No     | driver  |
| 12       | No     | driver  |
| 13       | No     | driver  |
+----------+--------+---------+
```
输出:
```
+------------+-------------------+
| Day        | Cancellation Rate |
+------------+-------------------+
| 2013-10-01 | 0.33              |
| 2013-10-02 | 0.00              |
| 2013-10-03 | 0.50              |
+------------+-------------------+
```
解释:
2013-10-01:
- 共有 4 条请求，其中 2 条取消。
- 然而，id=2 的请求是由禁止用户 (user_id=2) 发出的，所以计算时应当忽略它。
- 因此，总共有 3 条非禁止请求参与计算，其中 1 条取消。
- 取消率为 (1 / 3) = 0.33
2013-10-02:
- 共有 3 条请求，其中 0 条取消。
- 然而，id=6 的请求是由禁止用户发出的，所以计算时应当忽略它。
- 因此，总共有 2 条非禁止请求参与计算，其中 0 条取消。
- 取消率为 (0 / 2) = 0.00
2013-10-03:
- 共有 3 条请求，其中 1 条取消。
- 然而，id=8 的请求是由禁止用户发出的，所以计算时应当忽略它。
- 因此，总共有 2 条非禁止请求参与计算，其中 1 条取消。
- 取消率为 (1 / 2) = 0.50

*/
WITH
-- 1. 模拟 Trips 表
Trips AS (
    SELECT 1 AS id, 1 AS client_id, 10 AS driver_id, 1 AS city_id, 'completed' AS status, '2013-10-01' AS request_at UNION ALL
    SELECT 2, 2, 11, 1, 'cancelled_by_driver', '2013-10-01' UNION ALL
    SELECT 3, 3, 12, 6, 'completed', '2013-10-01' UNION ALL
    SELECT 4, 4, 13, 6, 'cancelled_by_client', '2013-10-01' UNION ALL
    SELECT 5, 1, 10, 1, 'completed', '2013-10-02' UNION ALL
    SELECT 6, 2, 11, 6, 'completed', '2013-10-02' UNION ALL
    SELECT 7, 3, 12, 6, 'completed', '2013-10-02' UNION ALL
    SELECT 8, 2, 12, 12, 'completed', '2013-10-03' UNION ALL
    SELECT 9, 3, 10, 12, 'completed', '2013-10-03' UNION ALL
    SELECT 10, 4, 13, 12, 'cancelled_by_driver', '2013-10-03'
),

-- 2. 模拟 Users 表
Users AS (
    SELECT 1 AS users_id, 'No' AS banned, 'client' AS role UNION ALL
    SELECT 2, 'Yes', 'client' UNION ALL
    SELECT 3, 'No', 'client' UNION ALL
    SELECT 4, 'No', 'client' UNION ALL
    SELECT 10, 'No', 'driver' UNION ALL
    SELECT 11, 'No', 'driver' UNION ALL
    SELECT 12, 'No', 'driver' UNION ALL
    SELECT 13, 'No', 'driver'
)
/*
思路：
1. 连接 Trips 和 Users 表，筛选出非禁止用户的行程记录
2. 日期筛选 和 至少一次行程
3. 取消率
*/
select
    t4.request_at,
    round(count(`if`(t4.status = 'cancelled_by_driver' or t4.status = 'cancelled_by_client', 1, null)) / count(1),2) as `Cancellation Rate`
from (
         select
             t1.id,
             t1.client_id,
             t1.driver_id,
             t1.request_at,
             t1.status
         from Trips t1
                  left join Users t2
                            on t1.client_id = t2.users_id
                  left join Users t3
                            on t1.driver_id = t3.users_id
         where t2.banned = 'No' and t3.banned = 'No'
           and t1.request_at between '2013-10-01' and '2013-10-03'
     )t4
group by t4.request_at
~~~



## 45 个玩家的日期和游戏数

~~~sql
/*

表: `Activity`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| player_id    | int     |
| device_id    | int     |
| event_date   | date    |
| games_played | int     |
+--------------+---------+
```
`(player_id, event_date)` 是此表的主键 (具有唯一值的列)。
这张表显示了某些游戏的玩家的活动情况。
每一行是一个玩家的记录，他在某一天使用某个设备注销之前登录并玩了很多游戏 (可能是 `0`)。
编写一个解决方案，同时报告每组玩家和日期，以及玩家到目前为止 玩了多少游戏。也就是说，玩家在该日期之前所玩的游戏总数。详细情况请查看示例。
以任意顺序 返回结果表。
结果格式如下所示。

示例 1:

输入:
`Activity table`:
活动表:
```
+-----------+-----------+------------+--------------+
| player_id | device_id | event_date | games_played |
+-----------+-----------+------------+--------------+
| 1         | 2         | 2016-03-01 | 5            |
| 1         | 2         | 2016-05-02 | 6            |
| 1         | 3         | 2017-06-25 | 1            |
| 3         | 1         | 2016-03-02 | 0            |
| 3         | 4         | 2018-07-03 | 5            |
+-----------+-----------+------------+--------------+
```
输出:
```
+-----------+------------+-----------------------+
| player_id | event_date | games_played_so_far   |
+-----------+------------+-----------------------+
| 1         | 2016-03-01 | 5                     |
| 1         | 2016-05-02 | 11                    |
| 1         | 2017-06-25 | 12                    |
| 3         | 2016-03-02 | 0                     |
| 3         | 2018-07-03 | 5                     |
+-----------+------------+-----------------------+```
解释:
对于 ID 为 1 的玩家, 2016-05-02 共玩了 5+6=11 个游戏, 2017-06-25 共玩了 5+6+1=12 个游戏。
对于 ID 为 3 的玩家, 2018-07-03 共玩了 0+5=5 个游戏。
请注意, 对于每个玩家, 我们只关心玩家的登录日期
*/
with
Activity AS (
    SELECT 1 AS player_id, 2 AS device_id, CAST('2016-03-01' AS DATE) AS event_date, 5 AS games_played UNION ALL
    SELECT 1, 2, CAST('2016-05-02' AS DATE), 6 UNION ALL
    SELECT 1, 3, CAST('2016-06-25' AS DATE), 1 UNION ALL
    SELECT 3, 1, CAST('2016-03-02' AS DATE), 0 UNION ALL
    SELECT 3, 4, CAST('2018-07-03' AS DATE), 5
)
/*
-- 方式1
select player_id,
       event_date,
       sum(games_played_per_date) over(partition by player_id order by event_date) as games_played_so_far
from (
         select
             player_id,
             event_date,
             sum(games_played) as games_played_per_date
         from Activity t1
         group by player_id, event_date

     ) t2
*/
-- 方式2 自链接实现 累计求和效果
select
    t2.player_id,
    t2.event_date,
    sum(t1.games_played) as games_played_so_far
from Activity t1
inner join Activity t2
on t1.player_id = t2.player_id and t1.event_date <= t2.event_date
group  by t2.player_id, t2.event_date
order by t2.player_id, t2.event_date;

~~~



## 46 次日登录人数

~~~sql
/*
Table: `Activity`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| player_id    | int     |
| device_id    | int     |
| event_date   | date    |
| games_played | int     |
+--------------+---------+
```
`(player_id, event_date)` 是此表的主键 (具有唯一值的列的组合)。
这张表显示了某些游戏的玩家的活动情况。
每一行是一个玩家的记录，他在某一天使用某个设备注销之前登录并玩了很多游戏 (可能是 `0`)。
编写解决方案，报告在首次登录的第二天再次登录的玩家的 比率，四舍五入到小数点后两位。换句话说，你需要计算从首次登录日期开始至少连续两天登录的玩家的数量，然后除以玩家总数。
结果格式如下所示:

示例 1:

输入:
`Activity table`:
```
+-----------+-----------+------------+--------------+
| player_id | device_id | event_date | games_played |
+-----------+-----------+------------+--------------+
| 1         | 2         | 2016-03-01 | 5            |
| 1         | 2         | 2016-03-02 | 6            |
| 2         | 3         | 2017-06-25 | 1            |
| 3         | 1         | 2016-03-02 | 0            |
| 3         | 4         | 2018-07-03 | 5            |
+-----------+-----------+------------+--------------+
```
输出:
```
+-----------+
| fraction  |
+-----------+
| 0.33      |
+-----------+
```
解释:
只有 ID 为 1 的玩家在第一天登录后才重新登录, 所以答案是 1/3 = 0.33


*/

WITH
-- 1. 模拟 Activity 表
Activity AS (
    SELECT 1 AS player_id, 2 AS device_id, CAST('2016-03-01' AS DATE) AS event_date, 5 AS games_played UNION ALL
    SELECT 1, 2, CAST('2016-03-02' AS DATE), 6 UNION ALL
    SELECT 2, 3, CAST('2017-06-25' AS DATE), 1 UNION ALL
    SELECT 3, 1, CAST('2016-03-02' AS DATE), 0 UNION ALL
    SELECT 3, 4, CAST('2018-07-03' AS DATE), 5
),
    user_daily_activity AS (
        select
            player_id,
            event_date
        from Activity t1
        group by player_id, event_date
    ),
    registered_activity as (
        select player_id,
               event_date
        from (
                 select player_id,
                        event_date,
                        row_number() over (partition by player_id order by event_date) as rn
                 from user_daily_activity
             ) t1
        where rn = 1
    )
/*
select
    round(count(distinct if(date_add(t1.event_date,1) = t2.event_date,t2.event_date,null)) / count(distinct t1.player_id),2) as fraction
from registered_activity t1
         -- 首次登录的玩家 与 每日登录表链接
         left join user_daily_activity t2
on t1.player_id = t2.player_id and t1.event_date < t2.event_date;*/

select
    round(count(distinct t2.player_id) / count(distinct t1.player_id),2) as fraction
from registered_activity t1
    -- 首次登录的玩家 与 每日登录表链接
left join user_daily_activity t2
on t1.player_id = t2.player_id and date_add(t1.event_date, 1) = t2.event_date


~~~



## 47 工资的中位数

~~~sql
/*
表: `Employee`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| id        | int     |
| company   | varchar |
| salary    | int     |
+-----------+---------+
```
id 是该表的主键列(具有唯一值的列)。
该表的每一行表示公司和一名员工的工资。
编写解决方案，找出每个公司的工资中位数。
以任意顺序 返回结果表。
查询结果格式如下所示。

示例 1:

输入:
`Employee` 表:
```
+----+---------+--------+
| id | company | salary |
+----+---------+--------+
| 1  | A       | 2341   |
| 2  | A       | 341    |
| 3  | A       | 15     |
| 4  | A       | 15314  |
| 5  | A       | 451    |
| 6  | A       | 513    |
| 7  | B       | 15     |
| 8  | B       | 13     |
| 9  | B       | 1154   |
| 10 | B       | 1345   |
| 11 | B       | 1221   |
| 12 | B       | 234    |
| 13 | C       | 2345   |
| 14 | C       | 2645   |
| 15 | C       | 2645   |
| 16 | C       | 2652   |
| 17 | C       | 65     |
+----+---------+--------+
```
输出:
```
+----+---------+--------+
| id | company | salary |
+----+---------+--------+
| 5  | A       | 451    |
| 6  | A       | 513    |
| 12 | B       | 234    |
| 9  | B       | 1154   |
| 14 | C       | 2645   |
+----+---------+--------+
```
进阶: 你能在不使用任何内置函数或窗口函数的情况下解决它吗?


*/



WITH
-- 1. 模拟 Employee 表
Employee AS (
    SELECT 1 AS id, 'A' AS company, 2341 AS salary UNION ALL
    SELECT 2, 'A', 341 UNION ALL
    SELECT 3, 'A', 15 UNION ALL
    SELECT 4, 'A', 15314 UNION ALL
    SELECT 5, 'A', 451 UNION ALL
    SELECT 6, 'A', 513 UNION ALL
    SELECT 7, 'B', 15 UNION ALL
    SELECT 8, 'B', 13 UNION ALL
    SELECT 9, 'B', 1154 UNION ALL
    SELECT 10, 'B', 1345 UNION ALL
    SELECT 11, 'B', 1221 UNION ALL
    SELECT 12, 'B', 234 UNION ALL
    SELECT 13, 'C', 2345 UNION ALL
    SELECT 14, 'C', 2645 UNION ALL
    SELECT 15, 'C', 2645 UNION ALL
    SELECT 16, 'C', 2652 UNION ALL
    SELECT 17, 'C', 65
)

-- 方式1
/*select
    company,percentile_approx(salary,0.5) as median_salary
from Employee
group by company*/

-- 方式2
/*
select
    id,
    company,
    salary
from (
         select id,
                company,
                salary,
                row_number() over (partition by company order by salary) rn,
                count(1) over (partition by company) cnt
         from Employee

     ) t1
where (cnt % 2 = 1 and rn = (cnt + 1) / 2) or (cnt % 2 = 0 and rn in (cnt / 2, cnt / 2 + 1));


*/

-- 方式3
    -- 自连接的方式计算排名
/*row_number as (
    select t1.id,
        t1.company,
        t1.salary,
        count(1) as less_equal_count
    from Employee t1
    inner join  Employee t2
    on t1.company = t2.company and ( (t1.salary > t2.salary ) or (t1.salary = t2.salary and t1.id > t2.id))
    group by t1.id, t1.company,t1.salary
    ),
    -- 计算每个公司的总人数
 total_number as(
     select
         company,
         count(1) as total_count
     from Employee
     group by  company
 )
-- 最终查询
select
    t1.id,
    t1.company,
    t1.salary
from row_number t1
inner join total_number t2
    -- 核心筛选逻辑：
    -- 这个条件可以同时处理奇数和偶数的情况
    -- 奇数 (如 5): 中位数是第 3 位。r.rn >= 2.5 AND r.rn <= 3.5 --> 只有 rn=3 满足
    -- 偶数 (如 6): 中位数是第 3, 4 位。r.rn >= 3 AND r.rn <= 4 --> rn=3,4 都满足
on t1.company = t2.company and (total_count / 2.0 >= t1.less_equal_count and total_count / 2.0 <= t1.less_equal_count + 1);*/

-- 方式4
/*
这个算法的根本逻辑是：如果一个值的“中位数”，那么比它小的值的数量和比它大的值的数量应该是大致相等的。
    对于一个奇数个数的集合（如 1, 2, 3, 4, 5），中位数是 3。比 3 小的有2个值，比 3 大的也有2个值。它们的数量差是 2 - 2 = 0。
    对于一个偶数个数的集合（如 1, 2, 3, 4, 5, 6），中位数是 3 和 4。
    对于 3：比它小的值有2个，比它大的值有3个。数量差是 2 - 3 = -1。
    对于 4：比它小的值有3个，比它大的值有2个。数量差是 3 - 2 = 1。
因此，我们可以得出一个结论：一个值是中位数，当且仅当“比它小的值的数量”减去“比它大的值的数量”的结果在 -1, 0, 1 这个范围内
*/
select
    t1.id,
    t1.company,
    t1.salary
--     count(distinct t2.id) as less_count,
--     count(distinct t3.id) as greater_count,
--     count(distinct t2.id) - count(distinct t3.id) as diff_count
from Employee t1
    -- 计算比当前员工薪资高和低的员工数量，可以通过on的条件来实现如何定义比员工薪资高和低，假如存在相同薪资的员工，可以加入员工id来区分。灵活处理
left join Employee t2 on t1.company = t2.company and t1.salary > t2.salary
    -- 计算比当前员工薪资高的员工数量
left join Employee t3 on t1.company = t3.company and t1.salary < t3.salary
group by t1.id, t1.company, t1.salary
-- 只保留那些比当前员工薪资高和低的员工数量差在 -1, 0, 1 范围内的记录
having count(distinct t2.id) - count(distinct t3.id) between  -1 and 1;
~~~



##  48 五个下属的经理

````sql
/*
表: `Employee`
```
+------------+---------+
| Column Name| Type    |
+------------+---------+
| id         | int     |
| name       | varchar |
| department | varchar |
| managerId  | int     |
+------------+---------+
```
id 是此表的主键 (具有唯一值的列)。
该表的每一行表示雇员的名字、他们的部门和他们的经理的id。
如果managerId为空，则该员工没有经理。
没有员工会成为自己的管理者。
编写一个解决方案，找出至少有五个直接下属的经理。
以 任意顺序 返回结果表。
查询结果格式如下所示。

示例 1:

输入:
`Employee` 表:
```
+-----+-------+------------+-----------+
| id  | name  | department | managerId |
+-----+-------+------------+-----------+
| 101 | John  | A          | Null      |
| 102 | Dan   | A          | 101       |
| 103 | James | A          | 101       |
| 104 | Amy   | A          | 101       |
| 105 | Anne  | A          | 101       |
| 106 | Ron   | B          | 101       |
+-----+-------+------------+-----------+
```
输出:
```
+------+
| name |
+------+
| John |
+------+
```

*/
WITH
-- 1. 模拟 Employee 表
Employee AS (
    SELECT 101 AS id, 'John' AS name, 'A' AS department, CAST(NULL AS INT) AS managerId UNION ALL
    SELECT 102, 'Dan',   'A', 101 UNION ALL
    SELECT 103, 'James', 'A', 101 UNION ALL
    SELECT 104, 'Amy',   'A', 101 UNION ALL
    SELECT 105, 'Anne',  'A', 101 UNION ALL
    SELECT 106, 'Ron',   'B', 101
)
select
    t1.name
from Employee t1
left join Employee t2
on t1.id = t2.managerId
group by t1.id,t1.name
having count(1) >= 5
````



## 49 所有数组的中位数

~~~sql
/*
`Numbers` 表:
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| num         | int     |
| frequency   | int     |
+-------------+---------+
```
`num` 是这张表的主键(具有唯一值的列)。
这张表的每一行表示某个数字在该数据库中的出现频率。

中位数 是将数据样本中半数较高值和半数较低值分隔开的值。编写解决方案，解压 `Numbers` 表，报告数据库中所有数字的 中位数 。结果四舍五入至 一位小数 。
返回结果如下例所示。

示例 1:
输入:
`Numbers` 表:
```
+-----+-----------+
| num | frequency |
+-----+-----------+
| 0   | 7         |
| 1   | 1         |
| 2   | 3         |
| 3   | 1         |
+-----+-----------+
```
输出:
```
+--------+
| median |
+--------+
| 0.0    |
+--------+
```
解释:
如果解压这个 `Numbers` 表,可以得到 `[0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 3]` , 所以中位数是 `(0 + 0) / 2 = 0`。

*/
WITH
-- 1. 模拟 Numbers 表
Numbers AS (
    SELECT 0 AS num, 7 AS frequency UNION ALL
    SELECT 1, 1 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 3, 1
)
/*
select
    t2.num
from (
         select
             t1.num,
             row_number() over (order by t1.num) rn,
             count(1) over(partition by t1.num) partitial_number
         from Numbers t1
                  lateral view posexplode(split(repeat(space(1), t1.frequency - 1), ' ')) t2 as pos, value
     ) t2
where rn >= partitial_number / 2.0 and rn <= (partitial_number + 1) / 2.0
group by t2.num
*/
select
    avg(num)
from (
         select
             t1.num,
             t1.frequency,
             sum(frequency) over () total_num,
             sum(frequency) over(order by num) rn1,
             sum(frequency) over(order by num desc) rn2

         from Numbers  t1
     ) t2
where rn1 >= total_num / 2 and rn2 >= total_num / 2
~~~



## 50 选举人的票最多的人

~~~sql
/*
表: `Candidate`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| name        | varchar |
+-------------+---------+
```
`id` 是该表中具有唯一值的列
该表的每一行都包含关于候选对象的id和名称的信息。

表: `Vote`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| candidateId | int     |
+-------------+---------+
```
`id` 是自动递增的主键(具有唯一值的列)。
`candidateId`是id来自Candidate表的外键(reference 列)。
该表的每一行决定了在选举中获得第i张选票的候选人。

编写解决方案来报告获胜候选人的名字(即获得最多选票的候选人)。
生成的测试用例保证 只有一个候选人赢得 选举。
返回结果格式如下所示。

示例 1:

输入:
`Candidate table`:
```
+----+------+
| id | name |
+----+------+
| 1  | A    |
| 2  | B    |
| 3  | C    |
| 4  | D    |
| 5  | E    |
+----+------+
```
`Vote table`:
```
+----+-------------+
| id | candidateId |
+----+-------------+
| 1  | 2           |
| 2  | 4           |
| 3  | 3           |
| 4  | 2           |
| 5  | 5           |
+----+-------------+
```
输出:
```
+------+
| name |
+------+
| B    |
+------+
```
解释:
候选人B有2票，候选人C、D、E各有1票。
获胜者是候选人B。
*/
WITH
-- 1. 模拟 Candidate 表
Candidate AS (
    SELECT 1 AS id, 'A' AS name UNION ALL
    SELECT 2, 'B' UNION ALL
    SELECT 3, 'C' UNION ALL
    SELECT 4, 'D' UNION ALL
    SELECT 5, 'E'
),

-- 2. 模拟 Vote 表
Vote AS (
    SELECT 1 AS id, 2 AS candidateId UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 3, 3 UNION ALL
    SELECT 4, 2 UNION ALL
    SELECT 5, 5
)
select
    t1.name
from Candidate t1
left join Vote t2
on t1.id = t2.candidateId
group by t1.id,t1.name
order by count(t2.id) desc
limit 1
~~~



## 51 问题回答率

~~~sql
/*

`SurveyLog` 表:
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| id          | int  |
|             |      |
| id          | int  |
|             |      |
| action      | ENUM |
| question_id | int  |
| answer_id   | int  |
| q_num       | int  |
| timestamp   | int  |
+-------------+------+
```
这张表可能包含重复项。
`action` 是一个 ENUM(category) 数据，可以是 "show"、"answer" 或者 "skip"。
这张表的每一行表示: ID = `id` 的用户对 `question_id` 的问题在 `timestamp` 时间进行了 `action` 操作。
如果用户对应的操作是 "answer", `answer_id` 将会是对应答案的 id, 否则, 值为 `null`。
`q_num` 是该问题在当前会话中的数字顺序。

回答率 是指：同一问题编号中回答次数占显示次数的比率。

编写一个解决方案以报告 回答率 最高的问题。如果有很多个问题具有相同的最大 回答率，返回 `question_id` 最小的那个。
查询结果如下例所示。

示例 1:
输入:
`SurveyLog table`:
```
+----+--------+-------------+-----------+-------+-----------+
| id | action | question_id | answer_id | q_num | timestamp |
+----+--------+-------------+-----------+-------+-----------+
| 5  | show   | 285         | null      | 1     | 123       |
| 5  | answer | 285         | 124124    | 1     | 124       |
| 5  | show   | 369         | null      | 2     | 125       |
| 5  | skip   | 369         | null      | 2     | 126       |
+----+--------+-------------+-----------+-------+-----------+
```
输出:
```
+-------------+
| survey_log  |
+-------------+
| 285         |
+-------------+
```
解释:
问题 285 显示 1 次、回答 1 次。回答率为 1.0。
问题 369 显示 1 次、回答 0 次。回答率为 0.0。
问题 285 回答率最高。

*/

WITH
-- 1. 模拟 SurveyLog 表数据
SurveyLog AS (
    SELECT 5 AS id, 'show' AS action, 285 AS question_id, CAST(NULL AS INT) AS answer_id, 1 AS q_num, 123 AS timestamp UNION ALL
    SELECT 5, 'answer', 285, 124124,    1, 124 UNION ALL
    SELECT 5, 'show',   369, CAST(NULL AS INT), 2, 125 UNION ALL
    SELECT 5, 'skip',   369, CAST(NULL AS INT), 2, 126
)
select
    question_id,
    nvl(count(if(action = 'answer', 1,null)) / count(if(action = 'show', 1,null)),0) rate
from SurveyLog t1
group by question_id
order by rate desc ,question_id desc
limit 1;


~~~



## 52 3个月总工资和

~~~sql
/*
表: `Employee`
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| id          | int  |
| month       | int  |
| salary      | int  |
+-------------+------+
```
(id, month) 是该表的主键(具有唯一值的列的组合)。
表中的每一行表示 2020 年期间员工一个月的工资。
编写一个解决方案，在一个统一的表中计算出每个员工的 累计工资汇总。
员工的 累计工资汇总 可以计算如下:

对于该员工工作的每个月，将 该月 和 前两个月 的工资 加 起来。这是他们当月的 3 个月总工资和。如果员工在前几个月没有为公司工作，那么他们在前几个月的有效工资为 `0`。
不要 在摘要中包括员工 最近一个月的 3 个月总工资和。
不要 包括雇员 没有工作 的任何一个月的 3 个月总工资和。
返回按 `id` 升序排序 的结果表。如果 `id` 相等，请按 `month` 降序排序。
结果格式如下所示。

示例 1:
输入:
`Employee table`:
```
+----+-------+--------+
| id | month | salary |
+----+-------+--------+
| 1  | 1     | 20     |
| 2  | 1     | 20     |
| 1  | 2     | 30     |
| 2  | 2     | 30     |
| 3  | 2     | 40     |
| 1  | 3     | 40     |
| 3  | 3     | 60     |
| 1  | 4     | 60     |
| 3  | 4     | 70     |
| 1  | 7     | 90     |
| 1  | 8     | 90     |
+----+-------+--------+
```
输出:
```
+----+-------+--------+
| id | month | Salary |
+----+-------+--------+
| 1  | 7     | 90     |
| 1  | 4     | 130    |
| 1  | 3     | 90     |
| 1  | 2     | 50     |
| 1  | 1     | 20     |
| 2  | 1     | 20     |
| 3  | 3     | 100    |
| 3  | 2     | 40     |
+----+-------+--------+
```
解释:
员工 “1” 有 5 条工资记录，不包括最近一个月的“8”:
- 第 ‘7’ 个月为 90。
- 第 ‘4’ 个月为 60。
- 第 ‘3’ 个月是 40。
- 第 ‘2’ 个月为 30。
- 第 ‘1’ 个月为 20。
因此, 该员工的累计工资汇总为:
```
+----+-------+--------+
| id | month | salary |
+----+-------+--------+
| 1  | 7     | 90     | (90 + 0 + 0)
| 1  | 4     | 130    | (60 + 40 + 30)
| 1  | 3     | 90     | (40 + 30 + 20)
| 1  | 2     | 50     | (30 + 20 + 0)
| 1  | 1     | 20     | (20 + 0 + 0)
+----+-------+--------+
```
请注意，‘7’ 月的 3 个月的总和是 90, 因为他们没有在 ‘6’ 月或 ‘5’ 月工作。

员工 ‘2’ 只有一个工资记录(‘1’ 月)，不包括最近的 ‘2’ 月。
```
+----+-------+--------+
| id | month | salary |
+----+-------+--------+
| 2  | 1     | 20     | (20 + 0 + 0)
+----+-------+--------+
```
员工 ‘3’ 有两个工资记录，不包括最近一个月的 ‘4’ 月:
- 第 ‘3’ 个月为 60。
- 第 ‘2’ 个月是 40。
因此, 该员工的累计工资汇总为:
```
+----+-------+--------+
| id | month | salary |
+----+-------+--------+
| 3  | 3     | 100    | (60 + 40 + 0)
| 3  | 2     | 40     | (40 + 0 + 0)
+----+-------+--------+
```
*/

WITH
-- 1. 模拟 Employee 表数据
Employee AS (
    SELECT 1 AS id, 1 AS month, 20 AS salary UNION ALL
    SELECT 2, 1, 20 UNION ALL
    SELECT 1, 2, 30 UNION ALL
    SELECT 2, 2, 30 UNION ALL
    SELECT 3, 2, 40 UNION ALL
    SELECT 1, 3, 40 UNION ALL
    SELECT 3, 3, 60 UNION ALL
    SELECT 1, 4, 60 UNION ALL
    SELECT 3, 4, 70 UNION ALL
    SELECT 1, 7, 90 UNION ALL
    SELECT 1, 8, 90
)
select
    id,
    month,
    salary + if(previous_month + 1 = month,previous_salary,0) + if(pre_previous_month + 1= previous_month,pre_previous_salary,0) salary
from (
         select id,
                month,
                salary,
                lag(salary,1,0) over(partition by id order by month) previous_salary,
                lag(month,1) over(partition by id order by month) previous_month,
                lag(salary,2,0) over(partition by id order by month) pre_previous_salary,
                lag(month,2) over(partition by id order by month) pre_previous_month,
                lead(salary,1) over(partition by id order by month) next_salary
         from Employee t1
     ) t2
where next_salary is not null


~~~



## 53 符合条件的投保之和

~~~sql
/*
`Insurance` 表:
```
+----------+-------+
| Column Name | Type  |
+----------+-------+
| pid      | int   |
| tiv_2015 | float |
| tiv_2016 | float |
| lat      | float |
| lon      | float |
+----------+-------+
```
pid 是这张表的主键(具有唯一值的列)。
表中的每一行都包含一条保险信息，其中:
pid 是投保人的投保编号。
tiv_2015 是该投保人在 2015 年的总投保金额, tiv_2016 是该投保人在 2016 年的总投保金额。
lat 是投保人所在城市的纬度。题目数据确保 lat 不为空。
lon 是投保人所在城市的经度。题目数据确保 lon 不为空。

编写解决方案报告 2016 年 (tiv_2016) 所有满足下述条件的投保人的投保金额之和:
他在 2015 年的投保额 (tiv_2015) 至少跟一个其他投保人在 2015 年的投保额相同。
他所在的城市必须与其他投保人人都不同 (也就是说说 (lat, lon) 不能跟其他任何一个投保人完全相同)。
tiv_2016 四舍五入的 两位小数。
查询结果格式如下例所示。

示例 1:

输入:
`Insurance` 表:
```
+-----+----------+----------+-----+-----+
| pid | tiv_2015 | tiv_2016 | lat | lon |
+-----+----------+----------+-----+-----+
| 1   | 10       | 5        | 10  | 10  |
| 2   | 20       | 20       | 20  | 20  |
| 3   | 10       | 30       | 20  | 20  |
| 4   | 10       | 40       | 40  | 40  |
+-----+----------+----------+-----+-----+
```
输出:
```
+----------+
| tiv_2016 |
+----------+
| 45.00    |
+----------+
```
解释:
表中的第一条记录和最后一条记录都满足两个条件。
tiv_2015 值为 10 与第三条和第四条记录相同, 且其位置是唯一的。

第二条记录不符合任何一个条件。其 tiv_2015 与其他投保人不同，并且位置与第三条记录相同，这也导致了第三条记录不符合题目要求。
因此, 结果是第一条记录和最后一条记录的 tiv_2016 之和, 即 45 。
*/


/*
1. 至少有一个2015年投保相同，只需要过滤掉2015年按照tiv分组后，计数为1的pid （符合条件的pid有 1 3 4 ）
2. 要去与其他投保人的投保城市都不相同，需要过滤出按照城市位置分组后，过滤出分组内只有一个计数的pid （符合条件你的pid有  1 4）
3. 1和2的数据集合求交集 （结果为pid 1， 4）


*/

WITH
-- 1. 模拟 Insurance 表
Insurance AS (
    SELECT 1 AS pid, 10.0 AS tiv_2015, 5.0 AS tiv_2016, 10.0 AS lat, 10.0 AS lon UNION ALL
    SELECT 2, 20.0, 20.0, 20.0, 20.0 UNION ALL
    SELECT 3, 10.0, 30.0, 20.0, 20.0 UNION ALL
    SELECT 4, 10.0, 40.0, 40.0, 40.0
)
select
    round(sum(tiv_2016),2)  tiv_2016
from (
         select
             t1.pid,
             t1.tiv_2016,
             count(1) over(partition by tiv_2015) group_2015,
             count(1) over(partition by lat,lon) group_city
         from Insurance t1

     ) t2
where t2.group_2015 != 1 and t2.group_city = 1

~~~



## 54 符合条件的连续

~~~sql
/*
表: `Stadium`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| visit_date  | date    |
| people      | int     |
+-------------+---------+
```
`visit_date` 是该表中具有唯一值的列。
每日人流量信息被记录在这三列信息中：序号 (id)、日期 (visit_date)、人流量 (people)
每天只有一行记录，日期随着 id 的增加而增加

编写解决方案找出每行的`人数大于或等于 100` 且 `id 连续的三行或更多行记录`。
返回按 `visit_date` 升序排列 的结果表。
查询结果格式如下所示。

示例 1:

输入:
`Stadium` 表:
```
+----+------------+--------+
| id | visit_date | people |
+----+------------+--------+
| 1  | 2017-01-01 | 10     |
| 2  | 2017-01-02 | 109    |
| 3  | 2017-01-03 | 150    |
| 4  | 2017-01-04 | 99     |
| 5  | 2017-01-05 | 145    |
| 6  | 2017-01-06 | 1455   |
| 7  | 2017-01-07 | 199    |
| 8  | 2017-01-09 | 188    |
+----+------------+--------+
```
输出:
```
+----+------------+--------+
| id | visit_date | people |
+----+------------+--------+
| 5  | 2017-01-05 | 145    |
| 6  | 2017-01-06 | 1455   |
| 7  | 2017-01-07 | 199    |
| 8  | 2017-01-09 | 188    |
+----+------------+--------+
```
解释:
id 为 5、6、7、8 的四行 id 连续, 并且每行都有 >= 100 的人数记录。
请注意，即便第 7 行和第 8 行的 visit_date 不是连续的, 输出也应当包含第 8 行, 因为我们只需要考虑 id 连续的记录。
不输出 id 为 2 和 3 的行, 因为至少需要三条 id 连续的记录。
*/

WITH
-- 1. 模拟 Stadium 表
Stadium AS (
    SELECT 1 AS id, CAST('2017-01-01' AS DATE) AS visit_date, 10 AS people UNION ALL
    SELECT 2, CAST('2017-01-02' AS DATE), 109 UNION ALL
    SELECT 3, CAST('2017-01-03' AS DATE), 150 UNION ALL
    SELECT 4, CAST('2017-01-04' AS DATE), 99 UNION ALL
    SELECT 5, CAST('2017-01-05' AS DATE), 145 UNION ALL
    SELECT 6, CAST('2017-01-06' AS DATE), 1455 UNION ALL
    SELECT 7, CAST('2017-01-07' AS DATE), 199 UNION ALL
    SELECT 8, CAST('2017-01-09' AS DATE), 188
)

-- 方式1
/*
     ,
    continus_analysis as (
        select
            id,
            visit_date,
            people,
            count(1) over(partition by group_flag) continus_days
        from (
                 select id,
                        people,
                        visit_date,
                        sum(if(diff is null or diff = 1,0,1)) over(order by id) group_flag
                 from (
                          select
                              id,
                              people,
                              visit_date,
                              id - lag(id, 1) over(order by id) diff
                          from Stadium t1
                          where people >= 100
                      ) t2

             ) t3

    )
select id,
       visit_date,
       people
from continus_analysis t0
where continus_days >= 3
order by visit_date;
*/

-- 方式2
select id,
       visit_date,
       people
from (
         select id,
                visit_date,
                people,
                id - row_number() over (order by id) group_flag,
                count(1) over(partition by (id - row_number() over (order by id))) continus_days
         from Stadium t0
         where people >= 100
     ) t1
where continus_days >= 3
order by visit_date;

/*
传统聚合函数（SUM, COUNT等）：不允许直接嵌套，需使用子查询或CTE。
窗口函数（... over (...)）：允许其 partition by 或 order by 子句中包含另一个窗口函数
*/
~~~



## 55 有好友最多的人及好友数

~~~sql

/*
`RequestAccepted` 表:
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| requester_id  | int     |
| accepter_id   | int     |
| accept_date   | date    |
+---------------+---------+
```
(requester_id, accepter_id) 是这张表的主键(具有唯一值的列的组合)。
这张表包含发送好友请求的人的 ID ，接收好友请求的人的 ID ，以及好友请求通过的日期。
编写解决方案，找出拥有最多的好友的人和他拥有的好友数目。
生成的测试用例保证拥有最多好友数目的人只有 `1` 个人。
查询结果格式如下例所示。

示例 1:

输入:
`RequestAccepted` 表:
```
+--------------+-------------+-------------+
| requester_id | accepter_id | accept_date |
+--------------+-------------+-------------+
| 1            | 2           | 2016/06/03  |
| 1            | 3           | 2016/06/08  |
| 2            | 3           | 2016/06/08  |
| 3            | 4           | 2016/06/09  |
+--------------+-------------+-------------+
```
输出:
```
+----+-----+
| id | num |
+----+-----+
| 3  | 3   |
+----+-----+
```
解释:
编号为 `3` 的人是编号为 `1` , `2` 和 `4` 的人的好友, 所以他总共有 `3` 个好友, 比其他人都多。

*/

WITH
-- 1. 模拟 RequestAccepted 表
RequestAccepted AS (
    SELECT 1 AS requester_id, 2 AS accepter_id, CAST('2016-06-03' AS DATE) AS accept_date UNION ALL
    SELECT 1, 3, CAST('2016-06-08' AS DATE) UNION ALL
    SELECT 2, 3, CAST('2016-06-08' AS DATE) UNION ALL
    SELECT 3, 4, CAST('2016-06-09' AS DATE)
)
-- 方式1
/*
select
    requester_id as id,
    count(distinct accepter_id) num
from (
         select requester_id,
                accepter_id
         from RequestAccepted t0
         union all
         select
             accepter_id,
             requester_id
         from RequestAccepted t1
     ) t2
group by requester_id
order by num desc
limit 1*/

     -- 方式2
,
    request_sent as (
        select
            requester_id as id,
            count(1) request_nums
        from RequestAccepted t0
        group by requester_id
    ),
    receive_request as (
        select
            accepter_id as id,
            count(1) receive_nums
        from RequestAccepted t0
        group by accepter_id
    )
select
    nvl(t0.id,t1.id) as id,
    sum(nvl(t0.receive_nums,0) ) + sum(nvl(t1.request_nums,0) ) as num
from receive_request t0
full join request_sent t1
on t0.id = t1.id
group by nvl(t0.id,t1.id)
order by num desc
limit 1;

~~~



## 56 日期格式转化

```sql
/*
当前表 `a` `date_id` 字段样式如下，请获取后面日期（`2025-3-7~2025-3-1` 取`2025-3-1`）并修改成`yyyymmdd`样式，如 `20250301`

`2025-3-7~2025-3-1`
`2025-4-22~2025-4-9`
`2025-5-13~2025-4-23`
`2025-11-20~2025-11-12`
*/

WITH
-- 1. 模拟表 a 和 date_id 字段
a AS (
    SELECT '2025-3-7~2025-3-1' as date_id UNION ALL
    SELECT '2025-4-22~2025-4-9' UNION ALL
    SELECT '2025-5-13~2025-4-23' UNION ALL
    SELECT '2025-11-20~2025-11-12'
)
select
    date_id,
    concat(
            split(suffix_date, '-')[0],
            '-',
            lpad(split(suffix_date, '-')[1], 2, '0'),
            '-',
            lpad(split(suffix_date, '-')[2], 2, '0')
    ) suffix_deal_date


from (
         select
             date_id,
             split(date_id,'~')[1] suffix_date
         from a
     ) t0
```



## 57 遍历二叉树

~~~sql
/*
表: `Tree`
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| id          | int  |
| p_id        | int  |
+-------------+------+
```
id 是该表中具有唯一值的列。
该表的每行包含树中节点的 id 及其父节点的 id 信息。
给定的结构总是一个有效的树。
树中的每个节点可以是以下三种类型之一:
"Leaf": 节点是叶子节点。
"Root": 节点是树的根节点。
"Inner": 节点既不是叶子节点也不是根节点。
编写一个解决方案来报告树中每个节点的类型。
以任意顺序返回结果表。
结果格式如下所示。

示例 1:
输入:
`Tree table`:
```
+----+------+
| id | p_id |
+----+------+
| 1  | null |
| 2  | 1    |
| 3  | 1    |
| 4  | 2    |
| 5  | 2    |
+----+------+
```
输出:
```
+----+-------+
| id | type  |
+----+-------+
| 1  | Root  |
| 2  | Inner |
| 3  | Leaf  |
| 4  | Leaf  |
| 5  | Leaf  |
+----+-------+
```
解释:
节点 1 是根节点, 因为它的父节点为空, 并且它有子节点 2 和 3。
节点 2 是一个内部节点, 因为它有父节点 1 和子节点 4 和 5。
节点 3、4 和 5 是叶子节点, 因为它们有父节点而没有子节点。

示例 2:
输入:
`Tree table`:
```
+----+------+
| id | p_id |
+----+------+
| 1  | null |
+----+------+
```
输出:
```
+----+-------+
| id | type  |
+----+-------+
| 1  | Root  |
+----+-------+
```
解释: 如果树中只有一个节点, 则只需要输出其根属性。
*/
WITH
-- 1. 模拟 Tree 表
Tree AS (
    SELECT 1 AS id, CAST(NULL AS INT) AS p_id UNION ALL
    SELECT 2, 1 UNION ALL
    SELECT 3, 1 UNION ALL
    SELECT 4, 2 UNION ALL
    SELECT 5, 2
)
/*
思路：
1. 根节点的父节点为null
2.叶子节点没有子节点
3. 其余为中间节点
*/


select
    id,
    type
from (
         select
             t2.id,
             case
                 when p_id is null then 'Root'
                 when p_id is not null and  s_id is not null then 'Inner'
                 else 'Leaf' end as type
         from (
                  select
                      t0.id,
                      t0.p_id,
                      t1.id s_id
                  from Tree t0
                  left join Tree t1
                  on t0.id = t1.p_id
              ) t2

     ) t3
group by id,type;




~~~



## 58 奇数偶数互换

~~~sql
/*
表: `Seat`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| id          | int      |
| student     | varchar  |
+-------------+----------+
```
id 是该表的主键 (唯一值) 列。
该表的每一行都表示学生的姓名和 ID。
ID 序列始终从 1 开始并连续增加。
编写解决方案来交换每两个连续的学生的座位号。如果学生的数量是奇数，则最后一个学生的id不交换。
按 id 升序 返回结果表。
查询结果格式如下所示。

示例 1:
输入:
`Seat` 表:
```
+----+---------+
| id | student |
+----+---------+
| 1  | Abbot   |
| 2  | Doris   |
| 3  | Emerson |
| 4  | Green   |
| 5  | Jeames  |
+----+---------+
```
输出:
```
+----+---------+
| id | student |
+----+---------+
| 1  | Doris   |
| 2  | Abbot   |
| 3  | Green   |
| 4  | Emerson |
| 5  | Jeames  |
+----+---------+
```
解释:
请注意，如果学生人数为奇数，则不需要更换最后一名学生的座位。
*/

WITH
-- 1. 模拟 Seat 表
Seat AS (
    SELECT 1 AS id, 'Abbot' AS student UNION ALL
    SELECT 2, 'Doris'   UNION ALL
    SELECT 3, 'Emerson' UNION ALL
    SELECT 4, 'Green'   UNION ALL
    SELECT 5, 'Jeames'
)
select
    case
        when stable_id % 2 == 1 and stable_id == total_nummbers then stable_id
        when stable_id % 2 == 1 and stable_id != total_nummbers then stable_id + 1
        when stable_id % 2 == 0 then stable_id - 1
    else null end as ids,
    student

from (
         select
             id,
             student,
             row_number() over (order by id) stable_id,
             count(1) over() total_nummbers
         from Seat t0
     ) t1;

~~~



## 59 符合条件的业务

~~~sql
/*

事件表: `Events`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| business_id   | int     |
| event_type    | varchar |
| occurrences   | int     |
+---------------+---------+
```
(business_id, event_type) 是这个表的主键 (具有唯一值的列的组合)。
表中的每一行记录了某种类型的事件在某些业务中多次发生的信息。
平均活动 是指有特定 event_type 的具有该事件的所有公司的 occurrences 的均值。
活跃业务 是指具有 多个 event_type 的业务, 它们的 occurrences 严格大于 该事件的平均活动次数。
写一个解决方案, 找到所有 活跃业务。
以 任意顺序 返回结果表。
结果格式如下所示。

示例 1:

输入:
`Events table`:
```
+-------------+------------+-------------+
| business_id | event_type | occurrences |
+-------------+------------+-------------+
| 1           | reviews    | 7           |
| 3           | reviews    | 3           |
| 1           | ads        | 11          |
| 2           | ads        | 7           |
| 3           | ads        | 6           |
| 1           | page views | 3           |
| 2           | page views | 12          |
+-------------+------------+-------------+
```
输出:
```
+-------------+
| business_id |
+-------------+
| 1           |
+-------------+
```
解释:
每次活动的平均活动可计算如下:
- 'reviews': (7+3)/2 = 5
- 'ads': (11+7+6)/3 = 8
- 'page views': (3+12)/2 = 7.5
id=1 的业务有 7 个 'reviews' 事件(多于 5 个)和 11 个 'ads' 事件(多于 8 个), 所以它是一个活跃的业务。
*/

WITH
-- 1. 模拟 Events 表
Events AS (
    SELECT 1 AS business_id, 'reviews' AS event_type, 7 AS occurrences UNION ALL
    SELECT 3, 'reviews', 3 UNION ALL
    SELECT 1, 'ads', 11 UNION ALL
    SELECT 2, 'ads', 7 UNION ALL
    SELECT 3, 'ads', 6 UNION ALL
    SELECT 1, 'page views', 3 UNION ALL
    SELECT 2, 'page views', 12
)
select
    business_id
from (
         select
             business_id,
             if(occurrences > avg(occurrences) over(partition by event_type) , 1,0) over_times
         from Events t0
     ) t1
where over_times = 1
group by business_id;
~~~



## 60 各种条件人群支出

~~~sql
/*
支出表: `Spending`
```
+-------------+--------+
| Column Name | Type   |
+-------------+--------+
| user_id     | int    |
| spend_date  | date   |
| platform    | enum   |
| amount      | int    |
+-------------+--------+
```
这张表记录了用户在一个在线购物网站的支出历史，该在线购物平台同时拥有桌面端 (`'desktop'`) 和手机端 (`'mobile'`) 的应用程序。
(user_id, spend_date, platform) 是这张表的主键(具有唯一值的列的组合)。
平台列 platform 是一种 ENUM 类型为 (`'desktop'`, `'mobile'`)。
编写解决方案找出每天 仅 使用手机端用户、仅 使用桌面端用户和 同时 使用桌面端和手机端的用户人数和总支出金额。
以 任意顺序 返回结果表。
返回结果格式如下例所示:

示例 1:

输入:
`Spending table`:
```
+---------+------------+----------+--------+
| user_id | spend_date | platform | amount |
+---------+------------+----------+--------+
| 1       | 2019-07-01 | mobile   | 100    |
| 1       | 2019-07-01 | desktop  | 100    |
| 2       | 2019-07-01 | mobile   | 100    |
| 2       | 2019-07-02 | mobile   | 100    |
| 3       | 2019-07-01 | desktop  | 100    |
| 3       | 2019-07-02 | desktop  | 100    |
+---------+------------+----------+--------+
```
输出:
```
+------------+----------+--------------+-------------+
| spend_date | platform | total_amount | total_users |
+------------+----------+--------------+-------------+
| 2019-07-01 | desktop  | 100          | 1           |
| 2019-07-01 | mobile   | 100          | 1           |
| 2019-07-01 | both     | 200          | 1           |
| 2019-07-02 | desktop  | 100          | 1           |
| 2019-07-02 | mobile   | 100          | 1           |
| 2019-07-02 | both     | 0            | 0           |
+------------+----------+--------------+-------------+
```
解释:
在 2019-07-01, 用户1 同时 使用桌面端和手机端购买, 用户2 仅 使用了手机端购买, 而用户3 仅 使用了桌面端购买。
在 2019-07-02, 用户2 仅 使用了手机端购买, 用户3 仅 使用了桌面端购买, 且没有用户 同时 使用桌面端和手机端购买。
*/

WITH
-- 1. 模拟 Spending 表
Spending AS (
    SELECT 1 AS user_id, CAST('2019-07-01' AS DATE) AS spend_date, 'mobile' AS platform, 100 AS amount UNION ALL
    SELECT 1, CAST('2019-07-01' AS DATE), 'desktop', 100 UNION ALL
    SELECT 2, CAST('2019-07-01' AS DATE), 'mobile', 100 UNION ALL
    SELECT 2, CAST('2019-07-02' AS DATE), 'mobile', 100 UNION ALL
    SELECT 3, CAST('2019-07-01' AS DATE), 'desktop', 100 UNION ALL
    SELECT 3, CAST('2019-07-02' AS DATE), 'desktop', 100
),
    -- 每日汇总情况
    summary as (
        select
            t0.spend_date,
            case
                when size(t1.refer_platforms) == 1 and refer_platforms[0] = 'mobile' then 'mobile'
                when size(t1.refer_platforms) == 1 and refer_platforms[0] = 'desktop' then 'desktop'
                when size(t1.refer_platforms) == 2 then 'both'
                else null end as platform,
            sum(t0.amount) total_amount,
            count(distinct t0.user_id) total_users
        from Spending t0
                 left join (
            select user_id,
                   spend_date,
                   sum(amount) date_amount,
                   collect_set(platform) refer_platforms
            from Spending t0
            group by user_id,spend_date

        ) t1
                           on t0.user_id = t1.user_id and t0.spend_date = t1.spend_date
        group by case
                     when size(t1.refer_platforms) == 1 and refer_platforms[0] = 'mobile' then 'mobile'
                     when size(t1.refer_platforms) == 1 and refer_platforms[0] = 'desktop' then 'desktop'
                     when size(t1.refer_platforms) == 2 then 'both'
                     else null end ,
                 t0.spend_date

    ),
    -- 日期消费维度
    dim_type as (
        select
            tt0.spend_date,
            tt1.platform
        from (
                 select
                     spend_date
                 from Spending
                 group by spend_date
             ) tt0
        lateral view explode(array('desktop','mobile','both')) tt1 as platform
    )
select
    t1.spend_date,
    t1.platform,
    nvl(t2.total_amount,0) total_amount,
    nvl(t2.total_users,0) total_users
from dim_type t1
left join summary t2
on t1.spend_date = t2.spend_date and t1.platform = t2.platform



~~~



## 61 条件帖子每日占比

~~~sql
/*
动作表: `Actions`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| user_id     | int     |
| post_id     | int     |
| action_date | date    |
| action      | enum    |
| extra       | varchar |
+-------------+---------+
```
这张表可能存在重复的行。
`action` 列的类型是 ENUM, 可能的值为 ('view', 'like', 'reaction', 'comment', 'report', 'share')。
`extra` 列拥有一些可选信息，例如：报告理由 (a reason for report)或反应类型 (a type of reaction)等。

移除表: `Removals`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| post_id     | int     |
| remove_date | date    |
+-------------+---------+
```
这张表的主键是 post_id (具有唯一值的列)。
这张表的每一行表示一个被移除的帖子，原因可能是由于被举报或被管理员审查。

编写解决方案，统计在被报告为垃圾广告的帖子中，被移除的帖子的每日平均占比，四舍五入到小数点后 2 位。
结果的格式如下。

示例 1:

输入:
`Actions table`:
```
+---------+---------+-------------+--------+---------+
| user_id | post_id | action_date | action | extra   |
+---------+---------+-------------+--------+---------+
| 1       | 1       | 2019-07-01  | view   | null    |
| 1       | 1       | 2019-07-01  | like   | null    |
| 1       | 1       | 2019-07-01  | share  | null    |
| 2       | 2       | 2019-07-04  | view   | null    |
| 2       | 2       | 2019-07-04  | report | spam    |
| 3       | 4       | 2019-07-04  | view   | null    |
| 3       | 4       | 2019-07-04  | report | spam    |
| 4       | 3       | 2019-07-02  | view   | null    |
| 4       | 3       | 2019-07-02  | report | spam    |
| 5       | 2       | 2019-07-03  | view   | null    |
| 5       | 2       | 2019-07-03  | report | racism  |
| 5       | 5       | 2019-07-03  | view   | null    |
| 5       | 5       | 2019-07-03  | report | racism  |
+---------+---------+-------------+--------+---------+
```
`Removals table`:
```
+---------+-------------+
| post_id | remove_date |
+---------+-------------+
| 2       | 2019-07-20  |
| 3       | 2019-07-18  |
+---------+-------------+
```
输出:
```
+-----------------------+
| average_daily_percent |
+-----------------------+
| 75.00                 |
+-----------------------+
```
解释:
2019-07-04 的垃圾广告移除率是 50%，因为有两张帖子被报告为垃圾广告，但只有一个得到移除。
2019-07-02 的垃圾广告移除率是 100%，因为有一张帖子被举报为垃圾广告并得到移除。
其余几天没有收到垃圾广告的举报，因此平均值为: (50 + 100) / 2 = 75%
注意，输出仅需要一个平均值即可，我们并不关注移除操作的日期。
*/


WITH
-- 1. 模拟 Actions 表
Actions AS (
    SELECT 1 AS user_id, 1 AS post_id, CAST('2019-07-01' AS DATE) AS action_date, 'view' AS action, CAST(NULL AS STRING) AS extra UNION ALL
    SELECT 1, 1, CAST('2019-07-01' AS DATE), 'like', NULL UNION ALL
    SELECT 1, 1, CAST('2019-07-01' AS DATE), 'share', NULL UNION ALL
    SELECT 2, 2, CAST('2019-07-04' AS DATE), 'view', NULL UNION ALL
    SELECT 2, 2, CAST('2019-07-04' AS DATE), 'report', 'spam' UNION ALL
    SELECT 3, 4, CAST('2019-07-04' AS DATE), 'view', NULL UNION ALL
    SELECT 3, 4, CAST('2019-07-04' AS DATE), 'report', 'spam' UNION ALL
    SELECT 4, 3, CAST('2019-07-02' AS DATE), 'view', NULL UNION ALL
    SELECT 4, 3, CAST('2019-07-02' AS DATE), 'report', 'spam' UNION ALL
    SELECT 5, 2, CAST('2019-07-03' AS DATE), 'view', NULL UNION ALL
    SELECT 5, 2, CAST('2019-07-03' AS DATE), 'report', 'racism' UNION ALL
    SELECT 5, 5, CAST('2019-07-03' AS DATE), 'view', NULL UNION ALL
    SELECT 5, 5, CAST('2019-07-03' AS DATE), 'report', 'racism'
),

-- 2. 模拟 Removals 表
Removals AS (
    SELECT 2 AS post_id, CAST('2019-07-20' AS DATE) AS remove_date UNION ALL
    SELECT 3, CAST('2019-07-18' AS DATE)
)

select
    round(avg(date_rate),2) * 100 as average_daily_percent
from (
         select
             t1.action_date,
             count(distinct t2.post_id) / count(distinct t1.post_id) date_rate
         from Actions t1
                  left join Removals t2
                            on t1.post_id = t2.post_id
         where t1.action = 'report' and t1.extra = 'spam'
         group by t1.action_date

     ) t3


~~~





## 62 注册和购买都在2019年的用户

~~~sql
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
`user_id` 是此表主键 (具有唯一值的列)。
表中描述了购物网站的的用户信息，用户可以在此网站上进行商品买卖。

表: `Orders`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| order_id    | int     |
| order_date  | date    |
| item_id     | int     |
| buyer_id    | int     |
| seller_id   | int     |
+-------------+---------+
```
`order_id` 是此表主键 (具有唯一值的列)。
`item_id` 是 `Items` 表的外键 (reference 列)。
`(buyer_id, seller_id)` 是 `User` 表的外键。

表: `Items`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| item_id     | int     |
| item_brand  | varchar |
+-------------+---------+
```
`item_id` 是此表的主键 (具有唯一值的列)。

编写解决方案找出每个用户的注册日期和在 `2019` 年作为买家的订单总数。
以任意顺序返回结果表。
查询结果格式如下。

示例 1:
输入:
`Users` 表:
```
+----------+------------+------------------+
| user_id  | join_date  | favorite_brand   |
+----------+------------+------------------+
| 1        | 2018-01-01 | Lenovo           |
| 2        | 2018-02-09 | Samsung          |
| 3        | 2018-01-19 | LG               |
| 4        | 2018-05-21 | HP               |
+----------+------------+------------------+
```
`Orders` 表:
```
+----------+------------+---------+----------+-----------+
| order_id | order_date | item_id | buyer_id | seller_id |
+----------+------------+---------+----------+-----------+
| 1        | 2019-08-01 | 4       | 1        | 2         |
| 2        | 2018-08-02 | 2       | 1        | 3         |
| 3        | 2019-08-03 | 3       | 2        | 3         |
| 4        | 2018-08-04 | 1       | 4        | 2         |
| 5        | 2018-08-04 | 1       | 3        | 4         |
| 6        | 2019-08-05 | 2       | 2        | 4         |
+----------+------------+---------+----------+-----------+
```
`Items` 表:
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
+----------+------------+----------------+
| buyer_id | join_date  | orders_in_2019 |
+----------+------------+----------------+
| 1        | 2018-01-01 | 1              |
| 2        | 2018-02-09 | 2              |
| 3        | 2018-01-19 | 0              |
| 4        | 2018-05-21 | 0              |
+----------+------------+----------------+
```
*/
WITH
-- 1. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, CAST('2018-01-01' AS DATE) AS join_date, 'Lenovo' AS favorite_brand UNION ALL
    SELECT 2, CAST('2018-02-09' AS DATE), 'Samsung' UNION ALL
    SELECT 3, CAST('2018-01-19' AS DATE), 'LG' UNION ALL
    SELECT 4, CAST('2018-05-21' AS DATE), 'HP'
),

-- 2. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, CAST('2019-08-01' AS DATE) AS order_date, 4 AS item_id, 1 AS buyer_id, 2 AS seller_id UNION ALL
    SELECT 2, CAST('2018-08-02' AS DATE), 2, 1, 3 UNION ALL
    SELECT 3, CAST('2019-08-03' AS DATE), 3, 2, 3 UNION ALL
    SELECT 4, CAST('2018-08-04' AS DATE), 1, 4, 2 UNION ALL
    SELECT 5, CAST('2018-08-04' AS DATE), 1, 3, 4 UNION ALL
    SELECT 6, CAST('2019-08-05' AS DATE), 2, 2, 4
),

-- 3. 模拟 Items 表 (此题解法中未使用，但为保持完整性而包含)
Items AS (
    SELECT 1 AS item_id, 'Samsung' AS item_brand UNION ALL
    SELECT 2, 'Lenovo' UNION ALL
    SELECT 3, 'LG' UNION ALL
    SELECT 4, 'HP'
)
select
    t0.user_id,
    t0.join_date,
    count(distinct t1.order_id)
from Users t0
left join Orders t1
on t0.user_id = t1.buyer_id and year(t1.order_date) = 2019
group by t0.user_id,join_date
~~~



## 63 出两件商品的售货员（符合条件判定）

~~~sql
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

~~~



## 64 某日商品的价格(某个时间点的信息)

~~~sql
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





~~~

## 65 首次订单中即时订单的比例

~~~sql

/*
配送表: `Delivery`
```
+-------------------------------+---------+
| Column Name                   | Type    |
+-------------------------------+---------+
| delivery_id                   | int     |
| customer_id                   | int     |
| order_date                    | date    |
| customer_pref_delivery_date   | date    |
+-------------------------------+---------+
```
`delivery_id` 是该表中具有唯一值的列。
该表保存着顾客的食物配送信息，顾客在某个日期下了订单，并指定了一个期望的配送日期（和下单日期相同或者在那之后）。
如果顾客期望的配送日期和下单日期相同，则该订单称为「即时订单」，否则称为「计划订单」。
「首次订单」是顾客最早创建的订单。我们保证一个顾客只会有一个「首次订单」。
编写解决方案以获取即时订单在所有用户的首次订单中的比例。保留两位小数。
结果示例示例如下所示：

示例 1:

输入:
`Delivery` 表:
```
+-------------+-------------+------------+-------------------------------+
| delivery_id | customer_id | order_date | customer_pref_delivery_date |
+-------------+-------------+------------+-------------------------------+
| 1           | 1           | 2019-08-01 | 2019-08-02                    |
| 2           | 2           | 2019-08-02 | 2019-08-02                    |
| 3           | 1           | 2019-08-11 | 2019-08-12                    |
| 4           | 3           | 2019-08-24 | 2019-08-24                    |
| 5           | 3           | 2019-08-21 | 2019-08-22                    |
| 6           | 2           | 2019-08-11 | 2019-08-13                    |
| 7           | 4           | 2019-08-09 | 2019-08-09                    |
+-------------+-------------+------------+-------------------------------+
```
输出:
```
+----------------------+
| immediate_percentage |
+----------------------+
| 50.00                |
+----------------------+
```
解释:
1 号顾客的 1 号订单是首次订单，并且是计划订单。
2 号顾客的 2 号订单是首次订单，并且是即时订单。
3 号顾客的 5 号订单是首次订单，并且是计划订单。
4 号顾客的 7 号订单是首次订单，并且是即时订单。
因此，一半顾客的首次订单是即时的。
*/

WITH
-- 1. 模拟 Delivery 表
Delivery AS (
    SELECT 1 AS delivery_id, 1 AS customer_id, CAST('2019-08-01' AS DATE) AS order_date, CAST('2019-08-02' AS DATE) AS customer_pref_delivery_date UNION ALL
    SELECT 2, 2, CAST('2019-08-02' AS DATE), CAST('2019-08-02' AS DATE) UNION ALL
    SELECT 3, 1, CAST('2019-08-11' AS DATE), CAST('2019-08-12' AS DATE) UNION ALL
    SELECT 4, 3, CAST('2019-08-24' AS DATE), CAST('2019-08-24' AS DATE) UNION ALL
    SELECT 5, 3, CAST('2019-08-21' AS DATE), CAST('2019-08-22' AS DATE) UNION ALL
    SELECT 6, 2, CAST('2019-08-11' AS DATE), CAST('2019-08-13' AS DATE) UNION ALL
    SELECT 7, 4, CAST('2019-08-09' AS DATE), CAST('2019-08-09' AS DATE)
)
select
    count(distinct if(order_date = customer_pref_delivery_date,delivery_id,null)) / count(distinct delivery_id)  immediate_percentage
from (
         select delivery_id,
                customer_id,
                order_date,
                customer_pref_delivery_date,
                row_number() over (partition by t0.customer_id order by order_date) order_number
         from Delivery t0
     ) t1
where order_number = 1;

~~~

## 66 每个月每个国家/地区的信息

~~~sql

/*
表: `Transactions`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| country     | varchar |
| state       | enum    |
| amount      | int     |
| trans_date  | date    |
+-------------+---------+
```
id 是这个表的主键。
该表包含有关传入事务的信息。
state 列类型为 ["approved", "declined"] 之一。
编写一个 sql 查询来查找每个月和每个国家/地区的事务数及其总金额、已批准的事务数及其总金额。
以任意顺序 返回结果表。
查询结果格式如下所示。

示例 1:

输入:
`Transactions table`:
```
+-----+---------+----------+--------+------------+
| id  | country | state    | amount | trans_date |
+-----+---------+----------+--------+------------+
| 121 | US      | approved | 1000   | 2018-12-18 |
| 122 | US      | declined | 2000   | 2018-12-19 |
| 123 | US      | approved | 2000   | 2019-01-01 |
| 124 | DE      | approved | 2000   | 2019-01-07 |
+-----+---------+----------+--------+------------+
```
输出:
```
+---------+---------+-------------+----------------+--------------------+----------------------+
| month   | country | trans_count | approved_count | trans_total_amount | approved_total_amount|
+---------+---------+-------------+----------------+--------------------+----------------------+
| 2018-12 | US      | 2           | 1              | 3000               | 1000                 |
| 2019-01 | US      | 1           | 1              | 2000               | 2000                 |
| 2019-01 | DE      | 1           | 1              | 2000               | 2000                 |
+---------+---------+-------------+----------------+--------------------+----------------------+
```
*/

WITH
-- 1. 模拟 Transactions 表
Transactions AS (
    SELECT 121 AS id, 'US' AS country, 'approved' AS state, 1000 AS amount, CAST('2018-12-18' AS DATE) AS trans_date UNION ALL
    SELECT 122, 'US', 'declined', 2000, CAST('2018-12-19' AS DATE) UNION ALL
    SELECT 123, 'US', 'approved', 2000, CAST('2019-01-01' AS DATE) UNION ALL
    SELECT 124, 'DE', 'approved', 2000, CAST('2019-01-07' AS DATE)
)
select
    substr(t0.trans_date,1,7),country,
    count(id) trans_count,
    count(if(state = 'approved',id,null)) approved_count,
    sum(amount) trans_total_amount,
    sum(if(state = 'approved',amount,0)) approved_total_amount


from Transactions t0
group by substr(t0.trans_date,1,7),country

~~~

## 67 每组中的获胜者

~~~sql



/*
`Players` 玩家表
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| player_id   | int     |
| group_id    | int     |
+-------------+---------+
```
`player_id` 是此表的主键(具有唯一值的列)。
此表的每一行表示每个玩家的组。

`Matches` 赛事表
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| match_id      | int     |
| first_player  | int     |
| second_player | int     |
| first_score   | int     |
| second_score  | int     |
+---------------+---------+
```
`match_id` 是此表的主键(具有唯一值的列)。
每一行是一场比赛的记录, `first_player` 和 `second_player` 表示该场比赛的球员 ID。
`first_score` 和 `second_score` 分别表示 `first_player` 和 `second_player` 的得分。
你可以假设，在每一场比赛中，球员都属于同一组。

每组的获胜者是在组内累积得分最高的选手。如果平局, `player_id` 最小的选手获胜。
编写解决方案来查找每组中的获胜者。
返回的结果表单 没有顺序要求。
返回结果格式如下所示。

示例 1:

输入:
`Players` 表:
```
+-----------+----------+
| player_id | group_id |
+-----------+----------+
| 15        | 1        |
| 25        | 1        |
| 30        | 1        |
| 45        | 1        |
| 10        | 2        |
| 35        | 2        |
| 50        | 2        |
| 20        | 3        |
| 40        | 3        |
+-----------+----------+
```
`Matches` 表:
```
+----------+--------------+---------------+-------------+--------------+
| match_id | first_player | second_player | first_score | second_score |
+----------+--------------+---------------+-------------+--------------+
| 1        | 15           | 45            | 3           | 0            |
| 2        | 30           | 25            | 1           | 2            |
| 3        | 30           | 15            | 2           | 0            |
| 4        | 40           | 20            | 5           | 2            |
| 5        | 35           | 50            | 1           | 1            |
+----------+--------------+---------------+-------------+--------------+
```
输出:
```
+----------+-----------+
| group_id | player_id |
+----------+-----------+
| 1        | 15        |
| 2        | 35        |
| 3        | 40        |
+----------+-----------+
```

*/

WITH
-- 1. 模拟 Players 表
Players AS (
    SELECT 15 AS player_id, 1 AS group_id UNION ALL
    SELECT 25, 1 UNION ALL
    SELECT 30, 1 UNION ALL
    SELECT 45, 1 UNION ALL
    SELECT 10, 2 UNION ALL
    SELECT 35, 2 UNION ALL
    SELECT 50, 2 UNION ALL
    SELECT 20, 3 UNION ALL
    SELECT 40, 3
),

-- 2. 模拟 Matches 表
Matches AS (
    SELECT 1 AS match_id, 15 AS first_player, 45 AS second_player, 3 AS first_score, 0 AS second_score UNION ALL
    SELECT 2, 30, 25, 1, 2 UNION ALL
    SELECT 3, 30, 15, 2, 0 UNION ALL
    SELECT 4, 40, 20, 5, 2 UNION ALL
    SELECT 5, 35, 50, 1, 1
),
    score_situation as (
        select
            case t1.player_id
                when 1 then first_player
                when 2 then second_player
                else null end player_id,
            sum(
                    case t1.player_id
                        when 1 then first_score
                        when 2 then second_score
                        else 0 end
            ) as player_total_scores
        from Matches t0
                 lateral view explode(array(1,2)) t1 as player_id
        group by case t1.player_id
                     when 1 then first_player
                     when 2 then second_player
                     else null end
    )
select
    group_id,
    player_id
from (
         select
             t2.group_id,
             t1.player_id,
             row_number() over (partition by t2.group_id order by t1.player_total_scores desc,t1.player_id asc) order_number
         from score_situation t1
                  left join Players t2
                            on t1.player_id = t2.player_id
     ) t3
where order_number = 1;

~~~

## 68 最后一个上巴士的人

~~~sql

/*
表: `Queue`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| person_id   | int      |
| person_name | varchar  |
| weight      | int      |
| turn        | int      |
+-------------+----------+
```
`person_id` 是这个表具有唯一值的列。
该表表示了所有候车乘客的信息。
表中 `person_id` 和 `turn` 列将包含从 `1` 到 `n` 的所有数字，其中 `n` 是表中的行数。
`turn` 决定了候车乘客上巴士的顺序，其中 `turn=1` 表示第一个上巴士，`turn=n` 表示最后一个上巴士。
`weight` 表示候车乘客的体重，以千克为单位。
有一队乘客在等着上巴士。然而，巴士有`1000` 千克的重量限制，所以其中一部分乘客可能无法上巴士。
编写解决方案找出 **最后一个** 上巴士且不超过重量限制的乘客，并报告 `person_name` 。题目测试用例确保顺位第一的人可以上巴士且不会超重。
返回结果格式如下所示。

示例 1:

输入:
`Queue` 表
```
+-----------+-------------+--------+------+
| person_id | person_name | weight | turn |
+-----------+-------------+--------+------+
| 5         | Alice       | 250    | 1    |
| 4         | Bob         | 175    | 5    |
| 3         | Alex        | 350    | 2    |
| 6         | John Cena   | 400    | 3    |
| 1         | Winston     | 500    | 6    |
| 2         | Marie       | 200    | 4    |
+-----------+-------------+--------+------+
```
输出:
```
+-------------+
| person_name |
+-------------+
| John Cena   |
+-------------+
```
解释:
为了简化, `Queue` 表按 `turn` 列由小到大排序。
```
+------+----+-----------+--------+--------------+
| Turn | ID | Name      | Weight | Total Weight |
+------+----+-----------+--------+--------------+
| 1    | 5  | Alice     | 250    | 250          |
| 2    | 3  | Alex      | 350    | 600          |
| 3    | 6  | John Cena | 400    | 1000         | (最后一个上巴士)
| 4    | 2  | Marie     | 200    | 1200         | (无法上巴士)
| 5    | 4  | Bob       | 175    | ---          |
| 6    | 1  | Winston   | 500    | ---          |
+------+----+-----------+--------+--------------+
```
*/

WITH
-- 1. 模拟 Queue 表
Queue AS (
    SELECT 5 AS person_id, 'Alice' AS person_name, 250 AS weight, 1 AS turn UNION ALL
    SELECT 4, 'Bob', 175, 5 UNION ALL
    SELECT 3, 'Alex', 350, 2 UNION ALL
    SELECT 6, 'John Cena', 400, 3 UNION ALL
    SELECT 1, 'Winston', 500, 6 UNION ALL
    SELECT 2, 'Marie', 200, 4
)
select
    person_name
from (
         select
             person_name,
             row_number() over (order by turn desc) bottom_number
         from (
                  select person_id,
                         person_name,
                         weight,
                         turn,
                         sum(weight) over(order by turn) current_total_weight
                  from Queue t0

              ) t1
         where current_total_weight <= 1000
     ) t2
where bottom_number = 1
~~~

## 69 积分排序

~~~sql

/*
表: `Teams`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| team_id     | int      |
| team_name   | varchar  |
+-------------+----------+
```
`team_id` 是该表具有唯一值的列。
表中的每一行都代表一支独立足球队。

表: `Matches`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| match_id    | int      |
| host_team   | int      |
| guest_team  | int      |
| host_goals  | int      |
| guest_goals | int      |
+-------------+----------+
```
`match_id` 是该表具有唯一值的列。
表中的每一行都代表一场已结束的比赛。
比赛的主客队分别由它们自己的 `id` 表示，他们的进球由 `host_goals` 和 `guest_goals` 分别表示。

你希望在所有比赛之后计算所有球队的比分。积分奖励方式如下:
*   如果球队赢了比赛(即比对手进更多的球)，就得 `3` 分。
*   如果双方打成平手(即，与对方得分相同)，则得 `1` 分。
*   如果球队输掉了比赛(例如，比对手少进球)，就 不得分。

编写解决方案，以找出每个队的 `team_id`, `team_name` 和 `num_points`。
返回的结果根据 `num_points` 降序排序，如果有两队积分相同，那么这两队按 `team_id` 升序排序。
返回结果格式如下。

示例 1:

输入:
`Teams table`:
```
+---------+--------------+
| team_id | team_name    |
+---------+--------------+
| 10      | Leetcode FC  |
| 20      | NewYork FC   |
| 30      | Atlanta FC   |
| 40      | Chicago FC   |
| 50      | Toronto FC   |
+---------+--------------+
```
`Matches table`:
```
+----------+-----------+------------+------------+-------------+
| match_id | host_team | guest_team | host_goals | guest_goals |
+----------+-----------+------------+------------+-------------+
| 1        | 10        | 20         | 3          | 0           |
| 2        | 30        | 10         | 2          | 2           |
| 3        | 10        | 50         | 5          | 1           |
| 4        | 20        | 30         | 1          | 0           |
| 5        | 50        | 30         | 1          | 0           |
+----------+-----------+------------+------------+-------------+
```
输出:
```
+---------+--------------+------------+
| team_id | team_name    | num_points |
+---------+--------------+------------+
| 10      | Leetcode FC  | 7          |
| 20      | NewYork FC   | 3          |
| 50      | Toronto FC   | 3          |
| 30      | Atlanta FC   | 1          |
| 40      | Chicago FC   | 0          |
+---------+--------------+------------+
```

*/
WITH
-- 1. 模拟 Teams 表
Teams AS (
    SELECT 10 AS team_id, 'Leetcode FC' AS team_name UNION ALL
    SELECT 20, 'NewYork FC' UNION ALL
    SELECT 30, 'Atlanta FC' UNION ALL
    SELECT 40, 'Chicago FC' UNION ALL
    SELECT 50, 'Toronto FC'
),

-- 2. 模拟 Matches 表
Matches AS (
    SELECT 1 AS match_id, 10 AS host_team, 20 AS guest_team, 3 AS host_goals, 0 AS guest_goals UNION ALL
    SELECT 2, 30, 10, 2, 2 UNION ALL
    SELECT 3, 10, 50, 5, 1 UNION ALL
    SELECT 4, 20, 30, 1, 0 UNION ALL
    SELECT 5, 50, 30, 1, 0
),
    team_scores as (
        select
            case t1.team_judge_number
                when 1 then host_team
                when 2 then guest_team
                else null end as team_id,

            sum(
                    case
                        when team_judge_number = 1 and  host_goals > guest_goals then 3
                        when team_judge_number = 1 and  host_goals < guest_goals then 0
                        when team_judge_number = 1 and  host_goals = guest_goals then 1
                        when team_judge_number = 2 and  host_goals < guest_goals then 3
                        when team_judge_number = 2 and  host_goals > guest_goals then 0
                        when team_judge_number = 2 and  host_goals = guest_goals then 1
                        else 0 end
            ) as num_points
        from Matches t0
                 lateral view explode(array(1,2)) t1 as team_judge_number
        group by
            case t1.team_judge_number
                when 1 then host_team
                when 2 then guest_team
                else null end
    )
select
    t0.team_id,
    t0.team_name,
    nvl(t1.num_points,0) as num_points
from Teams t0
left join team_scores t1
on t0.team_id = t1.team_id



~~~


## 70 连续状态的起止日期
~~~sql

/*
表: `Failed`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| fail_date   | date    |
+-------------+---------+
```
该表主键为 `fail_date` (具有唯一值的列)。
该表包含失败任务的天数。

表: `Succeeded`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| success_date | date    |
+--------------+---------+
```
该表主键为 `success_date` (具有唯一值的列)。
该表包含成功任务的天数。
系统每天运行一个任务。每个任务都独立于先前的任务。任务的状态可以是失败或是成功。

编写解决方案找出 `2019-01-01` 到 `2019-12-31` 期间任务连续同状态 `period_state` 的起止日期（`start_date` 和 `end_date`）。即如果任务失败了，就是失败状态的起止日期，如果任务成功了，就是成功状态的起止日期。
最后结果按照起始日期 `start_date` 排序
返回结果样例如下所示:

示例 1:

输入:
`Failed table`:
```
+------------+
| fail_date  |
+------------+
| 2018-12-28 |
| 2018-12-29 |
| 2019-01-04 |
| 2019-01-05 |
+------------+
```
`Succeeded table`:
```
+--------------+
| success_date |
+--------------+
| 2018-12-30   |
| 2018-12-31   |
| 2019-01-01   |
| 2019-01-02   |
| 2019-01-03   |
| 2019-01-06   |
+--------------+
```
输出:
```
+--------------+------------+------------+
| period_state | start_date | end_date   |
+--------------+------------+------------+
| succeeded    | 2019-01-01 | 2019-01-03 |
| failed       | 2019-01-04 | 2019-01-05 |
| succeeded    | 2019-01-06 | 2019-01-06 |
+--------------+------------+------------+
```
解释:
结果忽略了 2018 年的记录, 因为我们只关心从 2019-01-01 到 2019-12-31 的记录
从 2019-01-01 到 2019-01-03 所有任务成功, 系统状态为 "succeeded"。
从 2019-01-04 到 2019-01-05 所有任务失败, 系统状态为 "failed"。
从 2019-01-06 到 2019-01-06 所有任务成功, 系统状态为 "succeeded"。
*/

WITH
-- 1. 模拟 Failed 表
Failed AS (
    SELECT CAST('2018-12-28' AS DATE) AS fail_date UNION ALL
    SELECT CAST('2018-12-29' AS DATE) UNION ALL
    SELECT CAST('2019-01-04' AS DATE) UNION ALL
    SELECT CAST('2019-01-05' AS DATE)
),

-- 2. 模拟 Succeeded 表
Succeeded AS (
    SELECT CAST('2018-12-30' AS DATE) AS success_date UNION ALL
    SELECT CAST('2018-12-31' AS DATE) UNION ALL
    SELECT CAST('2019-01-01' AS DATE) UNION ALL
    SELECT CAST('2019-01-02' AS DATE) UNION ALL
    SELECT CAST('2019-01-03' AS DATE) UNION ALL
    SELECT CAST('2019-01-06' AS DATE)
),
    group_comming as (
        select work_date,
               flag,
               datediff,
               previous_flag,
               sum(
                       if((datediff is null or datediff = 1) and flag = previous_flag,0,1)
               ) over (order by work_date) group_flag
        from (select
                  work_date,
                  flag,
                  datediff(work_date,lag(work_date,1) over(order by work_date)) datediff,
                  lag(flag,1) over(order by work_date )previous_flag
              from (
                       select fail_date as work_date,'fail' as flag
                       from Failed t1
                       where fail_date between '2019-01-01' and '2019-12-31'
                       union all
                       select success_date ,'succeed'
                       from Succeeded t2
                       where success_date between '2019-01-01' and '2019-12-31'
                   ) t3)t4
    )
select
    flag,
    min(work_date) start_date,
    max(work_date) end_date
from group_comming t0
group by flag,group_flag

~~~

## 71 荐盆友喜欢但是你并没有喜欢的页面

~~~sql

/*
朋友关系列表: `Friendship`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| user1_id    | int     |
| user2_id    | int     |
+-------------+---------+
```
`(user1_id, user2_id)` 是这张表具有唯一值的列的组合。
这张表的每一行代表着 `user1_id` 和 `user2_id` 之间存在着朋友关系。

喜欢列表: `Likes`
```
+-------------+---------+
| 列名        | 类型    |
+-------------+---------+
| user_id     | int     |
| page_id     | int     |
+-------------+---------+
```
`(user_id, page_id)` 是这张表具有唯一值的列的组合。
这张表的每一行代表着 `user_id` 喜欢 `page_id`。

编写解决方案，向`user_id = 1`的用户，推荐其朋友们喜欢的页面。不要推荐该用户已经喜欢的页面。
以任意顺序 返回结果，其中不应当包含重复项。
返回结果的格式如下例所示。

示例 1:

输入:
`Friendship table`:
```
+----------+----------+
| user1_id | user2_id |
+----------+----------+
| 1        | 2        |
| 1        | 3        |
| 1        | 4        |
| 2        | 3        |
| 2        | 4        |
| 2        | 5        |
| 6        | 1        |
+----------+----------+
```
`Likes table`:
```
+---------+---------+
| user_id | page_id |
+---------+---------+
| 1       | 88      |
| 2       | 23      |
| 3       | 24      |
| 4       | 56      |
| 5       | 11      |
| 6       | 33      |
| 2       | 77      |
| 3       | 77      |
| 6       | 88      |
+---------+---------+
```
输出:
```
+------------------+
| recommended_page |
+------------------+
| 23               |
| 24               |
| 56               |
| 33               |
| 77               |
+------------------+
```
解释:
用户1 同 用户2, 3, 4, 6 是朋友关系。
推荐页面为： 页面23 来自于 用户2, 页面24 来自于 用户3, 页面56 来自于 用户4 以及 页面33 来自于 用户6。
页面77 同时被 用户2 和 用户3 推荐。
页面88 没有被推荐, 因为 用户1 已经喜欢了它。
*/

WITH
-- 1. 模拟 Friendship 表
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 1, 4 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 2, 5 UNION ALL
    SELECT 6, 1
),

-- 2. 模拟 Likes 表
Likes AS (
    SELECT 1 AS user_id, 88 AS page_id UNION ALL
    SELECT 2, 23 UNION ALL
    SELECT 3, 24 UNION ALL
    SELECT 4, 56 UNION ALL
    SELECT 5, 11 UNION ALL
    SELECT 6, 33 UNION ALL
    SELECT 2, 77 UNION ALL
    SELECT 3, 77 UNION ALL
    SELECT 6, 88
),
  page_like_situation as
  (
    SELECT
      t2.my_id,
      t3.page_id my_like_page,
      t2.friend_id,
      t4.page_id friend_like_page
    FROM
      (
        SELECT
          user1_id my_id,
          user2_id friend_id
        FROM
          Friendship t0
        UNION ALL
        SELECT
          user2_id,
          user1_id
        FROM
          Friendship t1
      ) t2
      LEFT JOIN Likes t3 ON t2.my_id = t3.user_id
      LEFT JOIN Likes t4 ON t2.friend_id = t4.user_id
  )
-- 方式1
/*
SELECT
    my_id,
    friend_like_page
FROM page_like_situation tt
WHERE tt.my_id = 1 AND tt.my_like_page != tt.friend_like_page
GROUP BY my_id, friend_like_page;
*/

-- 方式2 ,使用的spark sql 版本为3.3.1
select
    my_id,
    array_except(
            collect_set(friend_like_page),
            collect_set(my_like_page)
    ) as recommended_page

from page_like_situation t0
where my_id = 1
group by my_id

-- 方式3
/*
select
    t0.page_id as recommended_page
from Likes t0
-- 自己未关注的页面
where page_id not in (
    select
        t1.page_id
    from Likes t1
    where t1.user_id = 1
    )
  -- 朋友关注的页面
and t0.user_id in (
    select
        user2_id
    from Friendship t2
    where t2.user1_id = 1
    union
    select
        user1_id
    from Friendship t3
    where t3.user2_id = 1
    )
group by t0.page_id;
*/

-- 方式4 ，但数据基数（此处指系统中所有page_id去重后的数据量）达到 百万及以上级别， 可以考虑使用 bitmap实现


~~~

## 72 找出ceo的直接下属和下属的下属

~~~sql
/*
员工表: `Employees`
```
+----------------+---------+
| Column Name    | Type    |
+----------------+---------+
| employee_id    | int     |
| employee_name  | varchar |
| manager_id     | int     |
+----------------+---------+
```
`employee_id` 是这个表具有唯一值的列。
这个表中每一行中, `employee_id` 表示职工的 ID, `employee_name` 表示职工的名字, `manager_id` 表示该职工汇报工作的直属经理。
这个公司 CEO 是 `employee_id = 1` 的人。

编写解决方案，找出所有直接或间接向公司 CEO 汇报工作的职工的 `employee_id` 。
由于公司规模较小，经理之间的间接关系 不超过 `3` 个经理。
可以以 任何顺序 返回无重复项的结果。
返回结果示例如下。

示例 1:

输入:
`Employees table`:
```
+-------------+---------------+------------+
| employee_id | employee_name | manager_id |
+-------------+---------------+------------+
| 1           | Boss          | 1          |
| 3           | Alice         | 1          |
| 2           | Bob           | 1          |
| 4           | Daniel        | 2          |
| 7           | Luis          | 4          |
| 8           | Jhon          | 3          |
| 9           | Angela        | 8          |
| 77          | Robert        | 1          |
+-------------+---------------+------------+
```
输出:
```
+-------------+
| employee_id |
+-------------+
| 77           |
| 2          |
| 3           |
| 8           |
| 4           |
+-------------+
```
解释:
公司 CEO 的 `employee_id` 是 1。
*/

WITH
-- 1. 模拟 Employees 表
Employees AS (
    SELECT 1 AS employee_id, 'Boss' AS employee_name, 1 AS manager_id UNION ALL
    SELECT 3, 'Alice', 1 UNION ALL
    SELECT 2, 'Bob', 1 UNION ALL
    SELECT 4, 'Daniel', 2 UNION ALL
    SELECT 7, 'Luis', 4 UNION ALL
    SELECT 8, 'Jhon', 3 UNION ALL
    SELECT 9, 'Angela', 8 UNION ALL
    SELECT 77, 'Robert', 1
),
    -- 解法题目描述有出入
    ceo as (
        select
            employee_id,
            concat('/',employee_id) path
        from Employees
        where manager_id = employee_id
    ),
    level_1 as (
        select
            t2.employee_id,
            concat(t1.path,'/',t2.employee_id) path
        from ceo t1
        left join  Employees t2
        on t1.employee_id = t2.manager_id and t1.employee_id != t2.employee_id
    ),
    level_2 as (
        select
            t2.employee_id,
            concat(t1.path,'/',t2.employee_id) path
        from level_1 t1
        left join  Employees t2
        on t1.employee_id = t2.manager_id
        where t2.employee_id is not null
    ),
    level_3 as (
        select
            t2.employee_id,
            concat(t1.path,'/',t2.employee_id) path
        from level_2 t1
        left join  Employees t2
        on t1.employee_id = t2.manager_id
        where t2.employee_id is not null
    )
select
    employee_id
from (
         select * from ceo
         union all
         select * from level_1
         union all
         select * from level_2
         union all
         select * from level_3
     )
where size(split(path,'/')) > 2 and size(split(path,'/')) <= 4

~~~

## 73 餐馆七日均值

```sql

/*
表: `Customer`
```
+--------------+----------+
| Column Name  | Type     |
+--------------+----------+
| customer_id  | int      |
| name         | varchar  |
| visited_on   | date     |
| amount       | int      |
+--------------+----------+
```
在 SQL 中, `(customer_id, visited_on)` 是该表的主键。
该表包含一家餐馆的顾客交易数据。
`visited_on` 表示 `(customer_id)` 的顾客在 `visited_on` 那天访问了餐馆。
`amount` 是一个顾客某一天的消费总额。
你是餐馆的老板，现在你想分析一下可能的营业额变化增长（每天至少有一位顾客）。
计算以 `7` 天（某日期 + 该日期前的 6 天）为一个时间段的顾客消费平均值。`average_amount` 要 保留两位小数。
结果按 `visited_on` 升序排序。
返回结果格式的例子如下。

示例 1:

输入:
`Customer` 表:
```
+-------------+---------+------------+--------+
| customer_id | name    | visited_on | amount |
+-------------+---------+------------+--------+
| 1           | Jhon    | 2019-01-01 | 100    |
| 2           | Daniel  | 2019-01-02 | 110    |
| 3           | Jade    | 2019-01-03 | 120    |
| 4           | Khaled  | 2019-01-04 | 130    |
| 5           | Winston | 2019-01-05 | 110    |
| 6           | Elvis   | 2019-01-06 | 140    |
| 7           | Anna    | 2019-01-07 | 150    |
| 8           | Maria   | 2019-01-08 | 80     |
| 9           | Jaze    | 2019-01-09 | 110    |
| 1           | Jhon    | 2019-01-10 | 130    |
| 3           | Jade    | 2019-01-10 | 150    |
+-------------+---------+------------+--------+
```
输出:
```
+------------+--------+----------------+
| visited_on | amount | average_amount |
+------------+--------+----------------+
| 2019-01-07 | 860    | 122.86         |
| 2019-01-08 | 840    | 120            |
| 2019-01-09 | 840    | 120            |
| 2019-01-10 | 1000   | 142.86         |
+------------+--------+----------------+
```
解释:
第一个七天消费平均值从 2019-01-01 到 2019-01-07 是 (100 + 110 + 120 + 130 + 110 + 140 + 150)/7 = 122.86
第二个七天消费平均值从 2019-01-02 到 2019-01-08 是 (110 + 120 + 130 + 110 + 140 + 150 + 80)/7 = 120

*/
WITH
-- 1. 模拟 Customer 表
Customer AS (
    SELECT 1 AS customer_id, 'Jhon' AS name, CAST('2019-01-01' AS DATE) AS visited_on, 100 AS amount UNION ALL
    SELECT 2, 'Daniel', CAST('2019-01-02' AS DATE), 110 UNION ALL
    SELECT 3, 'Jade', CAST('2019-01-03' AS DATE), 120 UNION ALL
    SELECT 4, 'Khaled', CAST('2019-01-04' AS DATE), 130 UNION ALL
    SELECT 5, 'Winston', CAST('2019-01-05' AS DATE), 110 UNION ALL
    SELECT 6, 'Elvis', CAST('2019-01-06' AS DATE), 140 UNION ALL
    SELECT 7, 'Anna', CAST('2019-01-07' AS DATE), 150 UNION ALL
    SELECT 8, 'Maria', CAST('2019-01-08' AS DATE), 80 UNION ALL
    SELECT 9, 'Jaze', CAST('2019-01-09' AS DATE), 110 UNION ALL
    SELECT 1, 'Jhon', CAST('2019-01-10' AS DATE), 130 UNION ALL
    SELECT 3, 'Jade', CAST('2019-01-10' AS DATE), 150
)

-- 解法1 由于 每天至少有一位顾客
/*select visited_on,
       amount,
       round(average_amount,2) average_amount
from (
         select
             visited_on,
             sum(amount_date) over(order by visited_on rows between 6 preceding and current row )amount,
             avg(amount_date) over(order by visited_on rows between 6 preceding and current row )average_amount,
             row_number() over (order by visited_on) order_number
         from (
                  select
                      visited_on,
                      sum(amount) amount_date
                  from Customer t0
                  group by t0.visited_on

              ) t1
     ) t2
where order_number >= 7;*/


-- 解法2 针对如果存在该店不是每天都有顾客消费的情况，基于range between计算更加准确
/*
select visited_on,
       amount,
       round(average_amount,2) average_amount
from (
         select
             visited_on,
             sum(amount_date) over(order by visited_on range between 6 preceding and current row )amount,
             avg(amount_date) over(order by visited_on range between 6 preceding and current row )average_amount,
             row_number() over (order by visited_on) order_number
         from (
                  select
                      visited_on,
                      sum(amount) amount_date
                  from Customer t0
                  group by t0.visited_on

              ) t1
     ) t2
where order_number >= 7;
*/


-- 解法3 处理如果该店不是每天都有顾客消费，并且最近7日的消费需要考虑没有消费的日期，比如1号有消费，2号有消费，中间无顾客消费，直到8号才有新的消费。
,
    -- 步骤 1: 按天聚合，计算每日的总消费金额
    per_date_amount AS (
        SELECT
            visited_on,
            SUM(amount) AS date_amount
        FROM
            Customer AS t0
        GROUP BY
            t0.visited_on
    ),

    -- 步骤 2: 生成一个包含所有日期的完整日期维度表
    dim_date AS (
        SELECT
            date_add(t2.earliest_date, t3.index) AS date_value
        FROM (
            -- 找到数据中的最早和最晚日期
            SELECT
                MIN(visited_on) AS earliest_date,
                MAX(visited_on) AS lasted_date
            FROM
                per_date_amount AS t1
        ) AS t2
        -- 使用 LATERAL VIEW posexplode 技巧生成从最早到最晚的连续日期序列
        LATERAL VIEW posexplode(split(repeat(' ', datediff(t2.lasted_date, t2.earliest_date)), ' ')) t3 AS index, value
    )

-- 步骤 4: 最终查询和格式化输出
SELECT
    date_value,
    amount,
    ROUND(average_amount, 2) AS average_amount
FROM (
    -- 步骤 3: 计算7天的滑动窗口总和与平均值
    SELECT
        date_value,
        -- 计算从6天前到今天的总金额 (7天窗口)
        SUM(date_amount) OVER (ORDER BY date_valueROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS amount,
        -- 计算从6天前到今天的平均金额 (7天窗口)
        AVG(date_amount) OVER (ORDER BY date_valueROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS average_amount,
        -- 添加行号，用于过滤掉前面不足7天的数据
        ROW_NUMBER() OVER (ORDER BY date_value) AS order_number
    FROM (
        -- 将完整日期表与每日金额表左连接，确保没有消费的日期金额为0
        SELECT
            t0.date_value,
            NVL(t1.date_amount, 0) AS date_amount
        FROM
            dim_date AS t0
        LEFT JOIN
            per_date_amount AS t1 ON t0.date_value = t1.visited_on
    ) AS t2
)
-- 过滤掉前6天，因为它们的7日滑动窗口数据不完整
WHERE
    order_number >= 7;



```

## 74 大表 join 小表在spark sql的执行计划

```sql

/*
有如下hive表结构：
A表 a1、a2、a3、a4有4个字段

B表 b1、b2 b3 b4 有3个字段

C表c1 c2 c3 c4 有4个字段

A表a1是关联B表b1主键，a2是关联C表c1主键，查询A表不在B表和C表里面的数据

其中A表千万级 B表C表千级

考虑效率，写出 spark sql
*/

-- 由于spark 3.0以上版本存在AQE，在执行计划阶段，有规划阶段（initial plan），和最终执行阶段（final plan），Spark 会在运行时根据实际的数据统计信息动态调整Join 策略，
-- 比如spark join首选 sort merge join，在AQE后，发现小表的数据量小于设置的 spark.sql.autoBroadcastJoinThreshold 阈值，那么 会转化为broadcast hash join执行
-- spark 3.0后，自动有这个优化，一般不需要特定的参数优化
-- 具体说明文档可参考博客：https://5201969.xyz/post/-1122271105#spark%E7%9A%84join%E9%80%89%E6%8B%A9%E7%AD%96%E7%95%A5

-- explain
WITH

A (a1, a2, a3, a4) AS (
    SELECT * FROM (VALUES
                       (101, 201, 'Data-AAA', 'Info-01'),
                       (102, 999, 'Data-BBB', 'Info-02'),
                       (998, 202, 'Data-CCC', 'Info-03'),
                       (999, 999, 'Data-DDD', 'Info-04'),
                       (103, 203, 'Data-EEE', 'Info-05'),
                       (888, 888, 'Data-FFF', 'Info-06')
                  ) AS t (a1, a2, a3, a4)
),


B (b1, b2, b3) AS (
    SELECT * FROM (VALUES
                       (101, 'B-Info-1', 'Desc-1'),
                       (102, 'B-Info-2', 'Desc-2'),
                       (103, 'B-Info-3', 'Desc-3'),
                       (104, 'B-Info-4', 'Desc-4')
                  ) AS t (b1, b2, b3)
),


C (c1, c2, c3, c4) AS (
    SELECT * FROM (VALUES
                       (201, 'C-Info-A', 'Detail-A', 100),
                       (202, 'C-Info-B', 'Detail-B', 200),
                       (203, 'C-Info-C', 'Detail-C', 300)
                  ) AS t (c1, c2, c3, c4)
)
-- select
--     t1.*
-- FROM A t1
-- left join B t2 on t1.a1 = t2.b1
-- left join C t3 on t1.a1 = t3.c1
-- where t2.b1 is null and t3.c1 is null;

-- map join 加上 先过滤，后输出
SELECT /*+ MAPJOIN(B, C) */
    A.a1,
    A.a2,
    A.a3,
    A.a4
FROM
    A
        LEFT ANTI JOIN B ON A.a1 = B.b1
        LEFT ANTI JOIN C ON A.a2 = C.c1;
```

---

# 2026 年



##  75 公交车上的乘客数量

```hivesql
/*
====================================================================
题目：公交车上的乘客数量 (The Number of Passengers in Each Bus)
====================================================================

表：Buses
+--------------+------+
| Column Name  | Type |
+--------------+------+
| bus_id       | int  |
| arrival_time | int  |
| capacity     | int  |
+--------------+------+
bus_id 包含唯一的值。
该表的每一行都包含关于公交车到达车站的时间和它的容量（空座位的数量）的信息。
不会出现两辆公交车同时到达，所有公交车的容量都是正整数。

表：Passengers
+--------------+------+
| Column Name  | Type |
+--------------+------+
| passenger_id | int  |
| arrival_time | int  |
+--------------+------+
passenger_id 包含唯一的值。
该表的每一行都包含乘客到达车站的时间信息。

公交车和乘客到达车站。如果一辆公交车在 tbus 时间点到达车站，乘客在 tpassenger 到达车站，
其中 tpassenger <= tbus，而该乘客没有赶上任何公交车，则该乘客将搭乘该公交车。
此外，每辆公交车都有一个容量。如果在公交车到站的那一刻，等待的乘客超过了它的载客量 capacity，
只有 capacity 个乘客才会搭乘该公交车（先到先得/按等待队列）。

编写解决方案，报告搭乘每辆公交车的乘客数量。
返回按 bus_id 升序排序的结果表。

示例 1：

输入：
Buses 表：
+--------+--------------+----------+
| bus_id | arrival_time | capacity |
+--------+--------------+----------+
| 1      | 2            | 1        |
| 2      | 4            | 10       |
| 3      | 7            | 2        |
+--------+--------------+----------+

Passengers 表：
+--------------+--------------+
| passenger_id | arrival_time |
+--------------+--------------+
| 11           | 1            |
| 12           | 1            |
| 13           | 5            |
| 14           | 6            |
| 15           | 7            |
+--------------+--------------+

输出：
+--------+----------------+
| bus_id | passengers_cnt |
+--------+----------------+
| 1      | 1              |
| 2      | 1              |
| 3      | 2              |
+--------+----------------+

解释：
- 11 号乘客在时间 1 到达。
- 12 号乘客在时间 1 到达。
- 1 号公交车到达时间为 2，因为有一个空座位，所以搭载了 11 号乘客。
- 2 号公交车在时间 4 到达，搭载了 12 号乘客，因为它有 10 个空座位。
- 13 号乘客在时间 5 到达。
- 14 号乘客在时间 6 到达。
- 15 号乘客在时间 7 到达。
- 3 号公交车在时间 7 到达，车上有两个空座位，搭载了 13 号和 14 号乘客。
*/

WITH Buses AS (
    SELECT 1 AS bus_id, 2 AS arrival_time, 1 AS capacity UNION ALL
    SELECT 2 AS bus_id, 4 AS arrival_time, 10 AS capacity UNION ALL
    SELECT 3 AS bus_id, 7 AS arrival_time, 2 AS capacity
),
     Passengers AS (
         SELECT 11 AS passenger_id, 1 AS arrival_time UNION ALL
         SELECT 12 AS passenger_id, 1 AS arrival_time UNION ALL
         SELECT 13 AS passenger_id, 5 AS arrival_time UNION ALL
         SELECT 14 AS passenger_id, 6 AS arrival_time UNION ALL
         SELECT 15 AS passenger_id, 7 AS arrival_time
     )
-- ==========================================
-- 请在此处往下编写你的 Hive SQL 解答
-- 提示：此题在不使用存储过程/循环的情况下，
-- 非常考验对开窗函数（Window Functions）的综合运用
-- ==========================================
/*
思路：每个乘客上来那辆bus，匹配不上，赶不上车；匹配多个bus，取最近乘客到达时间的那个; 最后还需要根据bus的空余容量做筛选。
*/

, choice_bus as (
    select
        t1.passenger_id,
        t2.bus_id,
        t2.capacity,
        t1.arrival_time,
        t2.arrival_time,
        row_number() over (partition by t1.passenger_id order by t2.arrival_time - t1.arrival_time asc) as candidate_order_number
    from Passengers t1
    left join Buses t2
    on t1.arrival_time <= t2.arrival_time
    where t2.bus_id is not null
)
select
    t5.bus_id,
    if(capacity >= passengers_cnt, passengers_cnt, capacity) passengers_cnt
from (
         select
             t3.bus_id,
             t3.capacity,
             count(1) passengers_cnt
         from Buses t3
                  left join choice_bus t4
                            on t3.bus_id = t4.bus_id and t4.candidate_order_number = 1
         group by t3.bus_id,t3.capacity
     ) t5
order by passengers_cnt;


    // 以下为错误思路实现，会导致遗漏乘客
/*, choice_bus as (
    select
        t1.passenger_id,
        t2.bus_id,
        t2.capacity,
        t1.arrival_time,
        t2.arrival_time,
        row_number() over (partition by t1.passenger_id order by t2.arrival_time - t1.arrival_time asc) as candidate_order_number
    from Passengers t1
             left join Buses t2
                       on t1.arrival_time <= t2.arrival_time
    where t2.bus_id is not null
)
select
    bus_id,
    count(passenger_id) passengers_cnt
from (
         select
             bus_id,
             capacity,
             passenger_id,
             count(1) over (partition by bus_id order by passenger_id) accuate_passgener_numbers
         from choice_bus t3
         where t3.candidate_order_number = 1
     ) t4
where capacity >= accuate_passgener_numbers
group by bus_id
order by passengers_cnt;*/

```

![image-20260319141356081](https://5201969.xyz/api/public/img/d450bb876bcccdc41c6926a312e85c1b)



## 76 重新排列性别表

```hivesql
/*
====================================================================
题目：重新排列性别表 (Reformat Genders Table)
====================================================================

表：Genders
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| user_id     | int     |
| gender      | varchar |
+-------------+---------+
user_id 是该表的主键(具有唯一值的列)。
gender 的值是 'female', 'male', 'other' 之一。
该表中的每一行都包含用户的 ID 及其性别。
表格中 'female', 'male', 'other' 数量相等。

编写一个解决方案以重新排列 Genders 表，使行按顺序在 'female', 'other' 和 'male' 之间交替。
同时每种性别按照 user_id 升序进行排序。

按上述顺序返回结果表。

示例 1：

输入：
Genders 表：
+---------+--------+
| user_id | gender |
+---------+--------+
| 4       | male   |
| 7       | female |
| 2       | other  |
| 5       | male   |
| 1       | other  |
| 9       | female |
| 3       | female |
| 6       | other  |
| 8       | male   |
+---------+--------+

输出：
+---------+--------+
| user_id | gender |
+---------+--------+
| 3       | female |
| 1       | other  |
| 4       | male   |
| 7       | female |
| 2       | other  |
| 5       | male   |
| 9       | female |
| 6       | other  |
| 8       | male   |
+---------+--------+

解释：
女性: ID 3、7、9。
其他性别: ID 1、2、6。
男性: ID 4、5、8。
我们在 'female', 'other', 'male' 之间交替排列表。
注意，每种性别都是按 user_id 升序排序的。
*/

WITH Genders AS (
    SELECT 4 AS user_id, 'male' AS gender UNION ALL
    SELECT 7 AS user_id, 'female' AS gender UNION ALL
    SELECT 2 AS user_id, 'other' AS gender UNION ALL
    SELECT 5 AS user_id, 'male' AS gender UNION ALL
    SELECT 1 AS user_id, 'other' AS gender UNION ALL
    SELECT 9 AS user_id, 'female' AS gender UNION ALL
    SELECT 3 AS user_id, 'female' AS gender UNION ALL
    SELECT 6 AS user_id, 'other' AS gender UNION ALL
    SELECT 8 AS user_id, 'male' AS gender
)
-- ==========================================
-- 请在此处往下编写你的 Hive SQL 解答
-- ==========================================
, t1 as (
    select user_id,
           gender,
           row_number() over (order by gender_group_number,
               case gender
                    when 'female' then 1
                    when 'other' then 2
               else 3 end ) final_number
    from (
             select
                 user_id,
                 gender,
                 row_number() over (partition by gender order by user_id) gender_group_number
             from Genders
         )
)
select user_id,
       gender
from t1;
```

![image-20260320120613658](https://5201969.xyz/api/public/img/711814f1c9e874b82ea28b40c04fe124)



##　77 统计每个工资类别的银行账户数量

![image-20260405130141129](https://5201969.xyz/api/public/img/e17be60f414c70278b6e3dbe35d75bd5)

```sparksql

/*
题目名称：统计每个工资类别的银行账户数量

表名：Accounts

表结构：
1. account_id INT    账户ID，主键
2. income     INT    月收入

题目要求：
1. 统计每个工资类别的银行账户数量。
2. 工资类别定义如下：
   - Low Salary：所有工资严格低于 20000
   - Average Salary：工资范围在 [20000, 50000]
   - High Salary：所有工资严格大于 50000
3. 结果必须包含以下三个类别：
   - Low Salary
   - Average Salary
   - High Salary
4. 如果某个类别没有账户，则该类别的 accounts_count 返回 0。
5. 结果按任意顺序返回即可。

示例数据说明：
Accounts 表数据如下：
+------------+--------+
| account_id | income |
+------------+--------+
| 3          | 108939 |
| 2          | 12747  |
| 8          | 87709  |
| 6          | 91796  |
+------------+--------+

期望结果：
+----------------+----------------+
| category       | accounts_count |
+----------------+----------------+
| Low Salary     | 1              |
| Average Salary | 0              |
| High Salary    | 3              |
+----------------+----------------+
*/

WITH Accounts AS (
    SELECT 3 AS account_id, 108939 AS income
    UNION ALL
    SELECT 2 AS account_id, 12747 AS income
    UNION ALL
    SELECT 8 AS account_id, 87709 AS income
    UNION ALL
    SELECT 6 AS account_id, 91796 AS income
)

-- 请在这里继续编写你的解答
-- 解法一
/*
,
    actually_group as (
    SELECT
        case
            when income < 20000 then 'Low Salary'
            when income > 50000 then 'High Salary'
            else 'Average Salary' end as category,
        count(account_id) accounts_count
    FROM Accounts
    group by case
                 when income < 20000 then 'Low Salary'
                 when income > 50000 then 'High Salary'
                 else 'Average Salary' end
)
select
    dim_category.category,
    nvl(actually_group.accounts_count,0) accounts_count
    from (select  explode(split('Low Salary,Average Salary,High Salary',','))  category) dim_category
left join  actually_group
on dim_category.category = actually_group.category*/

-- 解法二

/*select
    category,
    case category
        when 'Low Salary' then low_count
        when 'Average Salary' then middle_count
    else high_count end as accounts_count
from (
         select
             sum(case when income < 20000 then 1 else 0 end ) low_count,
             sum(case when income >= 20000 and income <= 50000 then 1 else 0 end ) middle_count,
             sum(case when income > 50000 then 1 else 0 end ) high_count
         from Accounts t1
     ) t2
lateral view explode(split('Low Salary,Average Salary,High Salary',',')) dim_category as category*/


-- 解法三

select
    dim_category.category,
    count(t1.account_id) accounts_count
from (select  explode(split('Low Salary,Average Salary,High Salary',','))  category) dim_category
left join Accounts t1
on (dim_category.category = 'Low Salary' and t1.income < 20000)
or (dim_category.category = 'Average Salary' and t1.income >= 20000 and t1.income <= 50000)
or (dim_category.category = 'High Salary' and t1.income > 50000)
group by dim_category.category
```



## 78 页面平均访问时长

![image-20260408120931343](https://5201969.xyz/api/public/img/eabe7bdf60d474e046a0f21f8489bf45)

```sparksql
/*
题目要求：
现有用户行为表 user_log_5，字段如下：
1. uid：用户 id
2. actions：用户行为日志，内容为 json 数组字符串

actions 示例：
[
  {"url":"url01","time":"2025-01-01 10:00:00"},
  {"url":"url02","time":"2025-01-01 10:01:10"},
  {"url":"url03","time":"2025-01-01 10:01:20"},
  {"url":"url02","time":"2025-01-01 10:02:00"}
]

统计要求：
1. 将 actions 中的每个访问行为展开为明细数据，得到 uid、url、time。
2. 对每个用户的访问记录按照时间升序排序。
3. 对于当前页面，其访问结束时间定义为该用户下一次访问行为的 time。
4. 计算每个用户在每个页面上的访问时长，单位为秒。
5. 统计每个用户在每个页面上的平均访问时长。
6. 由于最后一次访问行为没有下一条记录，无法确定结束时间，因此不参与平均访问时长计算。
*/




WITH user_log_5 AS (
    SELECT * FROM VALUES
                      (
                          'u001',
                          '[{"url":"url01","time":"2025-01-01 10:00:00"},{"url":"url02","time":"2025-01-01 10:01:10"},{"url":"url03","time":"2025-01-01 10:01:20"},{"url":"url02","time":"2025-01-01 10:02:00"},{"url":"url04","time":"2025-01-01 10:05:00"}]'
                      ),
                      (
                          'u002',
                          '[{"url":"url01","time":"2025-01-01 11:00:00"},{"url":"url02","time":"2025-01-01 11:03:00"},{"url":"url01","time":"2025-01-01 11:05:30"},{"url":"url03","time":"2025-01-01 11:06:00"},{"url":"url02","time":"2025-01-01 11:10:00"}]'
                      ),
                      (
                          'u003',
                          '[{"url":"url05","time":"2025-01-01 09:00:00"},{"url":"url05","time":"2025-01-01 09:02:00"},{"url":"url06","time":"2025-01-01 09:05:00"}]'
                      )
                      AS t(uid, actions)
),
    detail as (
        select
            uid,
            url,
            final_view_time as enter_view_time,
            -- 最后一次浏览不计入结果
            lead(final_view_time, 1) over (partition by uid order by final_view_time asc) left_view_time
        from (
                 select
                     t1.uid,
                     t2.item.url,
                     max(to_unix_timestamp(t2.item.time, 'yyyy-MM-dd HH:mm:ss')) final_view_time
                 from user_log_5 t1
                          lateral view explode (from_json(actions,'ARRAY<STRUCT<url:STRING, time:STRING>>')) t2 as item
                 group by t1.uid, t2.item.url
             ) t3
    )
select
    uid,
    url,
    left_view_time - enter_view_time wait_time,
    avg(left_view_time - enter_view_time) over(partition by  uid) avg_wait_time
from detail;

```



## 79 坚定的友谊

```sparksql
/*
题目名称：坚定的友谊

表名：Friendship

字段说明：
- user1_id INT
- user2_id INT

约束说明：
- (user1_id, user2_id) 是主键
- 每一行表示用户 user1_id 和 user2_id 是朋友关系
- 并且满足 user1_id < user2_id

题目要求：
如果 x 和 y 为朋友，并且他们至少有 3 个共同的朋友，
那么 x 和 y 之间的友谊就是“坚定的友谊”。

请写出 SQL，找出所有“坚定的友谊”。

结果要求：
- 返回字段：
    1) user1_id
    2) user2_id
    3) common_friend  -- 共同朋友数量
- 结果中不能包含重复行
- 结果需满足 user1_id < user2_id
- 返回顺序任意

示例说明：
当前测试数据下：
- 用户 1 和 2 有 4 个共同朋友：3、4、5、6
- 用户 1 和 3 有 3 个共同朋友：2、6、7
- 用户 2 和 3 只有 2 个共同朋友：1、6，因此不满足条件
*/
use mydb;
WITH Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id
    UNION ALL
    SELECT 1 AS user1_id, 3 AS user2_id
    UNION ALL
    SELECT 2 AS user1_id, 3 AS user2_id
    UNION ALL
    SELECT 1 AS user1_id, 4 AS user2_id
    UNION ALL
    SELECT 2 AS user1_id, 4 AS user2_id
    UNION ALL
    SELECT 1 AS user1_id, 5 AS user2_id
    UNION ALL
    SELECT 2 AS user1_id, 5 AS user2_id
    UNION ALL
    SELECT 1 AS user1_id, 7 AS user2_id
    UNION ALL
    SELECT 3 AS user1_id, 7 AS user2_id
    UNION ALL
    SELECT 1 AS user1_id, 6 AS user2_id
    UNION ALL
    SELECT 3 AS user1_id, 6 AS user2_id
    UNION ALL
    SELECT 2 AS user1_id, 6 AS user2_id
)

/*
思路1： 分别求user1_id 和 user2_id的朋友集合，然后再求交集
*/

/*,friend_ralationships as(
    select
        user1_id as user_id,
        collect_set(user2_id) friends
    from (
             select user1_id,
                    user2_id
             from Friendship
             union  all
             select user2_id,
                    user1_id
             from Friendship
         ) t1
    group by user1_id
)
select t2.user1_id,
       t2.user2_id,
       size(array_intersect(t3.friends,t4.friends)) common_friend
from Friendship t2
left join friend_ralationships t3
on t2.user1_id = t3.user_id
left join  friend_ralationships t4
on t2.user2_id = t4.user_id
where size(array_intersect(t3.friends,t4.friends)) >=3;*/

/*
思路二：不使用交集函数，使用join + 分组聚合实现
*/

/*
, all_relationships as (
    select user1_id as me,
           user2_id as friend
    from Friendship
    union  all
    select user2_id,
           user1_id
    from Friendship
)
select
    t1.user1_id,
    t1.user2_id,
    count(distinct t2.friend) common_friend
from Friendship t1
left join all_relationships t2
on t1.user1_id = t2.me
left join all_relationships t3
on t1.user2_id = t3.me
where t2.friend = t3.friend
group by t1.user1_id,
         t1.user2_id
having count(distinct t2.friend) >=3;
*/

-- 思路三： 以共同好友为中心，反推用户对
    -- 如果某个人 c 是很多人的朋友，那么这些人两两组合，都可以形成一个“共享共同好友 c 的用户对”

   , all_relationships as (
    select user1_id as me,
           user2_id as friend
    from Friendship
    union  all
    select user2_id,
           user1_id
    from Friendship
),
    -- 有共同好友的用户对
     pair_by_common_friend as (
         select
             least(t1.me,t2.me) as user1_id,
             greatest(t1.me,t2.me) as user2_id,
             t1.friend as common_friend_id
         from all_relationships t1
                  inner join all_relationships t2
                  on t1.friend = t2.friend
                     and t1.me < t2.me -- 避免同一条记录重复统计
     ),
    -- 符合至少三个共同好友的用户对
    full_conditon_pair as (
        select
            user1_id,
            user2_id,
            count(common_friend_id) common_friend
        from pair_by_common_friend
        group by user1_id, user2_id
        having count(common_friend_id) >=3
    )
-- 内连接
select
    t1.user1_id,
    t1.user2_id,
    t2.common_friend
from Friendship t1
inner join full_conditon_pair t2
on t1.user1_id = t2.user1_id
and t1.user2_id = t2.user2_id;
```



## 80 共同关注者

```sparksql
/*
题目：共同关注者

表: Relations
+-------------+------+
| Column Name | Type |
+-------------+------+
| user_id     | int  |
| follower_id | int  |
+-------------+------+
(user_id, follower_id) 是这个表的主键。
这个表的每一行，表示这个user_id的用户和他的关注者，关注者的id就是本表的user_id。

要求：
写出一个查询语句，找到具有最多共同关注者的所有两两结对组。
换句话说，如果有两个用户的共同关注者是最大的，我们应该返回所有具有此最大值的两两结对组。

结果返回表，每一行应该包含user1_id和user2_id，其中user1_id < user2_id。
返回结果不要求顺序。

示例输入:
Relations 表:
+---------+-------------+
| user_id | follower_id |
+---------+-------------+
| 1       | 3           |
| 2       | 3           |
| 7       | 3           |
| 1       | 4           |
| 2       | 4           |
| 7       | 4           |
| 1       | 5           |
| 2       | 6           |
| 7       | 5           |
+---------+-------------+

示例输出:
+----------+----------+
| user1_id | user2_id |
+----------+----------+
| 1        | 7        |
+----------+----------+

解释：
用户1和用户2有2个共同的关注者（3和4）。
用户1和用户7有3个共同的关注者（3、4和5）。
用户2和用户7有2个共同的关注者（3和4）。
最大共同关注者数值是3，所以返回拥有3个共同关注者的两两组队(1, 7)。
返回(1, 7)而不是(7, 1)。
注意：用户3、4、5没有任何关注者信息，认为他们有0个关注者。
*/
use mydb;
WITH Relations AS (
    SELECT 1 AS user_id, 3 AS follower_id
    UNION ALL SELECT 2, 3
    UNION ALL SELECT 7, 3
    UNION ALL SELECT 1, 4
    UNION ALL SELECT 2, 4
    UNION ALL SELECT 7, 4
    UNION ALL SELECT 1, 5
    UNION ALL SELECT 2, 6
    UNION ALL SELECT 7, 5
)
/*,

-- 思路一：利用集合array_intersect计算交集

    follower_list as (
        select
            user_id,
            collect_set(follower_id) followers
        from Relations
        group by user_id
    )

select
    me user1_id,
    you user2_id
from (
         select
             t1.user_id me,
             t2.user_id you,
             dense_rank() over ( order by size(array_intersect(t1.followers, t2.followers)) desc ) dense_rank_number
         from follower_list t1
                  inner join follower_list t2
                             on size(array_intersect(t1.followers, t2.followers)) > 0 and t1.user_id < t2.user_id
     )
where dense_rank_number = 1;*/

-- 思路二：不依靠集合函数
/*select user1_id,
       user2_id
from (
         select
             t1.user_id as user1_id,
             t2.user_id as user2_id,
             dense_rank() over (order by count(distinct t1.follower_id) desc) common_follow_rn
         from Relations t1
                  inner join Relations t2
                             on t1.user_id < t2.user_id  and t1.follower_id = t2.follower_id
         group by t1.user_id, t2.user_id
     )t3
where common_follow_rn = 1;*/

-- 思路三： 从粉丝关注者的角度聚合存在共同粉丝的用户集合；对每个粉丝关注者角度穷举所有两两匹配的用户对情况；最后计算每个用户对的共同粉丝数量

,follower_groups as (
    select
        follower_id,
        collect_set(t1.user_id) users
    from Relations t1
    group by follower_id
    )
, pair as (
    select
        t1.follower_id,
        t2.user1_id,
        t3.user2_id
    from follower_groups t1
             lateral view explode(t1.users) t2 as user1_id
             lateral view explode(t1.users) t3 as user2_id
    where t2.user1_id < t3.user2_id
)
select
    user1_id,
    user2_id
from (
         select user1_id,
                user2_id,
                common_follower_num,
                dense_rank() over (order by common_follower_num desc) top_num
         from (
                  select
                      user1_id,
                      user2_id,
                      count(distinct follower_id) common_follower_num
                  from pair
                  group by user1_id,user2_id
              ) tt
     )
where top_num = 1;
```
