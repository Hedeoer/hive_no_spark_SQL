
/*
表: `Visits`
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| user_id     | int     |
| visit_date  | date    |
+-------------+---------+
```
(user_id, visit_date) 是该表的主键(具有唯一值的列的组合)
该表的每行表示 user_id 在 visit_date 访问了银行

表: `Trans`
```
+------------------+---------+
| Column Name      | Type    |
+------------------+---------+
| user_id          | int     |
| transaction_date | date    |
| amount           | int     |
+------------------+---------+
```
该表可能有重复行
该表的每一行表示 user_id 在 transaction_date 完成了一笔 amount 数额的交易
可以保证用户 (user) 在 transaction_date 访问了银行 (也就是说 Visits 表包含 (user_id, transaction_date) 行)

银行想要得到银行客户在一次访问时的交易次数和相应的在一次访问时该交易次数的客户数量的图表
编写解决方案找出多少客户访问了银行但没有进行任何交易，多少客户访问了银行进行了一次交易等等
结果包含两列:
`Trans_count`: 客户在一次访问中的交易次数
`visits_count`: 在 `Trans_count` 交易次数下相应的一次访问时的客户数量
`Trans_count` 的值从 `0` 到所有用户一次访问中的 `max(Trans_count)`
结果按 `Trans_count` 排序
下面是返回结果格式的例子：

示例 1:
输入:
`Visits` 表:
```
+---------+------------+
| user_id | visit_date |
+---------+------------+
| 1       | 2020-01-01 |
| 2       | 2020-01-02 |
| 12      | 2020-01-01 |
| 19      | 2020-01-03 |
| 1       | 2020-01-02 |
| 2       | 2020-01-03 |
| 1       | 2020-01-04 |
| 7       | 2020-01-11 |
| 9       | 2020-01-25 |
| 8       | 2020-01-28 |
+---------+------------+
```
`Trans` 表:
```
+---------+------------------+--------+
| user_id | transaction_date | amount |
+---------+------------------+--------+
| 1       | 2020-01-02       | 120    |
| 2       | 2020-01-03       | 22     |
| 7       | 2020-01-11       | 232    |
| 1       | 2020-01-04       | 7      |
| 9       | 2020-01-25       | 33     |
| 9       | 2020-01-25       | 66     |
| 8       | 2020-01-28       | 1      |
| 9       | 2020-01-25       | 99     |
+---------+------------------+--------+
```
输出:
```
+--------------------+--------------+
| Trans_count | visits_count |
+--------------------+--------------+
| 0                  | 4            |
| 1                  | 5            |
| 2                  | 0            |
| 3                  | 1            |
+--------------------+--------------+
```
解释: 为这个例子绘制的图表如上所示
*   对于 Trans_count = 0, visits 中 (1, "2020-01-01"), (2, "2020-01-02"), (12, "2020-01-01") 和 (19, "2020-01-03") 没有进行交易, 所以 visits_count = 4 。
*   对于 Trans_count = 1, visits 中 (1, "2020-01-02"), (2, "2020-01-03"), (7, "2020-01-11"), (1, "2020-01-04") 和 (8, "2020-01-28") 进行了一次交易, 所以 visits_count = 5 。
*   对于 Trans_count = 2, 没有客户访问银行进行了两次交易, 所以 visits_count = 0 。
*   对于 Trans_count = 3, visits 中 (9, "2020-01-25") 进行了三次交易, 所以 visits_count = 1 。
*   对于 Trans_count >= 4, 没有客户访问银行进行了超过3次交易,所以我们停止在 Trans_count = 3 。


*/


/*
1. 访问银行但是没有进行交易的交易次数（0）和相应的访问银行次数
2. 访问银行但是进行交易的交易1次和相应的访问银行次数
3. 访问银行但是进行交易的交易2次和相应的访问银行次数

*/

WITH
-- 1. 模拟 Visits 表
Visits AS (
    SELECT 1 AS user_id, CAST('2020-01-01' AS DATE) AS visit_date UNION ALL
    SELECT 2,  CAST('2020-01-02' AS DATE) UNION ALL
    SELECT 12, CAST('2020-01-01' AS DATE) UNION ALL
    SELECT 19, CAST('2020-01-03' AS DATE) UNION ALL
    SELECT 1,  CAST('2020-01-02' AS DATE) UNION ALL
    SELECT 2,  CAST('2020-01-03' AS DATE) UNION ALL
    SELECT 1,  CAST('2020-01-04' AS DATE) UNION ALL
    SELECT 7,  CAST('2020-01-11' AS DATE) UNION ALL
    SELECT 9,  CAST('2020-01-25' AS DATE) UNION ALL
    SELECT 8,  CAST('2020-01-28' AS DATE)
),

-- 2. 模拟 Trans 表
Trans AS (
    SELECT 1 AS user_id, CAST('2020-01-02' AS DATE) AS transaction_date, 120 AS amount UNION ALL
    SELECT 2, CAST('2020-01-03' AS DATE), 22  UNION ALL
    SELECT 7, CAST('2020-01-11' AS DATE), 232 UNION ALL
    SELECT 1, CAST('2020-01-04' AS DATE), 7   UNION ALL
    SELECT 9, CAST('2020-01-25' AS DATE), 33  UNION ALL
    SELECT 9, CAST('2020-01-25' AS DATE), 66  UNION ALL
    SELECT 8, CAST('2020-01-28' AS DATE), 1   UNION ALL
    SELECT 9, CAST('2020-01-25' AS DATE), 99
),

-- 3. 计算每次访问的交易次数
VisitTrans AS (
    SELECT
        v.user_id,
        v.visit_date,
        COUNT(t.transaction_date) AS Trans_count
    FROM
        Visits v
            LEFT JOIN
        Trans t ON v.user_id = t.user_id AND v.visit_date = t.transaction_date
    GROUP BY
        v.user_id, v.visit_date
),

-- 4. 按交易次数统计实际的访问量
AggregatedVisits AS (
    SELECT
        Trans_count,
        COUNT(1) AS visits_count
    FROM
        VisitTrans
    GROUP BY
        Trans_count
),

-- 5. 使用 posexplode 生成从 0 到最大交易次数的数字序列
NumberSequence AS (
    SELECT pos AS n
    FROM (
             SELECT MAX(Trans_count) AS t_max
             FROM VisitTrans
         ) base
    LATERAL VIEW posexplode(split(repeat(',', CAST(t_max AS INT)), ',')) pe AS pos, val
    )

-- 6. 最终查询：将数字序列与统计结果连接，填充缺失的交易次数
SELECT
    t1.n,
    NVL(t2.visits_count, 0) AS visits_count
FROM
    NumberSequence t1
        LEFT JOIN
    AggregatedVisits t2 ON t1.n = t2.Trans_count
ORDER BY
    n;