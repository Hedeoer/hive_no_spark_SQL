/*

用户：Users

| Column Name | Type    |
|-------------|---------|
| user_id     | int     |
| user_name   | varchar |
| credit      | int     |

user_id 是这个表的主键 (具有唯一性的列)。
表中的每一行都包含一个用户当前的信用信息。

交易者：Transactions

| Column Name  | Type    |
|--------------|---------|
| trans_id     | int     |
| paid_by      | int     |
| paid_to      | int     |
| amount       | int     |
| transacted_on| date    |

trans_id 是这个表的主键（具有唯一值的列）。
表中的每一列包含银行的交易信息。
ID 为 paid_by 的用户给 ID 为 paid_to 的用户转账。
力扣银行（LcB） 帮助程序员们完成虚拟支付。我们的银行在表 Transaction 中记录每条交易信息，我们要查询
每个用户的当前余额，并检查他们是否已透支（当前额度小于0）。
编写解决方案报告：
user_id 用户 ID
user_name 用户名
credit完成交易后的余额
credit_limit_breached 检查是否透支("Yes" 或 "No")
以任意顺序返回结果表。
结果格式见如下所示。

示例

输入：

Users 表：

| user_id | user_name  | credit |
|---------|------------|--------|
| 1       | Moustafa   | 100    |
| 2       | Jonathan   | 200    |
| 3       | Winston    | 10000  |
| 4       | Luis       | 800    |

Transactions 表：

| trans_id | paid_by | paid_to | amount | transacted_on |
|----------|---------|---------|--------|---------------|
| 1        | 1       | 3       | 400    | 2020-08-01    |
| 2        | 3       | 2       | 500    | 2020-08-02    |
| 3        | 2       | 1       | 200    | 2020-08-03    |

输出：

| user_id | user_name  | credit | credit_limit_breached |
|---------|------------|--------|-----------------------|
| 1       | Moustafa   | -100   | YES                   |
| 2       | Jonathan   | 500    | NO                    |
| 3       | Winston    | 9900   | NO                    |
| 4       | Luis       | 800    | NO                    |

解释：

Moustafa 在 "2020-08-01" 支付了 $400，在 "2020-08-03" 收到了 $200，他的余额为 $100 + $200 - $400 = -$100。
Jonathan 在 "2020-08-03" 支付了 $200，在 "2020-08-02" 收到了 $500，他的余额为 $200 + $500 - $200 = $500。
Winston 在 "2020-08-02" 支付了 $500，在 "2020-08-01" 收到了 $400，他的余额为 $10000 + $400 - $500 = $9900。
Luis 没有进行任何交易，他的余额保持 $800。

SELECT u.user_id, u.user_name, credit - paid + received as credit,
    CASE WHEN credit - paid + received < 0 THEN 'YES'
         ELSE 'NO'
    END AS credit_limit_breached
FROM Users as u
LEFT JOIN (
    SELECT paid_by as user_id, SUM(amount) as paid
    FROM Transactions
    GROUP BY paid_by
) as t1 ON u.user_id = t1.user_id
LEFT JOIN (
    SELECT paid_to as user_id, SUM(amount) as received
    FROM Transactions
    GROUP BY paid_to
) as t2 ON u.user_id = t2.user_id;

*/


WITH Users AS (
    SELECT 1 AS user_id, 'Moustafa' AS user_name, 100 AS credit
    UNION ALL
    SELECT 2, 'Jonathan', 200
    UNION ALL
    SELECT 3, 'Winston', 10000
    UNION ALL
    SELECT 4, 'Luis', 800
),
Transactions AS (SELECT 1 AS trans_id, 1 AS paid_by, 3 AS paid_to, 400 AS amount, '2020-08-01' AS transacted_on
                 UNION ALL
                 SELECT 2, 3, 2, 500, '2020-08-02'
                 UNION ALL
                 SELECT 3, 2, 1, 200, '2020-08-03'),
    credit_detail as (
        select trans_id,
               paid_by user_id,
               - amount amount,
               to_date(transacted_on) transacted_on
        from Transactions t1
        union all
        select trans_id,
               paid_to,
               amount,
               to_date(transacted_on)
        from Transactions t2
    )
select
    t2.user_id,
    t2.user_name,
    (coalesce(t1.credit,0) + t2.credit) credit,
    if((coalesce(t1.credit,0) + t2.credit) < 0, 'YES','NO') credit_limit_breached
from (
    select
           user_id,
           sum(amount) credit
    from credit_detail
    group by user_id
     ) t1
right join Users t2
on t1.user_id = t2.user_id;

-- 方式二
WITH Users AS (
    SELECT 1 AS user_id, 'Moustafa' AS user_name, 100 AS credit
    UNION ALL
    SELECT 2, 'Jonathan', 200
    UNION ALL
    SELECT 3, 'Winston', 10000
    UNION ALL
    SELECT 4, 'Luis', 800
),
Transactions AS (SELECT 1 AS trans_id, 1 AS paid_by, 3 AS paid_to, 400 AS amount, '2020-08-01' AS transacted_on
                 UNION ALL
                 SELECT 2, 3, 2, 500, '2020-08-02'
                 UNION ALL
                 SELECT 3, 2, 1, 200, '2020-08-03')
SELECT u.user_id, user_name, credit - paid + received AS credit,
       CASE WHEN u.credit - paid + received >= 0 THEN 'No'
            ELSE 'Yes' END AS credit_limit_breached
FROM Users AS u
LEFT JOIN (
    SELECT u.user_id, nullif(SUM(amount), 0) AS paid
    FROM Users AS u
    LEFT JOIN Transactions AS t ON u.user_id = t.paid_by
    GROUP BY u.user_id
) AS t1 ON u.user_id = t1.user_id
LEFT JOIN (
    SELECT u.user_id, nullif(SUM(amount), 0) AS received
    FROM Users AS u
    LEFT JOIN Transactions AS t ON u.user_id = t.paid_to
    GROUP BY u.user_id
) AS t2 ON u.user_id = t2.user_id;