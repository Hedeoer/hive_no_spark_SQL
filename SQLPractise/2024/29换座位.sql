/*
表: Seat

+---------+---------+
| Column Name | Type |
+---------+---------+
| id | int |
| student | varchar |
+---------+---------+
id 是该表的主键（唯一值）列。
该表的每一行都表示学生的姓名和 ID。
ID 排列依然从 1 开始并连续增加。
编写解决方案来交换每两个连续的学生的座位号。如果学生的数量是奇数，则最后一个学生的 id 不交换。
按 id 排序 返回结果表。
查询结果格式如下面示例。
示例 1:
输入:
Seat 表:
+----+---------+
| id | student |
+----+---------+
| 1  | Abbot   |
| 2  | Doris   |
| 3  | Emerson |
| 4  | Green   |
| 5  | Jeames  |
+----+---------+
输出:
+----+---------+
| id | student |
+----+---------+
| 1  | Doris   |
| 2  | Abbot   |
| 3  | Green   |
| 4  | Emerson |
| 5  | Jeames  |
+----+---------+
解释:
请注意，如果学生人数为奇数，则不需要再摸最后一名学生的座位。
*/

/*
方式一
两两交换，可以看作是相邻两组id交换
*/
WITH Seat AS (
    SELECT 1 AS id, 'Abbot' AS student
    UNION ALL
    SELECT 2, 'Doris'
    UNION ALL
    SELECT 3, 'Emerson'
    UNION ALL
    SELECT 4, 'Green'
    UNION ALL
    SELECT 5, 'Jeames'
),
    modified_seat AS (
        select id,
               student,
               mod,
               -- 用于判断是否是最后一个
               lead(id, 1) over(order by id) as next_id,
               -- 用于处理如果学生人数为奇数，则不需要再摸最后一名学生的座位
               count(*) over() total_number
        from (
            select id,
                   student,
                   -- 如果是偶数，-1，奇数，1
                   if(id % 2 = 0, -1, 1) mod
            from Seat t1
             ) t2
    )
select
    id + mod_consider_total_number as id,
    student
from (
    select id,
           student,
           -- 如果是最后一个，且学生总数是奇数，则不需要改变id，mod=0
           if(next_id is null and total_number % 2 = 1, 0,mod) mod_consider_total_number,
           next_id
    from modified_seat
         ) t3
order by id;

/*
方式二
使用lag和lead,直接交换学生姓名
*/
WITH Seat AS (
    SELECT 1 AS id, 'Abbot' AS student
    UNION ALL
    SELECT 2, 'Doris'
    UNION ALL
    SELECT 3, 'Emerson'
    UNION ALL
    SELECT 4, 'Green'
    UNION ALL
    SELECT 5, 'Jeames'
)
select
    id,
    case
        when mod(id, 2) = 0 then lag(student) over(order by id)
        when mod(id, 2) = 1  then coalesce(lead(student) over(order by id),student)
        end student
    from
Seat;