
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