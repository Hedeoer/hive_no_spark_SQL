/*

事件表: `Events`
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| business_id   | int     |
| event_type    | varchar |
| occurrences   | int     |
+---------------+---------+
```
(business_id, event_type) 是这个表的主键 (具有唯一值的列的组合)。
表中的每一行记录了某种类型的事件在某些业务中多次发生的信息。
平均活动 是指有特定 event_type 的具有该事件的所有公司的 occurrences 的均值。
活跃业务 是指具有 多个 event_type 的业务, 它们的 occurrences 严格大于 该事件的平均活动次数。
写一个解决方案, 找到所有 活跃业务。
以 任意顺序 返回结果表。
结果格式如下所示。

示例 1:

输入:
`Events table`:
```
+-------------+------------+-------------+
| business_id | event_type | occurrences |
+-------------+------------+-------------+
| 1           | reviews    | 7           |
| 3           | reviews    | 3           |
| 1           | ads        | 11          |
| 2           | ads        | 7           |
| 3           | ads        | 6           |
| 1           | page views | 3           |
| 2           | page views | 12          |
+-------------+------------+-------------+
```
输出:
```
+-------------+
| business_id |
+-------------+
| 1           |
+-------------+
```
解释:
每次活动的平均活动可计算如下:
- 'reviews': (7+3)/2 = 5
- 'ads': (11+7+6)/3 = 8
- 'page views': (3+12)/2 = 7.5
id=1 的业务有 7 个 'reviews' 事件(多于 5 个)和 11 个 'ads' 事件(多于 8 个), 所以它是一个活跃的业务。
*/

WITH
-- 1. 模拟 Events 表
Events AS (
    SELECT 1 AS business_id, 'reviews' AS event_type, 7 AS occurrences UNION ALL
    SELECT 3, 'reviews', 3 UNION ALL
    SELECT 1, 'ads', 11 UNION ALL
    SELECT 2, 'ads', 7 UNION ALL
    SELECT 3, 'ads', 6 UNION ALL
    SELECT 1, 'page views', 3 UNION ALL
    SELECT 2, 'page views', 12
)
select
    business_id
from (
         select
             business_id,
             if(occurrences > avg(occurrences) over(partition by event_type) , 1,0) over_times
         from Events t0
     ) t1
where over_times = 1
group by business_id;