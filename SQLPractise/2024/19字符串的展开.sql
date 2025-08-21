

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