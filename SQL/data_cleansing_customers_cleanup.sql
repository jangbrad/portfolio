--Removing Extra Spaces--

UPDATE customers 
SET first_name = TRIM(first_name),
    last_name = TRIM(last_name),
    email = TRIM(email),
    phone = TRIM(phone);
	
--Replace missing entries with placeholders--

UPDATE customers
SET first_name = CASE
                     WHEN first_name IS NULL OR first_name = '' THEN 'Unknown'
                     ELSE first_name
                 END,
    last_name = CASE
                     WHEN last_name IS NULL OR last_name = '' THEN 'Unknown'
                     ELSE last_name
                END,
        email = CASE
                     WHEN email IS NULL OR email = '' THEN 'Unknown'
                     ELSE email
                END;
				
--Standardize capitalisation for first_name and last_name--

UPDATE customers
SET first_name = CONCAT(
  UPPER(LEFT(first_name,1)),
  LOWER(SUBSTRING(first_name,2))
);

UPDATE customers
SET last_name = CONCAT(
  UPPER(LEFT(last_name,1)),
  LOWER(SUBSTRING(last_name,2))
);

--Standardise signup_date format to (YYYY-MM-DD)--

UPDATE customers
SET signup_date = STR_TO_DATE(signup_date, '%Y/%m/%d')
WHERE signup_date LIKE '%/%';

UPDATE customers
SET signup_date = STR_TO_DATE(signup_date, '%d-%m-%Y')
WHERE signup_date LIKE '__-__-____';

UPDATE customers
SET signup_date = STR_TO_DATE(signup_date, '%Y-%m-%d')
WHERE signup_date IS NOT NULL;

--Review cleaned table--
SELECT *
FROM customers