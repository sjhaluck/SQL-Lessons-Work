### SUBQUERIES AND TEMP TABLES

-- First, we needed to group by the day and channel. Then ordering by the number of events (the third column) gave us a quick way to answer the first question.
SELECT DATE_TRUNC('day',occurred_at) AS day,
   channel, COUNT(*) as events
FROM web_events
GROUP BY 1,2
ORDER BY 3 DESC;

-- Here you can see that to get the entire table in question 1 back, we included an * in our SELECT statement. You will need to be sure to alias your table.
SELECT *
FROM (SELECT DATE_TRUNC('day',occurred_at) AS day,
           channel, COUNT(*) as events
     FROM web_events
     GROUP BY 1,2
     ORDER BY 3 DESC) sub;

-- Finally, here we are able to get a table that shows the average number of events a day for each channel.
SELECT channel, AVG(events) AS average_events
FROM (SELECT DATE_TRUNC('day',occurred_at) AS day,
             channel, COUNT(*) as events
      FROM web_events
      GROUP BY 1,2) sub
GROUP BY channel
ORDER BY 2 DESC;

-- Here is the necessary quiz to pull the first month/year combo from the orders table.
SELECT DATE_TRUNC('month', MIN(occurred_at))
FROM orders;

-- Then to pull the average for each, we could do this all in one query, but for readability, I provided two queries below to perform each separately.
SELECT AVG(standard_qty) avg_std, AVG(gloss_qty) avg_gls, AVG(poster_qty) avg_pst
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
     (SELECT DATE_TRUNC('month', MIN(occurred_at)) FROM orders);

SELECT SUM(total_amt_usd)
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
      (SELECT DATE_TRUNC('month', MIN(occurred_at)) FROM orders);

-- Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.
SELECT rep_totals.rep_name, rep_totals.region_name, rep_totals.total_amt
FROM(SELECT region_name, MAX(total_amt) total_amt
     FROM(SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
             FROM sales_reps s
             JOIN accounts a
             ON a.sales_rep_id = s.id
             JOIN orders o
             ON o.account_id = a.id
             JOIN region r
             ON r.id = s.region_id
             GROUP BY 1, 2) rep_totals
     GROUP BY 1) region_max
JOIN (SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
        FROM sales_reps s
        JOIN accounts a
        ON a.sales_rep_id = s.id
        JOIN orders o
        ON o.account_id = a.id
        JOIN region r
        ON r.id = s.region_id
        GROUP BY 1, 2) rep_totals
ON rep_totals.region_name = region_max.region_name AND rep_totals.total_amt = region_max.total_amt;
-- WITH SOLTUION
WITH rep_totals AS (SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
        FROM sales_reps s
        JOIN accounts a
        ON a.sales_rep_id = s.id
        JOIN orders o
        ON o.account_id = a.id
        JOIN region r
        ON r.id = s.region_id
        GROUP BY 1, 2),

    region_max AS (SELECT region_name, MAX(total_amt) total_amt
         FROM rep_totals
         GROUP BY 1)

SELECT rep_totals.rep_name, rep_totals.region_name, rep_totals.total_amt
FROM region_max
JOIN rep_totals
ON rep_totals.region_name = region_max.region_name AND rep_totals.total_amt = region_max.total_amt;



-- For the region with the largest (sum) of sales total_amt_usd, how many total (count) orders were placed?
SELECT r.name, COUNT(*)
FROM orders o
JOIN accounts a
ON o.account_id = a.id
JOIN sales_reps s
ON a.sales_rep_id = s.id
JOIN region r
ON s.region_id = r.id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (
  SELECT MAX(total_sales)
  FROM (SELECT r.name, SUM(total_amt_usd) total_sales
        FROM orders o
        JOIN accounts a
        ON o.account_id = a.id
        JOIN sales_reps s
        ON a.sales_rep_id = s.id
        JOIN region r
        ON s.region_id = r.id
        GROUP BY 1) total_reg_sales);
        --REMOVED A SUBQUERY BASESD ON SOLUTION FROM TEXTBOOK

-- TEXTBOOK SOLUTION
SELECT r.name, COUNT(o.total) total_orders
FROM sales_reps s
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = s.region_id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (
      SELECT MAX(total_amt)
      FROM (SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
              FROM sales_reps s
              JOIN accounts a
              ON a.sales_rep_id = s.id
              JOIN orders o
              ON o.account_id = a.id
              JOIN region r
              ON r.id = s.region_id
              GROUP BY r.name) sub);

-- WITH SOLUTION
WITH sub AS (SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
        FROM sales_reps s
        JOIN accounts a
        ON a.sales_rep_id = s.id
        JOIN orders o
        ON o.account_id = a.id
        JOIN region r
        ON r.id = s.region_id
        GROUP BY r.name)

SELECT r.name, COUNT(o.total) total_orders
FROM sales_reps s
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = s.region_id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (
      SELECT MAX(total_amt)
      FROM sub);


-- How many accounts had more total purchases than the account name which has bought the most standard_qty paper throughout their lifetime as a customer?
SELECT a.name, COUNT(*) order_count
FROM orders o
JOIN accounts a
ON o.account_id = a.id
GROUP BY 1
HAVING COUNT(*) >
  (SELECT sub.total_orders
   FROM (SELECT a.name, COUNT(*) total_orders, SUM(standard_qty) stand_total
    FROM orders o
    JOIN accounts a
    ON o.account_id = a.id
    GROUP BY 1
  	ORDER BY stand_total DESC
  	LIMIT 1) sub)
ORDER BY 2 DESC;

-- For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, how many web_events did they have for each channel?
SELECT channel, COUNT(*)
FROM web_events
WHERE account_id = (
  SELECT id
FROM (SELECT a.id, SUM(total_amt_usd)
  FROM orders o
  JOIN accounts a
  ON o.account_id = a.id
  GROUP BY 1
  ORDER BY 2 DESC
  LIMIT 1) sub)
GROUP BY 1;

-- What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?
SELECT AVG(life_total) avg_life_top_10_total
FROM (SELECT account_id, SUM(total_amt_usd) life_total
      FROM orders o
      GROUP BY account_id
      ORDER BY 2 DESC
      LIMIT 10) top_10_list;

-- What is the lifetime average amount spent in terms of total_amt_usd, including only the companies that spent more per order, on average, than the average of all orders.
SELECT AVG(sum)
FROM (SELECT SUM(total_amt_usd)
    FROM orders
    WHERE account_id IN (SELECT account_id
        FROM orders o
        GROUP BY 1
        HAVING AVG(total_amt_usd) >
            (SELECT AVG(total_amt_usd)
            FROM orders o))
    GROUP BY account_id) totals;

-- TEXTBOOK SOLUTION
SELECT AVG(avg_amt)
FROM (SELECT o.account_id, SUM(o.total_amt_usd) avg_amt
    FROM orders o
    GROUP BY 1
    HAVING AVG(o.total_amt_usd) > (SELECT AVG(o.total_amt_usd) avg_all
                                   FROM orders o)) temp_table;
