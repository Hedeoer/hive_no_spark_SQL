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





CREATE TABLE live_room_activity
(
  room_id     STRING COMMENT '直播间ID',
  user_id     STRING COMMENT '用户ID',
  login_time  STRING COMMENT '用户进入直播间时间',
  logout_time STRING COMMENT '用户退出直播间时间',
  dt          DATE COMMENT '日期'
) COMMENT '直播间用户活动表'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t';


INSERT INTO live_room_activity VALUES
('R001', 'U001', '2024-09-28 10:00:00', '2024-09-28 10:45:00', '2024-09-28'),
('R002', 'U002', '2024-09-28 10:15:00', '2024-09-28 11:00:00', '2024-09-28'),
('R003', 'U003', '2024-09-28 11:05:00', '2024-09-28 12:00:00', '2024-09-28'),
('R001', 'U004', '2024-09-28 11:15:00', '2024-09-28 12:10:00', '2024-09-28'),
('R002', 'U005', '2024-09-28 12:20:00', '2024-09-28 13:00:00', '2024-09-28'),
('R003', 'U006', '2024-09-28 10:30:00', '2024-09-28 11:15:00', '2024-09-28'),
('R001', 'U007', '2024-09-28 10:05:00', '2024-09-28 19:45:00', '2024-09-28'),
('R002', 'U008', '2024-09-28 10:00:00', '2024-09-28 19:30:00', '2024-09-28'),
('R003', 'U009', '2024-09-28 10:10:00', '2024-09-28 19:00:00', '2024-09-28'),
('R001', 'U010', '2024-09-28 10:05:00', '2024-09-28 19:00:00', '2024-09-28'),
('R002', 'U011', '2024-09-28 10:10:00', '2024-09-28 19:50:00', '2024-09-28'),
('R003', 'U012', '2024-09-28 10:00:00', '2024-09-28 19:45:00', '2024-09-28'),
('R001', 'U013', '2024-09-28 10:00:00', '2024-09-28 19:35:00', '2024-09-28'),
('R002', 'U014', '2024-09-28 18:50:00', '2024-09-28 19:30:00', '2024-09-28'),
('R003', 'U015', '2024-09-28 19:40:00', '2024-09-28 20:10:00', '2024-09-28'),
('R001', 'U016', '2024-09-28 20:20:00', '2024-09-28 21:00:00', '2024-09-28'),
('R002', 'U017', '2024-09-28 21:10:00', '2024-09-28 21:45:00', '2024-09-28'),
('R003', 'U018', '2024-09-28 22:00:00', '2024-09-28 22:50:00', '2024-09-28'),
('R001', 'U019', '2024-09-28 23:05:00', '2024-09-28 23:55:00', '2024-09-28'),
('R002', 'U020', '2024-09-28 23:15:00', '2024-09-29 00:05:00', '2024-09-28'),
('R003', 'U021', '2024-09-29 00:10:00', '2024-09-29 01:00:00', '2024-09-28'),
('R001', 'U022', '2024-09-29 01:05:00', '2024-09-29 01:45:00', '2024-09-28'),
('R002', 'U023', '2024-09-29 01:50:00', '2024-09-29 02:30:00', '2024-09-28'),
('R003', 'U024', '2024-09-29 02:40:00', '2024-09-29 03:15:00', '2024-09-28'),
('R001', 'U025', '2024-09-29 03:30:00', '2024-09-29 04:00:00', '2024-09-28'),
('R002', 'U026', '2024-09-29 04:10:00', '2024-09-29 04:50:00', '2024-09-28'),
('R003', 'U027', '2024-09-29 05:00:00', '2024-09-29 05:45:00', '2024-09-28'),
('R001', 'U028', '2024-09-29 06:00:00', '2024-09-29 06:30:00', '2024-09-28'),
('R002', 'U029', '2024-09-29 06:40:00', '2024-09-29 07:20:00', '2024-09-28'),
('R003', 'U030', '2024-09-29 07:30:00', '2024-09-29 08:00:00', '2024-09-28');


-- 求某个时间段内/某小时/每小时直播间最大在线人数
-- 求每个直播间在2024-09-28 10：00到13：00内最大在线人数


select
    room_id,
    current_nums
    from (
select
    room_id,
    current_nums,
    row_number() over (partition by room_id order by current_nums desc) ask_max_num
    from (
select room_id,
       action_ts,
       action_type,
       dt,
       sum(action_type) over(partition by room_id order by action_ts asc) current_nums
from (select room_id, user_id, login_time as action_ts, 1 as action_type, dt
      from live_room_activity
      union all
      select room_id, user_id, logout_time, -1 , dt
      from live_room_activity) t1
    ) t2
where dt = '2024-09-28' and action_ts >= '2024-09-28 10:00:00' and action_ts <= '2024-09-28 13:00:00'
    ) t3
where ask_max_num = 1;

-- 求每个直播间某个时间段内每小时内的同时在线最大人数
-- 求每个直播间在2024-09-28 10：00到13：00时间段，每小时内的同时在线最大人数

with t1 as (
select room_id,
       user_id,
       date_format(login_time,'yyyy-MM-dd HH:00:00') as date_hour,
       hour(login_time) hour_lower,
       logout_time,
       hour(logout_time) hour_upper,
       dt
from live_room_activity
where dt = '2024-09-28' and login_time >= '2024-09-28 10:00:00' and login_time <= '2024-09-28 13:00:00'
    ),
t2 as (
    select
        *
        from (
            select
                room_id,
                user_id,
                date_hour,
                from_unixtime(unix_timestamp(date_hour, 'yyyy-MM-dd HH:mm:ss') + pos * 3600) analysis_hour,
                logout_time
            from t1
            lateral view posexplode(split(space(hour_upper - hour_lower), ' ')) tbl as  pos,hour_str
        ) t2
    where logout_time != date_format(analysis_hour,'yyyy-MM-dd HH:mm:ss')
    )
select
    room_id,analysis_hour,
    count(distinct user_id) online_nums
from t2
group by room_id,analysis_hour;


-- 求最小达到某累计金额日期
-- 求取每个用户最近3天累计消费金额首次达到1W的日期
WITH user_consume_order AS (
    SELECT 'user1' AS user_id, '2023-01-01'  AS dt, 1000 AS price
    UNION ALL SELECT 'user1', '2023-01-02', 1200
    UNION ALL SELECT 'user1', '2023-01-03', 1300
    UNION ALL SELECT 'user1', '2023-01-04', 1400
    UNION ALL SELECT 'user1', '2023-01-05', 1500
    UNION ALL SELECT 'user1', '2023-01-06', 1600
    UNION ALL SELECT 'user1', '2023-01-07', 1700
    UNION ALL SELECT 'user1', '2023-01-08', 1800
    UNION ALL SELECT 'user1', '2023-01-09', 1900
    UNION ALL SELECT 'user1', '2023-01-10', 2000

    UNION ALL SELECT 'user2', '2023-01-01', 1100
    UNION ALL SELECT 'user2', '2023-01-02', 1250
    UNION ALL SELECT 'user2', '2023-01-03', 1350
    UNION ALL SELECT 'user2', '2023-01-04', 1450
    UNION ALL SELECT 'user2', '2023-01-05', 1550
    UNION ALL SELECT 'user2', '2023-01-06', 1650
    UNION ALL SELECT 'user2', '2023-01-07', 1750
    UNION ALL SELECT 'user2', '2023-01-08', 1850
    UNION ALL SELECT 'user2', '2023-01-09', 1950
    UNION ALL SELECT 'user2', '2023-01-10', 2000

    UNION ALL SELECT 'user3', '2023-01-01', 1050
    UNION ALL SELECT 'user3', '2023-01-02', 1150
    UNION ALL SELECT 'user3', '2023-01-03', 1250
    UNION ALL SELECT 'user3', '2023-01-04', 1350
    UNION ALL SELECT 'user3', '2023-01-05', 1450
    UNION ALL SELECT 'user3', '2023-01-06', 1550
    UNION ALL SELECT 'user3', '2023-01-07', 1650
    UNION ALL SELECT 'user3', '2023-01-08', 1750
    UNION ALL SELECT 'user3', '2023-01-09', 1850
    UNION ALL SELECT 'user3', '2023-01-10', 1950
)
select user_id,
       min(dt) first_date_to_limit
from (select user_id,
             dt,
             sum(price_daily)
                 over (partition by user_id order by dt asc rows between 3 preceding and current row) cumulative_price
      from (SELECT user_id,
                   dt,
                   sum(coalesce(price, 0.0)) price_daily
            FROM user_consume_order
            group by user_id, dt) t1) t2
where cumulative_price >= 4000
group by user_id;


-----------------------------------
CREATE TABLE tmp_sales (
    pay_time    DATE    COMMENT '付款日期',
    member_id   STRING  COMMENT '用户id',
    country     STRING  COMMENT '国家',
    sku         STRING  COMMENT '商品名称',
    sale_cnt    BIGINT  COMMENT '销量'
) COMMENT '销售明细表'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t';

INSERT INTO tmp_sales VALUES
('2024-09-01', 'M001', 'US', 'SKU001', 10),
('2024-09-02', 'M002', 'CN', 'SKU002', 5),
('2024-09-03', 'M003', 'IN', 'SKU003', 20),
('2024-09-04', 'M004', 'UK', 'SKU004', 15),
('2024-09-05', 'M005', 'DE', 'SKU005', 25);

CREATE TABLE tmp_refund (
    pay_time    DATE    COMMENT '退款商品对应的销售日期',
    member_id   STRING  COMMENT '用户id',
    refund_time DATE    COMMENT '退货日期',
    country     STRING  COMMENT '国家',
    sku         STRING  COMMENT '商品名称',
    refund_cnt  BIGINT  COMMENT '退货量'
) COMMENT '退款表'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t';
INSERT INTO tmp_refund VALUES
('2024-09-01', 'M001', '2024-09-10', 'US', 'SKU001', 2),
('2024-09-02', 'M002', '2024-09-11', 'CN', 'SKU002', 1),
('2024-09-03', 'M003', '2024-09-12', 'IN', 'SKU003', 5),
('2024-09-04', 'M004', '2024-09-13', 'UK', 'SKU004', 3),
('2024-09-05', 'M005', '2024-09-14', 'DE', 'SKU005', 4);


CREATE TABLE goods_info (
    sku     STRING  COMMENT '商品名称',
    cate    STRING  COMMENT '商品对应的类目'
) COMMENT '商品信息表'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t';
INSERT INTO goods_info VALUES
('SKU001', 'Electronics'),
('SKU002', 'Apparel'),
('SKU003', 'Books'),
('SKU004', 'Furniture'),
('SKU005', 'Toys');

-- 1.计算各月各类目商品在各个国家销售后30天内的退货率（退货率=退货量/销量）
    -- 算出有售量的国家名单
    -- 构建明细表， 用户id， 商品id， 购买日期，退款日期，购买数量，退款数量
with tt_country as (
    select collect_list(country) as country_list
    from (
        select country
        from tmp_sales
        group by country
    ) t
),
detail as (
    select sku, date_format(refund_time, 'yyyy-MM') refund_month, cate, country,
           sum(refund_cnt) / sum(sale_cnt) as refund_rate
    from (
        select t1.member_id,
               t1.sku,
               t1.pay_time,
               t2.refund_time,
               t1.sale_cnt,
               coalesce(t2.refund_cnt, 0) refund_cnt,
               t1.country,
               t3.cate
        from tmp_sales t1
        left join tmp_refund t2
            on t1.member_id = t2.member_id and t1.sku = t2.sku and t1.pay_time = t2.pay_time
        left join goods_info t3
            on t1.sku = t3.sku
        where t2.refund_time is not null
    ) tt
    where datediff(refund_time, pay_time) < 30
    group by date_format(refund_time, 'yyyy-MM'), cate, sku, country
)
select
    *
from detail;


-- 2.把网站首次购买用户分成只购买服装、只购买非服装、既购买服装又购买非服装三类，分别计算每个月这三类用户的用户数量，以及
-- ①在30天内复购任意类目的复购率
-- ②在30天内复购相同类目的复购率
-- （复购率=复购用户数/首购用户数）



-- 需要标志位， 1. 用户首次购买时的的类型（只购买服装，只购买非服装，即购买服装又购买非服装）； 2. 用户首次购买后复购时，在30天内购买商品类目类型（复购任意类目，只复购相同类目）

with first_user_purchase as (
    select
        member_id,first_pay_time,
        max(case
            when is_toys = '1' and is_not_toys = '1' then 'both'
            when is_toys = '1' and is_not_toys = '0' then 'only_toys'
            when is_toys = '0' and is_not_toys = '1' then 'not_toys'
            else 'abnormal'
        end )  as first_purchase_type
        from (select t1.member_id,
                     min(t1.pay_time)                 first_pay_time,
                     max(if(t2.cate = 'Toys', 1, 0))  is_toys,
                     max(if(t2.cate != 'Toys', 1, 0)) is_not_toys
              from tmp_sales t1
                       left join goods_info t2 on t1.sku = t2.sku
              group by t1.member_id) t3
        group by member_id, first_pay_time
),  -- 用户首次购买记录
    purchase as (
select
    t2.member_id,
    t2.first_pay_time,
    t2.first_purchase_type,
    tt.cate
    from (
        select
            member_id,
            pay_time,
            cate
        from (
            select
                t1.member_id,
                t1.pay_time,
                t2.cate,
                row_number() over (partition by member_id order by pay_time asc) rn
            from tmp_sales t1
            left join goods_info t2 on t1.sku = t2.sku
             ) t1
        where rn = 1) tt
    left join first_user_purchase t2 on tt.member_id = t2.member_id and tt.pay_time = t2.first_pay_time

),
    repurchase_cate_type as (
    select
        t1.member_id,
        t3.first_purchase_type,
       if(t1.pay_time > t3.first_purchase_type and datediff(t1.pay_time, t3.first_pay_time) <= 30 and t2.cate = t3.cate, '1',0) some_cate,
       if(t1.pay_time > t3.first_purchase_type and datediff(t1.pay_time, t3.first_pay_time) <= 30 , '1',0) is_repurchase
    from tmp_sales t1
    left join goods_info t2 on t1.sku = t2.sku
    left join purchase t3 on t1.member_id = t3.member_id
)
select
    first_purchase_type,
    count(distinct member_id) repeat_users,
    count(distinct (case when is_repurchase = '1' then member_id end )) / count(distinct member_id) repurchase_rate,
    count(distinct (case when some_cate = '1' then member_id end )) / count(distinct member_id) some_cate_repurchase_rate
from repurchase_cate_type t1
group by first_purchase_type;


--历史新低的商品id
CREATE TABLE product_price_change (
    id STRING COMMENT '商品ID',
    start_price INT COMMENT '商品变更前价格',
    after_price INT COMMENT '商品变更后价格',
    `time` STRING COMMENT '时间戳'
)
COMMENT '商品价格变化表'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t';

-- 插入商品a111的6条数据
INSERT INTO product_price_change VALUES
('a111', 10, 8, '2023011000'),
('a111', 8, 7, '2023011100'),
('a111', 7, 5, '2023011200'),
('a111', 5, 6, '2023011300'),
('a111', 6, 4, '2023011400'),
('a111', 4, 3, '2023011500'),
('a111', 3, 2, '2023011600');

-- 插入商品a112的6条数据
INSERT INTO product_price_change VALUES
('a112', 12, 11, '2023011000'),
('a112', 11, 10, '2023011100'),
('a112', 10, 8, '2023011200'),
('a112', 8, 9, '2023011300'),
('a112', 9, 7, '2023011400'),
('a112', 7, 5, '2023011500');

-- 插入商品a113的6条数据
INSERT INTO product_price_change VALUES
('a113', 15, 14, '2023011000'),
('a113', 14, 13, '2023011100'),
('a113', 13, 11, '2023011200'),
('a113', 11, 10, '2023011300'),
('a113', 10, 8, '2023011400'),
('a113', 8, 7, '2023011500');


with lasted_price as (select id,
                             start_price,
                             after_price,
                             `time`,
                             rn
                      from (select id,
                                   start_price,
                                   after_price,
                                   `time`,
                                   row_number() over (partition by id order by `time` desc) rn

                            from product_price_change) t1
                      where rn = 1),
    history_price as (
        select
            id,
            min(start_price) min_start_price,
            min(after_price) min_after_price
        from (select
                  *
                  from (select id,
                     start_price,
                     after_price,
                     `time`,
                     row_number() over (partition by id order by `time` desc) rn
              from product_price_change) t1
                where rn > 1
             )tt
        group by id
    )

select
    t1.id,
    t1.after_price
from lasted_price t1
join history_price t2
on t1.id = t2.id
where t1.after_price < t2.min_start_price and t1.after_price < t2.min_after_price;

