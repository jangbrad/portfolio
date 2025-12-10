--Standardize capitalisation--

UPDATE transactions
SET complete_status =
	CONCAT(UPPER(LEFT(complete_status,1)),LOWER(SUBSTRING(complete_status,2)));

--replacing null transactions with avg--
UPDATE transactions
SET amount = (
    SELECT AVG(a.amount)
    FROM (SELECT amount FROM transactions WHERE amount IS NOT NULL) a
)
WHERE amount IS NULL;

--removing duplicate transactions--
SELECT
	customer_id,
    amount,
    transaction_date,
    count(*) as cnt
FROM transactions
GROUP BY customer_id,
    amount,
    transaction_date
HAVING cnt >1;

DELETE t1 FROM transactions t1
JOIN transactions t2
ON t1.customer_id = t2.customer_id
AND t1.amount = t2.amount
AND t1.transaction_date = t2.transaction_date
AND t1.transaction_id > t2.transaction_id;

--rectifying the wrong date format--
ALTER TABLE transactions
ADD clean_date DATE;

UPDATE transactions
SET clean_date = 
	CASE
    	WHEN TRIM(transaction_date) LIKE '%-%-%'
        	THEN STR_TO_DATE(transaction_date, '%Y-%m-%d')
		WHEN TRIM(transaction_date) LIKE '__-__-____'
        	THEN STR_TO_DATE(transaction_date, '%m-%d-%Y')
        WHEN TRIM(transaction_date) LIKE '%/%/%'
        	THEN STR_TO_DATE(transaction_date, '%Y/%m/%d')
      	ELSE NULL
	END;

ALTER TABLE transactions DROP COLUMN transaction_date;

ALTER TABLE transactions 
CHANGE COLUMN clean_date transaction_date DATE;


    