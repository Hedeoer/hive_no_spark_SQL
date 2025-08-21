/*
 题目43 连续会话

 SQL
 Sessions
| Column Name | Type |
| ----------- | ---- |
| user_id | int |
| session_start | datetime |
| session_end | datetime |
| session_id | int |
| session_type | enum |

session_id 是这张表中各不相同的列。
session_type 是 (Viewer, Streamer) 的一个 ENUM (category) 类型。
这张表包含 user_id, session_start, session_end, session_id 和 session 类型。
编写一个解决方案，以查找至少有一个相同类型的连续会话（无论是"viewer"还是"streamer"）的用户，会
话 之间 的 最大 间隔为 12 小时。
返回结果表，以 user_id 升序 排序。
结果格式如下所示。

 示例：
 输入：
Sessions 表:
| user_id | session_start | session_end | session_id | session_type |
| ------- | ------------- | ----------- | ---------- | ------------ |
| 101 | 2023-11-01 08:00:00 | 2023-11-01 09:00:00 | 1 | Viewer |
| 101 | 2023-11-01 10:00:00 | 2023-11-01 11:00:00 | 2 | Streamer |
| 102 | 2023-11-01 13:00:00 | 2023-11-01 14:00:00 | 3 | Viewer |
| 102 | 2023-11-01 15:00:00 | 2023-11-01 16:00:00 | 4 | Viewer |
| 101 | 2023-11-02 07:00:00 | 2023-11-02 08:00:00 | 5 | Viewer |
| 102 | 2023-11-02 12:00:00 | 2023-11-02 13:00:00 | 6 | Streamer |
| 101 | 2023-11-02 13:00:00 | 2023-11-02 14:00:00 | 7 | Streamer |
| 102 | 2023-11-02 16:00:00 | 2023-11-02 17:00:00 | 8 | Viewer |
| 103 | 2023-11-01 08:00:00 | 2023-11-01 09:00:00 | 9 | Viewer |
| 103 | 2023-11-02 20:00:00 | 2023-11-02 23:00:00 | 10 | Viewer |
| 103 | 2023-11-03 09:00:00 | 2023-11-03 10:00:00 | 11 | Viewer |

 输出：
| user_id |
| ------- |
| 102 |
| 103 |

 解释：
- 用户 ID 101 将不会包含在最终输出中，因为他们没有相同类型的连续会话。
- 用户 ID 102 将会包含在最终输出中，因为他们分别有两个 session ID 为 3 和 4 的 viewer 会话，并且时间间隔在 12 小时内。
- 用户 ID 103 参与了两次 viewer 会话，间隔不到 12 小时，会话 ID 为 10 和 11，因此，用户 103 将会被包含在最终输出中。
输出按照表格 user_id 升序排列。



*/

WITH Sessions AS (
  SELECT 101 AS user_id, '2023-11-01 08:00:00' AS session_start, '2023-11-01 09:00:00' AS session_end, 1 AS session_id, 'Viewer' AS session_type UNION ALL
  SELECT 101, '2023-11-01 10:00:00', '2023-11-01 11:00:00', 2, 'Streamer' UNION ALL
  SELECT 102, '2023-11-01 13:00:00', '2023-11-01 14:00:00', 3, 'Viewer' UNION ALL
  SELECT 102, '2023-11-01 15:00:00', '2023-11-01 16:00:00', 4, 'Viewer' UNION ALL
  SELECT 101, '2023-11-02 07:00:00', '2023-11-02 08:00:00', 5, 'Viewer' UNION ALL
  SELECT 102, '2023-11-02 12:00:00', '2023-11-02 13:00:00', 6, 'Streamer' UNION ALL
  SELECT 101, '2023-11-02 13:00:00', '2023-11-02 14:00:00', 7, 'Streamer' UNION ALL
  SELECT 102, '2023-11-02 16:00:00', '2023-11-02 17:00:00', 8, 'Viewer' UNION ALL
  SELECT 103, '2023-11-01 08:00:00', '2023-11-01 09:00:00', 9, 'Viewer' UNION ALL
  SELECT 103, '2023-11-02 20:00:00', '2023-11-02 23:00:00', 10, 'Viewer' UNION ALL
  SELECT 103, '2023-11-03 09:00:00', '2023-11-03 10:00:00', 11, 'Viewer'
),
    group_condition as (
        select
            user_id,
            session_type,
            start_seconds,
            session_start,
            end_seconds,
            session_end,
            before_session_end_seconds,
            sum(
             case
                 -- 首次会话
                 when before_session_end_seconds is null then 0
                 -- 会话区间重叠也视为满足连续条件
                 when start_seconds - before_session_end_seconds <= 0 then 0
                 -- 两个会话间隔少于12小时
                 when start_seconds - before_session_end_seconds <= 12 * 60 * 60 then 0
                 else 1 end
            ) over(partition by user_id, session_type order by start_seconds ) group_id

        from (
            select user_id,
                   session_type,
                   -- 秒级别
                   unix_timestamp(session_start,'yyyy-MM-dd HH:mm:ss') start_seconds,
                   session_start,
                   unix_timestamp(session_end,'yyyy-MM-dd HH:mm:ss') end_seconds,
                   session_end,
                   lag(unix_timestamp(session_end)) over(partition by user_id , session_type order by unix_timestamp(session_start)) before_session_end_seconds

            from Sessions
            where session_type in ("Viewer","Streamer")
             ) t1
    )
select
    user_id
from group_condition
group by user_id, session_type, group_id
having count(1) >= 2;
