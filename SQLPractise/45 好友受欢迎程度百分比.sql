/*

 题目37 好友受欢迎百分比

 表: Friends
```
+----------------+------+
| 列名           | 类型 |
+----------------+------+
| user1 | int |
| user2 | int |
+----------------+------+
```

(user1, user2) 是该表的主键(具有唯一值的列)。
每一行包含关于好友关系的信息，其中 user1 和 user2 是好友。
编写一条 SQL 查询，找出 Meta/Facebook 平台上每个用户的受欢迎度百分比。受欢迎度百分比定义为用户拥有的好友总数除以平台上的用户数，然后乘以 100，并 四舍五入保留 2 位小数。
返回结果 user1 升序 排序的结果表。

示例 1:
输入:

Friends 表:
```
+------+------+
| user1 | user2 |
+------+------+
| 2    | 1    |
| 1    | 3    |
| 4    | 1    |
| 1    | 5    |
| 1    | 6    |
| 2    | 6    |
| 7    | 2    |
| 8    | 3    |
| 3    | 9    |
+------+------+
```

输出:
```
+------+---------------------+
| user1 | percentage_popularity |
+------+---------------------+
| 1    | 55.56               |
| 2    | 33.33               |
| 3    | 33.33               |
| 4    | 11.11               |
| 5    | 11.11               |
| 6    | 22.22               |
| 7    | 11.11               |
| 8    | 11.11               |
| 9    | 11.11               |
+------+---------------------+
```

解释:
平台上总共有 9 个用户。
- 用户"1"与 2、3、4、5 和 6 是朋友，因此，用户 1 的受欢迎度百分比计算为 (5/9) * 100 = 55.56。
- 用户"2"与 1、6 和 7 是朋友，因此，用户 2 的受欢迎度百分比计算为 (3/9) * 100 = 33.33。
- 用户"3"与 1、8 和 9 是朋友，因此，用户 3 的受欢迎度百分比计算为 (3/9) * 100 = 33.33。
- 用户"4"与 1 是朋友，因此，用户 4 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
- 用户"5"与 1 是朋友，因此，用户 5 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
- 用户"6"与 1 和 2 是朋友，因此，用户 6 的受欢迎度百分比计算为 (2/9) * 100 = 22.22。
- 用户"7"与 2 是朋友，因此，用户 7 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
- 用户"8"与 3 是朋友，因此，用户 8 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
- 用户"9"与 3 是朋友，因此，用户 9 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
user1 按升序排序。

```sql
WITH src AS(
    SELECT * FROM Friends
    UNION ALL
    SELECT user2 AS user1,user1 AS user2
    FROM Friends
),t AS(
    SELECT src.user1,COUNT(DISTINCT src.user2) AS f2,COUNT(src.user1) OVER() AS fa
    FROM src
    GROUP BY user1
)
SELECT t.user1,round(f2*100/fa,2) AS percentage_popularity
FROM t
ORDER BY t.user1
```
*/
WITH Friends AS (
    SELECT 2 AS user1, 1 AS user2 UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 4, 1 UNION ALL
    SELECT 1, 5 UNION ALL
    SELECT 1, 6 UNION ALL
    SELECT 2, 6 UNION ALL
    SELECT 7, 2 UNION ALL
    SELECT 8, 3 UNION ALL
    SELECT 3, 9
)
select
    distinct
    user1,
    round(count(distinct user2) over(partition by user1) /
    count(distinct user1) over () ,2) rate
from (
    select
        user1,
        user2
    from Friends
    UNION all
    select
        user2,
        user1
    from Friends
     ) t1
order by user1;
