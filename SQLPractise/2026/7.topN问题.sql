/* ==========================================================================
   习题：电商品类销售额 TopN 多维分析
   ==========================================================================
   背景描述：
     某电商平台记录了 2024 年第一季度各品类商品每日的订单数据，存在单张表
     daily_category_sales 中，每行代表某天某品类某商品的一笔销售汇总记录。
     表结构如下：
       order_id      INT     -- 记录序号
       sale_date     STRING  -- 销售日期（格式 yyyy-MM-dd）
       category      STRING  -- 商品品类（共 4 个：手机数码、家用电器、
                                       服装鞋帽、食品生鲜）
       product_name  STRING  -- 商品名称
       sale_amount   DECIMAL -- 销售金额（元）
       sale_qty      INT     -- 销售数量（件）

   数据说明：
     - 数据覆盖 2024-01-01 至 2024-03-31，共 90 天
     - 4 个品类，每个品类下有不同商品，每个品类在每天可能有 0~3 条记录
     - 同一品类同一商品在同一天可能出现多条记录（订单拆分写入）

   ==========================================================================
   需求：
   ==========================================================================

     【需求一】每个品类在2024年Q1中，销售额排名前3的商品

       - 同一品类下，同一商品在多天的多条记录需要先按商品汇总求和
       - 按 sale_amount 降序取每个品类 Top 3
       - 同时标注排名序号 rn（1/2/3）
       - 输出字段：category, product_name, total_amount, rn
       - 按品类升序、排名升序排列

*/


-- ======================== 模拟数据 ========================
-- 通过 WITH 生成数据，用规律性 + 随机感混合的方法构造测试数据集

WITH raw_data AS (
    -- 手机数码品类
    SELECT 1 AS order_id, '2024-01-01' AS sale_date, '手机数码' AS category, 'iPhone15'   AS product_name, CAST(5600.00 AS DECIMAL(10,2)) AS sale_amount, 2  AS sale_qty
    UNION ALL SELECT 2,  '2024-01-01', '手机数码', 'iPhone15',   CAST(5600.00 AS DECIMAL(10,2)), 2
    UNION ALL SELECT 3,  '2024-01-01', '手机数码', 'iPadAir',    CAST(4200.00 AS DECIMAL(10,2)), 3
    UNION ALL SELECT 4,  '2024-01-02', '手机数码', 'iPhone15',   CAST(2800.00 AS DECIMAL(10,2)), 1
    UNION ALL SELECT 5,  '2024-01-02', '手机数码', 'AirPods',    CAST(1999.00 AS DECIMAL(10,2)), 5
    UNION ALL SELECT 6,  '2024-01-05', '手机数码', 'iPadAir',    CAST(8400.00 AS DECIMAL(10,2)), 6
    UNION ALL SELECT 7,  '2024-01-05', '手机数码', 'iPhone15',   CAST(8400.00 AS DECIMAL(10,2)), 3
    UNION ALL SELECT 8,  '2024-01-10', '手机数码', 'GalaxyS24',  CAST(3999.00 AS DECIMAL(10,2)), 2
    UNION ALL SELECT 9,  '2024-01-10', '手机数码', 'AirPods',    CAST(3998.00 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 10, '2024-01-15', '手机数码', 'iPhone15',   CAST(28000.00 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 11, '2024-01-15', '手机数码', 'GalaxyS24',  CAST(9998.00 AS DECIMAL(10,2)), 5
    UNION ALL SELECT 12, '2024-01-20', '手机数码', 'iPadAir',    CAST(12600.00 AS DECIMAL(10,2)), 9
    UNION ALL SELECT 13, '2024-01-20', '手机数码', 'AirPods',    CAST(5997.00 AS DECIMAL(10,2)), 15
    UNION ALL SELECT 14, '2024-02-01', '手机数码', 'iPhone15',   CAST(11200.00 AS DECIMAL(10,2)), 4
    UNION ALL SELECT 15, '2024-02-05', '手机数码', 'GalaxyS24',  CAST(7998.00 AS DECIMAL(10,2)), 4
    UNION ALL SELECT 16, '2024-02-10', '手机数码', 'iPadAir',    CAST(16800.00 AS DECIMAL(10,2)), 12
    UNION ALL SELECT 17, '2024-02-15', '手机数码', 'iPhone15',   CAST(14000.00 AS DECIMAL(10,2)), 5
    UNION ALL SELECT 18, '2024-02-15', '手机数码', 'iPhone15',   CAST(2800.00 AS DECIMAL(10,2)), 1
    UNION ALL SELECT 19, '2024-02-20', '手机数码', 'AirPods',    CAST(9995.00 AS DECIMAL(10,2)), 25
    UNION ALL SELECT 20, '2024-02-20', '手机数码', 'GalaxyS24',  CAST(3999.00 AS DECIMAL(10,2)), 2
    UNION ALL SELECT 21, '2024-03-01', '手机数码', 'iPhone15',   CAST(25200.00 AS DECIMAL(10,2)), 9
    UNION ALL SELECT 22, '2024-03-01', '手机数码', 'iPadAir',    CAST(8400.00 AS DECIMAL(10,2)), 6
    UNION ALL SELECT 23, '2024-03-10', '手机数码', 'GalaxyS24',  CAST(5999.00 AS DECIMAL(10,2)), 3
    UNION ALL SELECT 24, '2024-03-10', '手机数码', 'AirPods',    CAST(3998.00 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 25, '2024-03-10', '手机数码', 'GalaxyS24',  CAST(1999.50 AS DECIMAL(10,2)), 1
    UNION ALL SELECT 26, '2024-03-20', '手机数码', 'iPhone15',   CAST(19600.00 AS DECIMAL(10,2)), 7
    UNION ALL SELECT 27, '2024-03-20', '手机数码', 'iPadAir',    CAST(12600.00 AS DECIMAL(10,2)), 9
    UNION ALL SELECT 28, '2024-03-20', '手机数码', 'AirPods',    CAST(5997.00 AS DECIMAL(10,2)), 15
    UNION ALL SELECT 29, '2024-03-31', '手机数码', 'iPhone15',   CAST(16800.00 AS DECIMAL(10,2)), 6
    UNION ALL SELECT 30, '2024-03-31', '手机数码', 'GalaxyS24',  CAST(11997.00 AS DECIMAL(10,2)), 6


    -- 食品生鲜品类
    UNION ALL SELECT 90, '2024-01-01', '食品生鲜', '牛奶',     CAST(299.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 91, '2024-01-01', '食品生鲜', '鸡蛋',     CAST(159.00 AS DECIMAL(10,2)), 30
    UNION ALL SELECT 92, '2024-01-03', '食品生鲜', '苹果',     CAST(499.00 AS DECIMAL(10,2)), 25
    UNION ALL SELECT 93, '2024-01-03', '食品生鲜', '牛奶',     CAST(598.00 AS DECIMAL(10,2)), 100
    UNION ALL SELECT 94, '2024-01-05', '食品生鲜', '鸡蛋',     CAST(477.00 AS DECIMAL(10,2)), 90
    UNION ALL SELECT 95, '2024-01-05', '食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 96, '2024-01-05', '食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 97, '2024-01-08', '食品生鲜', '牛奶',     CAST(1196.00 AS DECIMAL(10,2)), 200
    UNION ALL SELECT 98, '2024-01-10', '食品生鲜', '鸡蛋',     CAST(954.00 AS DECIMAL(10,2)), 180
    UNION ALL SELECT 99, '2024-01-10', '食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 100,'2024-01-15','食品生鲜', '牛奶',     CAST(897.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 101,'2024-01-15','食品生鲜', '鸡蛋',     CAST(318.00 AS DECIMAL(10,2)), 60
    UNION ALL SELECT 102,'2024-02-01','食品生鲜', '牛奶',     CAST(1196.00 AS DECIMAL(10,2)), 200
    UNION ALL SELECT 103,'2024-02-05','食品生鲜', '牛奶',     CAST(897.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 104,'2024-02-05','食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 105,'2024-02-05','食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 106,'2024-02-10','食品生鲜', '鸡蛋',     CAST(1113.00 AS DECIMAL(10,2)), 210
    UNION ALL SELECT 107,'2024-02-10','食品生鲜', '牛奶',     CAST(598.00 AS DECIMAL(10,2)), 100
    UNION ALL SELECT 108,'2024-02-15','食品生鲜', '苹果',     CAST(2994.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 109,'2024-02-15','食品生鲜', '鸡蛋',     CAST(636.00 AS DECIMAL(10,2)), 120
    UNION ALL SELECT 110,'2024-02-15','食品生鲜', '鸡蛋',     CAST(318.00 AS DECIMAL(10,2)), 60
    UNION ALL SELECT 111,'2024-02-20','食品生鲜', '牛奶',     CAST(1495.00 AS DECIMAL(10,2)), 250
    UNION ALL SELECT 112,'2024-02-20','食品生鲜', '鸡蛋',     CAST(1431.00 AS DECIMAL(10,2)), 270
    UNION ALL SELECT 113,'2024-03-01','食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 114,'2024-03-01','食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 115,'2024-03-01','食品生鲜', '牛奶',     CAST(299.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 116,'2024-03-05','食品生鲜', '鸡蛋',     CAST(1113.00 AS DECIMAL(10,2)), 210
    UNION ALL SELECT 117,'2024-03-05','食品生鲜', '苹果',     CAST(998.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 118,'2024-03-05','食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 119,'2024-03-10','食品生鲜', '牛奶',     CAST(897.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 120,'2024-03-10','食品生鲜', '牛奶',     CAST(598.00 AS DECIMAL(10,2)), 100
    UNION ALL SELECT 121,'2024-03-10','食品生鲜', '牛奶',     CAST(299.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 122,'2024-03-15','食品生鲜', '鸡蛋',     CAST(1590.00 AS DECIMAL(10,2)), 300
    UNION ALL SELECT 123,'2024-03-15','食品生鲜', '苹果',     CAST(2994.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 124,'2024-03-15','食品生鲜', '苹果',     CAST(399.20 AS DECIMAL(10,2)), 20
    UNION ALL SELECT 125,'2024-03-15','食品生鲜', '鸡蛋',     CAST(636.00 AS DECIMAL(10,2)), 120
    UNION ALL SELECT 126,'2024-03-20','食品生鲜', '牛奶',     CAST(1495.00 AS DECIMAL(10,2)), 250
    UNION ALL SELECT 127,'2024-03-20','食品生鲜', '鸡蛋',     CAST(1431.00 AS DECIMAL(10,2)), 270
    UNION ALL SELECT 128,'2024-03-20','食品生鲜', '鸡蛋',     CAST(477.00 AS DECIMAL(10,2)), 90
    UNION ALL SELECT 129,'2024-03-25','食品生鲜', '苹果',     CAST(2994.00 AS DECIMAL(10,2)), 150
    UNION ALL SELECT 130,'2024-03-25','食品生鲜', '牛奶',     CAST(1794.00 AS DECIMAL(10,2)), 300
    UNION ALL SELECT 131,'2024-03-31','食品生鲜', '鸡蛋',     CAST(1590.00 AS DECIMAL(10,2)), 300
    UNION ALL SELECT 132,'2024-03-31','食品生鲜', '牛奶',     CAST(299.00 AS DECIMAL(10,2)), 50
    UNION ALL SELECT 133,'2024-03-31','食品生鲜', '苹果',     CAST(1497.00 AS DECIMAL(10,2)), 75
    UNION ALL SELECT 134,'2024-03-31','食品生鲜', '苹果',     CAST(199.60 AS DECIMAL(10,2)), 10
    UNION ALL SELECT 135,'2024-03-31','食品生鲜', '鸡蛋',     CAST(159.00 AS DECIMAL(10,2)), 30
)
/*

select
    c.product_name,
    c.quart_product_amt as sale_amount,
    c.rank_num
from (

         select product_name,
                quart_product_amt,
                row_number() over (order by quart_product_amt desc) rank_num
         from (

                  select
                      a.product_name,
                      sum(a.sale_qty * a.sale_amount) quart_product_amt
                  from raw_data a
                  where substr(a.sale_date,1,7) <= '2024-03'
                  group by a.product_name
              )b
     )c
where c.rank_num <= 3
order by c.product_name ,c.quart_product_amt;
*/

-- 方式2
        ,
     mid_count as (
         select
             a.product_name,
             sum(a.sale_qty * a.sale_amount) quart_product_amt
         from raw_data a
         where substr(a.sale_date,1,7) <= '2024-03'
         group by a.product_name
     )
select
    t1.product_name,
    t1.quart_product_amt,
    count(*) + 1 rank_num
from mid_count t1
         left join mid_count t2
                   on t1.product_name != t2.product_name and t1.quart_product_amt < t2.quart_product_amt
group by t1.product_name,t1.quart_product_amt
having count(*) + 1 <=3
order by t1.product_name asc ,t1.quart_product_amt asc;


