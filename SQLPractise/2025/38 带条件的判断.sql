/*
表: `Teams`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| player_id   | int     |
| team_name   | varchar |
+-------------+---------+
```
`player_id` 是这张表的唯一主键。
每一行包含队员的唯一标识以及在该场比赛中参赛的某支队伍的名称。

表: `Passes`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| pass_from   | int     |
| time_stamp  | varchar |
| pass_to     | int     |
+-------------+---------+
```
`(pass_from, time_stamp)` 是这张表的主键。
`pass_from` 是指向 `Teams` 表 `player_id` 字段的外键。
每一行代表比赛期间的一次传球，`time_stamp` 表示传球发生的分钟时间 (`00:00-90:00`)，`pass_to` 表示 `player_id` 对应队员接球。

编写一个解决方案来计算每支球队 在上半场的优势得分。规则如下:
一场比赛分为两个半场: 上半场 (`00:00-45:00` 分钟) 和 下半场 (`45:01-90:00` 分钟)
优势得分是根据成功和截获的传球来计算的: 当 `pass_to` 是 同球队 的队员: `+1` 分
当 `pass_to` 是 对方球队 的队员 (截获) : `-1` 分
更高的优势得分表明传球表现更好
返回结果表以 `team_name` 和 `half_number` 升序 排序。
结果格式如下所示。

示例:
输入:
`Teams` 表:
```
+-----------+-----------+
| player_id | team_name |
+-----------+-----------+
| 1         | Arsenal   |
| 2         | Arsenal   |
| 3         | Arsenal   |
| 4         | Chelsea   |
| 5         | Chelsea   |
| 6         | Chelsea   |
+-----------+-----------+
```
`Passes` 表:
```
+-----------+------------+---------+
| pass_from | time_stamp | pass_to |
+-----------+------------+---------+
| 1         | 00:15      | 2       |
| 2         | 00:45      | 3       |
| 3         | 01:15      | 1       |
| 4         | 00:30      | 1       |
| 2         | 46:00      | 3       |
| 3         | 46:15      | 4       |
| 1         | 46:45      | 2       |
| 5         | 46:30      | 6       |
+-----------+------------+---------+
```
输出:
```
+-----------+-------------+-----------+
| team_name | half_number | dominance |
+-----------+-------------+-----------+
| Arsenal   | 1           | 3         |
| Arsenal   | 2           | 1         |
| Chelsea   | 1           | -1        |
| Chelsea   | 2           | 1         |
+-----------+-------------+-----------+
```
解释:
前半场 (00:00-45:00) : 阿森纳的传球: 1 -> 2 (00:15): 成功传球 (+1)
2 -> 3 (00:45): 成功传球 (+1)
3 -> 1 (01:15): 成功传球 (+1)
切尔西的传球: 4 -> 1 (00:30): 被阿森纳截获 (-1)
下半场 (45:01-90:00) : 阿森纳的传球: 2 -> 3 (46:00): 成功传球 (+1)
3 -> 4 (46:15): 被切尔西截获 (-1)
1 -> 2 (46:45): 成功传球 (+1)
切尔西的传球: 5 -> 6 (46:30): 成功传球 (+1)
结果以 `team_name` 和 `half_number` 升序排序
*/

/*
1. 如何判断上下场？
2. 需求分析，按照正常的业务场景，一次传球只会有一个获胜方；比如同队球员传球一次，该队可以计1分；A对球员传球被B对球员截断一次，B队可以计1分，A队不计分。
回到题目的需求，A对球员传球被B对球员截断一次，B队可以计1分，A队计-1分；A对球员传球被A队球员一次，A队计1分，B队计0分，可能出现球队得分为负数的情况。
*/
WITH
-- 1. 模拟 Teams 表
Teams AS (
    SELECT 1 AS player_id, 'Arsenal' AS team_name UNION ALL
    SELECT 2, 'Arsenal' UNION ALL
    SELECT 3, 'Arsenal' UNION ALL
    SELECT 4, 'Chelsea' UNION ALL
    SELECT 5, 'Chelsea' UNION ALL
    SELECT 6, 'Chelsea'
),

-- 2. 模拟 Passes 表
Passes AS (
    SELECT 1 AS pass_from, '00:15' AS time_stamp, 2 AS pass_to UNION ALL
    SELECT 2, '00:45', 3 UNION ALL
    SELECT 3, '01:15', 1 UNION ALL
    SELECT 4, '00:30', 1 UNION ALL
    SELECT 2, '46:00', 3 UNION ALL
    SELECT 3, '46:15', 4 UNION ALL
    SELECT 1, '46:45', 2 UNION ALL
    SELECT 5, '46:30', 6
),
/*
    -- 正常的业务场景处理，一次传球只会有一个获胜方
    team_states as (
        select
            t2.team_name as first_team ,
            t1.time_stamp,
            t3.team_name as second_team,
            if(t2.team_name = t3.team_name, t2.team_name, t3.team_name) as winner_team
        from Passes t1
                 left join Teams t2
                           on t1.pass_from  = t2.player_id
                 left join Teams t3
                           on t1.pass_to = t3.player_id

    )
select
    team_name,
    if(time_stamp <= '45:00', 1, 2) half_number,
    sum(score) as dominance
from (
         select
             team_name,
             time_stamp,
             score
         from (
                  select first_team as team_name,time_stamp,if(first_team != winner_team, 0,1) as  score from team_states t1
                  union all
                  select second_team,time_stamp,if(second_team != winner_team, 0,1) from team_states t2
              ) t3
         group by team_name,time_stamp,score
     ) t4
group by team_name,
         if(time_stamp <= '45:00', 1, 2)
order by team_name,half_number;*/

-- 按照 题目需求处理，一次传球可能会有一个获胜方和一个失败方
team_states as (
    select
        t2.team_name as first_team ,
        t1.time_stamp,
        t3.team_name as second_team,
        if(t2.team_name = t3.team_name, t2.team_name, t3.team_name) as winner_team
    from Passes t1
             left join Teams t2
                       on t1.pass_from  = t2.player_id
             left join Teams t3
                       on t1.pass_to = t3.player_id
)
select
    team_name,
    if(time_stamp <= '45:00', 1, 2) half_number,
    sum(score) as dominance
from (
         select
             team_name,
             time_stamp,
             score
         from (
                  select first_team as team_name,time_stamp,if(first_team != winner_team, -1,1) as  score from team_states t1
                  union all
                  select second_team,time_stamp,if(second_team != winner_team, -1,1) from team_states t2
              ) t3
         group by team_name,time_stamp,score
     ) t4
group by team_name,
         if(time_stamp <= '45:00', 1, 2)
order by team_name,half_number;


