-- Q6 A: Underpayment per instalment
WITH inst AS (
  SELECT sk_id_prev, num_instalment_version, num_instalment_number,
         MAX(amt_instalment)          AS due_amt,     -- same value repeated on split rows, so MAX not SUM
         COALESCE(SUM(amt_payment),0) AS paid_amt     -- add up the parts
  FROM repayments
  GROUP BY 1, 2, 3
  HAVING MAX(amt_instalment) > 0
)
SELECT
  CASE
    WHEN paid_amt >= due_amt - 1      THEN '1. Paid in full'
    WHEN paid_amt >= 0.9 * due_amt    THEN '2. Paid 90 to 99%'
    WHEN paid_amt >= 0.5 * due_amt    THEN '3. Paid 50 to 90%'
    WHEN paid_amt >  0                THEN '4. Paid under 50%'
    ELSE                                   '5. Paid nothing'
  END AS payment_level,
  COUNT(*) AS instalments,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM inst
GROUP BY 1
ORDER BY 1;

/*
Result:

| payment_level         | instalments | pct   |
|-----------------------|-------------|-------|
| 1. Paid in full       | 11021507    | 99.96 |
| 2. Paid 90 to 99%     | 829         | 0.01  |
| 3. Paid 50 to 90%     | 384         | 0.00  |
| 4. Paid under 50%     | 1291        | 0.01  |
| 5. Paid nothing       | 2370        | 0.02  |
*/
----------------------------------------------------------------------------
-- Q6 B: The naive row-level view (for comparison)
SELECT ROUND(100.0 * AVG((amt_payment < amt_instalment - 1)::int), 2) AS naive_underpaid_pct
FROM repayments
WHERE amt_instalment > 0;
/*
Result:

| naive_underpaid_pct |
|---------------------|
| 9.51                |
*/