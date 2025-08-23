
/*
表: `Teams`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| team_id     | int      |
| team_name   | varchar  |
+-------------+----------+
```
`team_id` 是该表具有唯一值的列。
表中的每一行都代表一支独立足球队。

表: `Matches`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| match_id    | int      |
| host_team   | int      |
| guest_team  | int      |
| host_goals  | int      |
| guest_goals | int      |
+-------------+----------+
```
`match_id` 是该表具有唯一值的列。
表中的每一行都代表一场已结束的比赛。
比赛的主客队分别由它们自己的 `id` 表示，他们的进球由 `host_goals` 和 `guest_goals` 分别表示。

你希望在所有比赛之后计算所有球队的比分。积分奖励方式如下:
*   如果球队赢了比赛(即比对手进更多的球)，就得 `3` 分。
*   如果双方打成平手(即，与对方得分相同)，则得 `1` 分。
*   如果球队输掉了比赛(例如，比对手少进球)，就 不得分。

编写解决方案，以找出每个队的 `team_id`, `team_name` 和 `num_points`。
返回的结果根据 `num_points` 降序排序，如果有两队积分相同，那么这两队按 `team_id` 升序排序。
返回结果格式如下。

示例 1:

输入:
`Teams table`:
```
+---------+--------------+
| team_id | team_name    |
+---------+--------------+
| 10      | Leetcode FC  |
| 20      | NewYork FC   |
| 30      | Atlanta FC   |
| 40      | Chicago FC   |
| 50      | Toronto FC   |
+---------+--------------+
```
`Matches table`:
```
+----------+-----------+------------+------------+-------------+
| match_id | host_team | guest_team | host_goals | guest_goals |
+----------+-----------+------------+------------+-------------+
| 1        | 10        | 20         | 3          | 0           |
| 2        | 30        | 10         | 2          | 2           |
| 3        | 10        | 50         | 5          | 1           |
| 4        | 20        | 30         | 1          | 0           |
| 5        | 50        | 30         | 1          | 0           |
+----------+-----------+------------+------------+-------------+
```
输出:
```
+---------+--------------+------------+
| team_id | team_name    | num_points |
+---------+--------------+------------+
| 10      | Leetcode FC  | 7          |
| 20      | NewYork FC   | 3          |
| 50      | Toronto FC   | 3          |
| 30      | Atlanta FC   | 1          |
| 40      | Chicago FC   | 0          |
+---------+--------------+------------+
```

*/
WITH
-- 1. 模拟 Teams 表
Teams AS (
    SELECT 10 AS team_id, 'Leetcode FC' AS team_name UNION ALL
    SELECT 20, 'NewYork FC' UNION ALL
    SELECT 30, 'Atlanta FC' UNION ALL
    SELECT 40, 'Chicago FC' UNION ALL
    SELECT 50, 'Toronto FC'
),

-- 2. 模拟 Matches 表
Matches AS (
    SELECT 1 AS match_id, 10 AS host_team, 20 AS guest_team, 3 AS host_goals, 0 AS guest_goals UNION ALL
    SELECT 2, 30, 10, 2, 2 UNION ALL
    SELECT 3, 10, 50, 5, 1 UNION ALL
    SELECT 4, 20, 30, 1, 0 UNION ALL
    SELECT 5, 50, 30, 1, 0
),
team_scores as (
    select
        case t1.team_judge_number
            when 1 then host_team
            when 2 then guest_team
            else null end as team_id,

        sum(
                case
                    when team_judge_number = 1 and  host_goals > guest_goals then 3
                    when team_judge_number = 1 and  host_goals < guest_goals then 0
                    when team_judge_number = 1 and  host_goals = guest_goals then 1
                    when team_judge_number = 2 and  host_goals < guest_goals then 3
                    when team_judge_number = 2 and  host_goals > guest_goals then 0
                    when team_judge_number = 2 and  host_goals = guest_goals then 1
                    else 0 end
        ) as num_points
    from Matches t0
             lateral view explode(array(1,2)) t1 as team_judge_number
    group by
        case t1.team_judge_number
            when 1 then host_team
            when 2 then guest_team
            else null end
)
select
    t0.team_id,
    t0.team_name,
    nvl(t1.num_points,0) as num_points
from Teams t0
         left join team_scores t1
                   on t0.team_id = t1.team_id

