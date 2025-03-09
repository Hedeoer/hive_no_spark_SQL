WITH data AS (

    SELECT 1 AS uid, '2019-02-01 08:30:00' AS date_str
    UNION ALL
    SELECT 2 AS uid, '2019-02-01 09:15:00' AS date_str
    UNION ALL
    SELECT 3 AS uid, '2019-02-01 10:20:00' AS date_str
    UNION ALL
    SELECT 4 AS uid, '2019-02-01 11:05:00' AS date_str
    UNION ALL
    SELECT 5 AS uid, '2019-02-01 12:10:00' AS date_str
    UNION ALL
    SELECT 6 AS uid, '2019-02-01 13:25:00' AS date_str
    UNION ALL
    SELECT 7 AS uid, '2019-02-01 14:30:00' AS date_str
    UNION ALL
    SELECT 8 AS uid, '2019-02-01 15:40:00' AS date_str
    UNION ALL
    SELECT 9 AS uid, '2019-02-01 16:15:00' AS date_str
    UNION ALL
    SELECT 10 AS uid, '2019-02-01 17:20:00' AS date_str
    UNION ALL
    SELECT 11 AS uid, '2019-02-01 09:45:00' AS date_str
    UNION ALL
    SELECT 12 AS uid, '2019-02-01 10:50:00' AS date_str
    UNION ALL
    SELECT 13 AS uid, '2019-02-01 11:55:00' AS date_str
    UNION ALL
    SELECT 14 AS uid, '2019-02-01 13:00:00' AS date_str
    UNION ALL
    SELECT 15 AS uid, '2019-02-01 14:05:00' AS date_str
    UNION ALL
    SELECT 16 AS uid, '2019-02-01 15:10:00' AS date_str
    UNION ALL
    SELECT 17 AS uid, '2019-02-01 16:15:00' AS date_str
    UNION ALL
    SELECT 18 AS uid, '2019-02-01 17:20:00' AS date_str
    UNION ALL
    SELECT 19 AS uid, '2019-02-01 18:25:00' AS date_str
    UNION ALL
    SELECT 20 AS uid, '2019-02-01 19:30:00' AS date_str
    UNION ALL
    SELECT 1, '2019-02-02 09:10:00'
    UNION ALL
    SELECT 2, '2019-02-02 10:15:00'
    UNION ALL
    SELECT 3, '2019-02-02 11:20:00'
    UNION ALL
    SELECT 4, '2019-02-02 12:25:00'
    UNION ALL
    SELECT 5, '2019-02-02 13:30:00'
    UNION ALL
    SELECT 6, '2019-02-02 14:35:00'
    UNION ALL
    SELECT 7, '2019-02-02 15:40:00'
    UNION ALL
    SELECT 8, '2019-02-02 16:45:00'
    UNION ALL
    SELECT 9, '2019-02-02 17:50:00'
    UNION ALL
    SELECT 10, '2019-02-02 18:55:00'
    UNION ALL
    SELECT 11, '2019-02-02 19:00:00'
    UNION ALL
    SELECT 12, '2019-02-02 20:05:00'
    UNION ALL
    SELECT 13, '2019-02-03 10:15:00'
    UNION ALL
    SELECT 14, '2019-02-04 11:20:00'
    UNION ALL
    SELECT 21, '2019-01-28 14:25:00'
    UNION ALL
    SELECT 22, '2019-01-29 15:30:00'
    UNION ALL
    SELECT 23, '2019-01-30 16:35:00'
    UNION ALL
    SELECT 24, '2019-01-31 17:40:00'
    UNION ALL
    SELECT 25, '2019-02-09 10:45:00'
    UNION ALL
    SELECT 26, '2019-02-10 11:50:00'

),

     rt as (select uid,
                   min(to_date(date_str)) register_date
            from data
            group by uid),
     lt as (select uid,
                   to_date(date_str) login_date
            from data
            group by uid, to_date(date_str))
select rt.register_date,
       sum(case when datediff(login_date, register_date) = 1 then 1 else 0 end) / count(distinct rt.uid) lst1date_cnt,
       sum(case when datediff(login_date, register_date) = 3 then 1 else 0 end) / count(distinct rt.uid) lst3date_cnt,
       sum(case when datediff(login_date, register_date) = 7 then 1 else 0 end) / count(distinct rt.uid) lst7date_cnt
from rt
         left join lt on rt.uid = lt.uid and datediff(login_date, register_date) > 0
group by rt.register_date;


WITH data AS (SELECT 1 AS uid, '2019-01-01 00:00:00' AS date_str
              UNION ALL
              SELECT 1, '2019-01-01 01:00:00'
              UNION ALL
              SELECT 1, '2019-01-02 00:00:00'
              UNION ALL
              SELECT 1, '2019-01-03 00:00:00'
              UNION ALL
              SELECT 2, '2019-02-01 00:00:00'
              UNION ALL
              SELECT 2, '2019-02-02 00:00:00'
              UNION ALL
              SELECT 3, '2019-03-04 00:00:00'
              UNION ALL
              SELECT 3, '2019-03-05 00:00:00'
              UNION ALL
              SELECT 3, '2019-03-06 00:00:00'
              UNION ALL
              SELECT 3, '2019-03-07 00:00:00')
SELECT a.left_date,
       SUM((CASE WHEN DATEDIFF(b.right_date, a.left_date) = 1 THEN 1 ELSE 0 END)) /
       COUNT(DISTINCT a.uid)                                                                              AS lst1date_rate, -- 次日留存率
       SUM((CASE WHEN DATEDIFF(b.right_date, a.left_date) = 3 THEN 1 ELSE 0 END)) /
       COUNT(DISTINCT a.uid)                                                                              AS lst3date_rate, -- 三日留存率
       SUM((CASE WHEN DATEDIFF(b.right_date, a.left_date) = 7 THEN 1 ELSE 0 END)) /
       COUNT(DISTINCT a.uid)                                                                              AS lst7date_rate  -- 七日留存率
FROM (SELECT uid, CAST(substr(date_str, 1, 10) AS DATE) AS left_date FROM data) a
         LEFT JOIN
     (SELECT uid, CAST(substr(date_str, 1, 10) AS DATE) AS right_date FROM data) b
     ON a.uid = b.uid AND a.left_date < b.right_date
GROUP BY a.left_date;


WITH data AS (
    SELECT 1 AS uid, '2019-02-01 08:30:00' AS date_str
    UNION ALL
    SELECT 2 AS uid, '2019-02-01 09:15:00' AS date_str
    UNION ALL
    SELECT 3 AS uid, '2019-02-01 10:20:00' AS date_str
    UNION ALL
    SELECT 4 AS uid, '2019-02-01 11:05:00' AS date_str
    UNION ALL
    SELECT 5 AS uid, '2019-02-01 12:10:00' AS date_str
    UNION ALL
    SELECT 6 AS uid, '2019-02-01 13:25:00' AS date_str
    UNION ALL
    SELECT 7 AS uid, '2019-02-01 14:30:00' AS date_str
    UNION ALL
    SELECT 8 AS uid, '2019-02-01 15:40:00' AS date_str
    UNION ALL
    SELECT 9 AS uid, '2019-02-01 16:15:00' AS date_str
    UNION ALL
    SELECT 10 AS uid, '2019-02-01 17:20:00' AS date_str
    UNION ALL
    SELECT 11 AS uid, '2019-02-01 09:45:00' AS date_str
    UNION ALL
    SELECT 12 AS uid, '2019-02-01 10:50:00' AS date_str
    UNION ALL
    SELECT 13 AS uid, '2019-02-01 11:55:00' AS date_str
    UNION ALL
    SELECT 14 AS uid, '2019-02-01 13:00:00' AS date_str
    UNION ALL
    SELECT 15 AS uid, '2019-02-01 14:05:00' AS date_str
    UNION ALL
    SELECT 16 AS uid, '2019-02-01 15:10:00' AS date_str
    UNION ALL
    SELECT 17 AS uid, '2019-02-01 16:15:00' AS date_str
    UNION ALL
    SELECT 18 AS uid, '2019-02-01 17:20:00' AS date_str
    UNION ALL
    SELECT 19 AS uid, '2019-02-01 18:25:00' AS date_str
    UNION ALL
    SELECT 20 AS uid, '2019-02-01 19:30:00' AS date_str
    UNION ALL
    SELECT 1, '2019-02-02 09:10:00'
    UNION ALL
    SELECT 2, '2019-02-02 10:15:00'
    UNION ALL
    SELECT 3, '2019-02-02 11:20:00'
    UNION ALL
    SELECT 4, '2019-02-02 12:25:00'
    UNION ALL
    SELECT 5, '2019-02-02 13:30:00'
    UNION ALL
    SELECT 6, '2019-02-02 14:35:00'
    UNION ALL
    SELECT 7, '2019-02-02 15:40:00'
    UNION ALL
    SELECT 8, '2019-02-02 16:45:00'
    UNION ALL
    SELECT 9, '2019-02-02 17:50:00'
    UNION ALL
    SELECT 10, '2019-02-02 18:55:00'
    UNION ALL
    SELECT 11, '2019-02-02 19:00:00'
    UNION ALL
    SELECT 12, '2019-02-02 20:05:00'
    UNION ALL
    SELECT 13, '2019-02-03 10:15:00'
    UNION ALL
    SELECT 14, '2019-02-04 11:20:00'
    UNION ALL
    SELECT 21, '2019-01-28 14:25:00'
    UNION ALL
    SELECT 22, '2019-01-29 15:30:00'
    UNION ALL
    SELECT 23, '2019-01-30 16:35:00'
    UNION ALL
    SELECT 24, '2019-01-31 17:40:00'
    UNION ALL
    SELECT 25, '2019-02-09 10:45:00'
    UNION ALL
    SELECT 26, '2019-02-10 11:50:00'
)

SELECT
    a.left_date,
    SUM((CASE WHEN DATEDIFF(b.right_date, a.left_date) = 1 THEN 1 ELSE 0 END)) / COUNT(DISTINCT a.uid) AS lst1date_rate,
    SUM((CASE WHEN DATEDIFF(b.right_date, a.left_date) = 3 THEN 1 ELSE 0 END)) / COUNT(DISTINCT a.uid) AS lst3date_rate,
    SUM((CASE WHEN DATEDIFF(b.right_date, a.left_date) = 7 THEN 1 ELSE 0 END)) / COUNT(DISTINCT a.uid) AS lst7date_rate
FROM
    (SELECT uid, CAST(SUBSTR(date_str, 1, 10) AS DATE) AS left_date FROM data) a
LEFT JOIN
    (SELECT uid, CAST(SUBSTR(date_str, 1, 10) AS DATE) AS right_date FROM data) b
ON a.uid = b.uid AND a.left_date < b.right_date
GROUP BY a.left_date;
