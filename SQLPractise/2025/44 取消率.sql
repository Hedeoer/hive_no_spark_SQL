/*
表: `Trips`
```
+-------------+-------------------------------------------------+
| Column Name | Type                                            |
+-------------+-------------------------------------------------+
| id          | int                                             |
| client_id   | int                                             |
| driver_id   | int                                             |
| city_id     | int                                             |
| status      | enum                                            |
| request_at  | varchar                                         |
+-------------+-------------------------------------------------+
```
`id` 是这张表的主键 (具有唯一值的列) 。
这张表中存有所有出租车的行程信息。每段行程有唯一 `id` ，其中 `client_id` 和 `driver_id` 是 `Users` 表中 `users_id` 的外键。
`status` 是一个表示行程状态的枚举类型，枚举成员为(`'completed'`, `'cancelled_by_driver'`, `'cancelled_by_client'`) 。

表: `Users`
```
+-------------+----------------------------------+
| Column Name | Type                             |
+-------------+----------------------------------+
| users_id    | int                              |
| banned      | enum                             |
| role        | enum                             |
+-------------+----------------------------------+
```
`users_id` 是这张表的主键 (具有唯一值的列)。
这张表中存有所有用户，每个用户都有一个唯一的 `users_id` ，`role` 是一个表示用户身份的枚举类型，枚举成员为 (`'client'`, `'driver'`, `'partner'`)。
`banned` 是一个表示用户是否被禁止的枚举类型，枚举成员为 (`'Yes'`, `'No'`) 。

取消率的计算方式如下: (被司机或乘客取消的非禁止用户生成的订单数量) / (非禁止用户生成的订单总数)。
编写解决方案找出 "2013-10-01" 至 "2013-10-03" 期间有 至少一次行程的非禁止用户 (乘客和司机都必须未被禁止) 的取消率。非禁止用户即 `banned` 为 `No` 的用户，禁止用户即 `banned` 为 `Yes` 的用户。其中取消率 `Cancellation Rate` 需要四舍五入保留 两位小数。
返回结果表中的数据 无顺序要求。
结果格式如下例所示。

示例 1:

输入:
`Trips` 表:
```
+----+-----------+-----------+---------+------------------------+------------+
| id | client_id | driver_id | city_id | status                 | request_at |
+----+-----------+-----------+---------+------------------------+------------+
| 1  | 1         | 10        | 1       | completed              | 2013-10-01 |
| 2  | 2         | 11        | 1       | cancelled_by_driver    | 2013-10-01 |
| 3  | 3         | 12        | 6       | completed              | 2013-10-01 |
| 4  | 4         | 13        | 6       | cancelled_by_client    | 2013-10-01 |
| 5  | 1         | 10        | 1       | completed              | 2013-10-02 |
| 6  | 2         | 11        | 6       | completed              | 2013-10-02 |
| 7  | 3         | 12        | 6       | completed              | 2013-10-02 |
| 8  | 2         | 12        | 12      | completed              | 2013-10-03 |
| 9  | 3         | 10        | 12      | completed              | 2013-10-03 |
| 10 | 4         | 13        | 12      | cancelled_by_driver    | 2013-10-03 |
+----+-----------+-----------+---------+------------------------+------------+
```
`Users` 表:
```
+----------+--------+---------+
| users_id | banned | role    |
+----------+--------+---------+
| 1        | No     | client  |
| 2        | Yes    | client  |
| 3        | No     | client  |
| 4        | No     | client  |
| 10       | No     | driver  |
| 11       | No     | driver  |
| 12       | No     | driver  |
| 13       | No     | driver  |
+----------+--------+---------+
```
输出:
```
+------------+-------------------+
| Day        | Cancellation Rate |
+------------+-------------------+
| 2013-10-01 | 0.33              |
| 2013-10-02 | 0.00              |
| 2013-10-03 | 0.50              |
+------------+-------------------+
```
解释:
2013-10-01:
- 共有 4 条请求，其中 2 条取消。
- 然而，id=2 的请求是由禁止用户 (user_id=2) 发出的，所以计算时应当忽略它。
- 因此，总共有 3 条非禁止请求参与计算，其中 1 条取消。
- 取消率为 (1 / 3) = 0.33
2013-10-02:
- 共有 3 条请求，其中 0 条取消。
- 然而，id=6 的请求是由禁止用户发出的，所以计算时应当忽略它。
- 因此，总共有 2 条非禁止请求参与计算，其中 0 条取消。
- 取消率为 (0 / 2) = 0.00
2013-10-03:
- 共有 3 条请求，其中 1 条取消。
- 然而，id=8 的请求是由禁止用户发出的，所以计算时应当忽略它。
- 因此，总共有 2 条非禁止请求参与计算，其中 1 条取消。
- 取消率为 (1 / 2) = 0.50

*/
WITH
-- 1. 模拟 Trips 表
Trips AS (
    SELECT 1 AS id, 1 AS client_id, 10 AS driver_id, 1 AS city_id, 'completed' AS status, '2013-10-01' AS request_at UNION ALL
    SELECT 2, 2, 11, 1, 'cancelled_by_driver', '2013-10-01' UNION ALL
    SELECT 3, 3, 12, 6, 'completed', '2013-10-01' UNION ALL
    SELECT 4, 4, 13, 6, 'cancelled_by_client', '2013-10-01' UNION ALL
    SELECT 5, 1, 10, 1, 'completed', '2013-10-02' UNION ALL
    SELECT 6, 2, 11, 6, 'completed', '2013-10-02' UNION ALL
    SELECT 7, 3, 12, 6, 'completed', '2013-10-02' UNION ALL
    SELECT 8, 2, 12, 12, 'completed', '2013-10-03' UNION ALL
    SELECT 9, 3, 10, 12, 'completed', '2013-10-03' UNION ALL
    SELECT 10, 4, 13, 12, 'cancelled_by_driver', '2013-10-03'
),

-- 2. 模拟 Users 表
Users AS (
    SELECT 1 AS users_id, 'No' AS banned, 'client' AS role UNION ALL
    SELECT 2, 'Yes', 'client' UNION ALL
    SELECT 3, 'No', 'client' UNION ALL
    SELECT 4, 'No', 'client' UNION ALL
    SELECT 10, 'No', 'driver' UNION ALL
    SELECT 11, 'No', 'driver' UNION ALL
    SELECT 12, 'No', 'driver' UNION ALL
    SELECT 13, 'No', 'driver'
)
/*
思路：
1. 连接 Trips 和 Users 表，筛选出非禁止用户的行程记录
2. 日期筛选 和 至少一次行程
3. 取消率
*/
select
    t4.request_at,
    round(count(`if`(t4.status = 'cancelled_by_driver' or t4.status = 'cancelled_by_client', 1, null)) / count(1),2) as `Cancellation Rate`
from (
         select
             t1.id,
             t1.client_id,
             t1.driver_id,
             t1.request_at,
             t1.status
         from Trips t1
                  left join Users t2
                            on t1.client_id = t2.users_id
                  left join Users t3
                            on t1.driver_id = t3.users_id
         where t2.banned = 'No' and t3.banned = 'No'
           and t1.request_at between '2013-10-01' and '2013-10-03'
     )t4
group by t4.request_at