/*
表: Sessions
+---------------------+
| Column Name | Type  |
+---------------------+
| user_id | int |
| session_start | datetime |
| session_end | datetime |
| session_id | int |
| session_type | enum |
+---------------------+
session_id 是这张表具有唯一值的列。
session_type 是一个枚举(Enum)类型，类型为(Viewer, Streamer)两个类型。
这张表包含 user_id, session_start, session_end, session_id 和 session_type.
编写一个解决方案，找到 首次会话 为 观众型的 的用户, 其 主播会话 数量。
按照会话数量由 user_id 降序 排序返回结果集。
结果格式如下所示。

示例 1:
输入:
Sessions table:
+----------+---------------------+---------------------+-----------+-------------+
| user_id | session_start      | session_end        | session_id | session_type |
+----------+---------------------+---------------------+-----------+-------------+
| 101 | 2023-11-06 13:53:42 | 2023-11-06 14:05:42 | 375 | Viewer |
| 101 | 2023-11-22 16:45:21 | 2023-11-22 20:39:21 | 594 | Streamer |
| 102 | 2023-11-16 13:23:09 | 2023-11-16 16:10:09 | 777 | Streamer |
| 102 | 2023-11-17 13:23:09 | 2023-11-17 16:10:09 | 778 | Streamer |
| 101 | 2023-11-20 07:16:06 | 2023-11-20 08:33:06 | 315 | Streamer |
| 104 | 2023-11-27 03:10:49 | 2023-11-27 03:30:49 | 797 | Viewer |
| 103 | 2023-11-27 03:10:49 | 2023-11-27 03:30:49 | 798 | Streamer |
+----------+---------------------+---------------------+-----------+-------------+
输出:
+----------+----------------+
| user_id | sessions_count |
+----------+----------------+
| 101 | 2 |
+----------+----------------+
解释
- user_id 101, 在 2023-11-06 13:53:42 以观众身份开始了他们的初始会话，随后进行了两次主播会话，所以计数为 2。
- user_id 102, 尽管有两个会话，但初始会话是作为主播，因此被排除此用户。
- user_id 103 只参与了一次会话，即作为主播，因此不会考虑在内。
- user_id 104 以观众身份开始了他们的唯一一次会话，但没有后续会话，因此不会包括在最终计数中。
输出表按照会话数量和 user_id 降序排序。
*/
WITH Sessions AS (
    SELECT 101 as user_id, '2023-11-06 13:53:42' as session_start, '2023-11-06 14:05:42' as session_end, 375 as session_id, 'Viewer' as session_type UNION ALL
    SELECT 101, '2023-11-22 16:45:21', '2023-11-22 20:39:21', 594, 'Streamer' UNION ALL
    SELECT 102, '2023-11-16 13:23:09', '2023-11-16 16:10:09', 777, 'Streamer' UNION ALL
    SELECT 102, '2023-11-17 13:23:09', '2023-11-17 16:10:09', 778, 'Streamer' UNION ALL
    SELECT 101, '2023-11-20 07:16:06', '2023-11-20 08:33:06', 315, 'Streamer' UNION ALL
    SELECT 104, '2023-11-27 03:10:49', '2023-11-27 03:30:49', 797, 'Viewer' UNION ALL
    SELECT 103, '2023-11-27 03:10:49', '2023-11-27 03:30:49', 798, 'Streamer'
)
select
    distinct
    user_id,
    total_streamer_counts
from (
    select
        user_id,
        first_value(session_type) over(partition by user_id order by session_start) first_session_type,
        sum(if(session_type = 'Streamer', 1, 0)) over(partition by user_id ) total_streamer_counts
    from Sessions t1
     ) t2
where first_session_type = 'Viewer'
and total_streamer_counts != 0;