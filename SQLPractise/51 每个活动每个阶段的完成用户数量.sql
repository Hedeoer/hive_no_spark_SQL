
/*
act_order(
order_id， (订单)
act_id， (活动)
user_id, (用户)
pay_date (支付日期)

act_config (
act_id,
act_stage，(活动阶段)
act_config_cnt (完成活动阶段所需要的订单数量)

求在最近5天内，每个活动、每个阶段的完成用户数量（去重）

-- 查询示例：计算每个活动每个阶段的完成用户数量
SELECT
  c.act_id,
  c.act_stage,
  c.act_config_cnt as required_orders,
  COUNT(DISTINCT CASE WHEN user_orders.order_count >= c.act_config_cnt THEN user_orders.user_id ELSE NULL END) as completed_users
FROM act_config c
LEFT JOIN (
  SELECT
    act_id,
    user_id,
    COUNT(order_id) as order_count
  FROM act_order
  GROUP BY act_id, user_id
) user_orders ON c.act_id = user_orders.act_id
GROUP BY c.act_id, c.act_stage, c.act_config_cnt
ORDER BY c.act_id, c.act_stage;
  */

-- 使用 WITH 子句创建临时表
WITH
-- 模拟订单数据
act_order AS (
  SELECT 1001 as order_id, 101 as act_id, 1 as user_id, '2023-01-01' as pay_date UNION ALL
  SELECT 1002 as order_id, 101 as act_id, 1 as user_id, '2023-01-02' as pay_date UNION ALL
  SELECT 1003 as order_id, 101 as act_id, 1 as user_id, '2023-01-03' as pay_date UNION ALL
  SELECT 1004 as order_id, 101 as act_id, 2 as user_id, '2023-01-01' as pay_date UNION ALL
  SELECT 1005 as order_id, 101 as act_id, 2 as user_id, '2023-01-04' as pay_date UNION ALL
  SELECT 1006 as order_id, 101 as act_id, 3 as user_id, '2023-01-02' as pay_date UNION ALL
  SELECT 1007 as order_id, 102 as act_id, 1 as user_id, '2023-01-05' as pay_date UNION ALL
  SELECT 1008 as order_id, 102 as act_id, 2 as user_id, '2023-01-05' as pay_date UNION ALL
  SELECT 1009 as order_id, 102 as act_id, 4 as user_id, '2023-01-06' as pay_date UNION ALL
  SELECT 1010 as order_id, 102 as act_id, 4 as user_id, '2023-01-07' as pay_date
),

-- 模拟活动配置数据
act_config AS (
  SELECT 101 as act_id, 1 as act_stage, 1 as act_config_cnt UNION ALL
  SELECT 101 as act_id, 2 as act_stage, 2 as act_config_cnt UNION ALL
  SELECT 101 as act_id, 3 as act_stage, 3 as act_config_cnt UNION ALL
  SELECT 102 as act_id, 1 as act_stage, 1 as act_config_cnt UNION ALL
  SELECT 102 as act_id, 2 as act_stage, 2 as act_config_cnt
)
select
    ac.act_id, ac.act_stage,ac.act_config_cnt,
    count(distinct ao.user_id) actual_users,
    count(distinct ao.order_id) actual_orders
from act_order ao
left join act_config ac
on ao.act_id = ac.act_id
where to_date(ao.pay_date) >= date_sub(to_date('2023-01-07'), 5)
group by ac.act_id, ac.act_stage,ac.act_config_cnt
having actual_orders >= act_config_cnt;

