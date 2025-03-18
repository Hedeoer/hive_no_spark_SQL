
/*
Table: activity

+------------+---------+
| Column Name | Type   |
+------------+---------+
| player_id  | int     |
| device_id  | int     |
| event_date | date    |
| games_played | int   |
+------------+---------+
(player_id, event_date) 是此表的主键（具有唯一值的列组合）。
这张表显示了某些游戏的玩家的活动情况。
每一行是一个玩家的记录，他在某一天使用某个设备注销之前登录并玩了很多游戏（可能是0）。
编写解决方案，报告在首次登录的第二天再次登录的玩家的比率，四舍五入到小数点后两位。换句话说，你需要计
算从首次登录日期开始至少连续两天登录的玩家的数量，然后除以玩家总数。
结果格式如下所示：
输出 1:
输入:
activity table:
+----------+--------+-------------+--------------+
| player_id | device_id | event_date | games_played |
+----------+--------+-------------+--------------+
| 1 | 2 | 2016-03-01 | 5 |
| 1 | 2 | 2016-03-02 | 6 |
| 2 | 3 | 2017-06-25 | 1 |
| 3 | 1 | 2016-03-03 | 0 |
| 3 | 4 | 2018-07-03 | 5 |
+----------+--------+-------------+--------------+
输出:
+-----------+
| fraction  |
+-----------+
| 0.33      |
+-----------+
解释：
因为 ID 为 1 的玩家在第一天登录后才重新登录，所以答案是 1/3 = 0.33

*/

WITH activity AS (
    SELECT 1 AS player_id, 2 AS device_id, '2016-03-01' AS event_date, 5 AS games_played
    UNION ALL
    SELECT 1, 2, '2016-03-02', 6
    UNION ALL
    SELECT 2, 3, '2017-06-25', 1
    UNION ALL
    SELECT 3, 1, '2016-03-03', 0
    UNION ALL
    SELECT 3, 4, '2018-07-03', 5
),
    continue_login AS (
        select player_id,
               device_id,
               to_date(event_date) event_date,
               games_played,
               date_sub(to_date(event_date),row_number() over (partition by player_id order by event_date)) AS group_date,
               min(to_date(event_date)) over () AS first_date
        from activity
    ),
    three_days_events as (
        select
            1 flag,
            count(1) event_count
        from continue_login
        where event_date >= first_date and event_date <= date_add(first_date,2)
    ),
    continue_events_2timsover as (
        select
            count(distinct player_id) distinct_player_count,
            1 flag
        from (
            select
                player_id,
                count(1) event_continus_count
            from continue_login
            where event_date >= first_date and event_date <= date_add(first_date,2)
            group by player_id,group_date
            having count(1) >= 2
             ) t1
    )
select
    t2.distinct_player_count / t1.event_count fraction
from three_days_events t1
join continue_events_2timsover t2
on t1.flag = t2.flag;


