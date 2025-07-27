/*
表: `Listens`
```
+-----------+---------+
| Column Name | Type  |
+-----------+---------+
| user_id   | int     |
| song_id   | int     |
| day       | date    |
+-----------+---------+
```
这个表没有主键，可能存在重复项。
表中的每一行表示用户 `user_id` 在 `day` 这一天收听的歌曲 `song_id`。

表: `Friendship`
```
+-----------+---------+
| Column Name | Type  |
+-----------+---------+
| user1_id  | int     |
| user2_id  | int     |
+-----------+---------+
```
(user1_id, user2_id) 是这个表的主键。
表中的每一行表示 `user1_id` 和 `user2_id` 是好友。
注意，`user1_id < user2_id`。

写出 SQL 语句，为 Leetcodify 用户推荐好友。我们将符合下列条件的用户 `x` 推荐给用户 `y`：
用户 `x` 和 `y` 不是好友，且
用户 `x` 和 `y` 在同一天收听了相同的三首或更多不同歌曲。
注意，好友推荐是单向的，这意味着如果用户 `x` 和用户 `y` 需要互相推荐给对方，结果表需要将用户 `x` 推荐给用户 `y` 并将用户 `y` 推荐给用户 `x`。另外，结果表不得出现重复项（即，用户 `y` 不可多次推荐给用户 `x`）。
按任意顺序返回结果表。

查询格式如下示例所示:

示例 1:

输入:
`Listens` 表:
```
+---------+---------+------------+
| user_id | song_id | day        |
+---------+---------+------------+
| 1       | 10      | 2021-03-15 |
| 1       | 11      | 2021-03-15 |
| 1       | 12      | 2021-03-15 |
| 2       | 10      | 2021-03-15 |
| 2       | 11      | 2021-03-15 |
| 2       | 12      | 2021-03-15 |
| 3       | 10      | 2021-03-15 |
| 3       | 11      | 2021-03-15 |
| 3       | 12      | 2021-03-15 |
| 4       | 10      | 2021-03-15 |
| 4       | 11      | 2021-03-15 |
| 4       | 13      | 2021-03-15 |
| 5       | 10      | 2021-03-16 |
| 5       | 11      | 2021-03-16 |
| 5       | 12      | 2021-03-16 |
+---------+---------+------------+
```
`Friendship` 表:
```
+----------+----------+
| user1_id | user2_id |
+----------+----------+
| 1        | 2        |
+----------+----------+
```
输出:
```
+---------+----------------+
| user_id | recommended_id |
+---------+----------------+
| 1       | 3              |
| 2       | 3              |
| 3       | 1              |
| 3       | 2              |
+---------+----------------+
```
解释
用户 `1` 和 `2` 在同一天收听了歌曲 `10`、`11` 和 `12`，但他们已经是好友了。
用户 `1` 和 `3` 在同一天收听了歌曲 `10`、`11` 和 `12`。由于他们不是好友，所以我们给他们互相推荐为好友。
用户 `1` 和 `4` 没有收听三首相同的歌曲。
用户 `1` 和 `5` 收听了歌曲 `10`、`11` 和 `12`，但不是在同一天收听的。

类似地，我们可以发现用户 `2` 和 `3` 在同一天收听了歌曲 `10`、`11` 和 `12`，且他们不是好友，所以我们给他们互相推荐为好友。


*/



WITH
-- 1. 模拟 Listens 表
Listens AS (
    SELECT 1 AS user_id, 10 AS song_id, CAST('2021-03-15' AS DATE) AS day UNION ALL
    SELECT 1, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 1, 12, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 2, 10, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 2, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 2, 12, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 3, 10, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 3, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 3, 12, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 4, 10, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 4, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 4, 13, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 5, 10, CAST('2021-03-16' AS DATE) UNION ALL
    SELECT 5, 11, CAST('2021-03-16' AS DATE) UNION ALL
    SELECT 5, 12, CAST('2021-03-16' AS DATE)
),

-- 2. 模拟 Friendship 表
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id
),
-- 3. 计算每个用户在每一天收听的歌曲数量在3首或以上的用户对
user_limit as (
    select user_id,
           song_id,
           day
    from (
             select user_id,
                    song_id,
                    day,
                    count(distinct song_id) over (partition by user_id, day) as song_count
             from Listens t1

         ) t2
    where song_count >= 3
    group by song_id, user_id, day
),
distinct_user_pair as (
    select
        user_id,
        recommended_id
    from (
             select
                 t1.user_id,
                 t2.user_id as recommended_id,
                 t1.song_id,
                 t1.day,
                 -- 计算不为好友的用户对在同一天收听相同歌曲的数量
                 count(distinct t1.song_id) over(partition by t1.user_id, t2.user_id, t1.day) as song_count
             from user_limit t1
                      -- 选择不同的用户对,对于同一天和同一首歌
                      inner join user_limit t2
                 -- 减少重复计算，比如《用户1 和用户2》，《用户2 和 用户1》是相同的
                                 on t1.user_id < t2.user_id
                                     and t1.day = t2.day
                                     and t1.song_id = t2.song_id
                 -- 排除已经是好友的用户对
                      left join Friendship t3
                                on t1.user_id = t3.user1_id
                                    and t2.user_id = t3.user2_id
             where t3.user1_id is null
         ) t4
    where song_count >= 3
    group by user_id,
             recommended_id
)
-- 4. 返回单向推荐的用户对
select user_id,recommended_id from distinct_user_pair
union  all
select recommended_id,user_id from distinct_user_pair;

-- 第二种简化写法
/*
WITH L AS(
    SELECT user_id, song_id, day
    FROM Listens
    GROUP BY user_id, song_id, day
),
T AS(
    SELECT L1.user_id AS u1_id, L2.user_id AS u2_id, L1.day, L1.song_id
    FROM L L1, L L2
    WHERE L1.day = L2.day AND L1.song_id = L2.song_id AND L1.user_id < L2.user_id
),
D AS(
    SELECT u1_id, u2_id, day
    FROM T
    GROUP BY u1_id, u2_id, day HAVING COUNT(*) >= 3
),
ANS AS(
    SELECT u1_id, u2_id
    FROM D
    GROUP BY u1_id, u2_id
    EXCEPT
    SELECT * FROM Friendship
)
SELECT u1_id AS user_id, u2_id AS recommended_id FROM ANS
UNION
SELECT u2_id, u1_id FROM ANS
EXCEPT
SELECT user2_id, user1_id FROM Friendship
*/