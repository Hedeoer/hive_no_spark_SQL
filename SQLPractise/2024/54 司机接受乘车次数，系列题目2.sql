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
driver_id 是该表具有唯一值的列。
该表的每一行均包含驾驶员的ID以及他们加入 Hopper 公司的日期。

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
ride_id 是该表具有唯一值的列。
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
ride_id 是该表具有唯一值的列。
该表的每一行都包含已接受的行程信息。
表中的行程信息都在 "Rides" 表中存在。

编写解决方案以报告 2020 年每个月的工作驱动因素 百分比 (working_percentage)，其中：
注意：如果一个月内可用驾驶员的数量为零，我们认为 working_percentage 为 0。
返回按 month 升序 排列的结果表，其中 month 是月份的编号 (一月是 1，二月是 2, 等等)。将 working_percentage 四舍五入至 小数点后两位。
结果格式如下例所示。

示例 1:

输入:
表 `Drivers`:
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
表 `Rides`:
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
表 `AcceptedRides`:
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
+-------+--------------------+
| month | working_percentage |
+-------+--------------------+
| 1     | 0.00               |
| 2     | 0.00               |
| 3     | 25.00              |
| 4     | 0.00               |
| 5     | 0.00               |
| 6     | 20.00              |
| 7     | 20.00              |
| 8     | 20.00              |
| 9     | 0.00               |
| 10    | 0.00               |
| 11    | 33.33              |
| 12    | 16.67              |
+-------+--------------------+
```
解释:
截至 1 月底 --> 2 个活跃的驾驶员 (10, 8)，无被接受的行程。百分比是0%。
截至 2 月底 --> 3 个活跃的驾驶员 (10, 8, 5)，无被接受的行程。百分比是0%。
截至 3 月底 --> 4 个活跃的驾驶员 (10, 8, 5, 7)，1 个被接受的行程 (10)。百分比是 (1 / 4) * 100 = 25%。
截至 4 月底 --> 4 个活跃的驾驶员 (10, 8, 5, 7)，无被接受的行程。百分比是 0%。
截至 5 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，无被接受的行程。百分比是 0%。
截至 6 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，1 个被接受的行程 (10)。百分比是 (1 / 5) * 100 = 20%。
截至 7 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，1 个被接受的行程 (8)。百分比是 (1 / 5) * 100 = 20%。
截至 8 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，1 个被接受的行程 (7)。百分比是 (1 / 5) * 100 = 20%。
截至 9 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，无被接受的行程。百分比是 0%。
截至 10 月底 --> 6 个活跃的驾驶员 (10, 8, 5, 7, 4, 1)，无被接受的行程。百分比是 0%。
截至 11 月底 --> 6 个活跃的驾驶员 (10, 8, 5, 7, 4, 1)，2 个被接受的行程 (1, 7)。百分比是 (2 / 6) * 100 = 33.33%。
截至 12 月底 --> 6 个活跃的驾驶员 (10, 8, 5, 7, 4, 1)，1 个被接受的行程 (4)。百分比是 (1 / 6) * 100 = 16.67%。

*/

/*
1. 截止2020年每月底的活跃司机数
2. 2020年每月的接受行程数
3. / 并四舍五入处理，按照month升序
*/


WITH
-- 1. 模拟 Drivers 表 (使用 UNION ALL 语法)
Drivers AS (SELECT 10 AS driver_id, CAST('2019-12-10' AS DATE) AS join_date
            UNION ALL
            SELECT 8, CAST('2020-01-13' AS DATE)
            UNION ALL
            SELECT 5, CAST('2020-02-16' AS DATE)
            UNION ALL
            SELECT 7, CAST('2020-03-08' AS DATE)
            UNION ALL
            SELECT 4, CAST('2020-05-17' AS DATE)
            UNION ALL
            SELECT 1, CAST('2020-10-24' AS DATE)
            UNION ALL
            SELECT 6, CAST('2021-01-05' AS DATE)),

-- 2. 模拟 Rides 表 (使用 UNION ALL 语法)
Rides AS (SELECT 6 AS ride_id, 75 AS user_id, CAST('2019-12-09' AS DATE) AS requested_at
          UNION ALL
          SELECT 1, 54, CAST('2020-02-09' AS DATE)
          UNION ALL
          SELECT 10, 63, CAST('2020-03-04' AS DATE)
          UNION ALL
          SELECT 19, 39, CAST('2020-04-06' AS DATE)
          UNION ALL
          SELECT 3, 41, CAST('2020-06-03' AS DATE)
          UNION ALL
          SELECT 13, 52, CAST('2020-06-22' AS DATE)
          UNION ALL
          SELECT 7, 69, CAST('2020-07-16' AS DATE)
          UNION ALL
          SELECT 17, 70, CAST('2020-08-25' AS DATE)
          UNION ALL
          SELECT 20, 81, CAST('2020-11-02' AS DATE)
          UNION ALL
          SELECT 5, 57, CAST('2020-11-09' AS DATE)
          UNION ALL
          SELECT 2, 42, CAST('2020-12-09' AS DATE)
          UNION ALL
          SELECT 11, 68, CAST('2021-01-11' AS DATE)
          UNION ALL
          SELECT 15, 32, CAST('2021-01-17' AS DATE)
          UNION ALL
          SELECT 12, 11, CAST('2021-01-19' AS DATE)
          UNION ALL
          SELECT 14, 18, CAST('2021-01-27' AS DATE)),

-- 3. 模拟 AcceptedRides 表 (使用 UNION ALL 语法)
AcceptedRides AS (SELECT 10 AS ride_id, 10 AS driver_id, 63 AS ride_distance, 38 AS ride_duration
                  UNION ALL
                  SELECT 13, 10, 73, 96
                  UNION ALL
                  SELECT 7, 8, 100, 28
                  UNION ALL
                  SELECT 17, 7, 119, 68
                  UNION ALL
                  SELECT 20, 1, 121, 92
                  UNION ALL
                  SELECT 5, 7, 42, 101
                  UNION ALL
                  SELECT 2, 4, 6, 38
                  UNION ALL
                  SELECT 11, 8, 37, 43
                  UNION ALL
                  SELECT 15, 8, 108, 82
                  UNION ALL
                  SELECT 12, 8, 38, 34
                  UNION ALL
                  SELECT 14, 1, 90, 74),
dim_2020_month as (
    -- 查询出2020年每月的最后一天，比如 2020-06-30
    select
        pos + 1 month_number,
        last_day(to_date(concat('2020','-',lpad(val,2,'0'),'-01')) )last_day
    from (select posexplode(`array`(1,2,3,4,5,6,7,8,9,10,11,12))) t1
),
-- 2020年截止每月底的活跃司机数
active_drivers as (
    select
        t1.month_number,
        t1.last_day,
        count(distinct t2.driver_id) acc_active_drivers
    from dim_2020_month t1
             left join Drivers t2
                       on t1.last_day >= t2.join_date
    group by t1.month_number, t1.last_day
),
-- 2020年每月的接受的行程数
accept_rides as (
    select
        last_day(requested_at) last_day,
        count(1) accepts_rides
    from AcceptedRides t1
             left join Rides t2
                       on t1.ride_id = t2.ride_id
    where year(t2.requested_at) = 2020 and t2.ride_id is not null
    group by last_day(requested_at)
)
select
    t1.month_number,
    round(nvl(t2.accepts_rides,0) / t1.acc_active_drivers * 100, 2)  working_percentage
from active_drivers t1
         left join accept_rides t2
                   on t1.last_day  = t2.last_day
order by t1.month_number;
