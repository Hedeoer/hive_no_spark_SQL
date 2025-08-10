/*
Table: `Activity`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| player_id    | int     |
| device_id    | int     |
| event_date   | date    |
| games_played | int     |
+--------------+---------+
```
`(player_id, event_date)` 是此表的主键 (具有唯一值的列的组合)。
这张表显示了某些游戏的玩家的活动情况。
每一行是一个玩家的记录，他在某一天使用某个设备注销之前登录并玩了很多游戏 (可能是 `0`)。
编写解决方案，报告在首次登录的第二天再次登录的玩家的 比率，四舍五入到小数点后两位。换句话说，你需要计算从首次登录日期开始至少连续两天登录的玩家的数量，然后除以玩家总数。
结果格式如下所示:

示例 1:

输入:
`Activity table`:
```
+-----------+-----------+------------+--------------+
| player_id | device_id | event_date | games_played |
+-----------+-----------+------------+--------------+
| 1         | 2         | 2016-03-01 | 5            |
| 1         | 2         | 2016-03-02 | 6            |
| 2         | 3         | 2017-06-25 | 1            |
| 3         | 1         | 2016-03-02 | 0            |
| 3         | 4         | 2018-07-03 | 5            |
+-----------+-----------+------------+--------------+
```
输出:
```
+-----------+
| fraction  |
+-----------+
| 0.33      |
+-----------+
```
解释:
只有 ID 为 1 的玩家在第一天登录后才重新登录, 所以答案是 1/3 = 0.33


*/

WITH
-- 1. 模拟 Activity 表
Activity AS (
    SELECT 1 AS player_id, 2 AS device_id, CAST('2016-03-01' AS DATE) AS event_date, 5 AS games_played UNION ALL
    SELECT 1, 2, CAST('2016-03-02' AS DATE), 6 UNION ALL
    SELECT 2, 3, CAST('2017-06-25' AS DATE), 1 UNION ALL
    SELECT 3, 1, CAST('2016-03-02' AS DATE), 0 UNION ALL
    SELECT 3, 4, CAST('2018-07-03' AS DATE), 5
),
user_daily_activity AS (
    select
        player_id,
        event_date
    from Activity t1
    group by player_id, event_date
),
registered_activity as (
    select player_id,
           event_date
    from (
             select player_id,
                    event_date,
                    row_number() over (partition by player_id order by event_date) as rn
             from user_daily_activity
         ) t1
    where rn = 1
)
/*
select
    round(count(distinct if(date_add(t1.event_date,1) = t2.event_date,t2.event_date,null)) / count(distinct t1.player_id),2) as fraction
from registered_activity t1
         -- 首次登录的玩家 与 每日登录表链接
         left join user_daily_activity t2
on t1.player_id = t2.player_id and t1.event_date < t2.event_date;*/

select
    round(count(distinct t2.player_id) / count(distinct t1.player_id),2) as fraction
from registered_activity t1
         -- 首次登录的玩家 与 每日登录表链接
         left join user_daily_activity t2
                   on t1.player_id = t2.player_id and date_add(t1.event_date, 1) = t2.event_date

