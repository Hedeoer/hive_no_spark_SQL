
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






