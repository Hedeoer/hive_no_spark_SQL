/*
```
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| sample_id    | int     |
| dna_sequence | varchar |
| species      | varchar |
+--------------+---------+
```
`sample_id` 是这张表的唯一主键。
每一行包含一个 DNA 序列——以字符 (A, T, G, C) 组成的字符串表示以及它所采集自的物种。
生物学家正在研究 DNA 序列中的基本模式。编写一个解决方案以识别别具有以下模式的 `sample_id`:

*   以 `ATG` 开头的序列 (一个常见的 起始密码子)
*   以 `TAA`, `TAG` 或 `TGA` 结尾的序列 (终止密码子)
*   包含基序 `ATAT` 的序列 (一个简单重复模式)
*   有 至少 `3` 个连续 `G` 的序列 (如 `GGG` 或 `GGGG`)

返回结果表以 `sample_id` 升序 排序。
结果格式如下所示。

示例:

输入:
`Samples` 表:
```
+-----------+-------------------+-----------+
| sample_id | dna_sequence      | species   |
+-----------+-------------------+-----------+
| 1         | ATGCTAGCTAGCTAA   | Human     |
| 2         | GGGTCAATCATC      | Human     |
| 3         | ATATATCGTAGCTA    | Human     |
| 4         | ATGGGGTCAТСАТАА   | Mouse     |
| 5         | TCAGTCAGTCAG      | Mouse     |
| 6         | ATATCGCGCTAG      | Zebrafish |
| 7         | CGTATGCGTGTA      | Zebrafish |
+-----------+-------------------+-----------+
```
输出:
```
+-----------+-------------------+-----------+-----------+----------+----------+----------+
| sample_id | dna_sequence      | species   | has_start | has_stop | has_atat | has_ggg  |
+-----------+-------------------+-----------+-----------+----------+----------+----------+
| 1         | ATGCTAGCTAGCTAA   | Human     | 1         | 1        | 0        | 0        |
| 2         | GGGTCAATCATC      | Human     | 0         | 0        | 0        | 1        |
| 3         | ATATATCGTAGCTA    | Human     | 0         | 0        | 1        | 0        |
| 4         | ATGGGGTCAТСАТАА   | Mouse     | 1         | 1        | 0        | 1        |
| 5         | TCAGTCAGTCAG      | Mouse     | 0         | 0        | 0        | 0        |
| 6         | ATATCGCGCTAG      | Zebrafish | 0         | 1        | 1        | 0        |
| 7         | CGTATGCGTGTA      | Zebrafish | 0         | 0        | 0        | 0        |
+-----------+-------------------+-----------+-----------+----------+----------+----------+
```
解释:
*   样本 1 (ATGCTAGCTAGCTAA) : 以 ATG 开头 (has_start = 1)
    以 TAA 结尾 (has_stop = 1)
    不包含 ATAT (has_atat = 0)
    不包含至少 3 个连续 'G' (has_ggg = 0)
*   样本 2 (GGGTCAATCATC) : 不以 ATG 开头 (has_start = 0)
    不以 TAA, TAG 或 TGA 结尾 (has_stop = 0)
    不包含 ATAT (has_atat = 0)
    包含 GGG (has_ggg = 1)
*   样本 3 (ATATATCGTAGCTA) : 不以 ATG 开头 (has_start = 0)
    不以 TAA, TAG 或 TGA 结尾 (has_stop = 0)
    包含 ATAT (has_atat = 1)
    不包含至少 3 个连续 'G' (has_ggg = 0)
*   样本 4 (ATGGGGTCAТСАТАА) : 以 ATG 开头 (has_start = 1)
    以 TAA 结尾 (has_stop = 1)
    不包含 ATAT (has_atat = 0)
    包含 GGGG (has_ggg = 1)
*   样本 5 (TCAGTCAGTCAG) : 不匹配任何模式 (所有字段 = 0)
*   样本 6 (ATATCGCGCTAG) : 不以 ATG 开头 (has_start = 0)
    以 TAG 结尾 (has_stop = 1)
    包含 ATAT (has_atat = 1)
    不包含至少 3 个连续 'G' (has_ggg = 0)
*   样本 7 (CGTATGCGTGTA) : 不以 ATG 开头 (has_start = 0)
    不以 TAA, TAG 或 TGA 结尾 (has_stop = 0)
    不包含 ATAT (has_atat = 0)
    不包含至少 3 个连续 'G' (has_ggg = 0)

注意:
结果以 sample_id 升序排序
对于每个模式, 1 表示该模式存在, 0 表示不存在


*/


WITH
-- 1. 模拟 Samples 表
Samples AS (SELECT 1 AS sample_id, 'ATGCTAGCTAGCTAA' AS dna_sequence, 'Human' AS species
            UNION ALL
            SELECT 2, 'GGGTCAATCATC', 'Human'
            UNION ALL
            SELECT 3, 'ATATATCGTAGCTA', 'Human'
            UNION ALL
            SELECT 4, 'ATGGGGTCAТСАТАА', 'Mouse'
            UNION ALL
            SELECT 5, 'TCAGTCAGTCAG', 'Mouse'
            UNION ALL
            SELECT 6, 'ATATCGCGCTAG', 'Zebrafish'
            UNION ALL
            SELECT 7, 'CGTATGCGTGTA', 'Zebrafish')
-- 场景1
select sample_id,
       dna_sequence,
       species,
       case when dna_sequence regexp '^ATG' then 1 else 0 end           as has_start,
       case when dna_sequence regexp 'TAA$|TAG$|TGA$' then 1 else 0 end as has_stop,
       case when dna_sequence regexp 'ATAT' then 1 else 0 end           as has_atat,
       case when dna_sequence regexp 'G{3,}' then 1 else 0 end          as has_ggg
from Samples t1
order by sample_id;

/* 结果：
| sample_id | dna_sequence   | species   | has_start | has_stop | has_atat | has_ggg |
|:----------|:---------------|:----------|:----------|:---------|:---------|:--------|
| 1         | ATGCTAGCTAA    | Human     | 1         | 1        | 0        | 0       |
| 2         | GGGTCAATCATC   | Human     | 0         | 0        | 0        | 1       |
| 3         | ATATATCGTAGCTA | Human     | 0         | 0        | 1        | 0       |
| 4         | ATGGGTCATCATA  | Mouse     | 1         | 0        | 0        | 1       |
| 5         | TCAGTCAGTCAG   | Mouse     | 0         | 0        | 0        | 0       |
| 6         | ATATCGCGCTAG   | Zebrafish | 0         | 1        | 1        | 0       |
| 7         | CGTATGCGTGTA   | Zebrafish | 0         | 0        | 0        | 0       |
*/


-- 场景2 ， 查询每个dns序列符合特定序列的次数
WITH
-- 1. 模拟 Samples 表
Samples AS (
    SELECT 1 AS sample_id, 'ATGCTAGCTAGCTAA' AS dna_sequence, 'Human' AS species UNION ALL
    SELECT 2, 'GGGTCAATCATC',    'Human'     UNION ALL
    SELECT 3, 'ATATATCGTAGCTA',  'Human'     UNION ALL
    SELECT 4, 'ATGGGGTCAТСАТАА', 'Mouse'     UNION ALL
    SELECT 5, 'TCAGTCAGTCAG',    'Mouse'     UNION ALL
    SELECT 6, 'ATATCGCGCTAG',    'Zebrafish' UNION ALL
    -- 添加一个用于演示重叠计数的例子
    SELECT 8, 'GGGATATATGGG',    'Test'
),
explode_sequence as (
    select t1.sample_id,
           t1.dna_sequence,
           t1.species,
           t2.pos
    -- 使用 posexplode 和 split 函数将 dna_sequence 分割成单个字符,取每个字符的位置
    from Samples t1
    lateral view posexplode(split(space(length(t1.dna_sequence) - 1), ' ')) t2 AS pos, val
    )
select t1.sample_id,
       t1.dna_sequence,
       t1.species,
       -- 使用 substring 函数和条件聚合来计算每个模式的出现次数
       sum(case when substring(t1.dna_sequence,t2.pos,3) = 'ATG' and t2.pos = 0 then 1 else 0 end)           as start_ATG_count,
       sum(case when substring(t1.dna_sequence,t2.pos,3) in ('TAA', 'TAG', 'TGA') and t2.pos = length(t1.dna_sequence) - 2 then 1 else 0 end) as stop_count,
       sum(case when substring(t1.dna_sequence,t2.pos,4) = 'ATAT' then 1 else 0 end)           as atat_count,
       sum(case when substring(t1.dna_sequence,t2.pos,3) = 'GGG' then 1 else 0 end)          as ggg_count

from Samples t1
         left join explode_sequence t2
                   on t1.sample_id  = t2.sample_id
group by  t1.sample_id,
          t1.dna_sequence,
          t1.species
order by t1.sample_id;

/*结果
| sample_id | dna_sequence   | species   | start_count | stop_count | atat_count | ggg_count |
|:----------|:---------------|:----------|:------------|:-----------|:-----------|:----------|
| 1         | ATGCTAGCTAA    | Human     | 1           | 1          | 1          | 0         |
| 2         | GGGTCAATCATC   | Human     | 0           | 0          | 0          | 2         |
| 3         | ATATATCGTAGCTA | Human     | 0           | 0          | 3          | 0         |
| 4         | ATGGGTCATCATA  | Mouse     | 1           | 0          | 0          | 2         |
| 5         | TCAGTCAGTCAG   | Mouse     | 0           | 0          | 0          | 0         |
| 6         | ATATGCGGCTAG   | Zebrafish | 0           | 1          | 2          | 0         |
| 8         | GGGATATATGGG   | Test      | 0           | 0          | 2          | 3         |
*/
