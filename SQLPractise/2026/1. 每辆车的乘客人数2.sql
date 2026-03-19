/*
====================================================================
题目：公交车上的乘客数量 (The Number of Passengers in Each Bus)
====================================================================

表：Buses
+--------------+------+
| Column Name  | Type |
+--------------+------+
| bus_id       | int  |
| arrival_time | int  |
| capacity     | int  |
+--------------+------+
bus_id 包含唯一的值。
该表的每一行都包含关于公交车到达车站的时间和它的容量（空座位的数量）的信息。
不会出现两辆公交车同时到达，所有公交车的容量都是正整数。

表：Passengers
+--------------+------+
| Column Name  | Type |
+--------------+------+
| passenger_id | int  |
| arrival_time | int  |
+--------------+------+
passenger_id 包含唯一的值。
该表的每一行都包含乘客到达车站的时间信息。

公交车和乘客到达车站。如果一辆公交车在 tbus 时间点到达车站，乘客在 tpassenger 到达车站，
其中 tpassenger <= tbus，而该乘客没有赶上任何公交车，则该乘客将搭乘该公交车。
此外，每辆公交车都有一个容量。如果在公交车到站的那一刻，等待的乘客超过了它的载客量 capacity，
只有 capacity 个乘客才会搭乘该公交车（先到先得/按等待队列）。

编写解决方案，报告搭乘每辆公交车的乘客数量。
返回按 bus_id 升序排序的结果表。

示例 1：

输入：
Buses 表：
+--------+--------------+----------+
| bus_id | arrival_time | capacity |
+--------+--------------+----------+
| 1      | 2            | 1        |
| 2      | 4            | 10       |
| 3      | 7            | 2        |
+--------+--------------+----------+

Passengers 表：
+--------------+--------------+
| passenger_id | arrival_time |
+--------------+--------------+
| 11           | 1            |
| 12           | 1            |
| 13           | 5            |
| 14           | 6            |
| 15           | 7            |
+--------------+--------------+

输出：
+--------+----------------+
| bus_id | passengers_cnt |
+--------+----------------+
| 1      | 1              |
| 2      | 1              |
| 3      | 2              |
+--------+----------------+

解释：
- 11 号乘客在时间 1 到达。
- 12 号乘客在时间 1 到达。
- 1 号公交车到达时间为 2，因为有一个空座位，所以搭载了 11 号乘客。
- 2 号公交车在时间 4 到达，搭载了 12 号乘客，因为它有 10 个空座位。
- 13 号乘客在时间 5 到达。
- 14 号乘客在时间 6 到达。
- 15 号乘客在时间 7 到达。
- 3 号公交车在时间 7 到达，车上有两个空座位，搭载了 13 号和 14 号乘客。
*/

WITH Buses AS (
    SELECT 1 AS bus_id, 2 AS arrival_time, 1 AS capacity UNION ALL
    SELECT 2 AS bus_id, 4 AS arrival_time, 10 AS capacity UNION ALL
    SELECT 3 AS bus_id, 7 AS arrival_time, 2 AS capacity
),
     Passengers AS (
         SELECT 11 AS passenger_id, 1 AS arrival_time UNION ALL
         SELECT 12 AS passenger_id, 1 AS arrival_time UNION ALL
         SELECT 13 AS passenger_id, 5 AS arrival_time UNION ALL
         SELECT 14 AS passenger_id, 6 AS arrival_time UNION ALL
         SELECT 15 AS passenger_id, 7 AS arrival_time
     )
-- ==========================================
-- 请在此处往下编写你的 Hive SQL 解答
-- 提示：此题在不使用存储过程/循环的情况下，
-- 非常考验对开窗函数（Window Functions）的综合运用
-- ==========================================
/*
思路：每个乘客上来那辆bus，匹配不上，赶不上车；匹配多个bus，取最近乘客到达时间的那个; 最后还需要根据bus的空余容量做筛选。
*/
, choice_bus as (
    select
        t1.passenger_id,
        t2.bus_id,
        t2.capacity,
        t1.arrival_time,
        t2.arrival_time,
        row_number() over (partition by t1.passenger_id order by t2.arrival_time - t1.arrival_time asc) as candidate_order_number
    from Passengers t1
    left join Buses t2
    on t1.arrival_time <= t2.arrival_time
    where t2.bus_id is not null
)
select
    t5.bus_id,
    if(capacity >= passengers_cnt, passengers_cnt, capacity) passengers_cnt
from (
         select
             t3.bus_id,
             t3.capacity,
             count(1) passengers_cnt
         from Buses t3
                  left join choice_bus t4
                            on t3.bus_id = t4.bus_id and t4.candidate_order_number = 1
         group by t3.bus_id,t3.capacity
     ) t5
order by passengers_cnt;

    // 以下为错误思路实现，会导致遗漏乘客
/*, choice_bus as (
    select
        t1.passenger_id,
        t2.bus_id,
        t2.capacity,
        t1.arrival_time,
        t2.arrival_time,
        row_number() over (partition by t1.passenger_id order by t2.arrival_time - t1.arrival_time asc) as candidate_order_number
    from Passengers t1
             left join Buses t2
                       on t1.arrival_time <= t2.arrival_time
    where t2.bus_id is not null
)
select
    bus_id,
    count(passenger_id) passengers_cnt
from (
         select
             bus_id,
             capacity,
             passenger_id,
             count(1) over (partition by bus_id order by passenger_id) accuate_passgener_numbers
         from choice_bus t3
         where t3.candidate_order_number = 1
     ) t4
where capacity >= accuate_passgener_numbers
group by bus_id
order by passengers_cnt;*/
