
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
