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
