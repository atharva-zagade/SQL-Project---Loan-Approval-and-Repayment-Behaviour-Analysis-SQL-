-- Q7 A: Does lateness differ by loan type?
WITH inst AS (
  SELECT sk_id_prev, num_instalment_version, num_instalment_number,
         MAX(days_entry_payment) - MIN(days_instalment) AS days_late
  FROM repayments
  WHERE days_entry_payment IS NOT NULL
  GROUP BY 1, 2, 3
)
SELECT COALESCE(p.name_contract_type, 'Not linked (orphan)') AS loan_type,
       COUNT(*) AS instalments,
       ROUND(100.0 * AVG((i.days_late < 0)::int), 2)                          AS early_pct,
       ROUND(100.0 * AVG((i.days_late = 0)::int), 2)                          AS on_due_day_pct,
       ROUND(100.0 * AVG((i.days_late BETWEEN 1 AND 30)::int), 2)             AS late_1_30_pct,
       ROUND(100.0 * AVG((i.days_late > 30)::int), 2)                         AS late_30plus_pct
FROM inst i
LEFT JOIN previous_applications p USING (sk_id_prev)
GROUP BY 1
ORDER BY instalments DESC;

/*
Result:

| loan_type            | instalments | early_pct | on_due_day_pct | late_1_30_pct | late_30plus_pct |
|----------------------|-------------|-----------|----------------|---------------|-----------------|
| Consumer loans       | 4535996     | 84.98     | 5.89           | 8.76          | 0.38            |
| Cash loans           | 2955478     | 79.15     | 8.61           | 12.01         | 0.23            |
| Revolving loans      | 2537855     | 34.59     | 60.40          | 4.81          | 0.20            |
| Not linked (orphan)  | 994715      | 33.75     | 61.03          | 4.78          | 0.44            |
*/
------------------------------------------------------------------------------

-- Q7 B: Lateness by interest band (yield group)
WITH inst AS (
  SELECT sk_id_prev, num_instalment_version, num_instalment_number,
         MAX(days_entry_payment) - MIN(days_instalment) AS days_late
  FROM repayments
  WHERE days_entry_payment IS NOT NULL
  GROUP BY 1, 2, 3
)
SELECT p.name_yield_group,
       COUNT(*) AS instalments,
       ROUND(100.0 * AVG((i.days_late > 0)::int), 2)  AS any_late_pct,
       ROUND(100.0 * AVG((i.days_late > 30)::int), 2) AS late_30plus_pct
FROM inst i
JOIN previous_applications p USING (sk_id_prev)
WHERE p.name_yield_group <> 'XNA'
GROUP BY 1
ORDER BY any_late_pct DESC;

/*
Result:

| name_yield_group | instalments | any_late_pct | late_30plus_pct |
|------------------|-------------|--------------|-----------------|
| high             | 2275630     | 13.38        | 0.53            |
| middle           | 2475281     | 10.19        | 0.25            |
| low_normal       | 1966158     | 8.09         | 0.23            |
| low_action       | 774405      | 7.77         | 0.16            |
*/