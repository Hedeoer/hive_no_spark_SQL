/*

# 题目40 前三名酒庄 (dt = '2024-12-27')

表: Wineries
+-----------------------+
| Column Name | Type |
+-----------------------+
| id | int |
| country | varchar |
| points | int |
| winery | varchar |
+-----------------------+
id 是该张表具有唯一值的列。
这张表包含 id, country, points和 winery。
编写一个解决方案，根据每家酒庄的 总分 找出 每个国家 的前三名酒庄。如果有 多个酒庄 的总分 相同，则
按 winery名称升序排列。如果没有分数排在第二的酒庄，则输出‘No Second Winery"，如果没有分数排在
第三的酒庄，则输出‘No Third Winery”。
返回结果表按 country 升序 排列。
结果表格式如下例所示。

示例 1:
输入:
Wineries table:
+-----+----------+--------+------------------+
| id  | country  | points | winery           |
+-----+----------+--------+------------------+
| 103 | Australia | 84    | WhisperingPines  |
| 737 | Australia | 85    | GrapesGalore    |
| 848 | Australia | 100   | HarmonyHill     |
| 222 | Hungary   | 60    | MoonlitCellars   |
| 116 | USA       | 47    | RoyalVines      |
| 124 | USA       | 45    | EaglesNest      |
| 648 | India     | 69    | SunsetVines     |
| 894 | USA       | 39    | RoyalVines      |
| 677 | USA       | 9     | PacificCrest    |
+-----+----------+--------+------------------+

输出:
+----------+------------+--------------+-------------+
| country  | top_winery | second_winery | third_winery |
+----------+------------+--------------+-------------+
| Australia | HarmonyHill (100) | GrapesGalore (85) | WhisperingPines (84) |
| Hungary  | MoonlitCellars (60) | No second winery | No third winery |
| India    | SunsetVines (69) | No second winery | No third winery |
| USA      | RoyalVines (86) | EaglesNest (45) | PacificCrest (9) |
+----------+------------+--------------+-------------+

解释:
对于 Australia
- HarmonyHill 酒庄获得了 Australia 的最高分数, 为 100 分。
- GrapesGalore 酒庄总共获得 85 分, 位列 Australia 的第二位。
- WhisperingPines 酒庄总共获得 84 分, 位列 Australia 的第三位。
对于 Hungary
- MoonlitCellars 是唯一的酒庄, 获得 60 分, 自动成为最高分数的酒庄, 没有第二或第三名酒庄。
对于 India
- SunsetVines 是唯一的酒庄, 获得 69 分, 成为最高的酒庄, 没有第二或第三名酒庄。
对于 USA
- RoyalVines wines 累计了总分 47 + 39 = 86 分, 占据了 USA 的最高位置。
- EaglesNest 总共获得 45 分, 位列 USA 的第二高位置。
- PacificCrest 累计了 9 分, 位列 USA 的第三高位置。
输出表按国家名字母升序排列。




**表数据示例：**

*/

WITH Wineries AS (
  SELECT 103 AS id, 'Australia' AS country, 84 AS points, 'WhisperingPines' AS winery UNION ALL
  SELECT 737, 'Australia', 85, 'GrapesGalore' UNION ALL
  SELECT 848, 'Australia', 100, 'HarmonyHill' UNION ALL
  SELECT 222, 'Hungary', 60, 'MoonlitCellars' UNION ALL
  SELECT 116, 'USA', 47, 'RoyalVines' UNION ALL
  SELECT 124, 'USA', 45, 'EaglesNest' UNION ALL
  SELECT 648, 'India', 69, 'SunsetVines' UNION ALL
  SELECT 894, 'USA', 39, 'RoyalVines' UNION ALL
  SELECT 677, 'USA', 9, 'PacificCrest'
),
winer_rank AS (
    SELECT
        country,
        winery,
        SUM(points) AS points,
        ROW_NUMBER() OVER(PARTITION BY country ORDER BY SUM(points) DESC, winery ASC) AS rn
    FROM Wineries
    GROUP BY country, winery
),
dim_country AS (
    SELECT DISTINCT
        country
    FROM Wineries
)
SELECT
    t1.country,
    COALESCE(MAX(CASE WHEN t2.rn = 1 THEN CONCAT(t2.winery,' (',t2.points,')') END), 'No first winery') AS top_winery,
    COALESCE(MAX(CASE WHEN t2.rn = 2 THEN CONCAT(t2.winery,' (',t2.points,')') END), 'No second winery') AS second_winery,
    COALESCE(MAX(CASE WHEN t2.rn = 3 THEN CONCAT(t2.winery,' (',t2.points,')') END), 'No third winery') AS third_winery
FROM dim_country t1
LEFT JOIN winer_rank t2
ON t1.country = t2.country
GROUP BY t1.country
ORDER BY t1.country;

-- 方式二
WITH Wineries AS (
  SELECT 103 AS id, 'Australia' AS country, 84 AS points, 'WhisperingPines' AS winery UNION ALL
  SELECT 737, 'Australia', 85, 'GrapesGalore' UNION ALL
  SELECT 848, 'Australia', 100, 'HarmonyHill' UNION ALL
  SELECT 222, 'Hungary', 60, 'MoonlitCellars' UNION ALL
  SELECT 116, 'USA', 47, 'RoyalVines' UNION ALL
  SELECT 124, 'USA', 45, 'EaglesNest' UNION ALL
  SELECT 648, 'India', 69, 'SunsetVines' UNION ALL
  SELECT 894, 'USA', 39, 'RoyalVines' UNION ALL
  SELECT 677, 'USA', 9, 'PacificCrest'
),
winer_rank AS (
    SELECT
        country,
        winery,
        SUM(points) AS points,
        ROW_NUMBER() OVER(PARTITION BY country ORDER BY SUM(points) DESC, winery ASC) AS rn
    FROM Wineries
    GROUP BY country, winery
)
select
    country,
    coalesce(max(case when rn = 1 then CONCAT(winery,' (',points,')')  end ), 'No first winery') top_winery,
    coalesce(max(case when rn = 2 then CONCAT(winery,' (',points,')') end ), 'No second winery' ) second_winery,
    coalesce(max(case when rn = 3 then CONCAT(winery,' (',points,')') end ),'No third winery') third_winery
from winer_rank
where rn < 4
group by country
order by country;