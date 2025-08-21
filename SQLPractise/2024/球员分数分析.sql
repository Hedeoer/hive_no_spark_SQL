

-- 需求描述:
-- 对球员的的各场得分做一个分数段的区分，比如：
-- 球员张三，A场次得分 123，则需要得到 1 -100分段得分为6，101 - 200分段得分100，201 - 300分段得分17.依次类推。
WITH data AS (
    SELECT '张三' AS `palyer`, 1 AS `collector`, 30 AS `score`, '北京' AS `game_room`, '2022/2/2' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 2 AS `collector`, 28 AS `score`, '上海' AS `game_room`, '2022/2/7' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 3 AS `collector`, 36 AS `score`, '广州' AS `game_room`, '2022/2/12' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 4 AS `collector`, 123 AS `score`, '深圳' AS `game_room`, '2022/2/17' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 5 AS `collector`, 19 AS `score`, '南京' AS `game_room`, '2022/2/22' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 6 AS `collector`, 202 AS `score`, '武汉' AS `game_room`, '2022/2/27' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 7 AS `collector`, 354 AS `score`, '成都' AS `game_room`, '2022/3/4' AS `game_date` UNION ALL
    SELECT '张三' AS `palyer`, 8 AS `collector`, 23 AS `score`, '厦门' AS `game_room`, '2022/3/9' AS `game_date`
)


select
    *
from (select palyer,
             collector,
             score,
             game_room,
             game_date,
             -- 计算分区区间
             concat(score_group * 100 - 100 + 1, "-", score_group * 100) as                                                       score_range,
             -- 对相同分数组的行进行累加，得到当前分数的累计值
             sum(pos)
                 over (partition by palyer,game_date, game_room, collector, score_group order by game_date, score_group)          score_current,
             row_number() over (partition by palyer,game_date, game_room, collector, score_group order by game_date, score_group) rn
      from (select palyer,
                   collector,
                   score,
                   game_room,
                   game_date,
                   -- 对分数进行分组，每组100个，比如当前累计分数为54，计算后得到 score_group = 1;分配的组为1 -100；如果累计的分数为145，计算后得到 score_group = 2,分配的组为101 - 200
                   ceil(count(pos) over ( order by collector, game_date, pos) / 100) as score_group,
                   1                                                                 as pos
            from data
                     lateral view posexplode(split(repeat(' ', score - 1), '\\(?|$\\)')) temp as pos, val) t1)t2
-- 相同分数组的行，score_current是相同的，取第一条即可
where rn = 1;



-- 详细分析查看语雀文档： https://www.yuque.com/aoyixiong/nwfsd7/hk1v77258gg7hnqw 中的11球员得分分析案例

select concat_ws();