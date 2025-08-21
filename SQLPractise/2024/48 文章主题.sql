/*
 题目34 文章主题

```sql
表: Keywords
+---------------+------+
| Column Name   | Type |
+---------------+------+
| topic_id      | int  |
| word          | varchar |
+---------------+------+
(topic_id, word) 是该表的主键（具有唯一值的列的组合）。
该表的每一行都包含一个主题的 id 和一个用于描述该主题的词。
可以用多个词来表达同一个主题，也可以用一个词来表达多个主题。
表: Posts
+---------------+------+
| Column Name   | Type |
+---------------+------+
| post_id       | int  |
| content       | varchar |
+---------------+------+
post_id 是该表的主键（具有唯一值的列）。
该表的每一行都包含一个帖子的 ID 及其内容。
内容仅由英文字母和空格组成。
Leetcode 从其社交媒体网站上收集了一些帖子，并对每个帖子的主题感兴趣。每个主题可以用一个或多个关键字表示，如果某个主题的关键字存在于一个帖子的内容中（不区分大小写），那么这个帖子就有这个主题。
我们想找出每个帖子包含的主题：
如果帖子没有包含任何主题的关键词，那么这个的主题应该是 "Ambiguous!"。
如果帖子至少有一个主题的关键字，那主题应该是这些主题的 id 按升序排列并以逗号'，'分隔的字符串。字符串不应该包含重复的 id。
以 任意顺序 返回结果表。
结果格式如下所示。

示例 1:

输入：
Keywords 表:
+----------+--------+
| topic_id | word   |
+----------+--------+
| 1        | handball |
| 1        | football |
| 3        | WAR    |
| 2        | vaccine |
+----------+--------+
Posts 表:
+----------+--------------------------------------------+
| post_id  | content |
+----------+--------------------------------------------+
| 1        | We call it soccer They call it football hahaha |
| 2        | Americans prefer basketball while Europeans love handball and football |
| 3        | stop the war and play handball |
| 4        | warning I planted some flowers this morning and then got vaccinated |
+----------+--------------------------------------------+

输出：
+----------+----------+
| post_id  | topic    |
+----------+----------+
| 1        | 1        |
| 2        | 1        |
| 3        | 1,3      |
| 4        | Ambiguous! |
+----------+----------+

解释：
1: "We call it soccer They call it football hahaha"
"football" 表示主题 1，没有其他词能表示任何其他主题。

2: "Americans prefer basketball while Europeans love handball and football"
"handball" 表示主题 1，"football" 表示主题 1，
没有其他词能表示任何其他主题。

3: "stop the war and play handball"
"war" 表示主题 3，"handball" 表示主题 1，
没有其他词能表示任何其他主题。

4: "warning I planted some flowers this morning and then got vaccinated"
这个句子里没有一个词能表示任何主题，注意 "warning" 和 "war" 不同，尽管它们两个字母的前缀是相同的，所以这篇文章 "Ambiguous!"

请注意，可以使用一个词来表达多个主题。
```

*/

WITH Keywords AS (
    SELECT 1 AS topic_id, 'handball' AS word
    UNION ALL
    SELECT 1, 'football'
    UNION ALL
    SELECT 3, 'WAR'
    UNION ALL
    SELECT 2, 'vaccine'
),
Posts AS (
    SELECT 1 AS post_id, 'We call it soccer They call it football hahaha' AS content
    UNION ALL
    SELECT 2, 'Americans prefer basketball while Europeans love handball and football'
    UNION ALL
    SELECT 3, 'stop the war and play handball'
    UNION ALL
    SELECT 4, 'warning I planted some flowers this morning and then got vaccinated'
),
    tmp as (
        select
            t3.post_id,
            t3.amid_topic,
            row_number() over (partition by t3.post_id order by amid_topic)
        from (
            SELECT
                t1.post_id,
                CASE
                        WHEN t2.word IS NOT NULL THEN t2.topic_id /*CAST(t2.topic_id AS STRING)*/
                        ELSE -1 /*'Ambiguous'*/
                END amid_topic
            FROM Posts t1
            LEFT JOIN Keywords t2
                 -- 使用单词边界确保精确匹配 且 不区分大小写
            /*ON t1.content RLIKE CONCAT('\\b', t2.word, '\\b')
            or upper(t1.content) RLIKE CONCAT('\\b', t2.word, '\\b')*/
            on t1.content RLIKE CONCAT('(?i)\\b', t2.word, '\\b')
             ) t3

    )
select post_id,
       concat_ws(',',collect_set(
                     case
                         when amid_topic = -1 then 'Ambiguous'
                         else cast(amid_topic as string) end
                     )
       )
from tmp
group by post_id
order by post_id;


