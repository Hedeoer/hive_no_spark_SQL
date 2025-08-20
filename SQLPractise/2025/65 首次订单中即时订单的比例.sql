

/*
配送表: `Delivery`
```
+-------------------------------+---------+
| Column Name                   | Type    |
+-------------------------------+---------+
| delivery_id                   | int     |
| customer_id                   | int     |
| order_date                    | date    |
| customer_pref_delivery_date   | date    |
+-------------------------------+---------+
```
`delivery_id` 是该表中具有唯一值的列。
该表保存着顾客的食物配送信息，顾客在某个日期下了订单，并指定了一个期望的配送日期（和下单日期相同或者在那之后）。
如果顾客期望的配送日期和下单日期相同，则该订单称为「即时订单」，否则称为「计划订单」。
「首次订单」是顾客最早创建的订单。我们保证一个顾客只会有一个「首次订单」。
编写解决方案以获取即时订单在所有用户的首次订单中的比例。保留两位小数。
结果示例示例如下所示：

示例 1:

输入:
`Delivery` 表:
```
+-------------+-------------+------------+-------------------------------+
| delivery_id | customer_id | order_date | customer_pref_delivery_date |
+-------------+-------------+------------+-------------------------------+
| 1           | 1           | 2019-08-01 | 2019-08-02                    |
| 2           | 2           | 2019-08-02 | 2019-08-02                    |
| 3           | 1           | 2019-08-11 | 2019-08-12                    |
| 4           | 3           | 2019-08-24 | 2019-08-24                    |
| 5           | 3           | 2019-08-21 | 2019-08-22                    |
| 6           | 2           | 2019-08-11 | 2019-08-13                    |
| 7           | 4           | 2019-08-09 | 2019-08-09                    |
+-------------+-------------+------------+-------------------------------+
```
输出:
```
+----------------------+
| immediate_percentage |
+----------------------+
| 50.00                |
+----------------------+
```
解释:
1 号顾客的 1 号订单是首次订单，并且是计划订单。
2 号顾客的 2 号订单是首次订单，并且是即时订单。
3 号顾客的 5 号订单是首次订单，并且是计划订单。
4 号顾客的 7 号订单是首次订单，并且是即时订单。
因此，一半顾客的首次订单是即时的。
*/

WITH
-- 1. 模拟 Delivery 表
Delivery AS (
    SELECT 1 AS delivery_id, 1 AS customer_id, CAST('2019-08-01' AS DATE) AS order_date, CAST('2019-08-02' AS DATE) AS customer_pref_delivery_date UNION ALL
    SELECT 2, 2, CAST('2019-08-02' AS DATE), CAST('2019-08-02' AS DATE) UNION ALL
    SELECT 3, 1, CAST('2019-08-11' AS DATE), CAST('2019-08-12' AS DATE) UNION ALL
    SELECT 4, 3, CAST('2019-08-24' AS DATE), CAST('2019-08-24' AS DATE) UNION ALL
    SELECT 5, 3, CAST('2019-08-21' AS DATE), CAST('2019-08-22' AS DATE) UNION ALL
    SELECT 6, 2, CAST('2019-08-11' AS DATE), CAST('2019-08-13' AS DATE) UNION ALL
    SELECT 7, 4, CAST('2019-08-09' AS DATE), CAST('2019-08-09' AS DATE)
)
select
    count(distinct if(order_date = customer_pref_delivery_date,delivery_id,null)) / count(distinct delivery_id)  immediate_percentage
from (
         select delivery_id,
                customer_id,
                order_date,
                customer_pref_delivery_date,
                row_number() over (partition by t0.customer_id order by order_date) order_number
         from Delivery t0
     ) t1
where order_number = 1;