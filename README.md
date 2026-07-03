# Ecommerce Dataset Exploration
This project is a data exploration of **The Look Ecommerce** public dataset on Google BigQuery, built as a learning exercise to master SQL. I looked up common interesting questions that a business might find interesting across the three main common areas:

- Sales and Business Performance
- Customer Behaviour and Retention
- Risk and Anomalies

**Status: In Progress** — Sales & Business Performance section complete. 
Customer Behaviour/Retention and Risk/Anomalies sections in development.

## What is in the dataset?
- **users**
One row for every single person who has ever registered an account. This is where we'll get all your demographic data to find out who your customers are.
- **orders** (The Basket Summaries)
One row for every distinct checkout basket submitted by a user. This tracks high-level business volume and order success rates.
- **order_items** 
The is the most important table for revenue. If an order has 3 items in the basket, this table will show 3 individual rows for that single order_id.
We use this table to calculate financial metrics like total revenue, average order value, and product profit margins.
- **products** (The Inventory Catalog)
Thus contains a list of every single item of clothing available for sale on the website. We use this to order_items to see which brands or clothing categories are making the most money.
- **distribution_centers** 
This is a small reference table listing the physical warehouses where inventory is stored.
This is normally used by supply chain analysts to calculate shipping distances. We will not use this table for this project.
- **inventory_items** (The Warehouse Stock)
This is a live tracker of every physical piece of clothing sitting on a shelf in a warehouse. This tracks stock levels to ensure the website doesn't sell items that are out of stock.
- **events** (The Website Clickstream Logs)
This is the largest and messiest table. It records every single mouse click or screen tap a user makes on the website or mobile app.
We use this for behavioral analysis, mapping the customer journey, and spotting unusual activities.

## Sales and Business Performance Results
I first identified the five product categories that have generated the most sales for the company. I joined order_items to products on product_id to bring in category labels, then filtered to status = 'Complete' so cancelled/returned items don't inflate sales figures. Aggregated both unit count and gross revenue per category, ranked by revenue, and kept the top 5. Note that "Total sales volume" could mean units sold or revenue. I used revenue as the primary sort since it's usually the more relevant metric for businesses, but I kept total_units_sold in the output so both angles are visible.

<img width="1011" height="293" alt="Screenshot 2026-07-02 at 2 18 27 PM" src="https://github.com/user-attachments/assets/173cea0b-823b-4a87-9018-674cdf2ce405" />

I then calculated the Average Order Valie (AOV) for each distinct country in the system. Since country is readily available in the data, I thought that calculating this metric per country would allow us to easily localise business strategies. Here, AOV is defined as total revenue divided by distinct order count, not row count. This is important since order_items has one row per item, not per order. I joined order_items to users on user_id to get country, excluded Cancelled and Returned statuses (unlike the first query, I used a broader exclusion here rather than only keeping Complete, since Processing/Shipped orders still represent real committed revenue). Here, I noticed that countries with very few orders can produce a misleadingly high or low AOV (one large order can skew the whole average). For example, Spain has the highest AOV out of any country but only contain 3 orders so I included the HAVING COUNT(DISTINCT order_items.order_id) >= 50 to filter out countries with very little orders.

<img width="740" height="425" alt="aov" src="https://github.com/user-attachments/assets/f6602a08-a223-4244-8b72-38648d84adab" />

Here I looked at the top 10 highest-spending customers based on their lifetime purchase history. I joined order_items to users on user_id, excluded Cancelled/Returned orders (same reasoning as the second query), summed sale_price per customer, and took the top 10 by lifetime spend.

<img width="785" height="375" alt="Screenshot 2026-07-02 at 3 11 39 PM" src="https://github.com/user-attachments/assets/8c8f7321-baa0-4c94-99e6-af02bbf78df2" />


For this next query, I looked at month-over-month growth rate of completed sales. I built a monthly revenue total in table1 (Complete orders only), then used LAG() in table2 to pull the prior month's revenue for comparison, and calculated % growth = (current - prior) / prior. The earliest month in the dataset will show a null growth rate since there's no prior month to compare against. 

<img width="506" height="430" alt="month-over-month" src="https://github.com/user-attachments/assets/264b7a60-c473-4577-9f38-460cb1228716" />

## Customer Behaviour & Retention Results
*Coming soon*

## Risk & Anomalies Results
*Coming soon*

## Key SQL Techniques Used:

* **CTEs (Common Table Expressions**): Separated raw revenue aggregation from the window function logic in a second step, keeping the script readable and easy to debug independently.
* **Window Functions (LAG)**: Compared each month's revenue against the true immediately-preceding calendar month (ordered by year, month to avoid cross-year misalignment — see Technical Highlight below) to calculate period-over-period growth.

## Technical Highlights:  Getting Chronological Ordering Right in LAG()

The problem: Monthly revenue was extracted as two separate integer fields — EXTRACT(MONTH ...) and EXTRACT(YEAR ...). I initially sorted by month alone (since that's the value I ultimately care about comparing). But month only ranges 1–12 and repeats every year, so ordering by month alone would scramble the actual timeline: December 2023 could get placed next to December 2024 instead of next to January 2024, and LAG() would pull revenue from the wrong prior period entirely.
The fix: Window the LAG() function using ORDER BY year, month, treating year as the primary sort key and month as secondary. This guarantees the sequence is truly chronological (Jan 2023 → Feb 2023 → ... → Dec 2023 → Jan 2024 → ...), so LAG(revenue, 1) always pulls the immediately preceding calendar month's revenue, even across a year boundary.

```
LAG(revenue, 1) OVER (ORDER BY year, month) AS past_revenue
```



