/*
表: `Employee`
```
+-----------+---------+
| Column Name | Type    |
+-----------+---------+
| id        | int     |
| company   | varchar |
| salary    | int     |
+-----------+---------+
```
id 是该表的主键列(具有唯一值的列)。
该表的每一行表示公司和一名员工的工资。
编写解决方案，找出每个公司的工资中位数。
以任意顺序 返回结果表。
查询结果格式如下所示。

示例 1:

输入:
`Employee` 表:
```
+----+---------+--------+
| id | company | salary |
+----+---------+--------+
| 1  | A       | 2341   |
| 2  | A       | 341    |
| 3  | A       | 15     |
| 4  | A       | 15314  |
| 5  | A       | 451    |
| 6  | A       | 513    |
| 7  | B       | 15     |
| 8  | B       | 13     |
| 9  | B       | 1154   |
| 10 | B       | 1345   |
| 11 | B       | 1221   |
| 12 | B       | 234    |
| 13 | C       | 2345   |
| 14 | C       | 2645   |
| 15 | C       | 2645   |
| 16 | C       | 2652   |
| 17 | C       | 65     |
+----+---------+--------+
```
输出:
```
+----+---------+--------+
| id | company | salary |
+----+---------+--------+
| 5  | A       | 451    |
| 6  | A       | 513    |
| 12 | B       | 234    |
| 9  | B       | 1154   |
| 14 | C       | 2645   |
+----+---------+--------+
```
进阶: 你能在不使用任何内置函数或窗口函数的情况下解决它吗?


*/



WITH
-- 1. 模拟 Employee 表
Employee AS (
    SELECT 1 AS id, 'A' AS company, 2341 AS salary UNION ALL
    SELECT 2, 'A', 341 UNION ALL
    SELECT 3, 'A', 15 UNION ALL
    SELECT 4, 'A', 15314 UNION ALL
    SELECT 5, 'A', 451 UNION ALL
    SELECT 6, 'A', 513 UNION ALL
    SELECT 7, 'B', 15 UNION ALL
    SELECT 8, 'B', 13 UNION ALL
    SELECT 9, 'B', 1154 UNION ALL
    SELECT 10, 'B', 1345 UNION ALL
    SELECT 11, 'B', 1221 UNION ALL
    SELECT 12, 'B', 234 UNION ALL
    SELECT 13, 'C', 2345 UNION ALL
    SELECT 14, 'C', 2645 UNION ALL
    SELECT 15, 'C', 2645 UNION ALL
    SELECT 16, 'C', 2652 UNION ALL
    SELECT 17, 'C', 65
)

-- 方式1
/*select
    company,percentile_approx(salary,0.5) as median_salary
from Employee
group by company*/

-- 方式2
/*
select
    id,
    company,
    salary
from (
         select id,
                company,
                salary,
                row_number() over (partition by company order by salary) rn,
                count(1) over (partition by company) cnt
         from Employee

     ) t1
where (cnt % 2 = 1 and rn = (cnt + 1) / 2) or (cnt % 2 = 0 and rn in (cnt / 2, cnt / 2 + 1));


*/

-- 方式3
-- 自连接的方式计算排名
/*row_number as (
    select t1.id,
        t1.company,
        t1.salary,
        count(1) as less_equal_count
    from Employee t1
    inner join  Employee t2
    on t1.company = t2.company and ( (t1.salary > t2.salary ) or (t1.salary = t2.salary and t1.id > t2.id))
    group by t1.id, t1.company,t1.salary
    ),
    -- 计算每个公司的总人数
 total_number as(
     select
         company,
         count(1) as total_count
     from Employee
     group by  company
 )
-- 最终查询
select
    t1.id,
    t1.company,
    t1.salary
from row_number t1
inner join total_number t2
    -- 核心筛选逻辑：
    -- 这个条件可以同时处理奇数和偶数的情况
    -- 奇数 (如 5): 中位数是第 3 位。r.rn >= 2.5 AND r.rn <= 3.5 --> 只有 rn=3 满足
    -- 偶数 (如 6): 中位数是第 3, 4 位。r.rn >= 3 AND r.rn <= 4 --> rn=3,4 都满足
on t1.company = t2.company and (total_count / 2.0 >= t1.less_equal_count and total_count / 2.0 <= t1.less_equal_count + 1);*/

-- 方式4
/*
这个算法的根本逻辑是：如果一个值的“中位数”，那么比它小的值的数量和比它大的值的数量应该是大致相等的。
    对于一个奇数个数的集合（如 1, 2, 3, 4, 5），中位数是 3。比 3 小的有2个值，比 3 大的也有2个值。它们的数量差是 2 - 2 = 0。
    对于一个偶数个数的集合（如 1, 2, 3, 4, 5, 6），中位数是 3 和 4。
    对于 3：比它小的值有2个，比它大的值有3个。数量差是 2 - 3 = -1。
    对于 4：比它小的值有3个，比它大的值有2个。数量差是 3 - 2 = 1。
因此，我们可以得出一个结论：一个值是中位数，当且仅当“比它小的值的数量”减去“比它大的值的数量”的结果在 -1, 0, 1 这个范围内
*/
select
    t1.id,
    t1.company,
    t1.salary
--     count(distinct t2.id) as less_count,
--     count(distinct t3.id) as greater_count,
--     count(distinct t2.id) - count(distinct t3.id) as diff_count
from Employee t1
         -- 计算比当前员工薪资高和低的员工数量，可以通过on的条件来实现如何定义比员工薪资高和低，假如存在相同薪资的员工，可以加入员工id来区分。灵活处理
         left join Employee t2 on t1.company = t2.company and t1.salary > t2.salary
    -- 计算比当前员工薪资高的员工数量
         left join Employee t3 on t1.company = t3.company and t1.salary < t3.salary
group by t1.id, t1.company, t1.salary
-- 只保留那些比当前员工薪资高和低的员工数量差在 -1, 0, 1 范围内的记录
having count(distinct t2.id) - count(distinct t3.id) between  -1 and 1;