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