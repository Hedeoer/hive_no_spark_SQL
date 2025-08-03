/*
表: `EmployeeShifts`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| employee_id  | int     |
| start_time   | time    |
| end_time     | time    |
+--------------+---------+
```
(employee_id, start_time) 是此表的唯一主键。
这张表包含员工的排班工作，包括特定日期的开始和结束时间。
编写一个解决方案来为每个员工计算 重叠排班 的数量。如果一个排班的 end_time 比另一个排班的 start_time 更晚 则认为两个排班重叠。
返回结果表以 employee_id 升序 排序。
查询结果格式如下所示。

示例：
输入:
`EmployeeShifts` 表:
```
+-------------+------------+-----------+
| employee_id | start_time | end_time  |
+-------------+------------+-----------+
| 1           | 08:00:00   | 12:00:00  |
| 1           | 11:00:00   | 15:00:00  |
| 1           | 14:00:00   | 18:00:00  |
| 2           | 09:00:00   | 17:00:00  |
| 2           | 16:00:00   | 20:00:00  |
| 3           | 10:00:00   | 12:00:00  |
| 3           | 13:00:00   | 15:00:00  |
| 3           | 16:00:00   | 18:00:00  |
| 4           | 08:00:00   | 10:00:00  |
| 4           | 09:00:00   | 11:00:00  |
+-------------+------------+-----------+
```
输出:
```
+-------------+--------------------+
| employee_id | overlapping_shifts |
+-------------+--------------------+
| 1           | 2                  |
| 2           | 1                  |
| 4           | 1                  |
+-------------+--------------------+
```
解释:
员工 1 有 3 个排班: 08:00:00 到 12:00:00
11:00:00 到 15:00:00
14:00:00 到 18:00:00
第一个排班与第二个排班重叠，第二个排班与第三个排班重叠，因此有 2 个重叠排班。
员工 2 有 2 个排班: 09:00:00 到 17:00:00
16:00:00 到 20:00:00
这些排班彼此重叠，因此有 1 个重叠排班。
员工 3 有 3 个排班: 10:00:00 到 12:00:00
13:00:00 到 15:00:00
16:00:00 到 18:00:00
这些排班没有重叠，所以员工 3 不包含在输出中。
员工 4 有 2 个排班: 08:00:00 到 10:00:00
09:00:00 到 11:00:00
这些排班彼此重叠，因此有 1 个重叠排班。
输出展示了 employee_id 和至少有一个重叠排班的员工的重叠排班的数量，以 employee_id 升序排序。


*/

WITH
-- 1. 模拟 EmployeeShifts 表
EmployeeShifts AS (
    SELECT 1 AS employee_id, '08:00:00' AS start_time, '12:00:00' AS end_time UNION ALL
    SELECT 1, '11:00:00', '15:00:00' UNION ALL
    SELECT 1, '14:00:00', '18:00:00' UNION ALL
    SELECT 2, '09:00:00', '17:00:00' UNION ALL
    SELECT 2, '16:00:00', '20:00:00' UNION ALL
    SELECT 3, '10:00:00', '12:00:00' UNION ALL
    SELECT 3, '13:00:00', '15:00:00' UNION ALL
    SELECT 3, '16:00:00', '18:00:00' UNION ALL
    SELECT 4, '08:00:00', '10:00:00' UNION ALL
    SELECT 4, '09:00:00', '11:00:00'
)

select
    employee_id,
    count(*) as overlapping_shifts
from (
         select
             employee_id,
             start_time,
             lag(end_time,1) over(partition by employee_id order by start_time, end_time) previous_end_time
         from EmployeeShifts t1
     ) t2
where unix_timestamp(previous_end_time,'HH:mm:ss') - unix_timestamp(start_time,'HH:mm:ss') >= 0
group by employee_id
