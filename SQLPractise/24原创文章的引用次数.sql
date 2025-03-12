
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

