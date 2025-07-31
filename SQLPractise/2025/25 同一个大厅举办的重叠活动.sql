/*
表: `HallEvents`
```
+-----------+------+
| Column Name| Type |
+-----------+------+
| hall_id   | int  |
| start_day | date |
| end_day   | date |
+-----------+------+
```
该表可能包含重复字段。
该表的每一行表示活动的开始日期和结束日期，以及活动举行的大厅。

编写解决方案，合并在 同一个大厅举行的 所有重叠活动。如果两个活动 至少有一天 相同，那么它们就是重叠的。
以任意顺序返回结果表。
结果格式如下所示。

示例 1:

输入:
`HallEvents` 表:
```
+---------+------------+------------+
| hall_id | start_day  | end_day    |
+---------+------------+------------+
| 1       | 2023-01-13 | 2023-01-14 |
| 1       | 2023-01-14 | 2023-01-17 |
| 1       | 2023-01-18 | 2023-01-25 |
| 2       | 2022-12-09 | 2022-12-23 |
| 2       | 2022-12-13 | 2022-12-17 |
| 3       | 2022-12-01 | 2023-01-30 |
+---------+------------+------------+
```
输出:
```
+---------+------------+------------+
| hall_id | start_day  | end_day    |
+---------+------------+------------+
| 1       | 2023-01-13 | 2023-01-17 |
| 1       | 2023-01-18 | 2023-01-25 |
| 2       | 2022-12-09 | 2022-12-23 |
| 3       | 2022-12-01 | 2023-01-30 |
+---------+------------+------------+
```
解释: 有三个大厅。
大厅 1:
- 两个活动 `["2023-01-13", "2023-01-14"]` 和 `["2023-01-14", "2023-01-17"]` 重叠。我们将它们合并到一个个活动中 `["2023-01-13", "2023-01-17"]`。
- 活动 `["2023-01-18", "2023-01-25"]` 不与任何其他活动重叠，所以我们保持原样。
大厅 2:
- 两个活动 `["2022-12-09", "2022-12-23"]` 和 `["2022-12-13", "2022-12-17"]` 重叠。我们将它们合并到一个个活动中 `["2022-12-09", "2022-12-23"]`。
大厅 3:
- 大厅只有...一个活动，所以我们返回它。请注意，我们只分别考虑每个大厅的活动。


这个问题的核心是合并重叠的日期区间，这是一个经典的 "gaps-and-islands" 问题。下面的查询通过三个步骤解决它：
1.  **`MarkedStarts`**: 识别出每个不间断活动序列的起始事件。如果一个事件的开始日期晚于它所在大厅之前所有事件的最晚结束日期，那么它就是一个新的活动序列的开始。
2.  **`GroupedEvents`**: 利用上一步的标记，为每个连续的活动序列分配一个唯一的组ID。
3.  **最终查询**: 按组ID进行分组，找出每个组的最早开始日期和最晚结束日期，从而得到合并后的活动区间。

```sql


*/

WITH
-- 1. 模拟 HallEvents 表
HallEvents AS (
    SELECT 1 AS hall_id, CAST('2023-01-13' AS DATE) AS start_day, CAST('2023-01-14' AS DATE) AS end_day UNION ALL
    SELECT 1, CAST('2023-01-14' AS DATE), CAST('2023-01-17' AS DATE) UNION ALL
    SELECT 1, CAST('2023-01-18' AS DATE), CAST('2023-01-25' AS DATE) UNION ALL
    SELECT 2, CAST('2022-12-09' AS DATE), CAST('2022-12-23' AS DATE) UNION ALL
    SELECT 2, CAST('2022-12-13' AS DATE), CAST('2022-12-17' AS DATE) UNION ALL
    SELECT 3, CAST('2022-12-01' AS DATE), CAST('2023-01-30' AS DATE)
),
overlap_events_group as (
    select
        hall_id,
        start_day,
        end_day,
        -- 使用累计求和的方式来标记新的重叠活动窗口开始
        sum(is_new_flag) over (partition by hall_id order by start_day, end_day) as group_id
    from (
             -- 判断是否日期重叠 datediff 和 lag 函数实现
             select hall_id,
                    start_day,
                    end_day,
                    lag(end_day,1,start_day) over (partition by hall_id order by start_day,end_day) as previous_end_day,
                    datediff(lag(end_day,1,start_day) over (partition by hall_id order by start_day,end_day),start_day) as diff,
                    `if`(datediff(lag(end_day,1,start_day) over (partition by hall_id order by start_day,end_day),start_day) >= 0, 0, 1) as is_new_flag
             from (
                      -- 去重数据
                      select hall_id,
                             start_day,
                             end_day
                      from HallEvents t1
                      group by hall_id, start_day, end_day
                  ) t1
         ) t2

)
-- 每个重叠活动窗口的开始和结束日期
select
    hall_id,
    min(start_day) as start_day,
    max(end_day) as end_day
from overlap_events_group t1
group by hall_id,group_id
