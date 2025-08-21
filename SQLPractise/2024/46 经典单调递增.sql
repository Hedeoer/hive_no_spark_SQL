/*
 题目36 经典单调递增

 SQL

表: Orders

| Column Name | Type |
|------------|------|
| order_id | int |
| customer_id | int |
| order_date | date |
| price | int |

order_id 是该表的主键。
每行包含订单的 id, 订购订单的客户 id, 订单日期和价格。

编写一个 SQL 查询, 根据 总购买量 每年严格递增的客户 id。
即, 客户在附近 总购买量 是按照订单价格的总和, 如果某一年客户严没有下任何订单, 我们认为总购买量为 0。
对于每个客户, 要考虑的第一个年是他们 第一次下单 的年份。
对于每个客户, 要考虑的最后一个年是他们 最后一次下单 的年份。

以 任意顺序 返回结果表。

示例 1:

输入:
Orders 表:
| order_id | customer_id | order_date | price |
|---------|------------|-----------|-------|
| 1 | 1 | 2019-07-01 | 1100 |
| 2 | 1 | 2019-11-01 | 1200 |
| 3 | 1 | 2020-05-26 | 3000 |
| 4 | 1 | 2021-08-31 | 3100 |
| 5 | 1 | 2022-12-07 | 4700 |
| 6 | 2 | 2015-01-01 | 700 |
| 7 | 2 | 2017-11-07 | 1000 |
| 8 | 3 | 2017-01-01 | 900 |
| 9 | 3 | 2018-11-07 | 900 |

输出:
| customer_id |
|------------|
| 1 |

解释:
客户 1: 第一年是 2019 年, 最后一年是 2022 年
- 2019: 1100 + 1200 = 2300
- 2020: 3000
- 2021: 3100
- 2022: 4700
我们可以看到总购买量每年都在严格递增, 所以现在在答案中包含了客户 1.

客户 2: 第一年是2015年, 最后一年是2017年
- 2015: 700
- 2016: 0
- 2017: 1000
我们没有将客户 2 包括在答案中, 因为他的购买量并没有严格地增加, 请注意, 客户 2 在 2016 年没有购买任何物品。

客户 3: 第一年是 2017 年, 最后一年是 2018 年
- 2017: 900
- 2018: 900

```sql
select customer_id
from
(select customer_id,year,yearp,
year-rank() over(partition by customer_id order by year)) as dif
from
(select customer_id,year(order_date) as year,
sum(price) as yearp

from orders
group by customer_id,year(order_date)
) t1) t1
group by customer_id
having count(distinct dif)=1
```


*/

WITH orders_data AS (
    SELECT 1 as order_id, 1 as customer_id, '2019-07-01' as order_date, 1100 as price UNION ALL
    SELECT 2, 1, '2019-11-01', 1200 UNION ALL
    SELECT 3, 1, '2020-05-26', 3000 UNION ALL
    SELECT 4, 1, '2021-08-31', 3100 UNION ALL
    SELECT 5, 1, '2022-12-07', 4700 UNION ALL
    SELECT 6, 2, '2015-01-01', 700 UNION ALL
    SELECT 7, 2, '2017-11-07', 1000 UNION ALL
    SELECT 8, 3, '2017-01-01', 900 UNION ALL
    SELECT 9, 3, '2018-11-07', 900
),
    year_ana as (
        select
               customer_id,
               order_year,
               year_amount,
               lead(order_year) over (partition by customer_id order by order_year) next_year,
               lead(year_amount) over (partition by customer_id order by order_year) next_year_amount
        from (
                select
                     customer_id, year(date_format(order_date,'yyyy-mm-dd')) order_year,
                     sum(coalesce(price,0)) year_amount
                from orders_data t1
                group by customer_id, year(date_format(order_date,'yyyy-mm-dd'))
             ) t1

    )
select
    distinct customer_id
from (
    select
        customer_id,
        sum(case
            when next_year is null then 0
            when next_year is not null and next_year_amount > year_amount and next_year = order_year + 1 then 0
            else 1 end  )
        over (partition by customer_id order by order_year) grouping_id
    from year_ana
     ) t2
where grouping_id = 0;


