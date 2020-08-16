### CLEANING UP DATA

-- In the accounts table, there is a column holding the website for each company. The last three digits specify what type of web address they are using. A list of extensions (and pricing) is provided here. Pull these extensions and provide how many of each website type exist in the accounts table.
SELECT RIGHT(website, 3) web_ext, COUNT(*)
FROM accounts
GROUP BY 1;

-- There is much debate about how much the name (or even the first letter of a company name) matters. Use the accounts table to pull the first letter of each company name to see the distribution of company names that begin with each letter (or number).
SELECT LEFT(name, 1) first_init, COUNT(*)
FROM accounts
GROUP BY 1
ORDER BY 1;

-- Use the accounts table and a CASE statement to create two groups: one group of company names that start with a number and a second group of those company names that start with a letter. What proportion of company names start with a letter?
SELECT CASE WHEN LEFT(name, 1) BETWEEN 'A' AND 'Z' THEN 'Letter First' ELSE 'Number First' END, COUNT(*)
FROM accounts
GROUP BY 1;

-- Consider vowels as a, e, i, o, and u. What proportion of company names start with a vowel, and what percent start with anything else?
SELECT CASE WHEN LEFT(UPPER(name), 1) IN ('A','E','I','O','U') THEN 'Vowel First' ELSE 'Not Vowel First' END, COUNT(*)
FROM accounts
GROUP BY 1;

-- Use the accounts table to create first and last name columns that hold the first and last names for the primary_poc.
SELECT LEFT(primary_poc, POSITION(' ' IN primary_poc) -1) , RIGHT(primary_poc, LENGTH(primary_poc) - POSITION(' ' IN primary_poc))
FROM accounts;

-- Now see if you can do the same thing for every rep name in the sales_reps table. Again provide first and last name columns.
SELECT LEFT(name, POSITION(' ' IN name) -1) , RIGHT(name, LENGTH(name) - POSITION(' ' IN name))
FROM sales_reps;

-- Each company in the accounts table wants to create an email address for each primary_poc. The email address should be the first name of the primary_poc . last name primary_poc @ company name .com.
SELECT LOWER(LEFT(primary_poc, POSITION(' ' IN primary_poc) -1)) ||'.' || LOWER(RIGHT(primary_poc, LENGTH(primary_poc) - POSITION(' ' IN primary_poc))) || '@' || LOWER(name) || '.com' poc_email_address
FROM accounts;

-- You may have noticed that in the previous solution some of the company names include spaces, which will certainly not work in an email address. See if you can create an email address that will work by removing all of the spaces in the account name, but otherwise your solution should be just as in question 1. Some helpful documentation is here.
SELECT LOWER(LEFT(primary_poc, POSITION(' ' IN primary_poc) -1)) ||'.' || LOWER(RIGHT(primary_poc, LENGTH(primary_poc) - POSITION(' ' IN primary_poc))) || '@' || LOWER(REPLACE(name,' ','')) || '.com' poc_email_address
FROM accounts;

-- We would also like to create an initial password, which they will change after their first log in. The first password will be the first letter of the primary_poc's first name (lowercase), then the last letter of their first name (lowercase), the first letter of their last name (lowercase), the last letter of their last name (lowercase), the number of letters in their first name, the number of letters in their last name, and then the name of the company they are working with, all capitalized with no spaces.
SELECT LOWER(LEFT(primary_poc, POSITION(' ' IN primary_poc) -1)) ||'.' || LOWER(RIGHT(primary_poc, LENGTH(primary_poc) - POSITION(' ' IN primary_poc))) || '@' || LOWER(REPLACE(name,' ','')) || '.com' poc_email_address, LEFT(LOWER(LEFT(primary_poc, POSITION(' ' IN primary_poc) -1)),1) || RIGHT(LOWER(LEFT(primary_poc, POSITION(' ' IN primary_poc) -1)),1) || LEFT(LOWER(RIGHT(primary_poc, LENGTH(primary_poc) - POSITION(' ' IN primary_poc))),1) || RIGHT(LOWER(RIGHT(primary_poc, LENGTH(primary_poc) - POSITION(' ' IN primary_poc))),1) || LENGTH(LOWER(LEFT(primary_poc, POSITION(' ' IN primary_poc) -1))) || LENGTH(LOWER(RIGHT(primary_poc, LENGTH(primary_poc) - POSITION(' ' IN primary_poc)))) || UPPER(REPLACE(name,' ','')) init_pwd
FROM accounts;

-- TEXTBOOK USES WITH STATEMENTS SUCH AS
WITH t1 AS (
 SELECT LEFT(primary_poc,     STRPOS(primary_poc, ' ') -1 ) first_name,  RIGHT(primary_poc, LENGTH(primary_poc) - STRPOS(primary_poc, ' ')) last_name, name
 FROM accounts)
SELECT first_name, last_name, CONCAT(first_name, '.', last_name, '@', name, '.com'), LEFT(LOWER(first_name), 1) || RIGHT(LOWER(first_name), 1) || LEFT(LOWER(last_name), 1) || RIGHT(LOWER(last_name), 1) || LENGTH(first_name) || LENGTH(last_name) || REPLACE(UPPER(name), ' ', '')
FROM t1;

-- Quiz at the end of the CAST lesson regarding SF Crime Data and date formatting
SELECT *
FROM sf_crime_data
LIMIT 10;
-- yyyy-mm-dd

-- The format of the date column is mm/dd/yyyy with times that are not correct also at the end of the date.
SELECT date orig_date, (SUBSTR(date, 7, 4) || '-' || LEFT(date, 2) || '-' || SUBSTR(date, 4, 2)) new_date
FROM sf_crime_data;

-- Notice, this new date can be operated on using DATE_TRUNC and DATE_PART in the same way as earlier lessons.
SELECT date orig_date, (SUBSTR(date, 7, 4) || '-' || LEFT(date, 2) || '-' || SUBSTR(date, 4, 2))::DATE new_date
FROM sf_crime_data;


-- Finds the entry that has a blank total order (which leaves it out of a regular JOIN on id values)
SELECT *
FROM accounts a
LEFT JOIN orders o
ON a.id = o.account_id
WHERE o.total IS NULL;

-- Fills in the blank order with the corect account ID
SELECT COALESCE(a.id, a.id) filled_id, a.name, a.website, a.lat, a.long, a.primary_poc, a.sales_rep_id, o.*
FROM accounts a
LEFT JOIN orders o
ON a.id = o.account_id
WHERE o.total IS NULL;

-- Fills in the account_id for the order that was left null
SELECT COALESCE(a.id, a.id) filled_id, a.name, a.website, a.lat, a.long, a.primary_poc, a.sales_rep_id, COALESCE(o.account_id, a.id) account_id, o.occurred_at, o.standard_qty, o.gloss_qty, o.poster_qty, o.total, o.standard_amt_usd, o.gloss_amt_usd, o.poster_amt_usd, o.total_amt_usd
FROM accounts a
LEFT JOIN orders o
ON a.id = o.account_id
WHERE o.total IS NULL;

-- Fills in the order quantities and amounts to accurate represent an empty order, instead of leaving them null
SELECT COALESCE(a.id, a.id) filled_id, a.name, a.website, a.lat, a.long, a.primary_poc, a.sales_rep_id, COALESCE(o.account_id, a.id) account_id, o.occurred_at, COALESCE(o.standard_qty, 0) standard_qty, COALESCE(o.gloss_qty,0) gloss_qty, COALESCE(o.poster_qty,0) poster_qty, COALESCE(o.total,0) total, COALESCE(o.standard_amt_usd,0) standard_amt_usd, COALESCE(o.gloss_amt_usd,0) gloss_amt_usd, COALESCE(o.poster_amt_usd,0) poster_amt_usd, COALESCE(o.total_amt_usd,0) total_amt_usd
FROM accounts a
LEFT JOIN orders o
ON a.id = o.account_id
WHERE o.total IS NULL;

-- Shows the total number of orders and accounts without orders (6913) compared to number of orders (6912)
SELECT COUNT(*)
FROM accounts a
LEFT JOIN orders o
ON a.id = o.account_id;

-- COMPLETELY REPAIRED the null order and added it to the other orders, so now the order list is complete
SELECT COALESCE(a.id, a.id) filled_id, a.name, a.website, a.lat, a.long, a.primary_poc, a.sales_rep_id, COALESCE(o.account_id, a.id) account_id, o.occurred_at, COALESCE(o.standard_qty, 0) standard_qty, COALESCE(o.gloss_qty,0) gloss_qty, COALESCE(o.poster_qty,0) poster_qty, COALESCE(o.total,0) total, COALESCE(o.standard_amt_usd,0) standard_amt_usd, COALESCE(o.gloss_amt_usd,0) gloss_amt_usd, COALESCE(o.poster_amt_usd,0) poster_amt_usd, COALESCE(o.total_amt_usd,0) total_amt_usd
FROM accounts a
LEFT JOIN orders o
ON a.id = o.account_id;
