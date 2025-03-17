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

-- 日期汇总
/*# Hive 日期时间函数：各种时间单位"之前"的计算方法

Hive 3.1.3 提供了多种函数来计算不同时间单位之前的日期或时间。以下是按时间单位从小到大的完整列表和示例：

## 1. 秒级操作
```sql
-- 30秒前
SELECT from_unixtime(unix_timestamp() - 30)

-- 示例：当前时间的30秒前
SELECT from_unixtime(unix_timestamp('2023-04-15 14:30:45') - 30)
-- 结果：2023-04-15 14:30:15
```

## 2. 分钟级操作
```sql
-- 5分钟前
SELECT from_unixtime(unix_timestamp() - 5*60)

-- 示例：当前时间的5分钟前
SELECT from_unixtime(unix_timestamp('2023-04-15 14:30:45') - 5*60)
-- 结果：2023-04-15 14:25:45
```

## 3. 小时级操作
```sql
-- 3小时前
SELECT from_unixtime(unix_timestamp() - 3*60*60)

-- 示例：当前时间的3小时前
SELECT from_unixtime(unix_timestamp('2023-04-15 14:30:45') - 3*60*60)
-- 结果：2023-04-15 11:30:45
```

## 4. 天级操作
```sql
-- 7天前
SELECT date_sub(current_date(), 7)
-- 或
SELECT date_sub('2023-04-15', 7)
-- 结果：2023-04-08
```

## 5. 周级操作
```sql
-- 2周前
SELECT date_sub(current_date(), 2*7)
-- 或
SELECT date_sub('2023-04-15', 14)
-- 结果：2023-04-01
```

## 6. 月级操作
```sql
-- 3个月前
SELECT add_months(current_date(), -3)
-- 或
SELECT add_months('2023-04-15', -3)
-- 结果：2023-01-15
```

## 7. 季度级操作
```sql
-- 2个季度前
SELECT add_months(current_date(), -2*3)
-- 或
SELECT add_months('2023-04-15', -6)
-- 结果：2022-10-15
```

## 8. 年级操作
```sql
-- 1年前
SELECT add_months(current_date(), -12)
-- 或
SELECT add_months('2023-04-15', -12)
-- 结果：2022-04-15
```

## 特殊函数

- **next_day**：获取下一个指定星期几的日期
  ```sql
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
  ```

- **last_day**：获取当月最后一天
  ```sql
  SELECT last_day('2023-04-15')
  -- 结果：2023-04-30
  ```

- **trunc**：截断到指定的时间单位
  ```sql
  -- 截断到月初
  SELECT trunc('2023-04-15', 'MM')
  -- 结果：2023-04-01

  -- 截断到年初
  SELECT trunc('2023-04-15', 'YY')
  -- 结果：2023-01-01
  ```*/
