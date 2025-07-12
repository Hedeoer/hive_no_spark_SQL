/*
表: `Drivers`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| driver_id   | int     |
| join_date   | date    |
+-------------+---------+
```
`driver_id` 是该表具有唯一值的列。
该表的每一行均包含驾驶员的 ID 以及他们加入 Hopper 公司的日期。

表: `Rides`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| ride_id      | int     |
| user_id      | int     |
| requested_at | date    |
+--------------+---------+
```
`ride_id` 是该表具有唯一值的列。
该表的每一行均包含行程 ID(ride_id)，用户 ID(user_id) 以及该行程的日期 (requested_at)。
该表中可能有一些不被接受的乘车请求。

表: `AcceptedRides`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| ride_id       | int     |
| driver_id     | int     |
| ride_distance | int     |
| ride_duration | int     |
+---------------+---------+
```
`ride_id` 是该表具有唯一值的列。
该表的每一行都包含已接受的行程信息。
表中的行程信息都在 "Rides" 表中存在。

编写一个解决方案，计算出从 `2020 年 1 月至 3 月` 至 `2020 年 10 月至 12 月` 的每三个月窗口的 `average_ride_distance` 和 `average_ride_duration`。
并将 `average_ride_distance` 和 `average_ride_duration` 四舍五入至 小数点后两位。
通过将三个月的总 `ride_distance` 相加并除以 `3` 来计算 `average_ride_distance`。`average_ride_duration` 的计算方法与此类似。

返回按 `month` 升序排列的结果表，其中 `month` 是起始月份的编号 (一月为 1, 二月为 2 ...)。
查询结果格式如下示例所示。

示例 1:

输入:
`Drivers table`:
```
+-----------+------------+
| driver_id | join_date  |
+-----------+------------+
| 10        | 2019-12-10 |
| 8         | 2020-1-13  |
| 5         | 2020-2-16  |
| 7         | 2020-3-8   |
| 4         | 2020-5-17  |
| 1         | 2020-10-24 |
| 6         | 2021-1-5   |
+-----------+------------+
```
`Rides table`:
```
+---------+---------+--------------+
| ride_id | user_id | requested_at |
+---------+---------+--------------+
| 6       | 75      | 2019-12-9    |
| 1       | 54      | 2020-2-9     |
| 10      | 63      | 2020-3-4     |
| 19      | 39      | 2020-4-6     |
| 3       | 41      | 2020-6-3     |
| 13      | 52      | 2020-6-22    |
| 7       | 69      | 2020-7-16    |
| 17      | 70      | 2020-8-25    |
| 20      | 81      | 2020-11-2    |
| 5       | 57      | 2020-11-9    |
| 2       | 42      | 2020-12-9    |
| 11      | 68      | 2021-1-11    |
| 15      | 32      | 2021-1-17    |
| 12      | 11      | 2021-1-19    |
| 14      | 18      | 2021-1-27    |
+---------+---------+--------------+
```
`AcceptedRides table`:
```
+---------+-----------+---------------+---------------+
| ride_id | driver_id | ride_distance | ride_duration |
+---------+-----------+---------------+---------------+
| 10      | 10        | 63            | 38            |
| 13      | 10        | 73            | 96            |
| 7       | 8         | 100           | 28            |
| 17      | 7         | 119           | 68            |
| 20      | 1         | 121           | 92            |
| 5       | 7         | 42            | 101           |
| 2       | 4         | 6             | 38            |
| 11      | 8         | 37            | 43            |
| 15      | 8         | 108           | 82            |
| 12      | 8         | 38            | 34            |
| 14      | 1         | 90            | 74            |
+---------+-----------+---------------+---------------+
```
输出:
```
+-------+-----------------------+-------------------------+
| month | average_ride_distance | average_ride_duration   |
+-------+-----------------------+-------------------------+
| 1     | 21.00                 | 12.67                   |
| 2     | 21.00                 | 12.67                   |
| 3     | 21.00                 | 12.67                   |
| 4     | 24.33                 | 32.00                   |
| 5     | 57.67                 | 41.33                   |
| 6     | 97.33                 | 64.00                   |
| 7     | 73.00                 | 32.00                   |
| 8     | 39.67                 | 22.67                   |
| 9     | 54.33                 | 64.33                   |
| 10    | 56.33                 | 77.00                   |
+-------+-----------------------+-------------------------+
```
解释:
到1月底-->平均骑行距离= (0+0+63)/3=21, 平均骑行持续时间= (0+0+38)/3=12.67
到2月底-->平均骑行距离= (0+63+0)/3=21, 平均骑行持续时间= (0+38+0)/3=12.67
到3月底-->平均骑行距离= (63+0+0)/3=21, 平均骑行持续时间= (38+0+0)/3=12.67
到4月底-->平均骑行距离= (0+0+73)/3=24.33, 平均骑行持续时间= (0+0+96)/3=32.00
到5月底-->平均骑行距离= (0+73+100)/3=57.67, 平均骑行持续时间= (0+96+28)/3=41.33
到6月底-->平均骑行距离= (73+100+119)/3=97.33, 平均骑行持续时间= (96+28+68)/3=64.00
到7月底-->平均骑行距离= (100+119+0)/3=73.00, 平均骑行持续时间= (28+68+0)/3=32.00
到8月底-->平均骑行距离= (119+0+0)/3=39.67, 平均骑行持续时间= (68+0+0)/3=22.67
到9月底-->平均骑行距离= (0+0+163)/3=54.33, 平均骑行持续时间= (0+0+193)/3=64.33
到10月底-->平均骑行距离= (0+163+6)/3=56.33, 平均骑行持续时间= (0+193+38)/3=77.00
*/




WITH
-- 1. 模拟 Drivers 表
Drivers AS (
    SELECT 10 AS driver_id, CAST('2019-12-10' AS DATE) AS join_date UNION ALL
    SELECT 8,  CAST('2020-01-13' AS DATE) UNION ALL
    SELECT 5,  CAST('2020-02-16' AS DATE) UNION ALL
    SELECT 7,  CAST('2020-03-08' AS DATE) UNION ALL
    SELECT 4,  CAST('2020-05-17' AS DATE) UNION ALL
    SELECT 1,  CAST('2020-10-24' AS DATE) UNION ALL
    SELECT 6,  CAST('2021-01-05' AS DATE)
),

-- 2. 模拟 Rides 表
Rides AS (
    SELECT 6 AS ride_id, 75 AS user_id, CAST('2019-12-09' AS DATE) AS requested_at UNION ALL
    SELECT 1,  54, CAST('2020-02-09' AS DATE) UNION ALL
    SELECT 10, 63, CAST('2020-03-04' AS DATE) UNION ALL
    SELECT 19, 39, CAST('2020-04-06' AS DATE) UNION ALL
    SELECT 3,  41, CAST('2020-06-03' AS DATE) UNION ALL
    SELECT 13, 52, CAST('2020-06-22' AS DATE) UNION ALL
    SELECT 7,  69, CAST('2020-07-16' AS DATE) UNION ALL
    SELECT 17, 70, CAST('2020-08-25' AS DATE) UNION ALL
    SELECT 20, 81, CAST('2020-11-02' AS DATE) UNION ALL
    SELECT 5,  57, CAST('2020-11-09' AS DATE) UNION ALL
    SELECT 2,  42, CAST('2020-12-09' AS DATE) UNION ALL
    SELECT 11, 68, CAST('2021-01-11' AS DATE) UNION ALL
    SELECT 15, 32, CAST('2021-01-17' AS DATE) UNION ALL
    SELECT 12, 11, CAST('2021-01-19' AS DATE) UNION ALL
    SELECT 14, 18, CAST('2021-01-27' AS DATE)
),

-- 3. 模拟 AcceptedRides 表
AcceptedRides AS (
    SELECT 10 AS ride_id, 10 AS driver_id, 63 AS ride_distance, 38 AS ride_duration UNION ALL
    SELECT 13, 10, 73,  96  UNION ALL
    SELECT 7,  8,  100, 28  UNION ALL
    SELECT 17, 7,  119, 68  UNION ALL
    SELECT 20, 1,  121, 92  UNION ALL
    SELECT 5,  7,  42,  101 UNION ALL
    SELECT 2,  4,  6,   38  UNION ALL
    SELECT 11, 8,  37,  43  UNION ALL
    SELECT 15, 8,  108, 82  UNION ALL
    SELECT 12, 8,  38,  34  UNION ALL
    SELECT 14, 1,  90,  74
),
/*
1. 过滤出需要的数据
2. 每个月的行程数和 总耗时，总里程数
3. 窗口函数即可
*/
dim_2020_month as (
-- 查询出2020年每月的最后一天，比如 2020-06-30
    select
        pos + 1 month_number,
        last_day(to_date(concat('2020','-',lpad(val,2,'0'),'-01')) )last_day
    from (select posexplode(`array`(1,2,3,4,5,6,7,8,9,10,11,12))) t1
    union all
    select null,last_day('2019-11-01')
    union all
    select null,last_day('2019-12-01')
),
base_data as (
    select
        last_day(t1.requested_at) last_day,
        sum(t2.ride_distance) month_distance,
        sum(t2.ride_duration) month_duration
    from Rides t1
             left join AcceptedRides t2
                       on t1.ride_id = t2.ride_id
    where t2.ride_id is not null and  t1.requested_at >= to_date('2019-11-01') and t1.requested_at <= to_date('2020-12-31')
    group by last_day(t1.requested_at)
)
select
    t1.month_number,
    round(average_ride_distance1,2) average_ride_distance,
    round(average_ride_duration1,2) average_ride_duration
from (
         select
             t1.month_number,
             t1.last_day,
             avg(nvl(t2.month_distance,0)) over(order by t1.last_day rows between 2 preceding and current row ) average_ride_distance1,
             avg(nvl(t2.month_duration,0)) over(order by t1.last_day rows between 2 preceding and current row ) average_ride_duration1

         from dim_2020_month t1
                  left join base_data t2
                            on t1.last_day = t2.last_day
     ) t1
where t1.month_number is not null