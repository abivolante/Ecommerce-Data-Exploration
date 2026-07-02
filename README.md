# Ecommerce Dataset Exploration
This is a data exploration project of the data set: **The Look Ecommerce** publicly available on Google BigQuery. We will be answering common business questions regarding:
- Sales and Business Performance
- Customer Behaviour and Retention
- Risk and Anomalies

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

## Results
We identify the five product categories that have generated the most sales for the company.

<img width="1011" height="293" alt="Screenshot 2026-07-02 at 2 18 27 PM" src="https://github.com/user-attachments/assets/173cea0b-823b-4a87-9018-674cdf2ce405" />

Average order value (AOV) for each distinct country in the system
<img width="825" height="487" alt="Screenshot 2026-07-02 at 3 10 07 PM" src="https://github.com/user-attachments/assets/f611691c-ef47-4285-8011-c6ee40e9fcc9" />

Top 10 highest-spending customers based on their lifetime purchase history
<img width="785" height="375" alt="Screenshot 2026-07-02 at 3 11 39 PM" src="https://github.com/user-attachments/assets/8c8f7321-baa0-4c94-99e6-af02bbf78df2" />

