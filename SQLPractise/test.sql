-- 1. 查询连续登陆3天以上的用户
DROP TABLE IF EXISTS user_login_detail;
CREATE TABLE user_login_detail
(
    `user_id`    string comment '用户id',
    `ip_address` string comment 'ip地址',
    `login_ts`   string comment '登录时间',
    `logout_ts`  string comment '登出时间'
) COMMENT '用户登录明细表'
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';

INSERT overwrite table user_login_detail
VALUES ('101', '180.149.130.161', '2021-09-21 08:00:00', '2021-09-27 08:30:00'),
       ('101', '180.149.130.161', '2021-09-27 08:00:00', '2021-09-27 08:30:00'),
       ('101', '180.149.130.161', '2021-09-28 09:00:00', '2021-09-28 09:10:00'),
       ('101', '180.149.130.161', '2021-09-29 13:30:00', '2021-09-29 13:50:00'),
       ('101', '180.149.130.161', '2021-09-30 20:00:00', '2021-09-30 20:10:00'),
       ('102', '120.245.11.2', '2021-09-22 09:00:00', '2021-09-27 09:30:00'),
       ('102', '120.245.11.2', '2021-10-01 08:00:00', '2021-10-01 08:30:00'),
       ('102', '180.149.130.174', '2021-10-01 07:50:00', '2021-10-01 08:20:00'),
       ('102', '120.245.11.2', '2021-10-02 08:00:00', '2021-10-02 08:30:00'),
       ('103', '27.184.97.3', '2021-09-23 10:00:00', '2021-09-27 10:30:00'),
       ('103', '27.184.97.3', '2021-10-03 07:50:00', '2021-10-03 09:20:00'),
       ('104', '27.184.97.34', '2021-09-24 11:00:00', '2021-09-27 11:30:00'),
       ('104', '27.184.97.34', '2021-10-03 07:50:00', '2021-10-03 08:20:00'),
       ('104', '27.184.97.34', '2021-10-03 08:50:00', '2021-10-03 10:20:00'),
       ('104', '120.245.11.89', '2021-10-03 08:40:00', '2021-10-03 10:30:00'),
       ('105', '119.180.192.212', '2021-10-04 09:10:00', '2021-10-04 09:30:00'),
       ('106', '119.180.192.66', '2021-10-04 08:40:00', '2021-10-04 10:30:00'),
       ('106', '119.180.192.66', '2021-10-05 21:50:00', '2021-10-05 22:40:00'),
       ('107', '219.134.104.7', '2021-09-25 12:00:00', '2021-09-27 12:30:00'),
       ('107', '219.134.104.7', '2021-10-05 22:00:00', '2021-10-05 23:00:00'),
       ('107', '219.134.104.7', '2021-10-06 09:10:00', '2021-10-06 10:20:00'),
       ('107', '27.184.97.46', '2021-10-06 09:00:00', '2021-10-06 10:00:00'),
       ('108', '101.227.131.22', '2021-10-06 09:00:00', '2021-10-06 10:00:00'),
       ('108', '101.227.131.22', '2021-10-06 22:00:00', '2021-10-06 23:00:00'),
       ('109', '101.227.131.29', '2021-09-26 13:00:00', '2021-09-27 13:30:00'),
       ('109', '101.227.131.29', '2021-10-06 08:50:00', '2021-10-06 10:20:00'),
       ('109', '101.227.131.29', '2021-10-08 09:00:00', '2021-10-08 09:10:00'),
       ('1010', '119.180.192.10', '2021-09-27 14:00:00', '2021-09-27 14:30:00'),
       ('1010', '119.180.192.10', '2021-10-09 08:50:00', '2021-10-09 10:20:00');



with t1 as (
    select
        user_id,
        to_date(login_ts) login_date
    from user_login_detail
    group by user_id,to_date(login_ts)
),
    t2 as (
        select
            *,
            date_sub(login_date,row_number() over (partition by user_id order by login_date asc)) caulate_date
        from t1
    )
select
     user_id
from t2
group by user_id,caulate_date
having count(1) >= 3;


with t1 as (
    select
        user_id,
        to_date(login_ts) login_date
    from user_login_detail
    group by user_id,to_date(login_ts)
),

t2 as(
    select
        user_id,
        login_date,
        lag(login_date,1) over(partition by user_id order by login_date) before_login_date
    from t1),

t3 as (
    select
        user_id,
        login_date,
        before_login_date,
        case
        when DATEDIFF(login_date,before_login_date) is null then 0
        when DATEDIFF(login_date,before_login_date) <=1  then 0
        else 1 end flag
    from t2
    ),

    t4 as (
    select user_id,
              sum(flag) over (partition by user_id order by login_date) acc_flag
    from t3)

    select
    user_id
    from (select user_id,
                 row_number() over (order by continus_days desc) rn
          from (select user_id,
                       count(1) continus_days
                from t4
                group by user_id, acc_flag) tt) t
        where rn = 1;

-- 特列 查询连续4天登陆的用户
with t1 as (
    select
        user_id,
        to_date(login_ts) login_date
    from user_login_detail
    group by user_id,to_date(login_ts)
), t2 as (
select
    user_id,login_date,
    collect_list(login_date) over(partition by user_id order by login_date rows between 3 preceding and current row) data_list
from t1)
select
    distinct user_id
from t2
where size(data_list) = 4
and datediff(data_list[1],data_list[0]) = 1
and datediff(data_list[2],data_list[1]) = 1
and datediff(data_list[3],data_list[2]) = 1;


-- 查询连续登陆最大天数用户

WITH t1 AS (
    SELECT
        user_id,
        TO_DATE(login_ts) AS login_date
    FROM
        user_login_detail
    GROUP BY
        user_id, TO_DATE(login_ts)
),
t2 AS (
    SELECT
        *,
        DATE_SUB(login_date, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date ASC)) AS caulate_date
    FROM
        t1
)

SELECT
    user_id
FROM (
    SELECT
        user_id,
        ROW_NUMBER() OVER (ORDER BY continus_days DESC) AS rn
    FROM (
        SELECT
            user_id,
            COUNT(1) AS continus_days
        FROM
            t2
        GROUP BY
            user_id, caulate_date
    ) t3
) t4
WHERE
    rn = 1;


-- 按照天的单位合并用户连续登录的时间区间，间隔不大于2天，均算连续登录
-- 考虑特殊情况
-- 1. 登录区间存在重叠，属于异常登录的情况,以下sql适配
with t1 as (
    select
        user_id,
        to_date(login_ts) login_date,
        to_date(logout_ts) logout_date
    from user_login_detail
    group by user_id,to_date(login_ts),to_date(logout_ts)
),
    t2 as (
        select
            user_id,
            login_date,
            logout_date,
            lag(logout_date, 1) over(partition by  user_id order by login_date asc) before_logout_date,
            case
                when DATEDIFF(login_date,lag(logout_date, 1) over(partition by  user_id order by login_date asc)) <= 2 then 0
                when lag(logout_date, 1) over(partition by  user_id order by login_date asc) is null then 0
                else 1
            end flag
        from t1
    ),
    t3 as (
            select
        user_id,login_date,logout_date,
        sum(flag) over(partition by user_id order by login_date asc) acc_flag
        from t2

    )
select
    user_id,
    min(login_date) upper_login_date,
    max(logout_date) lower_logout_date
from t3
group by user_id,acc_flag;
