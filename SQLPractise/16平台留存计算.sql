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

---

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



