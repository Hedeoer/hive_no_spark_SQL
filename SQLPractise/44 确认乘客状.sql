/*
# 题目内容

```


表: Flights
+----------------+
| 列名 | 类型 |
+----------------+
| flight_id | int |
| capacity | int |
+----------------+
flight_id 列全不同的值。
每行包含航班 id 和座位容量。

表：Passengers
| 列名 | 类型 |
+--------------------+
| passenger_id | int |
| flight_id | int |
| booking_time | datetime |

passenger_id 包含不同的值。
booking_time 包含不同的值。
每行包含乘客 id、预订时间和所预订的航班 id。
乘客提前预订航班机票。如果乘客预订了一张航班机票，并且航班上还有空座位，则乘客的机票将得到确认。然
而，如果航班已经满员，乘客将被列入等候名单。
编写解决方案来确定每个乘客航班机票的当前状态。
按 passenger_id 升序排序 返回结果表。

| flight_id | capacity |
+-----------+----------+
| 1 | 2 |
| 2 | 2 |
| 3 | 1 |


表: Passengers
+------------------------------------------+
| passenger_id | flight_id | booking_time |
+------------------------------------------+
| 101 | 1 | 2023-07-10 16:30:00 |
| 102 | 1 | 2023-07-10 17:45:00 |
| 103 | 1 | 2023-07-10 12:00:00 |
| 104 | 2 | 2023-07-05 13:23:00 |
| 105 | 2 | 2023-07-05 09:00:00 |
| 106 | 3 | 2023-07-08 11:10:00 |
| 107 | 3 | 2023-07-08 09:10:00 |
+------------------------------------------+

输出:
+------------------------+
| passenger_id | status |
+------------------------+
| 101 | Confirmed |
| 104 | Confirmed |
| 105 | Confirmed |
| 106 | Waitlist |
| 107 | Confirmed |
+------------------------+

解释:
- 航班 1 的容量为 2，乘客 101 和乘客 103 是最先预订机票的，已经确认他们的预订。然而，乘客 102 是第三位预订该航班的乘客，这趟航班没有更多的可用座位，乘客 102 被添加入等候名单。
- 航班 2 的容量为 2，已经有两名乘客预订了机票，乘客 104 和乘客 105，由于预订机票的乘客数与可用座位数相符，这两个预订都得到了确认。
- 航班 3 的容量为 1，由于乘客 107 先预订了一个可用座位，该乘客的预订得到了确认。预订时间在乘客 107 之后的乘客 106 被列入等候名单。

with t as (select passenger_id,capacity,
rank() over(partition by flight_id order by booking_time) as rnk
from passengers join flights using(flight_id))

select passenger_id,
if(rnk<=capacity,'Confirmed','Waitlist') as status
from t
order by passenger_id


题目40 前三名酒店 (dt = '2024-12-27')*/

WITH Flights AS (
  SELECT 1 AS flight_id, 2 AS capacity UNION ALL
  SELECT 2 AS flight_id, 2 AS capacity UNION ALL
  SELECT 3 AS flight_id, 1 AS capacity
),
Passengers AS (
  SELECT 101 AS passenger_id, 1 AS flight_id, '2023-07-10 16:30:00' AS booking_time UNION ALL
  SELECT 102 AS passenger_id, 1 AS flight_id, '2023-07-10 17:45:00' AS booking_time UNION ALL
  SELECT 103 AS passenger_id, 1 AS flight_id, '2023-07-10 12:00:00' AS booking_time UNION ALL
  SELECT 104 AS passenger_id, 2 AS flight_id, '2023-07-05 13:23:00' AS booking_time UNION ALL
  SELECT 105 AS passenger_id, 2 AS flight_id, '2023-07-05 09:00:00' AS booking_time UNION ALL
  SELECT 106 AS passenger_id, 3 AS flight_id, '2023-07-08 11:10:00' AS booking_time UNION ALL
  SELECT 107 AS passenger_id, 3 AS flight_id, '2023-07-08 09:10:00' AS booking_time
)
select t1.passenger_id,
       t1.booking_time,
       if(t1.current_passagers <= t2.capacity, 'Confirmed', 'Waitlist') status
from (
    select passenger_id,
           flight_id,
           booking_time,
           count(distinct passenger_id) over(partition by flight_id order by booking_time ) current_passagers
    from Passengers t1
     ) t1
left join Flights t2
on t1.flight_id = t2.flight_id
order by t1.passenger_id;

-- 方式二
WITH Flights AS (
  SELECT 1 AS flight_id, 2 AS capacity UNION ALL
  SELECT 2 AS flight_id, 2 AS capacity UNION ALL
  SELECT 3 AS flight_id, 1 AS capacity
),
Passengers AS (
  SELECT 101 AS passenger_id, 1 AS flight_id, '2023-07-10 16:30:00' AS booking_time UNION ALL
  SELECT 102 AS passenger_id, 1 AS flight_id, '2023-07-10 17:45:00' AS booking_time UNION ALL
  SELECT 103 AS passenger_id, 1 AS flight_id, '2023-07-10 12:00:00' AS booking_time UNION ALL
  SELECT 104 AS passenger_id, 2 AS flight_id, '2023-07-05 13:23:00' AS booking_time UNION ALL
  SELECT 105 AS passenger_id, 2 AS flight_id, '2023-07-05 09:00:00' AS booking_time UNION ALL
  SELECT 106 AS passenger_id, 3 AS flight_id, '2023-07-08 11:10:00' AS booking_time UNION ALL
  SELECT 107 AS passenger_id, 3 AS flight_id, '2023-07-08 09:10:00' AS booking_time
)
select passenger_id,
           booking_time,
           if(rank() over(partition by t1.flight_id order by booking_time ) <= t2.capacity , 'Confirmed','Waitlist') status
    from Passengers t1
left join Flights t2
on t1.flight_id = t2.flight_id
order by t1.passenger_id;


