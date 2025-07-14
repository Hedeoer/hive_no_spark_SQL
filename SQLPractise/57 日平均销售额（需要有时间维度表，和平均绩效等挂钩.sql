/*
Product 表:
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| product_id    | int     |
| product_name  | varchar |
+---------------+---------+
```
product_id 是这张表的主键(具有唯一值的列)。
product_name 是产品的名称。

Sales 表:
```
+---------------------+---------+
| Column Name         | Type    |
+---------------------+---------+
| product_id          | int     |
| period_start        | date    |
| period_end          | date    |
| average_daily_sales | int     |
+---------------------+---------+
```
product_id 是这张表的主键(具有唯一值的列)。
period_start 和 period_end 是该产品销售期的起始日期和结束日期, 且这两个日期包含在销售期内。
average_daily_sales 列存储销售期内该产品的日平均销售额。
销售日期范围为2018年到2020年。

编写解决方案, 找出每个产品每年的总销售额, 并包含 `product_id`, `product_name`, `report_year` 以及 `total_amount`。
返回结果并按 `product_id` 和 `report_year` 排序。
返回结果格式如下例所示。

示例 1:

输入:
`Product table`:
```
+------------+---------------+
| product_id | product_name  |
+------------+---------------+
| 1          | LC Phone      |
| 2          | LC T-Shirt    |
| 3          | LC Keychain   |
+------------+---------------+
```
`Sales table`:
```
+------------+--------------+-------------+---------------------+
| product_id | period_start | period_end  | average_daily_sales |
+------------+--------------+-------------+---------------------+
| 1          | 2019-01-25   | 2019-02-28  | 100                 |
| 2          | 2018-12-01   | 2020-01-01  | 10                  |
| 3          | 2019-12-01   | 2020-01-31  | 1                   |
+------------+--------------+-------------+---------------------+
```
输出:
```
+------------+---------------+--------------+--------------+
| product_id | product_name  | report_year  | total_amount |
+------------+---------------+--------------+--------------+
| 1          | LC Phone      | 2019         | 3500         |
| 2          | LC T-Shirt    | 2018         | 310          |
| 2          | LC T-Shirt    | 2019         | 3650         |
| 2          | LC T-Shirt    | 2020         | 10           |
| 3          | LC Keychain   | 2019         | 31           |
| 3          | LC Keychain   | 2020         | 31           |
+------------+---------------+--------------+--------------+
```
解释:
LC Phone 在 2019-01-25 至 2019-02-28 期间销售, 该产品销售时间总计35天。销售总额 35*100 = 3500。
LC T-shirt 在 2018-12-01 至 2020-01-01 期间销售, 该产品在2018年、2019年、2020年的销售时间分别是31天、365天、1天, 2018年、2019年、2020年的销售总额分别是31*10=310、365*10=3650、1*10=10。
LC Keychain 在 2019-12-01 至 2020-01-31 期间销售, 该产品在2019年、2020年的销售时间分别是: 31天, 31天, 2019年、2020年的销售总额分别是31*1=31、31*1=31。

*/

WITH
-- 1. 模拟 Product 表
Product AS (
    SELECT 1 AS product_id, 'LC Phone' AS product_name UNION ALL
    SELECT 2, 'LC T-Shirt' UNION ALL
    SELECT 3, 'LC Keychain'
),

-- 2. 模拟 Sales 表
Sales AS (
    SELECT 1 AS product_id, CAST('2019-01-25' AS DATE) AS period_start, CAST('2019-02-28' AS DATE) AS period_end, 100 AS average_daily_sales UNION ALL
    SELECT 2, CAST('2018-12-01' AS DATE), CAST('2020-01-01' AS DATE), 10 UNION ALL
    SELECT 3, CAST('2019-12-01' AS DATE), CAST('2020-01-31' AS DATE), 1
),
year_salses AS (
    --计算每年销售总额
select
    t3.product_id,
    t3.report_year,
    CASE
        -- 如果报告年份小于销售期开始年份, 则总额为0
        WHEN report_year < year(period_start) THEN 0
        -- 如果报告年份大于销售期结束年份, 则总额为0
        when report_year > year(period_end) then 0
        -- 计算销售天数 *　平均日销售额
        ELSE (datediff(if(t3.report_year_end >= t3.period_end, t3.period_end,t3.report_year_end),
                       if(t3.report_year_start <= t3.period_start,  t3.period_start,t3.report_year_start)) + 1)
        END * t3.average_daily_sales as year_total_amount
from (
         -- 构建2018, 2019, 2020 年的销售数据
         select
             t1.product_id,
             t1.period_start,
             t1.period_end,
             t1.average_daily_sales,
             t2.year report_year,
             to_date(concat(t2.year, '-01-01')) as report_year_start,
             last_day(to_date(concat(t2.year, '-12-01'))) as report_year_end
         from Sales t1
              -- 使用 lateral view posexplode 生成每年的销售数据，已知只有2018, 2019, 2020 三年数据
             lateral view posexplode(array('2018', '2019', '2020')) t2 as pos, year
     ) t3
    )
select
    t1.product_id,
    t2.product_name,
    t1.report_year,
    t1.year_total_amount total_amount
from year_salses t1
         left join Product t2
                   on t1.product_id = t2.product_id
order by t1.product_id, t1.report_year;
