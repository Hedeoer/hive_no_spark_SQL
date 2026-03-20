/*
====================================================================
题目：重新排列性别表 (Reformat Genders Table)
====================================================================

表：Genders
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| user_id     | int     |
| gender      | varchar |
+-------------+---------+
user_id 是该表的主键(具有唯一值的列)。
gender 的值是 'female', 'male', 'other' 之一。
该表中的每一行都包含用户的 ID 及其性别。
表格中 'female', 'male', 'other' 数量相等。

编写一个解决方案以重新排列 Genders 表，使行按顺序在 'female', 'other' 和 'male' 之间交替。
同时每种性别按照 user_id 升序进行排序。

按上述顺序返回结果表。

示例 1：

输入：
Genders 表：
+---------+--------+
| user_id | gender |
+---------+--------+
| 4       | male   |
| 7       | female |
| 2       | other  |
| 5       | male   |
| 1       | other  |
| 9       | female |
| 3       | female |
| 6       | other  |
| 8       | male   |
+---------+--------+

输出：
+---------+--------+
| user_id | gender |
+---------+--------+
| 3       | female |
| 1       | other  |
| 4       | male   |
| 7       | female |
| 2       | other  |
| 5       | male   |
| 9       | female |
| 6       | other  |
| 8       | male   |
+---------+--------+

解释：
女性: ID 3、7、9。
其他性别: ID 1、2、6。
男性: ID 4、5、8。
我们在 'female', 'other', 'male' 之间交替排列表。
注意，每种性别都是按 user_id 升序排序的。
*/

WITH Genders AS (
    SELECT 4 AS user_id, 'male' AS gender UNION ALL
    SELECT 7 AS user_id, 'female' AS gender UNION ALL
    SELECT 2 AS user_id, 'other' AS gender UNION ALL
    SELECT 5 AS user_id, 'male' AS gender UNION ALL
    SELECT 1 AS user_id, 'other' AS gender UNION ALL
    SELECT 9 AS user_id, 'female' AS gender UNION ALL
    SELECT 3 AS user_id, 'female' AS gender UNION ALL
    SELECT 6 AS user_id, 'other' AS gender UNION ALL
    SELECT 8 AS user_id, 'male' AS gender
)
-- ==========================================
-- 请在此处往下编写你的 Hive SQL 解答
-- ==========================================
, t1 as (
    select user_id,
           gender,
           row_number() over (order by gender_group_number,
               case gender
                    when 'female' then 1
                    when 'other' then 2
               else 3 end ) final_number
    from (
             select
                 user_id,
                 gender,
                 row_number() over (partition by gender order by user_id) gender_group_number
             from Genders
         )
)
select user_id,
       gender
from t1;