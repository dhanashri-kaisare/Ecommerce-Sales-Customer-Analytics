-- E-Commerce Sales & Customer Analytics (PostgreSQL)

-- 1. Identify repeat buyers and rank orders per customer using ROW_NUMBER()
WITH CustomerOrderSequence AS (
    SELECT 
        order_id,
        customer_id,
        order_date,
        total_amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY order_date ASC
        ) AS order_sequence
    FROM orders
)
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders,
    SUM(total_amount) AS customer_lifetime_value,
    CASE 
        WHEN MAX(order_sequence) > 1 THEN 'Repeat Customer'
        ELSE 'One-Time Customer'
    END AS customer_segment
FROM CustomerOrderSequence
GROUP BY customer_id;

-- 2. Rank top-spending customers per product category using DENSE_RANK()
WITH CategorySpending AS (
    SELECT 
        p.category,
        o.customer_id,
        ROUND(SUM(oi.quantity * oi.unit_price)::numeric, 2) AS total_spent,
        DENSE_RANK() OVER (
            PARTITION BY p.category 
            ORDER BY SUM(oi.quantity * oi.unit_price) DESC
        ) AS spending_rank
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.category, o.customer_id
)
SELECT category, customer_id, total_spent, spending_rank
FROM CategorySpending
WHERE spending_rank <= 3;

-- 3. Core Business Metrics: Average Order Value (AOV) & monthly revenue
SELECT 
    DATE_TRUNC('month', order_date) AS sales_month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_amount)::numeric, 2) AS gross_revenue,
    ROUND((SUM(total_amount) / NULLIF(COUNT(DISTINCT order_id), 0))::numeric, 2) AS average_order_value
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY sales_month ASC;
