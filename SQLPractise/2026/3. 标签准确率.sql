

/*
某产品2022年2月8日系统推荐内容给部分用户的数据，以及用户信息和对推荐内容的评分交叉表部分数据如下：

【表1：推荐内容表 recommend_tb】
字段：rec_id-推荐信息id，rec_info_l-推荐信息标签，rec_user-推荐目标用户id，rec_time-推荐时间
数据如下：
1 健身 101 2022-02-08 07:23:15
2 美妆 102 2022-02-08 07:24:15
3 体育 103 2022-02-08 07:25:15
4 美妆 103 2022-02-08 07:26:15
5 搞笑 104 2022-02-08 07:27:15
6 体育 104 2022-02-08 07:28:15
7 体育 105 2022-02-08 07:29:15
8 影视 106 2022-02-08 07:30:15

【表2：用户信息及评分交叉表 user_action_tb】
字段：user_id-用户id，hobby_l-用户爱好标签，score-综合评分
注：该表score为对所有推荐给该用户的内容的综合评分。
数据如下：
101 健身 88
102 影视 81
103 美妆 78
104 健身 68
105 体育 90
106 影视 82

【问题】
请计算内容推荐的准确用户的平均评分？（结果保留3位小数）

【注】
准确的定义：推荐的内容标签与用户爱好标签一致；如被多次推荐给同一用户，一次及以上准确都记为准确。
如果同一用户被推荐同一个内容标签的话，计算的时候只算一次。

【示例数据结果如下】
avg_score
84.500

解释：一共推荐8条内容，其中推荐给101、103、105、106四位用户的内容准确。
四位用户的评分分别是88、78、90、82，故平均评分= (88+78+90+82) / 4 = 84.500
*/

WITH recommend_tb AS (
    SELECT 1 AS rec_id, '健身' AS rec_info_l, 101 AS rec_user, '2022-02-08 07:23:15' AS rec_time UNION ALL
    SELECT 2 AS rec_id, '美妆' AS rec_info_l, 102 AS rec_user, '2022-02-08 07:24:15' AS rec_time UNION ALL
    SELECT 3 AS rec_id, '体育' AS rec_info_l, 103 AS rec_user, '2022-02-08 07:25:15' AS rec_time UNION ALL
    SELECT 4 AS rec_id, '美妆' AS rec_info_l, 103 AS rec_user, '2022-02-08 07:26:15' AS rec_time UNION ALL
    SELECT 5 AS rec_id, '搞笑' AS rec_info_l, 104 AS rec_user, '2022-02-08 07:27:15' AS rec_time UNION ALL
    SELECT 6 AS rec_id, '体育' AS rec_info_l, 104 AS rec_user, '2022-02-08 07:28:15' AS rec_time UNION ALL
    SELECT 7 AS rec_id, '体育' AS rec_info_l, 105 AS rec_user, '2022-02-08 07:29:15' AS rec_time UNION ALL
    SELECT 8 AS rec_id, '影视' AS rec_info_l, 106 AS rec_user, '2022-02-08 07:30:15' AS rec_time
),
     user_action_tb AS (
         SELECT 101 AS user_id, '健身' AS hobby_l, 88 AS score UNION ALL
         SELECT 102 AS user_id, '影视' AS hobby_l, 81 AS score UNION ALL
         SELECT 103 AS user_id, '美妆' AS hobby_l, 78 AS score UNION ALL
         SELECT 104 AS user_id, '健身' AS hobby_l, 68 AS score UNION ALL
         SELECT 105 AS user_id, '体育' AS hobby_l, 90 AS score UNION ALL
         SELECT 106 AS user_id, '影视' AS hobby_l, 82 AS score
     )
-- ==========================================
-- 请在此处往下编写你的解答SQL
-- 下方为参考答案，为防止剧透你可以先遮挡下方代码
-- ==========================================

select
    cast(avg(t3.score) as decimal(10,3)) as avg_score
from (
         select
             rec_user,
             rec_info_l标签准确率
         from recommend_tb t1
         group by rec_user,rec_info_l
     ) t2
         inner join user_action_tb t3
                    on t2.rec_user = t3.user_id and t2.rec_info_l = t3.hobby_l

/*
SELECT
    -- 使用 CAST AS DECIMAL(10,3) 可以严格保证输出带有3位小数(如 84.500)
    CAST(AVG(score) AS DECIMAL(10,3)) AS avg_score
FROM (
         -- 核心逻辑：找到被准确推荐的用户（利用 distinct 去重，满足“同一用户算一次”的要求）
         SELECT DISTINCT
             u.user_id,
             u.score
         FROM recommend_tb r
                  JOIN user_action_tb u
                       ON r.rec_user = u.user_id
                           AND r.rec_info_l = u.hobby_l
     ) t;*/
