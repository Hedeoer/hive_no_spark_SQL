/*
表: `Votes`
```
+-----------+---------+
| Column Name| Type    |
+-----------+---------+
| voter     | varchar |
| candidate | varchar |
+-----------+---------+
```
`(voter, candidate)` 是该表的主键 (具有唯一值的列)。
该表的每一行都包含选民及其候选人的姓名。

选举在一个城市进行，每个人都可以投票给 一个或多个 候选人, 也可以选择 不 投票。每个人都有 `1` 票，所以如果他们投票给多个候选人，他们的选票会被平均分配。例如，如果一个人投票给 `2` 个候选人，这些候选人每人获得 `0.5` 张选票。

编写一个解决方案来查找获得最多选票并赢得选举的候选人 `candidate` 。输出 候选人 的姓名，或者如果多个候选人的票数 相等，则输出所有候选人的姓名。
返回按 `candidate` 升序排序 的结果表。
查询结果格式如下所示。

示例 1:

输入:
`Votes table`:
```
+----------+------------+
| voter    | candidate  |
+----------+------------+
| Kathy    | null       |
| Charles  | Ryan       |
| Charles  | Christine  |
| Charles  | Kathy      |
| Benjamin | Christine  |
| Anthony  | Ryan       |
| Edward   | Ryan       |
| Terry    | null       |
| Evelyn   | Kathy      |
| Arthur   | Christine  |
+----------+------------+
```
输出:
```
+-----------+
| candidate |
+-----------+
| Christine |
| Ryan      |
+-----------+
```
解释:
- Kathy 和 Terry 选择不投票, 导致他们的投票被记录为 `0`。 Charles 将他的选票分配给了三位候选人, 相当于每位候选人得到 `0.33` 票。另一方面, Benjamin, Arthur, Anthony, Edward, 和 Evely 各自把票投给了一位候选人。
- Ryan 和 Christine 总共获得了`2.33`票, 而 Kathy 总共获得了 `1.33` 票。
由于 Ryan 和 Christine 获得的票数相等, 我们将按升序显示他们的名字。
*/

WITH
-- 1. 模拟 Votes 表
Votes AS (
    SELECT 'Kathy' AS voter, CAST(null AS STRING) AS candidate UNION ALL
    SELECT 'Charles', 'Ryan' UNION ALL
    SELECT 'Charles', 'Christine' UNION ALL
    SELECT 'Charles', 'Kathy' UNION ALL
    SELECT 'Benjamin', 'Christine' UNION ALL
    SELECT 'Anthony', 'Ryan' UNION ALL
    SELECT 'Edward', 'Ryan' UNION ALL
    SELECT 'Terry', CAST(null AS STRING) UNION ALL
    SELECT 'Evelyn', 'Kathy' UNION ALL
    SELECT 'Arthur', 'Christine'
)
select
    candidate
from (
         -- 排序
         select
             *,
             rank() over (order by total_vote_share desc) as rnk
         from (
                  -- 计算每个候选人的总投票份额
                  select
                      candidate,
                      sum(vote_share) as total_vote_share
                  from (
                           -- 计算每个候选人的投票份额
                           select voter,
                                  candidate,
                                  if(candidate is null , 0, 1) / count(*) over (partition by voter) as vote_share
                           from Votes t1
                       ) t2
                  group by  candidate

              ) t3
     ) t4
where rnk = 1;
