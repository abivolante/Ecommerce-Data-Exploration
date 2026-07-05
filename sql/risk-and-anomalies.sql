-- ==========================================
-- Customer Behaviour & Rentention Analysis
-- ==========================================

-- Specific IP addresses associated with the highest volume of cancelled or returned orders
SELECT 
  e.ip_address, 
  COUNT(DISTINCT o.order_id) AS num_cancelled_or_returned_orders
FROM `bigquery-public-data.thelook_ecommerce.events` AS e
INNER JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o
  ON e.user_id = o.user_id
WHERE o.status IN ('Cancelled', 'Returned')
GROUP BY e.ip_address
ORDER BY num_cancelled_or_returned_orders DESC;

-- User accounts that have placed multiple orders within less than 5 minutes of each other
WITH OrderHistory AS (
  SELECT 
    user_id,
    created_at,
    -- Pulls the previous order timestamp for each unique user
    LAG(created_at, 1) OVER (PARTITION BY user_id ORDER BY created_at) AS prev_order_at
  FROM `bigquery-public-data.thelook_ecommerce.orders`
),

RapidOrders AS (
  SELECT 
    user_id,
    -- Calculates exact gap in seconds to avoid rounding/truncation bugs
    TIMESTAMP_DIFF(created_at, prev_order_at, SECOND) AS time_gap_seconds
  FROM OrderHistory
  WHERE prev_order_at IS NOT NULL 
    -- 300 seconds = exactly 5 minutes
    AND TIMESTAMP_DIFF(created_at, prev_order_at, SECOND) < 300
)

SELECT 
  user_id,
  COUNT(*) AS rapid_order_count
FROM RapidOrders
GROUP BY user_id
ORDER BY rapid_order_count DESC;
