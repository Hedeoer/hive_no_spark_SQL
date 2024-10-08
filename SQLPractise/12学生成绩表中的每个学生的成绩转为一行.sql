

-- 创建班级成绩表
CREATE TABLE IF NOT EXISTS ClassScores (
    class STRING,
    student STRING,
    score STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;




-- 插入示例数据
INSERT INTO ClassScores VALUES
('1班', '小A,小B,小C', '80,92,70'),
('2班', '小D,小E', '88,62'),
('3班', '小F,小G,小H', '90,97,85');


/*
需求描述:
1. 表 ClassScores 包含字段: `class` (班级)，`student` (学生列表)，`score` (对应的学生成绩列表)。
2. 目标是将每个学生的成绩转为独立的一行，即每个学生和他对应的成绩成为单独的一行。
3. 输出表应包含字段: 班级、学生、成绩。
4. 示例数据：
   +------+----------------+-----------+
   | class| student         | score     |
   +------+----------------+-----------+
   | 1班  | 小A,小B,小C     | 80,92,70  |
   | 2班  | 小D,小E         | 88,62     |
   | 3班  | 小F,小G,小H     | 90,97,85  |
   +------+----------------+-----------+
5. 需要将上述数据转换为如下格式：
   +------+---------+-------+
   | class| student | score |
   +------+---------+-------+
   | 1班  | 小A     | 80    |
   | 1班  | 小B     | 92    |
   | 1班  | 小C     | 70    |
   | 2班  | 小D     | 88    |
   | 2班  | 小E     | 62    |
   | 3班  | 小F     | 90    |
   | 3班  | 小G     | 97    |
   | 3班  | 小H     | 85    |
   +------+---------+-------+
*/

select
    t1.class,
    names.student_name,
    scores.student_score
from classscores t1
lateral view posexplode(split(t1.student ,',')) names as student_id, student_name
lateral view posexplode(split(t1.score,',')) scores as student_id, student_score
where names.student_id = scores.student_id;

