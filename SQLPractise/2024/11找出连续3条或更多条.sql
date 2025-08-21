
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



