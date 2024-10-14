CREATE TABLE fans (
    from_user STRING,
    to_user STRING,
    notice_date STRING
)
COMMENT '用户关注关系表'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;



INSERT INTO fans VALUES ('A', 'B', '2022-11-28 12:12:12');
INSERT INTO fans VALUES ('A', 'C', '2022-11-28 12:12:13');
INSERT INTO fans VALUES ('A', 'D', '2022-11-28 12:12:14');
INSERT INTO fans VALUES ('B', 'A', '2022-11-28 12:12:16');
INSERT INTO fans VALUES ('C', 'A', '2022-11-28 12:12:16');
INSERT INTO fans VALUES ('D', 'A', '2022-11-28 12:12:17');


/*
需求:
1. 在 fans 表中查找互相关注的用户对。
2. 互相关注定义为：用户 A 关注了用户 B，同时用户 B 也关注了用户 A。
3. 需要避免重复显示同一对用户（如 A-B 和 B-A 只显示一次）。
*/

-- 查找互相关注的用户对，避免重复
--方式一
SELECT t1.from_user, t1.to_user
FROM fans t1
 JOIN fans t2
ON t1.from_user = t2.to_user
AND t1.to_user = t2.from_user;


--方式二
select from_user,
       to_user
from (select from_user, to_user
      from fans
      union all
      select to_user, from_user
      from fans) t1
group by from_user, to_user
having count(1) >= 2;

-- 方式三
select from_user,to_user
from (select from_user,
             to_user,
             if(count(fans_user) over (partition by fans_user) > 1, 1, 0) as is_fans
      from (select
                if(hash(from_user) > hash(to_user), concat(from_user, '-', to_user),concat(to_user, '-', from_user)) fans_user,
                from_user,
                to_user
            from fans)t1)t2
where is_fans = 1;

/*
解释：
if(hash(from_user) > hash(to_user), concat(from_user, '-', to_user),concat(to_user, '-', from_user))。
这里的 if 语句用于生成唯一的 fans_user 标识符，代表一个唯一的关注关系对。
hash(from_user) 和 hash(to_user) 用于计算两个用户的哈希值。
如果 from_user 的哈希值大于 to_user 的哈希值，则将 from_user 和 to_user 连接为 from_user-to_user 的形式。
否则，将 to_user 和 from_user 连接为 to_user-from_user 的形式。
这样可以确保不管关注关系的方向，fans_user 都能够唯一标识一个用户对（如 A-B 和 B-A 用同一个标识B-A表示）。

if(count(fans_user) over (partition by fans_user) > 1, 1, 0)
这里的 if 语句用于判断 fans_user 的出现次数是否大于 1。
count(fans_user) over (partition by fans_user) 计算 fans_user 在整个结果集中出现的次数。
如果出现次数大于 1，则返回 1，表示这是一个互相关注的用户对。
否则，返回 0，表示这不是一个互相关注的用户对。

*/

-- 方式四
select count(*)
      ,fans2
      ,fans1
from (
SELECT
    t1.fans1 ,
    t2.fans2
FROM (
    SELECT
        CONCAT(from_user,'-',to_user) AS fan1,
        CONCAT(to_user,'-',from_user) AS fan2,
        from_user
    FROM fans
) as temp_table
LATERAL VIEW posexplode(split(temp_table.fan1,'-')) t1 AS fans_index1,fans1
LATERAL VIEW posexplode(split(temp_table.fan2,'-')) t2 AS fans_index2,fans2
WHERE t1.fans_index1 = t2.fans_index2
)
group by fans2
        ,fans1
having count(*)=2;


SELECT count(sort_array(split(user_fans,'-')))
      ,sort_array(split(user_fans,'-'))
from (
SELECT concat_ws(',',COLLECT_LIST(concat(from_user,'-',to_user))) as user_fans
      ,from_user
FROM fans
group by from_user
) GROUP BY sort_array(split(user_fans,'-'))
having count(sort_array(split(user_fans,'-')))=2;


