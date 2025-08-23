/*
表: `Failed`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| fail_date   | date    |
+-------------+---------+
```
该表主键为 `fail_date` (具有唯一值的列)。
该表包含失败任务的天数。

表: `Succeeded`
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| success_date | date    |
+--------------+---------+
```
该表主键为 `success_date` (具有唯一值的列)。
该表包含成功任务的天数。
系统每天运行一个任务。每个任务都独立于先前的任务。任务的状态可以是失败或是成功。

编写解决方案找出 `2019-01-01` 到 `2019-12-31` 期间任务连续同状态 `period_state` 的起止日期（`start_date` 和 `end_date`）。即如果任务失败了，就是失败状态的起止日期，如果任务成功了，就是成功状态的起止日期。
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
结果忽略了 2018 年的记录, 因为我们只关心从 2019-01-01 到 2019-12-31 的记录
从 2019-01-01 到 2019-01-03 所有任务成功, 系统状态为 "succeeded"。
从 2019-01-04 到 2019-01-05 所有任务失败, 系统状态为 "failed"。
从 2019-01-06 到 2019-01-06 所有任务成功, 系统状态为 "succeeded"。
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
group_comming as (
    select work_date,
           flag,
           datediff,
           previous_flag,
           sum(
                   if((datediff is null or datediff = 1) and flag = previous_flag,0,1)
           ) over (order by work_date) group_flag
    from (select
              work_date,
              flag,
              datediff(work_date,lag(work_date,1) over(order by work_date)) datediff,
              lag(flag,1) over(order by work_date )previous_flag
          from (
                   select fail_date as work_date,'fail' as flag
                   from Failed t1
                   where fail_date between '2019-01-01' and '2019-12-31'
                   union all
                   select success_date ,'succeed'
                   from Succeeded t2
                   where success_date between '2019-01-01' and '2019-12-31'
               ) t3)t4
)
select
    flag,
    min(work_date) start_date,
    max(work_date) end_date
from group_comming t0
group by flag,group_flag
