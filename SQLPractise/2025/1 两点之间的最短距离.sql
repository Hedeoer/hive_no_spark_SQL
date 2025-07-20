
/*
两点之间直线最短

`Point2D` 表:
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| x           | int  |
| y           | int  |
+-------------+------+
```
(x, y) 是该表的主键列(具有唯一值的列的组合)。
这张表的每一行表示 x-y 平面上的一个点的位置
p1(x1, y1) 和 p2(x2, y2) 这两点之间的距离是 `sqrt((x2 - x1)2 + (y2 - y1)2)` 。
编写解决方案，报告 `Point2D` 表中任意两点之间的最短距离。保留 `2` 位小数。
返回结果格式如下例所示。

示例 1:

输入:
`Point2D table`:
```
+----+----+
| x  | y  |
+----+----+
| -1 | -1 |
| 0  | 0  |
| -1 | -2 |
+----+----+
```
输出:
```
+-----------+
| shortest  |
+-----------+
| 1.00      |
+-----------+
```
解释: 最短距离是 1.00，从点 (-1, -1) 到点 (-1, -2)。

*/

WITH
-- 1. 模拟 Point2D 表
Point2D AS (
    SELECT -1 as x, -1 as y UNION ALL
    SELECT 0,  0  UNION ALL
    SELECT -1, -2
)
select
    min(distance)
from (
         select
             round(sqrt((pow(t1.x - t2.x,2) + pow(t1.y - t2.y,2)) * 1.0),2) distance
         from Point2D t1
                  cross join Point2D t2
                             on t1.x <> t2.x or t1.y <> t2.y
     ) tt;

