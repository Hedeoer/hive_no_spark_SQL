/*
 题目29 没有被执行的任务(不生效的投放，不生效的活动，点击进入但是未下单，点击了活动但是未参与，参与了一半就退出)

```sql
表: Tasks
+----------------+------+
| Column Name    | Type |
+----------------+------+
| task_id        | int  |
| subtasks_count | int  |
+----------------+------+
task_id 具有唯一值的列。
task_id 是示范为主任务的id,每一个task_id被分为了多个子任务(subtasks), subtasks_count表示为子任务的个数 (0) , 它的值表示子任务的索引从1到n,
本表保证: 2<=subtasks_count<= 20,

表: Executed
+---------------+------+
| Column Name   | Type |
+---------------+------+
| task_id       | int  |
| subtask_id    | int  |
+---------------+------+
(task_id, subtask_id) 是该表中具有唯一值的组合。
该表表示哪个task_id的哪些子任务(subtask_id的子任务)被成功执行了,
本表 保证: 对于每一个task_id, subtask_id <= subtasks_count,
当没有被成功完成的task_id的子任务(子任务) 时, 则没有被执行的 (task_id, subtask_id) 。
以 任何顺序 返回即可,

查询结果格式如下,
示例 1:
输入:
Tasks 表:
+-------------+----------------+
| task_id     | subtasks_count |
+-------------+----------------+
| 1           | 3              |
| 2           | 2              |
| 3           | 4              |
+-------------+----------------+
Executed 表:
+-------------+-------------+
| task_id     | subtask_id  |
+-------------+-------------+
| 1           | 2           |
| 3           | 1           |
| 3           | 2           |
| 3           | 3           |
| 3           | 4           |
+-------------+-------------+
输出:
+-------------+-------------+
| task_id     | subtask_id  |
+-------------+-------------+
| 1           | 1           |
| 1           | 3           |
| 2           | 1           |
| 2           | 2           |
+-------------+-------------+
解释:
Task 1 被分为了 3 subtasks (1, 2, 3). 只有 subtask 2 被成功执行了, 所以我们返回 (1, 1) 和 (1, 3)
这两个子任务子任务对.
Task 2 被分为了 2 subtasks (1, 2). 没有一个subtask被成功执行, 因此我们返回(2, 1)和(2, 2).
Task 3 被分为了 4 subtasks (1, 2, 3, 4). 所有的subtask都被成功执行了，因此对于Task 3，我们不返回任何值。
```

```sql
with recursive t(task_id, subtask_id) as (
    SELECT task_id, subtasks_count FROM Tasks
    UNION ALL
    SELECT task_id, subtask_id-1 FROM t where subtask_id>1
)

SELECT * FROM t left join Executed using(task_id, subtask_id)
WHERE Executed.subtask_id is null
ORDER BY task_id, subtask_id
```
*/
WITH Tasks AS (
    SELECT 1 AS task_id, 3 AS subtasks_count
    UNION ALL
    SELECT 2, 2
    UNION ALL
    SELECT 3, 4
),
Executed AS (
    SELECT 1 AS task_id, 2 AS subtask_id
    UNION ALL
    SELECT 3, 1
    UNION ALL
    SELECT 3, 2
    UNION ALL
    SELECT 3, 3
    UNION ALL
    SELECT 3, 4
),
    all_tasks as (
select
    t1.task_id,
    t1.subtasks_count,
    t2.pos + 1 subtask_id
from Tasks t1
lateral view posexplode(split(space(t1.subtasks_count - 1),'')) t2 as pos,val
    )
select
    t1.task_id,
    t1.subtask_id
from all_tasks t1
left join Executed t2
on t1.task_id = t2.task_id and t1.subtask_id = t2.subtask_id
where t2.subtask_id is null;