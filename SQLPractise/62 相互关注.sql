
/*


相互关注 (共同好友)
现在有一张表为fans(粉丝表) 里面有两个字段from_user,to_user ,如果两者一致代表from_user关注了to_user

**相互关注**
fans表 --关注表,记录关注动作记录的表
数据如下:
follow表: from_user: 关注用户, to_user: 被关注用户, timestamp: 关注时间。
比如第一行的意思是:A关注了B
```
from_user   to_user   timestamp
A           B         2022-11-28 12:12:12
A           C         2022-11-28 12:12:13
A           D         2022-11-28 12:12:14
B           A         2022-11-28 12:12:15
B           E         2022-11-28 12:12:16
C           A         2022-11-28 12:12:17
```
6行

`t1表left join t2表on t1.from_user=t2.to_user and t1.to_user=t2.from_user`

```
from_user   to_user
A           B
A           C
A           D
B           A
B           E
C           A
```
无条件join结果为6*6=36行

---
 现在有一张表为fans(粉丝表) 里面有两个字段from_user,to_user ,如果两者一致代表from_user关注了to_user
*/

with fans as (
    SELECT
        '001' as from_user,'002' as to_user
    union all
    SELECT
        '002' as from_user,'001' as to_user
    union all
    SELECT
        '003' as from_user,'001' as to_user
    union all
    SELECT
        '005' as from_user,'001' as to_user
)
/*
    -- 方法1: 使用UNION ALL和GROUP BY来计算相互关注的用户对
    -- 计算相互关注的用户对
  both_fans as (
      select
          from_user,
          to_user,
          -- 使用concat和least函数来确保相互关注的用户对的顺序一致
          concat(least(from_user, to_user), '-', least(to_user, from_user)) as user_group
      from (
               select
                   t1.from_user,
                   t1.to_user
               from fans t1
               union all
               select
                   t2.to_user,
                   t2.from_user
               from fans t2
           )t3
      group by
          t3.from_user,
          t3.to_user
      having count(1) > 1
  )
-- 从相互关注的用户对中选择每个用户组的第一个用户对即可
select
    from_user,
    to_user
from (
         select
             from_user,to_user,
             -- 为每个用户组分配一个行号
             row_number() over (partition by user_group order by from_user, to_user) as row_num
         from both_fans t1
     ) t2
where row_num = 1;

*/

/*
-- 方法2: 使用窗口函数和hash来计算相互关注的用户对
select
    from_user,
    to_user
from (
         select
             from_user,
             to_user,
             -- 使用hash和concat来确保相互关注的用户对的顺序一致
             row_number() over (partition by hash(concat(least(from_user, to_user),  greatest(from_user, to_user))) order by from_user,to_user ) rn,
             -- 计算每个用户组内的数量
             count() over (partition by hash(concat(least(from_user, to_user),  greatest(from_user, to_user))) ) as cnt
         from fans t1
     ) t2
-- 过滤出相互关注的用户对
where rn = 1 and cnt > 1;

*/

/*
-- 方法3: 使用JOIN来计算相互关注的用户对
select
    t1.from_user,
    t1.to_user
from fans t1
inner join fans t2
on t1.from_user = t2.to_user and t1.to_user = t2.from_user

*/

-- 方法4: 使用GROUP BY和HAVING来计算相互关注的用户对
SELECT count(sort_array(split(user_fans,'-')))
     ,sort_array(split(user_fans,'-'))
from (
         SELECT concat_ws(',',COLLECT_LIST(concat(from_user,'-',to_user))) as user_fans
              ,from_user
         FROM fans
         group by from_user
     ) a GROUP BY sort_array(split(user_fans,'-'))
having count(sort_array(split(user_fans,'-')))=2

