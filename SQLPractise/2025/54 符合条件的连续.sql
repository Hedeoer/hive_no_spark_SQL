/*
表: `Stadium`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| visit_date  | date    |
| people      | int     |
+-------------+---------+
```
`visit_date` 是该表中具有唯一值的列。
每日人流量信息被记录在这三列信息中：序号 (id)、日期 (visit_date)、人流量 (people)
每天只有一行记录，日期随着 id 的增加而增加

编写解决方案找出每行的`人数大于或等于 100` 且 `id 连续的三行或更多行记录`。
返回按 `visit_date` 升序排列 的结果表。
查询结果格式如下所示。

示例 1:

输入:
`Stadium` 表:
```
+----+------------+--------+
| id | visit_date | people |
+----+------------+--------+
| 1  | 2017-01-01 | 10     |
| 2  | 2017-01-02 | 109    |
| 3  | 2017-01-03 | 150    |
| 4  | 2017-01-04 | 99     |
| 5  | 2017-01-05 | 145    |
| 6  | 2017-01-06 | 1455   |
| 7  | 2017-01-07 | 199    |
| 8  | 2017-01-09 | 188    |
+----+------------+--------+
```
输出:
```
+----+------------+--------+
| id | visit_date | people |
+----+------------+--------+
| 5  | 2017-01-05 | 145    |
| 6  | 2017-01-06 | 1455   |
| 7  | 2017-01-07 | 199    |
| 8  | 2017-01-09 | 188    |
+----+------------+--------+
```
解释:
id 为 5、6、7、8 的四行 id 连续, 并且每行都有 >= 100 的人数记录。
请注意，即便第 7 行和第 8 行的 visit_date 不是连续的, 输出也应当包含第 8 行, 因为我们只需要考虑 id 连续的记录。
不输出 id 为 2 和 3 的行, 因为至少需要三条 id 连续的记录。
*/

WITH
-- 1. 模拟 Stadium 表
Stadium AS (
    SELECT 1 AS id, CAST('2017-01-01' AS DATE) AS visit_date, 10 AS people UNION ALL
    SELECT 2, CAST('2017-01-02' AS DATE), 109 UNION ALL
    SELECT 3, CAST('2017-01-03' AS DATE), 150 UNION ALL
    SELECT 4, CAST('2017-01-04' AS DATE), 99 UNION ALL
    SELECT 5, CAST('2017-01-05' AS DATE), 145 UNION ALL
    SELECT 6, CAST('2017-01-06' AS DATE), 1455 UNION ALL
    SELECT 7, CAST('2017-01-07' AS DATE), 199 UNION ALL
    SELECT 8, CAST('2017-01-09' AS DATE), 188
)

-- 方式1
/*
     ,
    continus_analysis as (
        select
            id,
            visit_date,
            people,
            count(1) over(partition by group_flag) continus_days
        from (
                 select id,
                        people,
                        visit_date,
                        sum(if(diff is null or diff = 1,0,1)) over(order by id) group_flag
                 from (
                          select
                              id,
                              people,
                              visit_date,
                              id - lag(id, 1) over(order by id) diff
                          from Stadium t1
                          where people >= 100
                      ) t2

             ) t3

    )
select id,
       visit_date,
       people
from continus_analysis t0
where continus_days >= 3
order by visit_date;
*/

-- 方式2
select id,
       visit_date,
       people
from (
         select id,
                visit_date,
                people,
                id - row_number() over (order by id) group_flag,
                count(1) over(partition by (id - row_number() over (order by id))) continus_days
         from Stadium t0
         where people >= 100
     ) t1
where continus_days >= 3
order by visit_date;

/*
传统聚合函数（SUM, COUNT等）：不允许直接嵌套，需使用子查询或CTE。
窗口函数（... over (...)）：允许其 partition by 或 order by 子句中包含另一个窗口函数
*/