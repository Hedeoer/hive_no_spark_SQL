/*
表: `Contests`
```
+--------------+------+
| Column Name  | Type |
+--------------+------+
| contest_id   | int  |
| gold_medal   | int  |
| silver_medal | int  |
| bronze_medal | int  |
+--------------+------+
```
`contest_id` 是该表的主键。
该表包含LeetCode竞赛的ID和该场比赛中金牌、银牌、铜牌的用户id。
可以保证，所有连续的比赛都有连续的ID，没有ID被跳过。

Table: `Users`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| user_id   | int     |
| mail      | varchar |
| name      | varchar |
+-----------+---------+
```
`user_id` 是该表的主键。
该表包含用户信息。

编写 SQL 语句来返回 所有面试候选人 的姓名 `name` 和邮件 `mail`。当用户满足以下两个要求中的 **任意一条**，其成为 面试候选人：
- 该用户在 **连续三场及更多** 比赛中赢得 **任意** 奖牌。
- 该用户在 **三场及更多不同**的 比赛中赢得 **金牌** (这些比赛可以不是连续的)

可以以 任何顺序 返回结果。
查询结果格式如下例所示。

示例 1:
输入:
`Contests`表:
```
+------------+------------+--------------+--------------+
| contest_id | gold_medal | silver_medal | bronze_medal |
+------------+------------+--------------+--------------+
| 190        | 1          | 5            | 2            |
| 191        | 2          | 3            | 5            |
| 192        | 5          | 2            | 3            |
| 193        | 1          | 3            | 5            |
| 194        | 4          | 5            | 2            |
| 195        | 4          | 2            | 1            |
| 196        | 1          | 5            | 2            |
+------------+------------+--------------+--------------+
```
`Users`表:
```
+---------+--------------------+--------+
| user_id | mail               | name   |
+---------+--------------------+--------+
| 1       | sarah@leetcode.com | Sarah  |
| 2       | bob@leetcode.com   | Bob    |
| 3       | alice@leetcode.com | Alice  |
| 4       | hercy@leetcode.com | Hercy  |
| 5       | quarz@leetcode.com | Quarz  |
+---------+--------------------+--------+
```
输出:
```
+--------+--------------------+
| name   | mail               |
+--------+--------------------+
| Sarah  | sarah@leetcode.com |
| Bob    | bob@leetcode.com   |
| Alice  | alice@leetcode.com |
| Quarz  | quarz@leetcode.com |
+--------+--------------------+
```
解释:
- Sarah 赢得了3块金牌 (190, 193, and 196), 所以我们将她列入结果表。
- Bob在连续3场竞赛中赢得了奖牌(190, 191, and 192), 所以我们将他列入结果表。
  - 注意他在另外的连续3场竞赛中也赢得了奖牌(194, 195, and 196).
- Alice在连续3场竞赛中赢得了奖牌(191, 192, and 193), 所以我们将她列入结果表。
- Quarz在连续5场竞赛中赢得了奖牌(190, 191, 192, 193, and 194), 所以我们将他列入结果表。


*/

WITH
-- 1. 模拟 Contests 表
Contests AS (
    SELECT 190 AS contest_id, 1 AS gold_medal, 5 AS silver_medal, 2 AS bronze_medal UNION ALL
    SELECT 191, 2, 3, 5 UNION ALL
    SELECT 192, 5, 2, 3 UNION ALL
    SELECT 193, 1, 3, 5 UNION ALL
    SELECT 194, 4, 5, 2 UNION ALL
    SELECT 195, 4, 2, 1 UNION ALL
    SELECT 196, 1, 5, 2
),

-- 2. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, 'sarah@leetcode.com' AS mail, 'Sarah' AS name UNION ALL
    SELECT 2, 'bob@leetcode.com', 'Bob' UNION ALL
    SELECT 3, 'alice@leetcode.com', 'Alice' UNION ALL
    SELECT 4, 'hercy@leetcode.com', 'Hercy' UNION ALL
    SELECT 5, 'quarz@leetcode.com', 'Quarz'
),
-- 获取连续三场及以上比赛获奖的用户，不区分奖牌类型
contious_three_medals_users as (
    select
        user_id
    from (
             select
                 user_id
             from (

                      select contest_id,
                             case idx
                                 when 1 then gold_medal
                                 when 2 then silver_medal
                                 else bronze_medal
                                 end as user_id,
                             -- 构建一个分组标识符，用于区分连续的比赛
                             contest_id - row_number() over (partition by case idx
                                                                              when 1 then gold_medal
                                                                              when 2 then silver_medal
                                                                              else bronze_medal
                                 end
                                 order by contest_id) as contest_group
                      from Contests t1
                           -- 将金银铜牌的用户ID展开
                          lateral view explode(array(1,2,3)) t as idx
                  ) t1
             -- 统计每个用户在连续比赛组中的获奖次数
             group by user_id, contest_group
             -- 筛选出满足连续三场及以上比赛获奖的用户，不区分奖牌类型
             having count(1) >= 3
         ) t2
-- 去重用户
    group by user_id
),
-- 获取三次及以上金牌的用户
gold_three_medals_users as (
    select
        distinct gold_medal as user_id
    from (
             select
                 gold_medal
             from Contests
             group by gold_medal
             having count(*) >= 3
         ) t1
)
select
    name,
    mail
from Users t1
         inner join (
    select user_id from contious_three_medals_users
    union
    select user_id from gold_three_medals_users
) t2
                    on t1.user_id = t2.user_id;