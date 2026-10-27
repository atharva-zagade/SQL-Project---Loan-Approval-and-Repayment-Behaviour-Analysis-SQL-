-- Q4 Asked vs Given

-- Q4 A: Who gets more, less or exactly what they asked, by loan type
SELECT 
	name_contract_type,
	COUNT (*) AS fair_rows,
	ROUND(100.0 * AVG((amt_credit>amt_application)::int),1) as given_more_pct,
	ROUND(100.0 * AVG((amt_credit<amt_application)::int),1) as given_less_pct,
	ROUND(100.0 * AVG((amt_credit=amt_application)::int),1) as given_exact_pct,
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY amt_credit/amt_application)::numeric,3) as median_given_to_asked
FROM previous_applications
WHERE name_contract_status = 'Approved'
AND amt_application > 0 AND amt_credit > 0
GROUP BY name_contract_type
ORDER BY fair_rows DESC;

/*
| name_contract_type | fair_rows | given_more_pct | given_less_pct | given_exact_pct | median_given_to_asked |
| Consumer loans     | 537310    | 32.7           | 52.0           | 15.3            | 0.995                 |
| Cash loans         | 266381    | 85.1           | 0.0            | 14.9            | 1.099                 |
| Revolving loans    | 42924     | 0.3            | 1.8            | 98.0            | 1.000                 |

*/

--------------------------------------------------------------------------------------------------

-- Q4 B: When people get less, how big is the cut?
SELECT name_contract_type,
	CASE
		WHEN amt_credit / amt_application < 0.5 THEN '1. Cut by more than half'
		WHEN amt_credit / amt_application < 0.8 THEN '2. Cut by 20 to 50%'
		WHEN amt_credit / amt_application < 0.95 THEN '3.  Cut by 5 to 20%'
		ELSE '4. Cut by under 5%'
	END as cut_size,
	COUNT(*) as applications,
	ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY name_contract_type),1) AS pct_within_type
FROM previous_applications
WHERE name_contract_status = 'Approved'
AND amt_application>0 AND amt_credit>0
AND amt_credit<amt_application
GROUP BY 1,2
ORDER BY 1,2;

/*
Result:

| name_contract_type | cut_size                  | applications | pct_within_type |
|--------------------|---------------------------|--------------|-----------------|
| Consumer loans     | 1. Cut by more than half  | 3077         | 1.1             |
| Consumer loans     | 2. Cut by 20 to 50%       | 42193        | 15.1            |
| Consumer loans     | 3. Cut by 5 to 20%        | 150041       | 53.7            |
| Consumer loans     | 4. Cut by under 5%        | 84325        | 30.2            |
| Revolving loans    | 1. Cut by more than half  | 375          | 48.8            |
| Revolving loans    | 2. Cut by 20 to 50%       | 195          | 25.4            |
| Revolving loans    | 3. Cut by 5 to 20%        | 157          | 20.4            |
| Revolving loans    | 4. Cut by under 5%        | 41           | 5.3             |

*/

------------------------------------------------------------------------------------------
