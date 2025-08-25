
/*
有如下hive表结构：
A表 a1、a2、a3、a4有4个字段

B表 b1、b2 b3 b4 有3个字段

C表c1 c2 c3 c4 有4个字段

A表a1是关联B表b1主键，a2是关联C表c1主键，查询A表不在B表和C表里面的数据

其中A表千万级 B表C表千级

考虑效率，写出 spark sql
*/

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