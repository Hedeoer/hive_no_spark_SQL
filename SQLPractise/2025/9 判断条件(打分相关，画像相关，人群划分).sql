
/*
表 `Variables`:
```
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| name        | varchar |
| value       | int     |
+-------------+---------+
```
在 SQL 中，`name` 是该表主键。
该表包含了存储的变量及其对应的值。

表 `Expressions`:
```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| left_operand  | varchar |
| operator      | enum    |
| right_operand | varchar |
+---------------+---------+
```
在 SQL 中，`(left_operand, operator, right_operand)` 是该表主键。
该表包含了需要计算的布尔表达式。
`operator` 是枚举类型，取值于(`'<', '>', '=')`
`left_operand` 和 `right_operand` 的值保证存在于 `Variables` 表单中。

计算表 `Expressions` 中的布尔表达式。
返回的结果表 无顺序要求。
结果格式如下例所示。

示例 1:

输入:
`Variables` 表:
```
+------+-------+
| name | value |
+------+-------+
| x    | 66    |
| y    | 77    |
+------+-------+
```
`Expressions` 表:
```
+--------------+----------+---------------+
| left_operand | operator | right_operand |
+--------------+----------+---------------+
| x            | >        | y             |
| x            | <        | y             |
| x            | =        | y             |
| y            | >        | x             |
| y            | <        | x             |
| x            | =        | x             |
+--------------+----------+---------------+
```
输出:
```
+--------------+----------+---------------+-------+
| left_operand | operator | right_operand | value |
+--------------+----------+---------------+-------+
| x            | >        | y             | false |
| x            | <        | y             | true  |
| x            | =        | y             | false |
| y            | >        | x             | true  |
| y            | <        | x             | false |
| x            | =        | x             | true  |
+--------------+----------+---------------+-------+
```
解释:
如上所示，你需要通过使用 `Variables` 表来找到 `Expressions` 表中的每一个布尔表达式的值。

*/

WITH
-- 1. 模拟 Variables 表
Variables AS (
    SELECT 'x' AS name, 66 AS value UNION ALL
    SELECT 'y', 77
),

-- 2. 模拟 Expressions 表
Expressions AS (
    SELECT 'x' AS left_operand, '>' AS operator, 'y' AS right_operand
    UNION ALL
    SELECT 'x', '<', 'y' UNION ALL
    SELECT 'x', '=', 'y' UNION ALL
    SELECT 'y', '>', 'x' UNION ALL
    SELECT 'y', '<', 'x' UNION ALL
    SELECT 'x', '=', 'x'
)
select
    left_operand,
    operator,
    right_operand,
    -- 嵌套case 语句来计算布尔表达式的值
    case operator
        when '>' then case when left_value > right_value then 'true' else 'false' end
        when '<' then case when left_value < right_value then 'true' else 'false' end
        when '=' then case when left_value = right_value then 'true' else 'false' end
        end as value
from (
         -- 将 Expressions 表中的操作数与 Variables 表中的值进行关联获取变量的值
         select t1.left_operand,
                t1.operator,
                t1.right_operand,
                t2.value left_value,
                t3.value right_value
         from Expressions t1
                  -- 左连接 Variables 表两次,Variables变量唯一，不会导致数据膨胀
                  left join Variables t2
                            on t1.left_operand = t2.name
                  left join Variables t3
                            on t1.right_operand = t3.name
     ) t4;
