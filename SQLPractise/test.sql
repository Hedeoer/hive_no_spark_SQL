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



CREATE TABLE stock_price_detail
(
  `id`      INT COMMENT '记录ID',
  `ds`      DATE COMMENT '日期',
  `price`   DOUBLE COMMENT '价格'
) COMMENT '股票价格明细表'
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';


-- 插入模拟数据
INSERT INTO stock_price_detail VALUES
(1, '2024-09-01', 100.0),
(2, '2024-09-02', 110.0),
(3, '2024-09-03', 105.0),
(4, '2024-09-04', 120.0),
(5, '2024-09-05', 115.0),
(6, '2024-09-06', 130.0),
(7, '2024-09-07', 125.0),
(8, '2024-09-08', 140.0),
(9, '2024-09-09', 135.0),
(10, '2024-09-10', 150.0);


-- 求出股票波峰波谷。
-- 波峰：当天的价格大于前一天和后一天，
-- 波谷：当天的价格小于前一天和后一天)


select
    id,
    ds,
    price,
    case
        when before_price is null or after_price is null then 'abnormal'
        when price > before_price and price > after_price then 'peak'
        when price < before_price and price < after_price then 'valley'
        else 'normal'
    end
    from (
select
    id,
    ds,price,
    lag(price,1,null) over(order by ds) before_price,
    lead(price,1,null) over(order by ds) after_price
from stock_price_detail
    ) t;

-- 求取每个店铺每次开业前一次开业日期和之后的最近的一次开业日期
-- 比如 店铺id， 开业日期，前一次开业日期，后一次开业日期

CREATE TABLE store_open_status
(
  `store_id`   STRING COMMENT '店铺ID',
  `is_open`    INT COMMENT '是否开业标志位（1表示开业，0表示未开业）',
  `open_date`  DATE COMMENT '开业日期'
) COMMENT '店铺开业状态表'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t';

INSERT INTO store_open_status VALUES
('S001', 1, '2023-01-15'),
('S002', 0, '2022-12-10'),
('S003', 1, '2023-03-05'),
('S001', 0, '2022-11-19'),
('S002', 1, '2023-05-01'),
('S003', 0, '2021-09-11'),
('S001', 1, '2022-07-13'),
('S002', 0, '2022-06-19'),
('S003', 1, '2023-02-22'),
('S001', 1, '2021-10-23'),
('S002', 0, '2023-04-30'),
('S003', 1, '2022-08-14'),
('S001', 1, '2021-03-19'),
('S002', 0, '2022-02-05'),
('S003', 1, '2023-01-01'),
('S001', 0, '2023-03-11'),
('S002', 1, '2022-04-25'),
('S003', 0, '2021-05-20'),
('S001', 1, '2023-02-27'),
('S002', 0, '2022-07-22'),
('S003', 1, '2021-11-11'),
('S001', 1, '2022-03-31'),
('S002', 0, '2023-02-16'),
('S003', 1, '2021-12-30'),
('S001', 1, '2022-05-19'),
('S002', 0, '2021-10-27'),
('S003', 1, '2023-03-23'),
('S001', 1, '2021-08-02'),
('S002', 0, '2022-09-14'),
('S003', 1, '2023-04-10');


-- 过滤出有开业的情况
-- 取前一次开业日期，后一次开业日期

select
    store_id,
    is_open,
    open_date,
    lag(open_date,1,null) over(partition by store_id order by open_date asc) before_open_date,
    lead(open_date,1,null) over(partition by store_id order by open_date asc) after_open_date
    from (
select
    *
from store_open_status
where is_open = 1
    ) t1;

--查询每条记录前后一次开业日期，不需要过滤未开业的情况

select store_id,
       is_open,
       open_date,
       last_value(if(is_open = 1 , open_date, null),true) over( partition by store_id order by open_date asc rows between unbounded preceding and 1 preceding ) before_open_date,
       first_value(if(is_open = 1 , open_date, null),true) over( partition by  store_id order by open_date asc rows between 1 following and unbounded following ) after_open_date
from store_open_status;


select 
    store_id,
    open_date,
    is_open,
    coalesce(if(is_open = 1 and tag_1 = 1, lag(pre_date) OVER (partition by store_id order by open_date), pre_date), '1900-01-01') as pre_date,
    coalesce(if(is_open = 1 and tag_2 = 1, lead(next_date) OVER (partition by store_id order by open_date), next_date), '9999-01-01') as next_date
from (
    select 
        store_id,
        open_date,
        is_open,
        if(is_open = 0, min(pre_date) over (partition by store_id, group_store_id), pre_date) as pre_date,
        if(is_open = 0, max(next_date) over (partition by store_id, group_store_id), next_date) as next_date,
        tag_1,
        tag_2
    from (
        select 
            store_id,
            open_date,
            is_open,
            coalesce(lag(open_date) over (partition by store_id order by open_date), '1900-01-01') as pre_date,
            coalesce(lead(open_date) over (partition by store_id order by open_date), '9999-01-01') as next_date,
            sum(tag_1) over (partition by store_id order by open_date) AS group_store_id,
            tag_1,
            tag_2
        from (
            select 
                store_id,
                open_date,
                is_open,
                if(lag(is_open) OVER (partition by store_id order by open_date) = is_open, 0, 1) AS tag_1,
                if(lead(is_open) OVER (partition by store_id order by open_date) = is_open, 0, 1) AS tag_2
            from store_open_status
        ) as temp1
    ) as temp3
) as temp2;



