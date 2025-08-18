/*
动作表: `Actions`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| user_id     | int     |
| post_id     | int     |
| action_date | date    |
| action      | enum    |
| extra       | varchar |
+-------------+---------+
```
这张表可能存在重复的行。
`action` 列的类型是 ENUM, 可能的值为 ('view', 'like', 'reaction', 'comment', 'report', 'share')。
`extra` 列拥有一些可选信息，例如：报告理由 (a reason for report)或反应类型 (a type of reaction)等。

移除表: `Removals`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| post_id     | int     |
| remove_date | date    |
+-------------+---------+
```
这张表的主键是 post_id (具有唯一值的列)。
这张表的每一行表示一个被移除的帖子，原因可能是由于被举报或被管理员审查。

编写解决方案，统计在被报告为垃圾广告的帖子中，被移除的帖子的每日平均占比，四舍五入到小数点后 2 位。
结果的格式如下。

示例 1:

输入:
`Actions table`:
```
+---------+---------+-------------+--------+---------+
| user_id | post_id | action_date | action | extra   |
+---------+---------+-------------+--------+---------+
| 1       | 1       | 2019-07-01  | view   | null    |
| 1       | 1       | 2019-07-01  | like   | null    |
| 1       | 1       | 2019-07-01  | share  | null    |
| 2       | 2       | 2019-07-04  | view   | null    |
| 2       | 2       | 2019-07-04  | report | spam    |
| 3       | 4       | 2019-07-04  | view   | null    |
| 3       | 4       | 2019-07-04  | report | spam    |
| 4       | 3       | 2019-07-02  | view   | null    |
| 4       | 3       | 2019-07-02  | report | spam    |
| 5       | 2       | 2019-07-03  | view   | null    |
| 5       | 2       | 2019-07-03  | report | racism  |
| 5       | 5       | 2019-07-03  | view   | null    |
| 5       | 5       | 2019-07-03  | report | racism  |
+---------+---------+-------------+--------+---------+
```
`Removals table`:
```
+---------+-------------+
| post_id | remove_date |
+---------+-------------+
| 2       | 2019-07-20  |
| 3       | 2019-07-18  |
+---------+-------------+
```
输出:
```
+-----------------------+
| average_daily_percent |
+-----------------------+
| 75.00                 |
+-----------------------+
```
解释:
2019-07-04 的垃圾广告移除率是 50%，因为有两张帖子被报告为垃圾广告，但只有一个得到移除。
2019-07-02 的垃圾广告移除率是 100%，因为有一张帖子被举报为垃圾广告并得到移除。
其余几天没有收到垃圾广告的举报，因此平均值为: (50 + 100) / 2 = 75%
注意，输出仅需要一个平均值即可，我们并不关注移除操作的日期。
*/


WITH
-- 1. 模拟 Actions 表
Actions AS (
    SELECT 1 AS user_id, 1 AS post_id, CAST('2019-07-01' AS DATE) AS action_date, 'view' AS action, CAST(NULL AS STRING) AS extra UNION ALL
    SELECT 1, 1, CAST('2019-07-01' AS DATE), 'like', NULL UNION ALL
    SELECT 1, 1, CAST('2019-07-01' AS DATE), 'share', NULL UNION ALL
    SELECT 2, 2, CAST('2019-07-04' AS DATE), 'view', NULL UNION ALL
    SELECT 2, 2, CAST('2019-07-04' AS DATE), 'report', 'spam' UNION ALL
    SELECT 3, 4, CAST('2019-07-04' AS DATE), 'view', NULL UNION ALL
    SELECT 3, 4, CAST('2019-07-04' AS DATE), 'report', 'spam' UNION ALL
    SELECT 4, 3, CAST('2019-07-02' AS DATE), 'view', NULL UNION ALL
    SELECT 4, 3, CAST('2019-07-02' AS DATE), 'report', 'spam' UNION ALL
    SELECT 5, 2, CAST('2019-07-03' AS DATE), 'view', NULL UNION ALL
    SELECT 5, 2, CAST('2019-07-03' AS DATE), 'report', 'racism' UNION ALL
    SELECT 5, 5, CAST('2019-07-03' AS DATE), 'view', NULL UNION ALL
    SELECT 5, 5, CAST('2019-07-03' AS DATE), 'report', 'racism'
),

-- 2. 模拟 Removals 表
Removals AS (
    SELECT 2 AS post_id, CAST('2019-07-20' AS DATE) AS remove_date UNION ALL
    SELECT 3, CAST('2019-07-18' AS DATE)
)

select
    round(avg(date_rate),2) * 100 as average_daily_percent
from (
         select
             t1.action_date,
             count(distinct t2.post_id) / count(distinct t1.post_id) date_rate
         from Actions t1
                  left join Removals t2
                            on t1.post_id = t2.post_id
         where t1.action = 'report' and t1.extra = 'spam'
         group by t1.action_date

     ) t3

