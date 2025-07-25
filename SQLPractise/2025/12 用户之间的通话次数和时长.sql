/*
表: `Calls`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| from_id     | int     |
| to_id       | int     |
| duration    | int     |
+-------------+---------+
```
该表没有主键(具有唯一值的列)，它可能包含重复项。
该表包含 `from_id` 与 `to_id` 间的一次电话的时长。
`from_id != to_id`

编写解决方案，统计每一对用户 (person1, person2) 之间的通话次数和通话总时长，其中 `person1 < person2` 。

以任意顺序返回结果表。
返回结果格式如下示例所示。

示例 1:

输入:
`Calls` 表:
```
+---------+-------+----------+
| from_id | to_id | duration |
+---------+-------+----------+
| 1       | 2     | 59       |
| 2       | 1     | 11       |
| 1       | 3     | 20       |
| 3       | 4     | 100      |
| 3       | 4     | 200      |
| 3       | 4     | 200      |
| 4       | 3     | 499      |
+---------+-------+----------+
```
输出:
```
+---------+---------+-------------+----------------+
| person1 | person2 | call_count  | total_duration |
+---------+---------+-------------+----------------+
| 1       | 2       | 2           | 70             |
| 1       | 3       | 1           | 20             |
| 3       | 4       | 4           | 999            |
+---------+---------+-------------+----------------+
```
解释:
用户 1 和 2 打过 2 次电话, 总时长为 70 (59 + 11)。
用户 1 和 3 打过 1 次电话, 总时长为 20。
用户 3 和 4 打过 4 次电话, 总时长为 999 (100 + 200 + 200 + 499)。


*/
WITH
-- 1. 模拟 Calls 表
Calls AS (
    SELECT 1 AS from_id, 2 AS to_id, 59 AS duration UNION ALL
    SELECT 2, 1, 11 UNION ALL
    SELECT 1, 3, 20 UNION ALL
    SELECT 3, 4, 100 UNION ALL
    SELECT 3, 4, 200 UNION ALL
    SELECT 3, 4, 200 UNION ALL
    SELECT 4, 3, 499
)
/*select
    if(t1.from_id < t1.to_id, t1.from_id, t1.to_id) as person1,
    if(t1.from_id < t1.to_id, t1.to_id, t1.from_id) as person2,
    count(1) as call_count,
    sum(t1.duration) as total_duration
from Calls t1
group by if(t1.from_id < t1.to_id, t1.from_id, t1.to_id),
         if(t1.from_id < t1.to_id, t1.to_id, t1.from_id);*/

-- 方式2
select
    least(t1.from_id,t1.to_id),
    greatest(t1.from_id,t1.to_id),
    count(*) as call_count,
    sum(t1.duration) as total_duration
from Calls t1
group by  least(t1.from_id,t1.to_id),
          greatest(t1.from_id,t1.to_id);