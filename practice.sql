-- Conditional Expressions: COALESCCE, NULLIF, CASE
WITH sales_data AS (
SELECT customerkey, SUM(quantity * netprice * exchangerate) AS net_revenue
FROM sales
GROUP BY customerkey
)

SELECT AVG(s.net_revenue) AS spending_customers_avg_net_revenue,
AVG(COALESCE(s.net_revenue, 0)) AS all_customers_avg_net_revenue
FROM customer c
LEFT JOIN sales_data s ON c.customerkey = s.customerkey;

-- DROP VIEW IF EXISTS cohort_analysis;

CREATE OR REPLACE VIEW public.cohort_analysis AS  --create view as cohort_analysis
WITH customer_revenue AS (
SELECT s.customerkey, s.orderdate,
SUM(s.quantity * s.netprice * s.exchangerate) AS total_net_revenue,
COUNT(s.orderkey) AS num_orders, c.countryfull, c.age, 
CONCAT(TRIM(c.givenname), ' ', TRIM(c.surname)) AS cleanned_name
FROM sales s 
LEFT JOIN customer c ON c.customerkey = s.customerkey
GROUP BY s.customerkey, s.orderdate, c.countryfull, c.age,
c.givenname, c.surname
)

SELECT cr.*, MIN(cr.orderdate) OVER (PARTITION BY cr.customerkey) AS first_purchase_date,
EXTRACT(YEAR FROM MIN(cr.orderdate) OVER (PARTITION BY cr.customerkey)) AS cohort_year
FROM customer_revenue cr; 

EXPLAIN ANALYZE
SELECT customerkey, SUM(quantity * netprice * exchangerate) AS net_revenue
FROM sales
WHERE orerdate >= '2024-01-01'
GROUP BY customerkey;

EXPLAIN ANALYZE
SELECT customerkey, SUM(quantity * netprice * exchangerate) AS net_revenue
FROM sales
GROUP BY customerkey
WHERE customerkey < 100
LIMIT 10;

EXPLAIN ANALYZE
SELECT customerkey, orderdate, orderkey, SUM(quantity * netprice * exchangerate) AS net_revenue
FROM sales
GROUP BY customerkey, orderdate, orderkey
ORDER BY net_revenue DESC, customerkey, orderdate, orderkey;

EXPLAIN ANALYZE
WITH customer_revenue AS (
SELECT s.customerkey, s.orderdate,
SUM(s.quantity * s.netprice * s.exchangerate) AS total_net_revenue,
COUNT(s.orderkey) AS num_orders, MAX(c.countryfull) AS countryfull, MAX(c.age) AS age, 
MAX(c.givenname) AS givenname, MAX(c.surname) AS surname
FROM sales s 
LEFT JOIN customer c ON c.customerkey = s.customerkey
GROUP BY s.customerkey, s.orderdate
)

SELECT customerkey, orderdate, total_net_revenue, num_orders, countryfull,
CONCAT(TRIM(BOTH FROM c.givenname), ' ', TRIM(BOTH FROM c.surname)) AS cleanned_name,
MIN(cr.orderdate) OVER (PARTITION BY cr.customerkey) AS first_purchase_date,
EXTRACT(YEAR FROM MIN(cr.orderdate) OVER (PARTITION BY cr.customerkey)) AS cohort_year
FROM customer_revenue cr; 