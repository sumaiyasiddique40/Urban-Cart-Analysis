-- 1. Total orders received
SELECT COUNT(order_id) AS total_orders FROM "FactOrders";

-- 2. Unique customers who placed at least one order
SELECT COUNT(DISTINCT customer_id) AS unique_customers FROM "FactOrders";

-- 3. Cities generating the highest number of orders
SELECT c.city, COUNT(o.order_id) AS order_count
FROM "DimCustomers" c
JOIN "FactOrders" o ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY order_count DESC;

-- 4. Percentage of customers with more than one order
SELECT 
    ROUND((COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0 / COUNT(*)),2) AS pct_repeat_customers
FROM (
    SELECT customer_id, COUNT(order_id) AS order_count
    FROM "FactOrders"
    GROUP BY customer_id
) sub;

-- 5. Monthly trend of total orders
SELECT TO_CHAR(order_date, 'YYYY-MM') AS month, COUNT(order_id) AS total_orders
FROM "FactOrders"
GROUP BY month
ORDER BY month;

-- 6. Total revenue generated
SELECT ROUND(SUM(oi.quantity * p.unit_price),2) AS total_revenue
FROM "FactOrderItems" oi
JOIN "DimProducts" p ON oi.product_id = p.product_id;

-- 7. Revenue by product category
SELECT p.category, ROUND(SUM(oi.quantity * p.unit_price),2) AS category_revenue
FROM "FactOrderItems" oi
JOIN "DimProducts" p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- 8. Top 5 individual products by revenue
SELECT p.product_name, ROUND(SUM(oi.quantity * p.unit_price),2) AS product_revenue
FROM "FactOrderItems" oi
JOIN "DimProducts" p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY product_revenue DESC
LIMIT 5;

-- 9. Average Order Value (AOV) and Average Basket Size
SELECT 
   ROUND(AVG(order_total),2) AS average_order_value,
    ROUND(AVG(total_quantity),2) AS average_basket_size
FROM (
    SELECT oi.order_id,ROUND(SUM(oi.quantity * p.unit_price),2) AS order_total, ROUND(SUM(oi.quantity),2) AS total_quantity
    FROM "FactOrderItems" oi
    JOIN "DimProducts" p ON oi.product_id = p.product_id
    GROUP BY oi.order_id
) sub;

-- 10. Products at risk of stock-out (High sales vs Low stock)
SELECT p.product_name, p.stock, SUM(oi.quantity) AS total_sold
FROM "DimProducts" p
JOIN "FactOrderItems" oi ON p.product_id = oi.product_id
GROUP BY p.product_name, p.stock
HAVING p.stock < SUM(oi.quantity)
ORDER BY p.stock ASC;

-- 11. Top revenue-contributing customers
SELECT c.full_name, SUM(oi.quantity * p.unit_price) AS total_spent
FROM "DimCustomers" c
JOIN "FactOrders" o ON c.customer_id = o.customer_id
JOIN "FactOrderItems" oi ON o.order_id = oi.order_id
JOIN "DimProducts" p ON oi.product_id = p.product_id
GROUP BY c.full_name
ORDER BY total_spent DESC
LIMIT 10;

-- 12. Average number of products purchased per order
SELECT ROUND(AVG(items_per_order),2) FROM (
    SELECT order_id, COUNT(product_id) AS items_per_order
    FROM "FactOrderItems"
    GROUP BY order_id
) sub;

-- 13. Purchasing patterns by Gender and Category
SELECT 
    c."Gender",
    p."category",
    COUNT(oi.order_item_id) AS total_purchases
FROM "DimCustomers" c
JOIN "FactOrders" o 
    ON c.customer_id = o.customer_id
JOIN "FactOrderItems" oi 
    ON o.order_id = oi.order_id
JOIN "DimProducts" p 
    ON oi.product_id = p.product_id
GROUP BY 
    c."Gender", 
    p."category"
ORDER BY 
    c."Gender", 
    total_purchases DESC;

-- 14. City-wise AOV
SELECT 
    c."city",
    ROUND(AVG(ot.order_total), 2) AS city_aov
FROM "DimCustomers" c
JOIN "FactOrders" o 
    ON c."customer_id" = o."customer_id"
JOIN (
    SELECT 
        oi."order_id",
        SUM(oi."quantity" * p."unit_price") AS order_total
    FROM "FactOrderItems" oi
    JOIN "DimProducts" p 
        ON oi."product_id" = p."product_id"
    GROUP BY oi."order_id"
) ot 
    ON o."order_id" = ot."order_id"
GROUP BY c."city"
ORDER BY city_aov DESC;

-- 15. Behavior change over time (Months since signup)
SELECT
    EXTRACT(
        MONTH FROM AGE(
            o."order_date",
            c."created_at"::timestamp
        )
    ) AS months_active,
    ROUND(SUM(oi."quantity" * p."unit_price"), 2) AS revenue
FROM "DimCustomers" c
JOIN "FactOrders" o
    ON c."customer_id" = o."customer_id"
JOIN "FactOrderItems" oi
    ON o."order_id" = oi."order_id"
JOIN "DimProducts" p
    ON oi."product_id" = p."product_id"
WHERE o."order_date" IS NOT NULL
  AND c."created_at" IS NOT NULL
GROUP BY months_active
ORDER BY months_active;

-- 16. Payment method frequency
SELECT method, COUNT(*) AS usage_count 
FROM "FactPayment" 
GROUP BY 1 
ORDER BY 2 DESC;

-- 17. Payment Method vs Status
SELECT py.method, o.status, COUNT(*) FROM "FactPayment" py
JOIN "FactOrders" o 
ON py.order_id = o.order_id 
GROUP BY 1, 2 
ORDER BY count;

-- 18. City-wise payment preference
SELECT c.city, py.method, COUNT(*) 
FROM "DimCustomers" c
JOIN "FactOrders" o ON c.customer_id = o.customer_id
JOIN "FactPayment" py ON o.order_id = py.order_id 
GROUP BY 1, 2
ORDER BY count;

-- 19. Payment method vs Order Value
SELECT py.method, ROUND(AVG(ot.order_total), 2) AS avg_val
FROM "FactPayment" py JOIN (
    SELECT order_id, SUM(quantity * unit_price) AS order_total 
    FROM "FactOrderItems" oi 
	JOIN "DimProducts" p 
	ON oi.product_id = p.product_id 
	GROUP BY 1
) ot ON py.order_id = ot.order_id 
GROUP BY 1
ORDER BY avg_val;

-- 20. Avg items per order by payment
SELECT py.method, ROUND(AVG(item_count), 2) AS avg_items
FROM "FactPayment" py 
JOIN (
    SELECT order_id, SUM(quantity) AS item_count 
	FROM "FactOrderItems" GROUP BY 1
) it ON py.order_id = it.order_id 
GROUP BY 1
ORDER BY avg_items DESC;


-- 21 & 22. Frequent Product Pairs
SELECT p1.product_name AS p_a, p2.product_name AS p_b, COUNT(*) AS freq
FROM "FactOrderItems" oi1
JOIN "FactOrderItems" oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN "DimProducts" p1 ON oi1.product_id = p1.product_id
JOIN "DimProducts" p2 ON oi2.product_id = p2.product_id
GROUP BY 1, 2 
ORDER BY 3 DESC LIMIT 10;

-- 23. Pairs driving high order value
SELECT p1.product_name, p2.product_name, ROUND(SUM((oi1.quantity * p1.unit_price) + (oi2.quantity * p2.unit_price)), 2) AS pair_rev
FROM "FactOrderItems" oi1
JOIN "FactOrderItems" oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN "DimProducts" p1 ON oi1.product_id = p1.product_id
JOIN "DimProducts" p2 ON oi2.product_id = p2.product_id
GROUP BY 1, 2 
ORDER BY 3 DESC LIMIT 10;

-- 24. Recommended Bundles (Cross-category)
SELECT p1.product_name, p2.product_name, COUNT(*) AS freq
FROM "FactOrderItems" oi1
JOIN "FactOrderItems" oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN "DimProducts" p1 ON oi1.product_id = p1.product_id
JOIN "DimProducts" p2 ON oi2.product_id = p2.product_id
WHERE p1.category != p2.category
GROUP BY 1, 2 
ORDER BY 3 DESC LIMIT 5;

-- 25. Cross-selling Promotion Strategy
SELECT p1.product_name, p2.product_name, COUNT(*) AS frequency
FROM "FactOrders" o
JOIN "FactOrderItems" oi1 ON o.order_id = oi1.order_id
JOIN "FactOrderItems" oi2 ON o.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN "DimProducts" p1 ON oi1.product_id = p1.product_id
JOIN "DimProducts" p2 ON oi2.product_id = p2.product_id
WHERE o.status = 'Completed'
GROUP BY 1, 2 
ORDER BY 3 DESC LIMIT 10;














