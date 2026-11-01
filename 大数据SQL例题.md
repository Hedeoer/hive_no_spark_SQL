---
private: true
title: 大数据SQL例题
category: SQL练习
pathname: __gh__50
author: 
copyright: 
top: 0
updatedAt: 2026-03-03T09:46:00.421Z
createdAt: 2025-03-06T09:13:32.000Z
hidden: false
password: 
---

## 查询连续登陆3天以上的用户

```plsql
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
-- 方法1
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
-- 方法2
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
```
## 查询连续登陆最大天数用户
```plsql
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
```
## 按照天的单位合并用户连续登录的时间区间，间隔不大于2天，均算连续登录

```plsql
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
```
## 求出股票波峰波谷
```plsql
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
```
## 求取每个店铺每次开业前一次开业日期和之后的最近的一次开业日期
```plsql
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
```
## 同时在线最大人数

```sql
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
group by room_id,analysis_hour
```
## 用户收购分析
```plsql
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
```
## 历史新低的商品id

```plsql
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
```
## 找出连续3条或更多条

```plsql
-- 创建 Stadium 表
CREATE TABLE IF NOT EXISTS Stadium (
  id INT,
  visit_date STRING,
  people INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;
-- 插入示例数据
INSERT INTO Stadium VALUES
(1, '2017-01-01', 10),
(2, '2017-01-02', 109),
(3, '2017-01-03', 150),
(4, '2017-01-04', 99),
(5, '2017-01-05', 145),
(6, '2017-01-06', 1455),
(7, '2017-01-07', 199),
(8, '2017-01-09', 188);
/*
需求描述:
1. 表 Stadium 包含字段: `id` (体育场访问记录唯一标识)，`visit_date` (访问日期)，`people` (当天人流量)。
2. 目标是找出 `id` 连续的记录，且这些连续的记录中 `people` 字段的值大于等于 100，满足连续的行数至少为 3。
3. 结果按 `visit_date` 升序排序。
4. 示例数据：
   +------+------------+-----------+
   | id   | visit_date | people    |
   +------+------------+-----------+
   | 1    | 2017-01-01 | 10        |
   | 2    | 2017-01-02 | 109       |
   | 3    | 2017-01-03 | 150       |
   | 4    | 2017-01-04 | 99        |
   | 5    | 2017-01-05 | 145       |
   | 6    | 2017-01-06 | 1455      |
   | 7    | 2017-01-07 | 199       |
   | 8    | 2017-01-09 | 188       |
   +------+------------+-----------+
5. 输出结果应包含连续 `id` 的记录，且这些行的 `people` 均大于等于 100，行数至少为 3。
6. 示例输出：
   +------+------------+-----------+
   | id   | visit_date | people    |
   +------+------------+-----------+
   | 5    | 2017-01-05 | 145       |
   | 6    | 2017-01-06 | 1455      |
   | 7    | 2017-01-07 | 199       |
   | 8    | 2017-01-09 | 188       |
   +------+------------+-----------+
*/
select id,
       visit_date,
       people,
       continus_counts,
       row_number() over (partition by continus_counts order by visit_date asc)
from (
        select
            id,
            visit_date,
            people,
            count(1) over(partition by flag) continus_counts
            from (
                select id,
                       visit_date,
                       people,
                       id - row_number() over (order by id asc) as flag
                from Stadium
                where people >= 100
            ) t1
        )t2
    where continus_counts >= 3;
with tmp as (
    select id,
           visit_date,
           people
    from Stadium
    where people >= 100
)
select t1.id,
       t1.visit_date,
       t1.people
from tmp t1
join tmp t2 on t1.id = t2.id - 1
join tmp t3 on t2.id = t3.id - 1;
```
## 学生成绩表中的每个学生的成绩转为一行

```plsql
-- 创建班级成绩表
CREATE TABLE IF NOT EXISTS ClassScores (
    class STRING,
    student STRING,
    score STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;
-- 插入示例数据
INSERT INTO ClassScores VALUES
('1班', '小A,小B,小C', '80,92,70'),
('2班', '小D,小E', '88,62'),
('3班', '小F,小G,小H', '90,97,85');
/*
需求描述:
1. 表 ClassScores 包含字段: `class` (班级)，`student` (学生列表)，`score` (对应的学生成绩列表)。
2. 目标是将每个学生的成绩转为独立的一行，即每个学生和他对应的成绩成为单独的一行。
3. 输出表应包含字段: 班级、学生、成绩。
4. 示例数据：
   +------+----------------+-----------+
   | class| student         | score     |
   +------+----------------+-----------+
   | 1班  | 小A,小B,小C     | 80,92,70  |
   | 2班  | 小D,小E         | 88,62     |
   | 3班  | 小F,小G,小H     | 90,97,85  |
   +------+----------------+-----------+
5. 需要将上述数据转换为如下格式：
   +------+---------+-------+
   | class| student | score |
   +------+---------+-------+
   | 1班  | 小A     | 80    |
   | 1班  | 小B     | 92    |
   | 1班  | 小C     | 70    |
   | 2班  | 小D     | 88    |
   | 2班  | 小E     | 62    |
   | 3班  | 小F     | 90    |
   | 3班  | 小G     | 97    |
   | 3班  | 小H     | 85    |
   +------+---------+-------+
*/
select
    t1.class,
    names.student_name,
    scores.student_score
from classscores t1
lateral view posexplode(split(t1.student ,',')) names as student_id, student_name
lateral view posexplode(split(t1.score,',')) scores as student_id, student_score
where names.student_id = scores.student_id;
```
## 球员得分分析
```plsql
-- 需求描述:
-- 对球员的的各场得分做一个分数段的区分，比如：
-- 球员张三，A场次得分 123，则需要得到 1 -100分段得分为6，101 - 200分段得分100，201 - 300分段得分17.依次类推。
WITH data AS (
    SELECT '张三' AS `palyer`, 1 AS `collector`, 30 AS `score`, '北京' AS `game_room`, '2022/2/2' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 2 AS `collector`, 28 AS `score`, '上海' AS `game_room`, '2022/2/7' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 3 AS `collector`, 36 AS `score`, '广州' AS `game_room`, '2022/2/12' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 4 AS `collector`, 123 AS `score`, '深圳' AS `game_room`, '2022/2/17' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 5 AS `collector`, 19 AS `score`, '南京' AS `game_room`, '2022/2/22' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 6 AS `collector`, 202 AS `score`, '武汉' AS `game_room`, '2022/2/27' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 7 AS `collector`, 354 AS `score`, '成都' AS `game_room`, '2022/3/4' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 8 AS `collector`, 23 AS `score`, '厦门' AS `game_room`, '2022/3/9' AS `game_date`
)
select
    *
from (select palyer,
             collector,
             score,
             game_room,
             game_date,
             -- 计算分区区间
             concat(score_group * 100 - 100 + 1, "-", score_group * 100) as                                                       score_range,
             -- 对相同分数组的行进行累加，得到当前分数的累计值
             sum(pos)
                 over (partition by palyer,game_date, game_room, collector, score_group order by game_date, score_group)          score_current,
             row_number() over (partition by palyer,game_date, game_room, collector, score_group order by game_date, score_group) rn
      from (select palyer,
                   collector,
                   score,
                   game_room,
                   game_date,
                   -- 对分数进行分组，每组100个，比如当前累计分数为54，计算后得到 score_group = 1;分配的组为1 -100；如果累计的分数为145，计算后得到 score_group = 2,分配的组为101 - 200
                   ceil(count(pos) over ( order by collector, game_date, pos) / 100) as score_group,
                   1                                                                 as pos
            from data
                     lateral view posexplode(split(repeat(' ', score - 1), '\\(?|$\\)')) temp as pos, val) t1)t2
-- 相同分数组的行，score_current是相同的，取第一条即可
where rn = 1;
-- 详细分析查看语雀文档：
```
分析：

![1](https://5201969.xyz/api/public/img/7c638ea319817382254e17bc483ff3d7)



![2](https://5201969.xyz/api/public/img/fe7ffa5718c87f80ee7c70511565e277)

## 查找互相关注的用户对

```plsql
CREATE TABLE fans (
    from_user STRING,
    to_user STRING,
    notice_date STRING
)
COMMENT '用户关注关系表'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;
INSERT INTO fans VALUES ('A', 'B', '2022-11-28 12:12:12');
INSERT INTO fans VALUES ('A', 'C', '2022-11-28 12:12:13');
INSERT INTO fans VALUES ('A', 'D', '2022-11-28 12:12:14');
INSERT INTO fans VALUES ('B', 'A', '2022-11-28 12:12:16');
INSERT INTO fans VALUES ('C', 'A', '2022-11-28 12:12:16');
INSERT INTO fans VALUES ('D', 'A', '2022-11-28 12:12:17');
/*
需求:
1. 在 fans 表中查找互相关注的用户对。
2. 互相关注定义为：用户 A 关注了用户 B，同时用户 B 也关注了用户 A。
3. 需要避免重复显示同一对用户（如 A-B 和 B-A 只显示一次）。
*/
-- 查找互相关注的用户对，避免重复
--方式一
SELECT t1.from_user, t1.to_user
FROM fans t1
 JOIN fans t2
ON t1.from_user = t2.to_user
AND t1.to_user = t2.from_user;
--方式二
select from_user,
       to_user
from (select from_user, to_user
      from fans
      union all
      select to_user, from_user
      from fans) t1
group by from_user, to_user
having count(1) >= 2;
-- 方式三
select from_user,to_user
from (select from_user,
             to_user,
             if(count(fans_user) over (partition by fans_user) > 1, 1, 0) as is_fans
      from (select
                if(hash(from_user) > hash(to_user), concat(from_user, '-', to_user),concat(to_user, '-', from_user)) fans_user,
                from_user,
                to_user
            from fans)t1)t2
where is_fans = 1;
/*
解释：
if(hash(from_user) > hash(to_user), concat(from_user, '-', to_user),concat(to_user, '-', from_user))。
这里的 if 语句用于生成唯一的 fans_user 标识符，代表一个唯一的关注关系对。
hash(from_user) 和 hash(to_user) 用于计算两个用户的哈希值。
如果 from_user 的哈希值大于 to_user 的哈希值，则将 from_user 和 to_user 连接为 from_user-to_user 的形式。
否则，将 to_user 和 from_user 连接为 to_user-from_user 的形式。
这样可以确保不管关注关系的方向，fans_user 都能够唯一标识一个用户对（如 A-B 和 B-A 用同一个标识B-A表示）。
if(count(fans_user) over (partition by fans_user) > 1, 1, 0)
这里的 if 语句用于判断 fans_user 的出现次数是否大于 1。
count(fans_user) over (partition by fans_user) 计算 fans_user 在整个结果集中出现的次数。
如果出现次数大于 1，则返回 1，表示这是一个互相关注的用户对。
否则，返回 0，表示这不是一个互相关注的用户对。
*/
-- 方式四
select count(*)
      ,fans2
      ,fans1
from (
SELECT
    t1.fans1 ,
    t2.fans2
FROM (
    SELECT
        CONCAT(from_user,'-',to_user) AS fan1,
        CONCAT(to_user,'-',from_user) AS fan2,
        from_user
    FROM fans
) as temp_table
LATERAL VIEW posexplode(split(temp_table.fan1,'-')) t1 AS fans_index1,fans1
LATERAL VIEW posexplode(split(temp_table.fan2,'-')) t2 AS fans_index2,fans2
WHERE t1.fans_index1 = t2.fans_index2
)
group by fans2
        ,fans1
having count(*)=2;
SELECT count(sort_array(split(user_fans,'-')))
      ,sort_array(split(user_fans,'-'))
from (
SELECT concat_ws(',',COLLECT_LIST(concat(from_user,'-',to_user))) as user_fans
      ,from_user
FROM fans
group by from_user
) GROUP BY sort_array(split(user_fans,'-'))
having count(sort_array(split(user_fans,'-')))=2;
```
## 平台留存分析

```plsql
-- ### 需求分析：
-- 基于提供的数据，计算某平台的N日留存率。留存率通常指在一个特定时间段注册或第一次访问的用户，在某个后续时间点（如第 7 天）再次访问或使用平台的用户百分比。
--
-- ### 数据分析：
-- - `uid`: 用户 ID。
-- - `date`: 用户登录或访问的时间。
-- - 需要计算七日留存率，即：
--   - 对于某一天注册或第一次访问的用户，查看他们是否在第 7 天再次访问。
-- ### 需求整理：
-- 1. **统计每个用户的首次访问时间**。
-- 2. **检查首次访问的第 7 天用户是否再次访问**。
-- 3. **计算七日留存率**。
-- ### 模拟数据和建表语句：
-- #### 1. **整理需求**
-- ```sql
-- /*
-- 需求：
-- 1. 计算某平台的七日留存率。
-- 2. 每个用户首次访问的第N天是否再次访问。
-- 3. 统计某天注册用户在第N天的留存情况。
-- */
-- ```
-- 创建用户访问日志表
drop table if exists user_access_log;
CREATE TABLE IF NOT EXISTS user_access_log (
    uid INT,               -- 用户ID
    access_time TIMESTAMP  -- 用户访问时间
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;
-- 插入模拟数据
-- 插入模拟数据
INSERT INTO user_access_log VALUES
    -- 用户1：2019-01-01首次访问，且在接下来的7天内每天都有访问
    (1, '2019-01-01 00:00:00'),
    (1, '2019-01-02 00:00:00'),  -- 1日留存
    (1, '2019-01-03 00:00:00'),  -- 2日留存
    (1, '2019-01-04 00:00:00'),  -- 3日留存
    (1, '2019-01-05 00:00:00'),  -- 4日留存
    (1, '2019-01-06 00:00:00'),  -- 5日留存
    (1, '2019-01-07 00:00:00'),  -- 6日留存
    (1, '2019-01-08 00:00:00'),  -- 7日留存
    -- 用户2：2019-01-01首次访问，且在接下来的7天内部分天有访问
    (2, '2019-01-01 00:00:00'),
    (2, '2019-01-02 00:00:00'),  -- 1日留存
    (2, '2019-01-04 00:00:00'),  -- 3日留存
    (2, '2019-01-06 00:00:00'),  -- 5日留存
    (2, '2019-01-08 00:00:00'),  -- 7日留存
    -- 用户3：2019-01-01首次访问，仅在部分天数有访问
    (3, '2019-01-01 00:00:00'),
    (3, '2019-01-03 00:00:00'),  -- 2日留存
    (3, '2019-01-05 00:00:00'),  -- 4日留存
    (3, '2019-01-07 00:00:00'),  -- 6日留存
    -- 用户4：2019-01-01首次访问，且在第7天也有访问
    (4, '2019-01-01 00:00:00'),
    (4, '2019-01-08 00:00:00');  -- 7日留存
-- 解法一
-- 自联结
select
t1.access_date,
    sum(if( datediff(t2.access_date , t1.access_date) = 1, 1, 0)) / count(distinct t1.uid) 1_rentions_rate,
    sum(if( datediff(t2.access_date , t1.access_date) = 2, 1, 0)) / count(distinct t1.uid) 2_rentions_rate,
    sum(if( datediff(t2.access_date , t1.access_date) = 3, 1, 0)) / count(distinct t1.uid) 3_rentions_rate
from (select uid, to_date(access_time) access_date from user_access_log group by uid ,to_date(access_time)) t1
left join (select uid, to_date(access_time) access_date from user_access_log group by uid ,to_date(access_time)) t2
on t1.access_date < t2.access_date and t1.uid = t2.uid
group by t1.access_date;
-- 解法二
-- lag处理
with user_access as (
    select
        uid,
        to_date(access_time) access_date,
        lag(to_date(access_time), 1) over(partition by uid order by to_date(access_time)) prev_date
    from user_access_log
)
select
    first_day.access_date,
    sum(if(datediff(next_day.access_date, first_day.access_date) = 1, 1, 0)) / count(distinct first_day.uid) 1_rentions_rate,
    sum(if(datediff(next_day.access_date, first_day.access_date) = 2, 1, 0)) / count(distinct first_day.uid) 2_rentions_rate,
    sum(if(datediff(next_day.access_date, first_day.access_date) = 3, 1, 0)) / count(distinct first_day.uid) 3_rentions_rate
from (
    select uid,
           access_date,
           prev_date
    from user_access
    where prev_date is null
     ) first_day
left join (
    select uid,
           access_date,
           prev_date
    from user_access
    where prev_date is not null
) next_day
on first_day.uid = next_day.uid
group by first_day.access_date;
-- 解法三
-- array_contains的方式
with user_access as (
    select
        uid,
        to_date(access_time) access_date
    from user_access_log
),
    user_visist as (
        select
            uid,
            collect_set(access_date) visit_list
        from user_access
        group by uid
    )
select
    t1.first_access_date,
    count(if(array_contains(t2.visit_list,date_add(t1.first_access_date,1)),t1.uid,null)) / count(t1.uid) 1_retention_rate,
    count(if(array_contains(t2.visit_list,date_add(t1.first_access_date,2)),t1.uid,null)) / count(t1.uid) 2_retention_rate,
    count(if(array_contains(t2.visit_list,date_add(t1.first_access_date,3)),t1.uid,null)) / count(t1.uid) 3_retention_rate
    from (
        select
            uid,
            min(access_date) first_access_date
        from user_access
        group by uid
    ) t1
left join user_visist t2
on t1.uid = t2.uid
group by t1.first_access_date;
```

## 用户存款期数维表构建

![image-20250306171332366](https://5201969.xyz/api/public/img/9b12938c46ea4b18bb4e26a56aa4529a)

```sql

-- 需求：根据第一张表生成第二张表。其中，"Amount"和"Value_Date"按逻辑递增。例如，对于每个合同（contract），在初始日期后每过一个"Term"月，"Value_Date"增加，"Amount"累计增加前一行"Amount"。
-- 用户存款期数维表构建
/*
1. 构建每组 constract 和 term对应的 最早 value_date
2. 炸裂
3. 围标 left join 原来表 on contract = contract and value_date = value_date
4. 累计求和
*/
WITH data AS (
  SELECT 'AAAA' AS contract, '2018-12-21' AS value_date, 9439 AS amount, 12 AS term
  UNION ALL
  SELECT 'AAAA', '2019-03-21', 9439, 12
  UNION ALL
  SELECT 'AAAA', '2019-06-21', 9439, 12
  UNION ALL
  SELECT 'AAAA', '2019-09-21', 9439, 12
  UNION ALL
  SELECT 'BBBB' AS contract, '2018-12-02' AS value_date, 9439 AS amount, 10 AS term
  UNION ALL
  SELECT 'BBBB', '2019-02-02', 9439, 10
  UNION ALL
  SELECT 'BBBB', '2019-06-02', 9439, 10
  UNION ALL
  SELECT 'BBBB', '2019-09-02', 9439, 10
),
    t1 as(
        select
            contract,
            term,
            min(to_date(value_date)) as min_value_date
        from data
        group by contract, term
    ),
    t2 as (
        select
            t1.contract,
            t1.term,
            add_months(t1.min_value_date, pos) as value_date
        from t1
        lateral view posexplode(split(space(term - 1), ' ')) tmp as pos, value
    )
select
  t2.contract,
  t2.value_date,
  cast(sum(nvl(data.amount, 0)) over(partition by t2.contract, t2.term order by t2.value_date) as decimal(18,2))  as acc_amount,
  t2.term
from t2
left join data on t2.contract = data.contract and t2.value_date = data.value_date;


```



## 炸裂中元素索引位置的使用



![image-20250307144840279](https://5201969.xyz/api/public/img/44941886cacc86d0ae4dfcc556d166ea)

```sql
-- 炸裂恢复
SELECT student,
       collect_list(concat_ws(',', class))                 AS class,
       collect_list(concat_ws(',', CAST(score AS STRING))) AS score
FROM (SELECT 'a' AS class, 'yuxing' AS student, 100 AS score
      UNION ALL
      SELECT 'c' AS class, 'yuxing1' AS student, null AS score
      UNION ALL
      SELECT 'b' AS class, 'yuxing' AS student, 80 AS score
      UNION ALL
      SELECT 'b' AS class, 'yuxing1' AS student, 80 AS score
      UNION ALL
      SELECT 'c' AS class, 'yuxing' AS student, 90 AS score) t
GROUP BY student;


-- 炸裂中元素索引位置的使用
with t1 as (SELECT student,
                   collect_list(concat_ws(',', class))                 AS class,
                   collect_list(concat_ws(',', CAST(score AS STRING))) AS score
            FROM (SELECT 'a' AS class, 'yuxing' AS student, 100 AS score
                  UNION ALL
                  SELECT 'c' AS class, 'yuxing1' AS student, null AS score
                  UNION ALL
                  SELECT 'b' AS class, 'yuxing' AS student, 80 AS score
                  UNION ALL
                  SELECT 'b' AS class, 'yuxing1' AS student, 80 AS score
                  UNION ALL
                  SELECT 'c' AS class, 'yuxing' AS student, 90 AS score) t
            GROUP BY student)
select
    t1.student,
    t2.class1,
    t3.score1
from t1
lateral view posexplode(class) t2 as pos,class1
lateral view posexplode(score) t3 as pos1,score1
where t2.pos = t3.pos1;

```

![image-20250307144913960](https://5201969.xyz/api/public/img/a04fe2b39dbf37bbcc2b863aa907af5e)





## 字符串的展开

![image-20250308190452384](https://5201969.xyz/api/public/img/a99ed3352db0e31147170fce936554bf)

```sql
-- To expand the string '1-5,16,11-13,9' to '1,2,3,4,5,16,11,12,13,9'
WITH t AS (SELECT '1-5,16,11-13,9' AS str),
     t1 AS (SELECT t2.str,
                   row_number() OVER (ORDER BY t2.pos) AS rn
            FROM t
                     LATERAL VIEW posexplode(split(str, ',')) t2 AS pos, str),
     t2 AS (SELECT t1.str,
                   t1.rn,
                   MIN(CAST(t3.part AS INT))                             AS start_value,
                   MAX(CAST(t3.part AS INT)) - MIN(CAST(t3.part AS INT)) AS len
            FROM t1
                     LATERAL VIEW explode(split(t1.str, '-')) t3 AS part
            GROUP BY t1.str, t1.rn),
    t4 AS (
        select t2.str,
               t2.rn,
               t2.start_value,
               t2.len,
               t2.start_value + t5.pos AS current_value,
               row_number() over (order by t2.rn) total_rn
        from t2
        lateral view posexplode(split(space(t2.len), '')) t5 as pos, part
    )
select
    concat_ws(',',collect_set(cast(current_value as string))) target
from t4;
```





![image-20250308190432310](https://5201969.xyz/api/public/img/e699067c07a6a28e3c05f7fa3cd742bc)





## 留存率的计算

参考文章[两表两条件解决次日留存率，七日留存率问题](https://blog.csdn.net/u013102054/article/details/134366691)

方式1

![image-20250309165828281](https://5201969.xyz/api/public/img/b506cdaeb14dfddcb983297092a5ffba)

```sql
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

```

方式二

![image-20250309165718400](https://5201969.xyz/api/public/img/e9404140e547795f4a03c8a098762461)



```sql

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

```





## 数据的合并

![image-20250310142137904](https://5201969.xyz/api/public/img/48f2c9567ea6dd24e284923316ea988b)

```sql

-- 数据合并
/*
1. max(id) over(partition by name order by id desc) max_id
2. group by max_id, name
*/
WITH data AS (SELECT 1 AS id, 'aa' AS name
              UNION ALL
              SELECT 2, 'aa'
              UNION ALL
              SELECT 3, 'aa'
              UNION ALL
              SELECT 4, 'aa'
              UNION ALL
              SELECT 5, 'c'
              UNION ALL
              SELECT 6, 'aa'
              UNION ALL
              SELECT 7, 'f'
              UNION ALL
              SELECT 8, 'e'
              UNION ALL
              SELECT 9, 'f'
              UNION ALL
              SELECT 10, 'g')
select max_id,
       concat_ws(',', collect_list(name)) names
from (select max(id) over (partition by name order by id desc) max_id,
             name
      from data) t1
group by max_id, name;


/*
方式二：
保证最终结果和元数据的name顺序一致
*/
WITH data AS (SELECT 1 AS id, 'aa' AS name
              UNION ALL
              SELECT 2, 'aa'
              UNION ALL
              SELECT 3, 'aa'
              UNION ALL
              SELECT 4, 'aa'
              UNION ALL
              SELECT 5, 'c'
              UNION ALL
              SELECT 6, 'aa'
              UNION ALL
              SELECT 7, 'f'
              UNION ALL
              SELECT 8, 'e'
              UNION ALL
              SELECT 9, 'f'
              UNION ALL
              SELECT 10, 'g'),

     t1 as (select max(id) over (partition by name) max_id,
                   min(id) over (partition by name) min_id,
                   name
            from data)
select
    max_id,
    concat_ws(',',collect_list(name)) names
from t1
group by name,max_id
order by min_id;

/*
1. 判断是否分为同一组
*/

WITH data AS (SELECT 1 AS id, 'aa' AS name
              UNION ALL
              SELECT 2, 'aa'
              UNION ALL
              SELECT 3, 'aa'
              UNION ALL
              SELECT 4, 'aa'
              UNION ALL
              SELECT 5, 'c'
              UNION ALL
              SELECT 6, 'aa'
              UNION ALL
              SELECT 7, 'f'
              UNION ALL
              SELECT 8, 'e'
              UNION ALL
              SELECT 9, 'f'
              UNION ALL
              SELECT 10, 'g'),
 t1 as (
    select
        id,
        name,
        sum(case
            when pre_name is null then 0
            when pre_name = name then 0
            else 1 end
        ) over(order by id) group_id
    from (
        select id,
               name,
               lag(name) over(order by id) pre_name
        from data
         ) t2
    ),
    t3 as (
        select
            group_id,
            name,
            min(id) over(partition by group_id, name) min_id,
            max(id) over(partition by group_id, name) max_id
        from t1
    )
select
    max_id,
    concat_ws(',',collect_list(name)) names
from t3
group by group_id,max_id,min_id
order by min_id;
```



## 数据的合并（数据交集）

```sql

-- 求出每个品牌的活动天数，出现日期重叠的算一天
WITH data AS (
    SELECT '华为' AS brand, '2018-08-04' AS begin_date, '2018-08-05' AS end_date  UNION ALL
    SELECT '华为' AS brand, '2018-08-04' AS begin_date, '2020-12-25' AS end_date  UNION ALL
    SELECT '小米' AS brand, '2018-08-15' AS begin_date, '2018-08-20' AS end_date  UNION ALL
    SELECT '小米' AS brand, '2020-01-01' AS begin_date, '2020-01-05' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-01' AS begin_date, '2018-09-05' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-03' AS begin_date, '2018-09-06' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-09' AS begin_date, '2018-09-15' AS end_date
)
select
    brand,
    count(distinct date_add(begin_date,pos)) read_days
from data
lateral view posexplode(split(space(datediff(end_date,begin_date)),'')) tmp as pos,val
group by brand;


-- 求出每个品牌的活动天数，出现日期重叠的算一天
WITH data AS (
    SELECT '华为' AS brand, '2018-08-04' AS begin_date, '2018-08-05' AS end_date  UNION ALL
    SELECT '华为' AS brand, '2018-08-04' AS begin_date, '2020-12-25' AS end_date  UNION ALL
    SELECT '小米' AS brand, '2018-08-15' AS begin_date, '2018-08-20' AS end_date  UNION ALL
    SELECT '小米' AS brand, '2020-01-01' AS begin_date, '2020-01-05' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-01' AS begin_date, '2018-09-05' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-03' AS begin_date, '2018-09-06' AS end_date  UNION ALL
    SELECT '苹果' AS brand, '2018-09-09' AS begin_date, '2018-09-15' AS end_date
),
    pre_max_end_date as (
        select brand,
               to_date(begin_date) `begin_date`,
               to_date(end_date) `end_date`,
               max(end_date) over(partition by brand order by begin_date rows between unbounded preceding and 1 preceding) pre_max_end_date
        from data
    ),
    group_date as (
        select
            brand,
            begin_date,
            end_date,
            pre_max_end_date,
            sum(is_new) over(partition by brand order by begin_date) group_id
        from (
            select brand,
                   begin_date,
                   end_date,
                   pre_max_end_date,
                   -- 如果开始时间小于等于前一个最大结束时间，则为日期重叠，标记为相同组，记为0，否则为1
                   case
                       when pre_max_end_date is null then 0
                       when begin_date <= pre_max_end_date then 0
                       else 1 end is_new
            from pre_max_end_date
             ) t
    ),
    -- 按照分组合并重叠区间
    merge_group as (
        select
            brand,
            group_id,
            min(begin_date) begin_date,
            max(end_date) end_date
        from group_date
        group by brand,group_id
    )
select
    brand,
    sum(datediff(end_date,begin_date)+1) read_days
from merge_group
group by brand;


-- 方式一
-- 直播间用户在线时长计算，有登录时间重叠的算一次时长
-- 1.炸裂登录区间，处理登出时间为null的情况
-- 2.统计每个user_id在不同room_id的在线时长
-- 3.排序求前五名
WITH user_live_sessions AS (
    -- 直播间101的用户
    SELECT 101 as room_id, 1001 as user_id, '2023-04-10 18:00:00' as login_time, '2023-04-10 19:30:00' as logout_time UNION ALL
    SELECT 101, 1001, '2023-04-10 20:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 101, 1002, '2023-04-10 18:30:00', '2023-04-10 20:45:00' UNION ALL
    SELECT 101, 1003, '2023-04-10 19:00:00', '2023-04-10 22:00:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 17:30:00', '2023-04-10 18:45:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 19:15:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 101, 1005, '2023-04-10 18:15:00', '2023-04-10 21:45:00' UNION ALL
    SELECT 101, 1006, '2023-04-10 18:45:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 101, 1007, '2023-04-10 19:30:00', '2023-04-10 21:30:00' UNION ALL

    -- 直播间102的用户
    SELECT 102, 1001, '2023-04-10 17:00:00', '2023-04-10 18:00:00' UNION ALL
    SELECT 102, 1002, '2023-04-10 17:30:00', '2023-04-10 19:00:00' UNION ALL
    SELECT 102, 1008, '2023-04-10 18:00:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 102, 1009, '2023-04-10 18:30:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 19:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 21:30:00', '2023-04-10 22:15:00' UNION ALL

    -- 异常记录（登出时间为NULL）
    SELECT 101, 1008, '2023-04-10 19:45:00', cast(NULL as string) UNION ALL
    SELECT 102, 1005, '2023-04-10 20:00:00', cast(NULL as string)
),
 explode_sessions as (
     select
         user_id,
         room_id,
         unix_timestamp(login_time) + tmp.pos as login_time
     from user_live_sessions
    lateral view posexplode(split(space(cast((coalesce(unix_timestamp(logout_time), unix_timestamp()) - unix_timestamp(login_time)) as int)),'')) tmp as pos,val
     group by user_id, room_id, unix_timestamp(login_time) + tmp.pos
 ),
    agg_onlin_time as (
        select
            user_id,
            room_id,
            max(login_time) - min(login_time) as online_time
        from explode_sessions
        group by user_id, room_id
    )
select
    room_id,
    online_time,
    rank_id
from (
    select
        user_id,
        room_id,
        online_time,
        rank() over(partition by room_id order by online_time desc) as rank_id
    from agg_onlin_time
        ) t
where rank_id <= 5;

-- 方式二 优化重复时间段的计算
/*
同一个用户在相同的直播间观看记录存在时间重叠，比如用户A：10:00 - 11:00 观看了直播间1，有一条记录，现有另一个记录用户A：10:30 - 11:30 观看了直播间1，那个统计用户A在直播间总共的观看时长为90分钟

核心处理逻辑
标记所有时间点：
将每个用户在每个直播间的所有登入登出时间标记为离散点
登入点标记为+1，登出点标记为-1

计算活跃状态：
按用户ID和房间ID分组，对时间点排序
使用窗口函数计算累计活跃状态
活跃状态>0表示用户在线

合并重叠时间段：
只计算活跃状态>0的相邻时间点之间的时长
自然处理了重叠时间问题
*/
WITH user_live_sessions AS (
     -- 直播间101的用户
    SELECT 101 as room_id, 1001 as user_id, '2023-04-10 18:00:00' as login_time, '2023-04-10 19:30:00' as logout_time UNION ALL
    SELECT 101, 1001, '2023-04-10 20:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 101, 1002, '2023-04-10 18:30:00', '2023-04-10 20:45:00' UNION ALL
    SELECT 101, 1003, '2023-04-10 19:00:00', '2023-04-10 22:00:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 17:30:00', '2023-04-10 18:45:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 19:15:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 101, 1005, '2023-04-10 18:15:00', '2023-04-10 21:45:00' UNION ALL
    SELECT 101, 1006, '2023-04-10 18:45:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 101, 1007, '2023-04-10 19:30:00', '2023-04-10 21:30:00' UNION ALL

    -- 直播间102的用户
    SELECT 102, 1001, '2023-04-10 17:00:00', '2023-04-10 18:00:00' UNION ALL
    SELECT 102, 1002, '2023-04-10 17:30:00', '2023-04-10 19:00:00' UNION ALL
    SELECT 102, 1008, '2023-04-10 18:00:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 102, 1009, '2023-04-10 18:30:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 19:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 21:30:00', '2023-04-10 22:15:00' UNION ALL

    -- 异常记录（登出时间为NULL）
    SELECT 101, 1008, '2023-04-10 19:45:00', cast(NULL as string) UNION ALL
    SELECT 102, 1005, '2023-04-10 20:00:00', cast(NULL as string)
),
-- 步骤1: 标记用户在房间的登入登出点
user_room_time_points AS (
    -- 登入点，标记为1
    SELECT
        user_id,
        room_id,
        unix_timestamp(login_time) AS time_point,
        1 AS flag
    FROM user_live_sessions


    UNION ALL

    -- 登出点，标记为-1
    SELECT
        user_id,
        room_id,
        COALESCE(unix_timestamp(logout_time), unix_timestamp()) AS time_point,
        -1 AS flag
    FROM user_live_sessions

),
-- 步骤2: 计算每个用户在每个房间的活跃状态
user_room_segments AS (
    SELECT
        user_id,
        room_id,
        time_point,
        -- 计算每个时间点后用户是否仍在线（累计标记值）
        SUM(flag) OVER (
            PARTITION BY user_id, room_id
            ORDER BY time_point
        ) AS active_status,
        -- 获取下一个时间点用于计算区间长度
        LEAD(time_point) OVER (
            PARTITION BY user_id, room_id
            ORDER BY time_point
        ) AS next_time_point
    FROM user_room_time_points
),
-- 步骤3: 计算每个用户在每个房间的有效观看时长
user_room_active_time AS (
    SELECT
        user_id,
        room_id,
        -- 只统计用户在线的时间段
        SUM(
            CASE
                WHEN active_status > 0 AND next_time_point IS NOT NULL
                THEN next_time_point - time_point
                ELSE 0
            END
        ) AS total_active_time
    FROM user_room_segments
    GROUP BY user_id, room_id
),
-- 步骤5: 对用户按观看时长排名
final_results AS (
    select
        user_id,
        room_id,
        total_active_time as online_time,
        rank() over (partition by room_id order by total_active_time desc) as rank_id
    from user_room_active_time
)
-- 步骤6: 获取每个直播间前5名用户
SELECT
    room_id,
    user_id,
    online_time,
    rank_id
FROM final_results
WHERE rank_id <= 5
ORDER BY room_id, rank_id;


-- 方式三
/*
1.时间区间分组：将重叠或相邻的时间区间分到同一组
2.合并区间：针对每组取最早的开始时间和最晚的结束时间
3.计算总时长：将合并后的不重叠区间时长相加
*/
WITH user_live_sessions AS (
    SELECT 101 as room_id, 1001 as user_id, '2023-04-10 18:00:00' as login_time, '2023-04-10 19:30:00' as logout_time UNION ALL
    SELECT 101, 1001, '2023-04-10 20:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 101, 1002, '2023-04-10 18:30:00', '2023-04-10 20:45:00' UNION ALL
    SELECT 101, 1003, '2023-04-10 19:00:00', '2023-04-10 22:00:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 17:30:00', '2023-04-10 18:45:00' UNION ALL
    SELECT 101, 1004, '2023-04-10 19:15:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 101, 1005, '2023-04-10 18:15:00', '2023-04-10 21:45:00' UNION ALL
    SELECT 101, 1006, '2023-04-10 18:45:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 101, 1007, '2023-04-10 19:30:00', '2023-04-10 21:30:00' UNION ALL

    -- 直播间102的用户
    SELECT 102, 1001, '2023-04-10 17:00:00', '2023-04-10 18:00:00' UNION ALL
    SELECT 102, 1002, '2023-04-10 17:30:00', '2023-04-10 19:00:00' UNION ALL
    SELECT 102, 1008, '2023-04-10 18:00:00', '2023-04-10 20:30:00' UNION ALL
    SELECT 102, 1009, '2023-04-10 18:30:00', '2023-04-10 19:15:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 19:00:00', '2023-04-10 21:00:00' UNION ALL
    SELECT 102, 1010, '2023-04-10 21:30:00', '2023-04-10 22:15:00' UNION ALL

    -- 异常记录（登出时间为NULL）
    SELECT 101, 1008, '2023-04-10 19:45:00', cast(NULL as string) UNION ALL
    SELECT 102, 1005, '2023-04-10 20:00:00', cast(NULL as string)
),
    user_session as (
        select
            user_id,
            room_id,
            unix_timestamp(login_time) as start_time,
            coalesce(unix_timestamp(logout_time), unix_timestamp()) as end_time
        from user_live_sessions
    ),
    -- 用户在直播间的之前的最大end_time
    user_prev_max_end_time as (
        select user_id,
               room_id,
               start_time,
               end_time,
               max(end_time) over (partition by user_id, room_id order by start_time rows between unbounded preceding and 1 preceding) as prev_max_end_time
        from user_session
    ),
    -- 用户观看时间区间分组
    user_watch_session_group as (
     select user_id,
            room_id,
            start_time,
            end_time,
            prev_max_end_time,
            sum(case
                when prev_max_end_time is null then 0
                when start_time >= prev_max_end_time then 0
                else 1 end
            ) over(
                partition by user_id, room_id
                order by start_time
                ) group_id
     from user_prev_max_end_time
    ),
    -- 用户观看时间区间分组内统计观看时长
    caulate_watch_group_time as (
     select
         user_id,
         room_id,
         group_id,
         max(end_time) - min(start_time) as group_watch_time
     from user_watch_session_group
     group by user_id,
              room_id,
              group_id
    ),
    caulate_watch_time as (
        select
            user_id,
            room_id,
            sum(group_watch_time) as total_watch_time
        from caulate_watch_group_time
        group by user_id,
                 room_id
    )
select
    room_id,
    user_id,
    total_watch_time online_time,
    rank_id
from (
    select
        *,
        rank() over (partition by room_id order by total_watch_time desc) as rank_id
    from caulate_watch_time
    ) t
where rank_id <= 5
order by room_id, rank_id;

```



## 原创文章的引用次数

> 名为article的表，包含以下两列：
>
> id：文章ID，表示每篇文章的唯一标识符。
> oid：引用的文章ID，表示该文章引用了哪篇文章，oid = 0表示该文章是原创文章。
> 任务：计算原创文章（即oid = 0的文章）被引用的次数，且在Hive SQL查询中不使用JOIN操作。

![image-20250312135431464](https://5201969.xyz/api/public/img/13fbd8e5930a2868f6a396300ef0e1c3)



```sql

-- 找出原创文章的引用次数
-- 使用join的方式
WITH article AS (
    SELECT 1 AS id, 1 AS oid UNION ALL
    SELECT 2, 2 UNION ALL
    SELECT 3, 0 UNION ALL
    SELECT 4, 3 UNION ALL
    SELECT 5, 10 UNION ALL
    SELECT 6, 4 UNION ALL
    SELECT 7, 10 UNION ALL
    SELECT 8, 3 UNION ALL
    SELECT 9, 6 UNION ALL
    SELECT 10, 0
)
select
    t1.id,
    count(1) ref_count
from article t1
left join article t2 on t1.id  = t2.oid
where t1.oid = 0
group by t1.id;


-- 不使用join的方式
WITH article AS (
    SELECT 1 AS id, 1 AS oid UNION ALL
    SELECT 2, 2 UNION ALL
    SELECT 3, 0 UNION ALL
    SELECT 4, 3 UNION ALL
    SELECT 5, 10 UNION ALL
    SELECT 6, 4 UNION ALL
    SELECT 7, 10 UNION ALL
    SELECT 8, 3 UNION ALL
    SELECT 9, 6 UNION ALL
    SELECT 10, 0
),
    mark_ori as (
        select
            id,
            oid,
            collect_set(if(oid = 0 , id, null)) over() origin
        from article
    )
select
    oid,
    sum(if(array_contains(origin, oid), 1, 0)) ref_count
from mark_ori
where oid != 0
group by  oid


```





## 填补缺失值



![image-20250313112707103](https://5201969.xyz/api/public/img/f28bd68b82d116df02f354c2301e1701)



![image-20250313112456728](https://5201969.xyz/api/public/img/3f51801a0ef48623ceb8ad33bf9b0bb8)

```sql

-- 填补缺失值 中间空缺值用紧邻两行非空的均值填充
WITH data AS (
    SELECT 'A' before, DATE'2023-03-01' as `date`, 4230  value UNION ALL
    SELECT 'A', DATE'2023-03-02', 4470  UNION ALL
    SELECT 'A', DATE'2023-03-03', 4520  UNION ALL
    SELECT 'A', DATE'2023-03-04', NULL  UNION ALL
    SELECT 'A', DATE'2023-03-05', NULL  UNION ALL
    SELECT 'A', DATE'2023-03-06', 4430  UNION ALL
    SELECT 'B', DATE'2023-03-01', 4310  UNION ALL
    SELECT 'B', DATE'2023-03-02', 4280  UNION ALL
    SELECT 'B', DATE'2023-03-03', 4470  UNION ALL
    SELECT 'B', DATE'2023-03-04', NULL  UNION ALL
    SELECT 'B', DATE'2023-03-05', NULL  UNION ALL
    SELECT 'B', DATE'2023-03-06', 4310  UNION ALL
    SELECT 'C', DATE'2022-09-27', 4280  UNION ALL
    SELECT 'C', DATE'2022-09-28', 4470  UNION ALL
    SELECT 'C', DATE'2022-09-29', 4280  UNION ALL
    SELECT 'C', DATE'2022-09-30', 4470  UNION ALL
    SELECT 'C', DATE'2022-10-01', NULL  UNION ALL
    SELECT 'C', DATE'2022-10-02', NULL  UNION ALL
    SELECT 'C', DATE'2022-10-03', NULL  UNION ALL
    SELECT 'C', DATE'2022-10-04', NULL  UNION ALL
    SELECT 'C', DATE'2022-10-05', NULL  UNION ALL
    SELECT 'C', DATE'2022-10-06', NULL  UNION ALL
    SELECT 'C', DATE'2022-10-07', NULL  UNION ALL
    SELECT 'C', DATE'2022-10-08', 4480  UNION ALL
    SELECT 'C', DATE'2022-10-09', 4470  UNION ALL
    SELECT 'C', DATE'2022-10-10', 4520
),
    find_near as (
        select before,
               `date`,
               value,
               -- 按"date"排序的数据中,相邻的且不为null的前一个值
               last_value(value,true) over (partition by before order by `date` rows between unbounded preceding and current row) as prev_value,
               -- 按"date"排序的数据中,相邻的且不为null的后一个值
               first_value(value,true) over (partition by before order by `date` rows between current row and unbounded following) as next_value
        from data
    )
select
    before,
    if(value = prev_value and value = next_value
        , value
        , round((prev_value + next_value) / 2)
    ) value
from find_near;

```



## 有条件的连续三次

```sql
/*
表：Stadium
+----------------+---------+
| Column Name    | Type    |
+----------------+---------+
| id             | int     |
| visit_date     | date    |
| people         | int     |
+----------------+---------+

visit_date 是该表中具有唯一值的列。
每条入流量信息被记录在这三列信息中：序号 (id)、日期 (visit_date)、人流量 (people)
每天只有一行记录，日期随着 id 的增加而增加
编写解决方案找出所有人数大于等于 100 且 id 连续的三行或更多行记录。
返回按 visit_date 升序排列的结果表。

查询结果格式如下所示。
示例 1:
输入:
Stadium 表:
+------+------------+-----------+
| id   | visit_date | people    |
+------+------------+-----------+
| 1    | 2017-01-01 | 10        |
| 2    | 2017-01-02 | 109       |
| 3    | 2017-01-03 | 150       |
| 4    | 2017-01-04 | 99        |
| 5    | 2017-01-05 | 145       |
| 6    | 2017-01-06 | 1455      |
| 7    | 2017-01-07 | 199       |
| 8    | 2017-01-09 | 188       |
+------+------------+-----------+
输出:
+------+------------+-----------+
| id   | visit_date | people    |
+------+------------+-----------+
| 5    | 2017-01-05 | 145       |
| 6    | 2017-01-06 | 1455      |
| 7    | 2017-01-07 | 199       |
| 8    | 2017-01-09 | 188       |
+------+------------+-----------+

解释:
id 为 5, 6, 7, 8 的四行 id 连续，并且每行都有 >= 100 的人数记录。
请注意，即使第 7 行和第 8 行的 visit_date 不是连续的，输出也应当包含第 8 行，因为我们只需要考虑 id 连续的记录。
不输出 id 为 2 和 3 的行，因为至少需要三条 id 连续的记录。
*/

-- 等差数列方式
WITH Stadium AS (SELECT 1 AS id, '2017-01-01' AS visit_date, 10 AS people
                 UNION ALL
                 SELECT 2, '2017-01-02', 109
                 UNION ALL
                 SELECT 3, '2017-01-03', 150
                 UNION ALL
                 SELECT 4, '2017-01-04', 99
                 UNION ALL
                 SELECT 5, '2017-01-05', 145
                 UNION ALL
                 SELECT 6, '2017-01-06', 1455
                 UNION ALL
                 SELECT 7, '2017-01-07', 199
                 UNION ALL
                 SELECT 8, '2017-01-09', 188)
select id,
       visit_date,
       people
from (
    select id,
           visit_date,
           people,
           group_id,
           count(*) over (partition by group_id) as countinus_days
    from (
        select id,
               visit_date,
               people,
               id - row_number() over (order by id) as group_id
        from Stadium
        where people >= 100
        ) t1
    ) t2
where countinus_days >= 3
order by visit_date;

-- 标记累加方式
WITH Stadium AS (SELECT 1 AS id, '2017-01-01' AS visit_date, 10 AS people
                 UNION ALL
                 SELECT 2, '2017-01-02', 109
                 UNION ALL
                 SELECT 3, '2017-01-03', 150
                 UNION ALL
                 SELECT 4, '2017-01-04', 99
                 UNION ALL
                 SELECT 5, '2017-01-05', 145
                 UNION ALL
                 SELECT 6, '2017-01-06', 1455
                 UNION ALL
                 SELECT 7, '2017-01-07', 199
                 UNION ALL
                 SELECT 8, '2017-01-09', 188),
    group_ids  as (
            select id,
               visit_date,
               people,
               pre_id,
               sum(
               case
                   when pre_id is null then 0
                   when id - pre_id = 1 then 0
                   else 1
               end
               ) over(order by id) group_id
        from (
            select id,
                   visit_date,
                   people,
                   lag(id) over(order by id) as pre_id
            from Stadium
            where people >= 100
            ) t1
    )
select id,
       visit_date,
       people

from (
    select id,
           visit_date,
           people,
           pre_id,
           group_id,
           count(*) over (partition by group_id) as countinus_days
    from group_ids
    ) t2
where countinus_days >= 3
order by visit_date;


```

![image-20250316150330116](https://5201969.xyz/api/public/img/fda1a2413e167cc13d839411b810e04d)





## 获取满足条件的书籍销量

前置知识：

```sql
-- 日期汇总
/* 
Hive 日期时间函数：各种时间单位"之前"的计算方法

Hive 3.1.3 提供了多种函数来计算不同时间单位之前的日期或时间。以下是按时间单位从小到大的完整列表和示例：

-  秒级操作

-- 30秒前
SELECT from_unixtime(unix_timestamp() - 30)

-- 示例：当前时间的30秒前
SELECT from_unixtime(unix_timestamp('2023-04-15 14:30:45') - 30)
-- 结果：2023-04-15 14:30:15


- 分钟级操作

-- 5分钟前
SELECT from_unixtime(unix_timestamp() - 5*60)

-- 示例：当前时间的5分钟前
SELECT from_unixtime(unix_timestamp('2023-04-15 14:30:45') - 5*60)
-- 结果：2023-04-15 14:25:45


- 小时级操作

-- 3小时前
SELECT from_unixtime(unix_timestamp() - 3*60*60)

-- 示例：当前时间的3小时前
SELECT from_unixtime(unix_timestamp('2023-04-15 14:30:45') - 3*60*60)
-- 结果：2023-04-15 11:30:45


- 天级操作

-- 7天前
SELECT date_sub(current_date(), 7)
-- 或
SELECT date_sub('2023-04-15', 7)
-- 结果：2023-04-08


- 周级操作

-- 2周前
SELECT date_sub(current_date(), 2*7)
-- 或
SELECT date_sub('2023-04-15', 14)
-- 结果：2023-04-01


- 月级操作

-- 3个月前
SELECT add_months(current_date(), -3)
-- 或
SELECT add_months('2023-04-15', -3)
-- 结果：2023-01-15


- 季度级操作

-- 2个季度前
SELECT add_months(current_date(), -2*3)
-- 或
SELECT add_months('2023-04-15', -6)
-- 结果：2022-10-15


- 年级操作

-- 1年前
SELECT add_months(current_date(), -12)
-- 或
SELECT add_months('2023-04-15', -12)
-- 结果：2022-04-15


 特殊函数

- **next_day**：获取下一个指定星期几的日期
  
  -- 获取下一个星期日，星球日(SU)，周六（SA），周五（FR），周四（TH），周三（WE），周二（TU），周一（MO）
周一：Monday
周二：Tuesday
周三：Wednesday
周四：Thursday
周五：Friday
周六：Saturday
周日：Sunday
  SELECT next_day('2023-04-15', 'SU')
  -- 结果：2023-04-16
  

- **last_day**：获取当月最后一天
  
  SELECT last_day('2023-04-15')
  -- 结果：2023-04-30
  

- **trunc**：截断到指定的时间单位
  
  -- 截断到月初
  SELECT trunc('2023-04-15', 'MM')
  -- 结果：2023-04-01

  -- 截断到年初
  SELECT trunc('2023-04-15', 'YY')
  -- 结果：2023-01-01
  */
```

~~~sql
/*
书籍表 Books:
+----------------+-------------+
| Column Name    | Type        |
+----------------+-------------+
| book_id        | int         |
| name           | varchar     |
| available_from | date        |
+----------------+-------------+
book_id 是这个表的主键（只有唯一值的列）。
订单表 Orders:
+----------------+-------------+
| Column Name    | Type        |
+----------------+-------------+
| order_id       | int         |
| book_id        | int         |
| quantity       | int         |
| dispatch_date  | date        |
+----------------+-------------+
order_id 是这个表的主键（只有唯一值的列）。
book_id 是 Books 表的外键（reference 列）。
编写解决方案，筛选出过去一年中订单总量少于 10 本的 书籍，并且 不考虑 上架至今距离今天 不满一个月 的书籍，假设今天是 2019-06-23。
返回结果表 无顺序要求。
结果格式如下所示。
示例 1：
输入：
Books 表：
+---------+-------------------+----------------+
| book_id | name              | available_from |
+---------+-------------------+----------------+
| 1       | "Kalila And Demna"| 2010-01-01     |
| 2       | "28 Letters"      | 2012-05-12     |
| 3       | "The Hobbit"      | 2019-06-10     |
| 4       | "13 Reasons Why"  | 2019-06-01     |
| 5       | "The Hunger Games"| 2008-09-21     |
+---------+-------------------+----------------+
Orders 表：
+---------+----------+----------+---------------+
| order_id| book_id  | quantity | dispatch_date |
+---------+----------+----------+---------------+
| 1       | 1        | 2        | 2018-07-26    |
| 2       | 1        | 2        | 2018-11-05    |
| 3       | 1        | 2        | 2019-05-11    |
| 4       | 3        | 2        | 2019-06-05    |
| 5       | 4        | 6        | 2019-06-05    |
| 6       | 5        | 1        | 2019-02-02    |
| 7       | 5        | 4        | 2010-04-13    |
+---------+----------+----------+---------------+
输出：
+---------+-------------------+
| book_id | name              |
+---------+-------------------+
| 1       | "Kalila And Demna"|
| 2       | "28 Letters"      |
| 5       | "The Hunger Games"|
+---------+-------------------+


*/

-- 模拟 Books 表数据
WITH Books AS (
  SELECT 1 AS book_id, 'Kalila And Demna' AS name, '2010-01-01' AS available_from
  UNION ALL
  SELECT 2, '28 Letters', '2012-05-12'
  UNION ALL
  SELECT 3, 'The Hobbit', '2019-06-10'
  UNION ALL
  SELECT 4, '13 Reasons Why', '2019-06-01'
  UNION ALL
  SELECT 5, 'The Hunger Games', '2008-09-21'
),

-- 模拟 Orders 表数据
Orders AS (
  SELECT 1 AS order_id, 1 AS book_id, 2 AS quantity, '2018-07-26' AS dispatch_date
  UNION ALL
  SELECT 2, 1, 2, '2018-11-05'
  UNION ALL
  SELECT 3, 1, 2, '2019-05-11'
  UNION ALL
  SELECT 4, 3, 2, '2019-06-05'
  UNION ALL
  SELECT 5, 4, 6, '2019-06-05'
  UNION ALL
  SELECT 6, 5, 1, '2019-02-02'
  UNION ALL
  SELECT 7, 5, 4, '2010-04-13'
)

select
    t2.book_id,
    t2.name,
    t2.available_from,
    sum(coalesce(t1.quantity,0)) as total_quantity
from Books t2
left join  Orders t1
on t1.book_id = t2.book_id
where
--     to_date(dispatch_date) between to_date('2018-06-23') and to_date('2019-06-23')
to_date(dispatch_date) >= add_months('2019-06-23' ,-12)
and to_date(t2.available_from) < add_months('2019-06-23',-1)
group by t2.book_id,t2.name,t2.available_from
having sum(coalesce(quantity,0)) < 10;



~~~



##  换座位

```sql
/*
表: Seat

+---------+---------+
| Column Name | Type |
+---------+---------+
| id | int |
| student | varchar |
+---------+---------+
id 是该表的主键（唯一值）列。
该表的每一行都表示学生的姓名和 ID。
ID 排列依然从 1 开始并连续增加。
编写解决方案来交换每两个连续的学生的座位号。如果学生的数量是奇数，则最后一个学生的 id 不交换。
按 id 排序 返回结果表。
查询结果格式如下面示例。
示例 1:
输入:
Seat 表:
+----+---------+
| id | student |
+----+---------+
| 1  | Abbot   |
| 2  | Doris   |
| 3  | Emerson |
| 4  | Green   |
| 5  | Jeames  |
+----+---------+
输出:
+----+---------+
| id | student |
+----+---------+
| 1  | Doris   |
| 2  | Abbot   |
| 3  | Green   |
| 4  | Emerson |
| 5  | Jeames  |
+----+---------+
解释:
请注意，如果学生人数为奇数，则不需要再摸最后一名学生的座位。
*/

/*
方式一
两两交换，可以看作是相邻两组id交换
*/
WITH Seat AS (
    SELECT 1 AS id, 'Abbot' AS student
    UNION ALL
    SELECT 2, 'Doris'
    UNION ALL
    SELECT 3, 'Emerson'
    UNION ALL
    SELECT 4, 'Green'
    UNION ALL
    SELECT 5, 'Jeames'
),
    modified_seat AS (
        select id,
               student,
               mod,
               -- 用于判断是否是最后一个
               lead(id, 1) over(order by id) as next_id,
               -- 用于处理如果学生人数为奇数，则不需要再摸最后一名学生的座位
               count(*) over() total_number
        from (
            select id,
                   student,
                   -- 如果是偶数，-1，奇数，1
                   if(id % 2 = 0, -1, 1) mod
            from Seat t1
             ) t2
    )
select
    id + mod_consider_total_number as id,
    student
from (
    select id,
           student,
           -- 如果是最后一个，且学生总数是奇数，则不需要改变id，mod=0
           if(next_id is null and total_number % 2 = 1, 0,mod) mod_consider_total_number,
           next_id
    from modified_seat
         ) t3
order by id;

/*
方式二
使用lag和lead,直接交换学生姓名
*/
WITH Seat AS (
    SELECT 1 AS id, 'Abbot' AS student
    UNION ALL
    SELECT 2, 'Doris'
    UNION ALL
    SELECT 3, 'Emerson'
    UNION ALL
    SELECT 4, 'Green'
    UNION ALL
    SELECT 5, 'Jeames'
)
select
    id,
    case
        when mod(id, 2) = 0 then lag(student) over(order by id)
        when mod(id, 2) = 1  then coalesce(lead(student) over(order by id),student)
        end student
    from
Seat;
```



## 回答率最高的题目

![image-20250318134736759](https://5201969.xyz/api/public/img/7a959710fff835caa0125ff9870256e1)

~~~sql
/*
整理后的文字如下：

---

**SurveyLog表：**

| Column Name | Type          |
|-------------|---------------|
| id          | int           |
| action      | ENUM          |
| question_id | int           |
| answer_id   | int           |
| q_num       | int           |
| timestamp   | int           |

- 这张表可能包含重复项。
- `action` 是一个 ENUM 类型的数据，可以是 "show"、"answer" 或者 "skip"。
- 这张表的每一行表示：ID=id 的用户对 question_id 的问题在 timestamp 时间进行了 action 操作。
- 如果用户的操作是 "answer"，`answer_id` 将会是对应答案的 ID，否则为 `null`。
- `q_num` 是该问题在当前会话中的数字顺序。
- 回答率是指：同一问题编号中回答次数占显示次数的比率。

编写一个解决方案以报告回答率最高的问题。如果有多个问题具有相同的最大回答率，返回 `question_id` 最小的那个。

**示例1：**

输入：
```
SurveyLog table:
| id | action | question_id | answer_id | q_num | timestamp |
|----|--------|-------------|-----------|-------|-----------|
| 5  | show   | 285         | null      | 1     | 123       |
| 5  | answer | 285         | 124124    | 1     | 124       |
| 5  | show   | 369         | null      | 2     | 125       |
| 5  | skip   | 369         | null      | 2     | 126       |
```

输出：
```
survey_log
| 285 |
```

解释：
- 问题 285 显示 1 次，回答 1 次，回答率为 1.0。
- 问题 369 显示 1 次，回答 0 次，回答率为 0.0。
- 问题 285 回答率最高。

*/

WITH surveyLog AS (
    SELECT 5 AS id, 'show' AS action, 285 AS question_id, NULL AS answer_id, 1 AS q_num, 123 AS `timestamp`
    UNION ALL
    SELECT 5, 'answer', 285, 124124, 1, 124
    UNION ALL
    SELECT 5, 'show', 369, NULL, 2, 125
    UNION ALL
    SELECT 5, 'skip', 369, NULL, 2, 126
)
select question_id,
       show_cnt,
       answer_cnt,
       answer_rate
from (
    select question_id,
           show_cnt,
           answer_cnt,
           answer_rate,
           row_number() over (order by answer_rate desc,question_id asc) as rn
    from (
        select
               question_id,
               sum(if(action = 'show',1,0)) as show_cnt,
               sum(if(action ='answer',1,0)) as answer_cnt,
               sum(if(action ='answer',1,0)) / sum(if(action ='show',1,0)) as answer_rate
        from surveyLog
        group by question_id
        -- 避免分母为0
        having sum(if(action ='show',1,0)) > 0
         ) t1
     ) t2
where rn = 1;

-- 方式二
WITH surveyLog AS (
    SELECT 5 AS id, 'show' AS action, 285 AS question_id, NULL AS answer_id, 1 AS q_num, 123 AS `timestamp`
    UNION ALL
    SELECT 5, 'answer', 285, 124124, 1, 124
    UNION ALL
    SELECT 5, 'show', 369, NULL, 2, 125
    UNION ALL
    SELECT 5, 'skip', 369, NULL, 2, 126
)
SELECT
    question_id,
    SUM(if(action = 'show', 1, 0)) AS show_cnt,
    SUM(if(action = 'answer', 1, 0)) AS answer_cnt,
    SUM(if(action = 'answer', 1, 0)) / SUM(if(action = 'show', 1, 0)) AS answer_rate
FROM surveyLog
GROUP BY question_id
HAVING SUM(if(action ='show', 1, 0)) > 0
ORDER BY answer_rate DESC, question_id ASC
LIMIT 1;


~~~



## 连续登录

```sql

/*
Table: activity

+------------+---------+
| Column Name | Type   |
+------------+---------+
| player_id  | int     |
| device_id  | int     |
| event_date | date    |
| games_played | int   |
+------------+---------+
(player_id, event_date) 是此表的主键（具有唯一值的列组合）。
这张表显示了某些游戏的玩家的活动情况。
每一行是一个玩家的记录，他在某一天使用某个设备注销之前登录并玩了很多游戏（可能是0）。
编写解决方案，报告在首次登录的第二天再次登录的玩家的比率，四舍五入到小数点后两位。换句话说，你需要计
算从首次登录日期开始至少连续两天登录的玩家的数量，然后除以玩家总数。
结果格式如下所示：
输出 1:
输入:
activity table:
+----------+--------+-------------+--------------+
| player_id | device_id | event_date | games_played |
+----------+--------+-------------+--------------+
| 1 | 2 | 2016-03-01 | 5 |
| 1 | 2 | 2016-03-02 | 6 |
| 2 | 3 | 2017-06-25 | 1 |
| 3 | 1 | 2016-03-03 | 0 |
| 3 | 4 | 2018-07-03 | 5 |
+----------+--------+-------------+--------------+
输出:
+-----------+
| fraction  |
+-----------+
| 0.33      |
+-----------+
解释：
因为 ID 为 1 的玩家在第一天登录后才重新登录，所以答案是 1/3 = 0.33

*/

WITH activity AS (
    SELECT 1 AS player_id, 2 AS device_id, '2016-03-01' AS event_date, 5 AS games_played
    UNION ALL
    SELECT 1, 2, '2016-03-02', 6
    UNION ALL
    SELECT 2, 3, '2017-06-25', 1
    UNION ALL
    SELECT 3, 1, '2016-03-03', 0
    UNION ALL
    SELECT 3, 4, '2018-07-03', 5
),
    continue_login AS (
        select player_id,
               device_id,
               to_date(event_date) event_date,
               games_played,
               date_sub(to_date(event_date),row_number() over (partition by player_id order by event_date)) AS group_date,
               min(to_date(event_date)) over () AS first_date
        from activity
    ),
    three_days_events as (
        select
            1 flag,
            count(1) event_count
        from continue_login
        where event_date >= first_date and event_date <= date_add(first_date,2)
    ),
    continue_events_2timsover as (
        select
            count(distinct player_id) distinct_player_count,
            1 flag
        from (
            select
                player_id,
                count(1) event_continus_count
            from continue_login
            where event_date >= first_date and event_date <= date_add(first_date,2)
            group by player_id,group_date
            having count(1) >= 2
             ) t1
    )
select
    t2.distinct_player_count / t1.event_count fraction
from three_days_events t1
join continue_events_2timsover t2
on t1.flag = t2.flag;




```

![image-20250318143233110](https://5201969.xyz/api/public/img/11da92120b998a7195af21c41b53bdf0)





## 顾客订单分析

```sql

/*

 顾客订单分析

 数据表结构

 Customers 表
sql
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| customer_id | int     |
| name        | varchar |
+-------------+---------+

- `customer_id` 是该表的唯一标识列。
- 该表包含所有顾客的信息。

 Orders 表
sql
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| order_id    | int     |
| order_date  | date    |
| customer_id | int     |
| product_id  | int     |
+-------------+---------+

- `order_id` 是该表的唯一标识列。
- 该表包含每个 `customer_id` 的订单信息。
- 没有顾客会在一天内订购相同的商品多于一次

 Products 表
sql
+--------------+-------------+
| Column Name  | Type        |
+--------------+-------------+
| product_id   | int         |
| product_name | varchar     |
| price        | int         |
+--------------+-------------+

- `product_id` 是该表的唯一标识列。
- 该表包含所有商品的信息。
- 目标是找到每个顾客最常购买的商品。

---

 查询需求
-写一个解决方案，找到每一个顾客最经常订购的商品。
结果表单应该有每一位至少下过一次单的顾客customer_id，他最经常订购的商品的product_id 和
product_name.
---

 示例数据

 Customers 表
sql
+-------------+------+
| customer_id | name |
+-------------+------+
| 1           | Alice  |
| 2           | Bob    |
| 3           | Jerry  |
| 4           | Tom    |
| 5           | John   |
+-------------+------+


 Orders 表
sql
+----------+------------+-------------+-----------+
| order_id | order_date | customer_id | product_id |
+----------+------------+-------------+-----------+
| 1        | 2020-07-31 | 1           | 2         |
| 2        | 2020-07-31 | 1           | 1         |
| 3        | 2020-08-01 | 2           | 2         |
| 4        | 2020-08-01 | 2           | 2         |
| 5        | 2020-08-01 | 3           | 3         |
| 6        | 2020-08-01 | 3           | 3         |
| 7        | 2020-08-01 | 3           | 3         |
| 8        | 2020-08-07 | 2           | 3         |
| 9        | 2020-08-07 | 2           | 2         |
| 10       | 2020-08-15 | 1           | 2         |
+----------+------------+-------------+-----------+


 Products 表
sql
+------------+--------------+-------+
| product_id | product_name | price |
+------------+--------------+-------+
| 1          | keyboard     | 120   |
| 2          | mouse        | 80    |
| 3          | screen       | 600   |
| 4          | hard disk    | 450   |
+------------+--------------+-------+


---

这是一个查询结果输出和解释说明，我来格式化一下内容：

customer_id | product_id | product_name
1 | 2 | mouse
2 | 1 | keyboard
2 | 2 | mouse
2 | 3 | screen
3 | 3 | screen
4 | 1 | keyboard


解释：
1. Alice (customer 1) 三次订购商品，一次订购鼠标，所以显示是 Alice 最经常订购的商品。
2. Bob (customer 2) 一次订购键盘，一次订购鼠标，一次订购显示器，所以这些都是 Bob 最经常订购的商品。
3. Tom (customer 3) 只购买订购显示器，所以显示器是 Tom 最经常订购的商品。
4. Jerry (customer 4) 只一次订购键盘，所以键盘是 Jerry 最经常订购的商品。
5. John (customer 5) 没有订购过商品，所以数据中没有把 John 包含在输出结果中。

*/

WITH Customers AS (
    SELECT 1 AS customer_id, 'Alice' AS name
    UNION ALL
    SELECT 2, 'Bob'
    UNION ALL
    SELECT 3, 'Jerry'
    UNION ALL
    SELECT 4, 'Tom'
    UNION ALL
    SELECT 5, 'John'
),
Orders AS (
    SELECT 1 AS order_id, '2020-07-31' AS order_date, 1 AS customer_id, 2 AS product_id
    UNION ALL
    SELECT 2, '2020-07-31', 1, 1
    UNION ALL
    SELECT 3, '2020-08-01', 2, 2
    UNION ALL
    SELECT 4, '2020-08-01', 2, 2
    UNION ALL
    SELECT 5, '2020-08-01', 3, 3
    UNION ALL
    SELECT 6, '2020-08-01', 3, 3
    UNION ALL
    SELECT 7, '2020-08-01', 3, 3
    UNION ALL
    SELECT 8, '2020-08-07', 2, 3
    UNION ALL
    SELECT 9, '2020-08-07', 2, 2
    UNION ALL
    SELECT 10, '2020-08-15', 1, 2
),
Products AS (
    SELECT 1 AS product_id, 'keyboard' AS product_name, 120 AS price
    UNION ALL
    SELECT 2, 'mouse', 80
    UNION ALL
    SELECT 3, 'screen', 600
    UNION ALL
    SELECT 4, 'hard disk', 450
),
    purchase AS (
        select customer_id,
               product_id,
               pruchase_times,
               rank() over (partition by customer_id order by pruchase_times desc) as rk
        from (
            select
                t1.customer_id,
                t1.product_id,
                count(1)  pruchase_times
            from Orders t1
            group by t1.customer_id, t1.product_id
             ) t2
    )
select
    t1.customer_id,
    t1.product_id,
    t2.product_name
from purchase t1
left join Products t2
on t1.product_id = t2.product_id
where t1.rk = 1
;

-- 方式二，简化方式一写法
WITH Customers AS (
    SELECT 1 AS customer_id, 'Alice' AS name
    UNION ALL
    SELECT 2, 'Bob'
    UNION ALL
    SELECT 3, 'Jerry'
    UNION ALL
    SELECT 4, 'Tom'
    UNION ALL
    SELECT 5, 'John'
),
Orders AS (
    SELECT 1 AS order_id, '2020-07-31' AS order_date, 1 AS customer_id, 2 AS product_id
    UNION ALL
    SELECT 2, '2020-07-31', 1, 1
    UNION ALL
    SELECT 3, '2020-08-01', 2, 2
    UNION ALL
    SELECT 4, '2020-08-01', 2, 2
    UNION ALL
    SELECT 5, '2020-08-01', 3, 3
    UNION ALL
    SELECT 6, '2020-08-01', 3, 3
    UNION ALL
    SELECT 7, '2020-08-01', 3, 3
    UNION ALL
    SELECT 8, '2020-08-07', 2, 3
    UNION ALL
    SELECT 9, '2020-08-07', 2, 2
    UNION ALL
    SELECT 10, '2020-08-15', 1, 2
),
Products AS (
    SELECT 1 AS product_id, 'keyboard' AS product_name, 120 AS price
    UNION ALL
    SELECT 2, 'mouse', 80
    UNION ALL
    SELECT 3, 'screen', 600
    UNION ALL
    SELECT 4, 'hard disk', 450
)
select
    t1.customer_id,
    t1.product_id,
    t2.product_name
from (
    select
        t1.customer_id,
        t1.product_id,
        rank() over(partition by t1.customer_id order by count(product_id) desc) as rk
    from Orders t1
    group by t1.customer_id, t1.product_id

     ) t1
left join Products t2
on t1.product_id = t2.product_id
where t1.rk = 1
;
```



![image-20250319143243974](https://5201969.xyz/api/public/img/22db0645914444f536a7ed8fad43b8f2)

> 知识点：分组后使用窗口函数，窗口函数的粒度不能是除了分组字段外的其他字段。
> ```sql
> select
>         t1.customer_id,
>         t1.product_id,
>         rank() over(partition by t1.customer_id order by count(product_id) desc) as rk
>     from Orders t1
>     group by t1.customer_id, t1.product_id
> 
> ```
>
> 



## 户额度信息（进出的问题，直播在线人数，订单的过程数，订单的总额)

> 类似问题：往往有随着某个维度进和出的概念，只要分别处理进和出，一般是累计求和效果（sum() over(order by dim_col)）

```sql
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
```

![image-20250320102241220](https://5201969.xyz/api/public/img/3ac7f6d8208d262519cd113a9fdc1a47)



## 商品最新订单



~~~sql
/*

题目50 商品最新订单

**Customers**

| Column Name | Type     |
|-------------|----------|
| customer_id | int      |
| customer_name| varchar  |

* customer_id 是该表的主键。
* 该表包含顾客的 ID 和姓名。

**Orders**

| Column Name | Type     |
|-------------|----------|
| order_id    | int      |
| order_date  | date     |
| customer_id | int      |
| product_id  | int      |

* order_id 是该表的主键。
* 该表包含顾客的订单信息。
* customer_id 是 Customers 表的外键。
* product_id 是 Products 表的外键。

**Products**

| Column Name | Type     |
|-------------|----------|
| product_id  | int      |
| product_name| varchar  |
| price       | int      |

* product_id 是该表的主键。
* 该表包含产品信息。

编写一个 SQL 查询，查找每个产品的最新订单的顾客 ID 和顾客姓名。
“最新”订单定义为具有最大 `order_date` 的订单。
如果两个或多个产品具有相同的最大 `order_date`，则考虑具有最大 `order_id` 的订单。
以任何顺序返回结果表。

查询结果格式如下例所示。

**示例 1**

**输入：**
**Customers 表：**
| customer_id | customer_name |
|-------------|---------------|
| 1           | Winston       |
| 2           | Jonathan      |
| 3           | Annabelle     |
| 4           | Marwan        |

**Orders 表：**
| order_id | order_date | customer_id | product_id |
|----------|------------|-------------|------------|
| 1        | 2020-07-31 | 1           | 1          |
| 2        | 2020-07-01 | 2           | 2          |
| 3        | 2020-08-30 | 4           | 3          |
| 4        | 2020-09-30 | 3           | 1          |
| 5        | 2020-08-03 | 3           | 2          |
| 6        | 2020-10-25 | 1           | 3          |
| 7        | 2020-12-15 | 1           | 2          |
| 8        | 2020-01-20 | 1           | 3          |
| 9        | 2020-03-03 | 3           | 3          |
| 10       | 2020-07-27 | 4           | 1          |
| 11       | 2020-08-01 | 2           | 1          |

**Products 表：**
| product_id | product_name | price |
|------------|--------------|-------|
| 1          | keyboard     | 120   |
| 2          | mouse        | 80    |
| 3          | hard disk    | 180   |

**输出：**
| product_name | product_id | order_id | order_date | customer_id | customer_name |
|--------------|------------|----------|------------|-------------|---------------|
| keyboard     | 1          | 4        | 2020-09-30 | 3           | Annabelle     |
| mouse        | 2          | 7        | 2020-12-15 | 1           | Winston       |
| hard disk    | 3          | 6        | 2020-10-25 | 1           | Winston       |

**解释：**
* keyboard 的最新订单是 2020-09-30 下的订单。
* mouse 的最新订单是 2020-12-15 下的订单。
* hard disk 的最新订单是 2020-10-25 下的订单。

**SQL:**
```sql
SELECT
    product_name,
    Products.product_id,
    order_id,
    order_date,
    Customers.customer_id,
    customer_name
FROM Products
JOIN Orders USING(product_id)
JOIN Customers USING(customer_id)
WHERE (product_id, order_date) IN (
    SELECT product_id, MAX(order_date)
    FROM Orders
    GROUP BY product_id
)
ORDER BY
    product_name,
    order_id;*/


WITH Customers AS (
    SELECT 1 AS customer_id, 'Winston' AS customer_name
    UNION ALL
    SELECT 2, 'Jonathan'
    UNION ALL
    SELECT 3, 'Annabelle'
    UNION ALL
    SELECT 4, 'Marwan'
),
Orders AS (
    SELECT 1 AS order_id, '2020-07-31' AS order_date, 1 AS customer_id, 1 AS product_id
    UNION ALL
    SELECT 2, '2020-07-01', 2, 2
    UNION ALL
    SELECT 3, '2020-08-30', 4, 3
    UNION ALL
    SELECT 4, '2020-09-30', 3, 1
    UNION ALL
    SELECT 5, '2020-08-03', 3, 2
    UNION ALL
    SELECT 6, '2020-10-25', 1, 3
    UNION ALL
    SELECT 7, '2020-12-15', 1, 2
    UNION ALL
    SELECT 8, '2020-01-20', 1, 3
    UNION ALL
    SELECT 9, '2020-03-03', 3, 3
    UNION ALL
    SELECT 10, '2020-07-27', 4, 1
    UNION ALL
    SELECT 11, '2020-08-01', 2, 1
),
Products AS (
    SELECT 1 AS product_id, 'keyboard' AS product_name, 120 AS price
    UNION ALL
    SELECT 2, 'mouse', 80
    UNION ALL
    SELECT 3, 'hard disk', 180
),
    lasted_order AS (
        select order_id,
               order_date,
               customer_id,
               product_id
        from (
            select order_id,
               order_date,
               customer_id,
               product_id,
               row_number() over (partition by product_id order by order_date desc, order_id desc) as rn
        from Orders t1
             ) t2
        where rn = 1
            )
select t1.product_id,
       t1.product_name,
       -- 可能product就没有订单，所以这里需要使用coalesce
       coalesce(t2.order_id,null) order_id,
       coalesce(t2.order_date,null) order_date,
       coalesce(t2.customer_id,null) customer_id,
       coalesce(t3.customer_name,null) customer_name
from Products t1
left join lasted_order t2
on t1.product_id = t2.product_id
left join Customers t3
on t2.customer_id = t3.customer_id;
~~~

![image-20250320102906672](https://5201969.xyz/api/public/img/5e575dc2f36fa021faa94f0fd8984149)





## 推荐画像



```sql

/*
-- Customers 表
CREATE TABLE Customers (
    customer_id INT,
    customer_name VARCHAR(255)
);

-- Orders 表
CREATE TABLE Orders (
    order_id INT,
    customer_id INT,
    product_name VARCHAR(255)
);
order_id 是这张表中具有唯一值的列。
customer_id 是购买了名为“product_name"产品顾客的id。
请你编写解决方案，报告购买了产品"A"，"B"但没有购买产品"c"的客户的customer_id和
customer_name，因为我们想推荐他们购买这样的产品。
返回按customer_id 排序的结果表。
返回结果格式如下所示。
示例1:
输入：
-- 插入 Customers 表数据
INSERT INTO Customers (customer_id, customer_name) VALUES
(1, 'Daniel'),
(2, 'Diana'),
(3, 'Elizabeth'),
(4, 'John');

-- 插入 Orders 表数据
INSERT INTO Orders (order_id, customer_id, product_name) VALUES
(10, 1, 'A'),
(20, 1, 'B'),
(30, 2, 'C'),
(40, 3, 'A'),
(50, 3, 'C'),
(60, 3, 'D'),
(70, 4, 'B'),
(80, 4, 'E');

输出：
| customer_id | customer_name
|3 |Elizabeth |
解释：
只有customer_id为3的顾客购买了产品A和产品B，却没有购买产品C

-- 查询购买了产品 "A" 和 "C" 的客户的 customer_id 和 customer_name
*/

-- 使用array_contains函数处理
WITH Customers AS (
    SELECT 1 AS customer_id, 'Daniel' AS customer_name
    UNION ALL
    SELECT 2, 'Diana'
    UNION ALL
    SELECT 3, 'Elizabeth'
    UNION ALL
    SELECT 4, 'John'
),
Orders AS (
    SELECT 10 AS order_id, 1 AS customer_id, 'A' AS product_name
    UNION ALL
    SELECT 20, 1, 'B'
    UNION ALL
    SELECT 30, 2, 'C'
    UNION ALL
    SELECT 40, 3, 'A'
    UNION ALL
    SELECT 50, 3, 'C'
    UNION ALL
    SELECT 60, 3, 'D'
    UNION ALL
    SELECT 70, 4, 'B'
    UNION ALL
    SELECT 80, 4, 'E'
)
select
    t3.customer_id,
    t4.customer_name
from (
    select
        customer_id
    from (
        select
            t1.customer_id,
            collect_set(product_name) as product_names
        from Orders t1
        group by t1.customer_id
         ) t2
    where array_contains(product_names, 'A')
    and array_contains(product_names, 'B')
    and not array_contains(product_names, 'C')
     ) t3
left join Customers t4
on t3.customer_id = t4.customer_id;

```

![image-20250321133207618](https://5201969.xyz/api/public/img/19751b4e35fea1933ae8aa42be4858c0)





## 工资缴税



```sql
/*

1. Salaries 表：

| Column Name   | Type    |
|---------------|---------|
| company_id    | int     |
| employee_id   | int     |
| employee_name | varchar |
| salary        | int     |

2. 描述：

* 在 SQL 中，(company_id, employee_id) 是该表的主键。
* 该表包含员工的 company_id, id, name 和 salary。
* 编写一个 SQL 查询来查找每个员工的税后工资。

3. 税率规则：

* 如果公司员工最高工资 < $1000，税率为 0%。
* 如果公司员工最高工资在 [$1000, $10000] 之间，税率为 24%。
* 如果公司员工最高工资 > $10000，税率为 49%。

4. 返回结果：

* 按任意顺序返回结果。
* 返回结果格式如下例所示。

5. 示例：

输入：

Salaries 表

| company_id | employee_id | employee_name | salary |
|------------|-------------|---------------|--------|
| 1          | 1           | Tony          | 2000   |
| 1          | 2           | Pranub        | 21300  |
| 1          | 3           | Tyrrox        | 10800  |
| 2          | 1           | Pam           | 300    |
| 2          | 7           | Bassen        | 450    |
| 2          | 9           | Hermione      | 700    |
| 3          | 7           | Bocaben       | 100    |
| 3          | 2           | Ognjen        | 2200   |
| 3          | 13          | Nyancat       | 3300   |
| 3          | 15          | Morninngcat    | 7777   |

输出：

| company_id | employee_id | employee_name | salary |
|------------|-------------|---------------|--------|
| 1          | 1           | Tony          | 1020   |
| 1          | 2           | Pranub        | 10863  |
| 1          | 3           | Tyrrox        | 5508   |
| 2          | 1           | Pam           | 300    |
| 2          | 7           | Bassen        | 450    |
| 2          | 9           | Hermione      | 700    |
| 3          | 7           | Bocaben       | 76     |
| 3          | 2           | Ognjen        | 1672   |
| 3          | 13          | Nyancat       | 2508   |
| 3          | 15          | Morninngcat    | 5911   |

6. 解释：

* 公司 1 最高薪资为 21300，员工税率为 49%。
* 公司 2 最高薪资为 700，员工税率为 0%。
* 公司 3 最高薪资为 7777，员工税率为 24%。
* 税后薪资计算公式：薪资 - (税率 / 100) * 薪资。
* 例如，Morninngcat (员工编号 3, 薪资 7777) 税后薪资为：7777 - (24 / 100) * 7777 = 5911 (四舍五入)。
*/
WITH Salaries AS (
    SELECT 1 AS company_id, 1 AS employee_id, 'Tony' AS employee_name, 2000 AS salary
    UNION ALL
    SELECT 1, 2, 'Pranub', 21300
    UNION ALL
    SELECT 1, 3, 'Tyrrox', 10800
    UNION ALL
    SELECT 2, 1, 'Pam', 300
    UNION ALL
    SELECT 2, 7, 'Bassen', 450
    UNION ALL
    SELECT 2, 9, 'Hermione', 700
    UNION ALL
    SELECT 3, 7, 'Bocaben', 100
    UNION ALL
    SELECT 3, 2, 'Ognjen', 2200
    UNION ALL
    SELECT 3, 13, 'Nyancat', 3300
    UNION ALL
    SELECT 3, 15, 'Morninngcat', 7777
),
    company_tax as (
        select
            company_id,
            case
                when max(salary) < 1000 then 1
                when max(salary) >= 1000 and max(salary) <= 10000 then 1 - 0.24
                else 1 - 0.49
            end as tax
        from Salaries
        group by company_id
    )
select
    t1.company_id,
    employee_id,
    employee_name,
    round(salary * tax, 0) as salary
from Salaries t1
left join company_tax t2
on t1.company_id = t2.company_id;



```

![image-20250321135054525](https://5201969.xyz/api/public/img/8ca4fd68613e000b2b1aef21da7a0ded)



## 顾客乘坐大巴

```sql
/*
 题目 46 乘客乘坐巴士

**Queue 表**

| Column Name | Type     |
|-------------|----------|
| person_id   | int      |
| person_name | varchar  |
| weight      | int      |
| turn        | int      |

* `person_id` 是这个表具有唯一值的列。
* 该表展示了所有候车乘客的信息。
* 表中 `person_id` 和 `turn` 列均包含从 1 到 n 的所有数字，其中 n 是表中的行数。
* `turn` 决定了候车乘客上巴士的顺序，其中 `turn=1` 表示第一个上巴士，`turn=n` 表示最后一个上巴士。
* `weight` 表示候车乘客的体重，以千克为单位。
* 有一队乘客在等着上巴士。然而，巴士有 1000 千克的重量限制，所以其中一部分乘客可能无法上巴士。
* 编写解决方案找出最后一个上巴士且不超过重量限制的乘客，并报告 `person_name`。题目测试用例确保顺位第一的人可以上巴士且不会超重。
* 返回结果格式如下所示。

**示例 1：**

**输入：**

**Queue 表**

| person_id | person_name | weight | turn |
|-----------|-------------|--------|------|
| 5         | Alice       | 250    | 1    |
| 4         | Bob         | 175    | 5    |
| 3         | Alex        | 350    | 2    |
| 6         | John Cena   | 400    | 3    |
| 1         | Winston     | 500    | 6    |
| 2         | Marie       | 200    | 4    |

**输出：**

| person_name |
|-------------|
| John Cena   |

**解释：**

为了简化，Queue 表按 turn 列由小到大排序。

| Turn | ID | Name      | Weight | Total weight |
|------|----|-----------|--------|--------------|
| 1    | 5  | Alice     | 250    | 250          |
| 2    | 3  | Alex      | 350    | 600          |
| 3    | 6  | John Cena | 400    | 1000         | (最后一个上巴士)
| 4    | 2  | Marie     | 200    | 1200         | (无法上巴士)
| 5    | 4  | Bob       | 175    | -            |
| 6    | 1  | Winston     | 500    | -            |

*/
WITH Queue AS (
    SELECT 5 AS person_id, 'Alice' AS person_name, 250 AS weight, 1 AS turn
    UNION ALL
    SELECT 4, 'Bob', 175, 5
    UNION ALL
    SELECT 3, 'Alex', 350, 2
    UNION ALL
    SELECT 6, 'John Cena', 400, 3
    UNION ALL
    SELECT 1, 'Winston', 500, 6
    UNION ALL
    SELECT 2, 'Marie', 200, 4
)
select
    distinct last_value(person_name) over() as last_person_name
from (
    select person_id,
           person_name,
           weight,
           turn,
           sum(weight) over(order by turn) as total_weight,
           if(sum(weight) over(order by turn) > 1000, 1, 0) as is_over
    from Queue t1
     ) t2
where is_over = 0;

WITH Queue AS (
    SELECT 5 AS person_id, 'Alice' AS person_name, 250 AS weight, 1 AS turn
    UNION ALL
    SELECT 4, 'Bob', 175, 5
    UNION ALL
    SELECT 3, 'Alex', 350, 2
    UNION ALL
    SELECT 6, 'John Cena', 400, 3
    UNION ALL
    SELECT 1, 'Winston', 500, 6
    UNION ALL
    SELECT 2, 'Marie', 200, 4
),
 running_weights AS (
  SELECT
    person_id,
    person_name,
    weight,
    turn,
    SUM(weight) OVER (ORDER BY turn) AS cum_weight
  FROM Queue
)
SELECT person_name
FROM running_weights
WHERE turn = (
  SELECT MAX(turn)
  FROM running_weights
  WHERE cum_weight <= 1000
);

```



## 发票信息



~~~sql
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

~~~



## 降水量

> LEAST 函数返回所有输入表达式中的最小值。该函数可以接受两个或多个参数，并在它们之间进行比较，找出最小的一个。

~~~sql
/*
 题目44 降水量

 表: Heights
| Column Name | Type |
| ----------- | ---- |
| id | int |
| height | int |

id 是这张表的主键 (值互不相同的列)，并且这个表有序。
这张表的每一行都包含 id 和 height。
一个地势图由多个连续高度的岛屿组成 沙洲之间 可以捕捉的雨水量。以卡方行列的形 变是为 1 个单位。
以 任何 顺序返回结果表。
结果格式如下所示。

 Example 1:

 输入:
Heights table:
| id | height |
| -- | ------ |
| 1 | 0 |
| 2 | 1 |
| 3 | 0 |
| 4 | 2 |
| 5 | 1 |
| 6 | 0 |
| 7 | 1 |
| 8 | 3 |
| 9 | 2 |
| 10 | 1 |
| 11 | 2 |
| 12 | 1 |

 输出:
| total_trapped_water |
| ------------------ |
| 6 |

```sql
WITH Heights AS (
  SELECT 1 AS id, 0 AS height UNION ALL
  SELECT 2, 1 UNION ALL
  SELECT 3, 0 UNION ALL
  SELECT 4, 2 UNION ALL
  SELECT 5, 1 UNION ALL
  SELECT 6, 0 UNION ALL
  SELECT 7, 1 UNION ALL
  SELECT 8, 3 UNION ALL
  SELECT 9, 2 UNION ALL
  SELECT 10, 1 UNION ALL
  SELECT 11, 2 UNION ALL
  SELECT 12, 1
)
```*/

// 水会填充到左右两边最高点中较低的那个高度 LEAST(left_max, right_max)
// 减去当前高度 - 因为已被地形占据的部分不能储水。least(left_max,right_max) - height)
// sum(if(,0,))：如果计算结果为负，则该位置不能蓄水，返回0
WITH Heights AS (
  SELECT 1 AS id, 0 AS height UNION ALL
  SELECT 2, 1 UNION ALL
  SELECT 3, 0 UNION ALL
  SELECT 4, 2 UNION ALL
  SELECT 5, 1 UNION ALL
  SELECT 6, 0 UNION ALL
  SELECT 7, 1 UNION ALL
  SELECT 8, 3 UNION ALL
  SELECT 9, 2 UNION ALL
  SELECT 10, 1 UNION ALL
  SELECT 11, 2 UNION ALL
  SELECT 12, 1
)
select
    -- LEAST 函数返回所有输入表达式中的最小值。该函数可以接受两个或多个参数，并在它们之间进行比较，找出最小的一个。
    sum(if(least(left_max,right_max) - height < 0, 0,least(left_max,right_max) - height)) total_trapped_water
from (
select id,
       height,
       coalesce(max(height) over(order by id rows between unbounded preceding and 1 preceding),0) left_max,
       coalesce(max(height) over(order by id rows between 1 following and unbounded following ),0) right_max
from Heights
     ) t1;

/*
位置 1 (height=0)：左侧没有柱子，所以左侧最大高度是0；右侧最大高度是3；较小值为0；0-0=0，不能捕获水。
位置 2 (height=1)：左侧最大高度是0；右侧最大高度是3；较小值为0；0-1=-1，不能捕获水。
位置 3 (height=0)：左侧最大高度是1；右侧最大高度是3；较小值为1；1-0=1，能捕获1单位的水。
位置 4 (height=2)：左侧最大高度是1；右侧最大高度是3；较小值为1；1-2=-1，不能捕获水。
位置 5 (height=1)：左侧最大高度是2；右侧最大高度是3；较小值为2；2-1=1，能捕获1单位的水。
位置 6 (height=0)：左侧最大高度是2；右侧最大高度是3；较小值为2；2-0=2，能捕获2单位的水。
位置 7 (height=1)：左侧最大高度是2；右侧最大高度是3；较小值为2；2-1=1，能捕获1单位的水。
位置 8 (height=3)：左侧最大高度是2；右侧最大高度是2；较小值为2；2-3=-1，不能捕获水。
位置 9 (height=2)：左侧最大高度是3；右侧最大高度是2；较小值为2；2-2=0，不能捕获水。
位置 10 (height=1)：左侧最大高度是3；右侧最大高度是2；较小值为2；2-1=1，能捕获1单位的水。
位置 11 (height=2)：左侧最大高度是3；右侧最大高度是1；较小值为1；1-2=-1，不能捕获水。
位置 12 (height=1)：左侧最大高度是3；右侧没有柱子，所以右侧最大高度是0；较小值为0；0-1=-1，不能捕获水。
*/

~~~

![image-20250323101746807](https://5201969.xyz/api/public/img/b767b76d987f26e945d48f45217268a6)



## 连续会话(标记累计求和分组)

> 日期格式化符号
>
> 年份相关
> y/Y - 年
> yy/YY - 两位年份 (23)
> yyyy/YYYY - 四位年份 (2023)
>
> 月份相关
> M - 月 (1-12)
> MM - 两位月份 (01-12)
> MMM - 月份简写 (Jan, Feb)
> MMMM - 月份全称 (January, February)
>
> 日期相关
> d - 日 (1-31)
> dd - 两位日期 (01-31)
> D - 一年中的第几天 (1-366)
> DDD - 三位数的一年中第几天 (001-366)
>
> 周相关
> E/EE - 星期简写 (Mon, Tue)
> EEEE - 星期全称 (Monday, Tuesday)
> w - 一年中的第几周
> W - 一个月中的第几周
>
> 小时相关
> H - 24小时制 (0-23)
> HH - 两位24小时制 (00-23)
> h - 12小时制 (1-12)
> hh - 两位12小时制 (01-12)
>
> 分钟相关
> m - 分钟 (0-59)
> mm - 两位分钟 (00-59)
>
> 秒相关
> s - 秒 (0-59)
> ss - 两位秒 (00-59)
> S - 毫秒
>
> 上午/下午
> a - AM/PM 标识
>
> 时区相关
> z - 时区名称
> Z - GMT时差

```sql
/*
 题目43 连续会话

 SQL
 Sessions
| Column Name | Type |
| ----------- | ---- |
| user_id | int |
| session_start | datetime |
| session_end | datetime |
| session_id | int |
| session_type | enum |

session_id 是这张表中各不相同的列。
session_type 是 (Viewer, Streamer) 的一个 ENUM (category) 类型。
这张表包含 user_id, session_start, session_end, session_id 和 session 类型。
编写一个解决方案，以查找至少有一个相同类型的连续会话（无论是"viewer"还是"streamer"）的用户，会
话 之间 的 最大 间隔为 12 小时。
返回结果表，以 user_id 升序 排序。
结果格式如下所示。

 示例：
 输入：
Sessions 表:
| user_id | session_start | session_end | session_id | session_type |
| ------- | ------------- | ----------- | ---------- | ------------ |
| 101 | 2023-11-01 08:00:00 | 2023-11-01 09:00:00 | 1 | Viewer |
| 101 | 2023-11-01 10:00:00 | 2023-11-01 11:00:00 | 2 | Streamer |
| 102 | 2023-11-01 13:00:00 | 2023-11-01 14:00:00 | 3 | Viewer |
| 102 | 2023-11-01 15:00:00 | 2023-11-01 16:00:00 | 4 | Viewer |
| 101 | 2023-11-02 07:00:00 | 2023-11-02 08:00:00 | 5 | Viewer |
| 102 | 2023-11-02 12:00:00 | 2023-11-02 13:00:00 | 6 | Streamer |
| 101 | 2023-11-02 13:00:00 | 2023-11-02 14:00:00 | 7 | Streamer |
| 102 | 2023-11-02 16:00:00 | 2023-11-02 17:00:00 | 8 | Viewer |
| 103 | 2023-11-01 08:00:00 | 2023-11-01 09:00:00 | 9 | Viewer |
| 103 | 2023-11-02 20:00:00 | 2023-11-02 23:00:00 | 10 | Viewer |
| 103 | 2023-11-03 09:00:00 | 2023-11-03 10:00:00 | 11 | Viewer |

 输出：
| user_id |
| ------- |
| 102 |
| 103 |

 解释：
- 用户 ID 101 将不会包含在最终输出中，因为他们没有相同类型的连续会话。
- 用户 ID 102 将会包含在最终输出中，因为他们分别有两个 session ID 为 3 和 4 的 viewer 会话，并且时间间隔在 12 小时内。
- 用户 ID 103 参与了两次 viewer 会话，间隔不到 12 小时，会话 ID 为 10 和 11，因此，用户 103 将会被包含在最终输出中。
输出按照表格 user_id 升序排列。



*/

WITH Sessions AS (
  SELECT 101 AS user_id, '2023-11-01 08:00:00' AS session_start, '2023-11-01 09:00:00' AS session_end, 1 AS session_id, 'Viewer' AS session_type UNION ALL
  SELECT 101, '2023-11-01 10:00:00', '2023-11-01 11:00:00', 2, 'Streamer' UNION ALL
  SELECT 102, '2023-11-01 13:00:00', '2023-11-01 14:00:00', 3, 'Viewer' UNION ALL
  SELECT 102, '2023-11-01 15:00:00', '2023-11-01 16:00:00', 4, 'Viewer' UNION ALL
  SELECT 101, '2023-11-02 07:00:00', '2023-11-02 08:00:00', 5, 'Viewer' UNION ALL
  SELECT 102, '2023-11-02 12:00:00', '2023-11-02 13:00:00', 6, 'Streamer' UNION ALL
  SELECT 101, '2023-11-02 13:00:00', '2023-11-02 14:00:00', 7, 'Streamer' UNION ALL
  SELECT 102, '2023-11-02 16:00:00', '2023-11-02 17:00:00', 8, 'Viewer' UNION ALL
  SELECT 103, '2023-11-01 08:00:00', '2023-11-01 09:00:00', 9, 'Viewer' UNION ALL
  SELECT 103, '2023-11-02 20:00:00', '2023-11-02 23:00:00', 10, 'Viewer' UNION ALL
  SELECT 103, '2023-11-03 09:00:00', '2023-11-03 10:00:00', 11, 'Viewer'
),
    group_condition as (
        select
            user_id,
            session_type,
            start_seconds,
            session_start,
            end_seconds,
            session_end,
            before_session_end_seconds,
            sum(
             case
                 -- 首次会话
                 when before_session_end_seconds is null then 0
                 -- 会话区间重叠也视为满足连续条件
                 when start_seconds - before_session_end_seconds <= 0 then 0
                 -- 两个会话间隔少于12小时
                 when start_seconds - before_session_end_seconds <= 12 * 60 * 60 then 0
                 else 1 end
            ) over(partition by user_id, session_type order by start_seconds ) group_id

        from (
            select user_id,
                   session_type,
                   -- 秒级别
                   unix_timestamp(session_start,'yyyy-MM-dd HH:mm:ss') start_seconds,
                   session_start,
                   unix_timestamp(session_end,'yyyy-MM-dd HH:mm:ss') end_seconds,
                   session_end,
                   lag(unix_timestamp(session_end)) over(partition by user_id , session_type order by unix_timestamp(session_start)) before_session_end_seconds

            from Sessions
            where session_type in ("Viewer","Streamer")
             ) t1
    )
select
    user_id
from group_condition
group by user_id, session_type, group_id
having count(1) >= 2;

```

![image-20250323112555570](https://5201969.xyz/api/public/img/dfc9ceac41d3026aca3a4bc0bbe32e16)





## 分配工作量

```sql
/*

表: Project
+--------------------+
| Column Name | Type |
+--------------------+
| project_id | int |
| employee_id | int |
| workload | int |
+--------------------+
employee_id 是这张表的主键 (有不同值的列)。
employee_id 是 Employee 表的外键 (引用列)。
这张表的每一行表示 employee_id 所指的员工在 project_id 所指的项目上工作，以及项目的工作量。

表: Employees
+--------------------+
| Column Name | Type |
+--------------------+
| employee_id | int |
| name | varchar |
| team | varchar |
+--------------------+
employee_id 是这张表的主键 (有不同值的列)。
这张表的每一行包含一个员工的信息。
考虑一个方案，找出分配给项目工作量 超过各自团队 所有员工 平均工作量 的 员工，
返回结果集，以 employee_id, project_id 开序 排序。
结果格式如下所示。

示例 1:
输入:
Project 表:
+------------+-------------+----------+
| project_id | employee_id | workload |
+------------+-------------+----------+
| 1 | 1 | 45 |
| 1 | 2 | 90 |
| 2 | 3 | 12 |
| 2 | 4 | 68 |
+------------+-------------+----------+
Employees 表:
+-------------+-------+------+
| employee_id | name | team |
+-------------+-------+------+
| 1 | Khaled | A |
| 2 | Ali | B |
| 3 | John | B |
| 4 | Doe | A |
+-------------+-------+------+
输出:
+-------------+------------+--------------+------------------+
| employee_id | project_id | employee_name | project_workload |
+-------------+------------+--------------+------------------+
| 2 | 1 | Ali | 90 |
| 4 | 2 | Doe | 68 |
+-------------+------------+--------------+------------------+
解释:
- ID 为 1 的员工项目工作为 45 并属于 Team A, 其中均工作量为 56.50，因为该个项目工作量没有超过小组的平均工作量，他被排除。
- ID 为 2 的员工项目工作为 90 并属于 Team B, 其中均工作量为 51.00，因为该个项目工作量超过小组的平均工作量，他将包含在结果中。
- ID 为 3 的员工项目工作为 12 并属于 Team B, 其中均工作量为 51.00，因为该个项目工作量没有超过小组的平均工作量，他被排除。
- ID 为 4 的员工项目工作为 68 并属于 Team A, 其中均工作量为 56.50，因为该个项目工作量超过小组的平均工作量，他将包含在结果中。
结果按(employee_id, project_id) 开序排序。
*/


WITH Project AS (
    SELECT 1 as project_id, 1 as employee_id, 45 as workload UNION ALL
    SELECT 1, 2, 90 UNION ALL
    SELECT 2, 3, 12 UNION ALL
    SELECT 2, 4, 68
),
Employees AS (
    SELECT 1 as employee_id, 'Khaled' as name, 'A' as team UNION ALL
    SELECT 2, 'Ali', 'B' UNION ALL
    SELECT 3, 'John', 'B' UNION ALL
    SELECT 4, 'Doe', 'A'
),
    avg_siuattion as (
        select team,
               project_id,
               employee_id,
               employee_name,
               total_workload,
               avg(total_workload) over(partition by team) team_avg_workload
        from (
            SELECT
                t1.team,
                t2.project_id,
                t1.employee_id,
                t1.name employee_name,
                sum(coalesce(t2.workload, 0)) total_workload
            from Employees t1
            left join Project t2
            on t1.employee_id = t2.employee_id
            group by t1.team , t2. project_id, t1.employee_id, t1.name

             ) t1
    )
select
    employee_id,
    project_id,
    employee_name,
    total_workload
from avg_siuattion
where total_workload > team_avg_workload
order by employee_id,project_id;
```


![image-20250324123049916](https://5201969.xyz/api/public/img/916863d97cca4a4303fcc9ef2d022513)



## 会话(有条件的开始和后续)



```sql
/*
表: Sessions
+---------------------+
| Column Name | Type  |
+---------------------+
| user_id | int |
| session_start | datetime |
| session_end | datetime |
| session_id | int |
| session_type | enum |
+---------------------+
session_id 是这张表具有唯一值的列。
session_type 是一个枚举(Enum)类型，类型为(Viewer, Streamer)两个类型。
这张表包含 user_id, session_start, session_end, session_id 和 session_type.
编写一个解决方案，找到 首次会话 为 观众型的 的用户, 其 主播会话 数量。
按照会话数量由 user_id 降序 排序返回结果集。
结果格式如下所示。

示例 1:
输入:
Sessions table:
+----------+---------------------+---------------------+-----------+-------------+
| user_id | session_start      | session_end        | session_id | session_type |
+----------+---------------------+---------------------+-----------+-------------+
| 101 | 2023-11-06 13:53:42 | 2023-11-06 14:05:42 | 375 | Viewer |
| 101 | 2023-11-22 16:45:21 | 2023-11-22 20:39:21 | 594 | Streamer |
| 102 | 2023-11-16 13:23:09 | 2023-11-16 16:10:09 | 777 | Streamer |
| 102 | 2023-11-17 13:23:09 | 2023-11-17 16:10:09 | 778 | Streamer |
| 101 | 2023-11-20 07:16:06 | 2023-11-20 08:33:06 | 315 | Streamer |
| 104 | 2023-11-27 03:10:49 | 2023-11-27 03:30:49 | 797 | Viewer |
| 103 | 2023-11-27 03:10:49 | 2023-11-27 03:30:49 | 798 | Streamer |
+----------+---------------------+---------------------+-----------+-------------+
输出:
+----------+----------------+
| user_id | sessions_count |
+----------+----------------+
| 101 | 2 |
+----------+----------------+
解释
- user_id 101, 在 2023-11-06 13:53:42 以观众身份开始了他们的初始会话，随后进行了两次主播会话，所以计数为 2。
- user_id 102, 尽管有两个会话，但初始会话是作为主播，因此被排除此用户。
- user_id 103 只参与了一次会话，即作为主播，因此不会考虑在内。
- user_id 104 以观众身份开始了他们的唯一一次会话，但没有后续会话，因此不会包括在最终计数中。
输出表按照会话数量和 user_id 降序排序。
*/
WITH Sessions AS (
    SELECT 101 as user_id, '2023-11-06 13:53:42' as session_start, '2023-11-06 14:05:42' as session_end, 375 as session_id, 'Viewer' as session_type UNION ALL
    SELECT 101, '2023-11-22 16:45:21', '2023-11-22 20:39:21', 594, 'Streamer' UNION ALL
    SELECT 102, '2023-11-16 13:23:09', '2023-11-16 16:10:09', 777, 'Streamer' UNION ALL
    SELECT 102, '2023-11-17 13:23:09', '2023-11-17 16:10:09', 778, 'Streamer' UNION ALL
    SELECT 101, '2023-11-20 07:16:06', '2023-11-20 08:33:06', 315, 'Streamer' UNION ALL
    SELECT 104, '2023-11-27 03:10:49', '2023-11-27 03:30:49', 797, 'Viewer' UNION ALL
    SELECT 103, '2023-11-27 03:10:49', '2023-11-27 03:30:49', 798, 'Streamer'
)
select
    distinct
    user_id,
    total_streamer_counts
from (
    select
        user_id,
        first_value(session_type) over(partition by user_id order by session_start) first_session_type,
        sum(if(session_type = 'Streamer', 1, 0)) over(partition by user_id ) total_streamer_counts
    from Sessions t1
     ) t2
where first_session_type = 'Viewer'
and total_streamer_counts != 0;


-- 方式2
WITH Sessions AS (
    SELECT 101 as user_id, '2023-11-06 13:53:42' as session_start, '2023-11-06 14:05:42' as session_end, 375 as session_id, 'Viewer' as session_type UNION ALL
    SELECT 101, '2023-11-22 16:45:21', '2023-11-22 20:39:21', 594, 'Streamer' UNION ALL
    SELECT 102, '2023-11-16 13:23:09', '2023-11-16 16:10:09', 777, 'Streamer' UNION ALL
    SELECT 102, '2023-11-17 13:23:09', '2023-11-17 16:10:09', 778, 'Streamer' UNION ALL
    SELECT 101, '2023-11-20 07:16:06', '2023-11-20 08:33:06', 315, 'Streamer' UNION ALL
    SELECT 104, '2023-11-27 03:10:49', '2023-11-27 03:30:49', 797, 'Viewer' UNION ALL
    SELECT 103, '2023-11-27 03:10:49', '2023-11-27 03:30:49', 798, 'Streamer'
),
    t1 as(
    select user_id
    from(
        select user_id,session_type,rank() over (partition by user_id order by session_start) as rk
        from Sessions
    ) r
    where rk = 1 and session_type = 'Viewer'
)
select t1.user_id,COUNT(1) as sessions_count
from t1
join Sessions s
on t1.user_id = s.user_id
where session_type = 'Streamer'
group by user_id
order by sessions_count desc,user_id desc

```



![image-20250324124626905](https://5201969.xyz/api/public/img/92c358a605610eb5f73a1327850cd5dd)



## 前三名酒庄

```sql
/*

# 题目40 前三名酒庄 (dt = '2024-12-27')

表: Wineries
+-----------------------+
| Column Name | Type |
+-----------------------+
| id | int |
| country | varchar |
| points | int |
| winery | varchar |
+-----------------------+
id 是该张表具有唯一值的列。
这张表包含 id, country, points和 winery。
编写一个解决方案，根据每家酒庄的 总分 找出 每个国家 的前三名酒庄。如果有 多个酒庄 的总分 相同，则
按 winery名称升序排列。如果没有分数排在第二的酒庄，则输出‘No Second Winery"，如果没有分数排在
第三的酒庄，则输出‘No Third Winery”。
返回结果表按 country 升序 排列。
结果表格式如下例所示。

示例 1:
输入:
Wineries table:
+-----+----------+--------+------------------+
| id  | country  | points | winery           |
+-----+----------+--------+------------------+
| 103 | Australia | 84    | WhisperingPines  |
| 737 | Australia | 85    | GrapesGalore    |
| 848 | Australia | 100   | HarmonyHill     |
| 222 | Hungary   | 60    | MoonlitCellars   |
| 116 | USA       | 47    | RoyalVines      |
| 124 | USA       | 45    | EaglesNest      |
| 648 | India     | 69    | SunsetVines     |
| 894 | USA       | 39    | RoyalVines      |
| 677 | USA       | 9     | PacificCrest    |
+-----+----------+--------+------------------+

输出:
+----------+------------+--------------+-------------+
| country  | top_winery | second_winery | third_winery |
+----------+------------+--------------+-------------+
| Australia | HarmonyHill (100) | GrapesGalore (85) | WhisperingPines (84) |
| Hungary  | MoonlitCellars (60) | No second winery | No third winery |
| India    | SunsetVines (69) | No second winery | No third winery |
| USA      | RoyalVines (86) | EaglesNest (45) | PacificCrest (9) |
+----------+------------+--------------+-------------+

解释:
对于 Australia
- HarmonyHill 酒庄获得了 Australia 的最高分数, 为 100 分。
- GrapesGalore 酒庄总共获得 85 分, 位列 Australia 的第二位。
- WhisperingPines 酒庄总共获得 84 分, 位列 Australia 的第三位。
对于 Hungary
- MoonlitCellars 是唯一的酒庄, 获得 60 分, 自动成为最高分数的酒庄, 没有第二或第三名酒庄。
对于 India
- SunsetVines 是唯一的酒庄, 获得 69 分, 成为最高的酒庄, 没有第二或第三名酒庄。
对于 USA
- RoyalVines wines 累计了总分 47 + 39 = 86 分, 占据了 USA 的最高位置。
- EaglesNest 总共获得 45 分, 位列 USA 的第二高位置。
- PacificCrest 累计了 9 分, 位列 USA 的第三高位置。
输出表按国家名字母升序排列。




**表数据示例：**

*/

WITH Wineries AS (
  SELECT 103 AS id, 'Australia' AS country, 84 AS points, 'WhisperingPines' AS winery UNION ALL
  SELECT 737, 'Australia', 85, 'GrapesGalore' UNION ALL
  SELECT 848, 'Australia', 100, 'HarmonyHill' UNION ALL
  SELECT 222, 'Hungary', 60, 'MoonlitCellars' UNION ALL
  SELECT 116, 'USA', 47, 'RoyalVines' UNION ALL
  SELECT 124, 'USA', 45, 'EaglesNest' UNION ALL
  SELECT 648, 'India', 69, 'SunsetVines' UNION ALL
  SELECT 894, 'USA', 39, 'RoyalVines' UNION ALL
  SELECT 677, 'USA', 9, 'PacificCrest'
),
winer_rank AS (
    SELECT
        country,
        winery,
        SUM(points) AS points,
        ROW_NUMBER() OVER(PARTITION BY country ORDER BY SUM(points) DESC, winery ASC) AS rn
    FROM Wineries
    GROUP BY country, winery
),
dim_country AS (
    SELECT DISTINCT
        country
    FROM Wineries
)
SELECT
    t1.country,
    COALESCE(MAX(CASE WHEN t2.rn = 1 THEN CONCAT(t2.winery,' (',t2.points,')') END), 'No first winery') AS top_winery,
    COALESCE(MAX(CASE WHEN t2.rn = 2 THEN CONCAT(t2.winery,' (',t2.points,')') END), 'No second winery') AS second_winery,
    COALESCE(MAX(CASE WHEN t2.rn = 3 THEN CONCAT(t2.winery,' (',t2.points,')') END), 'No third winery') AS third_winery
FROM dim_country t1
LEFT JOIN winer_rank t2
ON t1.country = t2.country
GROUP BY t1.country
ORDER BY t1.country;

-- 方式二
WITH Wineries AS (
  SELECT 103 AS id, 'Australia' AS country, 84 AS points, 'WhisperingPines' AS winery UNION ALL
  SELECT 737, 'Australia', 85, 'GrapesGalore' UNION ALL
  SELECT 848, 'Australia', 100, 'HarmonyHill' UNION ALL
  SELECT 222, 'Hungary', 60, 'MoonlitCellars' UNION ALL
  SELECT 116, 'USA', 47, 'RoyalVines' UNION ALL
  SELECT 124, 'USA', 45, 'EaglesNest' UNION ALL
  SELECT 648, 'India', 69, 'SunsetVines' UNION ALL
  SELECT 894, 'USA', 39, 'RoyalVines' UNION ALL
  SELECT 677, 'USA', 9, 'PacificCrest'
),
winer_rank AS (
    SELECT
        country,
        winery,
        SUM(points) AS points,
        ROW_NUMBER() OVER(PARTITION BY country ORDER BY SUM(points) DESC, winery ASC) AS rn
    FROM Wineries
    GROUP BY country, winery
)
select
    country,
    coalesce(max(case when rn = 1 then CONCAT(winery,' (',points,')')  end ), 'No first winery') top_winery,
    coalesce(max(case when rn = 2 then CONCAT(winery,' (',points,')') end ), 'No second winery' ) second_winery,
    coalesce(max(case when rn = 3 then CONCAT(winery,' (',points,')') end ),'No third winery') third_winery
from winer_rank
where rn < 4
group by country
order by country;
```



![image-20250325121132292](https://5201969.xyz/api/public/img/1e9f6934beec6773d96c09712233a5bc)

## 确认乘客状态

```sql
/*

表: Flights
+----------------+
| 列名 | 类型 |
+----------------+
| flight_id | int |
| capacity | int |
+----------------+
flight_id 列全不同的值。
每行包含航班 id 和座位容量。

表：Passengers
| 列名 | 类型 |
+--------------------+
| passenger_id | int |
| flight_id | int |
| booking_time | datetime |

passenger_id 包含不同的值。
booking_time 包含不同的值。
每行包含乘客 id、预订时间和所预订的航班 id。
乘客提前预订航班机票。如果乘客预订了一张航班机票，并且航班上还有空座位，则乘客的机票将得到确认。然
而，如果航班已经满员，乘客将被列入等候名单。
编写解决方案来确定每个乘客航班机票的当前状态。
按 passenger_id 升序排序 返回结果表。

| flight_id | capacity |
+-----------+----------+
| 1 | 2 |
| 2 | 2 |
| 3 | 1 |


表: Passengers
+------------------------------------------+
| passenger_id | flight_id | booking_time |
+------------------------------------------+
| 101 | 1 | 2023-07-10 16:30:00 |
| 102 | 1 | 2023-07-10 17:45:00 |
| 103 | 1 | 2023-07-10 12:00:00 |
| 104 | 2 | 2023-07-05 13:23:00 |
| 105 | 2 | 2023-07-05 09:00:00 |
| 106 | 3 | 2023-07-08 11:10:00 |
| 107 | 3 | 2023-07-08 09:10:00 |
+------------------------------------------+

输出:
+------------------------+
| passenger_id | status |
+------------------------+
| 101 | Confirmed |
| 104 | Confirmed |
| 105 | Confirmed |
| 106 | Waitlist |
| 107 | Confirmed |
+------------------------+

解释:
- 航班 1 的容量为 2，乘客 101 和乘客 103 是最先预订机票的，已经确认他们的预订。然而，乘客 102 是第三位预订该航班的乘客，这趟航班没有更多的可用座位，乘客 102 被添加入等候名单。
- 航班 2 的容量为 2，已经有两名乘客预订了机票，乘客 104 和乘客 105，由于预订机票的乘客数与可用座位数相符，这两个预订都得到了确认。
- 航班 3 的容量为 1，由于乘客 107 先预订了一个可用座位，该乘客的预订得到了确认。预订时间在乘客 107 之后的乘客 106 被列入等候名单。

with t as (select passenger_id,capacity,
rank() over(partition by flight_id order by booking_time) as rnk
from passengers join flights using(flight_id))

select passenger_id,
if(rnk<=capacity,'Confirmed','Waitlist') as status
from t
order by passenger_id


题目40 前三名酒店 (dt = '2024-12-27')*/

WITH Flights AS (
  SELECT 1 AS flight_id, 2 AS capacity UNION ALL
  SELECT 2 AS flight_id, 2 AS capacity UNION ALL
  SELECT 3 AS flight_id, 1 AS capacity
),
Passengers AS (
  SELECT 101 AS passenger_id, 1 AS flight_id, '2023-07-10 16:30:00' AS booking_time UNION ALL
  SELECT 102 AS passenger_id, 1 AS flight_id, '2023-07-10 17:45:00' AS booking_time UNION ALL
  SELECT 103 AS passenger_id, 1 AS flight_id, '2023-07-10 12:00:00' AS booking_time UNION ALL
  SELECT 104 AS passenger_id, 2 AS flight_id, '2023-07-05 13:23:00' AS booking_time UNION ALL
  SELECT 105 AS passenger_id, 2 AS flight_id, '2023-07-05 09:00:00' AS booking_time UNION ALL
  SELECT 106 AS passenger_id, 3 AS flight_id, '2023-07-08 11:10:00' AS booking_time UNION ALL
  SELECT 107 AS passenger_id, 3 AS flight_id, '2023-07-08 09:10:00' AS booking_time
)
select t1.passenger_id,
       t1.booking_time,
       if(t1.current_passagers <= t2.capacity, 'Confirmed', 'Waitlist') status
from (
    select passenger_id,
           flight_id,
           booking_time,
           count(distinct passenger_id) over(partition by flight_id order by booking_time ) current_passagers
    from Passengers t1
     ) t1
left join Flights t2
on t1.flight_id = t2.flight_id
order by t1.passenger_id;

-- 方式二
WITH Flights AS (
  SELECT 1 AS flight_id, 2 AS capacity UNION ALL
  SELECT 2 AS flight_id, 2 AS capacity UNION ALL
  SELECT 3 AS flight_id, 1 AS capacity
),
Passengers AS (
  SELECT 101 AS passenger_id, 1 AS flight_id, '2023-07-10 16:30:00' AS booking_time UNION ALL
  SELECT 102 AS passenger_id, 1 AS flight_id, '2023-07-10 17:45:00' AS booking_time UNION ALL
  SELECT 103 AS passenger_id, 1 AS flight_id, '2023-07-10 12:00:00' AS booking_time UNION ALL
  SELECT 104 AS passenger_id, 2 AS flight_id, '2023-07-05 13:23:00' AS booking_time UNION ALL
  SELECT 105 AS passenger_id, 2 AS flight_id, '2023-07-05 09:00:00' AS booking_time UNION ALL
  SELECT 106 AS passenger_id, 3 AS flight_id, '2023-07-08 11:10:00' AS booking_time UNION ALL
  SELECT 107 AS passenger_id, 3 AS flight_id, '2023-07-08 09:10:00' AS booking_time
)
select passenger_id,
           booking_time,
           if(rank() over(partition by t1.flight_id order by booking_time ) <= t2.capacity , 'Confirmed','Waitlist') status
    from Passengers t1
left join Flights t2
on t1.flight_id = t2.flight_id
order by t1.passenger_id;



```

![image-20250325121051945](https://5201969.xyz/api/public/img/edaa47cbe53ea02dc26c76e08e308c77)



## 好友受欢迎百分比

~~~sql
/*

 题目37 好友受欢迎百分比

 表: Friends
```
+----------------+------+
| 列名           | 类型 |
+----------------+------+
| user1 | int |
| user2 | int |
+----------------+------+
```

(user1, user2) 是该表的主键(具有唯一值的列)。
每一行包含关于好友关系的信息，其中 user1 和 user2 是好友。
编写一条 SQL 查询，找出 Meta/Facebook 平台上每个用户的受欢迎度百分比。受欢迎度百分比定义为用户拥有的好友总数除以平台上的用户数，然后乘以 100，并 四舍五入保留 2 位小数。
返回结果 user1 升序 排序的结果表。

示例 1:
输入:

Friends 表:
```
+------+------+
| user1 | user2 |
+------+------+
| 2    | 1    |
| 1    | 3    |
| 4    | 1    |
| 1    | 5    |
| 1    | 6    |
| 2    | 6    |
| 7    | 2    |
| 8    | 3    |
| 3    | 9    |
+------+------+
```

输出:
```
+------+---------------------+
| user1 | percentage_popularity |
+------+---------------------+
| 1    | 55.56               |
| 2    | 33.33               |
| 3    | 33.33               |
| 4    | 11.11               |
| 5    | 11.11               |
| 6    | 22.22               |
| 7    | 11.11               |
| 8    | 11.11               |
| 9    | 11.11               |
+------+---------------------+
```

解释:
平台上总共有 9 个用户。
- 用户"1"与 2、3、4、5 和 6 是朋友，因此，用户 1 的受欢迎度百分比计算为 (5/9) * 100 = 55.56。
- 用户"2"与 1、6 和 7 是朋友，因此，用户 2 的受欢迎度百分比计算为 (3/9) * 100 = 33.33。
- 用户"3"与 1、8 和 9 是朋友，因此，用户 3 的受欢迎度百分比计算为 (3/9) * 100 = 33.33。
- 用户"4"与 1 是朋友，因此，用户 4 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
- 用户"5"与 1 是朋友，因此，用户 5 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
- 用户"6"与 1 和 2 是朋友，因此，用户 6 的受欢迎度百分比计算为 (2/9) * 100 = 22.22。
- 用户"7"与 2 是朋友，因此，用户 7 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
- 用户"8"与 3 是朋友，因此，用户 8 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
- 用户"9"与 3 是朋友，因此，用户 9 的受欢迎度百分比计算为 (1/9) * 100 = 11.11。
user1 按升序排序。

```sql
WITH src AS(
    SELECT * FROM Friends
    UNION ALL
    SELECT user2 AS user1,user1 AS user2
    FROM Friends
),t AS(
    SELECT src.user1,COUNT(DISTINCT src.user2) AS f2,COUNT(src.user1) OVER() AS fa
    FROM src
    GROUP BY user1
)
SELECT t.user1,round(f2*100/fa,2) AS percentage_popularity
FROM t
ORDER BY t.user1
```
*/
WITH Friends AS (
    SELECT 2 AS user1, 1 AS user2 UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 4, 1 UNION ALL
    SELECT 1, 5 UNION ALL
    SELECT 1, 6 UNION ALL
    SELECT 2, 6 UNION ALL
    SELECT 7, 2 UNION ALL
    SELECT 8, 3 UNION ALL
    SELECT 3, 9
)
select
    distinct
    user1,
    round(count(distinct user2) over(partition by user1) /
    count(distinct user1) over () ,2) rate
from (
    select
        user1,
        user2
    from Friends
    UNION all
    select
        user2,
        user1
    from Friends
     ) t1
order by user1;

~~~





## 经典单调递增

~~~sql
/*
 题目36 经典单调递增

 SQL

表: Orders

| Column Name | Type |
|------------|------|
| order_id | int |
| customer_id | int |
| order_date | date |
| price | int |

order_id 是该表的主键。
每行包含订单的 id, 订购订单的客户 id, 订单日期和价格。

编写一个 SQL 查询, 根据 总购买量 每年严格递增的客户 id。
即, 客户在附近 总购买量 是按照订单价格的总和, 如果某一年客户严没有下任何订单, 我们认为总购买量为 0。
对于每个客户, 要考虑的第一个年是他们 第一次下单 的年份。
对于每个客户, 要考虑的最后一个年是他们 最后一次下单 的年份。

以 任意顺序 返回结果表。

示例 1:

输入:
Orders 表:
| order_id | customer_id | order_date | price |
|---------|------------|-----------|-------|
| 1 | 1 | 2019-07-01 | 1100 |
| 2 | 1 | 2019-11-01 | 1200 |
| 3 | 1 | 2020-05-26 | 3000 |
| 4 | 1 | 2021-08-31 | 3100 |
| 5 | 1 | 2022-12-07 | 4700 |
| 6 | 2 | 2015-01-01 | 700 |
| 7 | 2 | 2017-11-07 | 1000 |
| 8 | 3 | 2017-01-01 | 900 |
| 9 | 3 | 2018-11-07 | 900 |

输出:
| customer_id |
|------------|
| 1 |

解释:
客户 1: 第一年是 2019 年, 最后一年是 2022 年
- 2019: 1100 + 1200 = 2300
- 2020: 3000
- 2021: 3100
- 2022: 4700
我们可以看到总购买量每年都在严格递增, 所以现在在答案中包含了客户 1.

客户 2: 第一年是2015年, 最后一年是2017年
- 2015: 700
- 2016: 0
- 2017: 1000
我们没有将客户 2 包括在答案中, 因为他的购买量并没有严格地增加, 请注意, 客户 2 在 2016 年没有购买任何物品。

客户 3: 第一年是 2017 年, 最后一年是 2018 年
- 2017: 900
- 2018: 900

```sql
select customer_id 
from 
(select customer_id,year,yearp,
year-rank() over(partition by customer_id order by year)) as dif
from
(select customer_id,year(order_date) as year,
sum(price) as yearp
  
from orders
group by customer_id,year(order_date)
) t1) t1
group by customer_id
having count(distinct dif)=1
```


*/

WITH orders_data AS (
    SELECT 1 as order_id, 1 as customer_id, '2019-07-01' as order_date, 1100 as price UNION ALL
    SELECT 2, 1, '2019-11-01', 1200 UNION ALL
    SELECT 3, 1, '2020-05-26', 3000 UNION ALL
    SELECT 4, 1, '2021-08-31', 3100 UNION ALL
    SELECT 5, 1, '2022-12-07', 4700 UNION ALL
    SELECT 6, 2, '2015-01-01', 700 UNION ALL
    SELECT 7, 2, '2017-11-07', 1000 UNION ALL
    SELECT 8, 3, '2017-01-01', 900 UNION ALL
    SELECT 9, 3, '2018-11-07', 900
),
    year_ana as ( 
        select
               customer_id,
               order_year,
               year_amount,
               lead(order_year) over (partition by customer_id order by order_year) next_year,
               lead(year_amount) over (partition by customer_id order by order_year) next_year_amount
        from (
                select
                     customer_id, year(date_format(order_date,'yyyy-mm-dd')) order_year,
                     sum(coalesce(price,0)) year_amount
                from orders_data t1
                group by customer_id, year(date_format(order_date,'yyyy-mm-dd'))
             ) t1

    )
select
    distinct customer_id
from (
    select
        customer_id,
        sum(case
            when next_year is null then 0
            when next_year is not null and next_year_amount > year_amount and next_year = order_year + 1 then 0
            else 1 end  )
        over (partition by customer_id order by order_year) grouping_id
    from year_ana
     ) t2
where grouping_id = 0;



~~~



## 发票信息

~~~sql
/*
题目35 发票信息

```sql
表: Products

| Column Name | Type |
+--------------+------+
| product_id | int |
| price | int |
+--------------+------+
product_id 是该表的主键。
该表中的每一行描述了一个产品的 ID 和一个单位的价格。

表: Purchases

| Column Name | Type |
+--------------+------+
| invoice_id | int |
| product_id | int |
| quantity | int |
+--------------+------+
(invoice_id, product_id) 是该表的主键（具有唯一值的列的组合）。
该表中的每一行都显示了小张单中的一种产品订购的数量。
编写解决方案，展示价格最高的发票的详细信息。如果最高价签发了多个发票且有相同的价格，则返回 invoice_id 最小的发票的详细信息。

以 任意顺序 返回结果表。
结果格式示例如下。

示例 1:

输入:
Products 表:
+--------------+-------+
| product_id | price |
+--------------+-------+
| 1 | 100 |
| 2 | 200 |
+--------------+-------+
Purchases 表:
+------------+--------------+----------+
| invoice_id | product_id | quantity |
+------------+--------------+----------+
| 1 | 1 | 2 |
| 2 | 2 | 1 |
| 4 | 1 | 10 |
+------------+--------------+----------+
输出:
+--------------+----------+-------+
| product_id | quantity | price |
+--------------+----------+-------+
| 2 | 3 | 600 |
| 1 | 4 | 400 |
+--------------+----------+-------+
解释:
发票 1: price = (2 * 100) = $200
发票 2: price = (4 * 100) + (3 * 200) = $1000
发票 3: price = (1 * 200) = $200

最高价格是 1000 美元，最高价格的发票是 2 和 4。我们返回 ID 最小的发票 2 的详细信息。
```

*/
WITH Products AS (
    SELECT 1 AS product_id, 100 AS price
    UNION ALL
    SELECT 2, 200
),
Purchases AS (
    SELECT 1 AS invoice_id, 1 AS product_id, 2 AS quantity
    UNION ALL
    SELECT 2, 2, 1
    UNION ALL
    SELECT 4, 1, 10
),
    aimed_pur as (
        select
            t1.invoice_id,
            sum(t1.quantity * t2.price) amounts
        from Purchases t1
        left join Products t2
        on t1.product_id = t2.product_id
        group by t1.invoice_id
        order by amounts desc, invoice_id asc
        limit 1
    )
select
    t2.product_id,
    t1.quantity,
    t2.price
from Purchases t1
left join Products t2
on t1.product_id = t2.product_id
left join aimed_pur t3
on t1.invoice_id = t3.invoice_id
where t3.invoice_id is not null;

~~~



## 文章主题



1. 单词边界(\b)的工作原理

```sql

\b是正则表达式中的元字符，表示单词边界（word boundary），它匹配以下位置：

单词字符（字母、数字、下划线）与非单词字符之间的位置
字符串的开始或结束位置与单词字符之间的位置

ON t1.content RLIKE CONCAT('\\b', t2.word, '\\b')
- 大小写敏感问题
如果希望不区分大小写，可以修改为：`RLIKE CONCAT('(?i)\\b', t2.word, '\\b')`
- 特殊字符处理
如果t2.word可能包含正则特殊字符（如., *, +等），需要先转义：
`ON t1.content RLIKE CONCAT('\\b', regexp_replace(t2.word, '([.\\+*?^$\\[\\](){}\\\\|])', '\\\\$1'), '\\b')`

```

2. concat_ws函数（hive）

   ```bash
   concat_ws(string SEP, string A, string B…)
   或者 支持处理字符串数组 （hive文档 https://issues.apache.org/jira/browse/HIVE-2203）
   concat_ws(string SEP, array)
   ```

   

~~~sql
/*
 题目34 文章主题

```sql
表: Keywords
+---------------+------+
| Column Name   | Type |
+---------------+------+
| topic_id      | int  |
| word          | varchar |
+---------------+------+
(topic_id, word) 是该表的主键（具有唯一值的列的组合）。
该表的每一行都包含一个主题的 id 和一个用于描述该主题的词。
可以用多个词来表达同一个主题，也可以用一个词来表达多个主题。
表: Posts
+---------------+------+
| Column Name   | Type |
+---------------+------+
| post_id       | int  |
| content       | varchar |
+---------------+------+
post_id 是该表的主键（具有唯一值的列）。
该表的每一行都包含一个帖子的 ID 及其内容。
内容仅由英文字母和空格组成。
Leetcode 从其社交媒体网站上收集了一些帖子，并对每个帖子的主题感兴趣。每个主题可以用一个或多个关键字表示，如果某个主题的关键字存在于一个帖子的内容中（不区分大小写），那么这个帖子就有这个主题。
我们想找出每个帖子包含的主题：
如果帖子没有包含任何主题的关键词，那么这个的主题应该是 "Ambiguous!"。
如果帖子至少有一个主题的关键字，那主题应该是这些主题的 id 按升序排列并以逗号'，'分隔的字符串。字符串不应该包含重复的 id。
以 任意顺序 返回结果表。
结果格式如下所示。

示例 1:

输入：
Keywords 表:
+----------+--------+
| topic_id | word   |
+----------+--------+
| 1        | handball |
| 1        | football |
| 3        | WAR    |
| 2        | vaccine |
+----------+--------+
Posts 表:
+----------+--------------------------------------------+
| post_id  | content |
+----------+--------------------------------------------+
| 1        | We call it soccer They call it football hahaha |
| 2        | Americans prefer basketball while Europeans love handball and football |
| 3        | stop the war and play handball |
| 4        | warning I planted some flowers this morning and then got vaccinated |
+----------+--------------------------------------------+

输出：
+----------+----------+
| post_id  | topic    |
+----------+----------+
| 1        | 1        |
| 2        | 1        |
| 3        | 1,3      |
| 4        | Ambiguous! |
+----------+----------+

解释：
1: "We call it soccer They call it football hahaha"
"football" 表示主题 1，没有其他词能表示任何其他主题。

2: "Americans prefer basketball while Europeans love handball and football"
"handball" 表示主题 1，"football" 表示主题 1，
没有其他词能表示任何其他主题。

3: "stop the war and play handball"
"war" 表示主题 3，"handball" 表示主题 1，
没有其他词能表示任何其他主题。

4: "warning I planted some flowers this morning and then got vaccinated"
这个句子里没有一个词能表示任何主题，注意 "warning" 和 "war" 不同，尽管它们两个字母的前缀是相同的，所以这篇文章 "Ambiguous!"

请注意，可以使用一个词来表达多个主题。
```

*/

WITH Keywords AS (
    SELECT 1 AS topic_id, 'handball' AS word
    UNION ALL
    SELECT 1, 'football'
    UNION ALL
    SELECT 3, 'WAR'
    UNION ALL
    SELECT 2, 'vaccine'
),
Posts AS (
    SELECT 1 AS post_id, 'We call it soccer They call it football hahaha' AS content
    UNION ALL
    SELECT 2, 'Americans prefer basketball while Europeans love handball and football'
    UNION ALL
    SELECT 3, 'stop the war and play handball'
    UNION ALL
    SELECT 4, 'warning I planted some flowers this morning and then got vaccinated'
),
    tmp as (
        select
            t3.post_id,
            t3.amid_topic,
            row_number() over (partition by t3.post_id order by amid_topic)
        from (
            SELECT
                t1.post_id,
                CASE
                        WHEN t2.word IS NOT NULL THEN t2.topic_id /*CAST(t2.topic_id AS STRING)*/
                        ELSE -1 /*'Ambiguous'*/
                END amid_topic
            FROM Posts t1
            LEFT JOIN Keywords t2
                 -- 使用单词边界确保精确匹配 且 不区分大小写
            /*ON t1.content RLIKE CONCAT('\\b', t2.word, '\\b')
            or upper(t1.content) RLIKE CONCAT('\\b', t2.word, '\\b')*/
            on t1.content RLIKE CONCAT('(?i)\\b', t2.word, '\\b')
             ) t3

    )
select post_id,
       concat_ws(',',collect_set(
                     case
                         when amid_topic = -1 then 'Ambiguous'
                         else cast(amid_topic as string) end
                     )
       )
from tmp
group by post_id
order by post_id;



~~~



## 选手连胜数

~~~sql
/*
题目33 选手连胜数

```sql
表：Matches

+---------------+------+
| Column Name   | Type |
+---------------+------+
| player_id     | int  |
| match_day     | date |
| result        | enum |
+---------------+------+
(player_id, match_day) 是该表的主键 (具有唯一值的列的组合)。
每一行包括了: 参赛选手 id, 比赛时间, 比赛结果。
比赛结果 (result) 的枚举类型为 ('Win', 'Draw', 'Lose')。
选手的 连胜数 是指该选手获胜的次数, 且这有胜平局紧密相连的情况下。
题目解决方案是计算每个参赛选手最多的连胜数。
结果请按如下 选手id 返回。

示例 1:

输入：
Matches 表:
+------------+------------+---------+
| player_id  | match_day  | result  |
+------------+------------+---------+
| 1          | 2022-01-17 | Win     |
| 1          | 2022-01-18 | Win     |
| 1          | 2022-01-25 | Win     |
| 1          | 2022-01-31 | Draw    |
| 1          | 2022-02-08 | Win     |
| 2          | 2022-02-06 | Lose    |
| 2          | 2022-02-08 | Lose    |
| 3          | 2022-03-30 | Win     |
+------------+------------+---------+

输出：
+------------+----------------+
| player_id  | longest_streak |
+------------+----------------+
| 1          | 3              |
| 2          | 0              |
| 3          | 1              |
+------------+----------------+

解释：
Player 1:
从 2022-01-17 到 2022-01-25, player 1连续赢了三场比赛。
2022-01-31, player 1 平局。
2022-02-08, player 1 赢了一场比赛。
最多连续赢了三场比赛。

Player 2:
从 2022-02-06 到 2022-02-08, player 2 输了两场比赛。
最多连续赢了0场比赛。

Player 3:
2022-03-30, player 3 赢了一场比赛。
最多连续赢了一场比赛。
```


*/
with Matches as (
  select 1 as player_id, '2022-01-17' as match_day, 'Win' as result union all
  select 1 as player_id, '2022-01-18' as match_day, 'Win' as result union all
  select 1 as player_id, '2022-01-25' as match_day, 'Win' as result union all
  select 1 as player_id, '2022-01-31' as match_day, 'Draw' as result union all
  select 1 as player_id, '2022-02-08' as match_day, 'Win' as result union all
  select 2 as player_id, '2022-02-06' as match_day, 'Lose' as result union all
  select 2 as player_id, '2022-02-08' as match_day, 'Lose' as result union all
  select 3 as player_id, '2022-03-30' as match_day, 'Win' as result
),
    continus_wins as (
        select
            player_id,
            new_day,
            count(1) continus_days,
            row_number() over (partition by player_id order by count(1) desc) rn
        from (
            select player_id,
                   to_date(match_day) match_day,
                   date_sub(to_date(match_day),row_number() over (partition by player_id order by to_date(match_day))) new_day
            from Matches t1
            where result = 'Win'
             ) t1
        group by player_id,new_day
    )
select
    t2.player_id,
    coalesce(t3.continus_days ,0) longest_streak
from (
    select
        player_id
    from Matches
    group by player_id
     ) t2
left join continus_wins t3
on t2.player_id = t3.player_id and t3.rn = 1;
~~~



## 雇员系列题2

~~~sql
/*
题目32 雇员系列题2

```sql
表: Candidates
+---------------+------+
| Column Name   | Type |
+---------------+------+
| employee_id   | int  |
| experience    | enum |
| salary        | int  |
+---------------+------+
employee_id 是该表中具有唯一值的列。
经验是一个枚举，其中包含一个值 ("高级"，"初级")。
此表的每一行都显示候选人的id, 月薪和经验。
每个候选人的工资保证是 独一的。

一家公司想雇用新员工, 公司的工资预算是 $70000 , 公司的招聘标准是:
1.雇用尽可能多的高级候选人。
2.在剩余的预算中雇用尽可能多的初级候选人。

用解下的预算雇用薪水最低的初级候选人。
继续以最低的工资雇佣初级候选人，直到不能再雇佣更多的初级职员。
编写一个解决方案，查找根据上述条件雇用的职员的 ID。
按 ID 降序排序 返回结果。

返回结果格式如下例所示:

示例 1:
输入:
Candidates table:
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 10000  |
| 9           | Junior     | 15000  |
| 2           | Senior     | 20000  |
| 11          | Senior     | 16000  |
| 13          | Senior     | 50000  |
| 4           | Junior     | 40000  |
+-------------+------------+--------+

输出:
+-------------+
| employee_id |
+-------------+
| 11          |
| 2           |
| 1           |
| 9           |
+-------------+

解释:
我们可以雇佣3名有经验的ID (11,2) 的高级员工，由于预算是7万美元，他们的工资总额是:$16,000 + $20,000 + $50,000 = $86,000 > $70,000, 我们只有3.6万美元，但他们不足以雇佣ID为 13 的高级员工。
我们可以雇佣2名ID为 (1,9) 的初级员工，由于剩余预算为3.4万美元，他们的工资总额为:1.0万美元 + 1.5万美元 = 2.5万美元，我们还有9000美元，但他们不足以雇佣ID为 4 的初级员工。

示例 2:
输入:
Candidates table:
+-------------+------------+--------+
| employee_id | experience | salary |
+-------------+------------+--------+
| 1           | Junior     | 25000  |
| 9           | Junior     | 10000  |
| 2           | Senior     | 85000  |
| 11          | Senior     | 80000  |
| 13          | Senior     | 90000  |
| 4           | Junior     | 30000  |
+-------------+------------+--------+

输出:
+-------------+
| employee_id |
+-------------+
| 9           |
| 1           |
| 4           |
+-------------+

解释:
我们不能用目前的预算雇佣任何高级员工，因为我们需要至少 $80000 美元来雇佣一名高级员工。
我们可以用所有的预算雇佣所有三名初级员工。
```

*/

-- 方式1
with Candidates as (
  select 1 as employee_id, 'Junior' as experience, 25000 as salary union all
  select 9 as employee_id, 'Junior' as experience, 10000 as salary union all
  select 2 as employee_id, 'Senior' as experience, 85000 as salary union all
  select 11 as employee_id, 'Senior' as experience, 80000 as salary union all
  select 13 as employee_id, 'Senior' as experience, 90000 as salary union all
  select 4 as employee_id, 'Junior' as experience, 30000 as salary
),
    senior_list as (
        select employee_id,
               experience,
               salary,
               current_cost,
               current_amount,
               row_number() over (order by current_amount ) rn,
               1 flag
        from (
            select employee_id,
                   experience,
                   salary,
                   sum(salary) over (order by salary ) current_cost,
                   70000 - sum(salary) over (order by salary ) current_amount
            from Candidates
            where experience = 'Senior'
             ) t1
        where current_amount > 0
    ),
    availiable_amount as (
        select
            coalesce(b.current_amount, a.amount) amount
        from (
            select
            1 flag,
            70000 amount) a
        left join senior_list b
        on a.flag = b.flag and b.rn = 1
    ),
    junior_list as (
        select employee_id,
               experience,
               salary,
               current_cost,
               current_amount
        from (
            select employee_id,
                   experience,
                   salary,
                   sum(salary) over (order by salary ) current_cost,
                   availiable_amount.amount - sum(salary) over (order by salary ) current_amount
            from Candidates, availiable_amount
            where experience = 'Junior'
             ) t1
        where current_amount > 0
    )
select employee_id
from senior_list
union all
select employee_id
from junior_list;


-- 方式2
with Candidates as (
  select 1 as employee_id, 'Junior' as experience, 25000 as salary union all
  select 9 as employee_id, 'Junior' as experience, 10000 as salary union all
  select 2 as employee_id, 'Senior' as experience, 85000 as salary union all
  select 11 as employee_id, 'Senior' as experience, 80000 as salary union all
  select 13 as employee_id, 'Senior' as experience, 90000 as salary union all
  select 4 as employee_id, 'Junior' as experience, 30000 as salary
)
select employee_id
from
(select *,70000-sum(salary) over(order by experience_rk,salary) as sum_salary2
from
(select *,70000-sum(salary) over(partition by experience order by salary) as sum_salary,if(experience='Senior',1,2) as experience_rk
from candidates) t
where t.sum_salary>=0) t2
where t2.sum_salary2>=0

~~~





## 每个活动每个阶段的完成用户数量



```sql

/*
act_order(
order_id， (订单)
act_id， (活动)
user_id, (用户)
pay_date (支付日期)

act_config (
act_id,
act_stage，(活动阶段)
act_config_cnt (完成活动阶段所需要的订单数量)

求在最近5天内，每个活动、每个阶段的完成用户数量（去重）

-- 查询示例：计算每个活动每个阶段的完成用户数量
SELECT
  c.act_id,
  c.act_stage,
  c.act_config_cnt as required_orders,
  COUNT(DISTINCT CASE WHEN user_orders.order_count >= c.act_config_cnt THEN user_orders.user_id ELSE NULL END) as completed_users
FROM act_config c
LEFT JOIN (
  SELECT
    act_id,
    user_id,
    COUNT(order_id) as order_count
  FROM act_order
  GROUP BY act_id, user_id
) user_orders ON c.act_id = user_orders.act_id
GROUP BY c.act_id, c.act_stage, c.act_config_cnt
ORDER BY c.act_id, c.act_stage;
  */

-- 使用 WITH 子句创建临时表
WITH
-- 模拟订单数据
act_order AS (
  SELECT 1001 as order_id, 101 as act_id, 1 as user_id, '2023-01-01' as pay_date UNION ALL
  SELECT 1002 as order_id, 101 as act_id, 1 as user_id, '2023-01-02' as pay_date UNION ALL
  SELECT 1003 as order_id, 101 as act_id, 1 as user_id, '2023-01-03' as pay_date UNION ALL
  SELECT 1004 as order_id, 101 as act_id, 2 as user_id, '2023-01-01' as pay_date UNION ALL
  SELECT 1005 as order_id, 101 as act_id, 2 as user_id, '2023-01-04' as pay_date UNION ALL
  SELECT 1006 as order_id, 101 as act_id, 3 as user_id, '2023-01-02' as pay_date UNION ALL
  SELECT 1007 as order_id, 102 as act_id, 1 as user_id, '2023-01-05' as pay_date UNION ALL
  SELECT 1008 as order_id, 102 as act_id, 2 as user_id, '2023-01-05' as pay_date UNION ALL
  SELECT 1009 as order_id, 102 as act_id, 4 as user_id, '2023-01-06' as pay_date UNION ALL
  SELECT 1010 as order_id, 102 as act_id, 4 as user_id, '2023-01-07' as pay_date
),

-- 模拟活动配置数据
act_config AS (
  SELECT 101 as act_id, 1 as act_stage, 1 as act_config_cnt UNION ALL
  SELECT 101 as act_id, 2 as act_stage, 2 as act_config_cnt UNION ALL
  SELECT 101 as act_id, 3 as act_stage, 3 as act_config_cnt UNION ALL
  SELECT 102 as act_id, 1 as act_stage, 1 as act_config_cnt UNION ALL
  SELECT 102 as act_id, 2 as act_stage, 2 as act_config_cnt
)
select
    ac.act_id, ac.act_stage,ac.act_config_cnt,
    count(distinct ao.user_id) actual_users,
    count(distinct ao.order_id) actual_orders
from act_order ao
left join act_config ac
on ao.act_id = ac.act_id
where to_date(ao.pay_date) >= date_sub(to_date('2023-01-07'), 5)
group by ac.act_id, ac.act_stage,ac.act_config_cnt
having actual_orders >= act_config_cnt;


```



## 没有被执行的任务



~~~sql
/*
 题目29 没有被执行的任务(不生效的投放，不生效的活动，点击进入但是未下单，点击了活动但是未参与，参与了一半就退出)

```sql
表: Tasks
+----------------+------+
| Column Name    | Type |
+----------------+------+
| task_id        | int  |
| subtasks_count | int  |
+----------------+------+
task_id 具有唯一值的列。
task_id 是示范为主任务的id,每一个task_id被分为了多个子任务(subtasks), subtasks_count表示为子任务的个数 (0) , 它的值表示子任务的索引从1到n,
本表保证: 2<=subtasks_count<= 20,

表: Executed
+---------------+------+
| Column Name   | Type |
+---------------+------+
| task_id       | int  |
| subtask_id    | int  |
+---------------+------+
(task_id, subtask_id) 是该表中具有唯一值的组合。
该表表示哪个task_id的哪些子任务(subtask_id的子任务)被成功执行了,
本表 保证: 对于每一个task_id, subtask_id <= subtasks_count,
当没有被成功完成的task_id的子任务(子任务) 时, 则没有被执行的 (task_id, subtask_id) 。
以 任何顺序 返回即可,

查询结果格式如下,
示例 1:
输入:
Tasks 表:
+-------------+----------------+
| task_id     | subtasks_count |
+-------------+----------------+
| 1           | 3              |
| 2           | 2              |
| 3           | 4              |
+-------------+----------------+
Executed 表:
+-------------+-------------+
| task_id     | subtask_id  |
+-------------+-------------+
| 1           | 2           |
| 3           | 1           |
| 3           | 2           |
| 3           | 3           |
| 3           | 4           |
+-------------+-------------+
输出:
+-------------+-------------+
| task_id     | subtask_id  |
+-------------+-------------+
| 1           | 1           |
| 1           | 3           |
| 2           | 1           |
| 2           | 2           |
+-------------+-------------+
解释:
Task 1 被分为了 3 subtasks (1, 2, 3). 只有 subtask 2 被成功执行了, 所以我们返回 (1, 1) 和 (1, 3)
这两个子任务子任务对.
Task 2 被分为了 2 subtasks (1, 2). 没有一个subtask被成功执行, 因此我们返回(2, 1)和(2, 2).
Task 3 被分为了 4 subtasks (1, 2, 3, 4). 所有的subtask都被成功执行了，因此对于Task 3，我们不返回任何值。
```

```sql
with recursive t(task_id, subtask_id) as (
    SELECT task_id, subtasks_count FROM Tasks
    UNION ALL
    SELECT task_id, subtask_id-1 FROM t where subtask_id>1
)

SELECT * FROM t left join Executed using(task_id, subtask_id)
WHERE Executed.subtask_id is null
ORDER BY task_id, subtask_id
```
*/
WITH Tasks AS (
    SELECT 1 AS task_id, 3 AS subtasks_count
    UNION ALL
    SELECT 2, 2
    UNION ALL
    SELECT 3, 4
),
Executed AS (
    SELECT 1 AS task_id, 2 AS subtask_id
    UNION ALL
    SELECT 3, 1
    UNION ALL
    SELECT 3, 2
    UNION ALL
    SELECT 3, 3
    UNION ALL
    SELECT 3, 4
),
    all_tasks as (
select
    t1.task_id,
    t1.subtasks_count,
    t2.pos + 1 subtask_id
from Tasks t1
lateral view posexplode(split(space(t1.subtasks_count - 1),'')) t2 as pos,val
    )
select
    t1.task_id,
    t1.subtask_id
from all_tasks t1
left join Executed t2
on t1.task_id = t2.task_id and t1.subtask_id = t2.subtask_id
where t2.subtask_id is null;
~~~

## 司机接受乘车次数，系列题目1

~~~sql
/*
 题目26 司机接受乘车次数，系列题目1

表1: Drivers
| Column Name | Type |
|-------------|------|
| driver_id   | int  |
| join_date   | date |

driver_id 是该表的主键（具有唯一值的列）。
该表的每一行都包含驾驶员加入Hopper公司的日期(join_date)的信息。

表2: Rides
| Column Name | Type |
|-------------|------|
| ride_id     | int  |
| user_id     | int  |
| requested_at| date |

ride_id 是该表的主键（具有唯一值的列）。
该表的每一行都包含乘客请求打车服务的信息。
其中有一些请求可能被取消了。

表3: AcceptedRides
| Column Name | Type |
|-------------|------|
| ride_id     | int  |
| driver_id   | int  |
| ride_distance| int  |
| ride_duration| int  |

ride_id 是该表的主键(具有唯一值的列)。
该表的每一行都包含已接受的行程信息。
表中的行程信息都在"Rides"表中存在。
编写解决方案
 以报告2020 年每个月的以下统计信息：截至某月底，当前在Hopper公司工作的
 驾驶员数量（active_drivers）。
该月接受的乘车次数（accepted_rides）。
返回按month升序排列的结果表，其中month是月份的数字（一月是1，二月是2，依此类推）。
返回结果格式如下例所示。

表：Drivers
| driver_id | join_date  |
|-----------|------------|
| 10        | 2019-12-10 |
| 8         | 2020-1-13  |
| 5         | 2020-2-16  |
| 7         | 2020-3-8   |
| 4         | 2020-5-17  |
| 1         | 2020-10-24 |
| 6         | 2021-1-5   |

表：Rides
| ride_id   | user_id   | requested_at |
|-----------|-----------|--------------|
| 6         | 75        | 2019-12-9    |
| 1         | 54        | 2020-2-9     |
| 10        | 63        | 2020-3-4     |
| 19        | 39        | 2020-4-6     |
| 3         | 41        | 2020-6-3     |
| 13        | 52        | 2020-6-22    |
| 7         | 69        | 2020-7-16    |
| 17        | 70        | 2020-8-25    |
| 20        | 81        | 2020-11-2    |
| 5         | 57        | 2020-11-9    |
| 2         | 42        | 2020-12-9    |
| 11        | 68        | 2021-1-11    |
| 15        | 32        | 2021-1-17    |
| 12        | 11        | 2021-1-19    |
| 14        | 18        | 2021-1-27    |

表：AcceptedRides
| ride_id | driver_id | ride_distance | ride_duration |
|---------|-----------|---------------|--------------|
| 10      | 10        | 63            | 38           |
| 13      | 10        | 73            | 96           |
| 7       | 8         | 100           | 28           |
| 17      | 7         | 119           | 68           |
| 20      | 1         | 121           | 92           |
| 5       | 7         | 42            | 101          |
| 2       | 4         | 6             | 38           |
| 11      | 8         | 37            | 43           |
| 15      | 8         | 108           | 82           |
| 12      | 8         | 38            | 34           |
| 14      | 1         | 90            | 74           |

结果表:
| month | active_drivers | accepted_rides |
|-------|----------------|----------------|
| 1     | 2              | 0              |
| 2     | 3              | 1              |
| 3     | 4              | 1              |
| 4     | 4              | 1              |
| 5     | 5              | 0              |
| 6     | 5              | 2              |
| 7     | 5              | 1              |
| 8     | 5              | 1              |
| 9     | 5              | 0              |
| 10    | 6              | 0              |
| 11    | 6              | 2              |
| 12    | 6              | 1              |

解释:
- 1月份：有2位活跃司机（10，8）和0次接受的行程。
- 2月份：有3位活跃司机（10，8，5）和1次接受的行程。
- 3月份：有4位活跃司机（10，8，5，7）和1次接受的行程。
- 4月份：有4位活跃司机（10，8，5，7）和1次接受的行程。
- 5月份：有5位活跃司机（10，8，5，7，4）和0次接受的行程。
- 6月份：有5位活跃司机（10，8，5，7，4）和2次接受的行程。
- 7月份：有5位活跃司机（10，8，5，7，4）和1次接受的行程。
- 8月份：有5位活跃司机（10，8，5，7，4）和1次接受的行程。
- 9月份：有5位活跃司机（10，8，5，7，4）和0次接受的行程。
- 10月份：有6位活跃司机（10，8，5，7，4，1）和0次接受的行程。
- 11月份：有6位活跃司机（10，8，5，7，4，1）和2次接受的行程。
- 12月份：有6位活跃司机（10，8，5，7，4，1）和1次接受的行程。
*/

-- xx
WITH Drivers AS (
  SELECT 10 AS driver_id, CAST('2019-12-10' AS date) AS join_date UNION ALL
  SELECT 8, CAST('2020-1-13' AS date) UNION ALL
  SELECT 5, CAST('2020-2-16' AS date) UNION ALL
  SELECT 7, CAST('2020-3-8' AS date) UNION ALL
  SELECT 4, CAST('2020-5-17' AS date) UNION ALL
  SELECT 1, CAST('2020-10-24' AS date) UNION ALL
  SELECT 6, CAST('2021-1-5' AS date)
),

Rides AS (
  SELECT 6 AS ride_id, 75 AS user_id, CAST('2019-12-9' AS date) AS requested_at UNION ALL
  SELECT 1, 54, CAST('2020-2-9' AS date) UNION ALL
  SELECT 10, 63, CAST('2020-3-4' AS date) UNION ALL
  SELECT 19, 39, CAST('2020-4-6' AS date) UNION ALL
  SELECT 3, 41, CAST('2020-6-3' AS date) UNION ALL
  SELECT 13, 52, CAST('2020-6-22' AS date) UNION ALL
  SELECT 7, 69, CAST('2020-7-16' AS date) UNION ALL
  SELECT 17, 70, CAST('2020-8-25' AS date) UNION ALL
  SELECT 20, 81, CAST('2020-11-2' AS date) UNION ALL
  SELECT 5, 57, CAST('2020-11-9' AS date) UNION ALL
  SELECT 2, 42, CAST('2020-12-9' AS date) UNION ALL
  SELECT 11, 68, CAST('2021-1-11' AS date) UNION ALL
  SELECT 15, 32, CAST('2021-1-17' AS date) UNION ALL
  SELECT 12, 11, CAST('2021-1-19' AS date) UNION ALL
  SELECT 14, 18, CAST('2021-1-27' AS date)
),

AcceptedRides AS (
  SELECT 10 AS ride_id, 10 AS driver_id, 63 AS ride_distance, 38 AS ride_duration UNION ALL
  SELECT 13, 10, 73, 96 UNION ALL
  SELECT 7, 8, 100, 28 UNION ALL
  SELECT 17, 7, 119, 68 UNION ALL
  SELECT 20, 1, 121, 92 UNION ALL
  SELECT 5, 7, 42, 101 UNION ALL
  SELECT 2, 4, 6, 38 UNION ALL
  SELECT 11, 8, 37, 43 UNION ALL
  SELECT 15, 8, 108, 82 UNION ALL
  SELECT 12, 8, 38, 34 UNION ALL
  SELECT 14, 1, 90, 74
)

/*
1. 月份维度表构建
2. 计算截止每月底活跃司机
3. 计算截止每月底接受的行程
*/
, dim_month AS (
    select
        t1.include_year,
        tmp.include_month,
        date_format(concat(t1.include_year,'-',tmp.include_month,'-01'),'yyyy-MM') year_month
        from (select '2020' include_year) t1
    lateral view posexplode(array(1,2,3,4,5,6,7,8,9,10,11,12)) tmp as pos, include_month
),
    active_drivers AS (
        select
            t1.year_month,
            -- 截止每月底司机总数 = 以往每月入职司机数量总和
            sum(coalesce(t2.active_drivers,0)) active_drivers
        from dim_month t1
        left join (
            -- 每月入职司机
            select
                date_format(join_date,'yyyy-MM') join_month,
                count(distinct driver_id) active_drivers
            from Drivers t1
            where year(join_date) <= 2020
            group by date_format(join_date,'yyyy-MM')
        ) t2
            -- 截止每月底司机总数过滤条件
        on t2.join_month <= t1.year_month
        group by t1.year_month
    ),
    accepted_rides AS (
        select
            date_format(t1.requested_at, 'yyyy-MM') accept_month,
            count(distinct t2.ride_id) accepted_rides
        from Rides t1
        left join AcceptedRides t2
        on t1.ride_id = t2.ride_id
        where t2.ride_id is not null and year(t1.requested_at) = 2020
        group by date_format(t1.requested_at, 'yyyy-MM')
    )
select
    case
        when t1.year_month = '2020-01' then 1
        when t1.year_month = '2020-02' then 2
        when t1.year_month = '2020-03' then 3
        when t1.year_month = '2020-04' then 4
        when t1.year_month = '2020-05' then 5
        when t1.year_month = '2020-06' then 6
        when t1.year_month = '2020-07' then 7
        when t1.year_month = '2020-08' then 8
        when t1.year_month = '2020-09' then 9
        when t1.year_month = '2020-10' then 10
        when t1.year_month = '2020-11' then 11
        when t1.year_month = '2020-12' then 12
    end month,
    t1.active_drivers,
    coalesce(t2.accepted_rides,0) accepted_rides
from active_drivers t1
left join accepted_rides t2
on t1.year_month = t2.accept_month
order by month;

~~~



##  司机接受乘车次数，系列题目2

~~~sql
/*

表: `Drivers`
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| driver_id   | int     |
| join_date   | date    |
+-------------+---------+
driver_id 是该表具有唯一值的列。
该表的每一行均包含驾驶员的ID以及他们加入 Hopper 公司的日期。

表: `Rides`
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| ride_id      | int     |
| user_id      | int     |
| requested_at | date    |
+--------------+---------+
ride_id 是该表具有唯一值的列。
该表的每一行均包含行程 ID(ride_id)，用户 ID(user_id) 以及该行程的日期 (requested_at)。
该表中可能有一些不被接受的乘车请求。

表: `AcceptedRides`
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| ride_id       | int     |
| driver_id     | int     |
| ride_distance | int     |
| ride_duration | int     |
+---------------+---------+
ride_id 是该表具有唯一值的列。
该表的每一行都包含已接受的行程信息。
表中的行程信息都在 "Rides" 表中存在。

编写解决方案以报告 2020 年每个月的工作驱动因素 百分比 (working_percentage)，其中：
注意：如果一个月内可用驾驶员的数量为零，我们认为 working_percentage 为 0。
返回按 month 升序 排列的结果表，其中 month 是月份的编号 (一月是 1，二月是 2, 等等)。将 working_percentage 四舍五入至 小数点后两位。
结果格式如下例所示。

示例 1:

输入:
表 `Drivers`:
+-----------+------------+
| driver_id | join_date  |
+-----------+------------+
| 10        | 2019-12-10 |
| 8         | 2020-1-13  |
| 5         | 2020-2-16  |
| 7         | 2020-3-8   |
| 4         | 2020-5-17  |
| 1         | 2020-10-24 |
| 6         | 2021-1-5   |
+-----------+------------+
表 `Rides`:
+---------+---------+--------------+
| ride_id | user_id | requested_at |
+---------+---------+--------------+
| 6       | 75      | 2019-12-9    |
| 1       | 54      | 2020-2-9     |
| 10      | 63      | 2020-3-4     |
| 19      | 39      | 2020-4-6     |
| 3       | 41      | 2020-6-3     |
| 13      | 52      | 2020-6-22    |
| 7       | 69      | 2020-7-16    |
| 17      | 70      | 2020-8-25    |
| 20      | 81      | 2020-11-2    |
| 5       | 57      | 2020-11-9    |
| 2       | 42      | 2020-12-9    |
| 11      | 68      | 2021-1-11    |
| 15      | 32      | 2021-1-17    |
| 12      | 11      | 2021-1-19    |
| 14      | 18      | 2021-1-27    |
+---------+---------+--------------+
表 `AcceptedRides`:
+---------+-----------+---------------+---------------+
| ride_id | driver_id | ride_distance | ride_duration |
+---------+-----------+---------------+---------------+
| 10      | 10        | 63            | 38            |
| 13      | 10        | 73            | 96            |
| 7       | 8         | 100           | 28            |
| 17      | 7         | 119           | 68            |
| 20      | 1         | 121           | 92            |
| 5       | 7         | 42            | 101           |
| 2       | 4         | 6             | 38            |
| 11      | 8         | 37            | 43            |
| 15      | 8         | 108           | 82            |
| 12      | 8         | 38            | 34            |
| 14      | 1         | 90            | 74            |
+---------+-----------+---------------+---------------+
输出:
+-------+--------------------+
| month | working_percentage |
+-------+--------------------+
| 1     | 0.00               |
| 2     | 0.00               |
| 3     | 25.00              |
| 4     | 0.00               |
| 5     | 0.00               |
| 6     | 20.00              |
| 7     | 20.00              |
| 8     | 20.00              |
| 9     | 0.00               |
| 10    | 0.00               |
| 11    | 33.33              |
| 12    | 16.67              |
+-------+--------------------+
解释:
截至 1 月底 --> 2 个活跃的驾驶员 (10, 8)，无被接受的行程。百分比是0%。
截至 2 月底 --> 3 个活跃的驾驶员 (10, 8, 5)，无被接受的行程。百分比是0%。
截至 3 月底 --> 4 个活跃的驾驶员 (10, 8, 5, 7)，1 个被接受的行程 (10)。百分比是 (1 / 4) * 100 = 25%。
截至 4 月底 --> 4 个活跃的驾驶员 (10, 8, 5, 7)，无被接受的行程。百分比是 0%。
截至 5 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，无被接受的行程。百分比是 0%。
截至 6 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，1 个被接受的行程 (10)。百分比是 (1 / 5) * 100 = 20%。
截至 7 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，1 个被接受的行程 (8)。百分比是 (1 / 5) * 100 = 20%。
截至 8 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，1 个被接受的行程 (7)。百分比是 (1 / 5) * 100 = 20%。
截至 9 月底 --> 5 个活跃的驾驶员 (10, 8, 5, 7, 4)，无被接受的行程。百分比是 0%。
截至 10 月底 --> 6 个活跃的驾驶员 (10, 8, 5, 7, 4, 1)，无被接受的行程。百分比是 0%。
截至 11 月底 --> 6 个活跃的驾驶员 (10, 8, 5, 7, 4, 1)，2 个被接受的行程 (1, 7)。百分比是 (2 / 6) * 100 = 33.33%。
截至 12 月底 --> 6 个活跃的驾驶员 (10, 8, 5, 7, 4, 1)，1 个被接受的行程 (4)。百分比是 (1 / 6) * 100 = 16.67%。

*/

/*
1. 截止2020年每月底的活跃司机数
2. 2020年每月的接受行程数
3. / 并四舍五入处理，按照month升序
*/


WITH
-- 1. 模拟 Drivers 表 (使用 UNION ALL 语法)
Drivers AS (SELECT 10 AS driver_id, CAST('2019-12-10' AS DATE) AS join_date
            UNION ALL
            SELECT 8, CAST('2020-01-13' AS DATE)
            UNION ALL
            SELECT 5, CAST('2020-02-16' AS DATE)
            UNION ALL
            SELECT 7, CAST('2020-03-08' AS DATE)
            UNION ALL
            SELECT 4, CAST('2020-05-17' AS DATE)
            UNION ALL
            SELECT 1, CAST('2020-10-24' AS DATE)
            UNION ALL
            SELECT 6, CAST('2021-01-05' AS DATE)),

-- 2. 模拟 Rides 表 (使用 UNION ALL 语法)
Rides AS (SELECT 6 AS ride_id, 75 AS user_id, CAST('2019-12-09' AS DATE) AS requested_at
          UNION ALL
          SELECT 1, 54, CAST('2020-02-09' AS DATE)
          UNION ALL
          SELECT 10, 63, CAST('2020-03-04' AS DATE)
          UNION ALL
          SELECT 19, 39, CAST('2020-04-06' AS DATE)
          UNION ALL
          SELECT 3, 41, CAST('2020-06-03' AS DATE)
          UNION ALL
          SELECT 13, 52, CAST('2020-06-22' AS DATE)
          UNION ALL
          SELECT 7, 69, CAST('2020-07-16' AS DATE)
          UNION ALL
          SELECT 17, 70, CAST('2020-08-25' AS DATE)
          UNION ALL
          SELECT 20, 81, CAST('2020-11-02' AS DATE)
          UNION ALL
          SELECT 5, 57, CAST('2020-11-09' AS DATE)
          UNION ALL
          SELECT 2, 42, CAST('2020-12-09' AS DATE)
          UNION ALL
          SELECT 11, 68, CAST('2021-01-11' AS DATE)
          UNION ALL
          SELECT 15, 32, CAST('2021-01-17' AS DATE)
          UNION ALL
          SELECT 12, 11, CAST('2021-01-19' AS DATE)
          UNION ALL
          SELECT 14, 18, CAST('2021-01-27' AS DATE)),

-- 3. 模拟 AcceptedRides 表 (使用 UNION ALL 语法)
AcceptedRides AS (SELECT 10 AS ride_id, 10 AS driver_id, 63 AS ride_distance, 38 AS ride_duration
                  UNION ALL
                  SELECT 13, 10, 73, 96
                  UNION ALL
                  SELECT 7, 8, 100, 28
                  UNION ALL
                  SELECT 17, 7, 119, 68
                  UNION ALL
                  SELECT 20, 1, 121, 92
                  UNION ALL
                  SELECT 5, 7, 42, 101
                  UNION ALL
                  SELECT 2, 4, 6, 38
                  UNION ALL
                  SELECT 11, 8, 37, 43
                  UNION ALL
                  SELECT 15, 8, 108, 82
                  UNION ALL
                  SELECT 12, 8, 38, 34
                  UNION ALL
                  SELECT 14, 1, 90, 74),
dim_2020_month as (
    -- 查询出2020年每月的最后一天，比如 2020-06-30
    select
        pos + 1 month_number,
        last_day(to_date(concat('2020','-',lpad(val,2,'0'),'-01')) )last_day
    from (select posexplode(`array`(1,2,3,4,5,6,7,8,9,10,11,12))) t1
),
-- 2020年截止每月底的活跃司机数
active_drivers as (
    select
        t1.month_number,
        t1.last_day,
        count(distinct t2.driver_id) acc_active_drivers
    from dim_2020_month t1
             left join Drivers t2
                       on t1.last_day >= t2.join_date
    group by t1.month_number, t1.last_day
),
-- 2020年每月的接受的行程数
accept_rides as (
    select
        last_day(requested_at) last_day,
        count(1) accepts_rides
    from AcceptedRides t1
             left join Rides t2
                       on t1.ride_id = t2.ride_id
    where year(t2.requested_at) = 2020 and t2.ride_id is not null
    group by last_day(requested_at)
)
select
    t1.month_number,
    round(nvl(t2.accepts_rides,0) / t1.acc_active_drivers * 100, 2)  working_percentage
from active_drivers t1
         left join accept_rides t2
                   on t1.last_day  = t2.last_day
order by t1.month_number;

~~~



## 司机接受乘车次数，系列题目3

>题目解析有问题，忽略，以解答sql为准

~~~sql
/*
表: `Drivers`
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| driver_id   | int     |
| join_date   | date    |
+-------------+---------+
`driver_id` 是该表具有唯一值的列。
该表的每一行均包含驾驶员的 ID 以及他们加入 Hopper 公司的日期。

表: `Rides`
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| ride_id      | int     |
| user_id      | int     |
| requested_at | date    |
+--------------+---------+
`ride_id` 是该表具有唯一值的列。
该表的每一行均包含行程 ID(ride_id)，用户 ID(user_id) 以及该行程的日期 (requested_at)。
该表中可能有一些不被接受的乘车请求。

表: `AcceptedRides`
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| ride_id       | int     |
| driver_id     | int     |
| ride_distance | int     |
| ride_duration | int     |
+---------------+---------+
`ride_id` 是该表具有唯一值的列。
该表的每一行都包含已接受的行程信息。
表中的行程信息都在 "Rides" 表中存在。

编写一个解决方案，计算出从 `2020 年 1 月至 3 月` 至 `2020 年 10 月至 12 月` 的每三个月窗口的 `average_ride_distance` 和 `average_ride_duration`。
并将 `average_ride_distance` 和 `average_ride_duration` 四舍五入至 小数点后两位。
通过将三个月的总 `ride_distance` 相加并除以 `3` 来计算 `average_ride_distance`。`average_ride_duration` 的计算方法与此类似。

返回按 `month` 升序排列的结果表，其中 `month` 是起始月份的编号 (一月为 1, 二月为 2 ...)。
查询结果格式如下示例所示。

示例 1:

输入:
`Drivers table`:
+-----------+------------+
| driver_id | join_date  |
+-----------+------------+
| 10        | 2019-12-10 |
| 8         | 2020-1-13  |
| 5         | 2020-2-16  |
| 7         | 2020-3-8   |
| 4         | 2020-5-17  |
| 1         | 2020-10-24 |
| 6         | 2021-1-5   |
+-----------+------------+
`Rides table`:
+---------+---------+--------------+
| ride_id | user_id | requested_at |
+---------+---------+--------------+
| 6       | 75      | 2019-12-9    |
| 1       | 54      | 2020-2-9     |
| 10      | 63      | 2020-3-4     |
| 19      | 39      | 2020-4-6     |
| 3       | 41      | 2020-6-3     |
| 13      | 52      | 2020-6-22    |
| 7       | 69      | 2020-7-16    |
| 17      | 70      | 2020-8-25    |
| 20      | 81      | 2020-11-2    |
| 5       | 57      | 2020-11-9    |
| 2       | 42      | 2020-12-9    |
| 11      | 68      | 2021-1-11    |
| 15      | 32      | 2021-1-17    |
| 12      | 11      | 2021-1-19    |
| 14      | 18      | 2021-1-27    |
+---------+---------+--------------+
`AcceptedRides table`:
+---------+-----------+---------------+---------------+
| ride_id | driver_id | ride_distance | ride_duration |
+---------+-----------+---------------+---------------+
| 10      | 10        | 63            | 38            |
| 13      | 10        | 73            | 96            |
| 7       | 8         | 100           | 28            |
| 17      | 7         | 119           | 68            |
| 20      | 1         | 121           | 92            |
| 5       | 7         | 42            | 101           |
| 2       | 4         | 6             | 38            |
| 11      | 8         | 37            | 43            |
| 15      | 8         | 108           | 82            |
| 12      | 8         | 38            | 34            |
| 14      | 1         | 90            | 74            |
+---------+-----------+---------------+---------------+
输出:
+-------+-----------------------+-------------------------+
| month | average_ride_distance | average_ride_duration   |
+-------+-----------------------+-------------------------+
| 1     | 21.00                 | 12.67                   |
| 2     | 21.00                 | 12.67                   |
| 3     | 21.00                 | 12.67                   |
| 4     | 24.33                 | 32.00                   |
| 5     | 57.67                 | 41.33                   |
| 6     | 97.33                 | 64.00                   |
| 7     | 73.00                 | 32.00                   |
| 8     | 39.67                 | 22.67                   |
| 9     | 54.33                 | 64.33                   |
| 10    | 56.33                 | 77.00                   |
+-------+-----------------------+-------------------------+
解释:
到1月底-->平均骑行距离= (0+0+63)/3=21, 平均骑行持续时间= (0+0+38)/3=12.67
到2月底-->平均骑行距离= (0+63+0)/3=21, 平均骑行持续时间= (0+38+0)/3=12.67
到3月底-->平均骑行距离= (63+0+0)/3=21, 平均骑行持续时间= (38+0+0)/3=12.67
到4月底-->平均骑行距离= (0+0+73)/3=24.33, 平均骑行持续时间= (0+0+96)/3=32.00
到5月底-->平均骑行距离= (0+73+100)/3=57.67, 平均骑行持续时间= (0+96+28)/3=41.33
到6月底-->平均骑行距离= (73+100+119)/3=97.33, 平均骑行持续时间= (96+28+68)/3=64.00
到7月底-->平均骑行距离= (100+119+0)/3=73.00, 平均骑行持续时间= (28+68+0)/3=32.00
到8月底-->平均骑行距离= (119+0+0)/3=39.67, 平均骑行持续时间= (68+0+0)/3=22.67
到9月底-->平均骑行距离= (0+0+163)/3=54.33, 平均骑行持续时间= (0+0+193)/3=64.33
到10月底-->平均骑行距离= (0+163+6)/3=56.33, 平均骑行持续时间= (0+193+38)/3=77.00
*/




WITH
-- 1. 模拟 Drivers 表
Drivers AS (
    SELECT 10 AS driver_id, CAST('2019-12-10' AS DATE) AS join_date UNION ALL
    SELECT 8,  CAST('2020-01-13' AS DATE) UNION ALL
    SELECT 5,  CAST('2020-02-16' AS DATE) UNION ALL
    SELECT 7,  CAST('2020-03-08' AS DATE) UNION ALL
    SELECT 4,  CAST('2020-05-17' AS DATE) UNION ALL
    SELECT 1,  CAST('2020-10-24' AS DATE) UNION ALL
    SELECT 6,  CAST('2021-01-05' AS DATE)
),

-- 2. 模拟 Rides 表
Rides AS (
    SELECT 6 AS ride_id, 75 AS user_id, CAST('2019-12-09' AS DATE) AS requested_at UNION ALL
    SELECT 1,  54, CAST('2020-02-09' AS DATE) UNION ALL
    SELECT 10, 63, CAST('2020-03-04' AS DATE) UNION ALL
    SELECT 19, 39, CAST('2020-04-06' AS DATE) UNION ALL
    SELECT 3,  41, CAST('2020-06-03' AS DATE) UNION ALL
    SELECT 13, 52, CAST('2020-06-22' AS DATE) UNION ALL
    SELECT 7,  69, CAST('2020-07-16' AS DATE) UNION ALL
    SELECT 17, 70, CAST('2020-08-25' AS DATE) UNION ALL
    SELECT 20, 81, CAST('2020-11-02' AS DATE) UNION ALL
    SELECT 5,  57, CAST('2020-11-09' AS DATE) UNION ALL
    SELECT 2,  42, CAST('2020-12-09' AS DATE) UNION ALL
    SELECT 11, 68, CAST('2021-01-11' AS DATE) UNION ALL
    SELECT 15, 32, CAST('2021-01-17' AS DATE) UNION ALL
    SELECT 12, 11, CAST('2021-01-19' AS DATE) UNION ALL
    SELECT 14, 18, CAST('2021-01-27' AS DATE)
),

-- 3. 模拟 AcceptedRides 表
AcceptedRides AS (
    SELECT 10 AS ride_id, 10 AS driver_id, 63 AS ride_distance, 38 AS ride_duration UNION ALL
    SELECT 13, 10, 73,  96  UNION ALL
    SELECT 7,  8,  100, 28  UNION ALL
    SELECT 17, 7,  119, 68  UNION ALL
    SELECT 20, 1,  121, 92  UNION ALL
    SELECT 5,  7,  42,  101 UNION ALL
    SELECT 2,  4,  6,   38  UNION ALL
    SELECT 11, 8,  37,  43  UNION ALL
    SELECT 15, 8,  108, 82  UNION ALL
    SELECT 12, 8,  38,  34  UNION ALL
    SELECT 14, 1,  90,  74
),
/*
1. 过滤出需要的数据
2. 每个月的行程数和 总耗时，总里程数
3. 窗口函数即可
*/
dim_2020_month as (
-- 查询出2020年每月的最后一天，比如 2020-06-30
    select
        pos + 1 month_number,
        last_day(to_date(concat('2020','-',lpad(val,2,'0'),'-01')) )last_day
    from (select posexplode(`array`(1,2,3,4,5,6,7,8,9,10,11,12))) t1
    union all
    select null,last_day('2019-11-01')
    union all
    select null,last_day('2019-12-01')
),
base_data as (
    select
        last_day(t1.requested_at) last_day,
        sum(t2.ride_distance) month_distance,
        sum(t2.ride_duration) month_duration
    from Rides t1
             left join AcceptedRides t2
                       on t1.ride_id = t2.ride_id
    where t2.ride_id is not null and  t1.requested_at >= to_date('2019-11-01') and t1.requested_at <= to_date('2020-12-31')
    group by last_day(t1.requested_at)
)
select
    t1.month_number,
    round(average_ride_distance1,2) average_ride_distance,
    round(average_ride_duration1,2) average_ride_duration
from (
         select
             t1.month_number,
             t1.last_day,
             avg(nvl(t2.month_distance,0)) over(order by t1.last_day rows between 2 preceding and current row ) average_ride_distance1,
             avg(nvl(t2.month_duration,0)) over(order by t1.last_day rows between 2 preceding and current row ) average_ride_duration1

         from dim_2020_month t1
                  left join base_data t2
                            on t1.last_day = t2.last_day
     ) t1
where t1.month_number is not null
~~~



## 每日每种商品购买清单（简单的行转列)



~~~sql

/*
每日每种商品购买清单（简单的行转列)

表: `Orders`
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| order_id    | int     |
| customer_id | int     |
| order_date  | date    |
| item_id     | varchar |
| quantity    | int     |
+-------------+---------+
(order_id, item_id) 是该表主键(具有唯一值的列的组合)
该表包含了订单信息
order_date 是id为 item_id 的商品被id为 customer_id 的消费者订购的日期。

表: `Items`
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| item_id       | varchar |
| item_name     | varchar |
| item_category | varchar |
+---------------+---------+
item_id 是该表主键(具有唯一值的列)
item_name 是商品的的名字
item_category 是商品的类别

你是企业主，想要获得分类商品和周内每天的销售报告。
编写解决方案，报告 周内每天 每个商品类别下订购了多少单位。
返回结果表 按商品类别排序。
结果格式如下例所示。

示例 1:

输入:
`Orders` 表:
+----------+-------------+------------+---------+----------+
| order_id | customer_id | order_date | item_id | quantity |
+----------+-------------+------------+---------+----------+
| 1        | 1           | 2020-06-01 | 1       | 10       |
| 2        | 1           | 2020-06-08 | 2       | 10       |
| 3        | 2           | 2020-06-02 | 1       | 5        |
| 4        | 3           | 2020-06-03 | 3       | 5        |
| 5        | 4           | 2020-06-04 | 4       | 1        |
| 6        | 4           | 2020-06-05 | 5       | 5        |
| 7        | 5           | 2020-06-05 | 1       | 10       |
| 8        | 5           | 2020-06-14 | 4       | 5        |
| 9        | 5           | 2020-06-21 | 3       | 5        |
+----------+-------------+------------+---------+----------+
`Items` 表:
+---------+-----------------+---------------+
| item_id | item_name       | item_category |
+---------+-----------------+---------------+
| 1       | LC Alg. Book    | Book          |
| 2       | LC DB. Book     | Book          |
| 3       | LC SmarthPhone  | Phone         |
| 4       | LC Phone        | Phone         |
| 5       | LC SmartGlass   | Glasses       |
| 6       | LC T-Shirt XL   | T-Shirt       |
+---------+-----------------+---------------+
输出:
+----------+--------+---------+-----------+----------+--------+----------+--------+
| Category | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday | Sunday |
+----------+--------+---------+-----------+----------+--------+----------+--------+
| Book     | 20     | 5       | 0         | 0        | 10     | 0        | 0      |
| Glasses  | 0      | 0       | 0         | 0        | 5      | 0        | 0      |
| Phone    | 0      | 0       | 5         | 1        | 0      | 0        | 10     |
| T-Shirt  | 0      | 0       | 0         | 0        | 0      | 0        | 0      |
+----------+--------+---------+-----------+----------+--------+----------+--------+
解释:
在周一(2020-06-01, 2020-06-08), Book分类(ids: 1, 2)下，总共销售了20个单位(10 + 10)
在周二(2020-06-02), Book分类(ids: 1, 2)下，总共销售了5个单位
在周三(2020-06-03), Phone分类(ids: 3, 4)下，总共销售了5个单位
在周四(2020-06-04), Phone分类(ids: 3, 4)下，总共销售了1个单位
在周五(2020-06-05), Book分类(ids: 1, 2)下, 总共销售了10个单位, Glasses分类(ids: 5)下，总共销售了5个单位
在周六, 没有商品销售
在周天(2020-06-14, 2020-06-21), Phone分类(ids: 3, 4)下，总共销售了10个单位(5 + 5)
没有销售 T-Shirt 类别的商品

*/

WITH
-- 1. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, 1 AS customer_id, CAST('2020-06-01' AS DATE) AS order_date, '1' AS item_id, 10 AS quantity UNION ALL
    SELECT 2, 1, CAST('2020-06-08' AS DATE), '2', 10 UNION ALL
    SELECT 3, 2, CAST('2020-06-02' AS DATE), '1', 5  UNION ALL
    SELECT 4, 3, CAST('2020-06-03' AS DATE), '3', 5  UNION ALL
    SELECT 5, 4, CAST('2020-06-04' AS DATE), '4', 1  UNION ALL
    SELECT 6, 4, CAST('2020-06-05' AS DATE), '5', 5  UNION ALL
    SELECT 7, 5, CAST('2020-06-05' AS DATE), '1', 10 UNION ALL
    SELECT 8, 5, CAST('2020-06-14' AS DATE), '4', 5  UNION ALL
    SELECT 9, 5, CAST('2020-06-21' AS DATE), '3', 5
),

-- 2. 模拟 Items 表
Items AS (
    SELECT '1' AS item_id, 'LC Alg. Book' AS item_name, 'Book' AS item_category UNION ALL
    SELECT '2', 'LC DB. Book', 'Book' UNION ALL
    SELECT '3', 'LC SmarthPhone', 'Phone' UNION ALL
    SELECT '4', 'LC Phone', 'Phone' UNION ALL
    SELECT '5', 'LC SmartGlass', 'Glasses' UNION ALL
    SELECT '6', 'LC T-Shirt XL', 'T-Shirt'
),
    -- 商品类别维度表
dim_item_category AS (
    SELECT DISTINCT item_category
    FROM Items
),
weekly_quantity as (
--  行转列
    select
        t1.item_category,
        sum(case weekday when 1 then weekday_quantity else 0 end) monday,
        sum(case weekday when 2 then weekday_quantity else 0 end) tuesday,
        sum(case weekday when 3 then weekday_quantity else 0 end) wesdnesday,
        sum(case weekday when 4 then weekday_quantity else 0 end) thursday,
        sum(case weekday when 5 then weekday_quantity else 0 end) friday,
        sum(case weekday when 6 then weekday_quantity else 0 end) saturday,
        sum(case weekday when 7 then weekday_quantity else 0 end) sunday
    from (
             -- 计算每个商品类别在每个星期几的销售数量
             select
                 t2.item_category,
                 date_format(t1.order_date,'u') weekday,
                 sum(coalesce(t1.quantity,0)) weekday_quantity
             from Orders t1
                      left join Items t2
                                on t1.item_id = t2.item_id
             group by t2.item_category,date_format(t1.order_date,'u')

         ) t1
    group by t1.item_category
)
select
    t1.item_category,
    coalesce(t2.monday,0) monday,
    coalesce(t2.tuesday,0) tuesday,
    coalesce(t2.wesdnesday,0) wesdnesday,
    coalesce(t2.thursday,0) thursday,
    coalesce(t2.friday,0) friday,
    coalesce(t2.saturday,0) saturday,
    coalesce(t2.sunday,0) sunday
from dim_item_category t1
left join weekly_quantity t2
on t1.item_category = t2.item_category
order by t1.item_category;



~~~


1.  **函数基本功能**
    `date_format` 是 Hive SQL 中一个核心的日期时间处理函数。它的主要作用是将一个 `DATE`（日期）、`TIMESTAMP`（时间戳）或者符合标准格式的 `STRING`（字符串）类型的数据，按照您指定的格式，转换成一个新的字符串。此函数的格式化规则完全遵循 Java 的 `java.text.SimpleDateFormat` 规范。

2.  **函数语法**
    
    ```sql
    date_format(date|timestamp|string, format_string)
    ```
    
3.  **参数说明**
    *   **`date|timestamp|string`**：这是第一个参数，代表您想要进行格式化的原始日期/时间数据。
    *   **`format_string`**：这是第二个参数，是一个字符串，用于定义输出结果的格式。您可以通过组合不同的格式化字符来构建这个模板。

4.  **格式化字符 (`format_string`) 详细列表**
    下表列出了所有可用于 `format_string` 的字符。这些字符是**大小写敏感**的。为了方便演示，我们假设当前时间为 **`2023年10月26日 星期四, 下午 14:08:05.123`**，时区为 `Asia/Shanghai` (CST, +0800)。

| 格式化字符 (Pattern) | 说明                                            | 示例 (Example)                                               |
| :------------------- | :---------------------------------------------- | :----------------------------------------------------------- |
| **`G`**              | **纪元/时代** (Era designator)                  | `AD` (公元)                                                  |
| **`y`**              | **年份** (Year)                                 | `yy` -> `23`<br>`yyyy` -> `2023`                             |
| **`M`**              | **月份** (Month in year) (注意：**大写M**！)    | `M` -> `10`<br>`MM` -> `10`<br>`MMM` -> `Oct`<br>`MMMM` -> `October` |
| **`w`**              | **一年中的第几周** (Week in year)               | `43`                                                         |
| **`W`**              | **一月中的第几周** (Week in month)              | `4`                                                          |
| **`D`**              | **一年中的第几天** (Day in year)                | `299`                                                        |
| **`d`**              | **一月中的第几天 (日)** (Day in month)          | `d` -> `26`<br>`dd` -> `26`                                  |
| **`F`**              | **一月中的第几个星期几** (Day of week in month) | `4` (10月的第4个星期四)                                      |
| **`E`**              | **星期几的名称** (Day name in week)             | `E` / `EE` / `EEE` -> `Thu`<br>`EEEE` -> `Thursday`          |
| **`u`**              | **一周中的第几天 (ISO 8601)** (1=周一, 7=周日)  | `4`                                                          |
| **`a`**              | **上午/下午标记** (Am/pm marker)                | `PM`                                                         |
| **`H`**              | **一天中的小时 (0-23)** (24小时制)              | `H` -> `14`<br>`HH` -> `14`                                  |
| **`k`**              | **一天中的小时 (1-24)** (24小时制)              | `k` -> `14`<br>`kk` -> `14`                                  |
| **`K`**              | **上午/下午的小时 (0-11)** (12小时制)           | `K` -> `2`<br>`KK` -> `02`                                   |
| **`h`**              | **上午/下午的小时 (1-12)** (12小时制)           | `h` -> `2`<br>`hh` -> `02`                                   |
| **`m`**              | **分钟** (Minute in hour) (注意：**小写m**！)   | `m` -> `8`<br>`mm` -> `08`                                   |
| **`s`**              | **秒** (Second in minute)                       | `s` -> `5`<br>`ss` -> `05`                                   |
| **`S`**              | **毫秒** (Millisecond)                          | `123`                                                        |
| **`z`**              | **通用时区** (General time zone)                | `z` -> `CST`<br>`zzzz` -> `China Standard Time`              |
| **`Z`**              | **RFC 822 时区**                                | `+0800`                                                      |
| **`X`**              | **ISO 8601 时区**                               | `X` -> `+08`<br>`XX` -> `+0800`<br>`XXX` -> `+08:00`         |

5.  **关键要点和最佳实践**
    *   **大小写极其敏感**：`yyyy-MM-dd` 代表 `年-月-日`，而 `yyyy-mm-dd` 代表 `年-分钟-日`，后者通常是错误的用法。
    *   **字符重复次数的影响**：
        *   对于**数字**（如年、月、日），重复次数决定了输出的最小位数，不足时会用`0`在左侧填充。例如，`m` 对于8分钟输出 `8`，而 `mm` 输出 `08`。
        *   对于**文本**（如星期、月份），重复次数决定了是使用缩写还是完整形式。例如，`E` 输出 `Thu`，而 `EEEE` 输出 `Thursday`。
    *   **处理文本字面量**：如果您想在格式化字符串中包含固定的字母文本（如 `T` 或 `Z`），必须用**单引号 `''`** 将它们括起来，以防止它们被解析为格式化字符。
        ```sql
        -- 输出ISO 8601标准格式，'T'被单引号包裹
        SELECT date_format('2023-10-26 14:00:00', "yyyy-MM-dd'T'HH:mm:ss");
        -- 结果: '2023-10-26T14:00:00'
        ```

6.  **Hive 使用场景示例**
    *   **获取标准日期格式 `yyyy-MM-dd`**
        ```sql
        SELECT date_format(current_timestamp(), 'yyyy-MM-dd');
        -- 结果: '2023-10-26' (取决于执行日期)
        ```
    *   **获取年月 `yyyy-MM`，常用于按月分区或聚合**
        ```sql
        SELECT date_format('2023-05-15', 'yyyy-MM');
        -- 结果: '2023-05'
        ```
    *   **获取完整的、带毫秒和时区的格式**
        ```sql
        SELECT date_format(current_timestamp(), "yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
        -- 结果 (示例): '2023-10-26T14:08:05.123+08:00'
        ```
    *   **获取年份和一年中的周数**
        ```sql
        SELECT date_format('2023-01-10', 'yyyy-w');
        -- 结果: '2023-2'
        ```
    *   **获取带星期几的全格式日期**
        ```sql
        SELECT date_format('2023-10-26', 'EEEE, MMMM dd, yyyy');
        -- 结果: 'Thursday, October 26, 2023'
        ```
    *   **生成中文格式的日期时间**
        ```sql
        SELECT date_format('2023-10-26 14:08:05', "yyyy'年'M'月'd'日' H'时'm'分's'秒'");
        -- 结果: '2023年10月26日 14时8分5秒'
        ```





## 日平均销售额（需要有时间维度表，和平均绩效等挂钩）



![image-20250714112902346](https://5201969.xyz/api/public/img/69ffb1a74eaac3fc6d2501b378e03fdd)

~~~sql
/*
Product 表:
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| product_id    | int     |
| product_name  | varchar |
+---------------+---------+
product_id 是这张表的主键(具有唯一值的列)。
product_name 是产品的名称。

Sales 表:
+---------------------+---------+
| Column Name         | Type    |
+---------------------+---------+
| product_id          | int     |
| period_start        | date    |
| period_end          | date    |
| average_daily_sales | int     |
+---------------------+---------+
product_id 是这张表的主键(具有唯一值的列)。
period_start 和 period_end 是该产品销售期的起始日期和结束日期, 且这两个日期包含在销售期内。
average_daily_sales 列存储销售期内该产品的日平均销售额。
销售日期范围为2018年到2020年。

编写解决方案, 找出每个产品每年的总销售额, 并包含 `product_id`, `product_name`, `report_year` 以及 `total_amount`。
返回结果并按 `product_id` 和 `report_year` 排序。
返回结果格式如下例所示。

示例 1:

输入:
`Product table`:
+------------+---------------+
| product_id | product_name  |
+------------+---------------+
| 1          | LC Phone      |
| 2          | LC T-Shirt    |
| 3          | LC Keychain   |
+------------+---------------+
`Sales table`:
+------------+--------------+-------------+---------------------+
| product_id | period_start | period_end  | average_daily_sales |
+------------+--------------+-------------+---------------------+
| 1          | 2019-01-25   | 2019-02-28  | 100                 |
| 2          | 2018-12-01   | 2020-01-01  | 10                  |
| 3          | 2019-12-01   | 2020-01-31  | 1                   |
+------------+--------------+-------------+---------------------+
输出:
+------------+---------------+--------------+--------------+
| product_id | product_name  | report_year  | total_amount |
+------------+---------------+--------------+--------------+
| 1          | LC Phone      | 2019         | 3500         |
| 2          | LC T-Shirt    | 2018         | 310          |
| 2          | LC T-Shirt    | 2019         | 3650         |
| 2          | LC T-Shirt    | 2020         | 10           |
| 3          | LC Keychain   | 2019         | 31           |
| 3          | LC Keychain   | 2020         | 31           |
+------------+---------------+--------------+--------------+
解释:
LC Phone 在 2019-01-25 至 2019-02-28 期间销售, 该产品销售时间总计35天。销售总额 35*100 = 3500。
LC T-shirt 在 2018-12-01 至 2020-01-01 期间销售, 该产品在2018年、2019年、2020年的销售时间分别是31天、365天、1天, 2018年、2019年、2020年的销售总额分别是31*10=310、365*10=3650、1*10=10。
LC Keychain 在 2019-12-01 至 2020-01-31 期间销售, 该产品在2019年、2020年的销售时间分别是: 31天, 31天, 2019年、2020年的销售总额分别是31*1=31、31*1=31。

*/

WITH
-- 1. 模拟 Product 表
Product AS (
    SELECT 1 AS product_id, 'LC Phone' AS product_name UNION ALL
    SELECT 2, 'LC T-Shirt' UNION ALL
    SELECT 3, 'LC Keychain'
),

-- 2. 模拟 Sales 表
Sales AS (
    SELECT 1 AS product_id, CAST('2019-01-25' AS DATE) AS period_start, CAST('2019-02-28' AS DATE) AS period_end, 100 AS average_daily_sales UNION ALL
    SELECT 2, CAST('2018-12-01' AS DATE), CAST('2020-01-01' AS DATE), 10 UNION ALL
    SELECT 3, CAST('2019-12-01' AS DATE), CAST('2020-01-31' AS DATE), 1
),
    year_salses AS (
        --计算每年销售总额
        select
            t3.product_id,
            t3.report_year,
            CASE
                -- 如果报告年份小于销售期开始年份, 则总额为0
                WHEN report_year < year(period_start) THEN 0
                -- 如果报告年份大于销售期结束年份, 则总额为0
                when report_year > year(period_end) then 0
                -- 计算销售天数 *　平均日销售额
                ELSE (datediff(if(t3.report_year_end >= t3.period_end, t3.period_end,t3.report_year_end),
                               if(t3.report_year_start <= t3.period_start,  t3.period_start,t3.report_year_start)) + 1)
                END * t3.average_daily_sales as year_total_amount
        from (
                 -- 构建2018, 2019, 2020 年的销售数据
                 select
                     t1.product_id,
                     t1.period_start,
                     t1.period_end,
                     t1.average_daily_sales,
                     t2.year report_year,
                     to_date(concat(t2.year, '-01-01')) as report_year_start,
                     last_day(to_date(concat(t2.year, '-12-01'))) as report_year_end
                 from Sales t1
                     -- 使用 lateral view posexplode 生成每年的销售数据，已知只有2018, 2019, 2020 三年数据
                          lateral view posexplode(array('2018', '2019', '2020')) t2 as pos, year
             ) t3
    )
select
    t1.product_id,
    t2.product_name,
    t1.report_year,
    t1.year_total_amount total_amount
from year_salses t1
left join Product t2
on t1.product_id = t2.product_id
order by t1.product_id, t1.report_year;


-- 方式二
WITH
-- 1. 模拟 Product 表
Product AS (
    SELECT 1 AS product_id, 'LC Phone' AS product_name UNION ALL
    SELECT 2, 'LC T-Shirt' UNION ALL
    SELECT 3, 'LC Keychain'
),

-- 2. 模拟 Sales 表
Sales AS (
    SELECT 1 AS product_id, CAST('2019-01-25' AS DATE) AS period_start, CAST('2019-02-28' AS DATE) AS period_end, 100 AS average_daily_sales UNION ALL
    SELECT 2, CAST('2018-12-01' AS DATE), CAST('2020-01-01' AS DATE), 10 UNION ALL
    SELECT 3, CAST('2019-12-01' AS DATE), CAST('2020-01-31' AS DATE), 1
),

-- 3. 创建一个包含报告年份的辅助 CTE
Years AS (
    SELECT 2018 AS report_year UNION ALL
    SELECT 2019 UNION ALL
    SELECT 2020
)

-- 4. 主查询
SELECT
    p.product_id,
    p.product_name,
    y.report_year,
    -- 计算有效销售天数: DATEDIFF(有效结束日期, 有效开始日期) + 1
    -- 再乘以日均销售额得到总额
    (DATEDIFF(
         -- 有效结束日期 = MIN(销售结束日期, 当年最后一天)
             LEAST(s.period_end, CAST(CONCAT(y.report_year, '-12-31') AS DATE)),
         -- 有效开始日期 = MAX(销售开始日期, 当年第一天)
             GREATEST(s.period_start, CAST(CONCAT(y.report_year, '-01-01') AS DATE))
     ) + 1) * s.average_daily_sales AS total_amount
FROM
    Sales s
-- 关联产品信息
        JOIN
    Product p ON s.product_id = p.product_id
-- 将每个销售记录与每个年份组合，以便计算每个年份的销售额
        CROSS JOIN
    Years y
-- 过滤掉销售周期与当前年份完全没有交集的组合
WHERE
    GREATEST(s.period_start, CAST(CONCAT(y.report_year, '-01-01') AS DATE))
        <=
    LEAST(s.period_end, CAST(CONCAT(y.report_year, '-12-31') AS DATE))
ORDER BY
    p.product_id, y.report_year;

~~~





##   找出没有进行交易但是访问了银行的客户（点击加购但是没有下单的顾客)



~~~sql

/*
表: `Visits`
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| user_id     | int     |
| visit_date  | date    |
+-------------+---------+
(user_id, visit_date) 是该表的主键(具有唯一值的列的组合)
该表的每行表示 user_id 在 visit_date 访问了银行

表: `Trans`
+------------------+---------+
| Column Name      | Type    |
+------------------+---------+
| user_id          | int     |
| transaction_date | date    |
| amount           | int     |
+------------------+---------+
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
`Trans` 表:
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
输出:
+--------------------+--------------+
| Trans_count | visits_count |
+--------------------+--------------+
| 0                  | 4            |
| 1                  | 5            |
| 2                  | 0            |
| 3                  | 1            |
+--------------------+--------------+
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
~~~



## 查找每组中的获胜球员（也可以是优秀员工）



~~~sql
/*
`Players` 玩家表
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| player_id   | int     |
| group_id    | int     |
+-------------+---------+
player_id 是此表的主键(具有唯一值的列)。
此表的每一行表示每个玩家的组。

`Matches` 赛事表
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| match_id      | int     |
| first_player  | int     |
| second_player | int     |
| first_score   | int     |
| second_score  | int     |
+---------------+---------+
match_id 是此表的主键(具有唯一值的列)。
每一行是一场比赛的记录，first_player 和 second_player 表示该场比赛的球员 ID，first_score 和 second_score 分别表示 first_player 和 second_player 的得分。
你可以假设，在每一场比赛中，球员都属于同一组。

每组的获胜者是在组内累积得分最高的选手。如果平局，player_id 最小的选手获胜。
编写解决方案来查找每组中的获胜者。
返回的结果表单 没有顺序要求。
返回结果格式如下所示。

示例 1:

输入:
`Players` 表:
+-----------+-----------+
| player_id | group_id  |
+-----------+-----------+
| 15        | 1         |
| 25        | 1         |
| 30        | 1         |
| 45        | 1         |
| 10        | 2         |
| 35        | 2         |
| 50        | 2         |
| 20        | 3         |
| 40        | 3         |
+-----------+-----------+
`Matches` 表:
+----------+--------------+---------------+-------------+--------------+
| match_id | first_player | second_player | first_score | second_score |
+----------+--------------+---------------+-------------+--------------+
| 1        | 15           | 45            | 3           | 0            |
| 2        | 30           | 25            | 1           | 2            |
| 3        | 30           | 15            | 2           | 0            |
| 4        | 40           | 20            | 5           | 2            |
| 5        | 35           | 50            | 1           | 1            |
+----------+--------------+---------------+-------------+--------------+
输出:
+-----------+-----------+
| group_id  | player_id |
+-----------+-----------+
| 1         | 15        |
| 2         | 35        |
| 3         | 40        |
+-----------+-----------+
*/


-- 方式1 row_number方式
WITH
-- 1. 模拟 Players 表
Players AS (
    SELECT 15 AS player_id, 1 AS group_id UNION ALL
    SELECT 25, 1 UNION ALL
    SELECT 30, 1 UNION ALL
    SELECT 45, 1 UNION ALL
    SELECT 10, 2 UNION ALL
    SELECT 35, 2 UNION ALL
    SELECT 50, 2 UNION ALL
    SELECT 20, 3 UNION ALL
    SELECT 40, 3
),

-- 2. 模拟 Matches 表

Matches AS (
    SELECT 1 AS match_id, 15 AS first_player, 45 AS second_player, 3 AS first_score, 0 AS second_score UNION ALL
    SELECT 2, 30, 25, 1, 2 UNION ALL
    SELECT 3, 30, 15, 2, 0 UNION ALL
    SELECT 4, 40, 20, 5, 2 UNION ALL
    SELECT 5, 35, 50, 1, 1
),
    player_scores AS (
        select
            players.group_id,
            players.player_id,
            sum(nvl(tt.score,0)) player_score
        from Players players left join
             (
                 -- union all 用于合并两个查询的结果集
                 select
                     t1.first_player AS player_id,
                     t1.first_score AS score
                 from Matches t1
                 union all
                 select
                     t2.second_player,
                     t2.second_score
                 from Matches t2
             ) tt
             on players.player_id = tt.player_id
        group by players.group_id, players.player_id
    )
select
    t2.group_id,
    t2.player_id
from (
         select
             *,
             row_number() over (partition by t1.group_id order by t1.player_score desc ,t1.player_id) as row_num
         from player_scores t1
     ) t2
where t2.row_num = 1;

-- 方式2 采用join的方式
WITH
-- 1. 模拟 Players 表
Players AS (
    SELECT 15 AS player_id, 1 AS group_id UNION ALL
    SELECT 25, 1 UNION ALL
    SELECT 30, 1 UNION ALL
    SELECT 45, 1 UNION ALL
    SELECT 10, 2 UNION ALL
    SELECT 35, 2 UNION ALL
    SELECT 50, 2 UNION ALL
    SELECT 20, 3 UNION ALL
    SELECT 40, 3
),

-- 2. 模拟 Matches 表

Matches AS (
    SELECT 1 AS match_id, 15 AS first_player, 45 AS second_player, 3 AS first_score, 0 AS second_score UNION ALL
    SELECT 2, 30, 25, 1, 2 UNION ALL
    SELECT 3, 30, 15, 2, 0 UNION ALL
    SELECT 4, 40, 20, 5, 2 UNION ALL
    SELECT 5, 35, 50, 1, 1
),
player_scores AS (
    select
        players.group_id,
        players.player_id,
        sum(nvl(tt.score,0)) player_score
    from Players players left join
         (
             select
                 t1.first_player AS player_id,
                 t1.first_score AS score
             from Matches t1
             union all
             select
                 t2.second_player,
                 t2.second_score
             from Matches t2
         ) tt
         on players.player_id = tt.player_id
    group by players.group_id, players.player_id
)
select
    t4.group_id,
    min(t4.player_id) player_id
from (select
          t2.group_id,
          t2.player_id
      from player_scores t2
               inner join (select
                              t1.group_id,
                              max(t1.player_score) max_score
                          from player_scores t1
                          group by t1.group_id
      ) t3
                         on t2.group_id = t3.group_id and t2.player_score = t3.max_score
) t4
group by t4.group_id
~~~



## 投票人(川建国支持你)



~~~sql

/*
 投票人(川建国支持你)
表: `Candidate`
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| name        | varchar |
+-------------+---------+
id 是该表中具有唯一值的列
该表的每一行都包含关于候选对象的id和名称的信息。

表: `Vote`
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| candidateId | int     |
+-------------+---------+
id 是自动递增的主键(具有唯一值的列)。
candidateId是id来自Candidate表的外键(reference 列)。
该表的每一行决定了在选举中获得第1张选票的候选人。

编写解决方案来报告获胜候选人的名字(即获得最多选票的候选人)。
生成的测试用例保证 只有一个候选人赢得 选举。
返回结果格式如下所示。

示例 1:

输入:
`Candidate table`:
+----+------+
| id | name |
+----+------+
| 1  | A    |
| 2  | B    |
| 3  | C    |
| 4  | D    |
| 5  | E    |
+----+------+
`Vote table`:
+----+-------------+
| id | candidateId |
+----+-------------+
| 1  | 2           |
| 2  | 4           |
| 3  | 3           |
| 4  | 2           |
| 5  | 5           |
+----+-------------+
输出:
+------+
| name |
+------+
| B    |
+------+
解释:
候选人B有2票。候选人C、D、E各有1票。
获胜者是候选人B。
*/

WITH
-- 1. 模拟 Candidate 表
Candidate AS (
    SELECT 1 AS id, 'A' AS name UNION ALL
    SELECT 2, 'B' UNION ALL
    SELECT 3, 'C' UNION ALL
    SELECT 4, 'D' UNION ALL
    SELECT 5, 'E'
),

-- 2. 模拟 Vote 表
Vote AS (
    SELECT 1 AS id, 2 AS candidateId UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 3, 3 UNION ALL
    SELECT 4, 2 UNION ALL
    SELECT 5, 5
)

-- 方式1
/*select
    name
from (
    select
        t3.name,
        row_number() over (order by voteCount desc) as rank
    from (
             select
                 t1.candidateId,
                 t2.name,
                 count(1) as voteCount
             from Vote t1
                      left join Candidate t2
                                on t1.candidateId = t2.id
             group by t1.candidateId,t2.name
         ) t3
    )t4
where t4.rank = 1;*/

/*
-- 方式2
select
    t3.name
from (
         select
             t1.candidateId
         from Vote t1
         group by t1.candidateId
         order by count(id) desc
         limit 1
     ) t2
left join Candidate t3
on t2.candidateId = t3.id

*/

-- 方式3
select
    t3.name
from Candidate t3
left join (
    select
        t2.candidateId,
        row_number() over (order by t2.voteCount desc) as rank
    from (
             select
                 t1.candidateId,
                 count(1) as voteCount
             from Vote t1
             group by t1.candidateId
         ) t2
) t4
on t3.id = t4.candidateId
where t4.rank = 1;

~~~



## 关注但非互关



~~~sql
/*

表: `Follow`
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| followee  | varchar |
| follower  | varchar |
+-----------+---------+
(followee, follower) 是该表的主键(具有唯一值的列的组合)。 follower是 关注者，followee是被关注者。
该表的每一行表示关注者关注了社交网络上的被关注者。
不会有用户关注他们自己。

二级关注者 是指满足以下条件的用户:
关注至少一个用户，
被至少一个用户关注。

编写一个解决方案来报告 二级用户 及其关注者的数量。
返回按 follower 字典序排序 的结果表。
结果格式如下所示。

示例 1:

输入:
`Follow table`:
+----------+----------+
| followee | follower |
+----------+----------+
| Alice    | Bob      |
| Bob      | Cena     |
| Bob      | Donald   |
| Donald   | Edward   |
+----------+----------+
输出:
+----------+-----+
| follower | num |
+----------+-----+
| Bob      | 2   |
| Donald   | 1   |
+----------+-----+
解释:
用户 Bob 有 2 个关注者。Bob 是二级关注者，因为他关注了 Alice，所以我们把他包括在结果表中。
用户 Donald 有 1 个关注者。Donald 是二级关注者，因为他关注了 Bob，所以我们把他包括在结果表中。
用户 Alice 有 1 个关注者。Alice 不是二级关注者，但是她不关注任何人，所以我们不把她包括在结果表中。

*/
WITH
-- 1. 模拟 Follow 表
Follow AS (
    SELECT 'Alice' AS followee, 'Bob' AS follower UNION ALL
    SELECT 'Bob', 'Cena' UNION ALL
    SELECT 'Bob', 'Donald' UNION ALL
    SELECT 'Donald', 'Edward'
)
/*
    -- 2. 计算每个用户的关注者数量
    followers AS (
        select
            t1.followee,
            count(1) follower_count
        from Follow t1
        group by t1.followee
    ),

    -- 3. 二级用户有哪些
    lv2_users as(
        select
            followee
        from (
                 select
                     followee
                 from Follow
                 union all
                 select
                     follower
                 from Follow
             )t1
        group by followee
        having count(1) > 1
    )
select
    t1.followee,
    t2.follower_count
from lv2_users t1
left join followers t2
on t1.followee = t2.followee;
*/

/*
-- 方式2
select
t1.followee,
count(distinct t1.follower) follower_count
from Follow t1 -- 被关注者
cross join Follow t2 -- 关注者
on t1.followee = t2.follower
group by t1.followee
*/

-- 方式3
select
    followee,
    count(distinct follower) as num
from Follow
where followee in (select distinct follower from Follow)
group by followee
~~~



## 相互关注



~~~sql

/*

相互关注 (共同好友)
现在有一张表为fans(粉丝表) 里面有两个字段from_user,to_user ,如果两者一致代表from_user关注了to_user

**相互关注**
fans表 --关注表,记录关注动作记录的表
数据如下:
follow表: from_user: 关注用户, to_user: 被关注用户, timestamp: 关注时间。
比如第一行的意思是:A关注了B
from_user   to_user   timestamp
A           B         2022-11-28 12:12:12
A           C         2022-11-28 12:12:13
A           D         2022-11-28 12:12:14
B           A         2022-11-28 12:12:15
B           E         2022-11-28 12:12:16
C           A         2022-11-28 12:12:17
6行

`t1表left join t2表on t1.from_user=t2.to_user and t1.to_user=t2.from_user`

from_user   to_user
A           B
A           C
A           D
B           A
B           E
C           A
无条件join结果为6*6=36行

---
 现在有一张表为fans(粉丝表) 里面有两个字段from_user,to_user ,如果两者一致代表from_user关注了to_user
*/

with fans as (
    SELECT
        '001' as from_user,'002' as to_user
    union all
    SELECT
        '002' as from_user,'001' as to_user
    union all
    SELECT
        '003' as from_user,'001' as to_user
    union all
    SELECT
        '005' as from_user,'001' as to_user
)
/*
    -- 方法1: 使用UNION ALL和GROUP BY来计算相互关注的用户对
    -- 计算相互关注的用户对
  both_fans as (
      select
          from_user,
          to_user,
          -- 使用concat和least函数来确保相互关注的用户对的顺序一致
          concat(least(from_user, to_user), '-', least(to_user, from_user)) as user_group
      from (
               select
                   t1.from_user,
                   t1.to_user
               from fans t1
               union all
               select
                   t2.to_user,
                   t2.from_user
               from fans t2
           )t3
      group by
          t3.from_user,
          t3.to_user
      having count(1) > 1
  )
-- 从相互关注的用户对中选择每个用户组的第一个用户对即可
select
    from_user,
    to_user
from (
         select
             from_user,to_user,
             -- 为每个用户组分配一个行号
             row_number() over (partition by user_group order by from_user, to_user) as row_num
         from both_fans t1
     ) t2
where row_num = 1;

*/

/*
-- 方法2: 使用窗口函数和hash来计算相互关注的用户对
select
    from_user,
    to_user
from (
         select
             from_user,
             to_user,
             -- 使用hash和concat来确保相互关注的用户对的顺序一致
             row_number() over (partition by hash(concat(least(from_user, to_user),  greatest(from_user, to_user))) order by from_user,to_user ) rn,
             -- 计算每个用户组内的数量
             count() over (partition by hash(concat(least(from_user, to_user),  greatest(from_user, to_user))) ) as cnt
         from fans t1
     ) t2
-- 过滤出相互关注的用户对
where rn = 1 and cnt > 1;

*/

/*
-- 方法3: 使用JOIN来计算相互关注的用户对
select
    t1.from_user,
    t1.to_user
from fans t1
inner join fans t2
on t1.from_user = t2.to_user and t1.to_user = t2.from_user

*/

 -- 方法4: 使用GROUP BY和HAVING来计算相互关注的用户对
SELECT count(sort_array(split(user_fans,'-')))
     ,sort_array(split(user_fans,'-'))
from (
         SELECT concat_ws(',',COLLECT_LIST(concat(from_user,'-',to_user))) as user_fans
              ,from_user
         FROM fans
         group by from_user
     ) a GROUP BY sort_array(split(user_fans,'-'))
having count(sort_array(split(user_fans,'-')))=2


~~~



## 连续状态(连续登录改版，多状态)



~~~sql

/*
连续状态(连续登录改版，多状态)
表: `Failed`
+-----------+------+
| Column Name | Type |
+-----------+------+
| fail_date | date |
+-----------+------+
该表主键为 `fail_date` (具有唯一值的列)。
该表包含失败任务的天数。

表: `Succeeded`
+--------------+------+
| Column Name  | Type |
+--------------+------+
| success_date | date |
+--------------+------+
该表主键为 `success_date` (具有唯一值的列)。
该表包含成功任务的天数。

系统每天运行一个任务。每个任务都独立于先前的任务。任务的状态可以是失败或是成功。
编写解决方案找出 `2019-01-01` 到 `2019-12-31` 期间任务连续同状态 `period_state` 的起止日期 (`start_date` 和 `end_date`)。即如果任务失败了，就是失败状态的起止日期，如果任务成功了，就是成功状态的起止日期。
最后结果按照起始日期 `start_date` 排序
返回结果样例如下所示:

示例 1:
输入:
`Failed table`:
+------------+
| fail_date  |
+------------+
| 2018-12-28 |
| 2018-12-29 |
| 2019-01-04 |
| 2019-01-05 |
+------------+
`Succeeded table`:
+--------------+
| success_date |
+--------------+
| 2018-12-30   |
| 2018-12-31   |
| 2019-01-01   |
| 2019-01-02   |
| 2019-01-03   |
| 2019-01-06   |
+--------------+
输出:
+--------------+------------+------------+
| period_state | start_date | end_date   |
+--------------+------------+------------+
| succeeded    | 2019-01-01 | 2019-01-03 |
| failed       | 2019-01-04 | 2019-01-05 |
| succeeded    | 2019-01-06 | 2019-01-06 |
+--------------+------------+------------+
解释:
结果忽略了 2018 年的记录, 因为我们只关心从 `2019-01-01` 到 `2019-12-31` 的记录
从 `2019-01-01` 到 `2019-01-03` 所有任务成功, 系统状态为 "succeeded"。
从 `2019-01-04` 到 `2019-01-05` 所有任务失败, 系统状态为 "failed"。
从 `2019-01-06` 到 `2019-01-06` 所有任务成功, 系统状态为 "succeeded"。

### 使用 WITH 语法的 HiveQL 解决方案

这是一个典型的“寻找连续区间”（Gaps and Islands）问题。我们可以通过使用窗口函数 `ROW_NUMBER()` 来解决。基本思路是：
1.  将成功和失败的记录合并，并为每条记录打上状态标签。
2.  对所有记录按日期排序生成一个总行号。
3.  对每个状态内的记录按日期排序生成一个状态内行号。
4.  用“总行号”减去“状态内行号”，得到的差值对于同一个连续的状态区间来说是恒定的。
5.  按这个差值和状态进行分组，即可找出每个连续区间的开始和结束日期。


*/


WITH
-- 1. 模拟 Failed 表
Failed AS (
    SELECT CAST('2018-12-28' AS DATE) AS fail_date UNION ALL
    SELECT CAST('2018-12-29' AS DATE) UNION ALL
    SELECT CAST('2019-01-04' AS DATE) UNION ALL
    SELECT CAST('2019-01-05' AS DATE)
),

-- 2. 模拟 Succeeded 表
Succeeded AS (
    SELECT CAST('2018-12-30' AS DATE) AS success_date UNION ALL
    SELECT CAST('2018-12-31' AS DATE) UNION ALL
    SELECT CAST('2019-01-01' AS DATE) UNION ALL
    SELECT CAST('2019-01-02' AS DATE) UNION ALL
    SELECT CAST('2019-01-03' AS DATE) UNION ALL
    SELECT CAST('2019-01-06' AS DATE)
),
/*

-- 方式1: 使用窗口函数和日期分组来计算连续状态的起止日期
select
    -- 计算每个状态的起止日期
    t4.period_state,
    min(t4.task_date) as start_date,
    max(t4.task_date) as end_date
from (
         -- 为每条记录打上状态标签，并生成一个日期组
         select
             period_state,
             task_date,
             date_sub(task_date,
                      row_number() over (partition by period_state order by task_date)) as date_group
         from (
                  -- 将失败和成功的记录合并，并标记状态
                  select
                      'failed' as period_state,
                      fail_date as task_date
                  from Failed t1
                  union all
                  select
                      'succeeded' as period_state,
                      success_date
                  from Succeeded t2
              ) t3
     ) t4
group by t4.period_state,
         t4.date_group;

*/
    -- 方式2: 使用窗口函数和日期分组来计算连续状态的起止日期
-- 1. 合并数据并筛选年份
AllTasks AS (
    SELECT 'failed' AS period_state, fail_date AS task_date
    FROM Failed
    WHERE YEAR(fail_date) = 2019
    UNION ALL
    SELECT 'succeeded' AS period_state, success_date
    FROM Succeeded
    WHERE YEAR(success_date) = 2019
),


-- 2. 第一步：计算每个状态下的上一个日期
WithLagDate AS (
    SELECT
        period_state,
        task_date,
        LAG(task_date, 1) OVER (PARTITION BY period_state ORDER BY task_date) as prev_date
    FROM
        AllTasks
),

-- 3. 第二步：根据日期间隔，标记新分组的开始
WithGroupFlag AS (
    SELECT
        period_state,
        task_date,
        -- 如果没有上一个日期 (是第一个)，或者日期间隔大于1，则这是一个新分组的开始
        CASE
            WHEN prev_date IS NULL OR DATEDIFF(task_date, prev_date) > 1 THEN 1
            ELSE 0
            END AS is_new_group
    FROM
        WithLagDate
),

-- 4. 第三步：通过累加求和创建分组ID
WithGroupID AS (
    SELECT
        period_state,
        task_date,
        SUM(is_new_group) OVER (PARTITION BY period_state ORDER BY task_date) as grp
    FROM
        WithGroupFlag
)

-- 5. 第四步：按分组ID聚合，得到最终结果
SELECT
    period_state,
    MIN(task_date) AS start_date,
    MAX(task_date) AS end_date
FROM
    WithGroupID
GROUP BY
    period_state, grp
ORDER BY
    start_date;
~~~





## 游戏留存（用户留存，拓客、各种活动效果等）

~~~sql

/*
表: `Activity`
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| player_id     | int     |
| device_id     | int     |
| event_date    | date    |
| games_played  | int     |
+---------------+---------+
(player_id, event_date) 是此表的主键(具有唯一值的列的组合)
这张表显示了某些游戏的玩家的活动情况
每一行表示一个玩家的记录，在某一天使用某个设备注销之前，登录并玩了很多游戏（可能是 0）
玩家的安装日期 定义为该玩家的第一个登录日。
我们将日期 x 的 第一天留存率 定义为：假定安装日期为 x 的玩家的数量为 N ，其中在 X 之后的一天重新登录的玩家数量为 M，M/N 就是第一天留存率，四舍五入到小数点后两位。

编写解决方案，报告所有安装日期，当天安装游戏的玩家数量和玩家的 第一天留存率。
以 任意顺序 返回结果表。
结果格式如下所示。

示例 1:

输入:
`Activity` 表:
+-----------+-----------+------------+--------------+
| player_id | device_id | event_date | games_played |
+-----------+-----------+------------+--------------+
| 1         | 2         | 2016-03-01 | 5            |
| 1         | 2         | 2016-03-02 | 6            |
| 2         | 3         | 2017-06-25 | 1            |
| 3         | 1         | 2016-03-01 | 0            |
| 3         | 4         | 2016-07-03 | 5            |
+-----------+-----------+------------+--------------+
输出:
+------------+----------+----------------+
| install_dt | installs | Day1_retention |
+------------+----------+----------------+
| 2016-03-01 | 2        | 0.50           |
| 2017-06-25 | 1        | 0.00           |
+------------+----------+----------------+
解释:
玩家 1 和 3 在 2016-03-01 安装了游戏，但只有玩家 1 在 2016-03-02 重新登录，所以 2016-03-01 的第一天留存率是 1/2=0.50
玩家 2 在 2017-06-25 安装了游戏，但在 2017-06-26 没有重新登录，因此 2017-06-25 的第一天留存率为 0/1=0.00


*/

WITH
-- 1. 模拟 Activity 表
Activity AS (
    SELECT 1 AS player_id, 2 AS device_id, CAST('2016-03-01' AS DATE) AS event_date, 5 AS games_played UNION ALL
    SELECT 1, 2, CAST('2016-03-02' AS DATE), 6 UNION ALL
    SELECT 2, 3, CAST('2017-06-25' AS DATE), 1 UNION ALL
    SELECT 3, 1, CAST('2016-03-01' AS DATE), 0 UNION ALL
    SELECT 3, 4, CAST('2016-07-03' AS DATE), 5
),
/*
1. 每日注册的玩家有哪些？
2. 每日登录的玩家有哪些？
3. 每日登录的玩家中，有哪些是已经一天前注册的玩家？
*/
registered_players as (
    select
        player_id,
        min(event_date) as install_dt
    from Activity t1
    group by player_id
),
daily_logins as (
    select
        player_id,
        event_date
    from Activity t2
    group by player_id, event_date
),
day1_retention as (
    select
        t1.install_dt,
        count(distinct t1.player_id) as installs,
        round(count(distinct t2.player_id) * 1.0 / count(distinct t1.player_id),2) as Day1_retention
    from registered_players t1
    left join daily_logins t2 on t1.player_id = t2.player_id and date_add(t1.install_dt, 1) = t2.event_date
    group by t1.install_dt
) select * from day1_retention;


~~~





## 连续会话（社区相关）

~~~sql

/*
表: `Sessions`
```
+---------------+----------+
| Column Name   | Type     |
+---------------+----------+
| user_id       | int      |
| session_start | datetime |
| session_end   | datetime |
| session_id    | int      |
| session_type  | enum     |
+---------------+----------+
```
`session_id` 是这张表中有不同值的列。
`session_type` 是 (Viewer, Streamer) 的一个 ENUM (category) 类型。
这张表包含 user id, session start, session end, session id 和 session 类型。

编写一个解决方案，以查找 至少有一个相同 类型的 连续会话 (无论是“Viewer”还是“Streamer”) 的 用户，会话 之间的 最大 间隔为 12 小时。
返回结果表，以 `user_id` 升序 排序。
结果格式如下所述。

示例:

输入:
`Sessions` 表:
```
+---------+---------------------+---------------------+------------+--------------+
| user_id | session_start       | session_end         | session_id | session_type |
+---------+---------------------+---------------------+------------+--------------+
| 101     | 2023-11-01 08:00:00 | 2023-11-01 09:00:00 | 1          | Viewer       |
| 101     | 2023-11-01 10:00:00 | 2023-11-01 11:00:00 | 2          | Streamer     |
| 102     | 2023-11-01 13:00:00 | 2023-11-01 14:00:00 | 3          | Viewer       |
| 102     | 2023-11-01 15:00:00 | 2023-11-01 16:00:00 | 4          | Viewer       |
| 101     | 2023-11-02 09:00:00 | 2023-11-02 10:00:00 | 5          | Viewer       |
| 102     | 2023-11-02 12:00:00 | 2023-11-02 13:00:00 | 6          | Streamer     |
| 101     | 2023-11-02 13:00:00 | 2023-11-02 14:00:00 | 7          | Streamer     |
| 102     | 2023-11-02 16:00:00 | 2023-11-02 17:00:00 | 8          | Viewer       |
| 103     | 2023-11-01 08:00:00 | 2023-11-02 09:00:00 | 9          | Viewer       |
| 102     | 2023-11-02 20:00:00 | 2023-11-02 23:00:00 | 10         | Viewer       |
| 103     | 2023-11-03 09:00:00 | 2023-11-03 10:00:00 | 11         | Viewer       |
+---------+---------------------+---------------------+------------+--------------+
```
输出:
```
+---------+
| user_id |
+---------+
| 102     |
| 103     |
+---------+
```
解释:
- 用户 ID 101 将不会包含在最终输出中，因为他们没有相同会话类型的连续回话。
- 用户 ID 102 将会包含在最终输出中，因为他们分别有两个 session ID 为 3 和 4 的 viewer 会话, 并且时间间隔在 12 小时内。
- 用户 ID 103 参与了两次 viewer 会话, 间隔不到 12 小时, 会话 ID 为 10 和 11。因此, 用户 103 将会被包含在最终输出中。
输出表根据 `user_id` 升序排列。

*/

WITH
-- 1. 模拟 Sessions 表
Sessions AS (
    SELECT 101 AS user_id, CAST('2023-11-01 08:00:00' AS TIMESTAMP) AS session_start, CAST('2023-11-01 09:00:00' AS TIMESTAMP) AS session_end, 1  AS session_id, 'Viewer' AS session_type UNION ALL
    SELECT 101, CAST('2023-11-01 10:00:00' AS TIMESTAMP), CAST('2023-11-01 11:00:00' AS TIMESTAMP), 2,  'Streamer' UNION ALL
    SELECT 102, CAST('2023-11-01 13:00:00' AS TIMESTAMP), CAST('2023-11-01 14:00:00' AS TIMESTAMP), 3,  'Viewer'   UNION ALL
    SELECT 102, CAST('2023-11-01 15:00:00' AS TIMESTAMP), CAST('2023-11-01 16:00:00' AS TIMESTAMP), 4,  'Viewer'   UNION ALL
    SELECT 101, CAST('2023-11-02 09:00:00' AS TIMESTAMP), CAST('2023-11-02 10:00:00' AS TIMESTAMP), 5,  'Viewer'   UNION ALL
    SELECT 102, CAST('2023-11-02 12:00:00' AS TIMESTAMP), CAST('2023-11-02 13:00:00' AS TIMESTAMP), 6,  'Streamer' UNION ALL
    SELECT 101, CAST('2023-11-02 13:00:00' AS TIMESTAMP), CAST('2023-11-02 14:00:00' AS TIMESTAMP), 7,  'Streamer' UNION ALL
    SELECT 102, CAST('2023-11-02 16:00:00' AS TIMESTAMP), CAST('2023-11-02 17:00:00' AS TIMESTAMP), 8,  'Viewer'   UNION ALL
    SELECT 103, CAST('2023-11-01 08:00:00' AS TIMESTAMP), CAST('2023-11-03 09:00:00' AS TIMESTAMP), 9,  'Viewer'   UNION ALL
    SELECT 102, CAST('2023-11-02 20:00:00' AS TIMESTAMP), CAST('2023-11-02 23:00:00' AS TIMESTAMP), 10, 'Viewer'   UNION ALL
    SELECT 103, CAST('2023-11-03 09:00:00' AS TIMESTAMP), CAST('2023-11-03 10:00:00' AS TIMESTAMP), 11, 'Viewer'
),
    /*
    1. 时间相隔12小时如何计算
    2. 连续会话如何计算
    */
 continuous_group as (
     select user_id,
            session_type,
            session_id,
            session_start_ts,
            session_end_ts,
            last_session_end_ts,
            judge_continuous_condition,
            -- 计算连续会话的标志
            sum(
                    case
                        when last_session_end_ts is null then 1
                        when judge_continuous_condition then 0
                        else 1 end
            ) over (partition by user_id, session_type order by session_start_ts, session_end_ts) as continuous_session
     from (
                -- 计算每个用户的会话，及其上一个会话的结束时间
              select user_id,
                     session_type,
                     session_id,
                     session_start_ts,
                     session_end_ts,
                     -- 获取上一个会话的结束时间
                     lag(session_end_ts) over (partition by user_id, session_type order by session_start_ts,session_end_ts) as last_session_end_ts,
                     -- session_start_ts,session_end_ts 升序排列，保证顺序，并计算时间间隔
                     abs(session_end_ts - lag(session_end_ts) over (partition by user_id, session_type order by session_start_ts,session_end_ts)) <= 12 * 60 * 60 as judge_continuous_condition
              from (
                       -- 将时间戳转换为秒;并对会话类型过滤
                       select
                           user_id,
                           session_type,
                           session_id,
                           unix_timestamp(session_start,'yyyy-MM-dd HH:mm:ss') as session_start_ts,
                           unix_timestamp(session_end,'yyyy-MM-dd HH:mm:ss') as session_end_ts
                       from Sessions t1
                       where session_type in ('Viewer', 'Streamer')

                   ) t2
          ) t3

 )
select
    distinct user_id
from (
         select
             user_id
         from continuous_group t
         group by user_id, session_type,continuous_session
         having count(1) > 1
     ) tt;
~~~

