-- Q8 A: Past refusals vs current default
WITH prev AS (
  SELECT sk_id_curr,
         COUNT(*) AS past_apps,
         COUNT(*) FILTER (WHERE name_contract_status = 'Refused') AS refusals
  FROM previous_applications
  GROUP BY sk_id_curr
)
SELECT
  CASE
    WHEN p.sk_id_curr IS NULL       THEN '1. No past applications'
    WHEN p.refusals = 0             THEN '2. Never refused'
    WHEN p.refusals = 1             THEN '3. Refused once'
    WHEN p.refusals BETWEEN 2 AND 4 THEN '4. Refused 2 to 4 times'
    ELSE                                 '5. Refused 5+ times'
  END AS refusal_history,
  COUNT(*) AS customers,
  ROUND(100.0 * AVG(l.target), 2) AS default_rate_pct
FROM loans l
LEFT JOIN prev p USING (sk_id_curr)
GROUP BY 1
ORDER BY 1;

/*
Result:

| refusal_history          | customers | default_rate_pct |
|---------------------------|-----------|------------------|
| 1. No past applications   | 16454     | 5.96             |
| 2. Never refused          | 190763    | 7.07             |
| 3. Refused once           | 46534     | 8.83             |
| 4. Refused 2 to 4 times   | 41502     | 10.88            |
| 5. Refused 5+ times       | 12258     | 14.09            |
*/