/*
`Numbers` 表:
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| num         | int     |
| frequency   | int     |
+-------------+---------+
```
`num` 是这张表的主键(具有唯一值的列)。
这张表的每一行表示某个数字在该数据库中的出现频率。

中位数 是将数据样本中半数较高值和半数较低值分隔开的值。编写解决方案，解压 `Numbers` 表，报告数据库中所有数字的 中位数 。结果四舍五入至 一位小数 。
返回结果如下例所示。

示例 1:
输入:
`Numbers` 表:
```
+-----+-----------+
| num | frequency |
+-----+-----------+
| 0   | 7         |
| 1   | 1         |
| 2   | 3         |
| 3   | 1         |
+-----+-----------+
```
输出:
```
+--------+
| median |
+--------+
| 0.0    |
+--------+
```
解释:
如果解压这个 `Numbers` 表,可以得到 `[0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 3]` , 所以中位数是 `(0 + 0) / 2 = 0`。

*/
WITH
-- 1. 模拟 Numbers 表
Numbers AS (
    SELECT 0 AS num, 7 AS frequency UNION ALL
    SELECT 1, 1 UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 3, 1
)
/*
select
    t2.num
from (
         select
             t1.num,
             row_number() over (order by t1.num) rn,
             count(1) over(partition by t1.num) partitial_number
         from Numbers t1
                  lateral view posexplode(split(repeat(space(1), t1.frequency - 1), ' ')) t2 as pos, value
     ) t2
where rn >= partitial_number / 2.0 and rn <= (partitial_number + 1) / 2.0
group by t2.num
*/
select
    avg(num)
from (
         select
             t1.num,
             t1.frequency,
             sum(frequency) over () total_num,
             sum(frequency) over(order by num) rn1,
             sum(frequency) over(order by num desc) rn2

         from Numbers  t1
     ) t2
where rn1 >= total_num / 2 and rn2 >= total_num / 2