/*
Customer Journey:
Task: Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
Output:
*/
-- YOUR ANSWER HERE
SELECT 
    s.customer_id,
    p.plan_name,
    s.start_date
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p 
ON s.plan_id = p.plan_id
WHERE s.customer_id IN (SELECT DISTINCT customer_id FROM foodie_fi.subscriptions LIMIT 8)
ORDER BY s.customer_id, s.start_date;


/*
Question 1: How many customers has Foodie-Fi ever had?
Output:
*/

-- YOUR ANSWER HERE
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM foodie_fi.subscriptions;


/*
Question 2: What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
Output:
*/
-- YOUR ANSWER HERE
SELECT 
    EXTRACT(MONTH FROM start_date) AS month_number,
    TO_CHAR(start_date, 'Month') AS month_name,
    COUNT(customer_id) AS customer_count
FROM foodie_fi.subscriptions
WHERE plan_id = (SELECT plan_id FROM foodie_fi.plans WHERE plan_name = 'trial')
GROUP BY month_number, month_name
ORDER BY month_number;


/*
Question 3: What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
Output:
*/
-- YOUR ANSWER HERE
SELECT 
    p.plan_name,
    COUNT(s.start_date) AS event_count
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM s.start_date) > 2020
GROUP BY p.plan_name
ORDER BY event_count DESC;


/*
Question 4: What is the customer count and percentage of customers who have churned rounded to 1 decimal place?\
Output:
*/
-- YOUR ANSWER HERE
WITH total_customers AS (
    SELECT COUNT(DISTINCT customer_id) AS total FROM foodie_fi.subscriptions
)
SELECT 
    COUNT(DISTINCT s.customer_id) AS churned_customers,
    ROUND(100.0 * COUNT(DISTINCT s.customer_id) / (SELECT total FROM total_customers), 1) AS churn_percentage
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'churn';


/*
Question 5: How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
Output:
*/
-- YOUR ANSWER HERE
WITH ranked_plans AS (
    SELECT 
        customer_id, 
        plan_id,
        RANK() OVER (PARTITION BY customer_id ORDER BY start_date) AS plan_rank
    FROM foodie_fi.subscriptions
)
SELECT 
    COUNT(CASE WHEN p.plan_name = 'churn' AND r.plan_rank = 2 THEN 1 END) AS churned_after_trial,
    ROUND(
        100.0 * COUNT(CASE WHEN p.plan_name = 'churn' AND r.plan_rank = 2 THEN 1 END) / COUNT(DISTINCT r.customer_id),
        0
    ) AS churn_percentage
FROM ranked_plans r
JOIN foodie_fi.plans p ON r.plan_id = p.plan_id;


/*
Question 6: What is the number and percentage of customer plans after their initial free trial?
Output:
*/
-- YOUR ANSWER HERE
WITH next_plan AS (
    SELECT 
        customer_id, 
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_id
    FROM foodie_fi.subscriptions
)
SELECT 
    p.plan_name,
    COUNT(n.customer_id) AS customer_count,
    ROUND(100.0 * COUNT(n.customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions), 2) AS percentage
FROM next_plan n
JOIN foodie_fi.plans p ON n.next_plan_id = p.plan_id
WHERE n.next_plan_id IS NOT NULL
GROUP BY p.plan_name
ORDER BY customer_count DESC;


/*
Question 7: What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
Output:
*/
-- YOUR ANSWER HERE
WITH last_plan AS (
    SELECT customer_id, MAX(start_date) AS last_date
    FROM foodie_fi.subscriptions
    WHERE start_date <= '2020-12-31'
    GROUP BY customer_id
)
SELECT 
    p.plan_name,
    COUNT(s.customer_id) AS customer_count,
    ROUND(100.0 * COUNT(s.customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions WHERE start_date <= '2020-12-31'), 2) AS percentage
FROM last_plan lp
JOIN foodie_fi.subscriptions s ON lp.customer_id = s.customer_id AND lp.last_date = s.start_date
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY customer_count DESC;


/*
Question 8: How many customers have upgraded to an annual plan in 2020?
Output:
*/
-- YOUR ANSWER HERE
SELECT COUNT(DISTINCT customer_id) AS annual_upgrades
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'pro annual' AND EXTRACT(YEAR FROM s.start_date) = 2020;


/*
Question 9: How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
Output:
*/
-- YOUR ANSWER HERE
WITH first_trial AS (
    SELECT customer_id, MIN(start_date) AS first_date
    FROM foodie_fi.subscriptions
    WHERE plan_id = (SELECT plan_id FROM foodie_fi.plans WHERE plan_name = 'trial')
    GROUP BY customer_id
),
first_annual AS (
    SELECT customer_id, MIN(start_date) AS annual_date
    FROM foodie_fi.subscriptions
    WHERE plan_id = (SELECT plan_id FROM foodie_fi.plans WHERE plan_name = 'pro annual')
    GROUP BY customer_id
)
SELECT 
    ROUND(AVG(a.annual_date - t.first_date), 0) AS avg_days_to_annual
FROM first_trial t
JOIN first_annual a ON t.customer_id = a.customer_id;


/*
Question 10: Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
Output:
*/
-- YOUR ANSWER HERE
WITH time_to_annual AS (
    SELECT 
        t.customer_id,
        a.annual_date - t.first_date AS days_to_annual
    FROM (
        SELECT customer_id, MIN(start_date) AS first_date
        FROM foodie_fi.subscriptions
        WHERE plan_id = (SELECT plan_id FROM foodie_fi.plans WHERE plan_name = 'trial')
        GROUP BY customer_id
    ) t
    JOIN (
        SELECT customer_id, MIN(start_date) AS annual_date
        FROM foodie_fi.subscriptions
        WHERE plan_id = (SELECT plan_id FROM foodie_fi.plans WHERE plan_name = 'pro annual')
        GROUP BY customer_id
    ) a ON t.customer_id = a.customer_id
)
SELECT 
    CASE 
        WHEN days_to_annual <= 30 THEN '0-30 days'
        WHEN days_to_annual <= 60 THEN '31-60 days'
        WHEN days_to_annual <= 90 THEN '61-90 days'
        ELSE '90+ days'
    END AS period,
    COUNT(customer_id) AS customer_count
FROM time_to_annual
GROUP BY period
ORDER BY period;

/*
Question 11: How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
Output:
*/
-- YOUR ANSWER HERE
SELECT COUNT(DISTINCT customer_id) AS downgraded_customers
FROM foodie_fi.subscriptions
WHERE customer_id IN (
    SELECT customer_id 
    FROM foodie_fi.subscriptions 
    WHERE plan_id = (SELECT plan_id FROM foodie_fi.plans WHERE plan_name = 'pro monthly')
)
AND plan_id = (SELECT plan_id FROM foodie_fi.plans WHERE plan_name = 'basic monthly');

