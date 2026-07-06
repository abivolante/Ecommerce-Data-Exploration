# Ecommerce Dataset Exploration

This project is a data exploration of **The Look Ecommerce** public dataset on Google BigQuery, built as a learning exercise to master SQL. I looked at questions a business might find useful across three areas:

- Sales and Business Performance
- Customer Behaviour and Retention
- Risk and Anomalies

**Status: In Progress** — Will add further conclusions for Sales & Business Performance section and Customer Behaviour/Retention. Risk/Anomalies sections in development.
## Dataset
This project uses **thelook_ecommerce** data available on Google BigQuery.

**Source:** https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce

This Dataset contain 6 tables:
- **users**
One row for every single person who has ever registered an account. This is where we'll get all your demographic data to find out who your customers are.
- **orders** (The Basket Summaries)
One row for every distinct checkout basket submitted by a user. This tracks order success rates.
- **order_items** 
The is the most important table for revenue. If an order has 3 items in the basket, this table will show 3 individual rows for that single order_id.
We use this table to calculate financial metrics like total revenue, average order value, and product profit margins.
- **products** (The Inventory Catalog)
Thus contains a list of every single item of clothing available for sale on the website. We use this to order_items to see which brands or clothing categories are making the most money.
- **distribution_centers** 
This is a small reference table listing the physical warehouses where inventory is stored.
This is normally used by supply chain analysts to calculate shipping distances. I didn't use this table for this project.
- **inventory_items** (The Warehouse Stock)
This is a live tracker of every physical piece of clothing sitting on a shelf in a warehouse. This tracks stock levels to ensure the website doesn't sell items that are out of stock.
- **events** (The Website Clickstream Logs)
This is the largest and messiest table. It records every single mouse click or screen tap a user makes on the website or mobile app.
I used this for behavioral analysis, mapping the customer journey, and spotting unusual activities.
## Sales and Business Performance Results

I looked at overall sales performance from a few different angles: which categories sell best, how order value varies by country, who the highest-value customers are, and how revenue is trending month over month.

**Top 5 product categories by sales:** I joined `order_items` to `products` on `product_id` to bring in category labels, then filtered to `status = 'Complete'` so cancelled/returned items don't inflate sales figures. I aggregated both unit count and gross revenue per category, ranked by revenue, and kept the top 5. Note that "total sales volume" could mean units sold *or* revenue. I used revenue as the primary sort since it's usually the more relevant metric for businesses, but kept `total_units_sold` in the output so both information are visible.

<img width="1011" height="293" alt="Top 5 product categories by sales" src="https://github.com/user-attachments/assets/173cea0b-823b-4a87-9018-674cdf2ce405" />

**Average Order Value (AOV) by country:** Since country is readily available in the data, calculating AOV per country allows the business to easily localise strategy. AOV here is defined as total revenue divided by *distinct* order count, not row count — an important distinction, since `order_items` has one row per item, not per order. I joined `order_items` to `users` on `user_id` to get country, and excluded `Cancelled`/`Returned` statuses (a broader exclusion than the first query, since `Processing`/`Shipped` orders still represent real committed revenue).

<img width="740" height="425" alt="Average order value by country" src="https://github.com/user-attachments/assets/f6602a08-a223-4244-8b72-38648d84adab" />

**Top 10 highest-spending customers:** I joined `order_items` to `users` on `user_id`, excluded `Cancelled`/`Returned` orders (same reasoning as above), summed `sale_price` per customer, and took the top 10 by lifetime spend.

<img width="785" height="375" alt="Top 10 highest-spending customers" src="https://github.com/user-attachments/assets/8c8f7321-baa0-4c94-99e6-af02bbf78df2" />

**Month-over-month growth rate of completed sales:** I built a monthly revenue total in `table1` (Complete orders only), then used `LAG()` in `table2` to pull the prior month's revenue for comparison, and calculated growth as `(current - prior) / prior`. Note: the earliest month in the dataset shows a null growth rate, since there's no prior month to compare against — this is expected, not a bug.

<img width="506" height="430" alt="Month-over-month growth rate" src="https://github.com/user-attachments/assets/264b7a60-c473-4577-9f38-460cb1228716" />

## Customer Behaviour & Retention Results

Looking at the data recorded about customers and their behaviour, I wanted to understand how well the business converts and retains users — specifically, how many people who create an account actually go on to buy something, how quickly, through which channels, and how many come back.

**Conversion rate (account → first order):** I joined `users` to `orders` on `user_id` and built an indicator column marking whether each user placed at least one order (`1`) or not (`0`). Aggregating that column gave both the count of converting users and the total registered user base, from which I calculated the percentage.

<img width="517" height="169" alt="customers_who_ordered" src="https://github.com/user-attachments/assets/0011bca0-3a5f-4942-8755-2f67b62adff5" />

**Average days to first purchase:** I joined `orders` and `users` on `user_id` into a CTE recording each user's sign-up time and first purchase time using `MIN()`, then used `TIMESTAMP_DIFF()` and `AVG()` to find the average gap across all buyers.

<img width="425" height="140" alt="user_signup-purchase" src="https://github.com/user-attachments/assets/165e6264-01dc-4a01-9d69-48043f608e20" />

**Highest-converting traffic sources:** This one was more involved. The `orders` table has a `created_at` timestamp but no link to *how* the customer arrived. The `events` table tracks `traffic_source` and various `event_type`s (add to cart, purchase, cancel, etc.) but has no `order_id` to join on directly. The only way to connect the two is to match each purchase event to the order created closest to it in time.

<img width="484" height="267" alt="traffic_sources" src="https://github.com/user-attachments/assets/0a3f9a75-0c6f-4895-9e49-4de937300554" />

**Repeat Customers** I wanted to see how many customers come back and buy more than once, since repeat purchase rate is a strong signal of customer loyalty, much more so than one-off transactions. I grouped `orders` by `user_id` and used `HAVING COUNT(DISTINCT order_id) > 2` to isolate users with strictly more than two separate orders, then counted how many users met that threshold.

<img width="391" height="160" alt="num_repeat_cust" src="https://github.com/user-attachments/assets/9be0652f-fe9a-44f0-80cf-3ec26fc9d4ad" />


## Risk & Anomalies Results
In this section, I wanted to look for unusual activity that could signal fraud or risk to the business.

**IP addresses with the highest volume of cancelled/returned orders:** 
I first looked for IP address tied to an unusually high number of cancelled or returned orders, which could indicate abuse of the return/cancellation process rather than normal customer behaviour.
My first attempt joined `events` to `orders` on `user_id` alone, aggregated by IP address, and counted distinct cancelled/returned orders per IP. Then, when I looked at an instance of a specific user, I realised the code overcounted the number of cancelled/returned orders for a specific IP. I realised you'd need to use the same technique as when matching events to orders with no direct common link. (See 3. Technical Highlights for further explanation)

<img width="592" height="299" alt="ip_address" src="https://github.com/user-attachments/assets/fa4b55b4-462e-4dc4-85cd-9e98dfbc9158" />

**Users placing multiple orders within 5 minutes of each other:** To catch potential bot activity or accidental duplicate checkouts, I used `LAG()` partitioned by `user_id` and ordered by `created_at` to pull each user's previous order timestamp alongside their current one. I calculated the gap in seconds rather than minutes to avoid rounding or truncation bugs, then filtered to gaps under 300 seconds (5 minutes). Aggregating by user and counting how many of their orders fall under that threshold surfaces the accounts most likely to show automated or anomalous ordering behaviour.

<img width="427" height="326" alt="rapid_orders" src="https://github.com/user-attachments/assets/3a10d6f7-eeb6-4db9-b373-dd7f034e19d6" />


## Key SQL Techniques Used:

* **CTEs (Common Table Expressions**): Separated raw revenue aggregation from the window function logic in a second step, keeping the script readable and easy to debug independently.
* **Window Functions (LAG)**: Compared each month's revenue against the true immediately-preceding calendar month (ordered by year, month to avoid cross-year misalignment — see Technical Highlight below) to calculate period-over-period growth.

## Technical Highlights:  

### 1. Getting Chronological Ordering Right in LAG()

**The problem:** Monthly revenue was extracted as two separate integer fields — EXTRACT(MONTH ...) and EXTRACT(YEAR ...). I initially sorted by month alone (since that's the value I ultimately care about comparing). But month only ranges 1–12 and repeats every year, so ordering by month alone would scramble the actual timeline: December 2023 could get placed next to December 2024 instead of next to January 2024, and LAG() would pull revenue from the wrong prior period entirely.

**The fix:** Window the LAG() function using ORDER BY year, month, treating year as the primary sort key and month as secondary. This guarantees the sequence is truly chronological (Jan 2023 → Feb 2023 → ... → Dec 2023 → Jan 2024 → ...), so LAG(revenue, 1) always pulls the immediately preceding calendar month's revenue, even across a year boundary.
```
LAG(revenue, 1) OVER (ORDER BY year, month) AS past_revenue
```

### 2. Matching Events to Orders with No Direct Common Link


**The problem:** Purchase events and order creation timestamps are a few seconds to minutes apart, and there's no common variable that could link the specific rows for `events` and `orders`. A simple join on `user_id` alone would multiply every purchase event by every order that user ever placed, producing meaningless rows.

**The fix:** I used `ROW_NUMBER()` partitioned by `user_id`, `created_at`, and `traffic_source` from the events side, ordered by the absolute time difference (`ABS(TIMESTAMP_DIFF(...))`) between the event and each candidate order. This creates a "nearest-match" ranking per purchase event, and keeping only `rank = 1` isolates the single closest order to each event, thus eliminating the duplicate rows a naive join would produce.

Just as important: I filtered to `status = 'Complete'` *inside* the CTE, before ranking. Filtering after ranking would risk letting a closer but cancelled order win the match over a slightly later completed one, which would silently misattribute cancelled traffic as a successful conversion. Filtering first ensures only completed orders are ever eligible to be matched.

For marketing attribution, this is the difference between "this channel drives traffic" and "this channel drives *sales*." Aggregating the cleaned, correctly-matched data by traffic source shows which channels aren't just sending visitors, but actually converting them into completed purchases.

### 3. A Join That Silently Over-Counts

**The problem:** Joining `events` to `orders` on `user_id` alone doesn't specify *which* event corresponds to *which* order, it just returns every combination of matching rows for that user. If a user has, say, 3 cancelled orders and 3 logged events (e.g. from home, work, and phone), the join produces all 3 × 3 = 9 combinations, pairing every IP with every order regardless of whether that IP was actually used for that specific order. The result: each IP gets credited with all 3 cancelled orders, when in reality only one order may have come from each IP. Worse, this inflation isn't a fixed multiplier, it scales with however many events and orders each individual user has, so the distortion is inconsistent across the dataset rather than a simple, predictable bias. For a fraud-detection query specifically, this is a serious problem: an innocent IP could be flagged as high-risk purely because it belongs to a user who happened to generate a lot of event data, not because it was actually involved in the orders being counted.

**The fix:** I used the same nearest-timestamp-match pattern from the traffic source query in the Customer Behaviour section: a `ROW_NUMBER()` window function, partitioned by `order_id` and ordered by the absolute time difference between the order's `created_at` and each candidate event's `created_at`. Keeping only `rank = 1` per order ensures each cancelled/returned order is matched to the single event (and therefore IP address) most likely to be actually associated with it, rather than every IP the user has ever used.

```sql
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
```

Fraud and risk analysis depends on precision. A query that over-attributes cancelled orders to the wrong IPs could send an investigation down the wrong path or wrongly flag an innocent connection. Matching each order to its single closest event keeps the counts accurate and trustworthy before any business decision is made on top of them.



