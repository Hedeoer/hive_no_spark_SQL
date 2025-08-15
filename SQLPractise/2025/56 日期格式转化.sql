/*
当前表 `a` `date_id` 字段样式如下，请获取后面日期（`2025-3-7~2025-3-1` 取`2025-3-1`）并修改成`yyyymmdd`样式，如 `20250301`

`2025-3-7~2025-3-1`
`2025-4-22~2025-4-9`
`2025-5-13~2025-4-23`
`2025-11-20~2025-11-12`
*/

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