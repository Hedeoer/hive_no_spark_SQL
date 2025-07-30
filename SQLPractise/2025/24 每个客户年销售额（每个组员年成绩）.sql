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
