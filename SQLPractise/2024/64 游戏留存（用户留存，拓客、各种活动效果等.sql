
/*
表: `Activity`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| player_id     | int     |
| device_id     | int     |
| event_date    | date    |
| games_played  | int     |
+---------------+---------+
```
(player_id, event_date) 是此表的主键(具有唯一值的列的组合)
这张表显示了某些游戏的玩家的活动情况
每一行表示一个玩家的记录，在某一天使用某个设备注销之前，登录并玩了很多游戏（可能是 0）
玩家的安装日期 定义为该玩家的第一个登录日。
我们将日期 x 的 第一天留存率 定义为：假定安装日期为 x 的玩家的数量为 N ，其中在 X 之后的一天重新登录的玩家数量为 M，M/N 就是第一天留存率，四舍五入到小数点后两位。

编写解决方案，报告所有安装日期，当天安装游戏的玩家数量和玩家的 第一天留存率。
以 任意顺序 返回结果表。
结果格式如下所示。

示例 1:

输入:
`Activity` 表:
```
+-----------+-----------+------------+--------------+
| player_id | device_id | event_date | games_played |
+-----------+-----------+------------+--------------+
| 1         | 2         | 2016-03-01 | 5            |
| 1         | 2         | 2016-03-02 | 6            |
| 2         | 3         | 2017-06-25 | 1            |
| 3         | 1         | 2016-03-01 | 0            |
| 3         | 4         | 2016-07-03 | 5            |
+-----------+-----------+------------+--------------+
```
输出:
```
+------------+----------+----------------+
| install_dt | installs | Day1_retention |
+------------+----------+----------------+
| 2016-03-01 | 2        | 0.50           |
| 2017-06-25 | 1        | 0.00           |
+------------+----------+----------------+
```
解释:
玩家 1 和 3 在 2016-03-01 安装了游戏，但只有玩家 1 在 2016-03-02 重新登录，所以 2016-03-01 的第一天留存率是 1/2=0.50
玩家 2 在 2017-06-25 安装了游戏，但在 2017-06-26 没有重新登录，因此 2017-06-25 的第一天留存率为 0/1=0.00


*/

WITH
-- 1. 模拟 Activity 表
Activity AS (
    SELECT 1 AS player_id, 2 AS device_id, CAST('2016-03-01' AS DATE) AS event_date, 5 AS games_played UNION ALL
    SELECT 1, 2, CAST('2016-03-02' AS DATE), 6 UNION ALL
    SELECT 2, 3, CAST('2017-06-25' AS DATE), 1 UNION ALL
    SELECT 3, 1, CAST('2016-03-01' AS DATE), 0 UNION ALL
    SELECT 3, 4, CAST('2016-07-03' AS DATE), 5
),
/*
1. 每日注册的玩家有哪些？
2. 每日登录的玩家有哪些？
3. 每日登录的玩家中，有哪些是已经一天前注册的玩家？
*/
registered_players as (
    select
        player_id,
        min(event_date) as install_dt
    from Activity t1
    group by player_id
),
daily_logins as (
    select
        player_id,
        event_date
    from Activity t2
    group by player_id, event_date
),
day1_retention as (
    select
        t1.install_dt,
        count(distinct t1.player_id) as installs,
        round(count(distinct t2.player_id) * 1.0 / count(distinct t1.player_id),2) as Day1_retention
    from registered_players t1
             left join daily_logins t2 on t1.player_id = t2.player_id and date_add(t1.install_dt, 1) = t2.event_date
    group by t1.install_dt
) select * from day1_retention;

