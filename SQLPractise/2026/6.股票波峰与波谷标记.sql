

/* ==========================================================================
   习题：股票波峰与波谷标记
   ==========================================================================
   背景描述：
     现有一张股票每日收盘价表 stock_daily_price，记录了多支股票在一段时间内的
     日收盘价格。表结构如下：
       stock_id    STRING   -- 股票代码
       trade_date  STRING   -- 交易日期（格式 yyyy-MM-dd，已按日期升序排列）
       close_price DECIMAL  -- 当日收盘价

   数据说明：
     表中包含 3 支股票（TECH001、BANK002、ENERGY003），每支股票各有 15 个
     交易日（2024-01-01 至 2024-01-15），共计 45 条记录。

   需求：
     请编写 SQL，为每支股票在每个交易日标记出当前价格处于"波峰"、"波谷"
     还是"正常波动"状态，并输出以下字段：
       1. stock_id        — 股票代码
       2. trade_date      — 交易日期
       3. close_price     — 当日收盘价
       4. prev_price      — 前一交易日收盘价（首日为 NULL）
       5. next_price      — 后一交易日收盘价（末日为 NULL）
       6. price_type      — 价格类型标记，取值如下：
                             '波峰' — 当日价格严格高于前一天且严格高于后一天
                             '波谷' — 当日价格严格低于前一天且严格低于后一天
                             '正常'  — 其余情况（含首尾交易日）
       7. amplitude       — 振幅：若为波峰，取 (close_price - prev_price)
                                      与 (close_price - next_price) 的较大值；
                              若为波谷，取 (prev_price - close_price)
                                      与 (next_price - close_price) 的较大值；
                              若为正常，取 0

   补充说明：
     - 每支股票的首个交易日和末个交易日因缺少前/后参照，统一标记为 '正常'。
     - 振幅保留两位小数。
     - 最终结果按 stock_id 升序、trade_date 升序排列。
   ==========================================================================
*/
WITH stock_daily_price AS (
    SELECT 'TECH001' AS stock_id, '2024-01-01' AS trade_date, CAST(100.00 AS DECIMAL(10,2)) AS close_price
    UNION ALL SELECT 'TECH001', '2024-01-02', CAST(103.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-03', CAST(107.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-04', CAST(105.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-05', CAST(101.40 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-06', CAST(104.60 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-07', CAST(109.30 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-08', CAST(106.70 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-09', CAST(110.40 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-10', CAST(108.90 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-11', CAST(104.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-12', CAST(107.10 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-13', CAST(111.60 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-14', CAST(109.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'TECH001', '2024-01-15', CAST(113.40 AS DECIMAL(10,2))

    UNION ALL SELECT 'BANK002', '2024-01-01', CAST(50.00 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-02', CAST(48.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-03', CAST(51.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-04', CAST(49.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-05', CAST(52.60 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-06', CAST(51.30 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-07', CAST(47.90 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-08', CAST(50.10 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-09', CAST(53.40 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-10', CAST(52.00 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-11', CAST(49.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-12', CAST(51.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-13', CAST(54.70 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-14', CAST(53.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'BANK002', '2024-01-15', CAST(55.10 AS DECIMAL(10,2))

    UNION ALL SELECT 'ENERGY003', '2024-01-01', CAST(80.00 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-02', CAST(82.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-03', CAST(79.30 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-04', CAST(81.70 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-05', CAST(85.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-06', CAST(83.40 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-07', CAST(86.80 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-08', CAST(84.90 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-09', CAST(82.10 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-10', CAST(85.50 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-11', CAST(88.30 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-12', CAST(86.70 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-13', CAST(83.90 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-14', CAST(87.20 AS DECIMAL(10,2))
    UNION ALL SELECT 'ENERGY003', '2024-01-15', CAST(90.50 AS DECIMAL(10,2))
)
select stock_id,
       trade_date,
       close_price,
       prev_price,
       next_price,
       price_type,
       cast(case price_type
                when '正常' then 0
                else greatest(abs(close_price-prev_price),abs(close_price-next_price)) end
           as decimal(10,2)) as  amplitude
from (

         select stock_id,
                trade_date,
                close_price,
                prev_price,
                next_price,
                case
                    when close_price > prev_price and close_price > next_price then '波峰'
                    when close_price < prev_price and close_price < next_price then '波谷'
                    else '正常' end  as price_type

         from (

                  select stock_id,
                         trade_date,
                         close_price,
                         lag(close_price,1,null) over(partition by stock_id order by trade_date asc) prev_price,
                      lead(close_price,1,null) over(partition by stock_id order by trade_date asc) next_price

                  from stock_daily_price
              ) a
     )b
order by stock_id asc , trade_date asc;