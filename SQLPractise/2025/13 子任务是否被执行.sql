/*
表: `Tasks`
```
+-----------------+---------+
| Column Name     | Type    |
+-----------------+---------+
| task_id         | int     |
| subtasks_count  | int     |
+-----------------+---------+
```
`task_id` 具有唯一值的列。
`task_id` 表示的为主任务的id, 每一个`task_id`被分为了多个子任务(subtasks), `subtasks_count`表示为子任务的个数(n), 它的值表示了子任务的索引从1到n。
本表保证`2 <= subtasks_count<= 20`。

表: `Executed`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| task_id     | int     |
| subtask_id  | int     |
+-------------+---------+
```
`(task_id, subtask_id)` 是该表中具有唯一值的组合。
每一行表示标记为`task_id`的主任务与标记为`subtask_id`的子任务被成功执行。
本表 保证，对于每一个`task_id`, `subtask_id <= subtasks_count`。

编写解决方案报告没有被执行的 (主任务，子任务) 对，即没有被执行的 `(task_id, subtask_id)` 。
以 任何顺序 返回即可。
查询结果格式如下。

示例 1:

输入:
`Tasks` 表:
```
+---------+----------------+
| task_id | subtasks_count |
+---------+----------------+
| 1       | 3              |
| 2       | 2              |
| 3       | 4              |
+---------+----------------+
```
`Executed` 表:
```
+---------+------------+
| task_id | subtask_id |
+---------+------------+
| 1       | 2          |
| 3       | 1          |
| 3       | 2          |
| 3       | 3          |
| 3       | 4          |
+---------+------------+
```
输出:
```
+---------+------------+
| task_id | subtask_id |
+---------+------------+
| 1       | 1          |
| 1       | 3          |
| 2       | 1          |
| 2       | 2          |
+---------+------------+
```
解释:
Task 1 被分成了 3 subtasks (1, 2, 3)。只有 subtask 2 被成功执行, 所以我们返回 (1, 1) 和 (1, 3) 这两个主任务子任务对。
Task 2 被分成了 2 subtasks (1, 2)。没有一个subtask被成功执行, 因此我们返回(2, 1)和(2, 2)。
Task 3 被分成了 4 subtasks (1, 2, 3, 4)。所有的subtask都被成功执行, 因此对于Task 3,我们不返回任何值。
*/

WITH
-- 1. 模拟 Tasks 表
Tasks AS (
    SELECT 1 AS task_id, 3 AS subtasks_count UNION ALL
    SELECT 2, 2 UNION ALL
    SELECT 3, 4
),

-- 2. 模拟 Executed 表
Executed AS (
    SELECT 1 AS task_id, 2 AS subtask_id UNION ALL
    SELECT 3, 1 UNION ALL
    SELECT 3, 2 UNION ALL
    SELECT 3, 3 UNION ALL
    SELECT 3, 4
)
select
    t2.task_id,
    t2.subtask_id
from (
         select
             t1.task_id,
             t2.pos + 1 as subtask_id
         from Tasks t1
             lateral view posexplode(split(repeat(',',t1.subtasks_count - 1), ',')) t2 as pos, task
     ) t2
         left join Executed t3
                   on t2.task_id = t3.task_id and t2.subtask_id = t3.subtask_id
where t3.task_id is null


