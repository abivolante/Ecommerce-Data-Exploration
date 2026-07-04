-- ==========================================
-- Customer Behaviour & Rentention Analysis
-- ==========================================

-- Percentage of users who created an account and actually went on to place at least one order
WITH user_orders AS (
  SELECT 
    users.id, 
    CASE WHEN COUNT(orders.order_id) > 0 THEN 1 ELSE 0 END AS ordered
  FROM `bigquery-public-data.thelook_ecommerce.users` AS users
  LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS orders
    ON users.id = orders.user_id
  GROUP BY users.id
)

SELECT 
  SUM(ordered) AS total_users_who_ordered,
  COUNT(ordered) AS total_registered_users,
  -- Calculate the conversion percentage
  ROUND(100 * SUM(ordered) / COUNT(ordered), 2) AS conversion_rate_percentage
FROM user_orders;


-- Average number of days that pass between a user signing up and making their first purchase
WITH user_timeline AS (
  SELECT 
    orders.user_id, 
    MIN(orders.created_at) AS first_purchase, 
    MIN(users.created_at) AS sign_up 
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS orders 
  INNER JOIN `bigquery-public-data.thelook_ecommerce.users` AS users 
    ON users.id = orders.user_id 
  GROUP BY orders.user_id
) 
SELECT 
  -- Calculates the true average number of days across all buyers
  ROUND(AVG(TIMESTAMP_DIFF(first_purchase, sign_up, DAY)),0) AS avg_days_to_first_purchase
FROM user_timeline;


-- Traffic sources that result in the highest number of completed purchases
WITH RankedMatches AS (
  SELECT 
    e.user_id,
    e.traffic_source,
    e.created_at AS purchase_time,
    o.order_id,
    o.status,
    o.created_at AS order_created_at,
    -- Rank ONLY completed orders by how close they are to the event time
    ROW_NUMBER() OVER(
      PARTITION BY e.user_id, e.created_at, e.traffic_source
      ORDER BY ABS(TIMESTAMP_DIFF(e.created_at, o.created_at, SECOND)) ASC
    ) AS rank
  FROM `bigquery-public-data.thelook_ecommerce.events` AS e
  INNER JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o
    ON e.user_id = o.user_id
  WHERE e.user_id IS NOT NULL
    AND e.event_type = 'purchase' 
    -- Filter here so you only rank and match completed orders
    AND o.status = 'Complete' 
),

CleanedTable AS (
  SELECT 
    traffic_source
  FROM RankedMatches
  WHERE rank = 1
)

SELECT 
  traffic_source, 
  COUNT(*) AS completed_purchase_count
FROM CleanedTable
GROUP BY traffic_source
ORDER BY completed_purchase_count DESC;

-- Number of repeat customers (users with more than 2 separate orders) the platform have
WITH RepeatCustomers AS (
  SELECT 
    user_id
  FROM `bigquery-public-data.thelook_ecommerce.orders` 
  GROUP BY user_id
  -- Filters for users with strictly more than 2 distinct orders (3, 4, 5, etc.)
  HAVING COUNT(DISTINCT order_id) > 2
)

SELECT 
  COUNT(*) AS num_of_rep_cust 
FROM RepeatCustomers;
