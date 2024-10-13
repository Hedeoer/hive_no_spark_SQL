
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