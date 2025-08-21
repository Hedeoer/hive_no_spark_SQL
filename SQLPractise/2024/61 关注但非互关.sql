/*

表: `Follow`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| followee  | varchar |
| follower  | varchar |
+-----------+---------+
```
(followee, follower) 是该表的主键(具有唯一值的列的组合)。 follower是 关注者，followee是被关注者。
该表的每一行表示关注者关注了社交网络上的被关注者。
不会有用户关注他们自己。

二级关注者 是指满足以下条件的用户:
关注至少一个用户，
被至少一个用户关注。

编写一个解决方案来报告 二级用户 及其关注者的数量。
返回按 follower 字典序排序 的结果表。
结果格式如下所示。

示例 1:

输入:
`Follow table`:
```
+----------+----------+
| followee | follower |
+----------+----------+
| Alice    | Bob      |
| Bob      | Cena     |
| Bob      | Donald   |
| Donald   | Edward   |
+----------+----------+
```
输出:
```
+----------+-----+
| follower | num |
+----------+-----+
| Bob      | 2   |
| Donald   | 1   |
+----------+-----+
```
解释:
用户 Bob 有 2 个关注者。Bob 是二级关注者，因为他关注了 Alice，所以我们把他包括在结果表中。
用户 Donald 有 1 个关注者。Donald 是二级关注者，因为他关注了 Bob，所以我们把他包括在结果表中。
用户 Alice 有 1 个关注者。Alice 不是二级关注者，但是她不关注任何人，所以我们不把她包括在结果表中。

*/
WITH
-- 1. 模拟 Follow 表
Follow AS (
    SELECT 'Alice' AS followee, 'Bob' AS follower UNION ALL
    SELECT 'Bob', 'Cena' UNION ALL
    SELECT 'Bob', 'Donald' UNION ALL
    SELECT 'Donald', 'Edward'
)
/*
    -- 2. 计算每个用户的关注者数量
    followers AS (
        select
            t1.followee,
            count(1) follower_count
        from Follow t1
        group by t1.followee
    ),

    -- 3. 二级用户有哪些
    lv2_users as(
        select
            followee
        from (
                 select
                     followee
                 from Follow
                 union all
                 select
                     follower
                 from Follow
             )t1
        group by followee
        having count(1) > 1
    )
select
    t1.followee,
    t2.follower_count
from lv2_users t1
left join followers t2
on t1.followee = t2.followee;
*/

/*
-- 方式2
select
t1.followee,
count(distinct t1.follower) follower_count
from Follow t1 -- 被关注者
cross join Follow t2 -- 关注者
on t1.followee = t2.follower
group by t1.followee
*/

-- 方式3
select
    followee,
    count(distinct follower) as num
from Follow
where followee in (select distinct follower from Follow)
group by followee