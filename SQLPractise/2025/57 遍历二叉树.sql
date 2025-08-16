/*
表: `Tree`
```
+-------------+------+
| Column Name | Type |
+-------------+------+
| id          | int  |
| p_id        | int  |
+-------------+------+
```
id 是该表中具有唯一值的列。
该表的每行包含树中节点的 id 及其父节点的 id 信息。
给定的结构总是一个有效的树。
树中的每个节点可以是以下三种类型之一:
"Leaf": 节点是叶子节点。
"Root": 节点是树的根节点。
"Inner": 节点既不是叶子节点也不是根节点。
编写一个解决方案来报告树中每个节点的类型。
以任意顺序返回结果表。
结果格式如下所示。

示例 1:
输入:
`Tree table`:
```
+----+------+
| id | p_id |
+----+------+
| 1  | null |
| 2  | 1    |
| 3  | 1    |
| 4  | 2    |
| 5  | 2    |
+----+------+
```
输出:
```
+----+-------+
| id | type  |
+----+-------+
| 1  | Root  |
| 2  | Inner |
| 3  | Leaf  |
| 4  | Leaf  |
| 5  | Leaf  |
+----+-------+
```
解释:
节点 1 是根节点, 因为它的父节点为空, 并且它有子节点 2 和 3。
节点 2 是一个内部节点, 因为它有父节点 1 和子节点 4 和 5。
节点 3、4 和 5 是叶子节点, 因为它们有父节点而没有子节点。

示例 2:
输入:
`Tree table`:
```
+----+------+
| id | p_id |
+----+------+
| 1  | null |
+----+------+
```
输出:
```
+----+-------+
| id | type  |
+----+-------+
| 1  | Root  |
+----+-------+
```
解释: 如果树中只有一个节点, 则只需要输出其根属性。
*/
WITH
-- 1. 模拟 Tree 表
Tree AS (
    SELECT 1 AS id, CAST(NULL AS INT) AS p_id UNION ALL
    SELECT 2, 1 UNION ALL
    SELECT 3, 1 UNION ALL
    SELECT 4, 2 UNION ALL
    SELECT 5, 2
)
/*
思路：
1. 根节点的父节点为null
2.叶子节点没有子节点
3. 其余为中间节点
*/


select
    id,
    type
from (
         select
             t2.id,
             case
                 when p_id is null then 'Root'
                 when p_id is not null and  s_id is not null then 'Inner'
                 else 'Leaf' end as type
         from (
                  select
                      t0.id,
                      t0.p_id,
                      t1.id s_id
                  from Tree t0
                           left join Tree t1
                                     on t0.id = t1.p_id
              ) t2

     ) t3
group by id,type;



