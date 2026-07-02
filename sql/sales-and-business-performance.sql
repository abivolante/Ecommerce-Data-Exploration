-- =========================================
-- Sales & Business Performance Analysis
-- =========================================

-- Five product categories that generated the most total sales volume for the company
SELECT 
  products.category,
  COUNT(order_items.id) AS total_units_sold,
  ROUND(SUM(order_items.sale_price), 2) AS total_gross_sales
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS order_itemsi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS products 
  ON order_items.product_id = products.id
WHERE order_items.status = 'Complete'
GROUP BY products.category
ORDER BY total_gross_sales DESC
LIMIT 5;



-- Average order value (AOV) for each distinct country in the system
SELECT users.country,
      SUM(order_items.sale_price) AS revenue, 
      COUNT(DISTINCT order_items.order_id) AS total_orders,
      SUM(order_items.sale_price)/COUNT(DISTINCT order_items.order_id) aov
 FROM `bigquery-public-data.thelook_ecommerce.order_items` AS order_items
 JOIN `bigquery-public-data.thelook_ecommerce.users` AS users
 ON (order_items.user_id=users.id)
 WHERE order_items.status NOT IN ('Cancelled', 'Returned')
 GROUP BY users.country
 ORDER BY aov DESC


  
-- Top 10 highest-spending customers based on their lifetime purchase history
 SELECT users.id, users.last_name, users.first_name, SUM(order_items.sale_price) AS total_spent
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS order_items
 JOIN `bigquery-public-data.thelook_ecommerce.users` AS users
 ON (order_items.user_id=users.id)
WHERE order_items.status NOT IN ('Cancelled', 'Returned')
 GROUP BY users.id, users.last_name, users.first_name
 ORDER BY SUM(order_items.sale_price) DESC
 LIMIT 10;

-- Month-over-month growth rate of total completed sales
WITH table1 AS(
SELECT 
  EXTRACT(MONTH FROM created_at) AS month, 
  EXTRACT(YEAR FROM created_at) AS year, 
  SUM(sale_price) AS revenue
  FROM `bigquery-public-data.thelook_ecommerce.order_items` 
    WHERE status='Complete'
    GROUP BY year, month
),
table2 AS(
SELECT month, year, revenue,
LAG(revenue, 1) OVER (ORDER BY year, month) AS past_revenue,
FROM table1
)

SELECT month, year, 
100*(revenue-past_revenue)/(past_revenue) AS growth_rate
FROM table2
ORDER BY year, month
