/*
====================================================================
【题目名称】每日新增用户数计算
【测试环境】Spark 3.3.0 / Hive 3.1.3 / YARN Client 模式
【数据说明】
    模拟用户访问日志表，字段包含：
    - id: 用户ID
    - login_date: 登录日期

【题目要求】
    统计每天的新增用户数。
    "新增用户"定义：该用户历史上第一次登录系统的日期，即为该用户的新增日期。

【解题思路】
    1. 按照用户 id 分组，取每个用户的最小登录日期（MIN(login_date)），即为该用户的首次登录日期（新增日期）；
    2. 将步骤 1 得到的每个用户的首次登录日期按日期分组（GROUP BY），使用 COUNT(id) 统计该日期的首次登录人数，即为每日新增用户数。
    （注：也可使用窗口函数 ROW_NUMBER() OVER(PARTITION BY id ORDER BY login_date) 筛选 rn = 1）

【期望输出】
    +-------------+----------------+
    | first_date  | new_user_cnt   |
    +-------------+----------------+
    | 2022-02-02  | 2              |
    | 2022-02-04  | 1              |
    +-------------+----------------+
====================================================================
*/

WITH data AS (
    SELECT 1 AS id, '2022-02-02' AS login_date UNION ALL
    SELECT 1 AS id, '2022-02-03' AS login_date UNION ALL
    SELECT 1 AS id, '2022-02-04' AS login_date UNION ALL
    SELECT 2 AS id, '2022-02-04' AS login_date UNION ALL
    SELECT 2 AS id, '2022-02-06' AS login_date UNION ALL
    SELECT 2 AS id, '2022-02-08' AS login_date UNION ALL
    SELECT 2 AS id, '2022-02-09' AS login_date UNION ALL
    SELECT 2 AS id, '2022-02-10' AS login_date UNION ALL
    SELECT 3 AS id, '2022-02-02' AS login_date UNION ALL
    SELECT 3 AS id, '2022-02-03' AS login_date
)


/*
+----------+----------------------+
|login_date|first_login_people_num|
+----------+----------------------+
|2022-02-10|0                     |
|2022-02-03|0                     |
|2022-02-02|2                     |
|2022-02-08|0                     |
|2022-02-04|1                     |
|2022-02-09|0                     |
|2022-02-06|0                     |
+----------+----------------------+

*/

-- 方法1
/*

 select
     login_date,
     count(1) new_cnts
from (

         select
             id,
             login_date,
             lag(login_date,1,null) over(partition by id order by login_date) prev_login_date
         from data t1

     ) t2
where t2.prev_login_date is null
group by login_date;

*/

-- 方法2

/*

  select
      first_login_date,
      count(1) new_cnts
from (

         select
             id,
             min(login_date) first_login_date
         from data t1
         group by t1.id
     ) t2
group by first_login_date;
*/

-- 方法3

/*

select
    login_date,
    count( id) new_cnts
from (

         select
             id,
             login_date,
             row_number()  over(partition by id order by login_date) rn
         from data t1

     ) t2
where t2.rn = 1
group by login_date;
*/

-- 方法4

/*

select
    first_login_date,
    count(distinct id) new_cnts
from (

         select
             id,
             first_value(login_date) over(partition by id order by login_date) first_login_date
         from data t1

     ) t2
group by first_login_date;

*/

-- 方法5


/*

SELECT
    t1.login_date,
    -- 关键修改1：当 t2.id IS NULL 时，说明在当前日期之前找不到任何登录记录，即为首次登录
    COUNT(DISTINCT IF(t2.id IS NULL, t1.id, NULL)) AS first_login_people_num
FROM data t1
         LEFT JOIN data t2
    -- 关键修改2：只关联早于当前日期的历史记录
                   ON t1.id = t2.id AND t2.login_date < t1.login_date
GROUP BY
    t1.login_date
ORDER BY
    t1.login_date;
*/

-- 方法6


/*
    select
        login_date,
        count(distinct `if`(login_cnt = 1, id,null) ) first_login_people_num
from (

         select
             id,
             login_date,
             count(1) over(partition by  id order by login_date asc) login_cnt
         from data t1
     ) t2
group by login_date
order by login_date;*/

-- 方法7

   select
       t2.login_date,
       count(distinct `if`(t2.login_date == t2.first_login_date,t2.id,null)) first_login_people_num
from (

        select
            login_date,
            id,
            min(login_date) over(partition by id order by login_date asc) first_login_date
        from data t1
    ) t2
group by t2.login_date
