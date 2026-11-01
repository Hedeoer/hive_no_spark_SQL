# Spark SQL 练习总集

> 由仓库内 `SQLPractise/*.sql`（139 个文件）与 `大数据SQL例题.md`、`spark_SQL例题.md` 两份历史发布稿合并去重而成。
> **136 道唯一题目**，按技术手法聚成 12 类。本文件由 `tools/gen.py` 生成，SQL 正文从源文件按行区间原样抽取。

## 怎么用这份文档

1. **按类复习**：每类开头的导读讲清「这类在考什么」，先读导读再顺次刷。
2. **按编号溯源**：编号形如 `2024-01`，`年份-原编号`。同一道题若写在多处，只保留一条正文，其余在该条的「源」或「说明」里点名。
3. **SQL 一律原文照录**（按约定不改一个字符）。文中的 `> ⚠️ 静态观察` 是**未经执行验证**的疑点提示，不构成结论。

## 约定

| 记号 | 含义 |
| --- | --- |
| `2024-01` | `年份-原编号`。2024 段的重号合并后空缺（如 2024-11、2024-27 等已并入他条） |
| `2025-78` / `2025-80` | 只存在于 `spark_SQL例题.md`、没有独立 .sql 文件的题目 |
| L12–L88 | `2024/test.sql` 的行区间。该文件是 2024 年前 10 题的工作合集，不是草稿 |
| `<details>` | 建表 / 造数语句超过 20 行时折叠，点开即是原文 |
| 「变体」 | 同源、但参数或粒度不同的题目，保留但排在主解之后 |
| 缩进 | 代码块只做了「去掉公共前导缩进」这一项空白归一，非空白字符零改动 |

## 分类总览

| # | 大类 | 题数 |
| --- | --- | --- |
| A | 连续区间与连续状态（gaps & islands） | 12 |
| B | 窗口函数：排名 / TopN / 前后比较 | 33 |
| C | 行转列、列转行与炸裂展开 | 8 |
| D | 留存、新增与转化漏斗 | 7 |
| E | 区间重叠、时间线与并发 | 7 |
| F | 条件聚合与分组判定 | 27 |
| G | JSON、字符串与正则解析 | 10 |
| H | 树形层级与递归 / 自连接 | 5 |
| I | 贪心、调度与过程模拟 | 3 |
| J | 日期处理与时间维度 | 6 |
| K | Spark SQL 执行与优化 | 1 |
| L | 关系网络与集合运算 | 17 |
| | **合计** | **136** |

---

## A · 连续区间与连续状态（gaps & islands）（12 题）

核心模板只有一个：**目标行连续 ⟺ 某个单调量减去 row_number 后恒定**。日期用 `date_sub(col, rn)`，序号用 `id - rn`，状态用「发生变化就打 1，再累计求和」。把结果当分组键，`min/max` 取区间端点、`count` 取长度即可。

### 2024-01 · 查询连续登录 3 天以上的用户

**源**：`SQLPractise/2024/test.sql` L1–L106

**考点**：日期先去重，再 `date_sub(login_date, row_number())` 造分组键，`count >= 3` 即连续 3 天。

**输入 → 输出**：user_login_detail(user_id, ip_address, login_ts, logout_ts) → 连续登录 ≥3 天的 user_id

同一文件 L107–L127 还有「连续 4 天」的变体，见本节末尾。

<details>
<summary>建表与造数语句（原文照录，点击展开）</summary>

```sparksql
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
```

</details>

```sparksql
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
```

#### 变体：查询连续 4 天登录的用户

**源**：`SQLPractise/2024/test.sql` L107–L127

**差异**：不用 row_number 差值，而是 `collect_list over(rows between 3 preceding and current row)` 取最近 4 天，再逐位 `datediff = 1` 校验。写法定全不同，是同一模板的另一种实现。

```sparksql
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


### 2024-02 · 查询连续登录最大天数的用户

**源**：`SQLPractise/2024/test.sql` L128–L166

**考点**：同上造组键，`count` 出每段天数后按天数倒序取第一。

**输入 → 输出**：user_login_detail → 连续登录天数最长的那(些) user_id

```sparksql
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
```

### 2024-03 · 按天合并连续登录的时间区间（间隔 ≤ 2 天算连续）

**源**：`SQLPractise/2024/test.sql` L167–L206

**考点**：`lag(logout_date)` 与当前 `login_date` 做 `datediff <= 2` 比较打 flag，累计求和当组键，每组取 `min(login_date)` / `max(logout_date)`。

**输入 → 输出**：user_login_detail → 每个用户合并后的若干段 (user_id, 起始登录日, 结束登出日)

注释里点明了要处理「登录区间重叠」的异常情况。

```sparksql
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

### 2024-13 · 通过炸裂函数解决连续缴费问题

**源**：`SQLPractise/2024/13通过炸裂函数解决连续问题.sql`

**考点**：按时点对齐目标期数与实缴记录，靠炸裂生成应有的期数序列，再判断是否连续。

**输入 → 输出**：contract_consumption(contract, value_date, amount, term) → 连续缴费的合同及其区间

```sparksql
-- 建表: 原始消费记录表
CREATE TABLE contract_consumption (
  contract STRING,       -- 用户标识
  value_date DATE,       -- 消费日期
  amount DECIMAL(10, 2), -- 消费金额
  term INT               -- 用户应存期数
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- 示例数据插入
INSERT INTO contract_consumption VALUES
('AAAA', '2018-12-21', 9439.30, 12),
('AAAA', '2019-03-21', 9439.30, 12),
('AAAA', '2019-06-21', 9439.30, 12),
('BBBB', '2018-12-02', 9439.30, 10),
('BBBB', '2019-06-02', 9439.30, 10),
('BBBB', '2019-09-02', 9439.30, 10);

/*
需求描述:
1. 给定合同号、消费日期、消费金额、应存期数，需要按合同号生成连续的消费记录。
2. 新生成的消费记录每月增加一个月，消费金额累积计算。
3. 结果表的列包括合同号、连续的消费日期、新的累积消费金额和应存期数。
*/

-- 累计求和
WITH t1 AS (
  SELECT
    contract,
    last_day(value_date) value_date,
    term,
    SUM(amount) OVER (PARTITION BY contract ORDER BY value_date) AS acc_amount
  FROM (
    SELECT
      contract,
      value_date,
      term,
      SUM(amount) AS amount
    FROM contract_consumption
    GROUP BY contract, value_date, term
  ) AS subquery
),
    -- 构建日期维度表
t2 AS (
    SELECT
        t1.contract,
        ADD_MONTHS(date_format(t1.lower_date,'yyyy-MM-00'), tmp_pos.pos) AS cur_date
    FROM (
        SELECT
            contract,
            MAX(value_date) AS upper_date,
            MIN(value_date) AS lower_date,
            FLOOR(MONTHS_BETWEEN(MAX(value_date), MIN(value_date))) AS month_diff
        FROM contract_consumption
        GROUP BY contract
    ) t1
    LATERAL VIEW POSEXPLODE(SPLIT(SPACE(cast(t1.month_diff as int)), '')) tmp_pos AS pos, value_char
)
select
    contract,
    cur_date,
    term,
    acc_amount
    from (
        -- 对补充的日期维度利用函数last_value补充值
        select t2.contract,
               t2.cur_date,
               last_value(t1.acc_amount,true) over(partition by t2.contract order by t2.cur_date rows between  unbounded preceding and current row ) acc_amount,
               last_value(t1.term,true) over(partition by t2.contract order by t2.cur_date rows between  unbounded preceding and current row ) term
        from t2
        left join t1
        on t2.contract = t1.contract and t2.cur_date = t1.value_date
    ) tt
    -- 过滤异常值
where term is not null;



--
select months_between( '2022-05-22' ,  '2022-03-21' );
select `floor`(2.03225806);
select split(space(2),' ');

WITH data AS (
    SELECT 'AAAA' AS contract, '2018-12-21' AS value_date, 9439.30 AS amount, 12 AS term
    UNION ALL
    SELECT 'AAAA' AS contract, '2019-03-21' AS value_date, 9439.30 AS amount, 12 AS term
    UNION ALL
    SELECT 'AAAA' AS contract, '2019-06-21' AS value_date, 9439.30 AS amount, 12 AS term
    UNION ALL
    SELECT 'AAAA' AS contract, '2019-09-21' AS value_date, 9439.30 AS amount, 12 AS term
    UNION ALL
    SELECT 'BBBB' AS contract, '2018-12-21' AS value_date, 9439.30 AS amount, 10 AS term
    UNION ALL
    SELECT 'BBBB' AS contract, '2019-02-02' AS value_date, 9439.30 AS amount, 10 AS term
    UNION ALL
    SELECT 'BBBB' AS contract, '2019-05-02' AS value_date, 9439.30 AS amount, 10 AS term
    UNION ALL
    SELECT 'BBBB' AS contract, '2019-08-02' AS value_date, 9439.30 AS amount, 10 AS term
),
dim AS (
    SELECT contract,
           add_months(value_date, pos) AS value_date,
           term
    FROM (
        SELECT contract, MIN(value_date) AS value_date, MAX(amount) AS amount, MAX(term) AS term
        FROM data
        GROUP BY contract
    ) d
    LATERAL VIEW posexplode(split(space(term), '(?|$)')) temp AS pos, val
)
SELECT d.contract,
       dim.value_date,
       d.amount,
       SUM(d.amount) OVER (PARTITION BY dim.contract ORDER BY dim.value_date) AS amount
FROM dim
LEFT JOIN (
    SELECT contract, value_date, amount
    FROM data
) d ON dim.contract = d.contract AND dim.value_date = d.value_date;
```

### 2024-21 · 合并连续同名行（max(id) over 分组）

**源**：`SQLPractise/2024/21数据的合并.sql`

**考点**：`max(id) over(partition by name order by id desc)` 从后往前取最后一个 id 当组键，再 `group by` 合并。

**输入 → 输出**：id + name 明细 → 每段连续出现的 name 合并成一行（含区间端点）

解法注释写在文件头，是「反向累计取组键」的典型写法。

```sparksql
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
group by name,max_id,min_id
order by min_id;

-- 改进order by的单个reducer性能问题
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
            from data),

     -- 中间添加一步，确保min_id有唯一值用于分发和排序
     t2 as (
       SELECT
         min_id,
         max_id,
         name,
         dense_rank() OVER (ORDER BY min_id) as rank_id
       FROM t1
     )

SELECT
    max_id,
    concat_ws(',',collect_list(name)) names,
    rank_id  -- 将rank_id添加到SELECT子句
FROM t2
GROUP BY name, max_id,rank_id
DISTRIBUTE BY rank_id
SORT BY rank_id;

-- 当分发和排序使用相同的列时，使用DISTRIBUTE BY x 和SORT BY x 和 cluster by x 是等价的
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
            from data),

     -- 中间添加一步，确保min_id有唯一值用于分发和排序
     t2 as (
       SELECT
         min_id,
         max_id,
         name,
         dense_rank() OVER (ORDER BY min_id) as rank_id
       FROM t1
     )

SELECT
    max_id,
    concat_ws(',',collect_list(name)) names,
    rank_id  -- 将rank_id添加到SELECT子句
FROM t2
GROUP BY name, max_id,rank_id
CLUSTER BY rank_id;


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

### 2024-40 · 连续分组 / 连续会话（无间隔约束）

**源**：`SQLPractise/2024/40 连续分组.sql`

**考点**：`lag(session_type)` 判断状态是否变化，变化即打 1 累计求和，同组内取会话起止。

**输入 → 输出**：Sessions(user_id, session_start, session_end, session_id, session_type) → 相同类型的连续会话区间

与 2024-65 构成变体对：本条不限间隔，65 加了「间隔 ≤ 12 小时」。

```sparksql
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

### 2024-49 · 选手连胜数

**源**：`SQLPractise/2024/49 选手连胜数.sql`

**考点**：只对 `Win` 计数，遇到非 Win 就重置累加器（`sum(if(result='Win',1,0))` 配变化标记分组）。

**输入 → 输出**：Matches(player_id, match_day, result∈{Win,Draw,Lose}) → 每个选手的最长连胜数

```sparksql
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
```

### 2024-65 · 连续会话（会话间隔 ≤ 12 小时）

**源**：`SQLPractise/2024/65 连续会话（社区相关）.sql`

**考点**：`lag(session_end)` 与当前 `session_start` 的时间差 ≤ 12 小时视为连续，其余同 gaps & islands。

**输入 → 输出**：Sessions → 至少有一段同类型连续会话（间隔 ≤12h）的 user_id

```sparksql
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
```

### 2025-13 · 找出没有被执行的子任务

**源**：`SQLPractise/2025/13 子任务是否被执行.sql`

**考点**：`explode(sequence(1, subtasks_count))` 造出全部子任务，再反连接 Executed 找缺失项。

**输入 → 输出**：Tasks(task_id, subtasks_count) + Executed(task_id, subtask_id) → 未执行的 (task_id, subtask_id)

这是「全集 − 已发生」的通用模板，与 2024-52 是同一道题。

```sparksql
WITH
-- 1. 模拟 Tasks 表
Tasks AS (
    SELECT 1 AS task_id, 3 AS subtasks_count UNION ALL
    SELECT 2, 2 UNION ALL
    SELECT 3, 4
),

-- 2. 模拟 Executed 表
Executed AS (
    SELECT 1 AS task_id, 2 AS subtask_id UNION ALL
    SELECT 3, 1 UNION ALL
    SELECT 3, 2 UNION ALL
    SELECT 3, 3 UNION ALL
    SELECT 3, 4
)
select
    t2.task_id,
    t2.subtask_id
from (
         select
             t1.task_id,
             t2.pos + 1 as subtask_id
         from Tasks t1
             lateral view posexplode(split(repeat(',',t1.subtasks_count - 1), ',')) t2 as pos, task
     ) t2
         left join Executed t3
                   on t2.task_id = t3.task_id and t2.subtask_id = t3.subtask_id
where t3.task_id is null
```

### 2025-43 · 连续出现三次的数字（Logs）

**源**：`SQLPractise/2025/43 连续出现的数字.sql`

**考点**：无日期维度，直接 `lag` 两位比较（或用 `id - row_number()` 按 num 分组再 `having count>=3`）。

**输入 → 输出**：Logs(id 自增, num) → 至少连续出现三次的 num

```sparksql
WITH
-- 1. 模拟 Logs 表
Logs AS (
    SELECT 1 AS id, '1' AS num UNION ALL
    SELECT 2, '1' UNION ALL
    SELECT 3, '1' UNION ALL
    SELECT 4, '2' UNION ALL
    SELECT 5, '1' UNION ALL
    SELECT 6, '2' UNION ALL
    SELECT 7, '2'
)
select
    distinct num
from (
         select
             id,
             num,
             row_number() over (partition by  num order by id  ) row_number
         from Logs t1
     ) t2
group by id - row_number, num
having count(1) >= 3
```

### 2025-54 · Stadium 连续三行人数 ≥ 100

**源**：`SQLPractise/2025/54 符合条件的连续.sql`

**考点**：先滤 `people >= 100`，再 `id - row_number()` 分组，`having count >= 3`，回连原表取明细。

**输入 → 输出**：Stadium(id, visit_date, people) → 人数 ≥100 且连续 ≥3 天的记录，按 visit_date 升序

同一道 LC 601 在仓库里写了三遍（2024/11、2024/27 已合并至此）。

```sparksql
WITH
-- 1. 模拟 Stadium 表
Stadium AS (
    SELECT 1 AS id, CAST('2017-01-01' AS DATE) AS visit_date, 10 AS people UNION ALL
    SELECT 2, CAST('2017-01-02' AS DATE), 109 UNION ALL
    SELECT 3, CAST('2017-01-03' AS DATE), 150 UNION ALL
    SELECT 4, CAST('2017-01-04' AS DATE), 99 UNION ALL
    SELECT 5, CAST('2017-01-05' AS DATE), 145 UNION ALL
    SELECT 6, CAST('2017-01-06' AS DATE), 1455 UNION ALL
    SELECT 7, CAST('2017-01-07' AS DATE), 199 UNION ALL
    SELECT 8, CAST('2017-01-09' AS DATE), 188
)

-- 方式1
/*
     ,
    continus_analysis as (
        select
            id,
            visit_date,
            people,
            count(1) over(partition by group_flag) continus_days
        from (
                 select id,
                        people,
                        visit_date,
                        sum(if(diff is null or diff = 1,0,1)) over(order by id) group_flag
                 from (
                          select
                              id,
                              people,
                              visit_date,
                              id - lag(id, 1) over(order by id) diff
                          from Stadium t1
                          where people >= 100
                      ) t2

             ) t3

    )
select id,
       visit_date,
       people
from continus_analysis t0
where continus_days >= 3
order by visit_date;
*/

-- 方式2
select id,
       visit_date,
       people
from (
         select id,
                visit_date,
                people,
                id - row_number() over (order by id) group_flag,
                count(1) over(partition by (id - row_number() over (order by id))) continus_days
         from Stadium t0
         where people >= 100
     ) t1
where continus_days >= 3
order by visit_date;

/*
传统聚合函数（SUM, COUNT等）：不允许直接嵌套，需使用子查询或CTE。
窗口函数（... over (...)）：允许其 partition by 或 order by 子句中包含另一个窗口函数
*/
```

### 2025-70 · 连续状态的起止日期（多状态）

**源**：`SQLPractise/2025/70 连续状态的起止日期.sql`

**考点**：Failed / Succeeded 两表 `union all` 补上状态列，再按 status 分区做 gaps & islands，输出区间端点。

**输入 → 输出**：Failed(fail_date) + Succeeded(success_date) → 2019 年内每段连续状态的 (start_date, end_date, period_state)

与 2024/63 是同一道题。

```sparksql
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
group_comming as (
    select work_date,
           flag,
           datediff,
           previous_flag,
           sum(
                   if((datediff is null or datediff = 1) and flag = previous_flag,0,1)
           ) over (order by work_date) group_flag
    from (select
              work_date,
              flag,
              datediff(work_date,lag(work_date,1) over(order by work_date)) datediff,
              lag(flag,1) over(order by work_date )previous_flag
          from (
                   select fail_date as work_date,'fail' as flag
                   from Failed t1
                   where fail_date between '2019-01-01' and '2019-12-31'
                   union all
                   select success_date ,'succeed'
                   from Succeeded t2
                   where success_date between '2019-01-01' and '2019-12-31'
               ) t3)t4
)
select
    flag,
    min(work_date) start_date,
    max(work_date) end_date
from group_comming t0
group by flag,group_flag
```

---

## B · 窗口函数：排名 / TopN / 前后比较（33 题）

占比最大的一类。`row_number/rank/dense_rank` 解决「第 N 个 / 前 N 名」，`lag/lead` 解决「前一次 / 后一次」，`rows between` 解决滚动区间，中位数靠「按位次取中间行」或「排序后卡 rn」。

### 2024-04 · 求出股票波峰波谷

**源**：`SQLPractise/2024/test.sql` L207–L253

**考点**：`lag(price)` / `lead(price)` 取前后一天，与当天比较定 peak / valley / normal。

**输入 → 输出**：stock_price_detail(id, ds, price) → 每行打上 peak / valley / normal / abnormal 标记

与 2026-06 同题：本条是单股票且未分区，2026-06 是多股票 `partition by stock_id`。

<details>
<summary>建表与造数语句（原文照录，点击展开）</summary>

```sparksql
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
```

</details>

```sparksql
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

### 2024-05 · 每个店铺每次开业的前一次 / 后一次开业日期

**源**：`SQLPractise/2024/test.sql` L254–L365

**考点**：先 `where is_open = 1` 滤出开业记录，再 `lag/lead(open_date) over(partition by store_id order by open_date)`。

**输入 → 输出**：store_open_status(store_id, is_open, open_date) → 每次开业的 (前一次开业日, 后一次开业日)

文件里给了两种写法：只保留开业行 / 保留全部行（不过滤），后者未开业行的前后值需要额外处理。

<details>
<summary>建表与造数语句（原文照录，点击展开）</summary>

```sparksql
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
```

</details>

```sparksql
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

### 2024-07 · 求最小达到某累计金额的日期

**源**：`SQLPractise/2024/test.sql` L475–L525

**考点**：`sum(price) over(partition by user_id order by dt rows between 3 preceding and current row)` 滚动累计，取首次越过阈值的 `min(dt)`。

**输入 → 输出**：user_consume_order(user_id, dt, price) → 每个用户 3 天滚动累计首次达标的日期

**这一题只存在于 `test.sql`**，两份 md 与独立 .sql 都没有收录它。

```sparksql
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
```

### 2024-10 · 历史新低的商品 id

**源**：`SQLPractise/2024/test.sql` L684–L761

**考点**：把「变更前价格 / 变更后价格」还原成价格序列，`min(price) over(partition by id order by time)` 与当前值比较，首次创新的记录即历史新低点。

**输入 → 输出**：product_price_change(id, start_price, after_price, time) → 出现历史新低的商品 id / 记录

与 大数据md §历史新低的商品id 为同一题。

<details>
<summary>建表与造数语句（原文照录，点击展开）</summary>

```sparksql
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
```

</details>

```sparksql
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

### 2024-25 · 用相邻非空值均值填补空缺值

**源**：`SQLPractise/2024/25填补空缺值.sql`

**考点**：`lag` / `lead` 各取最近的非空值（或 `last_value ignore nulls`），线性插值补 NULL。

**输入 → 输出**：before, date, value（中间有 NULL） → 用紧邻两行非空值的均值填充后的序列

```sparksql
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

### 2024-34 · 商品最新订单（题面编号 50）

**源**：`SQLPractise/2024/34 最新订单数据.sql`

**考点**：`row_number() over(partition by customer_id order by order_date desc) = 1` 取每人最新一笔。

**输入 → 输出**：Customers + Orders → 每个顾客最近一次下单的 (customer, product, amount, date)

```sparksql
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
```

### 2024-39 · 降水量（左右最大值夹逼）

**源**：`SQLPractise/2024/39 降水量.sql`

**考点**：分别求 `max(height) over(order by id)`（左侧）与 `max(height) over(order by id desc)`（右侧），两者取 `least` 再减当前高度即为该位置积水。

**输入 → 输出**：Heights(id, height) → 总降水量（或每个位置的水位）

```sparksql
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
```

### 2024-43 · 前三名酒庄

**源**：`SQLPractise/2024/43 前三名酒庄.sql`

**考点**：按 country 分区对总分做排名，取前三；不足三名时补 `No Second/Third Winery` 文案。

**输入 → 输出**：Wineries(id, country, points, winery) → 每个国家总分前三的酒庄

三个坑：总分要 `sum(points)` 而非单行、并列要按 winery 升序、缺位要补文案。

```sparksql
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

### 2024-47 · 发票信息（Products / Purchases，每组最贵）

**源**：`SQLPractise/2024/47 发票信息.sql`

**考点**：按 invoice 分组求单价最高的商品，`row_number` 或 `max_by` 取一对多里的那一条。

**输入 → 输出**：Products(product_id, price) + Purchases(invoice_id, product_id, quantity) → 每张发票中单价最高的商品

注意与 2024-38「发票信息」**同名但是完全不同的题**（38 是顾客/联系人邮箱匹配）。

```sparksql
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
```

### 2025-01 · 两点之间的最短距离

**源**：`SQLPractise/2025/1 两点之间的最短距离.sql`

**考点**：自笛卡尔积取两两组合，`round(sqrt(pow(dx,2)+pow(dy,2)), 2)` 后取 `min`。

**输入 → 输出**：Point2D(x, y) → 任意两点间的最短距离（保留 2 位）

> ⚠️ 静态观察：`cross join Point2D t2 on t1.x <> t2.x or t1.y <> t2.y` 这种「cross join + on」写法在部分 Spark 版本下不被接受（需写成 `cross join` 后在 `where` 里加条件）。未执行验证，留待你实测。

```sparksql
WITH
-- 1. 模拟 Point2D 表
Point2D AS (
    SELECT -1 as x, -1 as y UNION ALL
    SELECT 0,  0  UNION ALL
    SELECT -1, -2
)
select
    min(distance)
from (
         select
             round(sqrt((pow(t1.x - t2.x,2) + pow(t1.y - t2.y,2)) * 1.0),2) distance
         from Point2D t1
                  cross join Point2D t2
                             on t1.x <> t2.x or t1.y <> t2.y
     ) tt;
```

### 2025-04 · 每一个商品的第一笔销售明细

**源**：`SQLPractise/2025/4 每一个商品的第一笔销售明细.sql`

**考点**：按 product_id 分区、year 升序取 `row_number = 1`。

**输入 → 输出**：Sales + Product → 每个商品最早一年的销售记录 (product_id, year, quantity, price)

```sparksql
WITH
-- 1. 模拟 Sales 表
Sales AS (
    SELECT 1 AS sale_id, 100 AS product_id, 2008 AS year, 10 AS quantity, 5000 AS price UNION ALL
    SELECT 2, 100, 2009, 12, 5000 UNION ALL
    SELECT 7, 200, 2011, 15, 9000
),

-- 2. 模拟 Product 表 (此题解法中无需使用该表，但为完整性而定义)
Product AS (
    SELECT 100 AS product_id, 'Nokia' AS product_name UNION ALL
    SELECT 200, 'Apple' UNION ALL
    SELECT 300, 'Samsung'
)
/*select product_id,
       year,
       quantity,
       price

from (
         select
             product_id,
             quantity,
             year,
             price,
             row_number() over (partition by product_id order by year) as order_number
         from Sales t1

     ) t2
where order_number = 1;*/

-- 方式2
select
    t1.product_id,
    t1.year,
    t1.quantity,
    t1.price
from Sales t1
         inner join (
    select
        product_id, min(year) as first_year
    from Sales
    group by product_id
) t2
on t1.product_id = t2.product_id and t1.year = t2.first_year;
```

### 2025-05 · 最有经验的员工

**源**：`SQLPractise/2025/5 最有经验的员工.sql`

**考点**：多对多关联后，按项目内 `experience_years` 取最大者，注意同项目并列。

**输入 → 输出**：Project(project_id, employee_id) + Employee(employee_id, name, experience_years) → 每个项目经验最久的员工

```sparksql
WITH
-- 1. 模拟 Project 表
Project AS (
    SELECT 1 AS project_id, 1 AS employee_id UNION ALL
    SELECT 1, 2 UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 2, 1 UNION ALL
    SELECT 2, 4
),

-- 2. 模拟 Employee 表
Employee AS (
    SELECT 1 AS employee_id, 'Khaled' AS name, 3 AS experience_years UNION ALL
    SELECT 2, 'Ali',    2 UNION ALL
    SELECT 3, 'John',   3 UNION ALL
    SELECT 4, 'Doe',    2
)
select
    project_id,
    employee_id
from (
         select
             t1.project_id,
             t1.employee_id,
             t2.experience_years,
             dense_rank() over (partition by t1.project_id order by t2.experience_years desc) as order_number
         from Project t1
                  left join Employee t2
                            on t1.employee_id = t2.employee_id
     ) t3
where order_number = 1;
```

### 2025-07 · 第二件商品（每组第 N 个）

**源**：`SQLPractise/2025/7 第二件商品（第二主责）.sql`

**考点**：`row_number() over(partition by buyer_id order by order_date) = 2`，无第二条则输出 NULL。

**输入 → 输出**：Users + Orders + Items → 每个顾客第二件购买的商品（没有则 NULL）

「第 N 条」通用模板：左连接保留无记录的用户是关键。

```sparksql
WITH
-- 1. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, CAST('2019-01-01' AS DATE) AS join_date, 'Lenovo' AS favorite_brand UNION ALL
    SELECT 2, CAST('2019-02-09' AS DATE), 'Samsung' UNION ALL
    SELECT 3, CAST('2019-01-19' AS DATE), 'LG' UNION ALL
    SELECT 4, CAST('2019-05-21' AS DATE), 'HP'
),

-- 2. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, CAST('2019-08-01' AS DATE) AS order_date, 4 AS item_id, 1 AS buyer_id, 2 AS seller_id UNION ALL
    SELECT 2, CAST('2019-08-02' AS DATE), 2, 1, 3 UNION ALL
    SELECT 3, CAST('2019-08-03' AS DATE), 3, 2, 3 UNION ALL
    SELECT 4, CAST('2019-08-04' AS DATE), 1, 4, 2 UNION ALL
    SELECT 5, CAST('2019-08-04' AS DATE), 1, 3, 4 UNION ALL
    SELECT 6, CAST('2019-08-05' AS DATE), 2, 2, 4
),

-- 3. 模拟 Items 表
Items AS (
    SELECT 1 AS item_id, 'Samsung' AS item_brand UNION ALL
    SELECT 2, 'Lenovo' UNION ALL
    SELECT 3, 'LG' UNION ALL
    SELECT 4, 'HP'
)
select
    t4.user_id,
    if(t5.item_brand is null ,'no','yes') as 2nd_item_fav_brand
from Users t4 left join  (
    -- 获取每个卖家的第二件商品
    select
        t3.seller_id,
        t3.item_id,
        t3.item_brand,
        t3.seller_rn
    from (
             select
                 t1.seller_id, t1.order_date, t2.item_brand, t1.item_id,
                 row_number() over (partition by t1.seller_id order by t1.order_date) seller_rn
             from Orders t1
                      left join Items t2
                                on t1.item_id = t2.item_id
         ) t3
    where seller_rn = 2
) t5
on t4.favorite_brand = t5.item_brand and t4.user_id = t5.seller_id;
```

### 2025-08 · 处于中游的学生（既非第一也非最后）

**源**：`SQLPractise/2025/8 处于中游的学生（处于得过且过的人群）.sql`

**考点**：分别求出每场考试的 `min` 与 `max` 得分者，再用 `not in` 两次排除。

**输入 → 输出**：Student + Exam(exam_id, student_id, score) → 每场考试既非最高也非最低的学生

```sparksql
WITH
-- 1. 模拟 Student 表
Student AS (
    SELECT 1 AS student_id, 'Daniel' AS student_name UNION ALL
    SELECT 2, 'Jade' UNION ALL
    SELECT 3, 'Stella' UNION ALL
    SELECT 4, 'Jonathan' UNION ALL
    SELECT 5, 'Will'
),

-- 2. 模拟 Exam 表
Exam AS (
    SELECT 10 AS exam_id, 1 AS student_id, 70 AS score UNION ALL
    SELECT 10, 2, 80 UNION ALL
    SELECT 10, 3, 90 UNION ALL
    SELECT 20, 1, 80 UNION ALL
    SELECT 30, 1, 70 UNION ALL
    SELECT 30, 3, 80 UNION ALL
    SELECT 30, 4, 90 UNION ALL
    SELECT 40, 1, 60 UNION ALL
    SELECT 40, 2, 70 UNION ALL
    SELECT 40, 4, 80
)

select
    distinct
    t3.student_id,
    t4.student_name
from Student t4  left join (
    select
        exam_id,
        student_id,
        score_rank
    from (
             -- 计算每个学生在每次考试中的得分排名
             select
                 exam_id,
                 student_id,
                 dense_rank() over (partition by exam_id order by score) score_rank,
                 max(dense_rank() over (partition by exam_id order by score)) over (partition by exam_id) max_score_rank
             from Exam t1
         ) t2
    -- 过滤出得分既不是最高分也不是最低分的学生
    where max_score_rank >= 3 and t2.score_rank > 1 and t2.score_rank < max_score_rank
) t3
                           on t4.student_id = t3.student_id
-- 过滤掉从来没有参加过测验的学生
where t3.student_id is not null
order by t3.student_id;
```

### 2025-19 · 任意一天的第一个和最后一个电话都是同一人

**源**：`SQLPractise/2025/19 第一个和最后一个是同一人.sql`

**考点**：把 caller/recipient 按 `least/greatest` 归并成无序对，再按天 `row_number` 正序取 1、倒序取 1 比较。

**输入 → 输出**：Calls(caller_id, recipient_id, call_time) → 当天首末通话对象相同的 user_id

关键点：同一通电话站在双方视角各记一行，必须先做对称归一。

```sparksql
WITH
-- 1. 模拟 Calls 表
Calls AS (
    SELECT 8 AS caller_id, 4 AS recipient_id, CAST('2021-08-24 17:46:07' AS TIMESTAMP) AS call_time UNION ALL
    SELECT 4, 8, CAST('2021-08-24 19:57:13' AS TIMESTAMP) UNION ALL
    SELECT 5, 1, CAST('2021-08-11 05:28:44' AS TIMESTAMP) UNION ALL
    SELECT 8, 3, CAST('2021-08-17 04:04:15' AS TIMESTAMP) UNION ALL
    SELECT 11, 3, CAST('2021-08-17 13:07:00' AS TIMESTAMP) UNION ALL
    SELECT 8, 11, CAST('2021-08-17 22:22:22' AS TIMESTAMP)
),
user_pairs as (
    select
        user1_id,
        user2_id
    from (
             select
                 user1_id,
                 user2_id,
                 call_time,
                 call_date,
                 first_value(hash_value) over(partition by call_date order by call_time) as first_hash,
                 first_value(hash_value) over(partition by call_date order by call_time desc) as last_hash
             from (
                      select
                          least(caller_id,recipient_id) user1_id,
                          greatest(caller_id,recipient_id) user2_id,
                          hash(concat(least(caller_id,recipient_id),'-', greatest(caller_id,recipient_id))) as hash_value,
                          to_date(call_time) call_date,
                          call_time
                      from Calls t1

                  ) t2
         ) t3
    where first_hash = last_hash
    group by user1_id,user2_id
)
-- select user1_id from user_pairs
-- union all
-- select user2_id from user_pairs;

select
    case
        when idx = 1 then user1_id
        else user2_id
        end as user_id
from user_pairs t1
    lateral view explode(array(1,2)) t as idx
```

### 2025-24 · 总购买量每年严格递增的客户

**源**：`SQLPractise/2025/24 每个客户年销售额（每个组员年成绩）.sql`

**考点**：补全「从首单年到末单年」的年份序列（`sequence + explode`），缺年补 0，再 `lag` 比较严格递增。

**输入 → 输出**：Orders(order_id, customer_id, order_date, price) → 年购买量严格递增的 customer_id

与 2024/46 是同一道题；缺年补 0 是本题唯一难点。

```sparksql
WITH
-- 1. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, 1 AS customer_id, CAST('2019-07-01' AS DATE) AS order_date, 1100 AS price UNION ALL
    SELECT 2, 1, CAST('2019-11-01' AS DATE), 1200 UNION ALL
    SELECT 3, 1, CAST('2020-05-26' AS DATE), 3000 UNION ALL
    SELECT 4, 1, CAST('2021-08-31' AS DATE), 3100 UNION ALL
    SELECT 5, 1, CAST('2022-12-07' AS DATE), 4700 UNION ALL
    SELECT 6, 2, CAST('2015-01-01' AS DATE), 700  UNION ALL
    SELECT 7, 2, CAST('2017-11-07' AS DATE), 1000 UNION ALL
    SELECT 8, 3, CAST('2017-01-01' AS DATE), 900  UNION ALL
    SELECT 9, 3, CAST('2018-11-07' AS DATE), 900
),
-- 1. 计算每个客户每年的总购买量
customer_yearly_totals AS (
    select
        customer_id, year(order_date) as date_year,
        sum(price) as year_cost
    from Orders t1
    group by customer_id, year(order_date)
),
-- 2. 计算每个客户的购买年份
dim_custome_years as (
    select
        t1.customer_id,
        first_year + t.idx cost_year
    from (
             select
                 customer_id,
                 min(date_year) as first_year,
                 max(date_year) as last_year
             from customer_yearly_totals
             group by customer_id
         ) t1
    LATERAL VIEW posexplode(split(space(t1.last_year - t1.first_year), ' ')) t AS idx, val
    )
select
    customer_id
from (

         select customer_id,
                cost_year,
                year_cost,
                -- 构建连续递增组
                sum(if( year_cost - previous_year_cost > 0,0,1))  over(partition by customer_id order by cost_year) as consecutive_increase_group,
                -- 计算用户购买总年数
                count(1) over(partition by customer_id) as total_years
         from (
                  -- 计算每个客户每年的总购买量和前一年总购买量
                  select
                      t1.customer_id,
                      t1.cost_year,
                      nvl(t2.year_cost, 0) as year_cost,
                      lag(nvl(t2.year_cost, 0), 1, 0) over (partition by t1.customer_id order by cost_year) as previous_year_cost
                  from dim_custome_years t1
                           left join customer_yearly_totals t2
                                     on t1.customer_id = t2.customer_id and t1.cost_year = t2.date_year
              ) t3

     ) t4
-- 连续递增，则只考虑具有2年及以上的客户
where total_years > 1
group by customer_id, total_years,  consecutive_increase_group
-- 所有年都严格递增
having count(1) = total_years
```

### 2025-26 · 候选人排名（选票平均分配）

**源**：`SQLPractise/2025/26 候选人排名.sql`

**考点**：先算每个 voter 投了几人，`1/人数` 作为每人实得票，`sum` 后取最大者（并列全出）。

**输入 → 输出**：Votes(voter, candidate) → 得票最多（可并列）的 candidate

> ⚠️ 静态观察：结果为浮点，并列判断建议用 `rank()` 而非 `=` 直接比较浮点值。

```sparksql
WITH
-- 1. 模拟 Votes 表
Votes AS (
    SELECT 'Kathy' AS voter, CAST(null AS STRING) AS candidate UNION ALL
    SELECT 'Charles', 'Ryan' UNION ALL
    SELECT 'Charles', 'Christine' UNION ALL
    SELECT 'Charles', 'Kathy' UNION ALL
    SELECT 'Benjamin', 'Christine' UNION ALL
    SELECT 'Anthony', 'Ryan' UNION ALL
    SELECT 'Edward', 'Ryan' UNION ALL
    SELECT 'Terry', CAST(null AS STRING) UNION ALL
    SELECT 'Evelyn', 'Kathy' UNION ALL
    SELECT 'Arthur', 'Christine'
)
select
    candidate
from (
         -- 排序
         select
             *,
             rank() over (order by total_vote_share desc) as rnk
         from (
                  -- 计算每个候选人的总投票份额
                  select
                      candidate,
                      sum(vote_share) as total_vote_share
                  from (
                           -- 计算每个候选人的投票份额
                           select voter,
                                  candidate,
                                  if(candidate is null , 0, 1) / count(*) over (partition by voter) as vote_share
                           from Votes t1
                       ) t2
                  group by  candidate

              ) t3
     ) t4
where rnk = 1;
```

### 2025-34 · 保险索赔前 5 百分位

**源**：`SQLPractise/2025/34 保险索赔.sql`

**考点**：按 state 分区，`percent_rank()` 或「rank ≤ 总数×5%」筛出前 5%。

**输入 → 输出**：Fraud(policy_id, state, fraud_score) → 每个州 fraud_score 前 5% 的索赔

`percent_rank` 与 `cume_dist` 的边界差异会导致结果不同，注意题干要的是哪一种。

```sparksql
WITH
-- 1. 模拟 Fraud 表
Fraud AS (
    SELECT 1 AS policy_id, 'California' AS state, 0.92 AS fraud_score UNION ALL
    SELECT 2, 'California', 0.68 UNION ALL
    SELECT 3, 'California', 0.17 UNION ALL
    SELECT 4, 'New York',   0.94 UNION ALL
    SELECT 5, 'New York',   0.81 UNION ALL
    SELECT 6, 'New York',   0.77 UNION ALL
    SELECT 7, 'Texas',      0.98 UNION ALL
    SELECT 8, 'Texas',      0.97 UNION ALL
    SELECT 9, 'Texas',      0.96 UNION ALL
    SELECT 10, 'Florida',    0.97 UNION ALL
    SELECT 11, 'Florida',    0.98 UNION ALL
    SELECT 12, 'Florida',    0.78 UNION ALL
    SELECT 13, 'Florida',    0.88 UNION ALL
    SELECT 14, 'Florida',    0.66
)
-- 方式1
/*
select
    policy_id,
    state,
    fraud_score
from (
         select policy_id,
                state,
                fraud_score,
                count(1) over(partition by state) as total_num,
                rank() over (partition by state order by fraud_score desc) order_num,
                0.05 * count(1) over(partition by state) limit_num
         from Fraud t1
     ) t2
-- 2. 计算每个州的总数, 排名和前 5% 的限制,如果limit_num为小数，则找到排名最靠前的那一个
where order_num <= `ceil`(limit_num) or order_num = 1
order by state asc, fraud_score desc, policy_id asc;

*/
-- 方式2
select policy_id,
       state,
       fraud_score
from (
         select policy_id,
                state,
                fraud_score,
                -- 计算每个州的 fraud_score 的累积分布
                cume_dist() over(partition by state order by fraud_score asc) as cume_dist
         from Fraud t1
     ) t2
where cume_dist >= 0.95
order by state asc, fraud_score desc, policy_id asc;
```

### 2025-35 · 进步的学生（首次考 vs 最近考）

**源**：`SQLPractise/2025/35 学生是否进步.sql`

**考点**：按 (student_id, subject) 分区取 `first_value` 与 `last_value`（按 exam_date 排序），比较大小。

**输入 → 输出**：Scores(student_id, subject, score, exam_date) → 最近一次分数高于首次的 (student_id, subject)

与 2025/39 是同一道题（题干逐字相同）。

```sparksql
-- 方式1 ：错误解法，只考虑了最近一次考试成绩相比第一次考试成绩的情况，没有考虑到可能存在多次考试的情况。
WITH
-- 1. 模拟 Scores 表
Scores AS (
    SELECT 101 AS student_id, 'Math' AS subject, 70 AS score, CAST('2023-01-15' AS DATE) AS exam_date UNION ALL
    SELECT 101, 'Math',    85, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 65, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 60, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 102, 'Math',    80, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 103, 'Math',    90, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 75, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 85, CAST('2023-02-15' AS DATE)
)
select student_id,
       subject,
       first_score,
       latest_score
from (
         select
             student_id,
             subject,
             first_score,
             latest_score

         from (
                  select student_id,
                         subject,
                         score,
                         exam_date,
                         count(1) over(partition by student_id ,subject) per_num,
                         first_value(score) over(partition by student_id,subject order by exam_date) first_score,
                         first_value(score) over(partition by student_id,subject order by exam_date desc) latest_score
                  from Scores t1

              ) t2
         where per_num > 1 and latest_score > first_score
     ) t3
group by student_id,subject,first_score,latest_score
order by student_id,subject;

-- 方式2: 使用自连接
WITH
-- 1. 模拟 Scores 表
Scores AS (
    SELECT 101 AS student_id, 'Math' AS subject, 70 AS score, CAST('2023-01-15' AS DATE) AS exam_date UNION ALL
    SELECT 101, 'Math',    85, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 65, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 101, 'Physics', 60, CAST('2023-02-15' AS DATE) UNION ALL
    SELECT 102, 'Math',    80, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 103, 'Math',    90, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 75, CAST('2023-01-15' AS DATE) UNION ALL
    SELECT 104, 'Physics', 85, CAST('2023-02-15' AS DATE)
)
select
    t1.student_id,
    t1.subject,
    t1.score as first_score,
    t2.score as latest_score
from Scores t1
         inner join Scores t2
                    on t1.student_id = t2.student_id
                        and t1.subject = t2.subject
                        and t1.exam_date < t2.exam_date
                        and t1.score < t2.score
order by t1.student_id, t1.subject;
```

### 2025-45 · 每个玩家到某日为止累计玩了多少游戏

**源**：`SQLPractise/2025/45 个玩家的日期和游戏数.sql`

**考点**：`sum(games_played) over(partition by player_id order by event_date)` 前缀和。

**输入 → 输出**：Activity(player_id, device_id, event_date, games_played) → (player_id, event_date, 累计 games_played)

```sparksql
with
    Activity AS (
        SELECT 1 AS player_id, 2 AS device_id, CAST('2016-03-01' AS DATE) AS event_date, 5 AS games_played UNION ALL
        SELECT 1, 2, CAST('2016-05-02' AS DATE), 6 UNION ALL
        SELECT 1, 3, CAST('2016-06-25' AS DATE), 1 UNION ALL
        SELECT 3, 1, CAST('2016-03-02' AS DATE), 0 UNION ALL
        SELECT 3, 4, CAST('2018-07-03' AS DATE), 5
    )
/*
-- 方式1
select player_id,
       event_date,
       sum(games_played_per_date) over(partition by player_id order by event_date) as games_played_so_far
from (
         select
             player_id,
             event_date,
             sum(games_played) as games_played_per_date
         from Activity t1
         group by player_id, event_date

     ) t2
*/
-- 方式2 自链接实现 累计求和效果
select
    t2.player_id,
    t2.event_date,
    sum(t1.games_played) as games_played_so_far
from Activity t1
         inner join Activity t2
                    on t1.player_id = t2.player_id and t1.event_date <= t2.event_date
group  by t2.player_id, t2.event_date
order by t2.player_id, t2.event_date;
```

### 2025-47 · 每个公司的工资中位数

**源**：`SQLPractise/2025/47 工资的中位数.sql`

**考点**：按公司分区 `row_number` 与 `count`，取正中间一行（偶数则取两行均值）。

**输入 → 输出**：Employee(id, company, salary) → 每个公司的工资中位数

```sparksql
WITH
-- 1. 模拟 Employee 表
Employee AS (
    SELECT 1 AS id, 'A' AS company, 2341 AS salary UNION ALL
    SELECT 2, 'A', 341 UNION ALL
    SELECT 3, 'A', 15 UNION ALL
    SELECT 4, 'A', 15314 UNION ALL
    SELECT 5, 'A', 451 UNION ALL
    SELECT 6, 'A', 513 UNION ALL
    SELECT 7, 'B', 15 UNION ALL
    SELECT 8, 'B', 13 UNION ALL
    SELECT 9, 'B', 1154 UNION ALL
    SELECT 10, 'B', 1345 UNION ALL
    SELECT 11, 'B', 1221 UNION ALL
    SELECT 12, 'B', 234 UNION ALL
    SELECT 13, 'C', 2345 UNION ALL
    SELECT 14, 'C', 2645 UNION ALL
    SELECT 15, 'C', 2645 UNION ALL
    SELECT 16, 'C', 2652 UNION ALL
    SELECT 17, 'C', 65
)

-- 方式1
/*select
    company,percentile_approx(salary,0.5) as median_salary
from Employee
group by company*/

-- 方式2
/*
select
    id,
    company,
    salary
from (
         select id,
                company,
                salary,
                row_number() over (partition by company order by salary) rn,
                count(1) over (partition by company) cnt
         from Employee

     ) t1
where (cnt % 2 = 1 and rn = (cnt + 1) / 2) or (cnt % 2 = 0 and rn in (cnt / 2, cnt / 2 + 1));


*/

-- 方式3
-- 自连接的方式计算排名
/*row_number as (
    select t1.id,
        t1.company,
        t1.salary,
        count(1) as less_equal_count
    from Employee t1
    inner join  Employee t2
    on t1.company = t2.company and ( (t1.salary > t2.salary ) or (t1.salary = t2.salary and t1.id > t2.id))
    group by t1.id, t1.company,t1.salary
    ),
    -- 计算每个公司的总人数
 total_number as(
     select
         company,
         count(1) as total_count
     from Employee
     group by  company
 )
-- 最终查询
select
    t1.id,
    t1.company,
    t1.salary
from row_number t1
inner join total_number t2
    -- 核心筛选逻辑：
    -- 这个条件可以同时处理奇数和偶数的情况
    -- 奇数 (如 5): 中位数是第 3 位。r.rn >= 2.5 AND r.rn <= 3.5 --> 只有 rn=3 满足
    -- 偶数 (如 6): 中位数是第 3, 4 位。r.rn >= 3 AND r.rn <= 4 --> rn=3,4 都满足
on t1.company = t2.company and (total_count / 2.0 >= t1.less_equal_count and total_count / 2.0 <= t1.less_equal_count + 1);*/

-- 方式4
/*
这个算法的根本逻辑是：如果一个值的“中位数”，那么比它小的值的数量和比它大的值的数量应该是大致相等的。
    对于一个奇数个数的集合（如 1, 2, 3, 4, 5），中位数是 3。比 3 小的有2个值，比 3 大的也有2个值。它们的数量差是 2 - 2 = 0。
    对于一个偶数个数的集合（如 1, 2, 3, 4, 5, 6），中位数是 3 和 4。
    对于 3：比它小的值有2个，比它大的值有3个。数量差是 2 - 3 = -1。
    对于 4：比它小的值有3个，比它大的值有2个。数量差是 3 - 2 = 1。
因此，我们可以得出一个结论：一个值是中位数，当且仅当“比它小的值的数量”减去“比它大的值的数量”的结果在 -1, 0, 1 这个范围内
*/
select
    t1.id,
    t1.company,
    t1.salary
--     count(distinct t2.id) as less_count,
--     count(distinct t3.id) as greater_count,
--     count(distinct t2.id) - count(distinct t3.id) as diff_count
from Employee t1
         -- 计算比当前员工薪资高和低的员工数量，可以通过on的条件来实现如何定义比员工薪资高和低，假如存在相同薪资的员工，可以加入员工id来区分。灵活处理
         left join Employee t2 on t1.company = t2.company and t1.salary > t2.salary
    -- 计算比当前员工薪资高的员工数量
         left join Employee t3 on t1.company = t3.company and t1.salary < t3.salary
group by t1.id, t1.company, t1.salary
-- 只保留那些比当前员工薪资高和低的员工数量差在 -1, 0, 1 范围内的记录
having count(distinct t2.id) - count(distinct t3.id) between  -1 and 1;
```

### 2025-49 · 所有数字的中位数（频率表展开）

**源**：`SQLPractise/2025/49 所有数组的中位数.sql`

**考点**：`explode(sequence(1, frequency))` 把频率展开成明细行，再按总行数取中位。

**输入 → 输出**：Numbers(num, frequency) → 全体数字的中位数（保留 1 位）

展开后行数可能很大，生产上要用「累计频率卡位」而非真展开。

```sparksql
WITH
-- 1. 模拟 Numbers 表
Numbers AS (
    SELECT 0 AS num, 7 AS frequency UNION ALL
    SELECT 1, 1 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 3, 1
)
/*
select
    t2.num
from (
         select
             t1.num,
             row_number() over (order by t1.num) rn,
             count(1) over(partition by t1.num) partitial_number
         from Numbers t1
                  lateral view posexplode(split(repeat(space(1), t1.frequency - 1), ' ')) t2 as pos, value
     ) t2
where rn >= partitial_number / 2.0 and rn <= (partitial_number + 1) / 2.0
group by t2.num
*/
select
    avg(num)
from (
         select
             t1.num,
             t1.frequency,
             sum(frequency) over () total_num,
             sum(frequency) over(order by num) rn1,
             sum(frequency) over(order by num desc) rn2

         from Numbers  t1
     ) t2
where rn1 >= total_num / 2 and rn2 >= total_num / 2
```

### 2025-50 · 得票最多的候选人

**源**：`SQLPractise/2025/50 选举人的票最多的人.sql`

**考点**：`group by candidateId` 计数后取最大，并列需全出。

**输入 → 输出**：Candidate(id, name) + Vote(id, candidateId) → 得票最多的候选人姓名

与 2024/60 是同一道题。

```sparksql
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
select
    t1.name
from Candidate t1
         left join Vote t2
                   on t1.id = t2.candidateId
group by t1.id,t1.name
order by count(t2.id) desc
limit 1
```

### 2025-52 · 3 个月总工资和（滚动窗口）

**源**：`SQLPractise/2025/52 3个月总工资和.sql`

**考点**：`sum(salary) over(partition by id order by month rows between 2 preceding and current row)`，并按题干剔除最近一个月与未在职的月份。

**输入 → 输出**：Employee(id, month, salary)（2020 年逐月） → 每人的 3 个月累计工资，按 id 升序、month 降序

两个易漏条件：不含最近一个月、不含未工作的月份。

```sparksql
WITH
-- 1. 模拟 Employee 表数据
Employee AS (
    SELECT 1 AS id, 1 AS month, 20 AS salary UNION ALL
    SELECT 2, 1, 20 UNION ALL
    SELECT 1, 2, 30 UNION ALL
    SELECT 2, 2, 30 UNION ALL
    SELECT 3, 2, 40 UNION ALL
    SELECT 1, 3, 40 UNION ALL
    SELECT 3, 3, 60 UNION ALL
    SELECT 1, 4, 60 UNION ALL
    SELECT 3, 4, 70 UNION ALL
    SELECT 1, 7, 90 UNION ALL
    SELECT 1, 8, 90
)
select
    id,
    month,
    salary + if(previous_month + 1 = month,previous_salary,0) + if(pre_previous_month + 1= previous_month,pre_previous_salary,0) salary
from (
         select id,
                month,
                salary,
                lag(salary,1,0) over(partition by id order by month) previous_salary,
                lag(month,1) over(partition by id order by month) previous_month,
                lag(salary,2,0) over(partition by id order by month) pre_previous_salary,
                lag(month,2) over(partition by id order by month) pre_previous_month,
                lead(salary,1) over(partition by id order by month) next_salary
         from Employee t1
     ) t2
where next_salary is not null
```

### 2025-58 · 交换相邻两个学生的座位号

**源**：`SQLPractise/2025/58 奇数偶数互换.sql`

**考点**：id 奇偶互换：奇数 `+1`、偶数 `-1`，奇数总数的情况最后一号不动。

**输入 → 输出**：Seat(id, student) → 相邻两行交换后的 (id, student)，按 id 升序

与 2024/29 是同一道题；写法有 `if(id%2=1,id+1,id-1)` 和 `lead/lag` 两种。

```sparksql
WITH
-- 1. 模拟 Seat 表
Seat AS (
    SELECT 1 AS id, 'Abbot' AS student UNION ALL
    SELECT 2, 'Doris'   UNION ALL
    SELECT 3, 'Emerson' UNION ALL
    SELECT 4, 'Green'   UNION ALL
    SELECT 5, 'Jeames'
)
select
    case
        when stable_id % 2 == 1 and stable_id == total_nummbers then stable_id
        when stable_id % 2 == 1 and stable_id != total_nummbers then stable_id + 1
        when stable_id % 2 == 0 then stable_id - 1
        else null end as ids,
    student

from (
         select
             id,
             student,
             row_number() over (order by id) stable_id,
             count(1) over() total_nummbers
         from Seat t0
     ) t1;
```

### 2025-64 · 某日各商品的价格（时间点快照）

**源**：`SQLPractise/2025/64 某日商品的价格(某个时间点的信息).sql`

**考点**：默认价 10 元；取 `change_date <= 目标日` 中最近的一条，没有则回落默认值。

**输入 → 输出**：Products(product_id, new_price, change_date) → 2019-08-16 当天所有产品的价格

「时间点快照」通用模板，`row_number desc` 或 `max_by` 都能做。

```sparksql
WITH
-- 1. 模拟 Products 表
Products AS (
    SELECT 1 AS product_id, 20 AS new_price, CAST('2019-08-14' AS DATE) AS change_date UNION ALL
    SELECT 2, 50, CAST('2019-08-14' AS DATE) UNION ALL
    SELECT 1, 30, CAST('2019-08-15' AS DATE) UNION ALL
    SELECT 1, 35, CAST('2019-08-16' AS DATE) UNION ALL
    SELECT 2, 65, CAST('2019-08-17' AS DATE) UNION ALL
    SELECT 3, 20, CAST('2019-08-18' AS DATE)
),
-- 利用距离最近的价格即为最新的价格
conditon_prices as (
    select product_id,
           new_price,
           change_date,
           datediff,
           row_number() over (partition by product_id order by datediff ) lasted_number
    from (
             select product_id,
                    new_price,
                    change_date,
                    datediff(to_date('2019-08-16'),change_date) datediff
             from Products t0
             where change_date <= to_date('2019-08-16')
         ) t1
),
dim_product as (
    select
        product_id
    from Products
    group by  product_id
)
select
    t0.product_id,
    nvl(t1.new_price,10) price
from dim_product t0
         left join conditon_prices t1
                   on t0.product_id = t1.product_id and t1.lasted_number = 1
```

### 2025-65 · 首次订单中即时订单的比例

**源**：`SQLPractise/2025/65 首次订单中即时订单的比例.sql`

**考点**：先按 customer_id 取最早订单（`row_number = 1`），再算即时订单占比并 `round(..., 2)`。

**输入 → 输出**：Delivery(delivery_id, customer_id, order_date, customer_pref_delivery_date) → 首次订单中即时订单的百分比

```sparksql
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
```

### 2025-67 · 每个组中的获胜者

**源**：`SQLPractise/2025/67 每组中的获胜者.sql`

**考点**：把 first/second player 的得分 `union all` 成长表，按 group_id 分区累计得分，取每组最高（并列取 player_id 小）。

**输入 → 输出**：Players(player_id, group_id) + Matches(match_id, first_player, second_player, first_score, second_score) → 每组总得分最高的 player_id

与 2024/59 是同一道题。

```sparksql
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
score_situation as (
    select
        case t1.player_id
            when 1 then first_player
            when 2 then second_player
            else null end player_id,
        sum(
                case t1.player_id
                    when 1 then first_score
                    when 2 then second_score
                    else 0 end
        ) as player_total_scores
    from Matches t0
             lateral view explode(array(1,2)) t1 as player_id
    group by case t1.player_id
                 when 1 then first_player
                 when 2 then second_player
                 else null end
)
select
    group_id,
    player_id
from (
         select
             t2.group_id,
             t1.player_id,
             row_number() over (partition by t2.group_id order by t1.player_total_scores desc,t1.player_id asc) order_number
         from score_situation t1
                  left join Players t2
                            on t1.player_id = t2.player_id
     ) t3
where order_number = 1;
```

### 2025-69 · 积分排序（足球联赛得分）

**源**：`SQLPractise/2025/69 积分排序.sql`

**考点**：主客队得分分别 `union all` 汇总，胜 3 平 1 负 0，再按分数、净胜球排序。

**输入 → 输出**：Teams(team_id, team_name) + Matches(host_team, guest_team, host_goals, guest_goals) → 各队积分排名

```sparksql
WITH
-- 1. 模拟 Teams 表
Teams AS (
    SELECT 10 AS team_id, 'Leetcode FC' AS team_name UNION ALL
    SELECT 20, 'NewYork FC' UNION ALL
    SELECT 30, 'Atlanta FC' UNION ALL
    SELECT 40, 'Chicago FC' UNION ALL
    SELECT 50, 'Toronto FC'
),

-- 2. 模拟 Matches 表
Matches AS (
    SELECT 1 AS match_id, 10 AS host_team, 20 AS guest_team, 3 AS host_goals, 0 AS guest_goals UNION ALL
    SELECT 2, 30, 10, 2, 2 UNION ALL
    SELECT 3, 10, 50, 5, 1 UNION ALL
    SELECT 4, 20, 30, 1, 0 UNION ALL
    SELECT 5, 50, 30, 1, 0
),
team_scores as (
    select
        case t1.team_judge_number
            when 1 then host_team
            when 2 then guest_team
            else null end as team_id,

        sum(
                case
                    when team_judge_number = 1 and  host_goals > guest_goals then 3
                    when team_judge_number = 1 and  host_goals < guest_goals then 0
                    when team_judge_number = 1 and  host_goals = guest_goals then 1
                    when team_judge_number = 2 and  host_goals < guest_goals then 3
                    when team_judge_number = 2 and  host_goals > guest_goals then 0
                    when team_judge_number = 2 and  host_goals = guest_goals then 1
                    else 0 end
        ) as num_points
    from Matches t0
             lateral view explode(array(1,2)) t1 as team_judge_number
    group by
        case t1.team_judge_number
            when 1 then host_team
            when 2 then guest_team
            else null end
)
select
    t0.team_id,
    t0.team_name,
    nvl(t1.num_points,0) as num_points
from Teams t0
         left join team_scores t1
                   on t0.team_id = t1.team_id
```

### 2025-73 · 餐馆七日均值

**源**：`SQLPractise/2025/73 餐馆七日均值 .sql`

**考点**：按日聚合后 `rows between 6 preceding and current row` 求均值，或 `range between` 按日期区间（更稳妥）。

**输入 → 输出**：Customer(customer_id, name, visited_on, amount) → 从第 7 天起每天的 7 日消费总额与均值

文件里给了两种写法，注释明确指出「若某天无人消费，基于 range between 更准确」。

```sparksql
WITH
-- 1. 模拟 Customer 表
Customer AS (
    SELECT 1 AS customer_id, 'Jhon' AS name, CAST('2019-01-01' AS DATE) AS visited_on, 100 AS amount UNION ALL
    SELECT 2, 'Daniel', CAST('2019-01-02' AS DATE), 110 UNION ALL
    SELECT 3, 'Jade', CAST('2019-01-03' AS DATE), 120 UNION ALL
    SELECT 4, 'Khaled', CAST('2019-01-04' AS DATE), 130 UNION ALL
    SELECT 5, 'Winston', CAST('2019-01-05' AS DATE), 110 UNION ALL
    SELECT 6, 'Elvis', CAST('2019-01-06' AS DATE), 140 UNION ALL
    SELECT 7, 'Anna', CAST('2019-01-07' AS DATE), 150 UNION ALL
    SELECT 8, 'Maria', CAST('2019-01-08' AS DATE), 80 UNION ALL
    SELECT 9, 'Jaze', CAST('2019-01-09' AS DATE), 110 UNION ALL
    SELECT 1, 'Jhon', CAST('2019-01-10' AS DATE), 130 UNION ALL
    SELECT 3, 'Jade', CAST('2019-01-10' AS DATE), 150
)

-- 解法1 由于 每天至少有一位顾客
/*select visited_on,
       amount,
       round(average_amount,2) average_amount
from (
         select
             visited_on,
             sum(amount_date) over(order by visited_on rows between 6 preceding and current row )amount,
             avg(amount_date) over(order by visited_on rows between 6 preceding and current row )average_amount,
             row_number() over (order by visited_on) order_number
         from (
                  select
                      visited_on,
                      sum(amount) amount_date
                  from Customer t0
                  group by t0.visited_on

              ) t1
     ) t2
where order_number >= 7;*/


-- 解法2 针对如果存在该店不是每天都有顾客消费的情况，基于range between计算更加准确
/*
select visited_on,
       amount,
       round(average_amount,2) average_amount
from (
         select
             visited_on,
             sum(amount_date) over(order by visited_on range between 6 preceding and current row )amount,
             avg(amount_date) over(order by visited_on range between 6 preceding and current row )average_amount,
             row_number() over (order by visited_on) order_number
         from (
                  select
                      visited_on,
                      sum(amount) amount_date
                  from Customer t0
                  group by t0.visited_on

              ) t1
     ) t2
where order_number >= 7;
*/


-- 解法3 处理如果该店不是每天都有顾客消费，并且最近7日的消费需要考虑没有消费的日期，比如1号有消费，2号有消费，中间无顾客消费，直到8号才有新的消费。
        ,
-- 步骤 1: 按天聚合，计算每日的总消费金额
per_date_amount AS (
    SELECT
        visited_on,
        SUM(amount) AS date_amount
    FROM
        Customer AS t0
    GROUP BY
        t0.visited_on
),

-- 步骤 2: 生成一个包含所有日期的完整日期维度表
dim_date AS (
    SELECT
        date_add(t2.earliest_date, t3.index) AS date_value
    FROM (
             -- 找到数据中的最早和最晚日期
             SELECT
                 MIN(visited_on) AS earliest_date,
                 MAX(visited_on) AS lasted_date
             FROM
                 per_date_amount AS t1
         ) AS t2
             -- 使用 LATERAL VIEW posexplode 技巧生成从最早到最晚的连续日期序列
             LATERAL VIEW posexplode(split(repeat(' ', datediff(t2.lasted_date, t2.earliest_date)), ' ')) t3 AS index, value
)

-- 步骤 4: 最终查询和格式化输出
SELECT
    date_value,
    amount,
    ROUND(average_amount, 2) AS average_amount
FROM (
         -- 步骤 3: 计算7天的滑动窗口总和与平均值
         SELECT
             date_value,
             -- 计算从6天前到今天的总金额 (7天窗口)
             SUM(date_amount) OVER (ORDER BY date_valueROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS amount,
             -- 计算从6天前到今天的平均金额 (7天窗口)
             AVG(date_amount) OVER (ORDER BY date_valueROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS average_amount,
             -- 添加行号，用于过滤掉前面不足7天的数据
             ROW_NUMBER() OVER (ORDER BY date_value) AS order_number
         FROM (
                  -- 将完整日期表与每日金额表左连接，确保没有消费的日期金额为0
                  SELECT
                      t0.date_value,
                      NVL(t1.date_amount, 0) AS date_amount
                  FROM
                      dim_date AS t0
                          LEFT JOIN
                      per_date_amount AS t1 ON t0.date_value = t1.visited_on
              ) AS t2
     )
-- 过滤掉前6天，因为它们的7日滑动窗口数据不完整
WHERE
    order_number >= 7;
```

### 2026-02 · 按要求排列表格（性别交替）

**源**：`SQLPractise/2026/2. 按照要求排列表格.sql`

**考点**：三种性别各自按 user_id 编号，再用编号把三组「拉链式」拼接。

**输入 → 输出**：Genders(user_id, gender) → female / other / male 交替排列，组内按 user_id 升序

与 spark md §76「重新排列性别表」是同一题。

```sparksql
WITH Genders AS (
    SELECT 4 AS user_id, 'male' AS gender UNION ALL
    SELECT 7 AS user_id, 'female' AS gender UNION ALL
    SELECT 2 AS user_id, 'other' AS gender UNION ALL
    SELECT 5 AS user_id, 'male' AS gender UNION ALL
    SELECT 1 AS user_id, 'other' AS gender UNION ALL
    SELECT 9 AS user_id, 'female' AS gender UNION ALL
    SELECT 3 AS user_id, 'female' AS gender UNION ALL
    SELECT 6 AS user_id, 'other' AS gender UNION ALL
    SELECT 8 AS user_id, 'male' AS gender
)
-- ==========================================
-- 请在此处往下编写你的 Hive SQL 解答
-- ==========================================
, t1 as (
    select user_id,
           gender,
           row_number() over (order by gender_group_number,
               case gender
                    when 'female' then 1
                    when 'other' then 2
               else 3 end ) final_number
    from (
             select
                 user_id,
                 gender,
                 row_number() over (partition by gender order by user_id) gender_group_number
             from Genders
         )
)
select user_id,
       gender
from t1;
```

### 2026-06 · 股票波峰与波谷标记（多股票）

**源**：`SQLPractise/2026/6.股票波峰与波谷标记.sql`

**考点**：`partition by stock_id order by trade_date` 后 `lag/lead` 比较，输出三态标记。

**输入 → 输出**：stock_daily_price(stock_id, trade_date, close_price) → 每日标注 波峰 / 波谷 / 正常波动

吸收了 2024-04 作为单股票变体。

```sparksql
WITH stock_daily_price AS (
    SELECT 'TECH001' AS stock_id, '2024-01-01' AS trade_date, CAST(100.00 AS DECIMAL(10,2)) AS close_price
    UNION ALL SELECT 'TECH001', '2024-01-02', CAST(103.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-03', CAST(107.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-04', CAST(105.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-05', CAST(101.40 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-06', CAST(104.60 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-07', CAST(109.30 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-08', CAST(106.70 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-09', CAST(110.40 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-10', CAST(108.90 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-11', CAST(104.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-12', CAST(107.10 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-13', CAST(111.60 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-14', CAST(109.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-15', CAST(113.40 AS DECIMAL(10,2))

    UNION ALL SELECT 'BANK002', '2024-01-01', CAST(50.00 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-02', CAST(48.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-03', CAST(51.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-04', CAST(49.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-05', CAST(52.60 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-06', CAST(51.30 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-07', CAST(47.90 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-08', CAST(50.10 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-09', CAST(53.40 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-10', CAST(52.00 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-11', CAST(49.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-12', CAST(51.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-13', CAST(54.70 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-14', CAST(53.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-15', CAST(55.10 AS DECIMAL(10,2))

    UNION ALL SELECT 'ENERGY003', '2024-01-01', CAST(80.00 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-02', CAST(82.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-03', CAST(79.30 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-04', CAST(81.70 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-05', CAST(85.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-06', CAST(83.40 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-07', CAST(86.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-08', CAST(84.90 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-09', CAST(82.10 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-10', CAST(85.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-11', CAST(88.30 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-12', CAST(86.70 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-13', CAST(83.90 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-14', CAST(87.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-15', CAST(90.50 AS DECIMAL(10,2))
)
select stock_id,
       trade_date,
       close_price,
       prev_price,
       next_price,
       price_type,
       cast(case price_type
                when '正常' then 0
                else greatest(abs(close_price-prev_price),abs(close_price-next_price)) end
           as decimal(10,2)) as  amplitude
from (

         select stock_id,
                trade_date,
                close_price,
                prev_price,
                next_price,
                case
                    when close_price > prev_price and close_price > next_price then '波峰'
                    when close_price < prev_price and close_price < next_price then '波谷'
                    else '正常' end  as price_type

         from (

                  select stock_id,
                         trade_date,
                         close_price,
                         lag(close_price,1,null) over(partition by stock_id order by trade_date asc) prev_price,
                      lead(close_price,1,null) over(partition by stock_id order by trade_date asc) next_price

                  from stock_daily_price
              ) a
     )b
order by stock_id asc , trade_date asc;
```

### 2026-07 · 电商品类销售额 TopN 多维分析

**源**：`SQLPractise/2026/7.topN问题.sql`

**考点**：一个文件里叠了多个需求：品类内商品 TopN、跨维度汇总、并列处理，考查 TopN 的组合拳。

**输入 → 输出**：daily_category_sales(order_id, sale_date, category, product_name, sale_amount, sale_qty) → 按各需求输出

这是全库最长的一题（10.9 KB），适合当 TopN 的综合练习。

```sparksql
-- ======================== 模拟数据 ========================
-- 通过 WITH 生成数据，用规律性 + 随机感混合的方法构造测试数据集

WITH raw_data AS (
    -- 手机数码品类
    SELECT 1 AS order_id, '2024-01-01' AS sale_date, '手机数码' AS category, 'iPhone15'   AS product_name, CAST(5600.00 AS DECIMAL(10,2)) AS sale_amount, 2  AS sale_qty
    UNION ALL SELECT 2,  '2024-01-01', '手机数码', 'iPhone15',   CAST(5600.00 AS DECIMAL(10,2)), 2
    UNION ALL SELECT 3,  '2024-01-01', '手机数码', 'iPadAir',    CAST(4200.00 AS DECIMAL(10,2)), 3
    UNION ALL SELECT 4,  '2024-01-02', '手机数码', 'iPhone15',   CAST(2800.00 AS DECIMAL(10,2)), 1
    UNION ALL SELECT 5,  '2024-01-02', '手机数码', 'AirPods',    CAST(1999.00 AS DECIMAL(10,2)), 5
    UNION ALL SELECT 6,  '2024-01-05', '手机数码', 'iPadAir',    CAST(8400.00 AS DECIMAL(10,2)), 6
    UNION ALL SELECT 7,  '2024-01-05', '手机数码', 'iPhone15',   CAST(8400.00 AS DECIMAL(10,2)), 3
    UNION ALL SELECT 8,  '2024-01-10', '手机数码', 'GalaxyS24',  CAST(3999.00 AS DECIMAL(10,2)), 2
    UNION ALL SELECT 9,  '2024-01-10', '手机数码', 'AirPods',    CAST(3998.00 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 10, '2024-01-15', '手机数码', 'iPhone15',   CAST(28000.00 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 11, '2024-01-15', '手机数码', 'GalaxyS24',  CAST(9998.00 AS DECIMAL(10,2)), 5
    UNION ALL SELECT 12, '2024-01-20', '手机数码', 'iPadAir',    CAST(12600.00 AS DECIMAL(10,2)), 9
    UNION ALL SELECT 13, '2024-01-20', '手机数码', 'AirPods',    CAST(5997.00 AS DECIMAL(10,2)), 15
    UNION ALL SELECT 14, '2024-02-01', '手机数码', 'iPhone15',   CAST(11200.00 AS DECIMAL(10,2)), 4
    UNION ALL SELECT 15, '2024-02-05', '手机数码', 'GalaxyS24',  CAST(7998.00 AS DECIMAL(10,2)), 4
    UNION ALL SELECT 16, '2024-02-10', '手机数码', 'iPadAir',    CAST(16800.00 AS DECIMAL(10,2)), 12
    UNION ALL SELECT 17, '2024-02-15', '手机数码', 'iPhone15',   CAST(14000.00 AS DECIMAL(10,2)), 5
    UNION ALL SELECT 18, '2024-02-15', '手机数码', 'iPhone15',   CAST(2800.00 AS DECIMAL(10,2)), 1
    UNION ALL SELECT 19, '2024-02-20', '手机数码', 'AirPods',    CAST(9995.00 AS DECIMAL(10,2)), 25
    UNION ALL SELECT 20, '2024-02-20', '手机数码', 'GalaxyS24',  CAST(3999.00 AS DECIMAL(10,2)), 2
    UNION ALL SELECT 21, '2024-03-01', '手机数码', 'iPhone15',   CAST(25200.00 AS DECIMAL(10,2)), 9
    UNION ALL SELECT 22, '2024-03-01', '手机数码', 'iPadAir',    CAST(8400.00 AS DECIMAL(10,2)), 6
    UNION ALL SELECT 23, '2024-03-10', '手机数码', 'GalaxyS24',  CAST(5999.00 AS DECIMAL(10,2)), 3
    UNION ALL SELECT 24, '2024-03-10', '手机数码', 'AirPods',    CAST(3998.00 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 25, '2024-03-10', '手机数码', 'GalaxyS24',  CAST(1999.50 AS DECIMAL(10,2)), 1
    UNION ALL SELECT 26, '2024-03-20', '手机数码', 'iPhone15',   CAST(19600.00 AS DECIMAL(10,2)), 7
    UNION ALL SELECT 27, '2024-03-20', '手机数码', 'iPadAir',    CAST(12600.00 AS DECIMAL(10,2)), 9
    UNION ALL SELECT 28, '2024-03-20', '手机数码', 'AirPods',    CAST(5997.00 AS DECIMAL(10,2)), 15
    UNION ALL SELECT 29, '2024-03-31', '手机数码', 'iPhone15',   CAST(16800.00 AS DECIMAL(10,2)), 6
    UNION ALL SELECT 30, '2024-03-31', '手机数码', 'GalaxyS24',  CAST(11997.00 AS DECIMAL(10,2)), 6


    -- 食品生鲜品类
    UNION ALL SELECT 90, '2024-01-01', '食品生鲜', '牛奶',     CAST(299.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 91, '2024-01-01', '食品生鲜', '鸡蛋',     CAST(159.00 AS DECIMAL(10,2)), 30
    UNION ALL SELECT 92, '2024-01-03', '食品生鲜', '苹果',     CAST(499.00 AS DECIMAL(10,2)), 25
    UNION ALL SELECT 93, '2024-01-03', '食品生鲜', '牛奶',     CAST(598.00 AS DECIMAL(10,2)), 100
    UNION ALL SELECT 94, '2024-01-05', '食品生鲜', '鸡蛋',     CAST(477.00 AS DECIMAL(10,2)), 90
    UNION ALL SELECT 95, '2024-01-05', '食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 96, '2024-01-05', '食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 97, '2024-01-08', '食品生鲜', '牛奶',     CAST(1196.00 AS DECIMAL(10,2)), 200
    UNION ALL SELECT 98, '2024-01-10', '食品生鲜', '鸡蛋',     CAST(954.00 AS DECIMAL(10,2)), 180
    UNION ALL SELECT 99, '2024-01-10', '食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 100,'2024-01-15','食品生鲜', '牛奶',     CAST(897.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 101,'2024-01-15','食品生鲜', '鸡蛋',     CAST(318.00 AS DECIMAL(10,2)), 60
    UNION ALL SELECT 102,'2024-02-01','食品生鲜', '牛奶',     CAST(1196.00 AS DECIMAL(10,2)), 200
    UNION ALL SELECT 103,'2024-02-05','食品生鲜', '牛奶',     CAST(897.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 104,'2024-02-05','食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 105,'2024-02-05','食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 106,'2024-02-10','食品生鲜', '鸡蛋',     CAST(1113.00 AS DECIMAL(10,2)), 210
    UNION ALL SELECT 107,'2024-02-10','食品生鲜', '牛奶',     CAST(598.00 AS DECIMAL(10,2)), 100
    UNION ALL SELECT 108,'2024-02-15','食品生鲜', '苹果',     CAST(2994.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 109,'2024-02-15','食品生鲜', '鸡蛋',     CAST(636.00 AS DECIMAL(10,2)), 120
    UNION ALL SELECT 110,'2024-02-15','食品生鲜', '鸡蛋',     CAST(318.00 AS DECIMAL(10,2)), 60
    UNION ALL SELECT 111,'2024-02-20','食品生鲜', '牛奶',     CAST(1495.00 AS DECIMAL(10,2)), 250
    UNION ALL SELECT 112,'2024-02-20','食品生鲜', '鸡蛋',     CAST(1431.00 AS DECIMAL(10,2)), 270
    UNION ALL SELECT 113,'2024-03-01','食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 114,'2024-03-01','食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 115,'2024-03-01','食品生鲜', '牛奶',     CAST(299.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 116,'2024-03-05','食品生鲜', '鸡蛋',     CAST(1113.00 AS DECIMAL(10,2)), 210
    UNION ALL SELECT 117,'2024-03-05','食品生鲜', '苹果',     CAST(998.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 118,'2024-03-05','食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 119,'2024-03-10','食品生鲜', '牛奶',     CAST(897.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 120,'2024-03-10','食品生鲜', '牛奶',     CAST(598.00 AS DECIMAL(10,2)), 100
    UNION ALL SELECT 121,'2024-03-10','食品生鲜', '牛奶',     CAST(299.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 122,'2024-03-15','食品生鲜', '鸡蛋',     CAST(1590.00 AS DECIMAL(10,2)), 300
    UNION ALL SELECT 123,'2024-03-15','食品生鲜', '苹果',     CAST(2994.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 124,'2024-03-15','食品生鲜', '苹果',     CAST(399.20 AS DECIMAL(10,2)), 20
    UNION ALL SELECT 125,'2024-03-15','食品生鲜', '鸡蛋',     CAST(636.00 AS DECIMAL(10,2)), 120
    UNION ALL SELECT 126,'2024-03-20','食品生鲜', '牛奶',     CAST(1495.00 AS DECIMAL(10,2)), 250
    UNION ALL SELECT 127,'2024-03-20','食品生鲜', '鸡蛋',     CAST(1431.00 AS DECIMAL(10,2)), 270
    UNION ALL SELECT 128,'2024-03-20','食品生鲜', '鸡蛋',     CAST(477.00 AS DECIMAL(10,2)), 90
    UNION ALL SELECT 129,'2024-03-25','食品生鲜', '苹果',     CAST(2994.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 130,'2024-03-25','食品生鲜', '牛奶',     CAST(1794.00 AS DECIMAL(10,2)), 300
    UNION ALL SELECT 131,'2024-03-31','食品生鲜', '鸡蛋',     CAST(1590.00 AS DECIMAL(10,2)), 300
    UNION ALL SELECT 132,'2024-03-31','食品生鲜', '牛奶',     CAST(299.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 133,'2024-03-31','食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 134,'2024-03-31','食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 135,'2024-03-31','食品生鲜', '鸡蛋',     CAST(159.00 AS DECIMAL(10,2)), 30
)
/*

select
    c.product_name,
    c.quart_product_amt as sale_amount,
    c.rank_num
from (

         select product_name,
                quart_product_amt,
                row_number() over (order by quart_product_amt desc) rank_num
         from (

                  select
                      a.product_name,
                      sum(a.sale_qty * a.sale_amount) quart_product_amt
                  from raw_data a
                  where substr(a.sale_date,1,7) <= '2024-03'
                  group by a.product_name
              )b
     )c
where c.rank_num <= 3
order by c.product_name ,c.quart_product_amt;
*/

-- 方式2
        ,
     mid_count as (
         select
             a.product_name,
             sum(a.sale_qty * a.sale_amount) quart_product_amt
         from raw_data a
         where substr(a.sale_date,1,7) <= '2024-03'
         group by a.product_name
     )
select
    t1.product_name,
    t1.quart_product_amt,
    count(*) + 1 rank_num
from mid_count t1
         left join mid_count t2
                   on t1.product_name != t2.product_name and t1.quart_product_amt < t2.quart_product_amt
group by t1.product_name,t1.quart_product_amt
having count(*) + 1 <=3
order by t1.product_name asc ,t1.quart_product_amt asc;
```

---

## C · 行转列、列转行与炸裂展开（8 题）

`collect_list` 聚合、`explode / posexplode + lateral view` 展开、`split` 切分、`concat_ws` 回拼。难点几乎都在「顺序」和「空值」：collect_list 不保证有序，posexplode 能顺手带上元素下标。

### 2024-12 · 学生成绩表的成绩转成一行

**源**：`SQLPractise/2024/12学生成绩表中的每个学生的成绩转为一行.sql`

**考点**：`split` 切分逗号串 + `posexplode` 按下标对齐姓名与分数，再 `collect_list` 回聚。

**输入 → 输出**：ClassScores(class, student="小A,小B", score="80,92") → 每个学生的 (class, 合并后的 student, 合并后的 score)

与 2024/18 是变体对：12 是炸开、18 是还原。

```sparksql
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

### 2024-17 · 用户存款期数维表构建（炸裂生成期数）

**源**：`SQLPractise/2024/17用户存款期数维表构建.sql`

**考点**：按合同取最早 `value_date`，`explode(sequence(...))` 生成 term 期，`add_months` 递推日期，再左连回原表做累计求和。

**输入 → 输出**：contract, value_date, amount, term → 每个合同按期的维表（每期应有日期 + 累计金额）

文件头注释把四步思路写全了，是很好的模板题。

```sparksql
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

### 2024-18 · 炸裂中元素索引位置的使用（还原爆炸表）

**源**：`SQLPractise/2024/18炸裂中元素索引位置的使用.sql`

**考点**：对已炸开的多行做 `collect_list(concat_ws(...))` 重组，验证「炸开-还原」是否可逆。

**输入 → 输出**：class, student, score 明细 → 每个学生聚合回一行（含 class 与 score 列表）

与 2024/12 是变体对；注意 NULL 参与 concat 时会拖累整串。

```sparksql
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

### 2024-22 · collect_list 如何保证合并后有序

**源**：`SQLPractise/2024/22colllect_list(）由于内部底层实现原因往往合并值是乱序的，如何保 证合并后内容的有序性？.sql`

**考点**：三条路：`sort_array(collect_list(...))`、`collect_list` 前先 `distribute by / sort by`、或 `collect_list(struct(排序键, 值))` 后按排序键取。

**输入 → 输出**：key, value → 按 key 聚合且 value 有序的数组

这是全库唯一的「纯函数行为」题，没有业务数据；答案是三个片段而非一个完整查询。

```sparksql
-- 方法一：使用 sort_array()
SELECT
  key,
  sort_array(collect_list(value)) AS sorted_values
FROM
  your_table
GROUP BY
  key;

-- 方法二：结合 SORT BY 和 collect_list()
SELECT
  key,
  collect_list(value) AS values_list
FROM
  (SELECT key, value FROM your_table
   DISTRIBUTE BY key
   SORT BY key, value) t
GROUP BY
  key;
```

### 2024-56 · 每日每种商品购买清单（按周内星期行转列）

**源**：`SQLPractise/2024/56 每日每种商品购买清单（简单的行转列).sql`

**考点**：先按 `dayofweek` 取出 7 列，再 `sum(case when 星期=… then quantity else 0 end)` 透视，最后补全 7 个固定列。

**输入 → 输出**：Orders(order_id, customer_id, order_date, item_id, quantity) + Items → 每件商品的 item_category、item_id、item_name 与周一至周日的购买数量

难点是「7 列必须全在」，即使某天无数据也要出 0。

```sparksql
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


-- 根据date_format函数的用法，可以使用 date_format(date，'EEEE') 来获取星期几的名称
-- 例如，date_format('2020-06-01', 'EEEE') 返回 'Monday'
select date_format('2020-06-01', 'EEEE');
```

### 2025-02 · 行转列（按大洲透视）

**源**：`SQLPractise/2025/2 行转列.sql`

**考点**：`row_number() over(partition by continent order by name)` 当行号，再 `max(case when continent=... )` 透视。

**输入 → 输出**：student(name, continent) → 三列 America / Asia / Europe，各自按姓名升序排成一行

与 2024-56 的区别：这里没有数值列可聚合，只能靠行号 + max 拼。

```sparksql
WITH
-- 1. 模拟 student 表
Student AS (
    SELECT 'Jane' AS name, 'America' AS continent UNION ALL
    SELECT 'Pascal', 'Europe' UNION ALL
    SELECT 'Xi', 'Asia' UNION ALL
    SELECT 'Jack', 'America'
)
/*
    -- 方式1， join方式
    rn as (
        select name,
               continent,
               row_number() over (partition by continent order by name) as rn
        from Student t1
    ),
    america_student as (
        select
            *
        from rn t2
        where continent = 'America'
    ),
    asia_student as (
        select
            *
        from rn t2
        where continent = 'Asia'
    ),
    europe_student as (
        select
            *
        from rn t2
        where continent = 'Europe'
    )
select
    t1.name as America,
    t2.name as Asia,
    t3.name as Europe
from america_student t1
left join asia_student t2
on t1.rn = t2.rn
left join europe_student t3
on t1.rn = t3.rn;

*/

-- 方式2，group by方式
select
    max(case when continent = 'America' then name end) as America,
    max(case when continent = 'Asia' then name end) as Asia,
    max(case when continent = 'Europe' then name end) as Europe
from (
         select
             name,
             continent,
             row_number() over (partition by continent order by name) as rn
         from Student t1
     ) t2
group by rn;
```

### 2025-60 · 各种条件人群支出（单端 / 双端透视）

**源**：`SQLPractise/2025/60 各种条件人群支出.sql`

**考点**：同一天同一用户可能同时出现在 desktop 与 mobile：先判「仅桌面 / 仅手机 / 两端都有」，再用 `cross join` 三个固定标签补全，保证三类都出数。

**输入 → 输出**：Spending(user_id, spend_date, platform, amount) → 每天三类人群的人数与总支出

「固定分类必须全出」的经典解法：造一个 3 行的维度表再去 left join。

```sparksql
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
```

### 2026-05 · 参与培训的人次（课程炸裂计数）

**源**：`SQLPractise/2026/5.参与培训的人次.sql`

**考点**：`course` 字段是逗号串，`explode(split(course, ','))` 炸开后按课程计数即人次。

**输入 → 输出**：cultivate_tb(info_id, staff_id, course="course1,course2") → 每门课程的参与人次

与 2026-04 是变体对：04 数「人」（去重 staff_id），05 数「人次」（炸开后计数）。

```sparksql
WITH cultivate_tb AS (
    SELECT 101 AS info_id, 1 AS staff_id, 'course1,course2' AS course UNION ALL
    SELECT 102 AS info_id, 2 AS staff_id, 'course2' AS course UNION ALL
    SELECT 103 AS info_id, 3 AS staff_id, 'course1,course3' AS course UNION ALL
    SELECT 104 AS info_id, 4 AS staff_id, 'course1,course2,course3' AS course UNION ALL
    SELECT 105 AS info_id, 5 AS staff_id, 'course3' AS course UNION ALL
    SELECT 106 AS info_id, 6 AS staff_id, NULL AS course UNION ALL
    SELECT 107 AS info_id, 7 AS staff_id, 'course1,course2' AS course
)
-- ==========================================
-- 请在此处往下编写你的解答SQL
-- ==========================================

/*select
    count(distinct t2.staff_id,t2.inner_course)
from (
         select
             staff_id,
             course,
             pos_courses.inner_course
         from cultivate_tb t1
                  lateral view explode(split(t1.course,',')) pos_courses as inner_course
     ) t2;*/


select
    sum(array_size(staff_course_set))
from (

         select
             staff_id,
             array_distinct(flatten(collect_list(split(course,',')))) staff_course_set
         from cultivate_tb t1
         group by staff_id
     ) t2
;
```

---

## D · 留存、新增与转化漏斗（7 题）

套路固定：先用 `min(日期)` 或 `row_number` 定基准日（安装日 / 首购日 / 首次行为），再回表 join 或自连接看「基准日 + N 天」是否还有行为，最后除总数得率。

### 2024-09 · 用户收购分析（首购分类 + 30 天复购率）

**源**：`SQLPractise/2024/test.sql` L613–L682

**考点**：先用 `min(pay_time)` 定首次购买，用 `max(if(cate=…,1,0))` 打「只买服装 / 只买非服装 / 都买」标签，再回表算 30 天内复购任意类目与复购同类目两个率。

**输入 → 输出**：tmp_sales + goods_info → 每月三类首购用户数、30 天内复购任意类目率、复购同类目率

与 2024-08 共用同一套建表语句；这是全库逻辑最长的一题（拆成多个 CTE）。

```sparksql
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

### 2024-16 · 平台 N 日留存率（三解法）

**源**：`SQLPractise/2024/16平台留存计算.sql`

**考点**：取每个 uid 的首次访问日当注册日，再看「注册日 + 7」当天是否仍有访问，相除得率。

**输入 → 输出**：uid, date → 每个注册日的 7 日留存率

文件里有解法一 / 二 / 三，是最值得对比阅读的一题。

<details>
<summary>建表与造数语句（原文照录，点击展开）</summary>

```sparksql
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
-- ```sparksql
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
```

</details>

```sparksql
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

### 2024-20 · 留存率的计算

**源**：`SQLPractise/2024/20留存率的计算.sql`

**考点**：同 2024-16：以首次访问日为基准，回表判断后续日期是否回流。

**输入 → 输出**：uid, date_str → 留存率

> 该文件**注释区一行注释都没有**，题名由文件名与造数结构推定（已由你确认属留存类）。

```sparksql
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

### 2024-51 · 每个活动每个阶段的完成用户数量

**源**：`SQLPractise/2024/51 每个活动每个阶段的完成用户数量.sql`

**考点**：先按 (act_id, user_id) 数订单数，再用 `count(distinct case when order_count >= act_config_cnt then user_id end)` 卡阶段。

**输入 → 输出**：act_order(order_id, act_id, user_id, pay_date) + act_config(act_id, act_stage, act_config_cnt) → (act_id, act_stage, required_orders, completed_users)

> ⚠️ 静态观察：题干要求「最近 5 天内」，但 SQL 正文里**没有日期过滤**，`pay_date` 未被使用。

```sparksql
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

### 2024-64 · 游戏留存（按安装日期输出新增数与次日留存率）

**源**：`SQLPractise/2024/64 游戏留存（用户留存，拓客、各种活动效果等.sql`

**考点**：`min(event_date)` 为安装日，统计当日新增人数，再看「安装日 +1」是否登录，算首日留存率。

**输入 → 输出**：Activity(player_id, device_id, event_date, games_played) → 每个安装日的 (新增人数, 次日留存率)

与 2025-46 同源：46 只输出一个总比率，本条按安装日期分组输出。

```sparksql
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
```

### 2025-46 · 次日再次登录的玩家比率

**源**：`SQLPractise/2025/46 次日登录的人数.sql`

**考点**：`min(event_date)` 定首次登录，自连接「首次日 +1」的记录，`count / 总人数` 并 `round 2` 位。

**输入 → 输出**：Activity → 首次登录次日仍登录的玩家占比（单一数值）

与 2024/31 是同一道题。

```sparksql
WITH
-- 1. 模拟 Activity 表
Activity AS (
    SELECT 1 AS player_id, 2 AS device_id, CAST('2016-03-01' AS DATE) AS event_date, 5 AS games_played UNION ALL
    SELECT 1, 2, CAST('2016-03-02' AS DATE), 6 UNION ALL
    SELECT 2, 3, CAST('2017-06-25' AS DATE), 1 UNION ALL
    SELECT 3, 1, CAST('2016-03-02' AS DATE), 0 UNION ALL
    SELECT 3, 4, CAST('2018-07-03' AS DATE), 5
),
user_daily_activity AS (
    select
        player_id,
        event_date
    from Activity t1
    group by player_id, event_date
),
registered_activity as (
    select player_id,
           event_date
    from (
             select player_id,
                    event_date,
                    row_number() over (partition by player_id order by event_date) as rn
             from user_daily_activity
         ) t1
    where rn = 1
)
/*
select
    round(count(distinct if(date_add(t1.event_date,1) = t2.event_date,t2.event_date,null)) / count(distinct t1.player_id),2) as fraction
from registered_activity t1
         -- 首次登录的玩家 与 每日登录表链接
         left join user_daily_activity t2
on t1.player_id = t2.player_id and t1.event_date < t2.event_date;*/

select
    round(count(distinct t2.player_id) / count(distinct t1.player_id),2) as fraction
from registered_activity t1
         -- 首次登录的玩家 与 每日登录表链接
         left join user_daily_activity t2
                   on t1.player_id = t2.player_id and date_add(t1.event_date, 1) = t2.event_date
```

### 2026-08 · 每日新增用户数

**源**：`SQLPractise/2026/8.每日新增用户数.sql`

**考点**：`min(login_date) group by id` 得每人新增日，再按新增日 `count`。窗口函数版是 `row_number() over(partition by id order by login_date) = 1`。

**输入 → 输出**：id, login_date → 每天的新增用户数

文件里给了方法 1（min 分组）与方法 2（row_number），两种都写了。

```sparksql
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
```

---

## E · 区间重叠、时间线与并发（7 题）

两条线：一是**打点法**——开始 +1、结束 -1，按时间排序后累计求和即当前并发数；二是**重叠合并**——`lag/lead` 比较相邻区间端点，或借助日期序列展开后去重计数。

### 2024-06 · 同时在线最大人数（直播间并发）

**源**：`SQLPractise/2024/test.sql` L366–L438

**考点**：开始时间 +1、结束时间 -1，`sum() over(order by 时间)` 累计即在线人数，再取 `max`。

**输入 → 输出**：live_room_activity(room_id, user_id, login_time, logout_time, dt) → 某时间段内每个直播间的最大同时在线人数

同一文件 L439–L474 还有「按小时切分」的变体，见本节末尾。

<details>
<summary>建表与造数语句（原文照录，点击展开）</summary>

```sparksql
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
```

</details>

```sparksql
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
```

#### 变体：每个直播间每小时的同时在线最大人数

**源**：`SQLPractise/2024/test.sql` L439–L474

**差异**：先用 `posexplode(split(space(小时差)))` 把一条登录记录拆成若干「小时槽」，再按槽分组数人数，把「时间点并发」变成了「时间片并发」。

```sparksql
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
```


### 2024-23 · 合并区间 / 每品牌活动天数（重叠算一天）

**源**：`SQLPractise/2024/23合并区间（区间交集）.sql`

**考点**：把每个区间展开成日期序列（`posexplode(split(space(datediff(...))))`），`count(distinct 日期)` 去重。

**输入 → 输出**：brand, begin_date, end_date → 每个品牌去重后的活动天数

与 大数据md §数据的合并（数据交集）SQL 正文一致；另有「真正合并区间端点」的写法可对照。

```sparksql
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
        COALESCE(unix_timestamp(logout_time), unix_timestamp('2023-04-11 00:00:00')) AS time_point,
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
            coalesce(unix_timestamp(logout_time), unix_timestamp('2023-04-11 00:00:00')) as end_time
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

### 2024-33 · 户额度信息（进出累计 + 余额）

**源**：`SQLPractise/2024/33 户额度信息（进出的问题，直播在线人数，订单的过程数，订单 的总额).sql`

**考点**：同一笔转账对付款人是减、对收款人是加：`union all` 出两条带正负号的流水，累计求和得余额，再判是否 < 0。

**输入 → 输出**：Users(user_id, user_name, credit) + Transactions(trans_id, paid_by, paid_to, amount, transacted_on) → 每个用户当前余额与是否透支

「进/出」通用模板，md 版注释把它类比到直播在线人数、订单过程数。与 2025-11 同表不同问。

```sparksql
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

### 2025-25 · 同一大厅的重叠活动合并

**源**：`SQLPractise/2025/25 同一个大厅举办的重叠活动.sql`

**考点**：按 hall 分区、start_day 排序，`lag(max_end)` 与当前 start 比较：当前 start 更晚则新开一段。

**输入 → 输出**：HallEvents(hall_id, start_day, end_day) → 合并后的 (hall_id, start_day, end_day)

与 2024-23 思路相反：这条是真的把重叠区间合并成一段，不是展开数天数。

```sparksql
WITH
-- 1. 模拟 HallEvents 表
HallEvents AS (
    SELECT 1 AS hall_id, CAST('2023-01-13' AS DATE) AS start_day, CAST('2023-01-14' AS DATE) AS end_day UNION ALL
    SELECT 1, CAST('2023-01-14' AS DATE), CAST('2023-01-17' AS DATE) UNION ALL
    SELECT 1, CAST('2023-01-18' AS DATE), CAST('2023-01-25' AS DATE) UNION ALL
    SELECT 2, CAST('2022-12-09' AS DATE), CAST('2022-12-23' AS DATE) UNION ALL
    SELECT 2, CAST('2022-12-13' AS DATE), CAST('2022-12-17' AS DATE) UNION ALL
    SELECT 3, CAST('2022-12-01' AS DATE), CAST('2023-01-30' AS DATE)
),
overlap_events_group as (
    select
        hall_id,
        start_day,
        end_day,
        -- 使用累计求和的方式来标记新的重叠活动窗口开始
        sum(is_new_flag) over (partition by hall_id order by start_day, end_day) as group_id
    from (
             -- 判断是否日期重叠 datediff 和 lag 函数实现
             select hall_id,
                    start_day,
                    end_day,
                    lag(end_day,1,start_day) over (partition by hall_id order by start_day,end_day) as previous_end_day,
                    datediff(lag(end_day,1,start_day) over (partition by hall_id order by start_day,end_day),start_day) as diff,
                    `if`(datediff(lag(end_day,1,start_day) over (partition by hall_id order by start_day,end_day),start_day) >= 0, 0, 1) as is_new_flag
             from (
                      -- 去重数据
                      select hall_id,
                             start_day,
                             end_day
                      from HallEvents t1
                      group by hall_id, start_day, end_day
                  ) t1
         ) t2

)
-- 每个重叠活动窗口的开始和结束日期
select
    hall_id,
    min(start_day) as start_day,
    max(end_day) as end_day
from overlap_events_group t1
group by hall_id,group_id
```

### 2025-30 · 是否排班重叠 1（重叠计数）

**源**：`SQLPractise/2025/30 是否排班重叠1.sql`

**考点**：按员工分区、start_time 排序，用 `lag(end_time)` 与前一条比：前一条结束晚于当前开始即重叠。

**输入 → 输出**：EmployeeShifts(employee_id, start_time, end_time) → 每个员工的重叠排班数量

与 2025-31 是变体对。

```sparksql
WITH
-- 1. 模拟 EmployeeShifts 表
EmployeeShifts AS (
    SELECT 1 AS employee_id, '08:00:00' AS start_time, '12:00:00' AS end_time UNION ALL
    SELECT 1, '11:00:00', '15:00:00' UNION ALL
    SELECT 1, '14:00:00', '18:00:00' UNION ALL
    SELECT 2, '09:00:00', '17:00:00' UNION ALL
    SELECT 2, '16:00:00', '20:00:00' UNION ALL
    SELECT 3, '10:00:00', '12:00:00' UNION ALL
    SELECT 3, '13:00:00', '15:00:00' UNION ALL
    SELECT 3, '16:00:00', '18:00:00' UNION ALL
    SELECT 4, '08:00:00', '10:00:00' UNION ALL
    SELECT 4, '09:00:00', '11:00:00'
)

select
    employee_id,
    count(*) as overlapping_shifts
from (
         select
             employee_id,
             start_time,
             lag(end_time,1) over(partition by employee_id order by start_time, end_time) previous_end_time
         from EmployeeShifts t1
     ) t2
where unix_timestamp(previous_end_time,'HH:mm:ss') - unix_timestamp(start_time,'HH:mm:ss') >= 0
group by employee_id
```

### 2025-31 · 是否排班重叠 2（最大并发 + 总重叠时长）

**源**：`SQLPractise/2025/31 是否排班重叠2.sql`

**考点**：在 30 的基础上进一步求「某时刻最多几个班重叠」与「所有重叠区间的总分钟数」。

**输入 → 输出**：EmployeeShifts → 每个员工的最大重叠班次数与重叠总时长（分钟）

需要先求重叠区间端点，再按区间求时长，是 30 的升级版。

```sparksql
WITH
-- 1. 模拟 EmployeeShifts 表，使用 TIMESTAMP 类型代替 datetime
EmployeeShifts AS (
    SELECT 1 AS employee_id, CAST('2023-10-01 09:00:00' AS TIMESTAMP) AS start_time, CAST('2023-10-01 17:00:00' AS TIMESTAMP) AS end_time UNION ALL
    SELECT 1, CAST('2023-10-01 15:00:00' AS TIMESTAMP), CAST('2023-10-01 23:00:00' AS TIMESTAMP) UNION ALL
    SELECT 1, CAST('2023-10-01 16:00:00' AS TIMESTAMP), CAST('2023-10-02 00:00:00' AS TIMESTAMP) UNION ALL
    SELECT 2, CAST('2023-10-01 09:00:00' AS TIMESTAMP), CAST('2023-10-01 17:00:00' AS TIMESTAMP) UNION ALL
    SELECT 2, CAST('2023-10-01 11:00:00' AS TIMESTAMP), CAST('2023-10-01 19:00:00' AS TIMESTAMP) UNION ALL
    SELECT 3, CAST('2023-10-01 09:00:00' AS TIMESTAMP), CAST('2023-10-01 17:00:00' AS TIMESTAMP)
),

-- Part 1: 计算最大并发班次数
-- 2. 将每个班次拆分为开始(+1)和结束(-1)两个事件点
TimePoints AS (
    SELECT employee_id, start_time AS event_time, 1 AS event_type FROM EmployeeShifts
    UNION ALL
    SELECT employee_id, end_time AS event_time, -1 AS event_type FROM EmployeeShifts
),
-- 3. 使用窗口函数计算每个时间点的并发班次数
RunningCounts AS (
    SELECT
        employee_id,
        -- 按时间排序，计算事件的累积和，即为并发数
        -- 如果一个“开始”事件和一个“结束”事件发生在同一时刻，我们总是先处理“开始”事件，再处理“结束”事件，这样才能准确反应重叠班次的峰值
        SUM(event_type) OVER (PARTITION BY employee_id ORDER BY event_time, event_type DESC) AS concurrent_shifts
    FROM TimePoints
),
-- 4. 找到每个员工的最大并发数
MaxOverlapCalc AS (
    SELECT
        employee_id,
        COALESCE(MAX(concurrent_shifts), 0) AS max_overlapping_shifts
    FROM RunningCounts
    GROUP BY employee_id
),

-- Part 2: 计算总重叠时长
-- 5. 自连接，找到所有在同一天开始且有重叠的班次对，并计算其重叠时长
DurationOverlapCalc AS (
    SELECT
        e1.employee_id,
        -- 计算所有成对重叠的总分钟数
        SUM(
                (unix_timestamp(LEAST(e1.end_time, e2.end_time)) - unix_timestamp(e2.start_time)) / 60
        ) AS total_overlap_duration
    FROM
        EmployeeShifts e1
            JOIN
        EmployeeShifts e2 ON e1.employee_id = e2.employee_id
            -- 比较不同的班次
            AND e1.start_time < e2.start_time
            -- 必须在同一天开始
            AND to_date(e1.start_time) = to_date(e2.start_time)
    -- 重叠条件: 第一个班次的结束时间晚于第二个的开始时间
    WHERE e1.end_time > e2.start_time
    GROUP BY
        e1.employee_id
)

-- 6. 最终合并结果
SELECT
    m.employee_id,
    m.max_overlapping_shifts,
    CAST(COALESCE(d.total_overlap_duration, 0) AS BIGINT) AS total_overlap_duration
FROM
    MaxOverlapCalc m
        LEFT JOIN
    DurationOverlapCalc d ON m.employee_id = d.employee_id
ORDER BY
    m.employee_id;
```

### 2026-01 · 每辆车的乘客人数（公交到站 + 乘客到达）

**源**：`SQLPractise/2026/1. 每辆车的乘客人数2.sql`

**考点**：对每辆公交，统计「到达时间 ≤ 公交到达时间」且还没上过车的乘客，用窗口函数或累计计数分配。

**输入 → 输出**：Buses(bus_id, arrival_time, capacity) + Passengers(passenger_id, arrival_time) → 每辆车实际载客人数（受容量与「先到先上」约束）

与 spark md §75「公交车上的乘客数量」是同一题。

```sparksql
WITH Buses AS (
    SELECT 1 AS bus_id, 2 AS arrival_time, 1 AS capacity UNION ALL
    SELECT 2 AS bus_id, 4 AS arrival_time, 10 AS capacity UNION ALL
    SELECT 3 AS bus_id, 7 AS arrival_time, 2 AS capacity
),
     Passengers AS (
         SELECT 11 AS passenger_id, 1 AS arrival_time UNION ALL
         SELECT 12 AS passenger_id, 1 AS arrival_time UNION ALL
         SELECT 13 AS passenger_id, 5 AS arrival_time UNION ALL
         SELECT 14 AS passenger_id, 6 AS arrival_time UNION ALL
         SELECT 15 AS passenger_id, 7 AS arrival_time
     )
-- ==========================================
-- 请在此处往下编写你的 Hive SQL 解答
-- 提示：此题在不使用存储过程/循环的情况下，
-- 非常考验对开窗函数（Window Functions）的综合运用
-- ==========================================
/*
思路：每个乘客上来那辆bus，匹配不上，赶不上车；匹配多个bus，取最近乘客到达时间的那个; 最后还需要根据bus的空余容量做筛选。
*/
, choice_bus as (
    select
        t1.passenger_id,
        t2.bus_id,
        t2.capacity,
        t1.arrival_time,
        t2.arrival_time,
        row_number() over (partition by t1.passenger_id order by t2.arrival_time - t1.arrival_time asc) as candidate_order_number
    from Passengers t1
    left join Buses t2
    on t1.arrival_time <= t2.arrival_time
    where t2.bus_id is not null
)
select
    t5.bus_id,
    if(capacity >= passengers_cnt, passengers_cnt, capacity) passengers_cnt
from (
         select
             t3.bus_id,
             t3.capacity,
             count(1) passengers_cnt
         from Buses t3
                  left join choice_bus t4
                            on t3.bus_id = t4.bus_id and t4.candidate_order_number = 1
         group by t3.bus_id,t3.capacity
     ) t5
order by passengers_cnt;

    // 以下为错误思路实现，会导致遗漏乘客
/*, choice_bus as (
    select
        t1.passenger_id,
        t2.bus_id,
        t2.capacity,
        t1.arrival_time,
        t2.arrival_time,
        row_number() over (partition by t1.passenger_id order by t2.arrival_time - t1.arrival_time asc) as candidate_order_number
    from Passengers t1
             left join Buses t2
                       on t1.arrival_time <= t2.arrival_time
    where t2.bus_id is not null
)
select
    bus_id,
    count(passenger_id) passengers_cnt
from (
         select
             bus_id,
             capacity,
             passenger_id,
             count(1) over (partition by bus_id order by passenger_id) accuate_passgener_numbers
         from choice_bus t3
         where t3.candidate_order_number = 1
     ) t4
where capacity >= accuate_passgener_numbers
group by bus_id
order by passengers_cnt;*/
```

---

## F · 条件聚合与分组判定（27 题）

用 `sum(case when ... then 1 else 0 end)` 把行内条件压成列，再用 `having` 做分组级判断；「全称量词」（所有科目都及格、所有行都满足）常靠 `count` 对比或 `min/max` 与阈值比较实现。

### 2024-08 · 各月各类目商品在国家销售后 30 天内的退货率

**源**：`SQLPractise/2024/test.sql` L526–L612

**考点**：销售表左连退款表（同 member/sku/pay_time），`datediff(refund_time,pay_time) < 30` 过滤，`sum(refund_cnt)/sum(sale_cnt)` 得率。

**输入 → 输出**：tmp_sales + tmp_refund + goods_info → 每月 × 类目 × 国家的 30 天退货率

**这一题只存在于 `test.sql`**；与 2024-09 共用同一套建表语句。

<details>
<summary>建表与造数语句（原文照录，点击展开）</summary>

```sparksql
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
```

</details>

```sparksql
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
```

### 2024-15 · 每门课都大于 60 分的学生

**源**：`SQLPractise/2024/15学生科目成绩.sql`

**考点**：全称量词：`having min(score) > 60`，或 `sum(if(score<=60,1,0)) = 0`，再回连取全部课程明细。

**输入 → 输出**：student + class + score 三表 → 所有课程都 >60 分的学生的全部课程成绩

「全部满足」是本类最核心的模板。

<details>
<summary>建表与造数语句（原文照录，点击展开）</summary>

```sparksql
-- ### 需求总结
--
-- 查询每一门课成绩都大于60分的学生，并返回这些学生的所有课程成绩。
--
-- ### 数据源建表语句


-- 学生表
drop table if exists student;
CREATE TABLE IF NOT EXISTS student (
    id INT,                 -- 学生ID
    student_name STRING     -- 学生姓名
) COMMENT '学生表';

-- 课程表
CREATE TABLE IF NOT EXISTS class (
    id INT,                 -- 课程ID
    class_name STRING       -- 课程名称
) COMMENT '课程表';

-- 选课表
CREATE TABLE IF NOT EXISTS sc (
    sid INT,                -- 学生ID
    cid INT,                -- 课程ID
    score INT               -- 成绩
) COMMENT '选课表';


-- ### 模拟数据

-- 插入学生表模拟数据
INSERT INTO student VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie');

-- 插入课程表模拟数据
INSERT INTO class VALUES
(101, 'Math'),
(102, 'English'),
(103, 'Science');

-- 插入选课表模拟数据
INSERT INTO sc VALUES
(1, 101, 65),     -- Alice Math 65
(1, 102, 75),     -- Alice English 75
(1, 103, 80),     -- Alice Science 80
(2, 101, 50),     -- Bob Math 50
(2, 102, 70),     -- Bob English 70
(3, 101, 90),     -- Charlie Math 90
(3, 102, 85),     -- Charlie English 85
(3, 103, 88);     -- Charlie Science 88


-- ### 整理明确需求


/*
需求：
1. 从选课表查询成绩都大于60分的学生。
2. 获取这些学生的所有课程成绩。
3. 学生需在所有已选课程中得分均超过60分。

-- 需求分解：
1. 找到每个学生的最低分大于60的学生ID。
2. 根据学生ID查询这些学生的所有课程成绩。
*/

select
    t1.id,
    t1.class_name,
    t2.sid,
    t3.student_name,
    t2.score
from class t1
left join sc t2
on t1.id = t2.cid
left join student t3
on t2.sid = t3.id;
```

</details>

```sparksql
with class_dim as (
    select
        collect_list(map(id,class_name)) class_list
    from class
)
select
    t1.student_id,
    t1.student_name,
    t2.c_map['id'] class_id,
    t2.c_map['class_name'] class_name/*,
    nvl(tt.score,0) score*/
    from (
        select
            t3.id student_id,
            t3.student_name
        from student t3
    ) t1
lateral view explode(class_dim.class_list) t2 as c_map;
/*left join sc tt
on t1.student_id = tt.sid and t2.c_map['id'] = tt.cid;*/

-- 方式一：笛卡尔积实现全科目匹配，比较总科名数和及格的科目数据
with tmp as (select tt.student_id,
                    tt.student_name,
                    tt.class_id,
                    tt.class_name,
                    nvl(t3.score, 0) score
             from (select t1.id student_id,
                          t1.student_name,
                          t2.id class_id,
                          t2.class_name
                   from student t1
                            cross join class t2) tt
                      left join sc t3
                                on tt.student_id = t3.sid and tt.class_id = t3.cid)
select student_id,
       student_name,
       class_id,
       class_name,
       score
from (
select
    *,
    count(*) over(partition by student_id) total_classs_nums,
    count(if(score > 60, 1, null)) over(partition by student_id) pass_classs_nums
from tmp) t
where total_classs_nums = pass_classs_nums;


-- 方式二 MAPJOIN， 比较总科名数和及格的科目数据
with tmp as (select tt.student_id,
                    tt.student_name,
                    tt.class_id,
                    tt.class_name,
                    nvl(t3.score, 0) score
             from (SELECT /*+ MAPJOIN(t2) */ t1.id AS student_id,
                                             t1.student_name,
                                             t2.id AS class_id,
                                             t2.class_name
                   FROM student t1
                   cross JOIN class t2) tt
             left join sc t3
             on tt.student_id = t3.sid and tt.class_id = t3.cid)
select student_id,
       student_name,
       class_id,
       class_name,
       score
from (select *,
             count(*) over (partition by student_id)                       total_classs_nums,
             count(if(score > 60, 1, null)) over (partition by student_id) pass_classs_nums
      from tmp) t
where total_classs_nums = pass_classs_nums;

-- 假设我使用的hive环境强制不能使用 1 = 1等类似的恒等条件或者笛卡尔join
-- 可以构建虚拟列实现效果
with tmp as (select tt.student_id,
                    tt.student_name,
                    tt.class_id,
                    tt.class_name,
                    nvl(t3.score, 0) score
             from (select t1.id AS student_id,
                          t1.student_name,
                          t2.id AS class_id,
                          t2.class_name
                       FROM (select id, student_name, 1 as join_key from student) t1
                                left JOIN (select id, class_name, 1 as join_key from class) t2
                                          on t1.join_key = t2.join_key
                       where t1.id is not null) tt
                      left join sc t3
                      on tt.student_id = t3.sid and tt.class_id = t3.cid)
select student_id,
       student_name,
       class_id,
       class_name,
       score
from (select *,
             count(*) over (partition by student_id)                       total_classs_nums,
             count(if(score > 60, 1, null)) over (partition by student_id) pass_classs_nums
      from tmp) t
where total_classs_nums = pass_classs_nums;


-- 方式三 通过查询学生得分最低的科目是否大于60，来判断每门科都及格
with tmp as (select tt.student_id,
                    tt.student_name,
                    tt.class_id,
                    tt.class_name,
                    nvl(t3.score, 0) score
             from (select t1.id AS student_id,
                          t1.student_name,
                          t2.id AS class_id,
                          t2.class_name
                       FROM (select id, student_name, 1 as join_key from student) t1
                                left JOIN (select id, class_name, 1 as join_key from class) t2
                                          on t1.join_key = t2.join_key
                       where t1.id is not null) tt
                      left join sc t3
                      on tt.student_id = t3.sid and tt.class_id = t3.cid)
select student_id,
       student_name,
       class_id,
       class_name,
       score
from (select *,
             min(score) over (partition by student_id) min_score
      from tmp) t
where min_score > 60;
```

### 2024-30 · 回答率最高的题目

**源**：`SQLPractise/2024/30回答率最高的题目.sql`

**考点**：`count(distinct answer_id) / count(distinct if(action='show', ...))` 算每题回答率，取最大（并列全出）。

**输入 → 输出**：SurveyLog(id, action, question_id, answer_id, q_num, timestamp) → 回答率最高的 question_id

与 2025-51 是变体对：本条只出最高的一道，51 出每道题的回答率。

```sparksql
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
```

### 2024-32 · 顾客订单分析（多维汇总）

**源**：`SQLPractise/2024/32 顾客订单分析.sql`

**考点**：Customers × Orders × OrderItems × Products 四表关联后做多维条件聚合。

**输入 → 输出**：四张订单表 → 按顾客维度的汇总指标

与 2025-32 是同源不同问（已确认不合并）：本条输出维度更宽，2025-32 限定「订单数 > 3」。

```sparksql
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

### 2024-36 · 工资缴税（分组税率）

**源**：`SQLPractise/2024/36 工资缴税.sql`

**考点**：先求每个公司的最高工资，用 `case when max_salary < 1000 then 0 ...` 定税率，再乘个人工资得税额。

**输入 → 输出**：Salaries(company_id, employee_id, employee_name, salary) → (company_id, employee_id, employee_name, salary)，末列名虽叫 salary，实际是**应缴税额** `round(salary*tax,0)`

税率取决于「公司最高工资」而非个人工资；输出列名沿用 salary，极易误读成税后工资。

```sparksql
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

### 2024-41 · 分配工作量

**源**：`SQLPractise/2024/41 分配工作量.sql`

**考点**：先按 (team, project, employee) 汇总 `workload`，再用 `avg(total_workload) over(partition by team)` 求团队均值，两者同列输出。

**输入 → 输出**：Project(project_id, employee_id, workload) + Employees(employee_id, name, team) → (team, project_id, employee_id, employee_name, total_workload, team_avg_workload)

名字叫「分配」，实际是一道「明细 vs 组均值」的窗口对比题。

```sparksql
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

### 2024-42 · 首次会话为观众型的用户，其主播会话数量

**源**：`SQLPractise/2024/42 会话(有条件的开始和后续).sql`

**考点**：先用 `row_number` 标记每个用户的首次会话类型，筛出 Viewer，再数该用户的 Streamer 会话数。

**输入 → 输出**：Sessions(user_id, session_start, session_end, session_id, session_type) → (user_id, sessions_count)，按 sessions_count 降序、user_id 降序

与 2024-40 / 2024-65 同一张表，但问的是「条件 + 计数」，所以归 F 而非 A。

```sparksql
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

### 2024-44 · 确认乘客状态

**源**：`SQLPractise/2024/44 确认乘客状.sql`

**考点**：按 `booking_time` 排序给乘客编号（`count` 窗口 / `rank` 窗口两种），位次 ≤ capacity 则 Confirmed。

**输入 → 输出**：Flights(flight_id, capacity) + Passengers(passenger_id, flight_id, booking_time) → (passenger_id, booking_time, status∈{Confirmed,Waitlist})，按 passenger_id 升序

与 `2025/27 航班是否满员` **是同一道题的逐字重复**（题干、数据、答案全一致），已合并至此。本文件含三种写法：`count(distinct)` 窗口、`if` 内联、`rank()` 窗口。

```sparksql
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

### 2024-66 · 球员分数段打标

**源**：`SQLPractise/2024/球员分数分析.sql`

**考点**：把每个得分拆到 100 分一档的桶里（`ceil(score/100)`），再按桶累加，输出每档得多少分。

**输入 → 输出**：palyer, collector, score, game_room, game_date → 球员在各分数段的得分合计

原文件**没有编号**，已新编为 2024-66；需求写在文件头的 `--` 注释里。

```sparksql
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



-- 详细分析查看语雀文档： https://www.yuque.com/aoyixiong/nwfsd7/hk1v77258gg7hnqw 中的11球员得分分析案例

select concat_ws();
```

### 2025-06 · 符合条件的书籍（近一年销量 < 10）

**源**：`SQLPractise/2025/6 符合条件的书籍（符合条件的人群、没有过实习期的）.sql`

**考点**：`available_from <= '2019-06-23'` 过滤上架满一个月的书，左连 12 个月窗口内的订单，`sum(quantity) < 10 or is null` 判销量不足。

**输入 → 输出**：Books(book_id, name, available_from) + Orders(order_id, book_id, quantity, dispatch_date) → 2019-06-23 之前 30 天内销量少于 10 本的 book_id

与 2024/28 是同一道题；「销量为 0 也要算」是唯一坑点。

```sparksql
WITH
-- 1. 模拟 Books 表
Books AS (
    SELECT 1 AS book_id, 'Kalila And Demna' AS name, CAST('2010-01-01' AS DATE) AS available_from UNION ALL
    SELECT 2, '28 Letters',       CAST('2012-05-12' AS DATE) UNION ALL
    SELECT 3, 'The Hobbit',       CAST('2019-06-10' AS DATE) UNION ALL
    SELECT 4, '13 Reasons Why',   CAST('2019-06-01' AS DATE) UNION ALL
    SELECT 5, 'The Hunger Games', CAST('2008-09-21' AS DATE)
),

-- 2. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, 1 AS book_id, 2 AS quantity, CAST('2018-07-26' AS DATE) AS dispatch_date UNION ALL
    SELECT 2, 1, 1, CAST('2018-11-05' AS DATE) UNION ALL
    SELECT 3, 3, 8, CAST('2019-06-11' AS DATE) UNION ALL
    SELECT 4, 4, 6, CAST('2019-06-05' AS DATE) UNION ALL
    SELECT 5, 4, 5, CAST('2019-06-20' AS DATE) UNION ALL
    SELECT 6, 5, 9, CAST('2009-02-02' AS DATE) UNION ALL
    SELECT 7, 5, 8, CAST('2010-04-13' AS DATE)
)

select
    t3.book_id,
    t3.name
from (
         select book_id,
                sum(nvl(quantity,0)) as total_quantity
         from Orders t1
         where dispatch_date >= add_months('2019-06-23', -12) and dispatch_date <= '2019-06-23'
         group by book_id
         having sum(nvl(quantity,0)) < 10
     ) t2
         right join Books t3 on t2.book_id = t3.book_id
where t3.available_from <= add_months('2019-06-23', -1);
```

### 2025-09 · 判断条件 / 布尔表达式求值

**源**：`SQLPractise/2025/9 判断条件(打分相关，画像相关，人群划分).sql`

**考点**：把 left_operand / operator / right_operand 各 join 一次 Variables 取值，再 `case` 分派比较符号。

**输入 → 输出**：Variables(name, value) + Expressions(left_operand, operator, right_operand) → (left_operand, operator, right_operand, true/false)

三表自连接是本题的骨架；operator 是枚举所以 case 可穷举。

```sparksql
WITH
-- 1. 模拟 Variables 表
Variables AS (
    SELECT 'x' AS name, 66 AS value UNION ALL
    SELECT 'y', 77
),

-- 2. 模拟 Expressions 表
Expressions AS (
    SELECT 'x' AS left_operand, '>' AS operator, 'y' AS right_operand
    UNION ALL
    SELECT 'x', '<', 'y' UNION ALL
    SELECT 'x', '=', 'y' UNION ALL
    SELECT 'y', '>', 'x' UNION ALL
    SELECT 'y', '<', 'x' UNION ALL
    SELECT 'x', '=', 'x'
)
select
    left_operand,
    operator,
    right_operand,
    -- 嵌套case 语句来计算布尔表达式的值
    case operator
        when '>' then case when left_value > right_value then 'true' else 'false' end
        when '<' then case when left_value < right_value then 'true' else 'false' end
        when '=' then case when left_value = right_value then 'true' else 'false' end
        end as value
from (
         -- 将 Expressions 表中的操作数与 Variables 表中的值进行关联获取变量的值
         select t1.left_operand,
                t1.operator,
                t1.right_operand,
                t2.value left_value,
                t3.value right_value
         from Expressions t1
                  -- 左连接 Variables 表两次,Variables变量唯一，不会导致数据膨胀
                  left join Variables t2
                            on t1.left_operand = t2.name
                  left join Variables t3
                            on t1.right_operand = t3.name
     ) t4;
```

### 2025-11 · 检查银行账户是否透支

**源**：`SQLPractise/2025/11 检查银行账户是否透支（假期和工作量恒定.sql`

**考点**：与 2024-33 同表：`union all` 出带正负号的流水，累计求和得余额，`< 0` 即透支。

**输入 → 输出**：Users + Transactions → (user_id, user_name, 当前额度, 是否透支)

与 2024-33 是变体对：33 输出余额，本条额外输出透支标记。

```sparksql
WITH
-- 1. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, 'Moustafa' AS user_name, 100 AS credit UNION ALL
    SELECT 2, 'Jonathan', 200 UNION ALL
    SELECT 3, 'Winston', 10000 UNION ALL
    SELECT 4, 'Luis', 800
),

-- 2. 模拟 Transactions 表
Transactions AS (
    SELECT 1 AS trans_id, 1 AS paid_by, 3 AS paid_to, 400 AS amount, CAST('2020-08-01' AS DATE) AS transacted_on UNION ALL
    SELECT 2, 3, 2, 500, CAST('2020-08-02' AS DATE) UNION ALL
    SELECT 3, 2, 1, 200, CAST('2020-08-03' AS DATE)
)
select
    users.user_id,
    users.user_name,
    users.credit + coalesce(t4.current_cost_credit,0) as credit,
    case
        when users.credit + coalesce(t4.current_cost_credit,0) < 0
            then 'Yes'
        else 'No'
        end as credit_limit_breached
from Users users left join (
    -- 计算每个用户的当前成本信用,并对交易日期倒序取目前最新的记录
    select
        user_id,
        transacted_on,
        sum(amount) over(partition by user_id order by transacted_on) as current_cost_credit,
        row_number() over (partition by user_id order by transacted_on desc) rn
    from (
             -- 将 paid_by 和 paid_to 的金额分别处理为负和正
             select
                 paid_by as user_id,
                 -amount as amount,
                 transacted_on
             from Transactions t1
             union all
             select
                 paid_to,
                 amount,
                 transacted_on
             from Transactions t2

         ) t3
) t4
on t4.user_id = users.user_id and t4.rn = 1;
```

### 2025-15 · 账户情况（三档工资分类，缺失补 0）

**源**：`SQLPractise/2025/15 账户情况.sql`

**考点**：`case` 分三档聚合，再用一个 3 行的固定维度表 left join，保证没有账户的档位出 0。

**输入 → 输出**：Accounts(account_id, income) → (category, accounts_count)，含 Low/Average/High 三档

与 2025-60 同一个套路：固定分类靠造维度表补齐。

```sparksql
WITH
-- 1. 模拟 Accounts 表
Accounts AS (
    SELECT 3 AS account_id, 108939 AS income UNION ALL
    SELECT 2, 12747  UNION ALL
    SELECT 8, 87709  UNION ALL
    SELECT 6, 91796
)
select
    t1.category,
    nvl(t2.accounts_count, 0) as accounts_count
from (
         select explode(`array`('Low Salary', 'Average Salary','High Salary')) category
     ) t1
         left join (
    select
        case
            when t1.income < 20000 then 'Low Salary'
            when t1.income >= 20000 and t1.income <= 50000 then 'Average Salary'
            when t1.income > 50000 then 'High Salary'
            end as category,
        count(t1.account_id) as accounts_count
    from Accounts t1
    group by
        case
            when t1.income < 20000 then 'Low Salary'
            when t1.income >= 20000 and t1.income <= 50000 then 'Average Salary'
            when t1.income > 50000 then 'High Salary'
            end
) t2
                   on t1.category = t2.category;
```

### 2025-18 · 用户满意度（确认率）

**源**：`SQLPractise/2025/18 用户满意度.sql`

**考点**：注册表左连「按用户算的确认率」，`count(if(action='confirmed',1,null)) / count(*)` 后 `round 2` 位。

**输入 → 输出**：Signups(user_id, time_stamp) + Confirmations(user_id, time_stamp, action) → (user_id, confirmation_rate)，没有任何确认记录的用户出 0.00

分母是该用户自己的确认记录条数，不是全体注册人数 —— 最容易搞错的地方。

```sparksql
WITH
-- 1. 模拟 Signups 表
Signups AS (
    SELECT 3 AS user_id, CAST('2020-03-21 10:16:13' AS TIMESTAMP) AS time_stamp UNION ALL
    SELECT 7, CAST('2020-01-04 13:57:59' AS TIMESTAMP) UNION ALL
    SELECT 2, CAST('2020-07-29 23:09:44' AS TIMESTAMP) UNION ALL
    SELECT 6, CAST('2020-12-09 10:39:37' AS TIMESTAMP)
),

-- 2. 模拟 Confirmations 表
Confirmations AS (
    SELECT 3 AS user_id, CAST('2021-01-06 03:30:46' AS TIMESTAMP) AS time_stamp, 'timeout' AS action UNION ALL
    SELECT 3, CAST('2021-07-14 14:00:00' AS TIMESTAMP), 'timeout' UNION ALL
    SELECT 7, CAST('2021-06-12 11:57:29' AS TIMESTAMP), 'confirmed' UNION ALL
    SELECT 7, CAST('2021-06-13 12:58:28' AS TIMESTAMP), 'confirmed' UNION ALL
    SELECT 7, CAST('2021-06-14 13:59:27' AS TIMESTAMP), 'confirmed' UNION ALL
    SELECT 2, CAST('2021-01-22 00:00:00' AS TIMESTAMP), 'confirmed' UNION ALL
    SELECT 2, CAST('2021-02-28 23:59:59' AS TIMESTAMP), 'timeout'
)
select
    t1.user_id,
    round(coalesce(t2.confirmation_rate, 0.00), 2) as confirmation_rate
from Signups t1
         left join (
    select
        user_id,
        count(if(action = 'confirmed', 1, null)) / count(*) as confirmation_rate
    from Confirmations t1
    group by user_id
) t2
                   on t1.user_id = t2.user_id
```

### 2025-22 · 选择合适的面试候选人

**源**：`SQLPractise/2025/22 选择合适的面试候选人.sql`

**考点**：候选人须「得过金牌」或「连续三场拿牌」，两种条件分别用「关联奖牌表」与「滑动三行 + count」判断。

**输入 → 输出**：Contests(contest_id, gold_medal, silver_medal, bronze_medal) + Users(user_id, mail) → 符合条件的 user_id 与 mail

「连续三场」是 gaps & islands 的窗口版，注意 Contest 连续 ID 的前提由题干保证。

```sparksql
WITH
-- 1. 模拟 Contests 表
Contests AS (
    SELECT 190 AS contest_id, 1 AS gold_medal, 5 AS silver_medal, 2 AS bronze_medal UNION ALL
    SELECT 191, 2, 3, 5 UNION ALL
    SELECT 192, 5, 2, 3 UNION ALL
    SELECT 193, 1, 3, 5 UNION ALL
    SELECT 194, 4, 5, 2 UNION ALL
    SELECT 195, 4, 2, 1 UNION ALL
    SELECT 196, 1, 5, 2
),

-- 2. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, 'sarah@leetcode.com' AS mail, 'Sarah' AS name UNION ALL
    SELECT 2, 'bob@leetcode.com', 'Bob' UNION ALL
    SELECT 3, 'alice@leetcode.com', 'Alice' UNION ALL
    SELECT 4, 'hercy@leetcode.com', 'Hercy' UNION ALL
    SELECT 5, 'quarz@leetcode.com', 'Quarz'
),
-- 获取连续三场及以上比赛获奖的用户，不区分奖牌类型
contious_three_medals_users as (
    select
        user_id
    from (
             select
                 user_id
             from (

                      select contest_id,
                             case idx
                                 when 1 then gold_medal
                                 when 2 then silver_medal
                                 else bronze_medal
                                 end as user_id,
                             -- 构建一个分组标识符，用于区分连续的比赛
                             contest_id - row_number() over (partition by case idx
                                                                              when 1 then gold_medal
                                                                              when 2 then silver_medal
                                                                              else bronze_medal
                                 end
                                 order by contest_id) as contest_group
                      from Contests t1
                           -- 将金银铜牌的用户ID展开
                          lateral view explode(array(1,2,3)) t as idx
                  ) t1
             -- 统计每个用户在连续比赛组中的获奖次数
             group by user_id, contest_group
             -- 筛选出满足连续三场及以上比赛获奖的用户，不区分奖牌类型
             having count(1) >= 3
         ) t2
-- 去重用户
    group by user_id
),
-- 获取三次及以上金牌的用户
gold_three_medals_users as (
    select
        distinct gold_medal as user_id
    from (
             select
                 gold_medal
             from Contests
             group by gold_medal
             having count(*) >= 3
         ) t1
)
select
    name,
    mail
from Users t1
         inner join (
    select user_id from contious_three_medals_users
    union
    select user_id from gold_three_medals_users
) t2
                    on t1.user_id = t2.user_id;
```

### 2025-28 · 指定区间内的订单数（6 分钟分桶）

**源**：`SQLPractise/2025/28 指定区间内的订单数.sql`

**考点**：`ceil(minute / 6)` 或 `(minute-1) div 6 + 1` 分桶，再按桶 `sum(order_count)`。

**输入 → 输出**：Orders(minute, order_count) → (interval_no, total_orders)，按 interval_no 升序

分桶边界极易差 1：1–6 为第 1 桶，不是 0–5。

```sparksql
WITH
-- 1. 模拟 Orders 表
Orders AS (
    SELECT 1 AS minute, 0 AS order_count UNION ALL
    SELECT 2, 2 UNION ALL
    SELECT 3, 4 UNION ALL
    SELECT 4, 6 UNION ALL
    SELECT 5, 1 UNION ALL
    SELECT 6, 4 UNION ALL
    SELECT 7, 1 UNION ALL
    SELECT 8, 2 UNION ALL
    SELECT 9, 4 UNION ALL
    SELECT 10, 1 UNION ALL
    SELECT 11, 4 UNION ALL
    SELECT 12, 6
)
select
    -- 计算区间号
    `floor`((minute - 1) / 6) + 1 as interval_no,
    sum(order_count) total_orders
from Orders t1
group by `floor`((minute - 1) / 6) + 1
```

### 2025-32 · 2024 年订单数（多维汇总）

**源**：`SQLPractise/2025/32 2024年订单数.sql`

**考点**：四表关联 + 2024 年份过滤 + `having count(order_id) > 3`，再取「购买次数最多的品类」（`row_number` 或 `max_by`）。

**输入 → 输出**：customers / orders / orders_items / products → (name, member_level, total_amount, total_quantity, top_purchased_category)，按金额倒序

与 2024-32 同源不同问（已确认不合并）；「确保只有一种品类」说明并列已被题干排除。

```sparksql
WITH

-- 1. 模拟数据表
customers AS (
    SELECT 1 AS id, 'Alice' AS name, 'Gold' AS member_level UNION ALL
    SELECT 2, 'Bob', 'Silver' UNION ALL
    SELECT 3, 'Charlie', 'Gold' UNION ALL
    SELECT 4, 'David', 'Bronze'
),
orders AS (
    -- Alice: 4 orders in 2024
    SELECT 101 AS id, 1 AS customer_id, 150.00 AS amount, CAST('2024-01-15' AS DATE) AS order_date UNION ALL
    SELECT 102, 1, 200.00, CAST('2024-02-20' AS DATE) UNION ALL
    SELECT 103, 1, 50.00,  CAST('2024-03-10' AS DATE) UNION ALL
    SELECT 104, 1, 80.00,  CAST('2024-04-05' AS DATE) UNION ALL
    -- Bob: 2 orders in 2024 (will be filtered out)
    SELECT 201, 2, 90.00,  CAST('2024-01-20' AS DATE) UNION ALL
    SELECT 202, 2, 120.00, CAST('2024-03-15' AS DATE) UNION ALL
    -- Charlie: 5 orders in 2024
    SELECT 301, 3, 30.00,  CAST('2024-01-05' AS DATE) UNION ALL
    SELECT 302, 3, 35.00,  CAST('2024-02-10' AS DATE) UNION ALL
    SELECT 303, 3, 40.00,  CAST('2024-03-18' AS DATE) UNION ALL
    SELECT 304, 3, 25.00,  CAST('2024-04-22' AS DATE) UNION ALL
    SELECT 305, 3, 60.00,  CAST('2024-05-30' AS DATE) UNION ALL
    -- David: 1 order in 2023 (will be filtered out)
    SELECT 401, 4, 100.00, CAST('2023-12-10' AS DATE)
),
products AS (
    SELECT 1 AS id, 'Laptop' AS name, 'Electronics' AS category UNION ALL
    SELECT 2, 'Keyboard', 'Electronics' UNION ALL
    SELECT 3, 'SQL Book', 'Books' UNION ALL
    SELECT 4, 'Desk Chair', 'Home Goods' UNION ALL
    SELECT 5, 'Coffee Mug', 'Home Goods'
),
-- 【修正部分】orders_items 表现在严格遵循5列的定义
orders_items AS (
    -- Alice's items
    SELECT 1 AS id, 101 AS order_id, 1 AS product_id, 1 AS quantity, 150.00 AS price UNION ALL
    SELECT 2, 102, 2, 1, 100.00 UNION ALL
    SELECT 3, 102, 3, 2, 50.00  UNION ALL
    SELECT 4, 103, 4, 1, 50.00  UNION ALL
    SELECT 5, 104, 2, 1, 80.00  UNION ALL
    -- Bob's items
    SELECT 6, 201, 3, 3, 30.00  UNION ALL
    SELECT 7, 202, 4, 1, 120.00 UNION ALL
    -- Charlie's items
    SELECT 8, 301, 3, 1, 30.00  UNION ALL
    SELECT 9, 302, 3, 1, 35.00  UNION ALL
    SELECT 10, 303, 3, 1, 40.00 UNION ALL
    SELECT 11, 304, 4, 1, 25.00 UNION ALL
    SELECT 12, 305, 5, 2, 30.00 UNION ALL
    -- David's items
    SELECT 13, 401, 1, 1, 100.00
),
-- 2024年订单数超过3单的用户购买情况
orders_items_details as (
    select customer_id,
           name,
           member_level,
           order_id,
           order_amount,
           order_date,
           product_id,
           category,
           quantity,
           price
    from (
             select
                 t2.customer_id,
                 t4.name,
                 t4.member_level,
                 t2.id order_id,
                 t2.amount order_amount,
                 t2.order_date,
                 t1.product_id,
                 t3.category,
                 t1.quantity,
                 t1.price,
                 count(distinct t2.id) over(partition by t2.customer_id) 2024_total_orders
             from orders_items t1
                      left join orders t2
                                on t1.order_id = t2.id
                      left join products t3
                                on t1.product_id = t3.id
                      left join customers t4
                                on t2.customer_id = t4.id
             where year(t2.order_date) = 2024
         ) tt
    where 2024_total_orders > 3
),
-- 计算每个用户2024年的总消费和总购买数量
result1 as (
    select
        t1.customer_id,
        t1.name,
        t1.member_level,
        sum(t1.price * t1.quantity) as total_spent,
        sum(t1.quantity) as total_quantity
    from orders_items_details t1
    group by
        t1.customer_id,
        t1.name,
        t1.member_level
),
-- 计算每个用户2024年购买次数最多的商品种类
result2 as (
    select
        customer_id,
        category
    from (
             select
                 t1.customer_id,
                 t1.category,
                 count(distinct t1.order_id) as order_count,
                 row_number() over (partition by t1.customer_id order by count(distinct t1.order_id) desc) rn
             from orders_items_details t1
             group by t1.customer_id, t1.category
         ) t2
    where rn = 1
)
-- 结果拼接
select t1.customer_id,
       t1.name,
       t1.member_level,
       t1.total_spent,
       t1.total_quantity,
       t2.category
from result1 t1
         join result2 t2
              on t1.customer_id = t2.customer_id
order by t1.total_spent desc;
```

### 2025-37 · 奇偶数值之和（条件聚合）

**源**：`SQLPractise/2025/37 奇偶数值之和（带条件的聚合运算）.sql`

**考点**：`sum(if(amount % 2 = 1, amount, 0))` 与 `sum(if(amount % 2 = 0, amount, 0))` 两列同出。

**输入 → 输出**：transactions(transaction_id, amount, transaction_date) → (transaction_date, odd_sum, even_sum)，按日期升序

没有某类交易时要出 0 而不是 NULL，所以必须用 sum(if(...)) 而非 where 过滤。

```sparksql
WITH
-- 1. 模拟 transactions 表
transactions AS (
    SELECT 1 AS transaction_id, 150 AS amount, CAST('2024-07-01' AS DATE) AS transaction_date UNION ALL
    SELECT 2, 200, CAST('2024-07-01' AS DATE) UNION ALL
    SELECT 3, 75,  CAST('2024-07-01' AS DATE) UNION ALL
    SELECT 4, 300, CAST('2024-07-02' AS DATE) UNION ALL
    SELECT 5, 50,  CAST('2024-07-02' AS DATE) UNION ALL
    SELECT 6, 120, CAST('2024-07-03' AS DATE)
)
select
    transaction_date,
    sum(if(amount % 2 = 1, amount, 0)) as odd_sum,
    sum(if(amount % 2 = 0, amount, 0)) as even_sum
from transactions  t1
group by transaction_date
```

### 2025-38 · 带条件的判断（传球网络）

**源**：`SQLPractise/2025/38 带条件的判断.sql`

**考点**：按时间排序判断传球是否「成功」（下一条的 pass_from 是否等于本条的 pass_to），再统计各队成功数。

**输入 → 输出**：Teams(player_id, team_name) + Passes(pass_from, time_stamp, pass_to) → 每队的成功传球次数

最后一传没有后手，需要额外处理边界。

```sparksql
WITH
-- 1. 模拟 Teams 表
Teams AS (
    SELECT 1 AS player_id, 'Arsenal' AS team_name UNION ALL
    SELECT 2, 'Arsenal' UNION ALL
    SELECT 3, 'Arsenal' UNION ALL
    SELECT 4, 'Chelsea' UNION ALL
    SELECT 5, 'Chelsea' UNION ALL
    SELECT 6, 'Chelsea'
),

-- 2. 模拟 Passes 表
Passes AS (
    SELECT 1 AS pass_from, '00:15' AS time_stamp, 2 AS pass_to UNION ALL
    SELECT 2, '00:45', 3 UNION ALL
    SELECT 3, '01:15', 1 UNION ALL
    SELECT 4, '00:30', 1 UNION ALL
    SELECT 2, '46:00', 3 UNION ALL
    SELECT 3, '46:15', 4 UNION ALL
    SELECT 1, '46:45', 2 UNION ALL
    SELECT 5, '46:30', 6
),
/*
    -- 正常的业务场景处理，一次传球只会有一个获胜方
    team_states as (
        select
            t2.team_name as first_team ,
            t1.time_stamp,
            t3.team_name as second_team,
            if(t2.team_name = t3.team_name, t2.team_name, t3.team_name) as winner_team
        from Passes t1
                 left join Teams t2
                           on t1.pass_from  = t2.player_id
                 left join Teams t3
                           on t1.pass_to = t3.player_id

    )
select
    team_name,
    if(time_stamp <= '45:00', 1, 2) half_number,
    sum(score) as dominance
from (
         select
             team_name,
             time_stamp,
             score
         from (
                  select first_team as team_name,time_stamp,if(first_team != winner_team, 0,1) as  score from team_states t1
                  union all
                  select second_team,time_stamp,if(second_team != winner_team, 0,1) from team_states t2
              ) t3
         group by team_name,time_stamp,score
     ) t4
group by team_name,
         if(time_stamp <= '45:00', 1, 2)
order by team_name,half_number;*/

-- 按照 题目需求处理，一次传球可能会有一个获胜方和一个失败方
team_states as (
    select
        t2.team_name as first_team ,
        t1.time_stamp,
        t3.team_name as second_team,
        if(t2.team_name = t3.team_name, t2.team_name, t3.team_name) as winner_team
    from Passes t1
             left join Teams t2
                       on t1.pass_from  = t2.player_id
             left join Teams t3
                       on t1.pass_to = t3.player_id
)
select
    team_name,
    if(time_stamp <= '45:00', 1, 2) half_number,
    sum(score) as dominance
from (
         select
             team_name,
             time_stamp,
             score
         from (
                  select first_team as team_name,time_stamp,if(first_team != winner_team, -1,1) as  score from team_states t1
                  union all
                  select second_team,time_stamp,if(second_team != winner_team, -1,1) from team_states t2
              ) t3
         group by team_name,time_stamp,score
     ) t4
group by team_name,
         if(time_stamp <= '45:00', 1, 2)
order by team_name,half_number;
```

### 2025-44 · 取消率

**源**：`SQLPractise/2025/44 取消率.sql`

**考点**：按日统计 `status like 'cancelled%'` 的占比，且要剔除被 banned 的用户与司机。

**输入 → 输出**：Trips(id, client_id, driver_id, city_id, status, request_at) + Users(users_id, banned, role) → 2013-10-01 至 10-03 每天的非 banned 用户取消率

三个过滤条件缺一不可：日期窗口、client 未 banned、driver 未 banned。

```sparksql
WITH
-- 1. 模拟 Trips 表
Trips AS (
    SELECT 1 AS id, 1 AS client_id, 10 AS driver_id, 1 AS city_id, 'completed' AS status, '2013-10-01' AS request_at UNION ALL
    SELECT 2, 2, 11, 1, 'cancelled_by_driver', '2013-10-01' UNION ALL
    SELECT 3, 3, 12, 6, 'completed', '2013-10-01' UNION ALL
    SELECT 4, 4, 13, 6, 'cancelled_by_client', '2013-10-01' UNION ALL
    SELECT 5, 1, 10, 1, 'completed', '2013-10-02' UNION ALL
    SELECT 6, 2, 11, 6, 'completed', '2013-10-02' UNION ALL
    SELECT 7, 3, 12, 6, 'completed', '2013-10-02' UNION ALL
    SELECT 8, 2, 12, 12, 'completed', '2013-10-03' UNION ALL
    SELECT 9, 3, 10, 12, 'completed', '2013-10-03' UNION ALL
    SELECT 10, 4, 13, 12, 'cancelled_by_driver', '2013-10-03'
),

-- 2. 模拟 Users 表
Users AS (
    SELECT 1 AS users_id, 'No' AS banned, 'client' AS role UNION ALL
    SELECT 2, 'Yes', 'client' UNION ALL
    SELECT 3, 'No', 'client' UNION ALL
    SELECT 4, 'No', 'client' UNION ALL
    SELECT 10, 'No', 'driver' UNION ALL
    SELECT 11, 'No', 'driver' UNION ALL
    SELECT 12, 'No', 'driver' UNION ALL
    SELECT 13, 'No', 'driver'
)
/*
思路：
1. 连接 Trips 和 Users 表，筛选出非禁止用户的行程记录
2. 日期筛选 和 至少一次行程
3. 取消率
*/
select
    t4.request_at,
    round(count(`if`(t4.status = 'cancelled_by_driver' or t4.status = 'cancelled_by_client', 1, null)) / count(1),2) as `Cancellation Rate`
from (
         select
             t1.id,
             t1.client_id,
             t1.driver_id,
             t1.request_at,
             t1.status
         from Trips t1
                  left join Users t2
                            on t1.client_id = t2.users_id
                  left join Users t3
                            on t1.driver_id = t3.users_id
         where t2.banned = 'No' and t3.banned = 'No'
           and t1.request_at between '2013-10-01' and '2013-10-03'
     )t4
group by t4.request_at
```

### 2025-51 · 问题回答率

**源**：`SQLPractise/2025/51 问题回答率.sql`

**考点**：同上 SurveyLog：`count(distinct answer_id) / count(distinct if(action='show', ...))`，但按题输出。

**输入 → 输出**：SurveyLog → (question_id, 回答率)，按回答率降序、question_id 升序

与 2024-30 是变体对。

```sparksql
WITH
-- 1. 模拟 SurveyLog 表数据
SurveyLog AS (
    SELECT 5 AS id, 'show' AS action, 285 AS question_id, CAST(NULL AS INT) AS answer_id, 1 AS q_num, 123 AS timestamp UNION ALL
    SELECT 5, 'answer', 285, 124124,    1, 124 UNION ALL
    SELECT 5, 'show',   369, CAST(NULL AS INT), 2, 125 UNION ALL
    SELECT 5, 'skip',   369, CAST(NULL AS INT), 2, 126
)
select
    question_id,
    nvl(count(if(action = 'answer', 1,null)) / count(if(action = 'show', 1,null)),0) rate
from SurveyLog t1
group by question_id
order by rate desc ,question_id desc
limit 1;
```

### 2025-53 · 符合条件的投保之和

**源**：`SQLPractise/2025/53 符合条件的投保之和.sql`

**考点**：两个条件：`tiv_2015` 出现次数 > 1、且 `(lat, lon)` 只出现一次。用窗口 `count` 判定后求和。

**输入 → 输出**：Insurance(pid, tiv_2015, tiv_2016, lat, lon) → 符合条件者的 tiv_2016 之和（保留 2 位）

「同值出现次数」用 `count(*) over(partition by ...)` 最直观。

```sparksql
WITH
-- 1. 模拟 Insurance 表
Insurance AS (
    SELECT 1 AS pid, 10.0 AS tiv_2015, 5.0 AS tiv_2016, 10.0 AS lat, 10.0 AS lon UNION ALL
    SELECT 2, 20.0, 20.0, 20.0, 20.0 UNION ALL
    SELECT 3, 10.0, 30.0, 20.0, 20.0 UNION ALL
    SELECT 4, 10.0, 40.0, 40.0, 40.0
)
select
    round(sum(tiv_2016),2)  tiv_2016
from (
         select
             t1.pid,
             t1.tiv_2016,
             count(1) over(partition by tiv_2015) group_2015,
             count(1) over(partition by lat,lon) group_city
         from Insurance t1

     ) t2
where t2.group_2015 != 1 and t2.group_city = 1
```

### 2025-59 · 符合条件的业务（活跃业务）

**源**：`SQLPractise/2025/59 符合条件的业务.sql`

**考点**：先求每个 event_type 的全局均值，再找「存在多个 event_type 且各自 occurrences 都严格大于该均值」的业务。

**输入 → 输出**：Events(business_id, event_type, occurrences) → 所有活跃 business_id

「多个都满足」= 过滤后计数 > 1，别写成「任意一个满足」。

```sparksql
WITH
-- 1. 模拟 Events 表
Events AS (
    SELECT 1 AS business_id, 'reviews' AS event_type, 7 AS occurrences UNION ALL
    SELECT 3, 'reviews', 3 UNION ALL
    SELECT 1, 'ads', 11 UNION ALL
    SELECT 2, 'ads', 7 UNION ALL
    SELECT 3, 'ads', 6 UNION ALL
    SELECT 1, 'page views', 3 UNION ALL
    SELECT 2, 'page views', 12
)
select
    business_id
from (
         select
             business_id,
             if(occurrences > avg(occurrences) over(partition by event_type) , 1,0) over_times
         from Events t0
     ) t1
where over_times = 1
group by business_id;
```

### 2025-61 · 条件帖子每日占比

**源**：`SQLPractise/2025/61 条件帖子每日占比.sql`

**考点**：先剔除 Removals 中的帖子，再 `sum(if(action='report',1,0)) / count(*)` 按日算占比并 `round 2`。

**输入 → 输出**：Actions(user_id, post_id, action_date, action, extra) + Removals(post_id) → 2019-07-01 至 07-31 每天的垃圾帖（report）占比

日期窗口 + 剔除删除帖 + 占比保留 2 位，三个条件都要。

```sparksql
WITH
-- 1. 模拟 Actions 表
Actions AS (
    SELECT 1 AS user_id, 1 AS post_id, CAST('2019-07-01' AS DATE) AS action_date, 'view' AS action, CAST(NULL AS STRING) AS extra UNION ALL
    SELECT 1, 1, CAST('2019-07-01' AS DATE), 'like', NULL UNION ALL
    SELECT 1, 1, CAST('2019-07-01' AS DATE), 'share', NULL UNION ALL
    SELECT 2, 2, CAST('2019-07-04' AS DATE), 'view', NULL UNION ALL
    SELECT 2, 2, CAST('2019-07-04' AS DATE), 'report', 'spam' UNION ALL
    SELECT 3, 4, CAST('2019-07-04' AS DATE), 'view', NULL UNION ALL
    SELECT 3, 4, CAST('2019-07-04' AS DATE), 'report', 'spam' UNION ALL
    SELECT 4, 3, CAST('2019-07-02' AS DATE), 'view', NULL UNION ALL
    SELECT 4, 3, CAST('2019-07-02' AS DATE), 'report', 'spam' UNION ALL
    SELECT 5, 2, CAST('2019-07-03' AS DATE), 'view', NULL UNION ALL
    SELECT 5, 2, CAST('2019-07-03' AS DATE), 'report', 'racism' UNION ALL
    SELECT 5, 5, CAST('2019-07-03' AS DATE), 'view', NULL UNION ALL
    SELECT 5, 5, CAST('2019-07-03' AS DATE), 'report', 'racism'
),

-- 2. 模拟 Removals 表
Removals AS (
    SELECT 2 AS post_id, CAST('2019-07-20' AS DATE) AS remove_date UNION ALL
    SELECT 3, CAST('2019-07-18' AS DATE)
)

select
    round(avg(date_rate),2) * 100 as average_daily_percent
from (
         select
             t1.action_date,
             count(distinct t2.post_id) / count(distinct t1.post_id) date_rate
         from Actions t1
                  left join Removals t2
                            on t1.post_id = t2.post_id
         where t1.action = 'report' and t1.extra = 'spam'
         group by t1.action_date

     ) t3
```

### 2025-66 · 每月每国家/地区的信息

**源**：`SQLPractise/2025/66 每个月每个国家地区的信息.sql`

**考点**：`date_format(trans_date, '%Y-%m')` 分组，`count(*)` 与 `sum(state='approved')` 同出，金额同样两列。

**输入 → 输出**：Transactions(id, country, state, amount, trans_date) → (month, country, trans_count, approved_count, trans_total_amount, approved_total_amount)

四个指标两两对应：笔数与金额都要出「全部 / 已批准」两份。

```sparksql
WITH
-- 1. 模拟 Transactions 表
Transactions AS (
    SELECT 121 AS id, 'US' AS country, 'approved' AS state, 1000 AS amount, CAST('2018-12-18' AS DATE) AS trans_date UNION ALL
    SELECT 122, 'US', 'declined', 2000, CAST('2018-12-19' AS DATE) UNION ALL
    SELECT 123, 'US', 'approved', 2000, CAST('2019-01-01' AS DATE) UNION ALL
    SELECT 124, 'DE', 'approved', 2000, CAST('2019-01-07' AS DATE)
)
select
    substr(t0.trans_date,1,7),country,
    count(id) trans_count,
    count(if(state = 'approved',id,null)) approved_count,
    sum(amount) trans_total_amount,
    sum(if(state = 'approved',amount,0)) approved_total_amount


from Transactions t0
group by substr(t0.trans_date,1,7),country
```

### 2026-03 · 标签准确率

**源**：`SQLPractise/2026/3. 标签准确率.sql`

**考点**：推荐表与用户评分表按 (rec_user, rec_info_l) ⋈ (user_id, hobby_l) 关联，对命中的 score 取 `avg` 并转 `decimal(10,3)`。

**输入 → 输出**：recommend_tb + user_action_tb → 单一数值 avg_score（推荐标签与用户偏好一致的评分均值）

> ⚠️ 静态观察：活代码写的是 `rec_info_l标签准确率`，缺逗号且混入了题名，是**语法错误**；正确写法（`SELECT DISTINCT` + `AVG`）被注释在文件末尾。

```sparksql
WITH recommend_tb AS (
    SELECT 1 AS rec_id, '健身' AS rec_info_l, 101 AS rec_user, '2022-02-08 07:23:15' AS rec_time UNION ALL
    SELECT 2 AS rec_id, '美妆' AS rec_info_l, 102 AS rec_user, '2022-02-08 07:24:15' AS rec_time UNION ALL
    SELECT 3 AS rec_id, '体育' AS rec_info_l, 103 AS rec_user, '2022-02-08 07:25:15' AS rec_time UNION ALL
    SELECT 4 AS rec_id, '美妆' AS rec_info_l, 103 AS rec_user, '2022-02-08 07:26:15' AS rec_time UNION ALL
    SELECT 5 AS rec_id, '搞笑' AS rec_info_l, 104 AS rec_user, '2022-02-08 07:27:15' AS rec_time UNION ALL
    SELECT 6 AS rec_id, '体育' AS rec_info_l, 104 AS rec_user, '2022-02-08 07:28:15' AS rec_time UNION ALL
    SELECT 7 AS rec_id, '体育' AS rec_info_l, 105 AS rec_user, '2022-02-08 07:29:15' AS rec_time UNION ALL
    SELECT 8 AS rec_id, '影视' AS rec_info_l, 106 AS rec_user, '2022-02-08 07:30:15' AS rec_time
),
     user_action_tb AS (
         SELECT 101 AS user_id, '健身' AS hobby_l, 88 AS score UNION ALL
         SELECT 102 AS user_id, '影视' AS hobby_l, 81 AS score UNION ALL
         SELECT 103 AS user_id, '美妆' AS hobby_l, 78 AS score UNION ALL
         SELECT 104 AS user_id, '健身' AS hobby_l, 68 AS score UNION ALL
         SELECT 105 AS user_id, '体育' AS hobby_l, 90 AS score UNION ALL
         SELECT 106 AS user_id, '影视' AS hobby_l, 82 AS score
     )
-- ==========================================
-- 请在此处往下编写你的解答SQL
-- 下方为参考答案，为防止剧透你可以先遮挡下方代码
-- ==========================================

select
    cast(avg(t3.score) as decimal(10,3)) as avg_score
from (
         select
             rec_user,
             rec_info_l标签准确率
         from recommend_tb t1
         group by rec_user,rec_info_l
     ) t2
         inner join user_action_tb t3
                    on t2.rec_user = t3.user_id and t2.rec_info_l = t3.hobby_l

/*
SELECT
    -- 使用 CAST AS DECIMAL(10,3) 可以严格保证输出带有3位小数(如 84.500)
    CAST(AVG(score) AS DECIMAL(10,3)) AS avg_score
FROM (
         -- 核心逻辑：找到被准确推荐的用户（利用 distinct 去重，满足“同一用户算一次”的要求）
         SELECT DISTINCT
             u.user_id,
             u.score
         FROM recommend_tb r
                  JOIN user_action_tb u
                       ON r.rec_user = u.user_id
                           AND r.rec_info_l = u.hobby_l
     ) t;*/
```

### 2026-04 · 参加培训的人员

**源**：`SQLPractise/2026/4.参加培训的人员.sql`

**考点**：员工表左连培训表，按部门 / 岗位筛选「参加过某课程」的人，注意未参加（NULL）的处理。

**输入 → 输出**：staff_tb + cultivate_tb → 符合条件的员工清单及明细

与 2026-05 是变体对：04 数「人」（去重），05 数「人次」（炸开）。

```sparksql
use base_ex;
/*
某公司员工信息表及员工培训信息表如下：

【表1：员工信息表 staff_tb】
字段：staff_id-员工id，staff_name-员工姓名，staff_gender-员工性别，post-员工岗位职务，department-员工所在部门
数据如下：
1 Angus male Financial dep1
2 Cathy female Director dep1
3 Miki female Director dep2
4 Lawson male Engineer dep1
5 Earl male Engineer dep2
6 Ben male Engineer dep1
7 Nura female Director dep2

【表2：员工培训信息表 cultivate_tb】
字段：info_id-培训信息id，staff_id-员工id，course-培训课程
注：该员工只培训了一门课程，该列只写课程名称；多门培训的话，互相用逗号分隔（含有空格）。
数据如下：
101 1 course1, course2
102 2 course2
103 3 course1, course3
104 4 course1, course2, course3
105 5 course3
106 6 NULL
107 7 course1, course2

【问题】
请查询培训课程带 course3 的员工信息？
输出列：staff_id，staff_name
排序要求：按 staff_id 升序排列

【示例数据结果如下】
staff_id  staff_name
3         Miki
4         Lawson
5         Earl

解释：有员工3、4、5培训了course3课程，故结果如上。
*/

WITH staff_tb AS (
    SELECT 1 AS staff_id, 'Angus' AS staff_name, 'male' AS staff_gender, 'Financial' AS post, 'dep1' AS department UNION ALL
    SELECT 2 AS staff_id, 'Cathy' AS staff_name, 'female' AS staff_gender, 'Director' AS post, 'dep1' AS department UNION ALL
    SELECT 3 AS staff_id, 'Miki' AS staff_name, 'female' AS staff_gender, 'Director' AS post, 'dep2' AS department UNION ALL
    SELECT 4 AS staff_id, 'Lawson' AS staff_name, 'male' AS staff_gender, 'Engineer' AS post, 'dep1' AS department UNION ALL
    SELECT 5 AS staff_id, 'Earl' AS staff_name, 'male' AS staff_gender, 'Engineer' AS post, 'dep2' AS department UNION ALL
    SELECT 6 AS staff_id, 'Ben' AS staff_name, 'male' AS staff_gender, 'Engineer' AS post, 'dep1' AS department UNION ALL
    SELECT 7 AS staff_id, 'Nura' AS staff_name, 'female' AS staff_gender, 'Director' AS post, 'dep2' AS department
),
     cultivate_tb AS (
         SELECT 101 AS info_id, 1 AS staff_id, 'course1, course2' AS course UNION ALL
         SELECT 102 AS info_id, 2 AS staff_id, 'course2' AS course UNION ALL
         SELECT 103 AS info_id, 3 AS staff_id, 'course1, course3' AS course UNION ALL
         SELECT 104 AS info_id, 4 AS staff_id, 'course1, course2, course3' AS course UNION ALL
         SELECT 105 AS info_id, 5 AS staff_id, 'course3' AS course UNION ALL
         SELECT 106 AS info_id, 6 AS staff_id, NULL AS course UNION ALL
         SELECT 107 AS info_id, 7 AS staff_id, 'course1, course2' AS course
     )
-- ==========================================
-- 请在此处往下编写你的解答SQL
-- 下方为参考答案，为防止剧透你可以先遮挡下方代码
-- ==========================================
-- 培训表中转化为数组；inner join；去重
select
    distinct
    t2.staff_id,
    t2.staff_name
from cultivate_tb t1
         inner join staff_tb t2
                    on array_contains(split(t1.course,',\\s+'),'course3') and t1.staff_id = t2.staff_id
order by t2.staff_id;
```

---

## G · JSON、字符串与正则解析（10 题）

`get_json_object / from_json + schema`、`lateral view explode` 处理数组、`regexp_extract / regexp_replace`、`RLIKE` 单词边界 `\b`。坑在转义层级、数组下标从 0 开始、以及「独立词」与「子串」的区别。

### 2024-19 · 字符串展开（1-5,16,11-13,9）

**源**：`SQLPractise/2024/19字符串的展开.sql`

**考点**：`posexplode(split(str, ','))` 定位每段，`split(段, '-')` 判区间，`explode(sequence(起, 止))` 展开后 `concat_ws` 回拼。

**输入 → 输出**：str = '1-5,16,11-13,9' → '1,2,3,4,5,16,11,12,13,9'

要保留原段顺序，所以 posexplode 的下标不能丢。

```sparksql
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

### 2024-26 · json 解析获取服装标准（Hive json 函数族）

**源**：`SQLPractise/2024/26json解析获取服装标准.sql`

**考点**：`get_json_object` 取单值、`json_tuple` 取多值，对比两种写法的差异。

**输入 → 输出**：一段嵌套 JSON 字符串（store.fruit[] / bicycle / email / owner） → 各字段的值

这是「函数族速查」型练习，文件里逐个小节演示，与 2025-33 是变体对。

```sparksql
# ---------------------hive中常见的json解析函数 ----------------------

-- get_json_object
with t1 as (

    select
    '{"store":
      {"fruit":\[{"weight":8,"type":"apple"},{"weight":9,"type":"pear"}],
       "bicycle":{"price":19.95,"color":"red"}
      },
     "email":"amy@only_for_json_udf_test.net",
     "owner":"amy"
    }'
    as        str
)
select
    get_json_object(str, '$.store.bicycle.color') color,
    get_json_object(str, '$.store.bicycle.price') price,
    get_json_object(str, '$.store.fruit[0]'),
    get_json_object(str, '$.store.fruit[1]')
from t1;

-- json_tuple
with t1 as (

    select
    '{"store":
      {"fruit":\[{"weight":8,"type":"apple"},{"weight":9,"type":"pear"}],
       "bicycle":{"price":19.95,"color":"red"}
      },
     "email":"amy@only_for_json_udf_test.net",
     "owner":"amy"
    }'
    as        str
)

select
    json_tuple(fruit, 'color', 'price') as (color, price)
from (
    select get_json_object(str, '$.store.bicycle') fruit from t1
) t2;

-- 炸裂json中的数组
with t1 as (

    select
    '{"store":
      {"fruit":\[{"weight":8,"type":"apple"},{"weight":9,"type":"pear"}],
       "bicycle":{"price":19.95,"color":"red"}
      },
     "email":"amy@only_for_json_udf_test.net",
     "owner":"amy"
    }'
    as        str
)
select
    *
from (
    select
    get_json_object(str, '$.store.fruit') fruits
    from t1
     ) t2
lateral view explode(split(replace(replace(t2.fruits,'[',''),']',''), '\\},\\{')) tmp as fruit;

# ---------------------hive中常见的json解析函数 ----------------------



-- hive 3.1.3版本
-- json解析获取 ‘服装标准尺寸’的 sizelist
-- ["XXXS","XXS","XS","S","M","L","XL","XXL","XXXL","4XL","5XL","6XL","7XL"]
with collect as (
    select
        '{"collectId":"farfetchcn_4bc68f664f1a03d79366a7c667993627_20240305191718","collectTime":"20240305191718","data":{"attributes":"","brandName":"WARDROBE.NYC","category":"女士西装/WARDROBE.NYC/女装/西装夹克","color":"中性色","country":"","currency":"CNY","dataSource":"farfetch-cn","discountedPrice":"16447.0","itemNumber":"W4043R12","material":"表面：羊毛, 衬里：粘胶纤维","newProductImgLinks":["https://yuxingShoping517d4465ee74b5ca8d3805592b1c71fd/","https://yuxingShoping1f8c975d69dfc3066770002f478c3bfb/","https://yuxingShopingad3be1e6ec6a2edc3d922951c522eb/","https://yuxingShoping5bef91b8aa001506eb3400646db51e8f/","https://yuxingShoping99c7f8fc6b051ec0afdb723613465051/","https://yuxingShoping72bf871ae95662e58f8d73b8cf06b76e/"],"productImgLinks":["https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287188_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287186_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287189_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287187_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287192_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287200_1000.jpg"],"productMainUrl":"https://yuxingShoping517d4465ee74b5ca8d3805592b1c71fd/","productName":"WARDROBE.NYC Contour 双排扣西装夹克","productRetailPrice":"16447.0","productUrl":"https://www.farfetch.cn/cn/shopping/women/wardrobenyc-contour-item-19404158.aspx","region":"美国","releaseDate":"","size":[{"sizeList":["XXXS","XXS","XS","S","M","L","XL","XXL","XXXL","4XL","5XL","6XL","7XL"],"sizeStandardName":"服装标准尺寸"},{"sizeList":["36","38","40","42","44","46","48","50","52","54","56","58","60"],"sizeStandardName":"意大利码"},{"sizeList":["32","34","36","38","40","42","44","46","48","50","52","54","56"],"sizeStandardName":"法国码"},{"sizeList":["4","6","8","10","12","14","16","18","20","22","24","26","28"],"sizeStandardName":"英国码"},{"sizeList":["0","2","4","6","8","10","12","14","16","18","20","22"],"sizeStandardName":"美国码"},{"sizeList":["30","32","34","36","38","40","42","44","46","48","50","52","54"],"sizeStandardName":"德国码"},{"sizeList":["PP","PP","P","M","M","G","GG","GG","XGG","XGG","XGG","XGG"],"sizeStandardName":"巴西码"},{"sizeList":["34","36","38","40","42","44","46","48","50","52","54","56","58"],"sizeStandardName":"巴西"},{"sizeList":["3","5","7","9","11","13","15","17","19","21","23","25","27"],"sizeStandardName":"日本码"},{"sizeList":["000","00","0","1","2","3","4","5","6","7","8","9","10"],"sizeStandardName":"标准尺寸"},{"sizeList":["000","00","0","I","II","III","IV","V","VI","VII","VIII","IX","X"],"sizeStandardName":"罗马数字"},{"sizeList":["38","40","42","44","46","48","50","52","54","56","58","60","62"],"sizeStandardName":"俄罗斯码"},{"sizeList":[null,"33","44","55","66","77","88","99",null,null,null,null,null],"sizeStandardName":"韩国码"},{"sizeList":["145/73A","150/76A","155/80A","160/84A","165/88A","170/92A","175/96A","180/100A","185/104A",null,null,null,null],"sizeStandardName":"中国码"},{"sizeList":["4","6","8","10","12","14","16","18","20","22","24","26","28"],"sizeStandardName":"澳大利亚码"}]},"skuId":"","spuId":"19404158","style":"","targetPopulation":""}'
    as json_str
),
    size_elements as (
        select
            get_json_object(json_str,'$.data.size[0]') size_element
        from collect
    )
select
    get_json_object(size_element,'$.sizeList') size_list
from size_elements;

-- 获取有多少中服装标准
-- +--------------+---------------------------------------------------------------------------------------------------+
-- |standard_count|standard_names                                                                                     |
-- +--------------+---------------------------------------------------------------------------------------------------+
-- |15            |["中国码","俄罗斯码","巴西","巴西码","德国码","意大利码","日本码","服装标准尺寸","标准尺寸","法国码","澳大利亚码","罗马数字","美国码","英国码","韩国码"]|
-- +--------------+---------------------------------------------------------------------------------------------------+
with collect as (
    select
        '{"collectId":"farfetchcn_4bc68f664f1a03d79366a7c667993627_20240305191718","collectTime":"20240305191718","data":{"attributes":"","brandName":"WARDROBE.NYC","category":"女士西装/WARDROBE.NYC/女装/西装夹克","color":"中性色","country":"","currency":"CNY","dataSource":"farfetch-cn","discountedPrice":"16447.0","itemNumber":"W4043R12","material":"表面：羊毛, 衬里：粘胶纤维","newProductImgLinks":["https://yuxingShoping517d4465ee74b5ca8d3805592b1c71fd/","https://yuxingShoping1f8c975d69dfc3066770002f478c3bfb/","https://yuxingShopingad3be1e6ec6a2edc3d922951c522eb/","https://yuxingShoping5bef91b8aa001506eb3400646db51e8f/","https://yuxingShoping99c7f8fc6b051ec0afdb723613465051/","https://yuxingShoping72bf871ae95662e58f8d73b8cf06b76e/"],"productImgLinks":["https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287188_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287186_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287189_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287187_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287192_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287200_1000.jpg"],"productMainUrl":"https://yuxingShoping517d4465ee74b5ca8d3805592b1c71fd/","productName":"WARDROBE.NYC Contour 双排扣西装夹克","productRetailPrice":"16447.0","productUrl":"https://www.farfetch.cn/cn/shopping/women/wardrobenyc-contour-item-19404158.aspx","region":"美国","releaseDate":"","size":[{"sizeList":["XXXS","XXS","XS","S","M","L","XL","XXL","XXXL","4XL","5XL","6XL","7XL"],"sizeStandardName":"服装标准尺寸"},{"sizeList":["36","38","40","42","44","46","48","50","52","54","56","58","60"],"sizeStandardName":"意大利码"},{"sizeList":["32","34","36","38","40","42","44","46","48","50","52","54","56"],"sizeStandardName":"法国码"},{"sizeList":["4","6","8","10","12","14","16","18","20","22","24","26","28"],"sizeStandardName":"英国码"},{"sizeList":["0","2","4","6","8","10","12","14","16","18","20","22"],"sizeStandardName":"美国码"},{"sizeList":["30","32","34","36","38","40","42","44","46","48","50","52","54"],"sizeStandardName":"德国码"},{"sizeList":["PP","PP","P","M","M","G","GG","GG","XGG","XGG","XGG","XGG"],"sizeStandardName":"巴西码"},{"sizeList":["34","36","38","40","42","44","46","48","50","52","54","56","58"],"sizeStandardName":"巴西"},{"sizeList":["3","5","7","9","11","13","15","17","19","21","23","25","27"],"sizeStandardName":"日本码"},{"sizeList":["000","00","0","1","2","3","4","5","6","7","8","9","10"],"sizeStandardName":"标准尺寸"},{"sizeList":["000","00","0","I","II","III","IV","V","VI","VII","VIII","IX","X"],"sizeStandardName":"罗马数字"},{"sizeList":["38","40","42","44","46","48","50","52","54","56","58","60","62"],"sizeStandardName":"俄罗斯码"},{"sizeList":[null,"33","44","55","66","77","88","99",null,null,null,null,null],"sizeStandardName":"韩国码"},{"sizeList":["145/73A","150/76A","155/80A","160/84A","165/88A","170/92A","175/96A","180/100A","185/104A",null,null,null,null],"sizeStandardName":"中国码"},{"sizeList":["4","6","8","10","12","14","16","18","20","22","24","26","28"],"sizeStandardName":"澳大利亚码"}]},"skuId":"","spuId":"19404158","style":"","targetPopulation":""}'
    as json_str
),
-- 提取size数组并统计服装标准种类
 size_data AS (
  SELECT get_json_object(json_str, '$.data.size') as size_array
  FROM collect
),
size_items AS (
  SELECT
    get_json_object( '{' || size_item || '}', '$.sizeStandardName') as standard_name
  FROM size_data
  LATERAL VIEW explode(split(regexp_replace(regexp_replace(size_array, '\\[\\{', ''), '\\}\\]', ''), '\\},\\{')) items AS size_item
)
SELECT
  COUNT(DISTINCT standard_name) as standard_count,
  collect_set(standard_name) as standard_names
FROM size_items
WHERE standard_name IS NOT NULL;
```

### 2024-48 · 文章主题（RLIKE 单词边界匹配）

**源**：`SQLPractise/2024/48 文章主题.sql`

**考点**：`ON content RLIKE CONCAT('\\b', word, '\\b')`，靠单词边界避免 'bull' 命中 'bullet'。

**输入 → 输出**：Keywords(topic_id, word) + Posts(post_id, content) → 每个帖子命中的 topic_id

文件里附带一大段 RLIKE 边界与转义的说明，是全库最有价值的正则笔记。

```sparksql
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
```

### 2025-10 · 可以投资的国家（电话国家码匹配）

**源**：`SQLPractise/2025/10 可以投资的国家(部门有效工时大于公司有效工时).sql`

**考点**：`left(phone_number, 3)` 取国家码去匹配 Country 表，再按国家分组出平均余额与人数。

**输入 → 输出**：Person(id, name, phone_number='xxx-yyyyyyy') + Country(name, country_code) → (country.name, 有效电话人数, 平均余额)

注意「有效电话」的判定：号码格式不对的不能计入分母。

```sparksql
WITH
-- 1. 模拟 Person 表
Person AS (
    SELECT 3 AS id, 'Jonathan' AS name, '051-1234567' AS phone_number UNION ALL
    SELECT 12, 'Elvis', '051-7654321' UNION ALL
    SELECT 1, 'Moncef', '212-1234567' UNION ALL
    SELECT 2, 'Maroua', '212-6523651' UNION ALL
    SELECT 7, 'Meir', '972-1234567' UNION ALL
    SELECT 9, 'Rachel', '972-0011100'
),

-- 2. 模拟 Country 表
Country AS (
    SELECT 'Peru' AS name, '051' AS country_code UNION ALL
    SELECT 'Israel', '972' UNION ALL
    SELECT 'Morocco', '212' UNION ALL
    SELECT 'Germany', '049' UNION ALL
    SELECT 'Ethiopia', '251'
),

-- 3. 模拟 Calls 表
Calls AS (
    SELECT 1 AS caller_id, 9 AS callee_id, 33 AS duration UNION ALL
    SELECT 2, 9, 4 UNION ALL
    SELECT 1, 2, 59 UNION ALL
    SELECT 3, 12, 102 UNION ALL
    SELECT 3, 12, 330 UNION ALL
    SELECT 12, 3, 5 UNION ALL
    SELECT 7, 9, 13 UNION ALL
    SELECT 7, 1, 3 UNION ALL
    SELECT 9, 7, 1 UNION ALL
    SELECT 1, 7, 7
)
/*

-- 方式1
select name,
       average_country_duration,
       avg(average_country_duration) over () as average_global_duration
from (
         select
             '0' as gloabal_flag,
             t3.name,
             avg(t1.duration) as average_country_duration
         from Calls t1
                  left join Person t2
                            on t1.caller_id = t2.id
                  left join Country t3
                            on substr(t2.phone_number,0,3) = t3.country_code
         group by t3.name
     ) t4
*/


-- 方式2
select
    name
from (
         -- 每个国家的平均通话时长 和 全局的平均通话时长
         select name,
                average_country_duration,
                avg(average_country_duration) over () as average_global_duration
         from (
                  -- 计算每个国家的平均通话时长
                  select
                      t3.name,
                      avg(t1.duration) as average_country_duration
                  from Calls t1
                           left join Person t2
                                     on t1.caller_id = t2.id
                           left join Country t3
                                     on substr(t2.phone_number,0,3) = t3.country_code
                  group by t3.name
              ) t4

     ) t5
where average_country_duration > average_global_duration;
```

### 2025-23 · 函数处理（把方程格式化成字符串）

**源**：`SQLPractise/2025/23 函数处理.sql`

**考点**：按 power 降序拼接：`power=0` 不出 X、`power=1` 不出指数、`factor=1` 不出系数、首项不带 `+`。

**输入 → 输出**：Terms(power, factor) → 形如 "-4X^3+5X^2-3X+1=0" 的单个字符串

这是一道纯字符串拼接题，边界条件（±1、指数 0/1、首项符号）最多。

```sparksql
-- 方式1 使用 CONCAT_WS() 和 COLLECT_LIST()
WITH
-- 1. 模拟 Terms 表 (使用示例1的数据)
Terms AS (
    SELECT 2 AS power, 1 AS factor UNION ALL
    SELECT 1, -4 UNION ALL
    SELECT 0, 2
)
select
    concat(concat_ws('',collect_list(term)), '=0') as equation
from (
         select power,
                factor,
                concat(
                        if(factor > 0, '+', '-'),
                        case when power = 0 then abs(factor)
                             when power = 1 then concat(abs(factor),'X')
                             else concat(abs(factor),'X^',power) end
                ) as term

         from Terms t1
         -- 全局排序
         order by power desc
     ) t2;


-- 方式2 使用窗口函数 COLLECT_LIST() OVER()
WITH
-- 1. 模拟 Terms 表
Terms AS (
    SELECT 2 AS power, 1 AS factor UNION ALL
    SELECT 1, -4 UNION ALL
    SELECT 0, 2
),

-- 2. 格式化每一项并使用窗口函数
CumulativeList AS (
    SELECT
        -- 使用窗口函数生成一个累积的、有序的列表
        collect_list(
                CONCAT(
                        CASE WHEN factor > 0 THEN '+' ELSE '-' END,
                        ABS(factor),
                        CASE
                            WHEN power = 0 THEN ''
                            WHEN power = 1 THEN 'X'
                            ELSE CONCAT('X^', power)
                            END
                )
        ) OVER (ORDER BY power DESC) AS term_list,
        -- 使用 row_number 标记最后一行
        row_number() OVER (ORDER BY power ASC) as rn_asc
    FROM
        Terms
)

-- 3. 筛选出最后一行并拼接
SELECT
    CONCAT(concat_ws('', term_list), '=0') AS equation
FROM
    CumulativeList
WHERE
    -- 最后一行 (按 power 升序的第一行) 包含了完整的列表
    rn_asc = 1;
```

### 2025-29 · 单词出现频次（非 wordcount）

**源**：`SQLPractise/2025/29 单词出现频次（非wordcount).sql`

**考点**：`content RLIKE '\\bbull\\b'` 判「独立词」，按文件计数而不是按出现次数。

**输入 → 输出**：Files(file_name, content) → ('bull'/'bear', 包含该独立词的文件数)

「文件数」不是「出现次数」，一个文件里出现多次也只算 1。

```sparksql
WITH
-- 1. 模拟 Files 表
    Files AS (
        SELECT 'draft1.txt' AS file_name, 'The stock exchange predicts a bull market which would make many investors happy.' AS content UNION ALL
        SELECT 'draft2.txt', 'The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market.' UNION ALL
        SELECT 'draft3.txt', 'The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market. As always predicting the future market is an uncertain game and all investors should follow their instincts and best practices.'
    ),words as (
    select file_name,
           content,
--                 content regexp ' bull| bull |bull ' exists_flag1,
--                 content regexp ' bear| bear |bear ' exists_flag2
           content like '% bull %' as exists_flag1,
           content like '% bear %' as exists_flag2

    from Files t1
)
select
    'bull' as word,
    count(distinct if(exists_flag1 = 1, file_name, null)) as count
from words

union all

select
    'bear' as word,
    count(distinct if(exists_flag2 = 1, file_name, null)) as count
from words
```

### 2025-33 · json 解析（多层炸裂取四字段）

**源**：`SQLPractise/2025/33 json解析.sql`

**考点**：`from_json` 定 schema（array<struct<...>>）后 `lateral view explode` 逐层展开，再从各层取 upc / poiCoverIds / activityStatus / childActivityId。

**输入 → 输出**：一段三层嵌套的 JSON 数组字符串 → 每个 (upc, poiCoverIds, activityStatus, childActivityId) 组合

文件给了两种方式：方式 1 是 `from_json` + 显式 schema（推荐），另有 get_json_object 的写法。

```sparksql
-- 方式1 ，如果json结构固定，使用from_json函数
WITH raw_data AS (
    SELECT '[{"upc":"4891214699106","groupNumber":2,"poiCoverIds":[27328289,27177717,27641161,27273825,27397427,27143163,27286728,27202288,27380897,27270871,27410428,27531096,27181919,27622791,27473153,27364924,27665032,27428734,27661498,27250113],"productName":"自然派 蜜汁猪肉条 65克/袋","subsidyType":"GOODS_RETURN","activityInfo":[{"activityStatus":"CREATE_DRAFT","childActivityId":63623316},{"activityStatus":"CREATE_DRAFT","childActivityId":63220296}],"subsidyDetail":"单品补贴额每单件1.2元"},{"upc":"6924509900767","groupNumber":3,"poiCoverIds":[27328289,27177717,27641161,27273825,27397427,27143163,27286728,27202288,27380897,27270871,27410428,27531096,27181919,27622791,27473153,27364924,27665032,27428734,27661498,27250113],"productName":"准盐 海藻碘食用盐 400g/袋","subsidyType":"GOODS_RETURN","activityInfo":[{"activityStatus":"CREATE_DRAFT","childActivityId":63625381},{"activityStatus":"CREATE_DRAFT","childActivityId":63220296}],"subsidyDetail":"单品补贴额每单件3元"}]'
               AS json_string
)
SELECT
    -- 从第一层展开的结构体中直接获取 upc
    t1_product.upc,
    -- 从第二层展开中获取 poiCoverIds (这是一个基本类型，不是结构体)
    t2_poi AS poiCoverIds,
    -- 从第三层展开的结构体中获取 activityStatus 和 childActivityId
    t3_activity.activityStatus,
    t3_activity.childActivityId
FROM
    raw_data

    -- 步骤1: 使用 from_json 和 schema 将整个字符串解析成一个 Hive 数组结构，并展开
    LATERAL VIEW explode(
            from_json(
                    json_string,
                    'ARRAY<STRUCT<upc:STRING, groupNumber:INT, poiCoverIds:ARRAY<BIGINT>, productName:STRING, subsidyType:STRING, activityInfo:ARRAY<STRUCT<activityStatus:STRING, childActivityId:BIGINT>>, subsidyDetail:STRING>>'
            )
                     ) t1 AS t1_product

        -- 步骤2: 展开每个产品结构体中的 poiCoverIds 数组
        LATERAL VIEW explode(t1_product.poiCoverIds) t2 AS t2_poi

        -- 步骤3: 展开每个产品结构体中的 activityInfo 数组
        LATERAL VIEW explode(t1_product.activityInfo) t3 AS t3_activity
;

-- 方式2，直接解析

select
    GET_JSON_OBJECT(a3,'$.upc') as upc,
    GET_JSON_OBJECT(a3,'$.poiCoverIds') as poiCoverIds,
    GET_JSON_OBJECT(a4,'$.activityStatus') as activityStatus,
    GET_JSON_OBJECT(a4,'$.childActivityId') as childActivityId
from (
         select
             a3,
             if(a4 is null, lead(a4,1) over(ORDER BY 1) ,a4) as a4
         from (
                  select
                      -- If the chunk contains "upc", it's the main object.
                      -- The split mangles the start/end brackets, so we replace '[{' with '{' and '}]' with '}' to make it a valid JSON object again.
                      if(a2 like '%upc%', replace(replace(a2, '[{', '{'), '}]', '}'), null) as a3,

                      -- If the chunk does NOT contain "upc", it's an activity object.
                      -- These chunks are missing the surrounding braces after the split, so we add them back with concat.
                      if(a2 not like '%upc%', concat('{', a2, '}'), null) as a4
                  from
                      (
                          select '[{"upc": "4891214699106", "groupNumber": 2, "poiCoverIds": [27328289, 27177717, 27641161, 27273825, 27397427, 27143163, 27286728, 27202288, 27380897, 27270871, 27410428, 27531096, 27181919, 27622791, 27473153, 27364924, 27665032, 27428734, 27661498, 27250113], "productName": "自然派 蜜汁猪肉条 65克/袋", "subsidyType": "GOODS_RETURN", "activityInfo": [{"activityStatus": "CREATE_DRAFT", "childActivityId": 63623316}, {"activityStatus": "CREATE_DRAFT", "childActivityId": 63220296}], "subsidyDetail": "单品补贴额每单件1.2元"}, {"upc": "6924509900767", "groupNumber": 3, "poiCoverIds": [27328289, 27177717, 27641161, 27273825, 27397427, 27143163, 27286728, 27202288, 27380897, 27270871, 27410428, 27531096, 27181919, 27622791, 27473153, 27364924, 27665032, 27428734, 27661498, 27250113], "productName": "淮盐 海藻碘食用盐 400g/袋", "subsidyType": "GOODS_RETURN", "activityInfo": [{"activityStatus": "CREATE_DRAFT", "childActivityId": 63625381}, {"activityStatus": "CREATE_DRAFT", "childActivityId": 63220296}], "subsidyDetail": "单品补贴额每单件3元"}]' as a
                      ) t1
                      lateral view explode(split(a,'},')) t2 as a2
              ) t3
     ) t4
where t4.a3 is not null;
```

### 2025-40 · ip 校验（IPv4 合法性）

**源**：`SQLPractise/2025/40 ip校验.sql`

**考点**：`split(ip, '\\.')` 后校验三件事：段数必须为 4、每段 ≤ 255、无前导零。

**输入 → 输出**：logs(log_id, ip, status_code) → (invalid_count, ip)，按 invalid_count、ip 降序

正则版与 split 版思路不同，文件里有对应写法。

```sparksql
WITH
-- 1. 模拟 Logs 表
Logs AS (
    SELECT 1 AS log_id, '192.168.1.1' AS ip, 200 AS status_code UNION ALL
    SELECT 2, '256.1.2.3', 404 UNION ALL
    SELECT 3, '192.168.001.1', 200 UNION ALL
    SELECT 4, '192.168.1.1', 200 UNION ALL
    SELECT 5, '192.168.1', 500 UNION ALL
    SELECT 6, '256.1.2.3', 404 UNION ALL
    SELECT 7, '192.168.001.1', 200
)
select
    ip,
    count(distinct log_id) invalid_count
from Logs t1
    lateral view explode(split(t1.ip, '\\.')) t2 as bit_number
where
-- 2. 检查每个 8 位字节是否大于 255
    cast(bit_number as int) > 255
   or
-- 3. 检查是否有前导零
    bit_number like '0%'
   or
-- 4. 检查是否有少于或多于 4 个 8 位字节
    size(split(t1.ip, '\\.')) != 4
group by t1.ip
order by invalid_count desc;

/*
hive中并未直接提供ip地址处理相关的系统内置函数
*/
```

### 2025-41 · 模式匹配（DNA 序列四规则）

**源**：`SQLPractise/2025/41 模式匹配.sql`

**考点**：四条规则各写一个 `RLIKE`：`^ATG`、`(TAA|TAG|TGA)$`、`ATAT`、`G{3,}`，按 sample_id 输出命中情况。

**输入 → 输出**：Samples(sample_id, dna_sequence, species) → (sample_id, 是否起始密码子, 是否终止, 是否含 ATAT, 是否含 GGG+)

同一行可能同时满足多条规则，输出是多个布尔列而不是过滤。

```sparksql
WITH
-- 1. 模拟 Samples 表
Samples AS (SELECT 1 AS sample_id, 'ATGCTAGCTAGCTAA' AS dna_sequence, 'Human' AS species
            UNION ALL
            SELECT 2, 'GGGTCAATCATC', 'Human'
            UNION ALL
            SELECT 3, 'ATATATCGTAGCTA', 'Human'
            UNION ALL
            SELECT 4, 'ATGGGGTCAТСАТАА', 'Mouse'
            UNION ALL
            SELECT 5, 'TCAGTCAGTCAG', 'Mouse'
            UNION ALL
            SELECT 6, 'ATATCGCGCTAG', 'Zebrafish'
            UNION ALL
            SELECT 7, 'CGTATGCGTGTA', 'Zebrafish')
-- 场景1
select sample_id,
       dna_sequence,
       species,
       case when dna_sequence regexp '^ATG' then 1 else 0 end           as has_start,
       case when dna_sequence regexp 'TAA$|TAG$|TGA$' then 1 else 0 end as has_stop,
       case when dna_sequence regexp 'ATAT' then 1 else 0 end           as has_atat,
       case when dna_sequence regexp 'G{3,}' then 1 else 0 end          as has_ggg
from Samples t1
order by sample_id;

/* 结果：
| sample_id | dna_sequence   | species   | has_start | has_stop | has_atat | has_ggg |
|:----------|:---------------|:----------|:----------|:---------|:---------|:--------|
| 1         | ATGCTAGCTAA    | Human     | 1         | 1        | 0        | 0       |
| 2         | GGGTCAATCATC   | Human     | 0         | 0        | 0        | 1       |
| 3         | ATATATCGTAGCTA | Human     | 0         | 0        | 1        | 0       |
| 4         | ATGGGTCATCATA  | Mouse     | 1         | 0        | 0        | 1       |
| 5         | TCAGTCAGTCAG   | Mouse     | 0         | 0        | 0        | 0       |
| 6         | ATATCGCGCTAG   | Zebrafish | 0         | 1        | 1        | 0       |
| 7         | CGTATGCGTGTA   | Zebrafish | 0         | 0        | 0        | 0       |
*/


-- 场景2 ， 查询每个dns序列符合特定序列的次数
WITH
-- 1. 模拟 Samples 表
Samples AS (
    SELECT 1 AS sample_id, 'ATGCTAGCTAGCTAA' AS dna_sequence, 'Human' AS species UNION ALL
    SELECT 2, 'GGGTCAATCATC',    'Human'     UNION ALL
    SELECT 3, 'ATATATCGTAGCTA',  'Human'     UNION ALL
    SELECT 4, 'ATGGGGTCAТСАТАА', 'Mouse'     UNION ALL
    SELECT 5, 'TCAGTCAGTCAG',    'Mouse'     UNION ALL
    SELECT 6, 'ATATCGCGCTAG',    'Zebrafish' UNION ALL
    -- 添加一个用于演示重叠计数的例子
    SELECT 8, 'GGGATATATGGG',    'Test'
),
explode_sequence as (
    select t1.sample_id,
           t1.dna_sequence,
           t1.species,
           t2.pos
    -- 使用 posexplode 和 split 函数将 dna_sequence 分割成单个字符,取每个字符的位置
    from Samples t1
    lateral view posexplode(split(space(length(t1.dna_sequence) - 1), ' ')) t2 AS pos, val
    )
select t1.sample_id,
       t1.dna_sequence,
       t1.species,
       -- 使用 substring 函数和条件聚合来计算每个模式的出现次数
       sum(case when substring(t1.dna_sequence,t2.pos,3) = 'ATG' and t2.pos = 0 then 1 else 0 end)           as start_ATG_count,
       sum(case when substring(t1.dna_sequence,t2.pos,3) in ('TAA', 'TAG', 'TGA') and t2.pos = length(t1.dna_sequence) - 2 then 1 else 0 end) as stop_count,
       sum(case when substring(t1.dna_sequence,t2.pos,4) = 'ATAT' then 1 else 0 end)           as atat_count,
       sum(case when substring(t1.dna_sequence,t2.pos,3) = 'GGG' then 1 else 0 end)          as ggg_count

from Samples t1
         left join explode_sequence t2
                   on t1.sample_id  = t2.sample_id
group by  t1.sample_id,
          t1.dna_sequence,
          t1.species
order by t1.sample_id;

/*结果
| sample_id | dna_sequence   | species   | start_count | stop_count | atat_count | ggg_count |
|:----------|:---------------|:----------|:------------|:-----------|:-----------|:----------|
| 1         | ATGCTAGCTAA    | Human     | 1           | 1          | 1          | 0         |
| 2         | GGGTCAATCATC   | Human     | 0           | 0          | 0          | 2         |
| 3         | ATATATCGTAGCTA | Human     | 0           | 0          | 3          | 0         |
| 4         | ATGGGTCATCATA  | Mouse     | 1           | 0          | 0          | 2         |
| 5         | TCAGTCAGTCAG   | Mouse     | 0           | 0          | 0          | 0         |
| 6         | ATATGCGGCTAG   | Zebrafish | 0           | 1          | 2          | 0         |
| 8         | GGGATATATGGG   | Test      | 0           | 0          | 2          | 3         |
*/
```

### 2025-78 · 页面平均访问时长（json 展开 + 下一次行为算时长）

**源**：`spark_SQL例题.md` §78 页面平均访问时长

**考点**：`from_json` + `explode` 展开 actions 得 (url, time)，`lead(time)` 取下一次行为时间相减得本次时长，最后一次无后继故不参与。

**输入 → 输出**：user_log_5(uid, actions=JSON 数组) → 每个用户在每个页面上的平均访问时长（秒）

**该题只在 `spark_SQL例题.md` §78 中**，无独立 .sql 文件。

```sparksql
WITH user_log_5 AS (
    SELECT * FROM VALUES
                      (
                          'u001',
                          '[{"url":"url01","time":"2025-01-01 10:00:00"},{"url":"url02","time":"2025-01-01 10:01:10"},{"url":"url03","time":"2025-01-01 10:01:20"},{"url":"url02","time":"2025-01-01 10:02:00"},{"url":"url04","time":"2025-01-01 10:05:00"}]'
                      ),
                      (
                          'u002',
                          '[{"url":"url01","time":"2025-01-01 11:00:00"},{"url":"url02","time":"2025-01-01 11:03:00"},{"url":"url01","time":"2025-01-01 11:05:30"},{"url":"url03","time":"2025-01-01 11:06:00"},{"url":"url02","time":"2025-01-01 11:10:00"}]'
                      ),
                      (
                          'u003',
                          '[{"url":"url05","time":"2025-01-01 09:00:00"},{"url":"url05","time":"2025-01-01 09:02:00"},{"url":"url06","time":"2025-01-01 09:05:00"}]'
                      )
                      AS t(uid, actions)
),
    detail as (
        select
            uid,
            url,
            final_view_time as enter_view_time,
            -- 最后一次浏览不计入结果
            lead(final_view_time, 1) over (partition by uid order by final_view_time asc) left_view_time
        from (
                 select
                     t1.uid,
                     t2.item.url,
                     max(to_unix_timestamp(t2.item.time, 'yyyy-MM-dd HH:mm:ss')) final_view_time
                 from user_log_5 t1
                          lateral view explode (from_json(actions,'ARRAY<STRUCT<url:STRING, time:STRING>>')) t2 as item
                 group by t1.uid, t2.item.url
             ) t3
    )
select
    uid,
    url,
    left_view_time - enter_view_time wait_time,
    avg(left_view_time - enter_view_time) over(partition by  uid) avg_wait_time
from detail;
```

---

## H · 树形层级与递归 / 自连接（5 题）

Spark SQL 里递归 CTE 支持有限，实战多用**有限次自连接**（经理数不超过 k 层）或先展开再聚合。核心是把「父子关系」翻成「层级路径」或「可传递闭包」。

### 2024-24 · 原创文章的引用次数

**源**：`SQLPractise/2024/24原创文章的引用次数.sql`

**考点**：用 `collect_set(if(oid=0, id, null)) over()` 把「原创 id 集合」广播到每一行，再 `array_contains` 判断本行 oid 是否原创。

**输入 → 输出**：article(id, oid)（oid=0 表示原创） → (oid, ref_count)：被引用的原创文章 id 及其被引用次数

不是自连接，是「窗口聚合出集合 + 数组包含」的写法。

```sparksql
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

### 2025-42 · 员工按照职级排序（层级 + 团队规模）

**源**：`SQLPractise/2025/42 员工按照职级排序.sql`

**考点**：层级靠多次自连接往上追到 CEO；团队规模靠向下层层 join 汇总，或递归 CTE。

**输入 → 输出**：Employees(employee_id, employee_name, manager_id, salary, department) → (employee_id, 层级, 团队规模)，按 employee_id 升序

本题两个指标方向相反（向上 / 向下），是最适合对比递归与自连接的题。

```sparksql
WITH
-- 1. 模拟 Employees 表
Employees AS (
    SELECT 2 AS employee_id, 'Bob' AS employee_name, 1 AS manager_id, 10000 AS salary, 'Sales' AS department UNION ALL
    SELECT 1 AS employee_id, 'Alice' AS employee_name, null AS manager_id, 12000 AS salary, 'Executive' AS department UNION ALL
    SELECT 3, 'Charlie', 1, 10000, 'Engineering' UNION ALL
    SELECT 4, 'David', 2, 7500, 'Sales' UNION ALL
    SELECT 5, 'Eva', 2, 7500, 'Sales' UNION ALL
    SELECT 6, 'Frank', 3, 9000, 'Engineering' UNION ALL
    SELECT 7, 'Grace', 3, 8500, 'Engineering' UNION ALL
    SELECT 8, 'Hank', 4, 6000, 'Sales' UNION ALL
    SELECT 9, 'Ivy', 6, 7000, 'Engineering' UNION ALL
    SELECT 10, 'Judy', 6, 7000, 'Engineering'
),
level1 as (
    select
        employee_id,
        employee_name,
        1 as level,
        concat('/', employee_id, '/') as path,
        salary
    from Employees
    where manager_id is null
),
level2 as (
    select
        e.employee_id,
        e.employee_name,
        2 as level,
        concat(l1.path, e.employee_id, '/') as path,
        e.salary
    from Employees e
             join level1 l1 on e.manager_id = l1.employee_id
),
level3 as (
    select
        e.employee_id,
        e.employee_name,
        3 as level,
        concat(l2.path, e.employee_id, '/') as path,
        e.salary
    from Employees e
             join level2 l2 on e.manager_id = l2.employee_id
),
level4 as (
    select
        e.employee_id,
        e.employee_name,
        4 as level,
        concat(l3.path, e.employee_id, '/') as path,
        e.salary
    from Employees e
             join level3 l3 on e.manager_id = l3.employee_id
),
full_hierarchy as (
    select * from level1 union all
    select * from level2 union all
    select * from level3 union all
    select * from level4
)

select
    t2.employee_id,
    t2.employee_name,
    t2.level,
    -- team_size: 计算下属数量 (直接+间接)
    count(t3.employee_id) as team_size,
    -- budget: 计算薪资预算 (所有手下员工的工资总和，包括间接下属，加上自己的工资)
    nvl(sum(t3.salary),0) + t2.salary as budget
from full_hierarchy t2
         -- 获取每个职员的直接下属
         left join full_hierarchy t3 on t3.path like concat(t2.path, '%') and t2.employee_id != t3.employee_id
group by t2.employee_id,
         t2.employee_name,
         t2.salary,
         t2.level
order by t2.level asc,
         budget desc,
         t2.employee_name asc;
```

### 2025-48 · 至少有五个直接下属的经理

**源**：`SQLPractise/2025/48 五个下属的经理.sql`

**考点**：`group by managerId having count(*) >= 5`，再回连取姓名。

**输入 → 输出**：Employee(id, name, department, managerId) → 直接下属 ≥ 5 的经理 (name)

只数直接下属，不做递归 —— 与 2025-72 的间接下属正好互补。

```sparksql
WITH
-- 1. 模拟 Employee 表
Employee AS (
    SELECT 101 AS id, 'John' AS name, 'A' AS department, CAST(NULL AS INT) AS managerId UNION ALL
    SELECT 102, 'Dan',   'A', 101 UNION ALL
    SELECT 103, 'James', 'A', 101 UNION ALL
    SELECT 104, 'Amy',   'A', 101 UNION ALL
    SELECT 105, 'Anne',  'A', 101 UNION ALL
    SELECT 106, 'Ron',   'B', 101
)
select
    t1.name
from Employee t1
         left join Employee t2
                   on t1.id = t2.managerId
group by t1.id,t1.name
having count(1) >= 5
```

### 2025-57 · 遍历二叉树（节点类型）

**源**：`SQLPractise/2025/57 遍历二叉树.sql`

**考点**：`p_id is null` → Root；`id in (子查询 p_id)` → Inner；否则 Leaf。

**输入 → 输出**：Tree(id, p_id) → (id, type∈{Root,Inner,Leaf})

三种类型的判定顺序会影响结果，写成 case 时要注意先后。

```sparksql
WITH
-- 1. 模拟 Tree 表
Tree AS (
    SELECT 1 AS id, CAST(NULL AS INT) AS p_id UNION ALL
    SELECT 2, 1 UNION ALL
    SELECT 3, 1 UNION ALL
    SELECT 4, 2 UNION ALL
    SELECT 5, 2
)
/*
思路：
1. 根节点的父节点为null
2.叶子节点没有子节点
3. 其余为中间节点
*/


select
    id,
    type
from (
         select
             t2.id,
             case
                 when p_id is null then 'Root'
                 when p_id is not null and  s_id is not null then 'Inner'
                 else 'Leaf' end as type
         from (
                  select
                      t0.id,
                      t0.p_id,
                      t1.id s_id
                  from Tree t0
                           left join Tree t1
                                     on t0.id = t1.p_id
              ) t2

     ) t3
group by id,type;
```

### 2025-72 · CEO 的直接与间接下属

**源**：`SQLPractise/2025/72 找出ceo的直接下属和下属的下属.sql`

**考点**：题干保证「经理层数不超过 3」，所以可以两次自连接从 CEO 往下展开。

**输入 → 输出**：Employees(employee_id, employee_name, manager_id) → 直接或间接向 CEO(employee_id=1) 汇报的 employee_id

题干给了层数上限，正说明它是要你用「有限次自连接」而不是递归。

```sparksql
WITH
-- 1. 模拟 Employees 表
Employees AS (
    SELECT 1 AS employee_id, 'Boss' AS employee_name, 1 AS manager_id UNION ALL
    SELECT 3, 'Alice', 1 UNION ALL
    SELECT 2, 'Bob', 1 UNION ALL
    SELECT 4, 'Daniel', 2 UNION ALL
    SELECT 7, 'Luis', 4 UNION ALL
    SELECT 8, 'Jhon', 3 UNION ALL
    SELECT 9, 'Angela', 8 UNION ALL
    SELECT 77, 'Robert', 1
),
-- 解法题目描述有出入
ceo as (
    select
        employee_id,
        concat('/',employee_id) path
    from Employees
    where manager_id = employee_id
),
level_1 as (
    select
        t2.employee_id,
        concat(t1.path,'/',t2.employee_id) path
    from ceo t1
             left join  Employees t2
                        on t1.employee_id = t2.manager_id and t1.employee_id != t2.employee_id
),
level_2 as (
    select
        t2.employee_id,
        concat(t1.path,'/',t2.employee_id) path
    from level_1 t1
             left join  Employees t2
                        on t1.employee_id = t2.manager_id
    where t2.employee_id is not null
),
level_3 as (
    select
        t2.employee_id,
        concat(t1.path,'/',t2.employee_id) path
    from level_2 t1
             left join  Employees t2
                        on t1.employee_id = t2.manager_id
    where t2.employee_id is not null
)
select
    employee_id
from (
         select * from ceo
         union all
         select * from level_1
         union all
         select * from level_2
         union all
         select * from level_3
     )
where size(split(path,'/')) > 2 and size(split(path,'/')) <= 4
```

---

## I · 贪心、调度与过程模拟（3 题）

SQL 没有循环，靠**有序累计 + 约束过滤**模拟贪心：按优先级排序求累计和，取累计值不超预算的前若干条。

### 2025-20 · 雇佣员工（贪心 1：先最多高级再最多初级）

**源**：`SQLPractise/2025/20 雇佣员工（贪心算法1）.sql`

**考点**：按经验分组、薪资升序求累计和，取累计不超 70000 的条数：先花完高级预算，剩的再雇初级。

**输入 → 输出**：Candidates(employee_id, experience, salary) → (高级录用人数, 初级录用人数)

与 2025/50 是同一道题；与 2025-21 的差别只在选人优先级。

```sparksql
WITH
-- 1. 模拟 Candidates 表
/*Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 10000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 20000 UNION ALL
    SELECT 11, 'Senior', 20000 UNION ALL
    SELECT 13, 'Senior', 50000 UNION ALL
    SELECT 4, 'Junior', 40000
),*/
Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 10000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 80000 UNION ALL
    SELECT 11, 'Senior', 80000 UNION ALL
    SELECT 13, 'Senior', 80000 UNION ALL
    SELECT 4, 'Junior', 40000
),
-- 获取所有经验级别
levels as (
    select
        distinct experience
    from Candidates
),
-- 计算高级候选人的当前余额
senior_candidates AS (
    select
        employee_id,
        current_balance
    from (
             SELECT employee_id, salary,
                    70000 - sum(salary) OVER (ORDER BY salary) AS current_balance
             FROM Candidates
             WHERE experience = 'Senior'
             ORDER BY salary
         ) t1
    where current_balance >= 0
),
-- 计算高级候选人的当前余额，如果没有高级候选人，则设置最小余额为70000
balance as (
    select
        nvl(min(current_balance),70000) as min_balance
    from senior_candidates
),
-- 计算初级候选人的当前余额
junior_candidates AS (
    select
        employee_id,
        current_balance
    from (
             SELECT employee_id, salary,
                    balance.min_balance - sum(salary) OVER (ORDER BY salary) AS current_balance
             FROM Candidates,balance
             WHERE experience = 'Junior'
             ORDER BY salary
         ) t1
    where current_balance >= 0
)
-- 最终查询，统计每个经验级别的候选人数量
select
    tt.experience,
    nvl(t1.accepted_candidates, 0) as accepted_candidates
from levels tt
         left join (
    select
        'Senior' as experience,
        count(*) as accepted_candidates
    from senior_candidates
    union all
    select
        'Junior' as experience,
        count(*) as accepted_candidates
    from junior_candidates
) t1 on tt.experience = t1.experience;
```

### 2025-21 · 雇佣员工（贪心 2：最低薪资优先）

**源**：`SQLPractise/2025/21 雇佣员工（贪心算法2）.sql`

**考点**：同样是「排序 + 累计和 ≤ 预算」，但题干细化为「始终选最便宜的」，逻辑更贴近经典贪心。

**输入 → 输出**：Candidates → (高级录用人数, 初级录用人数)

与 2025-20 是变体对：规则不同（先最多高级 vs 最低薪优先），答案可能不同。

```sparksql
WITH
-- 1. 模拟 Candidates 表数据
-- Candidates AS (
--     SELECT 1 AS employee_id, 'Junior' AS experience, 10000 AS salary UNION ALL
--     SELECT 9, 'Junior', 15000 UNION ALL
--     SELECT 2, 'Senior', 20000 UNION ALL
--     SELECT 11, 'Senior', 16000 UNION ALL
--     SELECT 13, 'Senior', 50000 UNION ALL
--     SELECT 4, 'Junior', 40000
-- ),
Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 25000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 85000 UNION ALL
    SELECT 11, 'Senior', 80000 UNION ALL
    SELECT 13, 'Senior', 90000 UNION ALL
    SELECT 4, 'Junior', 30000
),


hired_seniors as (
    select
        employee_id,
        cost
    from (
             select
                 employee_id,
                 sum(salary) over(order by salary) cost
             from Candidates t1
             where experience = 'Senior'
         ) t2
    where cost <= 70000
),
hired_juniors as (
    select
        employee_id,
        cost
    from (
             select
                 employee_id
                  , sum(salary) over(order by salary) cost
             from Candidates
             where experience = 'Junior'
         ) t1
    where cost <= 70000 - (select nvl(max(cost),0) from hired_seniors)
)
select
    employee_id
from hired_juniors
union  all
select
    employee_id
from hired_seniors;

-- 方式2
WITH
-- 1. 使用 WITH 子句模拟您提供的 Candidates 表数据
Candidates AS (
    SELECT 1 AS employee_id, 'Junior' AS experience, 25000 AS salary UNION ALL
    SELECT 9, 'Junior', 10000 UNION ALL
    SELECT 2, 'Senior', 85000 UNION ALL
    SELECT 11, 'Senior', 80000 UNION ALL
    SELECT 13, 'Senior', 90000 UNION ALL
    SELECT 4, 'Junior', 30000
)

/**
第一次SUM OVER(PARTITION BY ...)，在各自组内进行“预演”，淘汰掉那些仅靠本组力量都无法入围的候选人。
第二次SUM OVER()，在全局范围内，按我们之前创建的优先级 experience_rk 排序，如果优先级相同（即都是高级或都是初级），则再按薪资 salary 排序。
  这完美地实现了**“先按薪资从低到高排列所有（备选的）高级员工，然后紧接着按薪资从低到高排列所有（备选的）初级员工”**这一最终雇佣顺序。
 */
SELECT
    employee_id
FROM
    (
        SELECT
            *,
            70000 - SUM(salary) OVER(ORDER BY experience_rk, salary) AS sum_salary2
        FROM
            (
                SELECT
                    *,
                    70000 - SUM(salary) OVER(PARTITION BY experience ORDER BY salary) AS sum_salary,
                    IF(experience = 'Senior', 1, 2) AS experience_rk
                FROM
                    Candidates
            ) t
        WHERE t.sum_salary >= 0
    ) t2
WHERE t2.sum_salary2 >= 0;
```

### 2025-68 · 最后一个上巴士的人（1000kg 约束）

**源**：`SQLPractise/2025/68 最后一个上巴士的人.sql`

**考点**：按 turn 排序求累计体重，取累计 ≤ 1000 的最后一行。

**输入 → 输出**：Queue(person_id, person_name, weight, turn) → 最后一位能上车的 person_name

与 2024/37 是同一道题；「累计和卡阈值 + 取最后一行」是贪心题的标准 SQL 形态。

```sparksql
WITH
-- 1. 模拟 Queue 表
Queue AS (
    SELECT 5 AS person_id, 'Alice' AS person_name, 250 AS weight, 1 AS turn UNION ALL
    SELECT 4, 'Bob', 175, 5 UNION ALL
    SELECT 3, 'Alex', 350, 2 UNION ALL
    SELECT 6, 'John Cena', 400, 3 UNION ALL
    SELECT 1, 'Winston', 500, 6 UNION ALL
    SELECT 2, 'Marie', 200, 4
)
select
    person_name
from (
         select
             person_name,
             row_number() over (order by turn desc) bottom_number
         from (
                  select person_id,
                         person_name,
                         weight,
                         turn,
                         sum(weight) over(order by turn) current_total_weight
                  from Queue t0

              ) t1
         where current_total_weight <= 1000
     ) t2
where bottom_number = 1
```

---

## J · 日期处理与时间维度（6 题）

生成日期/月份序列（`sequence` + `explode`、`add_months`、`last_day`）、按年拆期、区间求日均、同比用 `lag` 或自连接上年同期。

### 2024-53 · Hopper 司机接受次数（系列 1：按月生成日历）

**源**：`SQLPractise/2024/53 司机接受乘车次数，系列题目1.sql`

**考点**：为每个司机生成「入司月 → 当前月」的月份序列，再左连实际接单，`union all` 出 Accepted / Rejected 两种情况。

**输入 → 输出**：Drivers(driver_id, join_date) + Rides(ride_id, user_id, requested_at) → 每个司机每个月的 (接受次数, 拒绝次数)，无单的月份出 0

系列三题的第 1 题，主题是「补全时间骨架」。

```sparksql
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
```

### 2024-54 · Hopper 司机接受次数（系列 2）

**源**：`SQLPractise/2024/54 司机接受乘车次数，系列题目2.sql`

**考点**：与系列 1 同一套数据，问题换成「每个司机每个月的接受率 / 取消率」。

**输入 → 输出**：Drivers + Rides → 每个司机每个月接受与取消的比例

与 53 相邻阅读：骨架相同，指标不同。

```sparksql
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
```

### 2024-55 · Hopper 司机接受次数（系列 3）

**源**：`SQLPractise/2024/55 司机接受乘车次数，系列题目3.sql`

**考点**：与系列 1 同一套数据，问题换成「截至某日各司机累计接受 / 拒绝次数」。

**输入 → 输出**：Drivers + Rides → 截至每日的累计接受与拒绝次数

与前两题相邻阅读：骨架 → 比例 → 累计。

```sparksql
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
```

### 2024-57 · 日平均销售额（按年拆期）

**源**：`SQLPractise/2024/57 日平均销售额（需要有时间维度表，和平均绩效等挂钩.sql`

**考点**：产品销售期用 `period_start/period_end` 表示并提供日均值，求每年销售额：按年取交集天数 × 日均值再汇总。

**输入 → 输出**：Product(product_id, product_name) + Sales(product_id, period_start, period_end, average_daily_sales) → (product_id, product_name, report_year, total_amount)，按 product_id、report_year 排序

与 大数据md §日平均销售额 是同一题；「跨年销售期要按年切分」是唯一难点。

```sparksql
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
```

### 2025-36 · 同比增长率

**源**：`SQLPractise/2025/36 同比增长率.sql`

**考点**：按年 × 产品汇总后，`lag(spend) over(partition by product_id order by year)` 取上年，再算增长率。

**输入 → 输出**：user_transactions(transaction_id, product_id, spend, transaction_date) → (year, product_id, curr_year_spend, prev_year_spend, yoy_rate)，按 year、product_id 升序

首个年份没有上年，增长率要出 NULL 而不是 0。

```sparksql
WITH
-- 1. 模拟 user_transactions 表
user_transactions AS (
    SELECT 1341 AS transaction_id, 123424 AS product_id, CAST(1500.60 AS DECIMAL(10,2)) AS spend, CAST('2019-12-31 12:00:00' AS TIMESTAMP) AS transaction_date UNION ALL
    SELECT 1423, 123424, CAST(1000.20 AS DECIMAL(10,2)), CAST('2020-12-31 12:00:00' AS TIMESTAMP) UNION ALL
    SELECT 1623, 123424, CAST(1246.44 AS DECIMAL(10,2)), CAST('2021-12-31 12:00:00' AS TIMESTAMP) UNION ALL
    SELECT 1322, 123424, CAST(2145.32 AS DECIMAL(10,2)), CAST('2022-12-31 12:00:00' AS TIMESTAMP)
)
select product_id,
       year,
       curr_year_spend,
       prev_year_spend,
       round(((curr_year_spend - prev_year_spend) / prev_year_spend) * 100, 2)  as yoy_rate
from (
         select
             product_id , year(transaction_date) year,
             sum(spend) as curr_year_spend,
             lag(sum(spend)) over (partition by product_id order by year(transaction_date)) as prev_year_spend
         from user_transactions t1
         group by product_id , year(transaction_date)
     ) t2
order by product_id, year;
```

### 2025-56 · 日期格式转化（区间取后值转 yyyymmdd）

**源**：`SQLPractise/2025/56 日期格式转化.sql`

**考点**：`split(date_id, '~')` 取后半段，`str_to_date` + `date_format('yyyyMMdd')` 转目标格式。

**输入 → 输出**：a.date_id（形如 '2025-3-7~2025-3-1'） → 后段日期的 yyyymmdd 形式（20250301）

单数字月份不需要补零，`date_format` 自动处理。

```sparksql
WITH
-- 1. 模拟表 a 和 date_id 字段
a AS (
    SELECT '2025-3-7~2025-3-1' as date_id UNION ALL
    SELECT '2025-4-22~2025-4-9' UNION ALL
    SELECT '2025-5-13~2025-4-23' UNION ALL
    SELECT '2025-11-20~2025-11-12'
)
select
    date_id,
    concat(
            split(suffix_date, '-')[0],
            '-',
            lpad(split(suffix_date, '-')[1], 2, '0'),
            '-',
            lpad(split(suffix_date, '-')[2], 2, '0')
    ) suffix_deal_date


from (
         select
             date_id,
             split(date_id,'~')[1] suffix_date
         from a
     ) t0
```

---

## K · Spark SQL 执行与优化（1 题）

本类只有一条**笔记而非题目**：AQE 与 join 策略（broadcast vs sort-merge）。

### 2025-74 · 大表 join 小表在 Spark SQL 的执行计划

**源**：`SQLPractise/2025/74 大表 join 小表在spark sql的执行计划.sql`

**考点**：A 表千万级、B/C 千级：先用 `left anti join` 或 `not in` 求差集，再依赖 AQE 在运行期把小表自动转 broadcast。

**输入 → 输出**：A(a1..a4) 千万级 + B(b1..) / C(c1..) 千级，A.a1=B.b1、A.a2=C.c1 → A 中既不在 B 也不在 C 的记录

**本类唯一一条是笔记而非题目**：没有造数、没有执行结果，正文是对 AQE 与 join 策略的说明。

```sparksql
-- 由于spark 3.0以上版本存在AQE，在执行计划阶段，有规划阶段（initial plan），和最终执行阶段（final plan），Spark 会在运行时根据实际的数据统计信息动态调整Join 策略，
-- 比如spark join首选 sort merge join，在AQE后，发现小表的数据量小于设置的 spark.sql.autoBroadcastJoinThreshold 阈值，那么 会转化为broadcast hash join执行
-- spark 3.0后，自动有这个优化，一般不需要特定的参数优化
-- 具体说明文档可参考博客：https://5201969.xyz/post/-1122271105#spark%E7%9A%84join%E9%80%89%E6%8B%A9%E7%AD%96%E7%95%A5

-- explain
WITH

    A (a1, a2, a3, a4) AS (
        SELECT * FROM (VALUES
                           (101, 201, 'Data-AAA', 'Info-01'),
                           (102, 999, 'Data-BBB', 'Info-02'),
                           (998, 202, 'Data-CCC', 'Info-03'),
                           (999, 999, 'Data-DDD', 'Info-04'),
                           (103, 203, 'Data-EEE', 'Info-05'),
                           (888, 888, 'Data-FFF', 'Info-06')
                      ) AS t (a1, a2, a3, a4)
    ),


    B (b1, b2, b3) AS (
        SELECT * FROM (VALUES
                           (101, 'B-Info-1', 'Desc-1'),
                           (102, 'B-Info-2', 'Desc-2'),
                           (103, 'B-Info-3', 'Desc-3'),
                           (104, 'B-Info-4', 'Desc-4')
                      ) AS t (b1, b2, b3)
    ),


    C (c1, c2, c3, c4) AS (
        SELECT * FROM (VALUES
                           (201, 'C-Info-A', 'Detail-A', 100),
                           (202, 'C-Info-B', 'Detail-B', 200),
                           (203, 'C-Info-C', 'Detail-C', 300)
                      ) AS t (c1, c2, c3, c4)
    )
-- select
--     t1.*
-- FROM A t1
-- left join B t2 on t1.a1 = t2.b1
-- left join C t3 on t1.a1 = t3.c1
-- where t2.b1 is null and t3.c1 is null;

-- map join 加上 先过滤，后输出
SELECT /*+ MAPJOIN(B, C) */
    A.a1,
    A.a2,
    A.a3,
    A.a4
FROM
    A
        LEFT ANTI JOIN B ON A.a1 = B.b1
        LEFT ANTI JOIN C ON A.a2 = C.c1;
```

---

## L · 关系网络与集合运算（17 题）

双向关系去重（`A<B` 归并）、共同好友用自连接 + 计数、推荐用「好友喜欢 − 我已有」做差集、「全部满足」用 `count(distinct)` 与总量比对、反连接找「没有发生过的」。

### 2024-14 · 相互关注（fans 表，去重输出）

**源**：`SQLPractise/2024/14相互关注.sql`

**考点**：`fans` 自连接 `a.from=b.to and a.to=b.from`，再用 `from_user < to_user` 去重成无序对。

**输入 → 输出**：fans(from_user, to_user, notice_date) → 互相关注的 (user1, user2)，每对只出一次

与大数据md §查找互相关注的用户对 SQL 正文一致；与 2024/62 同名不同题。

```sparksql
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
) result_table
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

### 2024-35 · 推荐画像

**源**：`SQLPractise/2024/35 推荐画像.sql`

**考点**：`collect_set(product_name)` 聚成数组后，用 `array_contains` 同时判定「买过 A」「买过 B」「没买过 C」。

**输入 → 输出**：Customers + Orders → 同时买过 A 和 B、且没买过 C 的 (customer_id, customer_name)

与 2025/14、2025/71 的推荐思路不同：这条是数组包含判定，不是差集。

```sparksql
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

### 2024-38 · 发票信息（顾客与联系人姓名 + 邮箱双匹配）

**源**：`SQLPractise/2024/38 发票信息.sql`

**考点**：按「姓名 + 邮箱」两列同时匹配 Customers 与 Contacts，区分 matching / not matching 两类。

**输入 → 输出**：Customers(customer_id, customer_name, email) + Contacts(user_id, contact_name, contact_email) → (invoice_id, 匹配关系, 邮箱)

与 2024/47「发票信息」**同名但完全不同**：38 是双列匹配，47 是每组最贵。

```sparksql
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
```

### 2024-45 · 好友受欢迎程度百分比

**源**：`SQLPractise/2024/45 好友受欢迎程度百分比.sql`

**考点**：双向展开成「用户-好友」长表，`count(好友) / count(distinct 总用户)` × 100。

**输入 → 输出**：Friends(user1, user2) → (user1, friends_count, popularity_percentage)，按 user1 升序

分母是平台用户总数，不是好友总数 —— 最常见的错解。

```sparksql
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
```

### 2024-58 · 没有交易但访问了银行的客户

**源**：`SQLPractise/2024/58 找出没有进行交易但是访问了银行的客户（点击加购但是没有下单 的顾客).sql`

**考点**：`Visits left join Trans` 后 `where trans is null`，等价于 `not exists` / `left anti join`。

**输入 → 输出**：Visits(user_id, visit_date) + Trans(user_id, transaction_date, amount) → 有访问但无交易的 (user_id, visit_date)

「点击加购未下单」「浏览未参与」都是同一个反连接模板。

```sparksql
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
```

### 2024-61 · 关注但非互关 / 二级用户及关注者数

**源**：`SQLPractise/2024/61 关注但非互关.sql`

**考点**：既关注了人、又被人关注 → 二级用户；对这批人按 follower 计数。

**输入 → 输出**：Follow(followee, follower) → (follower, num_followers)，按 follower 字典序

题干里的「二级关注者」定义有两条件，缺一个答案就变。

```sparksql
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
```

### 2024-62 · 相互关注（共同好友数）

**源**：`SQLPractise/2024/62 相互关注.sql`

**考点**：以共同好友为桥梁自连接，统计每对用户的共同好友数，可选地再用窗口函数取最大。

**输入 → 输出**：fans(from_user, to_user, timestamp) → 每对用户及其共同好友数

与 2024/14 同名不同题；文件里方法 2 用「窗口函数 + hash」计算。

```sparksql
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
```

### 2025-03 · 购买了所有商品的客户

**源**：`SQLPractise/2025/3 购买了所有商品的客户（符合所有条件的员工.sql`

**考点**：`count(distinct product_key) = (select count(*) from Product)` —— 全称量词用计数比对。

**输入 → 输出**：Customer(customer_id, product_key) + Product(product_key) → 买齐了所有商品的 customer_id

「符合所有条件」的通用模板；Customer 表可能重复，所以必须 distinct。

```sparksql
WITH
-- 1. 模拟 Customer 表
Customer AS (
    SELECT 1 AS customer_id, 5 AS product_key UNION ALL
    SELECT 2, 6 UNION ALL
    SELECT 3, 5 UNION ALL
    SELECT 3, 6 UNION ALL
    SELECT 1, 6
),

-- 2. 模拟 Product 表
Product AS (
    SELECT 5 AS product_key UNION ALL
    SELECT 6
)
select
    t1.customer_id
from Customer t1
         left join Product t2
                   on t1.product_key = t2.product_key
         cross join (select count(1) total_products from Product) t3
group by t1.customer_id,t3.total_products
having count(distinct t2.product_key) = t3.total_products;
```

### 2025-12 · 用户之间的通话次数和时长

**源**：`SQLPractise/2025/12 用户之间的通话次数和时长.sql`

**考点**：`least(from_id,to_id)` / `greatest(...)` 归一成无序对，再 `count` / `sum(duration)`。

**输入 → 输出**：Calls(from_id, to_id, duration) → (person1, person2, call_count, total_duration)，保证 person1 < person2

A→B 与 B→A 必须合并成一对，这是所有双向关系统计的第一步。

```sparksql
WITH
-- 1. 模拟 Calls 表
Calls AS (
    SELECT 1 AS from_id, 2 AS to_id, 59 AS duration UNION ALL
    SELECT 2, 1, 11 UNION ALL
    SELECT 1, 3, 20 UNION ALL
    SELECT 3, 4, 100 UNION ALL
    SELECT 3, 4, 200 UNION ALL
    SELECT 3, 4, 200 UNION ALL
    SELECT 4, 3, 499
)
/*select
    if(t1.from_id < t1.to_id, t1.from_id, t1.to_id) as person1,
    if(t1.from_id < t1.to_id, t1.to_id, t1.from_id) as person2,
    count(1) as call_count,
    sum(t1.duration) as total_duration
from Calls t1
group by if(t1.from_id < t1.to_id, t1.from_id, t1.to_id),
         if(t1.from_id < t1.to_id, t1.to_id, t1.from_id);*/

-- 方式2
select
    least(t1.from_id,t1.to_id),
    greatest(t1.from_id,t1.to_id),
    count(*) as call_count,
    sum(t1.duration) as total_duration
from Calls t1
group by  least(t1.from_id,t1.to_id),
          greatest(t1.from_id,t1.to_id);
```

### 2025-14 · 推荐页面（好友喜欢、我未互动）

**源**：`SQLPractise/2025/14 推荐页面.sql`

**考点**：好友喜欢的页面集合 `union` 起来，减去「我喜欢的」与「我讨厌的」，再排除已推荐的。

**输入 → 输出**：Friendship + Likes + （用户对页面的反馈） → (user_id, page_id) 推荐列表

与 2025/71 是变体对：14 面向多个用户，71 只面向 user_id = 1。

```sparksql
WITH
-- 1. 模拟 Friendship 表
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 1, 4 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 2, 5 UNION ALL
    SELECT 6, 1
),

-- 2. 模拟 Likes 表
Likes AS (
    SELECT 1 AS user_id, 88 AS page_id UNION ALL
    SELECT 2, 23 UNION ALL
    SELECT 3, 24 UNION ALL
    SELECT 4, 56 UNION ALL
    SELECT 5, 11 UNION ALL
    SELECT 6, 33 UNION ALL
    SELECT 2, 77 UNION ALL
    SELECT 3, 77 UNION ALL
    SELECT 6, 88
),
-- 3. 获取所有好友关系
all_friends AS (
    SELECT DISTINCT user1_id AS user_id, user2_id AS friend_id FROM Friendship
    UNION
    SELECT DISTINCT user2_id AS user_id, user1_id AS friend_id FROM Friendship
),
-- 4. 获取用户和好友喜欢的页面情况
page_like_sutuation as (
    select
        t1.user_id,
        t2.page_id user_like_page_id,
        t1.friend_id,
        t3.page_id friend_like_page_id
    from all_friends t1
             left join Likes t2
                       on t1.user_id = t2.user_id
             left join Likes t3
                       on t1.friend_id = t3.user_id
)
select
    user_id,
    friend_like_page_id as page_id,
    -- 统计有多少好友喜欢了这个页面
    count(distinct friend_id) as friends_likes
from page_like_sutuation t1
-- 过滤掉用户自己喜欢的页面
where user_like_page_id <> friend_like_page_id
-- 对所有用户和好友喜欢的页面进行分组
group by user_id,friend_like_page_id;
```

### 2025-16 · 推荐歌曲（共同的收听记录）

**源**：`SQLPractise/2025/16 推荐歌曲(查找共同点).sql`

**考点**：对好友对求「共同听过的歌」，再按共同好友数与共同歌曲数筛选推荐。

**输入 → 输出**：Listens(user_id, song_id, day) + Friendship(user1_id, user2_id) → 好友对及其共同歌曲

与 2024/62 的共同好友模板同构，只是把「好友」换成了「歌曲」。

```sparksql
WITH
-- 1. 模拟 Listens 表
Listens AS (
    SELECT 1 AS user_id, 10 AS song_id, CAST('2021-03-15' AS DATE) AS day UNION ALL
    SELECT 1, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 1, 12, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 2, 10, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 2, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 2, 12, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 3, 10, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 3, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 3, 12, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 4, 10, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 4, 11, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 4, 13, CAST('2021-03-15' AS DATE) UNION ALL
    SELECT 5, 10, CAST('2021-03-16' AS DATE) UNION ALL
    SELECT 5, 11, CAST('2021-03-16' AS DATE) UNION ALL
    SELECT 5, 12, CAST('2021-03-16' AS DATE)
),

-- 2. 模拟 Friendship 表
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id
),
-- 3. 计算每个用户在每一天收听的歌曲数量在3首或以上的用户对
user_limit as (
    select user_id,
           song_id,
           day
    from (
             select user_id,
                    song_id,
                    day,
                    count(distinct song_id) over (partition by user_id, day) as song_count
             from Listens t1

         ) t2
    where song_count >= 3
    group by song_id, user_id, day
),
distinct_user_pair as (
    select
        user_id,
        recommended_id
    from (
             select
                 t1.user_id,
                 t2.user_id as recommended_id,
                 t1.song_id,
                 t1.day,
                 -- 计算不为好友的用户对在同一天收听相同歌曲的数量
                 count(distinct t1.song_id) over(partition by t1.user_id, t2.user_id, t1.day) as song_count
             from user_limit t1
                      -- 选择不同的用户对,对于同一天和同一首歌
                      inner join user_limit t2
                 -- 减少重复计算，比如《用户1 和用户2》，《用户2 和 用户1》是相同的
                                 on t1.user_id < t2.user_id
                                     and t1.day = t2.day
                                     and t1.song_id = t2.song_id
                 -- 排除已经是好友的用户对
                      left join Friendship t3
                                on t1.user_id = t3.user1_id
                                    and t2.user_id = t3.user2_id
             where t3.user1_id is null
         ) t4
    where song_count >= 3
    group by user_id,
             recommended_id
)
-- 4. 返回单向推荐的用户对
select user_id,recommended_id from distinct_user_pair
union  all
select recommended_id,user_id from distinct_user_pair;

-- 第二种简化写法
/*
WITH L AS(
    SELECT user_id, song_id, day
    FROM Listens
    GROUP BY user_id, song_id, day
),
T AS(
    SELECT L1.user_id AS u1_id, L2.user_id AS u2_id, L1.day, L1.song_id
    FROM L L1, L L2
    WHERE L1.day = L2.day AND L1.song_id = L2.song_id AND L1.user_id < L2.user_id
),
D AS(
    SELECT u1_id, u2_id, day
    FROM T
    GROUP BY u1_id, u2_id, day HAVING COUNT(*) >= 3
),
ANS AS(
    SELECT u1_id, u2_id
    FROM D
    GROUP BY u1_id, u2_id
    EXCEPT
    SELECT * FROM Friendship
)
SELECT u1_id AS user_id, u2_id AS recommended_id FROM ANS
UNION
SELECT u2_id, u1_id FROM ANS
EXCEPT
SELECT user2_id, user1_id FROM Friendship
*/
```

### 2025-17 · 坚定的友谊（≥3 个共同好友）

**源**：`SQLPractise/2025/17 坚定的友谊.sql`

**考点**：共同好友数 ≥ 3：`join` 两次 Friendship 求交集后 `having count >= 3`（或 count(distinct)）。

**输入 → 输出**：Friendship(user1_id, user2_id) → (user1_id, user2_id, common_friend) 中共同好友 ≥ 3 的行

与 spark md §79「坚定的友谊」是同一题；文件与 md 两份都要留档。

```sparksql
WITH
-- 1. 模拟 Friendship 表数据
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 1, 4 UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 1, 5 UNION ALL
    SELECT 2, 5 UNION ALL
    SELECT 1, 7 UNION ALL
    SELECT 3, 7 UNION ALL
    SELECT 1, 6 UNION ALL
    SELECT 3, 6 UNION ALL
    SELECT 2, 6
),
-- 2. 获取所有用户的好友对
all_pairs AS (
    select user1_id as user_id, user2_id as friend_id from Friendship t1
    union all
    select user2_id, user1_id from Friendship t1
)
select
    user_id user1_id,
    friend_id user2_id,
    count(distinct recommended_id1) as common_friend
from (
         select
             t1.user1_id user_id,
             t1.user2_id friend_id,
             t2.friend_id as recommended_id1,
             t3.friend_id as recommended_id2
         from Friendship t1
                  left join all_pairs t2
             -- 查询各个用户的好友，
                            on t1.user1_id = t2.user_id
                  left join all_pairs t3
             -- 查询各个用户的好友的好友
                            on t1.user2_id = t3.user_id
         where t2.friend_id = t3.friend_id
     ) t3
group by
    user_id,
    friend_id
having count(distinct recommended_id1) >= 3
```

### 2025-55 · 拥有最多好友的人及好友数

**源**：`SQLPractise/2025/55 有好友最多的人及好友数.sql`

**考点**：requester / accepter 双向 `union all` 成长表，`count(distinct 对方)` 后取最大。

**输入 → 输出**：RequestAccepted(requester_id, accepter_id, accept_date) → (id, num)，好友最多者仅一人

不双向展开会漏掉「只当过 accepter」的人。

```sparksql
WITH
-- 1. 模拟 RequestAccepted 表
RequestAccepted AS (
    SELECT 1 AS requester_id, 2 AS accepter_id, CAST('2016-06-03' AS DATE) AS accept_date UNION ALL
    SELECT 1, 3, CAST('2016-06-08' AS DATE) UNION ALL
    SELECT 2, 3, CAST('2016-06-08' AS DATE) UNION ALL
    SELECT 3, 4, CAST('2016-06-09' AS DATE)
)
-- 方式1
/*
select
    requester_id as id,
    count(distinct accepter_id) num
from (
         select requester_id,
                accepter_id
         from RequestAccepted t0
         union all
         select
             accepter_id,
             requester_id
         from RequestAccepted t1
     ) t2
group by requester_id
order by num desc
limit 1*/

-- 方式2
        ,
request_sent as (
    select
        requester_id as id,
        count(1) request_nums
    from RequestAccepted t0
    group by requester_id
),
receive_request as (
    select
        accepter_id as id,
        count(1) receive_nums
    from RequestAccepted t0
    group by accepter_id
)
select
    nvl(t0.id,t1.id) as id,
    sum(nvl(t0.receive_nums,0) ) + sum(nvl(t1.request_nums,0) ) as num
from receive_request t0
         full join request_sent t1
                   on t0.id = t1.id
group by nvl(t0.id,t1.id)
order by num desc
limit 1;
```

### 2025-62 · 注册和购买都在 2019 年的用户

**源**：`SQLPractise/2025/62 注册和购买都在2019年的用户.sql`

**考点**：`Users` 与 `Orders` 内连接后，要求 `join_date` 与 `order_date` 同为 2019 年，再数购买量。

**输入 → 输出**：Users(user_id, join_date) + Orders(order_id, order_date, item_id, buyer_id) → (buyer_id, join_date, orders_in_2019)，按 buyer_id 排序

「都在 2019」是两列各自过滤，不是区间交集。

```sparksql
WITH
-- 1. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, CAST('2018-01-01' AS DATE) AS join_date, 'Lenovo' AS favorite_brand UNION ALL
    SELECT 2, CAST('2018-02-09' AS DATE), 'Samsung' UNION ALL
    SELECT 3, CAST('2018-01-19' AS DATE), 'LG' UNION ALL
    SELECT 4, CAST('2018-05-21' AS DATE), 'HP'
),

-- 2. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, CAST('2019-08-01' AS DATE) AS order_date, 4 AS item_id, 1 AS buyer_id, 2 AS seller_id UNION ALL
    SELECT 2, CAST('2018-08-02' AS DATE), 2, 1, 3 UNION ALL
    SELECT 3, CAST('2019-08-03' AS DATE), 3, 2, 3 UNION ALL
    SELECT 4, CAST('2018-08-04' AS DATE), 1, 4, 2 UNION ALL
    SELECT 5, CAST('2018-08-04' AS DATE), 1, 3, 4 UNION ALL
    SELECT 6, CAST('2019-08-05' AS DATE), 2, 2, 4
),

-- 3. 模拟 Items 表 (此题解法中未使用，但为保持完整性而包含)
Items AS (
    SELECT 1 AS item_id, 'Samsung' AS item_brand UNION ALL
    SELECT 2, 'Lenovo' UNION ALL
    SELECT 3, 'LG' UNION ALL
    SELECT 4, 'HP'
)
select
    t0.user_id,
    t0.join_date,
    count(distinct t1.order_id)
from Users t0
         left join Orders t1
                   on t0.user_id = t1.buyer_id and year(t1.order_date) = 2019
group by t0.user_id,join_date
```

### 2025-63 · 卖出过两件商品的售货员

**源**：`SQLPractise/2025/63 出两件商品的售货员（符合条件判定）.sql`

**考点**：卖家 = `Orders.seller_id`，按卖家统计 2019 年售出件数，筛 `= 2`，再左连取 favorite_brand。

**输入 → 输出**：Users + Orders + Items → 2019 年卖出恰好 2 件的 (seller_id, join_date, favorite_brand)，按 seller_id 排序

「恰好 2 件」不是「≥2 件」，且件数按 item 计而非订单计。

```sparksql
WITH
-- 1. 模拟 Users 表
Users AS (
    SELECT 1 AS user_id, CAST('2019-01-01' AS DATE) AS join_date, 'Lenovo' AS favorite_brand UNION ALL
    SELECT 2, CAST('2019-02-09' AS DATE), 'Samsung' UNION ALL
    SELECT 3, CAST('2019-01-19' AS DATE), 'LG' UNION ALL
    SELECT 4, CAST('2019-05-21' AS DATE), 'HP'
),

-- 2. 模拟 Orders 表
Orders AS (
    SELECT 1 AS order_id, CAST('2019-08-01' AS DATE) AS order_date, 4 AS item_id, 1 AS buyer_id, 2 AS seller_id UNION ALL
    SELECT 2, CAST('2019-08-02' AS DATE), 2, 1, 3 UNION ALL
    SELECT 3, CAST('2019-08-03' AS DATE), 3, 2, 3 UNION ALL
    SELECT 4, CAST('2019-08-04' AS DATE), 1, 4, 2 UNION ALL
    SELECT 5, CAST('2019-08-04' AS DATE), 1, 3, 4 UNION ALL
    SELECT 6, CAST('2019-08-05' AS DATE), 2, 2, 4
),

-- 3. 模拟 Items 表
Items AS (
    SELECT 1 AS item_id, 'Samsung' AS item_brand UNION ALL
    SELECT 2, 'Lenovo' UNION ALL
    SELECT 3, 'LG' UNION ALL
    SELECT 4, 'HP'
)
select
    t3.user_id,
    if(t4.item_brand is not null , 'yes','no') 2nd_item_fav_brand
from Users t3
         left join (
    select
        t0.seller_id,
        t0.order_date,
        t1.item_brand,
        row_number() over (partition by t0.seller_id order by t0.order_date) sell_number
    from Orders t0
             left join Items t1
                       on t0.item_id = t1.item_id
) t4
                   on t3.user_id = t4.seller_id and t4.sell_number = 2 and t3.favorite_brand = t4.item_brand
```

### 2025-71 · 推荐朋友喜欢但你没喜欢的页面

**源**：`SQLPractise/2025/71 荐盆友喜欢但是你并没有喜欢的页面.sql`

**考点**：取 user_id=1 的所有好友喜欢的页面，减去 user_id=1 已喜欢的页面。

**输入 → 输出**：Friendship + Likes → 推荐给 user_id=1 的 page_id（去重、排序）

与 2025/14 是变体对：71 是 14 的单用户特例，题干更简单。

```sparksql
WITH
-- 1. 模拟 Friendship 表
Friendship AS (
    SELECT 1 AS user1_id, 2 AS user2_id UNION ALL
    SELECT 1, 3 UNION ALL
    SELECT 1, 4 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 2, 4 UNION ALL
    SELECT 2, 5 UNION ALL
    SELECT 6, 1
),

-- 2. 模拟 Likes 表
Likes AS (
    SELECT 1 AS user_id, 88 AS page_id UNION ALL
    SELECT 2, 23 UNION ALL
    SELECT 3, 24 UNION ALL
    SELECT 4, 56 UNION ALL
    SELECT 5, 11 UNION ALL
    SELECT 6, 33 UNION ALL
    SELECT 2, 77 UNION ALL
    SELECT 3, 77 UNION ALL
    SELECT 6, 88
),
page_like_situation as
    (
        SELECT
            t2.my_id,
            t3.page_id my_like_page,
            t2.friend_id,
            t4.page_id friend_like_page
        FROM
            (
                SELECT
                    user1_id my_id,
                    user2_id friend_id
                FROM
                    Friendship t0
                UNION ALL
                SELECT
                    user2_id,
                    user1_id
                FROM
                    Friendship t1
            ) t2
                LEFT JOIN Likes t3 ON t2.my_id = t3.user_id
                LEFT JOIN Likes t4 ON t2.friend_id = t4.user_id
    )
-- 方式1
/*
SELECT
    my_id,
    friend_like_page
FROM page_like_situation tt
WHERE tt.my_id = 1 AND tt.my_like_page != tt.friend_like_page
GROUP BY my_id, friend_like_page;
*/

-- 方式2 ,使用的spark sql 版本为3.3.1
select
    my_id,
    array_except(
            collect_set(friend_like_page),
            collect_set(my_like_page)
    ) as recommended_page

from page_like_situation t0
where my_id = 1
group by my_id

-- 方式3
/*
select
    t0.page_id as recommended_page
from Likes t0
-- 自己未关注的页面
where page_id not in (
    select
        t1.page_id
    from Likes t1
    where t1.user_id = 1
    )
  -- 朋友关注的页面
and t0.user_id in (
    select
        user2_id
    from Friendship t2
    where t2.user1_id = 1
    union
    select
        user1_id
    from Friendship t3
    where t3.user2_id = 1
    )
group by t0.page_id;
*/

-- 方式4 ，但数据基数（此处指系统中所有page_id去重后的数据量）达到 百万及以上级别， 可以考虑使用 bitmap实现
```

### 2025-80 · 共同关注者（共同关注者最多的两两结对）

**源**：`spark_SQL例题.md` §80 共同关注者

**考点**：自连接 Relations 求两两用户的共同 follower 数，取最大值后输出全部并列对。

**输入 → 输出**：Relations(user_id, follower_id) → (user1_id, user2_id) 中共同关注者最多的所有配对，user1_id < user2_id

**该题只在 `spark_SQL例题.md` §80 中**，无独立 .sql 文件。

```sparksql
use mydb;
WITH Relations AS (
    SELECT 1 AS user_id, 3 AS follower_id
    UNION ALL SELECT 2, 3
    UNION ALL SELECT 7, 3
    UNION ALL SELECT 1, 4
    UNION ALL SELECT 2, 4
    UNION ALL SELECT 7, 4
    UNION ALL SELECT 1, 5
    UNION ALL SELECT 2, 6
    UNION ALL SELECT 7, 5
)
/*,

-- 思路一：利用集合array_intersect计算交集

    follower_list as (
        select
            user_id,
            collect_set(follower_id) followers
        from Relations
        group by user_id
    )

select
    me user1_id,
    you user2_id
from (
         select
             t1.user_id me,
             t2.user_id you,
             dense_rank() over ( order by size(array_intersect(t1.followers, t2.followers)) desc ) dense_rank_number
         from follower_list t1
                  inner join follower_list t2
                             on size(array_intersect(t1.followers, t2.followers)) > 0 and t1.user_id < t2.user_id
     )
where dense_rank_number = 1;*/

-- 思路二：不依靠集合函数
/*select user1_id,
       user2_id
from (
         select
             t1.user_id as user1_id,
             t2.user_id as user2_id,
             dense_rank() over (order by count(distinct t1.follower_id) desc) common_follow_rn
         from Relations t1
                  inner join Relations t2
                             on t1.user_id < t2.user_id  and t1.follower_id = t2.follower_id
         group by t1.user_id, t2.user_id
     )t3
where common_follow_rn = 1;*/

-- 思路三： 从粉丝关注者的角度聚合存在共同粉丝的用户集合；对每个粉丝关注者角度穷举所有两两匹配的用户对情况；最后计算每个用户对的共同粉丝数量

,follower_groups as (
    select
        follower_id,
        collect_set(t1.user_id) users
    from Relations t1
    group by follower_id
    )
, pair as (
    select
        t1.follower_id,
        t2.user1_id,
        t3.user2_id
    from follower_groups t1
             lateral view explode(t1.users) t2 as user1_id
             lateral view explode(t1.users) t3 as user2_id
    where t2.user1_id < t3.user2_id
)
select
    user1_id,
    user2_id
from (
         select user1_id,
                user2_id,
                common_follower_num,
                dense_rank() over (order by common_follower_num desc) top_num
         from (
                  select
                      user1_id,
                      user2_id,
                      count(distinct follower_id) common_follower_num
                  from pair
                  group by user1_id,user2_id
              ) tt
     )
where top_num = 1;
```


---

## 附录 A · 去重对照表

### A1 判为重复、不再单列的 .sql 文件（14 个）

| 被合并的文件 | 归并到 | 判定依据 |
| --- | --- | --- |
| `2024/11找出连续3条或更多条.sql` | 2025-54 | 同一 LC 601，仅建表与输出写法不同 |
| `2024/27有条件的连续三次.sql` | 2025-54 | 同上，题干逐字为 LC 601 |
| `2024/29换座位.sql` | 2025-58 | 同一 LC 626 |
| `2024/31连续登录.sql` | 2025-46 | 同一 LC 550 |
| `2024/46 经典单调递增.sql` | 2025-24 | 同一 LC 1860 |
| `2024/52 没有被执行的任务.sql` | 2025-13 | 同一 LC 1767 |
| `2024/59 查找每组中的获胜球员（也可以是优秀员工.sql` | 2025-67 | 同一 LC 1194 |
| `2024/60 投票人(川建国支持你).sql` | 2025-50 | 同一 LC 574 |
| `2024/63 连续状态(连续登录改版，多状态).sql` | 2025-70 | 同一 LC 1369 |
| `2024/28获取满足条件的书籍销量.sql` | 2025-06 | 同一 LC 1098，题干与数据相同 |
| `2024/37 乘客乘坐巴士.sql` | 2025-68 | 同一 LC 1204 |
| `2024/50 雇员系列题2.sql` | 2025-20 | 同一 LC 2004 |
| `2025/39 近一次和第一次的比较.sql` | 2025-35 | 题干与数据逐字相同 |
| `2025/27 航班是否满员.sql` | 2024-44 | 题干、示例数据、答案三处全一致，是逐字重复 |

### A2 判为重复、不再单列的 md 小节（12 个）

| md 小节 | 归并到 |
| --- | --- |
| 大数据md §查找互相关注的用户对 | 2024-14 |
| 大数据md §数据的合并 | 2024-21 |
| 大数据md §数据的合并（数据交集） | 2024-23 |
| 大数据md §日平均销售额 | 2024-57 |
| 大数据md §每日每种商品购买清单 | 2024-56 |
| 大数据md §户额度信息 | 2024-33 |
| 大数据md §连续会话(标记累计求和分组) | 2024-40 |
| 大数据md §球员得分分析 | 2024-66 |
| 大数据md §文章主题 | 2024-48 |
| spark md §75 公交车上的乘客数量 | 2026-01 |
| spark md §76 重新排列性别表 | 2026-02 |
| spark md §79 坚定的友谊 | 2025-17 |

### A3 `2024/test.sql` 分块索引（该文件是 2024 年前 10 题的合集）

| 行区间 | 题目 | 编号 |
| --- | --- | --- |
| L1–L106 | 查询连续登陆 3 天以上的用户 | 2024-01 |
| L107–L127 | （变体）连续 4 天登录 | 2024-01 内嵌 |
| L128–L166 | 查询连续登陆最大天数用户 | 2024-02 |
| L167–L206 | 按天合并连续登录区间 | 2024-03 |
| L207–L253 | 求出股票波峰波谷 | 2024-04 |
| L254–L365 | 店铺开业前一次 / 后一次开业日期 | 2024-05 |
| L366–L438 | 同时在线最大人数 | 2024-06 |
| L439–L474 | （变体）每小时同时在线 | 2024-06 内嵌 |
| L475–L525 | 求最小达到某累计金额日期 | 2024-07 |
| L526–L612 | 30 天内退货率 | 2024-08 |
| L613–L682 | 用户收购分析 | 2024-09 |
| L684–L761 | 历史新低的商品 id | 2024-10 |

> **注意**：L475「求最小达到某累计金额日期」与 L526「30 天退货率」**只存在于本文件**，
> `README.md` 列了这两项，但两份 md 与 `SQLPractise/` 下都没有对应文件。

## 附录 B · 变体与同名不同题（保留、不合并）

### B1 相邻变体 / 同源不同问

| 组 | 差异 | 处置 |
| --- | --- | --- |
| 2024-16 ↔ 2024-20 | 都是留存率；16 有 7 日留存三解法，20 无注释 | 均保留 |
| 2025-46 ↔ 2024-64 | 同一 Activity 表；46 出单一比率，64 按安装日期分组 | 均保留 |
| 2024-40 ↔ 2024-65 | 同为连续会话；65 加了「间隔 ≤ 12 小时」 | 均保留 |
| 2024-13 ↔ 2024-17 | 同一 contract 数据；13 判连续缴费，17 建期数维表 | 均保留 |
| 2024-12 ↔ 2024-18 | 同一成绩表；12 炸开、18 还原 | 均保留 |
| 2024-26 ↔ 2025-33 | 同为 json 解析；26 穷举函数族，33 多层炸裂取字段 | 均保留 |
| 2024-33 ↔ 2025-11 | 同一 Users/Transactions；33 出余额，11 判透支 | 均保留 |
| 2024-30 ↔ 2025-51 | 同一 SurveyLog；30 取最高，51 出每题 | 均保留 |
| 2024-32 ↔ 2025-32 | 同为四表订单汇总；2025-32 限定订单数 > 3 | 均保留（已确认） |
| 2025-30 ↔ 2025-31 | 同一排班表；31 多求最大并发与总时长 | 均保留 |
| 2025-20 ↔ 2025-21 | 同一 Candidates；选人规则不同 | 均保留 |
| 2025-14 ↔ 2025-71 | 同一 Friendship/Likes；71 是单用户特例 | 均保留 |
| 2026-04 ↔ 2026-05 | 同一 cultivate_tb；04 数人，05 数人次 | 均保留 |
| 2024-04 ↔ 2026-06 | 同为波峰波谷；06 多股票分区 | 均保留 |
| 2024-08 ↔ 2024-09 | 同一套 tmp_sales 建表；退货率 vs 复购率 | 均保留 |

### B2 同名但完全不同的题（**未**被误合并）

| 名字 | 两条编号 | 实际内容 |
| --- | --- | --- |
| 「发票信息」 | 2024-38 / 2024-47 | 前者 Customers×Contacts 姓名+邮箱双匹配；后者 Products×Purchases 每组最贵 |
| 「相互关注」 | 2024-14 / 2024-62 | 前者基础互关去重；后者共同好友计数 |
| 「连续三次」 | 2025-54 / 2025-43 | 前者 Stadium 日期连续；后者 Logs 同值连续 |

## 附录 C · 待核清单

没有 Spark 执行环境，以下疑点**全部为静态阅读所得**，未经验证，仅供你日后实测时对照。

| 编号 | 疑点 |
| --- | --- |
| 2025-01 | `cross join ... on ...` 的写法在部分 Spark 版本下不被接受，通常要改成 `cross join` + `where` |
| 2025-26 | 得票是浮点数（1/投票数），并列判断若用 `=` 比较浮点可能失效，建议 `rank()` |
| 2025-34 | `percent_rank` 与 `cume_dist` 的边界不同，会改变「前 5%」的成员 |
| 2024-20 | 该文件注释区为空，题干与归类由造数结构推定 |
| 2024-08 | 退货率分母用 `sum(sale_cnt)`，若同一 member+sku+pay_time 有多条退款会重复计入 |
| 2024-36 | 输出末列名为 `salary`，实际是应缴税额 `round(salary*tax,0)`，读结果时极易误会 |
| 2024-39 | 第 57–59 行用 `//` 写注释；Spark SQL / Hive **不认 `//` 注释**，直接执行会报语法错 |
| 2024-51 | 题干要求「最近 5 天内」，但正文没有日期过滤，`pay_date` 未被使用 |
| 2024-61 | 方式 1、方式 2 两个解法整段被 `/* */` 注释，仅方式 3 存活；方式 2 里同样用了 `cross join ... on` |
| 2026-01 | 第 127 行用 `//` 写注释（同 2024-39 的问题） |
| 2026-03 | 活代码 `rec_info_l标签准确率` 是语法错误（缺逗号、混入题名）；正确写法被注释在文末 |
