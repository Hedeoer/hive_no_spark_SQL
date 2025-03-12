
-- 求出每个品牌的活动天数，出现日期重叠的算一天
WITH data AS (
    SELECT '华为' AS brand, '2018-08-04' AS begin_date, '2018-08-05' AS end_date  UNION ALL
    SELECT '华为' AS brand, '2018-08-04' AS begin_date, '2020-12-25' AS end_date  UNION ALL
    SELECT '小米' AS brand, '2018-08-15' AS begin_date, '2018-08-20' AS end_date  UNION ALL
    SELECT '小米' AS brand, '2020-01-01' AS begin_date, '2020-01-05' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-01' AS begin_date, '2018-09-05' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-03' AS begin_date, '2018-09-06' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-09' AS begin_date, '2018-09-15' AS end_date
)
select
    brand,
    count(distinct date_add(begin_date,pos)) read_days
from data
lateral view posexplode(split(space(datediff(end_date,begin_date)),'')) tmp as pos,val
group by brand;


-- 求出每个品牌的活动天数，出现日期重叠的算一天
WITH data AS (
    SELECT '华为' AS brand, '2018-08-04' AS begin_date, '2018-08-05' AS end_date  UNION ALL
    SELECT '华为' AS brand, '2018-08-04' AS begin_date, '2020-12-25' AS end_date  UNION ALL
    SELECT '小米' AS brand, '2018-08-15' AS begin_date, '2018-08-20' AS end_date  UNION ALL
    SELECT '小米' AS brand, '2020-01-01' AS begin_date, '2020-01-05' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-01' AS begin_date, '2018-09-05' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-03' AS begin_date, '2018-09-06' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-09' AS begin_date, '2018-09-15' AS end_date
),
    pre_max_end_date as (
        select brand,
               to_date(begin_date) `begin_date`,
               to_date(end_date) `end_date`,
               max(end_date) over(partition by brand order by begin_date rows between unbounded preceding and 1 preceding) pre_max_end_date
        from data
    ),
    group_date as (
        select
            brand,
            begin_date,
            end_date,
            pre_max_end_date,
            sum(is_new) over(partition by brand order by begin_date) group_id
        from (
            select brand,
                   begin_date,
                   end_date,
                   pre_max_end_date,
                   -- 如果开始时间小于等于前一个最大结束时间，则为日期重叠，标记为相同组，记为0，否则为1
                   case
                       when pre_max_end_date is null then 0
                       when begin_date <= pre_max_end_date then 0
                       else 1 end is_new
            from pre_max_end_date
             ) t
    ),
    -- 按照分组合并重叠区间
    merge_group as (
        select
            brand,
            group_id,
            min(begin_date) begin_date,
            max(end_date) end_date
        from group_date
        group by brand,group_id
    )
select
    brand,
    sum(datediff(end_date,begin_date)+1) read_days
from merge_group
group by brand;

-- 方式一
-- 直播间用户在线时长计算，有登录时间重叠的算一次时长
-- 1.炸裂登录区间，处理登出时间为null的情况
-- 2.统计每个user_id在不同room_id的在线时长
-- 3.排序求前五名
WITH user_live_sessions AS (
    -- 直播间101的用户
    SELECT 101 as room_id, 1001 as user_id, '2023-04-10 18:00:00' as login_time, '2023-04-10 19:30:00' as logout_time UNION ALL
    SELECT 101, 1001, '2023-04-10 20:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 101, 1002, '2023-04-10 18:30:00', '2023-04-10 20:45:00' UNION ALL
    SELECT 101, 1003, '2023-04-10 19:00:00', '2023-04-10 22:00:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 17:30:00', '2023-04-10 18:45:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 19:15:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 101, 1005, '2023-04-10 18:15:00', '2023-04-10 21:45:00' UNION ALL
    SELECT 101, 1006, '2023-04-10 18:45:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 101, 1007, '2023-04-10 19:30:00', '2023-04-10 21:30:00' UNION ALL

    -- 直播间102的用户
    SELECT 102, 1001, '2023-04-10 17:00:00', '2023-04-10 18:00:00' UNION ALL
    SELECT 102, 1002, '2023-04-10 17:30:00', '2023-04-10 19:00:00' UNION ALL
    SELECT 102, 1008, '2023-04-10 18:00:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 102, 1009, '2023-04-10 18:30:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 19:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 21:30:00', '2023-04-10 22:15:00' UNION ALL

    -- 异常记录（登出时间为NULL）
    SELECT 101, 1008, '2023-04-10 19:45:00', cast(NULL as string) UNION ALL
    SELECT 102, 1005, '2023-04-10 20:00:00', cast(NULL as string)
),
 explode_sessions as (
     select
         user_id,
         room_id,
         unix_timestamp(login_time) + tmp.pos as login_time
     from user_live_sessions
    lateral view posexplode(split(space(cast((coalesce(unix_timestamp(logout_time), unix_timestamp()) - unix_timestamp(login_time)) as int)),'')) tmp as pos,val
     group by user_id, room_id, unix_timestamp(login_time) + tmp.pos
 ),
    agg_onlin_time as (
        select
            user_id,
            room_id,
            max(login_time) - min(login_time) as online_time
        from explode_sessions
        group by user_id, room_id
    )
select
    room_id,
    online_time,
    rank_id
from (
    select
        user_id,
        room_id,
        online_time,
        rank() over(partition by room_id order by online_time desc) as rank_id
    from agg_onlin_time
        ) t
where rank_id <= 5;

-- 方式二 优化重复时间段的计算
/*
同一个用户在相同的直播间观看记录存在时间重叠，比如用户A：10:00 - 11:00 观看了直播间1，有一条记录，现有另一个记录用户A：10:30 - 11:30 观看了直播间1，那个统计用户A在直播间总共的观看时长为90分钟

核心处理逻辑
标记所有时间点：
将每个用户在每个直播间的所有登入登出时间标记为离散点
登入点标记为+1，登出点标记为-1

计算活跃状态：
按用户ID和房间ID分组，对时间点排序
使用窗口函数计算累计活跃状态
活跃状态>0表示用户在线

合并重叠时间段：
只计算活跃状态>0的相邻时间点之间的时长
自然处理了重叠时间问题
*/
WITH user_live_sessions AS (
     -- 直播间101的用户
    SELECT 101 as room_id, 1001 as user_id, '2023-04-10 18:00:00' as login_time, '2023-04-10 19:30:00' as logout_time UNION ALL
    SELECT 101, 1001, '2023-04-10 20:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 101, 1002, '2023-04-10 18:30:00', '2023-04-10 20:45:00' UNION ALL
    SELECT 101, 1003, '2023-04-10 19:00:00', '2023-04-10 22:00:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 17:30:00', '2023-04-10 18:45:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 19:15:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 101, 1005, '2023-04-10 18:15:00', '2023-04-10 21:45:00' UNION ALL
    SELECT 101, 1006, '2023-04-10 18:45:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 101, 1007, '2023-04-10 19:30:00', '2023-04-10 21:30:00' UNION ALL

    -- 直播间102的用户
    SELECT 102, 1001, '2023-04-10 17:00:00', '2023-04-10 18:00:00' UNION ALL
    SELECT 102, 1002, '2023-04-10 17:30:00', '2023-04-10 19:00:00' UNION ALL
    SELECT 102, 1008, '2023-04-10 18:00:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 102, 1009, '2023-04-10 18:30:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 19:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 21:30:00', '2023-04-10 22:15:00' UNION ALL

    -- 异常记录（登出时间为NULL）
    SELECT 101, 1008, '2023-04-10 19:45:00', cast(NULL as string) UNION ALL
    SELECT 102, 1005, '2023-04-10 20:00:00', cast(NULL as string)
),
-- 步骤1: 标记用户在房间的登入登出点
user_room_time_points AS (
    -- 登入点，标记为1
    SELECT
        user_id,
        room_id,
        unix_timestamp(login_time) AS time_point,
        1 AS flag
    FROM user_live_sessions


    UNION ALL

    -- 登出点，标记为-1
    SELECT
        user_id,
        room_id,
        COALESCE(unix_timestamp(logout_time), unix_timestamp('2023-04-11 00:00:00')) AS time_point,
        -1 AS flag
    FROM user_live_sessions

),
-- 步骤2: 计算每个用户在每个房间的活跃状态
user_room_segments AS (
    SELECT
        user_id,
        room_id,
        time_point,
        -- 计算每个时间点后用户是否仍在线（累计标记值）
        SUM(flag) OVER (
            PARTITION BY user_id, room_id
            ORDER BY time_point
        ) AS active_status,
        -- 获取下一个时间点用于计算区间长度
        LEAD(time_point) OVER (
            PARTITION BY user_id, room_id
            ORDER BY time_point
        ) AS next_time_point
    FROM user_room_time_points
),
-- 步骤3: 计算每个用户在每个房间的有效观看时长
user_room_active_time AS (
    SELECT
        user_id,
        room_id,
        -- 只统计用户在线的时间段
        SUM(
            CASE
                WHEN active_status > 0 AND next_time_point IS NOT NULL
                THEN next_time_point - time_point
                ELSE 0
            END
        ) AS total_active_time
    FROM user_room_segments
    GROUP BY user_id, room_id
),
-- 步骤5: 对用户按观看时长排名
final_results AS (
    select
        user_id,
        room_id,
        total_active_time as online_time,
        rank() over (partition by room_id order by total_active_time desc) as rank_id
    from user_room_active_time
)
-- 步骤6: 获取每个直播间前5名用户
SELECT
    room_id,
    user_id,
    online_time,
    rank_id
FROM final_results
WHERE rank_id <= 5
ORDER BY room_id, rank_id;


-- 方式三
/*
1.时间区间分组：将重叠或相邻的时间区间分到同一组
2.合并区间：针对每组取最早的开始时间和最晚的结束时间
3.计算总时长：将合并后的不重叠区间时长相加
*/
WITH user_live_sessions AS (
    SELECT 101 as room_id, 1001 as user_id, '2023-04-10 18:00:00' as login_time, '2023-04-10 19:30:00' as logout_time UNION ALL
    SELECT 101, 1001, '2023-04-10 20:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 101, 1002, '2023-04-10 18:30:00', '2023-04-10 20:45:00' UNION ALL
    SELECT 101, 1003, '2023-04-10 19:00:00', '2023-04-10 22:00:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 17:30:00', '2023-04-10 18:45:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 19:15:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 101, 1005, '2023-04-10 18:15:00', '2023-04-10 21:45:00' UNION ALL
    SELECT 101, 1006, '2023-04-10 18:45:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 101, 1007, '2023-04-10 19:30:00', '2023-04-10 21:30:00' UNION ALL

    -- 直播间102的用户
    SELECT 102, 1001, '2023-04-10 17:00:00', '2023-04-10 18:00:00' UNION ALL
    SELECT 102, 1002, '2023-04-10 17:30:00', '2023-04-10 19:00:00' UNION ALL
    SELECT 102, 1008, '2023-04-10 18:00:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 102, 1009, '2023-04-10 18:30:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 19:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 21:30:00', '2023-04-10 22:15:00' UNION ALL

    -- 异常记录（登出时间为NULL）
    SELECT 101, 1008, '2023-04-10 19:45:00', cast(NULL as string) UNION ALL
    SELECT 102, 1005, '2023-04-10 20:00:00', cast(NULL as string)
),
    user_session as (
        select
            user_id,
            room_id,
            unix_timestamp(login_time) as start_time,
            coalesce(unix_timestamp(logout_time), unix_timestamp('2023-04-11 00:00:00')) as end_time
        from user_live_sessions
    ),
    -- 用户在直播间的之前的最大end_time
    user_prev_max_end_time as (
        select user_id,
               room_id,
               start_time,
               end_time,
               max(end_time) over (partition by user_id, room_id order by start_time rows between unbounded preceding and 1 preceding) as prev_max_end_time
        from user_session
    ),
    -- 用户观看时间区间分组
    user_watch_session_group as (
     select user_id,
            room_id,
            start_time,
            end_time,
            prev_max_end_time,
            sum(case
                when prev_max_end_time is null then 0
                when start_time >= prev_max_end_time then 0
                else 1 end
            ) over(
                partition by user_id, room_id
                order by start_time
                ) group_id
     from user_prev_max_end_time
    ),
    -- 用户观看时间区间分组内统计观看时长
    caulate_watch_group_time as (
     select
         user_id,
         room_id,
         group_id,
         max(end_time) - min(start_time) as group_watch_time
     from user_watch_session_group
     group by user_id,
              room_id,
              group_id
    ),
    caulate_watch_time as (
        select
            user_id,
            room_id,
            sum(group_watch_time) as total_watch_time
        from caulate_watch_group_time
        group by user_id,
                 room_id
    )
select
    room_id,
    user_id,
    total_watch_time online_time,
    rank_id
from (
    select
        *,
        rank() over (partition by room_id order by total_watch_time desc) as rank_id
    from caulate_watch_time
    ) t
where rank_id <= 5
order by room_id, rank_id;
