/*
表：Stadium
+----------------+---------+
| Column Name    | Type    |
+----------------+---------+
| id             | int     |
| visit_date     | date    |
| people         | int     |
+----------------+---------+

visit_date 是该表中具有唯一值的列。
每条入流量信息被记录在这三列信息中：序号 (id)、日期 (visit_date)、人流量 (people)
每天只有一行记录，日期随着 id 的增加而增加
编写解决方案找出所有人数大于等于 100 且 id 连续的三行或更多行记录。
返回按 visit_date 升序排列的结果表。

查询结果格式如下所示。
示例 1:
输入:
Stadium 表:
+------+------------+-----------+
| id   | visit_date | people    |
+------+------------+-----------+
| 1    | 2017-01-01 | 10        |
| 2    | 2017-01-02 | 109       |
| 3    | 2017-01-03 | 150       |
| 4    | 2017-01-04 | 99        |
| 5    | 2017-01-05 | 145       |
| 6    | 2017-01-06 | 1455      |
| 7    | 2017-01-07 | 199       |
| 8    | 2017-01-09 | 188       |
+------+------------+-----------+
输出:
+------+------------+-----------+
| id   | visit_date | people    |
+------+------------+-----------+
| 5    | 2017-01-05 | 145       |
| 6    | 2017-01-06 | 1455      |
| 7    | 2017-01-07 | 199       |
| 8    | 2017-01-09 | 188       |
+------+------------+-----------+

解释:
id 为 5, 6, 7, 8 的四行 id 连续，并且每行都有 >= 100 的人数记录。
请注意，即使第 7 行和第 8 行的 visit_date 不是连续的，输出也应当包含第 8 行，因为我们只需要考虑 id 连续的记录。
不输出 id 为 2 和 3 的行，因为至少需要三条 id 连续的记录。
*/

-- 等差数列方式
WITH Stadium AS (SELECT 1 AS id, '2017-01-01' AS visit_date, 10 AS people
                 UNION ALL
                 SELECT 2, '2017-01-02', 109
                 UNION ALL
                 SELECT 3, '2017-01-03', 150
                 UNION ALL
                 SELECT 4, '2017-01-04', 99
                 UNION ALL
                 SELECT 5, '2017-01-05', 145
                 UNION ALL
                 SELECT 6, '2017-01-06', 1455
                 UNION ALL
                 SELECT 7, '2017-01-07', 199
                 UNION ALL
                 SELECT 8, '2017-01-09', 188)
select id,
       visit_date,
       people
from (
    select id,
           visit_date,
           people,
           group_id,
           count(*) over (partition by group_id) as countinus_days
    from (
        select id,
               visit_date,
               people,
               id - row_number() over (order by id) as group_id
        from Stadium
        where people >= 100
        ) t1
    ) t2
where countinus_days >= 3
order by visit_date;

-- 标记累加方式
WITH Stadium AS (SELECT 1 AS id, '2017-01-01' AS visit_date, 10 AS people
                 UNION ALL
                 SELECT 2, '2017-01-02', 109
                 UNION ALL
                 SELECT 3, '2017-01-03', 150
                 UNION ALL
                 SELECT 4, '2017-01-04', 99
                 UNION ALL
                 SELECT 5, '2017-01-05', 145
                 UNION ALL
                 SELECT 6, '2017-01-06', 1455
                 UNION ALL
                 SELECT 7, '2017-01-07', 199
                 UNION ALL
                 SELECT 8, '2017-01-09', 188),
    group_ids  as (
            select id,
               visit_date,
               people,
               pre_id,
               sum(
               case
                   when pre_id is null then 0
                   when id - pre_id = 1 then 0
                   else 1
               end
               ) over(order by id) group_id
        from (
            select id,
                   visit_date,
                   people,
                   lag(id) over(order by id) as pre_id
            from Stadium
            where people >= 100
            ) t1
    )
select id,
       visit_date,
       people

from (
    select id,
           visit_date,
           people,
           pre_id,
           group_id,
           count(*) over (partition by group_id) as countinus_days
    from group_ids
    ) t2
where countinus_days >= 3
order by visit_date;


