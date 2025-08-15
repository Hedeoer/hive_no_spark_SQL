
/*
`RequestAccepted` 表:
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| requester_id  | int     |
| accepter_id   | int     |
| accept_date   | date    |
+---------------+---------+
```
(requester_id, accepter_id) 是这张表的主键(具有唯一值的列的组合)。
这张表包含发送好友请求的人的 ID ，接收好友请求的人的 ID ，以及好友请求通过的日期。
编写解决方案，找出拥有最多的好友的人和他拥有的好友数目。
生成的测试用例保证拥有最多好友数目的人只有 `1` 个人。
查询结果格式如下例所示。

示例 1:

输入:
`RequestAccepted` 表:
```
+--------------+-------------+-------------+
| requester_id | accepter_id | accept_date |
+--------------+-------------+-------------+
| 1            | 2           | 2016/06/03  |
| 1            | 3           | 2016/06/08  |
| 2            | 3           | 2016/06/08  |
| 3            | 4           | 2016/06/09  |
+--------------+-------------+-------------+
```
输出:
```
+----+-----+
| id | num |
+----+-----+
| 3  | 3   |
+----+-----+
```
解释:
编号为 `3` 的人是编号为 `1` , `2` 和 `4` 的人的好友, 所以他总共有 `3` 个好友, 比其他人都多。

*/

WITH
-- 1. 模拟 RequestAccepted 表
RequestAccepted AS (
    SELECT 1 AS requester_id, 2 AS accepter_id, CAST('2016-06-03' AS DATE) AS accept_date UNION ALL
    SELECT 1, 3, CAST('2016-06-08' AS DATE) UNION ALL
    SELECT 2, 3, CAST('2016-06-08' AS DATE) UNION ALL
    SELECT 3, 4, CAST('2016-06-09' AS DATE)
)
-- 方式1
/*
select
    requester_id as id,
    count(distinct accepter_id) num
from (
         select requester_id,
                accepter_id
         from RequestAccepted t0
         union all
         select
             accepter_id,
             requester_id
         from RequestAccepted t1
     ) t2
group by requester_id
order by num desc
limit 1*/

-- 方式2
        ,
request_sent as (
    select
        requester_id as id,
        count(1) request_nums
    from RequestAccepted t0
    group by requester_id
),
receive_request as (
    select
        accepter_id as id,
        count(1) receive_nums
    from RequestAccepted t0
    group by accepter_id
)
select
    nvl(t0.id,t1.id) as id,
    sum(nvl(t0.receive_nums,0) ) + sum(nvl(t1.request_nums,0) ) as num
from receive_request t0
         full join request_sent t1
                   on t0.id = t1.id
group by nvl(t0.id,t1.id)
order by num desc
limit 1;
