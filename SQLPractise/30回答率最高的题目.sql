/*
整理后的文字如下：

---

**SurveyLog表：**

| Column Name | Type          |
|-------------|---------------|
| id          | int           |
| action      | ENUM          |
| question_id | int           |
| answer_id   | int           |
| q_num       | int           |
| timestamp   | int           |

- 这张表可能包含重复项。
- `action` 是一个 ENUM 类型的数据，可以是 "show"、"answer" 或者 "skip"。
- 这张表的每一行表示：ID=id 的用户对 question_id 的问题在 timestamp 时间进行了 action 操作。
- 如果用户的操作是 "answer"，`answer_id` 将会是对应答案的 ID，否则为 `null`。
- `q_num` 是该问题在当前会话中的数字顺序。
- 回答率是指：同一问题编号中回答次数占显示次数的比率。

编写一个解决方案以报告回答率最高的问题。如果有多个问题具有相同的最大回答率，返回 `question_id` 最小的那个。

**示例1：**

输入：
```
SurveyLog table:
| id | action | question_id | answer_id | q_num | timestamp |
|----|--------|-------------|-----------|-------|-----------|
| 5  | show   | 285         | null      | 1     | 123       |
| 5  | answer | 285         | 124124    | 1     | 124       |
| 5  | show   | 369         | null      | 2     | 125       |
| 5  | skip   | 369         | null      | 2     | 126       |
```

输出：
```
survey_log
| 285 |
```

解释：
- 问题 285 显示 1 次，回答 1 次，回答率为 1.0。
- 问题 369 显示 1 次，回答 0 次，回答率为 0.0。
- 问题 285 回答率最高。

*/

WITH surveyLog AS (
    SELECT 5 AS id, 'show' AS action, 285 AS question_id, NULL AS answer_id, 1 AS q_num, 123 AS `timestamp`
    UNION ALL
    SELECT 5, 'answer', 285, 124124, 1, 124
    UNION ALL
    SELECT 5, 'show', 369, NULL, 2, 125
    UNION ALL
    SELECT 5, 'skip', 369, NULL, 2, 126
)
select question_id,
       show_cnt,
       answer_cnt,
       answer_rate
from (
    select question_id,
           show_cnt,
           answer_cnt,
           answer_rate,
           row_number() over (order by answer_rate desc,question_id asc) as rn
    from (
        select
               question_id,
               sum(if(action = 'show',1,0)) as show_cnt,
               sum(if(action ='answer',1,0)) as answer_cnt,
               sum(if(action ='answer',1,0)) / sum(if(action ='show',1,0)) as answer_rate
        from surveyLog
        group by question_id
        -- 避免分母为0
        having sum(if(action ='show',1,0)) > 0
         ) t1
     ) t2
where rn = 1;

-- 方式二
WITH surveyLog AS (
    SELECT 5 AS id, 'show' AS action, 285 AS question_id, NULL AS answer_id, 1 AS q_num, 123 AS `timestamp`
    UNION ALL
    SELECT 5, 'answer', 285, 124124, 1, 124
    UNION ALL
    SELECT 5, 'show', 369, NULL, 2, 125
    UNION ALL
    SELECT 5, 'skip', 369, NULL, 2, 126
)
SELECT
    question_id,
    SUM(if(action = 'show', 1, 0)) AS show_cnt,
    SUM(if(action = 'answer', 1, 0)) AS answer_cnt,
    SUM(if(action = 'answer', 1, 0)) / SUM(if(action = 'show', 1, 0)) AS answer_rate
FROM surveyLog
GROUP BY question_id
HAVING SUM(if(action ='show', 1, 0)) > 0
ORDER BY answer_rate DESC, question_id ASC
LIMIT 1;

