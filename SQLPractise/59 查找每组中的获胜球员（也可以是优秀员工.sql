/*
`Players` 玩家表
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| player_id   | int     |
| group_id    | int     |
+-------------+---------+
```
player_id 是此表的主键(具有唯一值的列)。
此表的每一行表示每个玩家的组。

`Matches` 赛事表
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| match_id      | int     |
| first_player  | int     |
| second_player | int     |
| first_score   | int     |
| second_score  | int     |
+---------------+---------+
```
match_id 是此表的主键(具有唯一值的列)。
每一行是一场比赛的记录，first_player 和 second_player 表示该场比赛的球员 ID，first_score 和 second_score 分别表示 first_player 和 second_player 的得分。
你可以假设，在每一场比赛中，球员都属于同一组。

每组的获胜者是在组内累积得分最高的选手。如果平局，player_id 最小的选手获胜。
编写解决方案来查找每组中的获胜者。
返回的结果表单 没有顺序要求。
返回结果格式如下所示。

示例 1:

输入:
`Players` 表:
```
+-----------+-----------+
| player_id | group_id  |
+-----------+-----------+
| 15        | 1         |
| 25        | 1         |
| 30        | 1         |
| 45        | 1         |
| 10        | 2         |
| 35        | 2         |
| 50        | 2         |
| 20        | 3         |
| 40        | 3         |
+-----------+-----------+
```
`Matches` 表:
```
+----------+--------------+---------------+-------------+--------------+
| match_id | first_player | second_player | first_score | second_score |
+----------+--------------+---------------+-------------+--------------+
| 1        | 15           | 45            | 3           | 0            |
| 2        | 30           | 25            | 1           | 2            |
| 3        | 30           | 15            | 2           | 0            |
| 4        | 40           | 20            | 5           | 2            |
| 5        | 35           | 50            | 1           | 1            |
+----------+--------------+---------------+-------------+--------------+
```
输出:
```
+-----------+-----------+
| group_id  | player_id |
+-----------+-----------+
| 1         | 15        |
| 2         | 35        |
| 3         | 40        |
+-----------+-----------+
```
*/


-- 方式1 row_number方式
WITH
-- 1. 模拟 Players 表
Players AS (
    SELECT 15 AS player_id, 1 AS group_id UNION ALL
    SELECT 25, 1 UNION ALL
    SELECT 30, 1 UNION ALL
    SELECT 45, 1 UNION ALL
    SELECT 10, 2 UNION ALL
    SELECT 35, 2 UNION ALL
    SELECT 50, 2 UNION ALL
    SELECT 20, 3 UNION ALL
    SELECT 40, 3
),

-- 2. 模拟 Matches 表

Matches AS (
    SELECT 1 AS match_id, 15 AS first_player, 45 AS second_player, 3 AS first_score, 0 AS second_score UNION ALL
    SELECT 2, 30, 25, 1, 2 UNION ALL
    SELECT 3, 30, 15, 2, 0 UNION ALL
    SELECT 4, 40, 20, 5, 2 UNION ALL
    SELECT 5, 35, 50, 1, 1
),
player_scores AS (
    select
        players.group_id,
        players.player_id,
        sum(nvl(tt.score,0)) player_score
    from Players players left join
         (
             -- union all 用于合并两个查询的结果集
             select
                 t1.first_player AS player_id,
                 t1.first_score AS score
             from Matches t1
             union all
             select
                 t2.second_player,
                 t2.second_score
             from Matches t2
         ) tt
         on players.player_id = tt.player_id
    group by players.group_id, players.player_id
)
select
    t2.group_id,
    t2.player_id
from (
         select
             *,
             row_number() over (partition by t1.group_id order by t1.player_score desc ,t1.player_id) as row_num
         from player_scores t1
     ) t2
where t2.row_num = 1;

-- 方式2 采用join的方式
WITH
-- 1. 模拟 Players 表
Players AS (
    SELECT 15 AS player_id, 1 AS group_id UNION ALL
    SELECT 25, 1 UNION ALL
    SELECT 30, 1 UNION ALL
    SELECT 45, 1 UNION ALL
    SELECT 10, 2 UNION ALL
    SELECT 35, 2 UNION ALL
    SELECT 50, 2 UNION ALL
    SELECT 20, 3 UNION ALL
    SELECT 40, 3
),

-- 2. 模拟 Matches 表

Matches AS (
    SELECT 1 AS match_id, 15 AS first_player, 45 AS second_player, 3 AS first_score, 0 AS second_score UNION ALL
    SELECT 2, 30, 25, 1, 2 UNION ALL
    SELECT 3, 30, 15, 2, 0 UNION ALL
    SELECT 4, 40, 20, 5, 2 UNION ALL
    SELECT 5, 35, 50, 1, 1
),
player_scores AS (
    select
        players.group_id,
        players.player_id,
        sum(nvl(tt.score,0)) player_score
    from Players players left join
         (
             select
                 t1.first_player AS player_id,
                 t1.first_score AS score
             from Matches t1
             union all
             select
                 t2.second_player,
                 t2.second_score
             from Matches t2
         ) tt
         on players.player_id = tt.player_id
    group by players.group_id, players.player_id
)
select
    t4.group_id,
    min(t4.player_id) player_id
from (select
          t2.group_id,
          t2.player_id
      from player_scores t2
               inner join (select
                               t1.group_id,
                               max(t1.player_score) max_score
                           from player_scores t1
                           group by t1.group_id
      ) t3
                          on t2.group_id = t3.group_id and t2.player_score = t3.max_score
     ) t4
group by t4.group_id