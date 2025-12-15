-- change over time trend 

SELECT
YEAR(order_date) as order_year,
MONTh(order_date) as order_month,
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTh(order_date)
ORDER BY YEAR(order_date), MONTh(order_date)
;
--calculating the total sales per month
-- and the running total

SELECT
order_date,
total_sales,
SUM(total_sales) OVER (ORDER BY order_date) as running_total_sales,
AVG(avg_price) OVER (ORDER BY order_date) as moving_average_price
FROM
(
SELECT
DATETRUNC(year, order_date) as order_date,
SUM(sales_amount) as total_sales,
AVG(price) as avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year, order_date)
) t
;
-- performance analysiｓ
-- analysing yearly performance of products

WITH yearly_product_sales as (
SELECT
YEAR(fs.order_date) as order_year,
p.product_name,
SUM(fs.sales_amount) as current_sales
FROM gold.fact_sales fs
	LEFT JOIN gold.dim_products p ON fs.product_key = p.product_key 
WHERE fs.order_date IS NOT NULL
GROUP BY YEAR(fs.order_date), p.product_name
)

SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) as avg_sales,
current_sales - AVG(current_sales) OVER(PARTITION BY product_name) as diff_avg,
CASE
	WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0  THEN 'Above AVG'
	WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0  THEN 'Below AVG'
	ELSE 'AVG'
END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as diff_py,
CASE
	WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0  THEN 'Increase'
	WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0  THEN 'Decrease'
	ELSE 'No change'
END py_change
FROM yearly_product_sales
ORDER BY product_name, order_year

-- categories contributing most to sales

WITH category_sales as (
SELECT
category,
SUM(sales_amount) total_sales
FROM gold.fact_sales fs
	LEFT JOIN gold.dim_products p ON fs.product_key = p.product_key
GROUP BY category
)

SELECT
category,
total_sales,
SUM(total_sales) OVER () overall_sales,
CONCAT(ROUND((CAST (total_sales as FLOAT) / SUM(total_sales) OVER ()) * 100,2), '%') as percentage_of_total
FROM category_sales
ORDER BY total_sales DESC
;
-- segmenting products into cost ranges and counting products

WITH product_segment as (
SELECT
product_key,
product_name,
cost,
CASE
	WHEN cost < 100 THEN 'Below 100'
	WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	ELSE 'Above 1000'
END cost_range
FROM gold.dim_products
)

SELECT
cost_range,
COUNT(product_key) as total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC
;
-- segmenting customers into VIP, regular and new using subquery and CTE 

WITH customer_spending as (
SELECT 
c.customer_key,
SUM(fs.sales_amount) AS total_spend,
MIN(order_date) first_order,
MAX(order_date) last_order,
DATEDIFF(month,MIN(order_date), MAX(order_date)) as life_span_month
FROM gold.fact_sales fs
	LEFT JOIN gold.dim_customers c on fs.customer_key = c.customer_key
GROUP BY c.customer_key
)

SELECT
customer_segment,
COUNT(customer_key) as total_customer
FROM (
	SELECT
	customer_key,
	CASE
		WHEN life_span_month >= 12 AND total_spend > 5000 THEN 'VIP'
		WHEN life_span_month >= 12 AND total_spend <= 5000 THEN 'Regular'
		ELSE 'New'
	END customer_segment
	FROM customer_spending
	) t
GROUP BY customer_segment
ORDER BY total_customer DESC
