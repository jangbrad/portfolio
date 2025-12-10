--Detect customers with irregular activity gaps--

WITH numbered AS (
    SELECT
        customer_id,
        transaction_id,
        transaction_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY transaction_date) AS rn
    FROM transactions
),

days_btw AS(
SELECT
    t1.customer_id,
    t1.transaction_date AS current_txn,
    t2.transaction_date AS next_txn,
    DATEDIFF(t2.transaction_date, t1.transaction_date) AS days_between
FROM numbered t1
JOIN numbered t2
    ON t1.customer_id = t2.customer_id
   AND t2.rn = t1.rn + 1
ORDER BY t1.customer_id, t1.transaction_date
)

SELECT customer_id,
    CASE
    	WHEN days_between > 30 THEN 'IRREGULAR'
        ELSE 'REGULAR'
    END AS Churn_status
FROM days_btw

--Ranking customers by total spend within their relative tier--

WITH total_spend AS (
	SELECT c.customer_id,
		c.first_name,
    	c.last_name,
  		c.tier,
    	SUM(t.amount) as amount
	FROM customers c
		JOIN transactions t on c.customer_id = t.customer_id
	GROUP BY c.customer_id,
		c.first_name,
   	 	c.last_name,
  		c.tier
 )

SELECT customer_id,
	first_name,
    last_name,
    amount,
    tier,
    amount,
    DENSE_RANK() OVER (PARTITION BY tier ORDER BY amount) as tier_rank
FROM total_spend

--Period-over-Period Comparisons--

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    LAG(amount) OVER (PARTITION BY customer_id ORDER BY transaction_date) AS prev_amount,
    amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY transaction_date) AS change_amount
FROM transactions
ORDER BY customer_id, transaction_date;    
    
 --Moving Averages--
 
 SELECT
    customer_id,
    transaction_date,
    amount,
    ROUND(AVG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3
FROM transactions
ORDER BY customer_id, transaction_date;