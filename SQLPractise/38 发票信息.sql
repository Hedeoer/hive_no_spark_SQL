/*
题目 45 发票信息(可拓展到其他方向)

顾客表: Customers

+--------------+-------------+
| Column Name  | Type        |
+--------------+-------------+
| customer_id  | int         |
| customer_name| varchar     |
| email        | varchar     |
+--------------+-------------+

customer_id 是这张表的主键单值列。
每行中存有每个顾客姓名的顾客姓名和电子邮箱。

联系人表: Contacts

+--------------+-------------+
| Column Name  | Type        |
+--------------+-------------+
| user_id      | id          |
| contact_name | varchar     |
| contact_email| varchar     |
+--------------+-------------+

(user_id，contact_email）是这张表的主键（具有唯一值的列的组合）。
此表的每一行表示编号为user_id 的顾客的某位联系人的姓名和电子邮件。
此表包含每位顾客的联系人信息，但顾客的联系人不一定存在于顾客表中。

发票表: Invoices

+--------------+-------------+
| Column Name  | Type        |
+--------------+-------------+
| invoice_id   | int         |
| price        | int         |
| user_id      | int         |
+--------------+-------------+

invoice_id 是这张表具有唯一值的列。
此表的每一行分别表示编号为user_id 的顾客拥有有一张编号为invoice_id、价格为price 的发票。

为每张发票 invoice_id 编写一个查询方案以查找以下内容：
customer_name：与发票相关的顾客名称。
price：发票的价格。
contacts_cnt：该顾客的联系人数量
trusted_contacts_cnt：可信联系人的数量：既是该顾客的联系人又是商店顾客的联系人数量（即：可信联系人
的电子邮件存在于customers 表中）。

返回结果按照invoice_id 排序。

输入:

Customers table:

+-------------+---------------+---------------------+
| customer_id | customer_name | email               |
+-------------+---------------+---------------------+
| 1           | Alice         | alice@leetcode.com  |
| 2           | Bob           | bob@leetcode.com    |
| 3           | John          | john@leetcode.com   |
| 6           | Alex          | alex@leetcode.com   |
+-------------+---------------+---------------------+

Contacts table:

+--------+--------------+---------------------+
| user_id| contact_name | contact_email       |
+--------+--------------+---------------------+
| 1      | Bob          | bob@leetcode.com    |
| 1      | John         | john@leetcode.com   |
| 2      | Alice        | alice@leetcode.com  |
| 2      | Niel         | niel@leetcode.com   |
| 6      | Alice        | alice@leetcode.com  |
+--------+--------------+---------------------+

Invoices table:

+-------------+--------+---------+
| invoice_id  | price  | user_id |
+-------------+--------+---------+
| 77          | 100    | 1       |
| 89          | 200    | 1       |
| 90          | 300    | 2       |
| 56          | 400    | 2       |
| 66          | 1000   | 3       |
| 23          | 900    | 6       |
| 44          | 600    | 6       |
+-------------+--------+---------+

输出:

+------------+---------------+--------+-------------+---------------------+
| invoice_id | customer_name | price  | contacts_cnt| trusted_contacts_cnt|
+------------+---------------+--------+-------------+---------------------+
| 44         | Alex          | 600    | 1           | 1                   |
| 56         | Bob           | 400    | 2           | 0                   |
| 66         | John          | 1000   | 0           | 0                   |
| 77         | Alice         | 100    | 2           | 1                   |
| 89         | Alice         | 200    | 2           | 1                   |
| 90         | Bob           | 300    | 2           | 1                   |
+------------+---------------+--------+-------------+---------------------+

解释:
Alice 有三个联系联系人，其中两个(Bob 和 John)是可信联系联系人。
Bob 拥有两位联系人，他们中的任何一位都不是可信联系联系人。
Alex 只有一位联系人(Alice)，并且是一位可信联系人。
John 没有任何联系联系人。

```sql
SELECT
    invoice_id,
    customer_name,
    price,
    IFNULL(a.x, 0) contacts_cnt,
    IFNULL(a.y, 0) trusted_contacts_cnt
FROM Invoices i
LEFT JOIN Customers c ON i.user_id = c.customer_id
LEFT JOIN (
    SELECT
        user_id,
        COUNT(contact_name) x,
        SUM(contact_name IN (
            SELECT
                customer_name
            FROM Customers
        )) y
    FROM Contacts
    GROUP BY user_id
) a ON c.customer_id = a.user_id
ORDER BY invoice_id
*/

WITH Customers AS (
    SELECT 1 AS customer_id, 'Alice' AS customer_name, 'alice@leetcode.com' AS email
    UNION ALL
    SELECT 2, 'Bob', 'bob@leetcode.com'
    UNION ALL
    SELECT 13, 'John', 'john@leetcode.com'
    UNION ALL
    SELECT 6, 'Alex', 'alex@leetcode.com'
)
,
Contacts AS (
    SELECT 1 AS user_id, 'Bob' AS contact_name, 'bob@leetcode.com' AS contact_email
    UNION ALL
    SELECT 1, 'John', 'john@leetcode.com'
    UNION ALL
    SELECT 1, 'Jal', 'jal@leetcode.com'
    UNION ALL
    SELECT 2, 'Omar', 'omar@leetcode.com'
    UNION ALL
    SELECT 2, 'Meir', 'meir@leetcode.com'
    UNION ALL
    SELECT 6, 'Alice', 'alice@leetcode.com'
),
Invoices AS (
    SELECT 77 AS invoice_id, 100 AS price, 1 AS user_id
    UNION ALL
    SELECT 88, 200, 1
    UNION ALL
    SELECT 99, 300, 2
    UNION ALL
    SELECT 66, 400, 2
    UNION ALL
    SELECT 55, 500, 13
    UNION ALL
    SELECT 44, 60, 6
),
    connectors as (
        select
        t1.user_id,
        count(1) contacts_cnt,
        sum(if(t2.customer_name is not null, 1, 0)) trusted_contacts_cnt
        from Contacts t1
        left join Customers t2 on t1.contact_name = t2.customer_name
        group by t1.user_id
    )
select
    t1.invoice_id,
    t3.customer_name,
    t1.price,
    coalesce(contacts_cnt, 0) contacts_cnt,
    coalesce(trusted_contacts_cnt,0) trusted_contacts_cnt
from Invoices t1
left join connectors t2 on t1.user_id = t2.user_id
left join Customers t3 on t1.user_id = t3.customer_id
