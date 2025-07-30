
/*
表: `Terms`
```
+--------+--------+
| Column Name | Type |
+--------+--------+
| power  | int    |
| factor | int    |
+--------+--------+
```
`power` 是该表具有唯一值的列。
该表的每一行包含关于方程的一项的信息。
`power` 是范围为 `[0, 100]` 的整数。
`factor` 是范围为 `[-100,100]` 的整数，且不能为零。
你有一个非常强大的程序，可以解决世界上任何单变量的方程。传递给程序的方程必须格式化如下:
左边 (LHS) 应该包含所有的术语。
右边 (RHS) 应该是零。
LHS 的每一项应遵循 `"<sign><fact>X^<pow>"` 的格式, 其中:`<sign>` 是 `"+"` 或者 `"-"`。
`<fact>` 是 `factor` 的 绝对值。
`<pow>` 是 `power` 的值。
如果幂是 `1`，不要加上 `^<pow>`。例如, 如果 `power = 1` 并且 `factor = 3`, 将有 `"+3X"`。
如果幂是 `0`，不要加上 `"X"` 和 `^<pow>`。例如, 如果 `power = 0` 并且 `factor = -3`, 将有 `"-3"`。
LHS 中的幂应该按 降序排序。
编写一个解决方案来构建方程。
结果格式如下所示。

示例 1:

输入:
`Terms` 表:
```
+-------+--------+
| power | factor |
+-------+--------+
| 2     | 1      |
| 1     | -4     |
| 0     | 2      |
+-------+--------+
```
输出:
```
+----------------+
| equation       |
+----------------+
| +1X^2-4X+2=0   |
+----------------+
```
示例 2:

输入:
`Terms` 表:
```
+-------+--------+
| power | factor |
+-------+--------+
| 4     | -4     |
| 2     | 1      |
| 1     | -1     |
+-------+--------+
```
输出:
```
+------------------+
| equation         |
+------------------+
| -4X^4+1X^2-1X=0  |
+------------------+
```

*/

-- 方式1 使用 CONCAT_WS() 和 COLLECT_LIST()
WITH
-- 1. 模拟 Terms 表 (使用示例1的数据)
Terms AS (
    SELECT 2 AS power, 1 AS factor UNION ALL
    SELECT 1, -4 UNION ALL
    SELECT 0, 2
)
select
    concat(concat_ws('',collect_list(term)), '=0') as equation
from (
         select power,
                factor,
                concat(
                        if(factor > 0, '+', '-'),
                        case when power = 0 then abs(factor)
                             when power = 1 then concat(abs(factor),'X')
                             else concat(abs(factor),'X^',power) end
                ) as term

         from Terms t1
         -- 全局排序
         order by power desc
     ) t2;


-- 方式2 使用窗口函数 COLLECT_LIST() OVER()
WITH
-- 1. 模拟 Terms 表
Terms AS (
    SELECT 2 AS power, 1 AS factor UNION ALL
    SELECT 1, -4 UNION ALL
    SELECT 0, 2
),

-- 2. 格式化每一项并使用窗口函数
CumulativeList AS (
    SELECT
        -- 使用窗口函数生成一个累积的、有序的列表
        collect_list(
                CONCAT(
                        CASE WHEN factor > 0 THEN '+' ELSE '-' END,
                        ABS(factor),
                        CASE
                            WHEN power = 0 THEN ''
                            WHEN power = 1 THEN 'X'
                            ELSE CONCAT('X^', power)
                            END
                )
        ) OVER (ORDER BY power DESC) AS term_list,
        -- 使用 row_number 标记最后一行
        row_number() OVER (ORDER BY power ASC) as rn_asc
    FROM
        Terms
)

-- 3. 筛选出最后一行并拼接
SELECT
    CONCAT(concat_ws('', term_list), '=0') AS equation
FROM
    CumulativeList
WHERE
    -- 最后一行 (按 power 升序的第一行) 包含了完整的列表
    rn_asc = 1;





