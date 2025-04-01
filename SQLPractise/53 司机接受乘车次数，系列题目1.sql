/*
 题目26 司机接受乘车次数，系列题目1

```sql
表1: Drivers

| Column Name | Type |
|-------------|------|
| driver_id   | int  |
| join_date   | date |

driver_id 是该表的主键（具有唯一值的列）。
该表的每一行都包含驾驶员加入Hopper公司的日期(join_date)的信息。

表2: Rides

| Column Name | Type |
|-------------|------|
| ride_id     | int  |
| user_id     | int  |
| requested_at| date |

ride_id 是该表的主键（具有唯一值的列）。
该表的每一行都包含乘客请求打车服务的信息。
其中有一些请求可能被取消了。

表3: AcceptedRides

| Column Name | Type |
|-------------|------|
| ride_id     | int  |
| driver_id   | int  |
| ride_distance| int  |
| ride_duration| int  |

ride_id 是该表的主键(具有唯一值的列)。
该表的每一行都包含已接受的行程信息。
表中的行程信息都在"Rides"表中存在。
编写解决方案
 以报告2020 年每个月的以下统计信息：截至某月底，当前在Hopper公司工作的
 驾驶员数量（active_drivers）。
该月接受的乘车次数（accepted_rides）。
返回按month升序排列的结果表，其中month是月份的数字（一月是1，二月是2，依此类推）。
返回结果格式如下例所示。

表：Drivers
```
| driver_id | join_date  |
|-----------|------------|
| 10        | 2019-12-10 |
| 8         | 2020-1-13  |
| 5         | 2020-2-16  |
| 7         | 2020-3-8   |
| 4         | 2020-5-17  |
| 1         | 2020-10-24 |
| 6         | 2021-1-5   |
```

表：Rides
```
| ride_id   | user_id   | requested_at |
|-----------|-----------|--------------|
| 6         | 75        | 2019-12-9    |
| 1         | 54        | 2020-2-9     |
| 10        | 63        | 2020-3-4     |
| 19        | 39        | 2020-4-6     |
| 3         | 41        | 2020-6-3     |
| 13        | 52        | 2020-6-22    |
| 7         | 69        | 2020-7-16    |
| 17        | 70        | 2020-8-25    |
| 20        | 81        | 2020-11-2    |
| 5         | 57        | 2020-11-9    |
| 2         | 42        | 2020-12-9    |
| 11        | 68        | 2021-1-11    |
| 15        | 32        | 2021-1-17    |
| 12        | 11        | 2021-1-19    |
| 14        | 18        | 2021-1-27    |
```

表：AcceptedRides
```
| ride_id | driver_id | ride_distance | ride_duration |
|---------|-----------|---------------|--------------|
| 10      | 10        | 63            | 38           |
| 13      | 10        | 73            | 96           |
| 7       | 8         | 100           | 28           |
| 17      | 7         | 119           | 68           |
| 20      | 1         | 121           | 92           |
| 5       | 7         | 42            | 101          |
| 2       | 4         | 6             | 38           |
| 11      | 8         | 37            | 43           |
| 15      | 8         | 108           | 82           |
| 12      | 8         | 38            | 34           |
| 14      | 1         | 90            | 74           |
```

结果表:
```
| month | active_drivers | accepted_rides |
|-------|----------------|----------------|
| 1     | 2              | 0              |
| 2     | 3              | 1              |
| 3     | 4              | 1              |
| 4     | 4              | 1              |
| 5     | 5              | 0              |
| 6     | 5              | 2              |
| 7     | 5              | 1              |
| 8     | 5              | 1              |
| 9     | 5              | 0              |
| 10    | 6              | 0              |
| 11    | 6              | 2              |
| 12    | 6              | 1              |
```

解释:
- 1月份：有2位活跃司机（10，8）和0次接受的行程。
- 2月份：有3位活跃司机（10，8，5）和1次接受的行程。
- 3月份：有4位活跃司机（10，8，5，7）和1次接受的行程。
- 4月份：有4位活跃司机（10，8，5，7）和1次接受的行程。
- 5月份：有5位活跃司机（10，8，5，7，4）和0次接受的行程。
- 6月份：有5位活跃司机（10，8，5，7，4）和2次接受的行程。
- 7月份：有5位活跃司机（10，8，5，7，4）和1次接受的行程。
- 8月份：有5位活跃司机（10，8，5，7，4）和1次接受的行程。
- 9月份：有5位活跃司机（10，8，5，7，4）和0次接受的行程。
- 10月份：有6位活跃司机（10，8，5，7，4，1）和0次接受的行程。
- 11月份：有6位活跃司机（10，8，5，7，4，1）和2次接受的行程。
- 12月份：有6位活跃司机（10，8，5，7，4，1）和1次接受的行程。
*/

-- xx
WITH Drivers AS (
  SELECT 10 AS driver_id, CAST('2019-12-10' AS date) AS join_date UNION ALL
  SELECT 8, CAST('2020-1-13' AS date) UNION ALL
  SELECT 5, CAST('2020-2-16' AS date) UNION ALL
  SELECT 7, CAST('2020-3-8' AS date) UNION ALL
  SELECT 4, CAST('2020-5-17' AS date) UNION ALL
  SELECT 1, CAST('2020-10-24' AS date) UNION ALL
  SELECT 6, CAST('2021-1-5' AS date)
),

Rides AS (
  SELECT 6 AS ride_id, 75 AS user_id, CAST('2019-12-9' AS date) AS requested_at UNION ALL
  SELECT 1, 54, CAST('2020-2-9' AS date) UNION ALL
  SELECT 10, 63, CAST('2020-3-4' AS date) UNION ALL
  SELECT 19, 39, CAST('2020-4-6' AS date) UNION ALL
  SELECT 3, 41, CAST('2020-6-3' AS date) UNION ALL
  SELECT 13, 52, CAST('2020-6-22' AS date) UNION ALL
  SELECT 7, 69, CAST('2020-7-16' AS date) UNION ALL
  SELECT 17, 70, CAST('2020-8-25' AS date) UNION ALL
  SELECT 20, 81, CAST('2020-11-2' AS date) UNION ALL
  SELECT 5, 57, CAST('2020-11-9' AS date) UNION ALL
  SELECT 2, 42, CAST('2020-12-9' AS date) UNION ALL
  SELECT 11, 68, CAST('2021-1-11' AS date) UNION ALL
  SELECT 15, 32, CAST('2021-1-17' AS date) UNION ALL
  SELECT 12, 11, CAST('2021-1-19' AS date) UNION ALL
  SELECT 14, 18, CAST('2021-1-27' AS date)
),

AcceptedRides AS (
  SELECT 10 AS ride_id, 10 AS driver_id, 63 AS ride_distance, 38 AS ride_duration UNION ALL
  SELECT 13, 10, 73, 96 UNION ALL
  SELECT 7, 8, 100, 28 UNION ALL
  SELECT 17, 7, 119, 68 UNION ALL
  SELECT 20, 1, 121, 92 UNION ALL
  SELECT 5, 7, 42, 101 UNION ALL
  SELECT 2, 4, 6, 38 UNION ALL
  SELECT 11, 8, 37, 43 UNION ALL
  SELECT 15, 8, 108, 82 UNION ALL
  SELECT 12, 8, 38, 34 UNION ALL
  SELECT 14, 1, 90, 74
)

/*
1. 月份维度表构建
2. 计算截止每月底活跃司机
3. 计算截止每月底接受的行程
*/
, dim_month AS (
    select
        t1.include_year,
        tmp.include_month,
        date_format(concat(t1.include_year,'-',tmp.include_month,'-01'),'yyyy-MM') year_month
        from (select '2020' include_year) t1
    lateral view posexplode(array(1,2,3,4,5,6,7,8,9,10,11,12)) tmp as pos, include_month
),
    active_drivers AS (
        select
            t1.year_month,
            -- 截止每月底司机总数 = 以往每月入职司机数量总和
            sum(coalesce(t2.active_drivers,0)) active_drivers
        from dim_month t1
        left join (
            -- 每月入职司机
            select
                date_format(join_date,'yyyy-MM') join_month,
                count(distinct driver_id) active_drivers
            from Drivers t1
            where year(join_date) <= 2020
            group by date_format(join_date,'yyyy-MM')
        ) t2
            -- 截止每月底司机总数过滤条件
        on t2.join_month <= t1.year_month
        group by t1.year_month
    ),
    accepted_rides AS (
        select
            date_format(t1.requested_at, 'yyyy-MM') accept_month,
            count(distinct t2.ride_id) accepted_rides
        from Rides t1
        left join AcceptedRides t2
        on t1.ride_id = t2.ride_id
        where t2.ride_id is not null and year(t1.requested_at) = 2020
        group by date_format(t1.requested_at, 'yyyy-MM')
    )
select
    case
        when t1.year_month = '2020-01' then 1
        when t1.year_month = '2020-02' then 2
        when t1.year_month = '2020-03' then 3
        when t1.year_month = '2020-04' then 4
        when t1.year_month = '2020-05' then 5
        when t1.year_month = '2020-06' then 6
        when t1.year_month = '2020-07' then 7
        when t1.year_month = '2020-08' then 8
        when t1.year_month = '2020-09' then 9
        when t1.year_month = '2020-10' then 10
        when t1.year_month = '2020-11' then 11
        when t1.year_month = '2020-12' then 12
    end month,
    t1.active_drivers,
    coalesce(t2.accepted_rides,0) accepted_rides
from active_drivers t1
left join accepted_rides t2
on t1.year_month = t2.accept_month
order by month;
