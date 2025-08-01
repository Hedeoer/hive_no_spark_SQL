/*
表: `Files`
```
+-------------+---------+
| 列名        | 类型    |
+-------------+---------+
| file_name   | varchar |
| content     | text    |
+-------------+---------+
```
`file_name` 为该表的主键 (具有唯一值的列) 。
每行包含 `file_name` 和该文件的内容。

编写解决方案，找出单词 `'bull'` 和 `'bear'` 作为 `独立词` 有出现的文件数量，不考虑任何它出现在两侧没有空格的情况 (例如, `'bullet'`, `'bears'`, `'bull.'`, 或者 `'bear'` 在句首或句尾 不会 被考虑) 。
返回单词 `'bull'` 和 `'bear'` 以及它们对应的出现文件数量，顺序没有限制 。
结果的格式如下所示:

示例 1:

输入:
`Files` 表:
```
+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| file_name   | content                                                                                                                                                                                                                                                                           |
+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| draft1.txt  | The stock exchange predicts a bull market which would make many investors happy.                                                                                                                                                                                                  |
| draft2.txt  | The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market.                                                                                             |
| draft3.txt  | The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market. As always predicting the future market is an uncertain game and all investors should follow their instincts and best practices. |
+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```
输出:
```
+------+-------+
| word | count |
+------+-------+
| bull | 3     |
| bear | 2     |
+------+-------+
```
解释:
- 单词 "bull" 在 "draft1.txt" 中出现1次, 在 "draft2.txt" 中出现 1 次, 在 "draft3.txt" 中出现 1 次。因此, 单词 "bull" 出现在 3 个文件中。
- 单词 "bear" 在 "draft2.txt" 中出现1次, 在 "draft3.txt" 中出现 1 次。因此, 单词 "bear" 出现在 2 个文件中。
*/
WITH
-- 1. 模拟 Files 表
    Files AS (
        SELECT 'draft1.txt' AS file_name, 'The stock exchange predicts a bull market which would make many investors happy.' AS content UNION ALL
        SELECT 'draft2.txt', 'The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market.' UNION ALL
        SELECT 'draft3.txt', 'The stock exchange predicts a bull market which would make many investors happy, but analysts warn of possibility of too much optimism and that in fact we are awaiting a bear market. As always predicting the future market is an uncertain game and all investors should follow their instincts and best practices.'
    ),words as (
    select file_name,
           content,
--                 content regexp ' bull| bull |bull ' exists_flag1,
--                 content regexp ' bear| bear |bear ' exists_flag2
           content like '% bull %' as exists_flag1,
           content like '% bear %' as exists_flag2

    from Files t1
)
select
    'bull' as word,
    count(distinct if(exists_flag1 = 1, file_name, null)) as count
from words

union all

select
    'bear' as word,
    count(distinct if(exists_flag2 = 1, file_name, null)) as count
from words
