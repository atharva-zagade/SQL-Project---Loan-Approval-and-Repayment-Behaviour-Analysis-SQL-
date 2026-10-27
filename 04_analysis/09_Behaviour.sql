-- Q9 A: Share of late instalments per customer vs current default
WITH inst AS (
  SELECT sk_id_curr, sk_id_prev, num_instalment_version, num_instalment_number,
         MAX(days_entry_payment) - MIN(days_instalment) AS days_late
  FROM repayments
  WHERE days_entry_payment IS NOT NULL
  GROUP BY 1, 2, 3, 4
),
cust AS (
  SELECT sk_id_curr, AVG((days_late > 0)::int) AS late_share
  FROM inst
  GROUP BY sk_id_curr
)
SELECT
  CASE
    WHEN c.sk_id_curr IS NULL  THEN '1. No payment history'
    WHEN c.late_share = 0      THEN '2. Never late'
    WHEN c.late_share <= 0.10  THEN '3. Late on up to 10%'
    WHEN c.late_share <= 0.25  THEN '4. Late on 10 to 25%'
    ELSE                            '5. Late on over 25%'
  END AS payment_history,
  COUNT(*) AS customers,
  ROUND(100.0 * AVG(l.target), 2) AS default_rate_pct
FROM loans l
LEFT JOIN cust c USING (sk_id_curr)
GROUP BY 1
ORDER BY 1;

/*
Result:

| payment_history         | customers | default_rate_pct |
|-------------------------|-----------|------------------|
| 1. No payment history   | 15876     | 5.98             |
| 2. Never late           | 136636    | 6.80             |
| 3. Late on up to 10%    | 75587     | 7.88             |
| 4. Late on 10 to 25%    | 48694     | 9.93             |
| 5. Late on over 25%     | 30718     | 12.34            |
*/

-------------------------------------------------------------------
-- Q9 B: Combining both signals (refused before x late before)
WITH prev AS (
  SELECT sk_id_curr, COUNT(*) FILTER (WHERE name_contract_status = 'Refused') AS refusals
  FROM previous_applications GROUP BY 1
),
inst AS (
  SELECT sk_id_curr, sk_id_prev, num_instalment_version, num_instalment_number,
         MAX(days_entry_payment) - MIN(days_instalment) AS days_late
  FROM repayments WHERE days_entry_payment IS NOT NULL
  GROUP BY 1, 2, 3, 4
),
cust AS (
  SELECT sk_id_curr, AVG((days_late > 0)::int) AS late_share FROM inst GROUP BY 1
)
SELECT
  CASE WHEN COALESCE(p.refusals, 0) > 0 THEN 'Refused before' ELSE 'Never refused' END AS refusal,
  CASE WHEN COALESCE(c.late_share, 0) > 0.10 THEN 'Late on >10%' ELSE 'Rarely or never late' END AS lateness,
  COUNT(*) AS customers,
  ROUND(100.0 * AVG(l.target), 2) AS default_rate_pct
FROM loans l
LEFT JOIN prev p USING (sk_id_curr)
LEFT JOIN cust c USING (sk_id_curr)
GROUP BY 1, 2
ORDER BY default_rate_pct;

/*
Result:

| refusal          | lateness                 | customers | default_rate_pct |
|------------------|--------------------------|-----------|------------------|
| Never refused    | Rarely or never late     | 159550    | 6.11             |
| Refused before   | Rarely or never late     | 68549     | 9.40             |
| Never refused    | Late on >10%             | 47667     | 9.90             |
| Refused before   | Late on >10%             | 31745     | 12.32            |
*/