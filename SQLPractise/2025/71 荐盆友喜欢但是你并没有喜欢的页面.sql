/*
朋友关系列表: `Friendship`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| user1_id    | int     |
| user2_id    | int     |
+-------------+---------+
```
`(user1_id, user2_id)` 是这张表具有唯一值的列的组合。
这张表的每一行代表着 `user1_id` 和 `user2_id` 之间存在着朋友关系。

喜欢列表: `Likes`
```
+-------------+---------+
| 列名        | 类型    |
+-------------+---------+
| user_id     | int     |
| page_id     | int     |
+-------------+---------+
```
`(user_id, page_id)` 是这张表具有唯一值的列的组合。
这张表的每一行代表着 `user_id` 喜欢 `page_id`。

编写解决方案，向`user_id = 1`的用户，推荐其朋友们喜欢的页面。不要推荐该用户已经喜欢的页面。
以任意顺序 返回结果，其中不应当包含重复项。
返回结果的格式如下例所示。

示例 1:

输入:
`Friendship table`:
```
+----------+----------+
| user1_id | user2_id |
+----------+----------+
| 1        | 2        |
| 1        | 3        |
| 1        | 4        |
| 2        | 3        |
| 2        | 4        |
| 2        | 5        |
| 6        | 1        |
+----------+----------+
```
`Likes table`:
```
+---------+---------+
| user_id | page_id |
+---------+---------+
| 1       | 88      |
| 2       | 23      |
| 3       | 24      |
| 4       | 56      |
| 5       | 11      |
| 6       | 33      |
| 2       | 77      |
| 3       | 77      |
| 6       | 88      |
+---------+---------+
```
输出:
```
+------------------+
| recommended_page |
+------------------+
| 23               |
| 24               |
| 56               |
| 33               |
| 77               |
+------------------+
```
解释:
用户1 同 用户2, 3, 4, 6 是朋友关系。
推荐页面为： 页面23 来自于 用户2, 页面24 来自于 用户3, 页面56 来自于 用户4 以及 页面33 来自于 用户6。
页面77 同时被 用户2 和 用户3 推荐。
页面88 没有被推荐, 因为 用户1 已经喜欢了它。
*/

WITH
-- 1. 模拟 Friendship 表
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 1, 4 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 2, 5 UNION ALL
    SELECT 6, 1
),

-- 2. 模拟 Likes 表
Likes AS (
    SELECT 1 AS user_id, 88 AS page_id UNION ALL
    SELECT 2, 23 UNION ALL
    SELECT 3, 24 UNION ALL
    SELECT 4, 56 UNION ALL
    SELECT 5, 11 UNION ALL
    SELECT 6, 33 UNION ALL
    SELECT 2, 77 UNION ALL
    SELECT 3, 77 UNION ALL
    SELECT 6, 88
),
page_like_situation as
    (
        SELECT
            t2.my_id,
            t3.page_id my_like_page,
            t2.friend_id,
            t4.page_id friend_like_page
        FROM
            (
                SELECT
                    user1_id my_id,
                    user2_id friend_id
                FROM
                    Friendship t0
                UNION ALL
                SELECT
                    user2_id,
                    user1_id
                FROM
                    Friendship t1
            ) t2
                LEFT JOIN Likes t3 ON t2.my_id = t3.user_id
                LEFT JOIN Likes t4 ON t2.friend_id = t4.user_id
    )
-- 方式1
/*
SELECT
    my_id,
    friend_like_page
FROM page_like_situation tt
WHERE tt.my_id = 1 AND tt.my_like_page != tt.friend_like_page
GROUP BY my_id, friend_like_page;
*/

-- 方式2 ,使用的spark sql 版本为3.3.1
select
    my_id,
    array_except(
            collect_set(friend_like_page),
            collect_set(my_like_page)
    ) as recommended_page

from page_like_situation t0
where my_id = 1
group by my_id

-- 方式3
/*
select
    t0.page_id as recommended_page
from Likes t0
-- 自己未关注的页面
where page_id not in (
    select
        t1.page_id
    from Likes t1
    where t1.user_id = 1
    )
  -- 朋友关注的页面
and t0.user_id in (
    select
        user2_id
    from Friendship t2
    where t2.user1_id = 1
    union
    select
        user1_id
    from Friendship t3
    where t3.user2_id = 1
    )
group by t0.page_id;
*/

-- 方式4 ，但数据基数（此处指系统中所有page_id去重后的数据量）达到 百万及以上级别， 可以考虑使用 bitmap实现