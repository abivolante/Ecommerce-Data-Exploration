-- ==========================================
-- Customer Behaviour & Rentention Analysis
-- ==========================================

-- Specific IP addresses associated with the highest volume of cancelled or returned orders
WITH ranked_events AS (
  SELECT
    o.order_id,
    e.ip_address,
    ROW_NUMBER() OVER (
      PARTITION BY o.order_id
      ORDER BY ABS(TIMESTAMP_DIFF(o.created_at, e.created_at, SECOND))
    ) AS rank
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
  INNER JOIN `bigquery-public-data.thelook_ecommerce.events` AS e
    ON o.user_id = e.user_id
  WHERE o.status IN ('Cancelled', 'Returned')
)
SELECT
  ip_address,
  COUNT(DISTINCT order_id) AS num_cancelled_or_returned_orders
FROM ranked_events
WHERE rank = 1
GROUP BY ip_address
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
