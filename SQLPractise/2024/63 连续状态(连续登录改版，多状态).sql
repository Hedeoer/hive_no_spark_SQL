
/*
连续状态(连续登录改版，多状态)
表: `Failed`
```
+-----------+------+
| Column Name | Type |
+-----------+------+
| fail_date | date |
+-----------+------+
```
该表主键为 `fail_date` (具有唯一值的列)。
该表包含失败任务的天数。

表: `Succeeded`
```
+--------------+------+
| Column Name  | Type |
+--------------+------+
| success_date | date |
+--------------+------+
```
该表主键为 `success_date` (具有唯一值的列)。
该表包含成功任务的天数。

系统每天运行一个任务。每个任务都独立于先前的任务。任务的状态可以是失败或是成功。
编写解决方案找出 `2019-01-01` 到 `2019-12-31` 期间任务连续同状态 `period_state` 的起止日期 (`start_date` 和 `end_date`)。即如果任务失败了，就是失败状态的起止日期，如果任务成功了，就是成功状态的起止日期。
最后结果按照起始日期 `start_date` 排序
返回结果样例如下所示:

示例 1:
输入:
`Failed table`:
```
+------------+
| fail_date  |
+------------+
| 2018-12-28 |
| 2018-12-29 |
| 2019-01-04 |
| 2019-01-05 |
+------------+
```
`Succeeded table`:
```
+--------------+
| success_date |
+--------------+
| 2018-12-30   |
| 2018-12-31   |
| 2019-01-01   |
| 2019-01-02   |
| 2019-01-03   |
| 2019-01-06   |
+--------------+
```
输出:
```
+--------------+------------+------------+
| period_state | start_date | end_date   |
+--------------+------------+------------+
| succeeded    | 2019-01-01 | 2019-01-03 |
| failed       | 2019-01-04 | 2019-01-05 |
| succeeded    | 2019-01-06 | 2019-01-06 |
+--------------+------------+------------+
```
解释:
结果忽略了 2018 年的记录, 因为我们只关心从 `2019-01-01` 到 `2019-12-31` 的记录
从 `2019-01-01` 到 `2019-01-03` 所有任务成功, 系统状态为 "succeeded"。
从 `2019-01-04` 到 `2019-01-05` 所有任务失败, 系统状态为 "failed"。
从 `2019-01-06` 到 `2019-01-06` 所有任务成功, 系统状态为 "succeeded"。

### 使用 WITH 语法的 HiveQL 解决方案

这是一个典型的“寻找连续区间”（Gaps and Islands）问题。我们可以通过使用窗口函数 `ROW_NUMBER()` 来解决。基本思路是：
1.  将成功和失败的记录合并，并为每条记录打上状态标签。
2.  对所有记录按日期排序生成一个总行号。
3.  对每个状态内的记录按日期排序生成一个状态内行号。
4.  用“总行号”减去“状态内行号”，得到的差值对于同一个连续的状态区间来说是恒定的。
5.  按这个差值和状态进行分组，即可找出每个连续区间的开始和结束日期。


*/


WITH
-- 1. 模拟 Failed 表
Failed AS (
    SELECT CAST('2018-12-28' AS DATE) AS fail_date UNION ALL
    SELECT CAST('2018-12-29' AS DATE) UNION ALL
    SELECT CAST('2019-01-04' AS DATE) UNION ALL
    SELECT CAST('2019-01-05' AS DATE)
),

-- 2. 模拟 Succeeded 表
Succeeded AS (
    SELECT CAST('2018-12-30' AS DATE) AS success_date UNION ALL
    SELECT CAST('2018-12-31' AS DATE) UNION ALL
    SELECT CAST('2019-01-01' AS DATE) UNION ALL
    SELECT CAST('2019-01-02' AS DATE) UNION ALL
    SELECT CAST('2019-01-03' AS DATE) UNION ALL
    SELECT CAST('2019-01-06' AS DATE)
),
/*

-- 方式1: 使用窗口函数和日期分组来计算连续状态的起止日期
select
    -- 计算每个状态的起止日期
    t4.period_state,
    min(t4.task_date) as start_date,
    max(t4.task_date) as end_date
from (
         -- 为每条记录打上状态标签，并生成一个日期组
         select
             period_state,
             task_date,
             date_sub(task_date,
                      row_number() over (partition by period_state order by task_date)) as date_group
         from (
                  -- 将失败和成功的记录合并，并标记状态
                  select
                      'failed' as period_state,
                      fail_date as task_date
                  from Failed t1
                  union all
                  select
                      'succeeded' as period_state,
                      success_date
                  from Succeeded t2
              ) t3
     ) t4
group by t4.period_state,
         t4.date_group;

*/
-- 方式2: 使用窗口函数和日期分组来计算连续状态的起止日期
-- 1. 合并数据并筛选年份
AllTasks AS (
    SELECT 'failed' AS period_state, fail_date AS task_date
    FROM Failed
    WHERE YEAR(fail_date) = 2019
    UNION ALL
    SELECT 'succeeded' AS period_state, success_date
    FROM Succeeded
    WHERE YEAR(success_date) = 2019
),


-- 2. 第一步：计算每个状态下的上一个日期
WithLagDate AS (
    SELECT
        period_state,
        task_date,
        LAG(task_date, 1) OVER (PARTITION BY period_state ORDER BY task_date) as prev_date
    FROM
        AllTasks
),

-- 3. 第二步：根据日期间隔，标记新分组的开始
WithGroupFlag AS (
    SELECT
        period_state,
        task_date,
        -- 如果没有上一个日期 (是第一个)，或者日期间隔大于1，则这是一个新分组的开始
        CASE
            WHEN prev_date IS NULL OR DATEDIFF(task_date, prev_date) > 1 THEN 1
            ELSE 0
            END AS is_new_group
    FROM
        WithLagDate
),

-- 4. 第三步：通过累加求和创建分组ID
WithGroupID AS (
    SELECT
        period_state,
        task_date,
        SUM(is_new_group) OVER (PARTITION BY period_state ORDER BY task_date) as grp
    FROM
        WithGroupFlag
)

-- 5. 第四步：按分组ID聚合，得到最终结果
SELECT
    period_state,
    MIN(task_date) AS start_date,
    MAX(task_date) AS end_date
FROM
    WithGroupID
GROUP BY
    period_state, grp
ORDER BY
    start_date;