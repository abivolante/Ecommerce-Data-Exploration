# Ecommerce Dataset Exploration
This is a data exploration project of the data set: **The Look Ecommerce** publicly available on Google BigQuery. We will be answering common business questions regarding:
- Sales and Business Performance
- Customer Behaviour and Retention
- Risk and Anomalies

This data contains 7 tables:
- users (The Customer Profiles)
One row for every single person who has ever registered an account. This is where we'll get all your demographic data to find out who your customers are.
- orders (The Basket Summaries)
One row for every distinct checkout basket submitted by a user. This tracks high-level business volume and order success rates.
- order_items (The Individual Sales Ledger)
The is the most important table for revenue. If an order has 3 items in the basket, this table will show 3 individual rows for that single order_id.
We use this table to calculate financial metrics like total revenue, average order value, and product profit margins.
- products (The Inventory Catalog)
Thus contains a list of every single item of clothing available for sale on the website. We use this to order_items to see which brands or clothing categories are making the most money.
- distribution_centers (The Logistics Hubs)
This is a small reference table listing the physical warehouses where inventory is stored.
This is normally used by supply chain analysts to calculate shipping distances. In this project we will not be using this.
- inventory_items (The Warehouse Stock)
This is a live tracker of every physical piece of clothing sitting on a shelf in a warehouse. This tracks stock levels to ensure the website doesn't sell items that are out of stock.
- events (The Website Clickstream Logs)
This is the largest and messiest table. It records every single mouse click or screen tap a user makes on the website or mobile app.
We use this for behavioral analysis, mapping the customer journey, and spotting unusual activities.

