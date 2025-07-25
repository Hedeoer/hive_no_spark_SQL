/*

表 `Person`:
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| id           | int     |
| name         | varchar |
| phone_number | varchar |
+--------------+---------+
```
id 是该表具有唯一值的列。
该表每一行包含一个人的名字和电话号码。
电话号码的格式是：'xxx-yyyyyyy'，其中 xxx 是国家码(3 个字符)，yyyyyyy 是电话号码(7 个字符)，x 和 y 都表示数字。同时，国家码和电话号码都可以包含前导 0。

表 `Country`:
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| name         | varchar |
| country_code | varchar |
+--------------+---------+
```
country_code 是该表具有唯一值的列。
该表每一行包含国家名和国家码。country_code 的格式是 'xxx'，x 是数字。

表 `Calls`:
```
+-----------+---------+
| Column Name | Type  |
+-----------+---------+
| caller_id | int     |
| callee_id | int     |
| duration  | int     |
+-----------+---------+
```
该表无主键，可能包含重复行。
每一行包含呼叫方 id，被呼叫方 id 和以分钟为单位的通话时长。caller_id != callee_id
一家电信公司想要投资新的国家。该公司想要投资的国家是： 该国的平均通话时长要严格地大于全球平均通话时长。
写一个解决方案，找到所有该公司可以投资的国家。
返回的结果表 无顺序要求。
结果格式如下例所示。

示例 1:

输入:
`Person` 表:
```
+----+----------+--------------+
| id | name     | phone_number |
+----+----------+--------------+
| 3  | Jonathan | 051-1234567  |
| 12 | Elvis    | 051-7654321  |
| 1  | Moncef   | 212-1234567  |
| 2  | Maroua   | 212-6523651  |
| 7  | Meir     | 972-1234567  |
| 9  | Rachel   | 972-0011100  |
+----+----------+--------------+
```
`Country` 表:
```
+---------+--------------+
| name    | country_code |
+---------+--------------+
| Peru    | 051          |
| Israel  | 972          |
| Morocco | 212          |
| Germany | 049          |
| Ethiopia| 251          |
+---------+--------------+
```
`Calls` 表:
```
+-----------+-----------+----------+
| caller_id | callee_id | duration |
+-----------+-----------+----------+
| 1         | 9         | 33       |
| 2         | 9         | 4        |
| 1         | 2         | 59       |
| 3         | 12        | 102      |
| 3         | 12        | 330      |
| 12        | 3         | 5        |
| 7         | 9         | 13       |
| 7         | 1         | 3        |
| 9         | 7         | 1        |
| 1         | 7         | 7        |
+-----------+-----------+----------+
```
输出:
```
+---------+
| country |
+---------+
| Peru    |
+---------+
```
解释:
国家 Peru 的平均通话时长是 (102 + 102 + 330 + 330 + 5 + 5) / 6 = 145.666667
国家 Israel 的平均通话时长是 (33 + 4 + 13 + 13 + 3 + 1 + 1 + 7) / 8 = 9.37500
国家 Morocco 的平均通话时长是 (33 + 4 + 59 + 59 + 3 + 7) / 6 = 27.5000
全球平均通话时长 = (2 * (33 + 4 + 59 + 102 + 330 + 5 + 13 + 3 + 1 + 7)) / 20 = 55.70000
所以，Peru 是唯一的平均通话时长大于全球平均通话时长的国家，也是唯一的推荐投资的国家。
*/

WITH
-- 1. 模拟 Person 表
Person AS (
    SELECT 3 AS id, 'Jonathan' AS name, '051-1234567' AS phone_number UNION ALL
    SELECT 12, 'Elvis', '051-7654321' UNION ALL
    SELECT 1, 'Moncef', '212-1234567' UNION ALL
    SELECT 2, 'Maroua', '212-6523651' UNION ALL
    SELECT 7, 'Meir', '972-1234567' UNION ALL
    SELECT 9, 'Rachel', '972-0011100'
),

-- 2. 模拟 Country 表
Country AS (
    SELECT 'Peru' AS name, '051' AS country_code UNION ALL
    SELECT 'Israel', '972' UNION ALL
    SELECT 'Morocco', '212' UNION ALL
    SELECT 'Germany', '049' UNION ALL
    SELECT 'Ethiopia', '251'
),

-- 3. 模拟 Calls 表
Calls AS (
    SELECT 1 AS caller_id, 9 AS callee_id, 33 AS duration UNION ALL
    SELECT 2, 9, 4 UNION ALL
    SELECT 1, 2, 59 UNION ALL
    SELECT 3, 12, 102 UNION ALL
    SELECT 3, 12, 330 UNION ALL
    SELECT 12, 3, 5 UNION ALL
    SELECT 7, 9, 13 UNION ALL
    SELECT 7, 1, 3 UNION ALL
    SELECT 9, 7, 1 UNION ALL
    SELECT 1, 7, 7
)
/*

-- 方式1
select name,
       average_country_duration,
       avg(average_country_duration) over () as average_global_duration
from (
         select
             '0' as gloabal_flag,
             t3.name,
             avg(t1.duration) as average_country_duration
         from Calls t1
                  left join Person t2
                            on t1.caller_id = t2.id
                  left join Country t3
                            on substr(t2.phone_number,0,3) = t3.country_code
         group by t3.name
     ) t4
*/


-- 方式2
select
    name
from (
         -- 每个国家的平均通话时长 和 全局的平均通话时长
         select name,
                average_country_duration,
                avg(average_country_duration) over () as average_global_duration
         from (
                  -- 计算每个国家的平均通话时长
                  select
                      t3.name,
                      avg(t1.duration) as average_country_duration
                  from Calls t1
                           left join Person t2
                                     on t1.caller_id = t2.id
                           left join Country t3
                                     on substr(t2.phone_number,0,3) = t3.country_code
                  group by t3.name
              ) t4

     ) t5
where average_country_duration > average_global_duration;
