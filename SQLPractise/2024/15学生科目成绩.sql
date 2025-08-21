-- ### 需求总结
--
-- 查询每一门课成绩都大于60分的学生，并返回这些学生的所有课程成绩。
--
-- ### 数据源建表语句


-- 学生表
drop table if exists student;
CREATE TABLE IF NOT EXISTS student (
    id INT,                 -- 学生ID
    student_name STRING     -- 学生姓名
) COMMENT '学生表';

-- 课程表
CREATE TABLE IF NOT EXISTS class (
    id INT,                 -- 课程ID
    class_name STRING       -- 课程名称
) COMMENT '课程表';

-- 选课表
CREATE TABLE IF NOT EXISTS sc (
    sid INT,                -- 学生ID
    cid INT,                -- 课程ID
    score INT               -- 成绩
) COMMENT '选课表';


-- ### 模拟数据

-- 插入学生表模拟数据
INSERT INTO student VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie');

-- 插入课程表模拟数据
INSERT INTO class VALUES
(101, 'Math'),
(102, 'English'),
(103, 'Science');

-- 插入选课表模拟数据
INSERT INTO sc VALUES
(1, 101, 65),     -- Alice Math 65
(1, 102, 75),     -- Alice English 75
(1, 103, 80),     -- Alice Science 80
(2, 101, 50),     -- Bob Math 50
(2, 102, 70),     -- Bob English 70
(3, 101, 90),     -- Charlie Math 90
(3, 102, 85),     -- Charlie English 85
(3, 103, 88);     -- Charlie Science 88


-- ### 整理明确需求


/*
需求：
1. 从选课表查询成绩都大于60分的学生。
2. 获取这些学生的所有课程成绩。
3. 学生需在所有已选课程中得分均超过60分。

-- 需求分解：
1. 找到每个学生的最低分大于60的学生ID。
2. 根据学生ID查询这些学生的所有课程成绩。
*/

select
    t1.id,
    t1.class_name,
    t2.sid,
    t3.student_name,
    t2.score
from class t1
left join sc t2
on t1.id = t2.cid
left join student t3
on t2.sid = t3.id;

with class_dim as (
    select
        collect_list(map(id,class_name)) class_list
    from class
)
select
    t1.student_id,
    t1.student_name,
    t2.c_map['id'] class_id,
    t2.c_map['class_name'] class_name/*,
    nvl(tt.score,0) score*/
    from (
        select
            t3.id student_id,
            t3.student_name
        from student t3
    ) t1
lateral view explode(class_dim.class_list) t2 as c_map;
/*left join sc tt
on t1.student_id = tt.sid and t2.c_map['id'] = tt.cid;*/

-- 方式一：笛卡尔积实现全科目匹配，比较总科名数和及格的科目数据
with tmp as (select tt.student_id,
                    tt.student_name,
                    tt.class_id,
                    tt.class_name,
                    nvl(t3.score, 0) score
             from (select t1.id student_id,
                          t1.student_name,
                          t2.id class_id,
                          t2.class_name
                   from student t1
                            cross join class t2) tt
                      left join sc t3
                                on tt.student_id = t3.sid and tt.class_id = t3.cid)
select student_id,
       student_name,
       class_id,
       class_name,
       score
from (
select
    *,
    count(*) over(partition by student_id) total_classs_nums,
    count(if(score > 60, 1, null)) over(partition by student_id) pass_classs_nums
from tmp) t
where total_classs_nums = pass_classs_nums;


-- 方式二 MAPJOIN， 比较总科名数和及格的科目数据
with tmp as (select tt.student_id,
                    tt.student_name,
                    tt.class_id,
                    tt.class_name,
                    nvl(t3.score, 0) score
             from (SELECT /*+ MAPJOIN(t2) */ t1.id AS student_id,
                                             t1.student_name,
                                             t2.id AS class_id,
                                             t2.class_name
                   FROM student t1
                   cross JOIN class t2) tt
             left join sc t3
             on tt.student_id = t3.sid and tt.class_id = t3.cid)
select student_id,
       student_name,
       class_id,
       class_name,
       score
from (select *,
             count(*) over (partition by student_id)                       total_classs_nums,
             count(if(score > 60, 1, null)) over (partition by student_id) pass_classs_nums
      from tmp) t
where total_classs_nums = pass_classs_nums;

-- 假设我使用的hive环境强制不能使用 1 = 1等类似的恒等条件或者笛卡尔join
-- 可以构建虚拟列实现效果
with tmp as (select tt.student_id,
                    tt.student_name,
                    tt.class_id,
                    tt.class_name,
                    nvl(t3.score, 0) score
             from (select t1.id AS student_id,
                          t1.student_name,
                          t2.id AS class_id,
                          t2.class_name
                       FROM (select id, student_name, 1 as join_key from student) t1
                                left JOIN (select id, class_name, 1 as join_key from class) t2
                                          on t1.join_key = t2.join_key
                       where t1.id is not null) tt
                      left join sc t3
                      on tt.student_id = t3.sid and tt.class_id = t3.cid)
select student_id,
       student_name,
       class_id,
       class_name,
       score
from (select *,
             count(*) over (partition by student_id)                       total_classs_nums,
             count(if(score > 60, 1, null)) over (partition by student_id) pass_classs_nums
      from tmp) t
where total_classs_nums = pass_classs_nums;


-- 方式三 通过查询学生得分最低的科目是否大于60，来判断每门科都及格
with tmp as (select tt.student_id,
                    tt.student_name,
                    tt.class_id,
                    tt.class_name,
                    nvl(t3.score, 0) score
             from (select t1.id AS student_id,
                          t1.student_name,
                          t2.id AS class_id,
                          t2.class_name
                       FROM (select id, student_name, 1 as join_key from student) t1
                                left JOIN (select id, class_name, 1 as join_key from class) t2
                                          on t1.join_key = t2.join_key
                       where t1.id is not null) tt
                      left join sc t3
                      on tt.student_id = t3.sid and tt.class_id = t3.cid)
select student_id,
       student_name,
       class_id,
       class_name,
       score
from (select *,
             min(score) over (partition by student_id) min_score
      from tmp) t
where min_score > 60;



