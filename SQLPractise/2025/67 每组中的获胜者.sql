


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
`player_id` 是此表的主键(具有唯一值的列)。
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
`match_id` 是此表的主键(具有唯一值的列)。
每一行是一场比赛的记录, `first_player` 和 `second_player` 表示该场比赛的球员 ID。
`first_score` 和 `second_score` 分别表示 `first_player` 和 `second_player` 的得分。
你可以假设，在每一场比赛中，球员都属于同一组。

每组的获胜者是在组内累积得分最高的选手。如果平局, `player_id` 最小的选手获胜。
编写解决方案来查找每组中的获胜者。
返回的结果表单 没有顺序要求。
返回结果格式如下所示。

示例 1:

输入:
`Players` 表:
```
+-----------+----------+
| player_id | group_id |
+-----------+----------+
| 15        | 1        |
| 25        | 1        |
| 30        | 1        |
| 45        | 1        |
| 10        | 2        |
| 35        | 2        |
| 50        | 2        |
| 20        | 3        |
| 40        | 3        |
+-----------+----------+
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
+----------+-----------+
| group_id | player_id |
+----------+-----------+
| 1        | 15        |
| 2        | 35        |
| 3        | 40        |
+----------+-----------+
```

*/

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
score_situation as (
    select
        case t1.player_id
            when 1 then first_player
            when 2 then second_player
            else null end player_id,
        sum(
                case t1.player_id
                    when 1 then first_score
                    when 2 then second_score
                    else 0 end
        ) as player_total_scores
    from Matches t0
             lateral view explode(array(1,2)) t1 as player_id
    group by case t1.player_id
                 when 1 then first_player
                 when 2 then second_player
                 else null end
)
select
    group_id,
    player_id
from (
         select
             t2.group_id,
             t1.player_id,
             row_number() over (partition by t2.group_id order by t1.player_total_scores desc,t1.player_id asc) order_number
         from score_situation t1
                  left join Players t2
                            on t1.player_id = t2.player_id
     ) t3
where order_number = 1;