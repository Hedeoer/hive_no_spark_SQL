/*
支出表: `Spending`
```
+-------------+--------+
| Column Name | Type   |
+-------------+--------+
| user_id     | int    |
| spend_date  | date   |
| platform    | enum   |
| amount      | int    |
+-------------+--------+
```
这张表记录了用户在一个在线购物网站的支出历史，该在线购物平台同时拥有桌面端 (`'desktop'`) 和手机端 (`'mobile'`) 的应用程序。
(user_id, spend_date, platform) 是这张表的主键(具有唯一值的列的组合)。
平台列 platform 是一种 ENUM 类型为 (`'desktop'`, `'mobile'`)。
编写解决方案找出每天 仅 使用手机端用户、仅 使用桌面端用户和 同时 使用桌面端和手机端的用户人数和总支出金额。
以 任意顺序 返回结果表。
返回结果格式如下例所示:

示例 1:

输入:
`Spending table`:
```
+---------+------------+----------+--------+
| user_id | spend_date | platform | amount |
+---------+------------+----------+--------+
| 1       | 2019-07-01 | mobile   | 100    |
| 1       | 2019-07-01 | desktop  | 100    |
| 2       | 2019-07-01 | mobile   | 100    |
| 2       | 2019-07-02 | mobile   | 100    |
| 3       | 2019-07-01 | desktop  | 100    |
| 3       | 2019-07-02 | desktop  | 100    |
+---------+------------+----------+--------+
```
输出:
```
+------------+----------+--------------+-------------+
| spend_date | platform | total_amount | total_users |
+------------+----------+--------------+-------------+
| 2019-07-01 | desktop  | 100          | 1           |
| 2019-07-01 | mobile   | 100          | 1           |
| 2019-07-01 | both     | 200          | 1           |
| 2019-07-02 | desktop  | 100          | 1           |
| 2019-07-02 | mobile   | 100          | 1           |
| 2019-07-02 | both     | 0            | 0           |
+------------+----------+--------------+-------------+
```
解释:
在 2019-07-01, 用户1 同时 使用桌面端和手机端购买, 用户2 仅 使用了手机端购买, 而用户3 仅 使用了桌面端购买。
在 2019-07-02, 用户2 仅 使用了手机端购买, 用户3 仅 使用了桌面端购买, 且没有用户 同时 使用桌面端和手机端购买。
*/

WITH
-- 1. 模拟 Spending 表
Spending AS (
    SELECT 1 AS user_id, CAST('2019-07-01' AS DATE) AS spend_date, 'mobile' AS platform, 100 AS amount UNION ALL
    SELECT 1, CAST('2019-07-01' AS DATE), 'desktop', 100 UNION ALL
    SELECT 2, CAST('2019-07-01' AS DATE), 'mobile', 100 UNION ALL
    SELECT 2, CAST('2019-07-02' AS DATE), 'mobile', 100 UNION ALL
    SELECT 3, CAST('2019-07-01' AS DATE), 'desktop', 100 UNION ALL
    SELECT 3, CAST('2019-07-02' AS DATE), 'desktop', 100
),
-- 每日汇总情况
summary as (
    select
        t0.spend_date,
        case
            when size(t1.refer_platforms) == 1 and refer_platforms[0] = 'mobile' then 'mobile'
            when size(t1.refer_platforms) == 1 and refer_platforms[0] = 'desktop' then 'desktop'
            when size(t1.refer_platforms) == 2 then 'both'
            else null end as platform,
        sum(t0.amount) total_amount,
        count(distinct t0.user_id) total_users
    from Spending t0
             left join (
        select user_id,
               spend_date,
               sum(amount) date_amount,
               collect_set(platform) refer_platforms
        from Spending t0
        group by user_id,spend_date

    ) t1
                       on t0.user_id = t1.user_id and t0.spend_date = t1.spend_date
    group by case
                 when size(t1.refer_platforms) == 1 and refer_platforms[0] = 'mobile' then 'mobile'
                 when size(t1.refer_platforms) == 1 and refer_platforms[0] = 'desktop' then 'desktop'
                 when size(t1.refer_platforms) == 2 then 'both'
                 else null end ,
             t0.spend_date

),
-- 日期消费维度
dim_type as (
    select
        tt0.spend_date,
        tt1.platform
    from (
             select
                 spend_date
             from Spending
             group by spend_date
         ) tt0
             lateral view explode(array('desktop','mobile','both')) tt1 as platform
)
select
    t1.spend_date,
    t1.platform,
    nvl(t2.total_amount,0) total_amount,
    nvl(t2.total_users,0) total_users
from dim_type t1
         left join summary t2
                   on t1.spend_date = t2.spend_date and t1.platform = t2.platform


