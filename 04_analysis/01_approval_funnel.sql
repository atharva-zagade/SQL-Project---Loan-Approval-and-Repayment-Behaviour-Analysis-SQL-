-- Data Analysis
-- Q1 A: What happens to applications? (the approval funnel)

SELECT name_contract_status,
	COUNT(*) AS applications,
	ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(),2) as pct
FROM previous_applications
GROUP BY name_contract_status
ORDER BY applications DESC;

/*
Result:

| name_contract_status | applications | pct   |
|----------------------|--------------|-------|
| Approved             | 886099       | 62.68 |
| Canceled             | 259441       | 18.35 |
| Refused              | 245390       | 17.36 |
| Unused offer         | 22771        | 1.61  |
*/

---------------------------------------------------------

-- Q1 B: Who made the decision, lender or customer?

SELECT
CASE
	WHEN name_contract_status = 'Approved' THEN '1. Approved'
	WHEN name_contract_status = 'Refused' THEN '2. Lender said no'
	WHEN name_contract_status IN ('Canceled','Unused offer') THEN '3. Customer walked away'
END AS outcome,
COUNT(*) AS applications,
ROUND(100.0*COUNT(*) / SUM(COUNT(*)) OVER(),2) as pct
FROM previous_applications
GROUP BY 1
ORDER BY 1;
/*
Result:

| category                    | applications | pct   |
|-----------------------------|--------------|-------|
| 1. Approved                 | 886099       | 62.68 |
| 2. Lender said no           | 245390       | 17.36 |
| 3. Customer walked away     | 282212       | 19.96 |
*/

----------------------------------------------------------------

-- Q1 C: Does the funnel differ for new vs repeat customers?

SELECT name_client_type,
	COUNT(*) AS applications,
	ROUND(100.0 * AVG((name_contract_status='Approved')::int),1) as approved_pct,
	ROUND(100.0 * AVG((name_contract_status='Refused')::int),1) as refused_pct,
	ROUND(100.0 * AVG((name_contract_status IN ('Canceled','Unused offer'))::int),1) as walked_away_pct
FROM previous_applications
WHERE name_client_type <> 'XNA'
GROUP BY name_client_type
ORDER BY applications DESC;

/*
Result:

| name_client_type | applications | approved_pct | refused_pct | walked_away_pct |
|------------------|--------------|--------------|-------------|-----------------|
| Repeater         | 1037682      | 54.0         | 21.2        | 24.8            |
| New              | 259540       | 93.4         | 4.8         | 1.8             |
| Refreshed        | 114936       | 72.1         | 10.9        | 17.0            |
*/

-----------------------------------------------------------------------------------

-- Q1 D: Is it the customer type, or the product mix?

SELECT name_client_type,
	name_contract_type,
	COUNT(*) AS applications,
	ROUND(100.0 * COUNT(*)/ SUM(COUNT(*)) OVER(PARTITION BY name_client_type),1) as pct_of_client_type,
	ROUND(100.0 * AVG((name_contract_status='Approved')::int),1) AS approved_pct,
	ROUND(100.0 * AVG((name_contract_status='Refused')::int),1) as refused_pct
FROM previous_applications
WHERE name_client_type <> 'XNA'
and name_contract_type <> 'XNA'
GROUP BY 1,2
ORDER BY 1,3 DESC;

/*
Result:

| name_client_type | name_contract_type | applications | pct_within_client | approved_pct | refused_pct |
|------------------|--------------------|--------------|-------------------|--------------|-------------|
| New              | Consumer loans     | 232074       | 89.4              | 95.7         | 3.5         |
| New              | Cash loans         | 18622        | 7.2               | 77.5         | 11.2        |
| New              | Revolving loans    | 8823         | 3.4               | 67.8         | 23.9        |
| Refreshed        | Consumer loans     | 56229        | 48.9              | 87.5         | 6.3         |
| Refreshed        | Cash loans         | 45453        | 39.6              | 57.2         | 12.4        |
| Refreshed        | Revolving loans    | 13232        | 11.5              | 58.4         | 25.3        |
| Repeater         | Cash loans         | 561692       | 54.1              | 40.2         | 23.4        |
| Repeater         | Consumer loans     | 336561       | 32.4              | 79.0         | 15.6        |
| Repeater         | Revolving loans    | 139159       | 13.4              | 49.4         | 25.9        |
*/
	
