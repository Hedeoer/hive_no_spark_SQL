
-- 方法一：使用 sort_array()
SELECT
  key,
  sort_array(collect_list(value)) AS sorted_values
FROM
  your_table
GROUP BY
  key;

-- 方法二：结合 SORT BY 和 collect_list()
SELECT
  key,
  collect_list(value) AS values_list
FROM
  (SELECT key, value FROM your_table
   DISTRIBUTE BY key
   SORT BY key, value) t
GROUP BY
  key;
