
/*
表: `Sessions`
```
+---------------+----------+
| Column Name   | Type     |
+---------------+----------+
| user_id       | int      |
| session_start | datetime |
| session_end   | datetime |
| session_id    | int      |
| session_type  | enum     |
+---------------+----------+
```
`session_id` 是这张表中有不同值的列。
`session_type` 是 (Viewer, Streamer) 的一个 ENUM (category) 类型。
这张表包含 user id, session start, session end, session id 和 session 类型。

编写一个解决方案，以查找 至少有一个相同 类型的 连续会话 (无论是“Viewer”还是“Streamer”) 的 用户，会话 之间的 最大 间隔为 12 小时。
返回结果表，以 `user_id` 升序 排序。
结果格式如下所述。

示例:

输入:
`Sessions` 表:
```
+---------+---------------------+---------------------+------------+--------------+
| user_id | session_start       | session_end         | session_id | session_type |
+---------+---------------------+---------------------+------------+--------------+
| 101     | 2023-11-01 08:00:00 | 2023-11-01 09:00:00 | 1          | Viewer       |
| 101     | 2023-11-01 10:00:00 | 2023-11-01 11:00:00 | 2          | Streamer     |
| 102     | 2023-11-01 13:00:00 | 2023-11-01 14:00:00 | 3          | Viewer       |
| 102     | 2023-11-01 15:00:00 | 2023-11-01 16:00:00 | 4          | Viewer       |
| 101     | 2023-11-02 09:00:00 | 2023-11-02 10:00:00 | 5          | Viewer       |
| 102     | 2023-11-02 12:00:00 | 2023-11-02 13:00:00 | 6          | Streamer     |
| 101     | 2023-11-02 13:00:00 | 2023-11-02 14:00:00 | 7          | Streamer     |
| 102     | 2023-11-02 16:00:00 | 2023-11-02 17:00:00 | 8          | Viewer       |
| 103     | 2023-11-01 08:00:00 | 2023-11-02 09:00:00 | 9          | Viewer       |
| 102     | 2023-11-02 20:00:00 | 2023-11-02 23:00:00 | 10         | Viewer       |
| 103     | 2023-11-03 09:00:00 | 2023-11-03 10:00:00 | 11         | Viewer       |
+---------+---------------------+---------------------+------------+--------------+
```
输出:
```
+---------+
| user_id |
+---------+
| 102     |
| 103     |
+---------+
```
解释:
- 用户 ID 101 将不会包含在最终输出中，因为他们没有相同会话类型的连续回话。
- 用户 ID 102 将会包含在最终输出中，因为他们分别有两个 session ID 为 3 和 4 的 viewer 会话, 并且时间间隔在 12 小时内。
- 用户 ID 103 参与了两次 viewer 会话, 间隔不到 12 小时, 会话 ID 为 10 和 11。因此, 用户 103 将会被包含在最终输出中。
输出表根据 `user_id` 升序排列。

*/

WITH
-- 1. 模拟 Sessions 表
Sessions AS (
    SELECT 101 AS user_id, CAST('2023-11-01 08:00:00' AS TIMESTAMP) AS session_start, CAST('2023-11-01 09:00:00' AS TIMESTAMP) AS session_end, 1  AS session_id, 'Viewer' AS session_type UNION ALL
    SELECT 101, CAST('2023-11-01 10:00:00' AS TIMESTAMP), CAST('2023-11-01 11:00:00' AS TIMESTAMP), 2,  'Streamer' UNION ALL
    SELECT 102, CAST('2023-11-01 13:00:00' AS TIMESTAMP), CAST('2023-11-01 14:00:00' AS TIMESTAMP), 3,  'Viewer'   UNION ALL
    SELECT 102, CAST('2023-11-01 15:00:00' AS TIMESTAMP), CAST('2023-11-01 16:00:00' AS TIMESTAMP), 4,  'Viewer'   UNION ALL
    SELECT 101, CAST('2023-11-02 09:00:00' AS TIMESTAMP), CAST('2023-11-02 10:00:00' AS TIMESTAMP), 5,  'Viewer'   UNION ALL
    SELECT 102, CAST('2023-11-02 12:00:00' AS TIMESTAMP), CAST('2023-11-02 13:00:00' AS TIMESTAMP), 6,  'Streamer' UNION ALL
    SELECT 101, CAST('2023-11-02 13:00:00' AS TIMESTAMP), CAST('2023-11-02 14:00:00' AS TIMESTAMP), 7,  'Streamer' UNION ALL
    SELECT 102, CAST('2023-11-02 16:00:00' AS TIMESTAMP), CAST('2023-11-02 17:00:00' AS TIMESTAMP), 8,  'Viewer'   UNION ALL
    SELECT 103, CAST('2023-11-01 08:00:00' AS TIMESTAMP), CAST('2023-11-03 09:00:00' AS TIMESTAMP), 9,  'Viewer'   UNION ALL
    SELECT 102, CAST('2023-11-02 20:00:00' AS TIMESTAMP), CAST('2023-11-02 23:00:00' AS TIMESTAMP), 10, 'Viewer'   UNION ALL
    SELECT 103, CAST('2023-11-03 09:00:00' AS TIMESTAMP), CAST('2023-11-03 10:00:00' AS TIMESTAMP), 11, 'Viewer'
),
    /*
    1. 时间相隔12小时如何计算
    2. 连续会话如何计算
    */
continuous_group as (
    select user_id,
           session_type,
           session_id,
           session_start_ts,
           session_end_ts,
           last_session_end_ts,
           judge_continuous_condition,
           -- 计算连续会话的标志
           sum(
                   case
                       when last_session_end_ts is null then 1
                       when judge_continuous_condition then 0
                       else 1 end
           ) over (partition by user_id, session_type order by session_start_ts, session_end_ts) as continuous_session
    from (
             -- 计算每个用户的会话，及其上一个会话的结束时间
             select user_id,
                    session_type,
                    session_id,
                    session_start_ts,
                    session_end_ts,
                    -- 获取上一个会话的结束时间
                    lag(session_end_ts) over (partition by user_id, session_type order by session_start_ts,session_end_ts) as last_session_end_ts,
                    -- session_start_ts,session_end_ts 升序排列，保证顺序，并计算时间间隔
                    abs(session_end_ts - lag(session_end_ts) over (partition by user_id, session_type order by session_start_ts,session_end_ts)) <= 12 * 60 * 60 as judge_continuous_condition
             from (
                      -- 将时间戳转换为秒;并对会话类型过滤
                      select
                          user_id,
                          session_type,
                          session_id,
                          unix_timestamp(session_start,'yyyy-MM-dd HH:mm:ss') as session_start_ts,
                          unix_timestamp(session_end,'yyyy-MM-dd HH:mm:ss') as session_end_ts
                      from Sessions t1
                      where session_type in ('Viewer', 'Streamer')

                  ) t2
         ) t3

)
select
    distinct user_id
from (
         select
             user_id
         from continuous_group t
         group by user_id, session_type,continuous_session
         having count(1) > 1
     ) tt;