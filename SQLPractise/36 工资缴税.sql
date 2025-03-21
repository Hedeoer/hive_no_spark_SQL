/*

1. Salaries 表：

| Column Name   | Type    |
|---------------|---------|
| company_id    | int     |
| employee_id   | int     |
| employee_name | varchar |
| salary        | int     |

2. 描述：

* 在 SQL 中，(company_id, employee_id) 是该表的主键。
* 该表包含员工的 company_id, id, name 和 salary。
* 编写一个 SQL 查询来查找每个员工的税后工资。

3. 税率规则：

* 如果公司员工最高工资 < $1000，税率为 0%。
* 如果公司员工最高工资在 [$1000, $10000] 之间，税率为 24%。
* 如果公司员工最高工资 > $10000，税率为 49%。

4. 返回结果：

* 按任意顺序返回结果。
* 返回结果格式如下例所示。

5. 示例：

输入：

Salaries 表

| company_id | employee_id | employee_name | salary |
|------------|-------------|---------------|--------|
| 1          | 1           | Tony          | 2000   |
| 1          | 2           | Pranub        | 21300  |
| 1          | 3           | Tyrrox        | 10800  |
| 2          | 1           | Pam           | 300    |
| 2          | 7           | Bassen        | 450    |
| 2          | 9           | Hermione      | 700    |
| 3          | 7           | Bocaben       | 100    |
| 3          | 2           | Ognjen        | 2200   |
| 3          | 13          | Nyancat       | 3300   |
| 3          | 15          | Morninngcat    | 7777   |

输出：

| company_id | employee_id | employee_name | salary |
|------------|-------------|---------------|--------|
| 1          | 1           | Tony          | 1020   |
| 1          | 2           | Pranub        | 10863  |
| 1          | 3           | Tyrrox        | 5508   |
| 2          | 1           | Pam           | 300    |
| 2          | 7           | Bassen        | 450    |
| 2          | 9           | Hermione      | 700    |
| 3          | 7           | Bocaben       | 76     |
| 3          | 2           | Ognjen        | 1672   |
| 3          | 13          | Nyancat       | 2508   |
| 3          | 15          | Morninngcat    | 5911   |

6. 解释：

* 公司 1 最高薪资为 21300，员工税率为 49%。
* 公司 2 最高薪资为 700，员工税率为 0%。
* 公司 3 最高薪资为 7777，员工税率为 24%。
* 税后薪资计算公式：薪资 - (税率 / 100) * 薪资。
* 例如，Morninngcat (员工编号 3, 薪资 7777) 税后薪资为：7777 - (24 / 100) * 7777 = 5911 (四舍五入)。
*/
WITH Salaries AS (
    SELECT 1 AS company_id, 1 AS employee_id, 'Tony' AS employee_name, 2000 AS salary
    UNION ALL
    SELECT 1, 2, 'Pranub', 21300
    UNION ALL
    SELECT 1, 3, 'Tyrrox', 10800
    UNION ALL
    SELECT 2, 1, 'Pam', 300
    UNION ALL
    SELECT 2, 7, 'Bassen', 450
    UNION ALL
    SELECT 2, 9, 'Hermione', 700
    UNION ALL
    SELECT 3, 7, 'Bocaben', 100
    UNION ALL
    SELECT 3, 2, 'Ognjen', 2200
    UNION ALL
    SELECT 3, 13, 'Nyancat', 3300
    UNION ALL
    SELECT 3, 15, 'Morninngcat', 7777
),
    company_tax as (
        select
            company_id,
            case
                when max(salary) < 1000 then 1
                when max(salary) >= 1000 and max(salary) <= 10000 then 1 - 0.24
                else 1 - 0.49
            end as tax
        from Salaries
        group by company_id
    )
select
    t1.company_id,
    employee_id,
    employee_name,
    round(salary * tax, 0) as salary
from Salaries t1
left join company_tax t2
on t1.company_id = t2.company_id;


