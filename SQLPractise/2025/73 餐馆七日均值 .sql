
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
