/*
 题目44 降水量

 表: Heights
| Column Name | Type |
| ----------- | ---- |
| id | int |
| height | int |

id 是这张表的主键 (值互不相同的列)，并且这个表有序。
这张表的每一行都包含 id 和 height。
一个地势图由多个连续高度的岛屿组成 沙洲之间 可以捕捉的雨水量。以卡方行列的形 变是为 1 个单位。
以 任何 顺序返回结果表。
结果格式如下所示。

 Example 1:

 输入:
Heights table:
| id | height |
| -- | ------ |
| 1 | 0 |
| 2 | 1 |
| 3 | 0 |
| 4 | 2 |
| 5 | 1 |
| 6 | 0 |
| 7 | 1 |
| 8 | 3 |
| 9 | 2 |
| 10 | 1 |
| 11 | 2 |
| 12 | 1 |

 输出:
| total_trapped_water |
| ------------------ |
| 6 |

```sql
WITH Heights AS (
  SELECT 1 AS id, 0 AS height UNION ALL
  SELECT 2, 1 UNION ALL
  SELECT 3, 0 UNION ALL
  SELECT 4, 2 UNION ALL
  SELECT 5, 1 UNION ALL
  SELECT 6, 0 UNION ALL
  SELECT 7, 1 UNION ALL
  SELECT 8, 3 UNION ALL
  SELECT 9, 2 UNION ALL
  SELECT 10, 1 UNION ALL
  SELECT 11, 2 UNION ALL
  SELECT 12, 1
)
```*/

// 水会填充到左右两边最高点中较低的那个高度 LEAST(left_max, right_max)
// 减去当前高度 - 因为已被地形占据的部分不能储水。least(left_max,right_max) - height)
// sum(if(,0,))：如果计算结果为负，则该位置不能蓄水，返回0
WITH Heights AS (
  SELECT 1 AS id, 0 AS height UNION ALL
  SELECT 2, 1 UNION ALL
  SELECT 3, 0 UNION ALL
  SELECT 4, 2 UNION ALL
  SELECT 5, 1 UNION ALL
  SELECT 6, 0 UNION ALL
  SELECT 7, 1 UNION ALL
  SELECT 8, 3 UNION ALL
  SELECT 9, 2 UNION ALL
  SELECT 10, 1 UNION ALL
  SELECT 11, 2 UNION ALL
  SELECT 12, 1
)
select
    -- LEAST 函数返回所有输入表达式中的最小值。该函数可以接受两个或多个参数，并在它们之间进行比较，找出最小的一个。
    sum(if(least(left_max,right_max) - height < 0, 0,least(left_max,right_max) - height)) total_trapped_water
from (
select id,
       height,
       coalesce(max(height) over(order by id rows between unbounded preceding and 1 preceding),0) left_max,
       coalesce(max(height) over(order by id rows between 1 following and unbounded following ),0) right_max
from Heights
     ) t1;

/*
位置 1 (height=0)：左侧没有柱子，所以左侧最大高度是0；右侧最大高度是3；较小值为0；0-0=0，不能捕获水。
位置 2 (height=1)：左侧最大高度是0；右侧最大高度是3；较小值为0；0-1=-1，不能捕获水。
位置 3 (height=0)：左侧最大高度是1；右侧最大高度是3；较小值为1；1-0=1，能捕获1单位的水。
位置 4 (height=2)：左侧最大高度是1；右侧最大高度是3；较小值为1；1-2=-1，不能捕获水。
位置 5 (height=1)：左侧最大高度是2；右侧最大高度是3；较小值为2；2-1=1，能捕获1单位的水。
位置 6 (height=0)：左侧最大高度是2；右侧最大高度是3；较小值为2；2-0=2，能捕获2单位的水。
位置 7 (height=1)：左侧最大高度是2；右侧最大高度是3；较小值为2；2-1=1，能捕获1单位的水。
位置 8 (height=3)：左侧最大高度是2；右侧最大高度是2；较小值为2；2-3=-1，不能捕获水。
位置 9 (height=2)：左侧最大高度是3；右侧最大高度是2；较小值为2；2-2=0，不能捕获水。
位置 10 (height=1)：左侧最大高度是3；右侧最大高度是2；较小值为2；2-1=1，能捕获1单位的水。
位置 11 (height=2)：左侧最大高度是3；右侧最大高度是1；较小值为1；1-2=-1，不能捕获水。
位置 12 (height=1)：左侧最大高度是3；右侧没有柱子，所以右侧最大高度是0；较小值为0；0-1=-1，不能捕获水。
*/