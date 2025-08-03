/*
表: `EmployeeShifts`
```
+-------------+----------+
| Column Name | Type     |
+-------------+----------+
| employee_id | int      |
| start_time  | datetime |
| end_time    | datetime |
+-------------+----------+
```
(employee_id, start_time) 是此表的唯一主键。
这张表包含员工的排班工作，包括特定日期的开始和结束时间。
编写一个解决方案来为每个员工分析重叠排班。如果两个排班在 同一天 且一个排班的 end_time 比另一个排班的 start_time 更晚 则认为两个排班重叠。
对于 每个员工, 计算如下内容:
任何 给定时间 的 最多重叠 班次数。
所有重叠班次的总持续时间, 以分钟为单位。
返回结果表以 employee_id 升序 排序。
查询结果格式如下所示。

示例：
输入:
`EmployeeShifts` 表:
```
+-------------+---------------------+---------------------+
| employee_id | start_time          | end_time            |
+-------------+---------------------+---------------------+
| 1           | 2023-10-01 09:00:00 | 2023-10-01 17:00:00 |
| 1           | 2023-10-01 15:00:00 | 2023-10-01 23:00:00 |
| 1           | 2023-10-01 16:00:00 | 2023-10-02 00:00:00 |
| 2           | 2023-10-01 09:00:00 | 2023-10-01 17:00:00 |
| 2           | 2023-10-01 11:00:00 | 2023-10-01 19:00:00 |
| 3           | 2023-10-01 09:00:00 | 2023-10-01 17:00:00 |
+-------------+---------------------+---------------------+
```
输出:
```
+-------------+----------------------+--------------------------+
| employee_id | max_overlapping_shifts | total_overlap_duration   |
+-------------+----------------------+--------------------------+
| 1           | 3                    | 600                      |
| 2           | 2                    | 360                      |
| 3           | 1                    | 0                        |
+-------------+----------------------+--------------------------+
```
解释:
-- “任何 给定时间 的 最多重叠 班次数 ”解释
让我们把员工1的三个班次画在时间轴上，看看并发数是如何变化的：
班次 1: 09:00 —————— 17:00
班次 2: 　　　 15:00 —————— 23:00
班次 3: 　　　　 16:00 —————————— (次日)00:00
现在我们沿着时间轴走一遍，数一数每个时间段有多少个班次在“进行中”：
09:00 - 15:00 之前: 只有 1 个班次（班次1）。
15:00 - 16:00 之前: 班次2开始了，现在有 2 个班次在同时进行（班次1 和 班次2）。
16:00 - 17:00 之前: 班次3也开始了，现在有 3 个班次在同时进行（班次1、班次2 和 班次3）。
17:00 - 23:00 之前: 班次1结束了，只剩下 2 个班次在同时进行（班次2 和 班次3）。
23:00 - 00:00 之前: 班次2结束了，只剩下 1 个班次（班次3）。
我们把整个过程中的并发数量列出来：1, 2, 3, 2, 1。
这个数列中的最大值是多少？是 3。\

-- “所有重叠班次的总持续时间” 解释
找出每一对相互重叠的班次，计算它们各自重叠了多长时间，然后把所有这些重叠时间加起来

员工 1 有 3 个排班: 2023-10-01 09:00:00 到 2023-10-01 17:00:00
2023-10-01 15:00:00 到 2023-10-01 23:00:00
2023-10-01 16:00:00 到 2023-10-02 00:00:00
最大重叠班次数量为 3 (from 16:00 to 17:00)。重叠班次的总持续时间为: 第 1 个和第 2 个排班之间的 2 小时 (15:00-17:00) + 第 1 个和第 3 个排班之间的 1 小时 (16:00-17:00) + 第 2 个和第 3 个排班之间的 7 小时 (16:00-23:00)，总共: 10 小时 = 600 分钟
员工 2 有 2 个排班: 2023-10-01 09:00:00 到 2023-10-01 17:00:00
2023-10-01 11:00:00 到 2023-10-01 19:00:00
最大重叠班次数量为 2。重叠班次的总持续时间为 6 小时 (11:00

*/

WITH
-- 1. 模拟 EmployeeShifts 表，使用 TIMESTAMP 类型代替 datetime
EmployeeShifts AS (
    SELECT 1 AS employee_id, CAST('2023-10-01 09:00:00' AS TIMESTAMP) AS start_time, CAST('2023-10-01 17:00:00' AS TIMESTAMP) AS end_time UNION ALL
    SELECT 1, CAST('2023-10-01 15:00:00' AS TIMESTAMP), CAST('2023-10-01 23:00:00' AS TIMESTAMP) UNION ALL
    SELECT 1, CAST('2023-10-01 16:00:00' AS TIMESTAMP), CAST('2023-10-02 00:00:00' AS TIMESTAMP) UNION ALL
    SELECT 2, CAST('2023-10-01 09:00:00' AS TIMESTAMP), CAST('2023-10-01 17:00:00' AS TIMESTAMP) UNION ALL
    SELECT 2, CAST('2023-10-01 11:00:00' AS TIMESTAMP), CAST('2023-10-01 19:00:00' AS TIMESTAMP) UNION ALL
    SELECT 3, CAST('2023-10-01 09:00:00' AS TIMESTAMP), CAST('2023-10-01 17:00:00' AS TIMESTAMP)
),

-- Part 1: 计算最大并发班次数
-- 2. 将每个班次拆分为开始(+1)和结束(-1)两个事件点
TimePoints AS (
    SELECT employee_id, start_time AS event_time, 1 AS event_type FROM EmployeeShifts
    UNION ALL
    SELECT employee_id, end_time AS event_time, -1 AS event_type FROM EmployeeShifts
),
-- 3. 使用窗口函数计算每个时间点的并发班次数
RunningCounts AS (
    SELECT
        employee_id,
        -- 按时间排序，计算事件的累积和，即为并发数
        -- 如果一个“开始”事件和一个“结束”事件发生在同一时刻，我们总是先处理“开始”事件，再处理“结束”事件，这样才能准确反应重叠班次的峰值
        SUM(event_type) OVER (PARTITION BY employee_id ORDER BY event_time, event_type DESC) AS concurrent_shifts
    FROM TimePoints
),
-- 4. 找到每个员工的最大并发数
MaxOverlapCalc AS (
    SELECT
        employee_id,
        COALESCE(MAX(concurrent_shifts), 0) AS max_overlapping_shifts
    FROM RunningCounts
    GROUP BY employee_id
),

-- Part 2: 计算总重叠时长
-- 5. 自连接，找到所有在同一天开始且有重叠的班次对，并计算其重叠时长
DurationOverlapCalc AS (
    SELECT
        e1.employee_id,
        -- 计算所有成对重叠的总分钟数
        SUM(
                (unix_timestamp(LEAST(e1.end_time, e2.end_time)) - unix_timestamp(e2.start_time)) / 60
        ) AS total_overlap_duration
    FROM
        EmployeeShifts e1
            JOIN
        EmployeeShifts e2 ON e1.employee_id = e2.employee_id
            -- 比较不同的班次
            AND e1.start_time < e2.start_time
            -- 必须在同一天开始
            AND to_date(e1.start_time) = to_date(e2.start_time)
    -- 重叠条件: 第一个班次的结束时间晚于第二个的开始时间
    WHERE e1.end_time > e2.start_time
    GROUP BY
        e1.employee_id
)

-- 6. 最终合并结果
SELECT
    m.employee_id,
    m.max_overlapping_shifts,
    CAST(COALESCE(d.total_overlap_duration, 0) AS BIGINT) AS total_overlap_duration
FROM
    MaxOverlapCalc m
        LEFT JOIN
    DurationOverlapCalc d ON m.employee_id = d.employee_id
ORDER BY
    m.employee_id;