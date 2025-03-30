/*
# 题目33 选手连胜数

```sql
表：Matches

+---------------+------+
| Column Name   | Type |
+---------------+------+
| player_id     | int  |
| match_day     | date |
| result        | enum |
+---------------+------+
(player_id, match_day) 是该表的主键 (具有唯一值的列的组合)。
每一行包括了: 参赛选手 id, 比赛时间, 比赛结果。
比赛结果 (result) 的枚举类型为 ('Win', 'Draw', 'Lose')。
选手的 连胜数 是指该选手获胜的次数, 且这有胜平局紧密相连的情况下。
题目解决方案是计算每个参赛选手最多的连胜数。
结果请按如下 选手id 返回。

示例 1:

输入：
Matches 表:
+------------+------------+---------+
| player_id  | match_day  | result  |
+------------+------------+---------+
| 1          | 2022-01-17 | Win     |
| 1          | 2022-01-18 | Win     |
| 1          | 2022-01-25 | Win     |
| 1          | 2022-01-31 | Draw    |
| 1          | 2022-02-08 | Win     |
| 2          | 2022-02-06 | Lose    |
| 2          | 2022-02-08 | Lose    |
| 3          | 2022-03-30 | Win     |
+------------+------------+---------+

输出：
+------------+----------------+
| player_id  | longest_streak |
+------------+----------------+
| 1          | 3              |
| 2          | 0              |
| 3          | 1              |
+------------+----------------+

解释：
Player 1:
从 2022-01-17 到 2022-01-25, player 1连续赢了三场比赛。
2022-01-31, player 1 平局。
2022-02-08, player 1 赢了一场比赛。
最多连续赢了三场比赛。

Player 2:
从 2022-02-06 到 2022-02-08, player 2 输了两场比赛。
最多连续赢了0场比赛。

Player 3:
2022-03-30, player 3 赢了一场比赛。
最多连续赢了一场比赛。
```


*/
with Matches as (
  select 1 as player_id, '2022-01-17' as match_day, 'Win' as result union all
  select 1 as player_id, '2022-01-18' as match_day, 'Win' as result union all
  select 1 as player_id, '2022-01-25' as match_day, 'Win' as result union all
  select 1 as player_id, '2022-01-31' as match_day, 'Draw' as result union all
  select 1 as player_id, '2022-02-08' as match_day, 'Win' as result union all
  select 2 as player_id, '2022-02-06' as match_day, 'Lose' as result union all
  select 2 as player_id, '2022-02-08' as match_day, 'Lose' as result union all
  select 3 as player_id, '2022-03-30' as match_day, 'Win' as result
),
    continus_wins as (
        select
            player_id,
            new_day,
            count(1) continus_days,
            row_number() over (partition by player_id order by count(1) desc) rn
        from (
            select player_id,
                   to_date(match_day) match_day,
                   date_sub(to_date(match_day),row_number() over (partition by player_id order by to_date(match_day))) new_day
            from Matches t1
            where result = 'Win'
             ) t1
        group by player_id,new_day
    )
select
    t2.player_id,
    coalesce(t3.continus_days ,0) longest_streak
from (
    select
        player_id
    from Matches
    group by player_id
     ) t2
left join continus_wins t3
on t2.player_id = t3.player_id and t3.rn = 1;