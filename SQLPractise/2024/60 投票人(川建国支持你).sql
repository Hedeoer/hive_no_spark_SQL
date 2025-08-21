
/*
 投票人(川建国支持你)
表: `Candidate`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| name        | varchar |
+-------------+---------+
```
id 是该表中具有唯一值的列
该表的每一行都包含关于候选对象的id和名称的信息。

表: `Vote`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| candidateId | int     |
+-------------+---------+
```
id 是自动递增的主键(具有唯一值的列)。
candidateId是id来自Candidate表的外键(reference 列)。
该表的每一行决定了在选举中获得第1张选票的候选人。

编写解决方案来报告获胜候选人的名字(即获得最多选票的候选人)。
生成的测试用例保证 只有一个候选人赢得 选举。
返回结果格式如下所示。

示例 1:

输入:
`Candidate table`:
```
+----+------+
| id | name |
+----+------+
| 1  | A    |
| 2  | B    |
| 3  | C    |
| 4  | D    |
| 5  | E    |
+----+------+
```
`Vote table`:
```
+----+-------------+
| id | candidateId |
+----+-------------+
| 1  | 2           |
| 2  | 4           |
| 3  | 3           |
| 4  | 2           |
| 5  | 5           |
+----+-------------+
```
输出:
```
+------+
| name |
+------+
| B    |
+------+
```
解释:
候选人B有2票。候选人C、D、E各有1票。
获胜者是候选人B。
*/

WITH
-- 1. 模拟 Candidate 表
Candidate AS (
    SELECT 1 AS id, 'A' AS name UNION ALL
    SELECT 2, 'B' UNION ALL
    SELECT 3, 'C' UNION ALL
    SELECT 4, 'D' UNION ALL
    SELECT 5, 'E'
),

-- 2. 模拟 Vote 表
Vote AS (
    SELECT 1 AS id, 2 AS candidateId UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 3, 3 UNION ALL
    SELECT 4, 2 UNION ALL
    SELECT 5, 5
)

-- 方式1
/*select
    name
from (
    select
        t3.name,
        row_number() over (order by voteCount desc) as rank
    from (
             select
                 t1.candidateId,
                 t2.name,
                 count(1) as voteCount
             from Vote t1
                      left join Candidate t2
                                on t1.candidateId = t2.id
             group by t1.candidateId,t2.name
         ) t3
    )t4
where t4.rank = 1;*/

/*
-- 方式2
select
    t3.name
from (
         select
             t1.candidateId
         from Vote t1
         group by t1.candidateId
         order by count(id) desc
         limit 1
     ) t2
left join Candidate t3
on t2.candidateId = t3.id

*/

-- 方式3
select
    t3.name
from Candidate t3
         left join (
    select
        t2.candidateId,
        row_number() over (order by t2.voteCount desc) as rank
    from (
        select
        t1.candidateId,
        count(1) as voteCount
        from Vote t1
        group by t1.candidateId
        ) t2
) t4
                   on t3.id = t4.candidateId
where t4.rank = 1;
