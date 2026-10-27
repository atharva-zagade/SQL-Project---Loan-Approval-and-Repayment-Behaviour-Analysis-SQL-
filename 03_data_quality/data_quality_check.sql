CREATE INDEX idx_loans_curr  ON loans(sk_id_curr);
CREATE INDEX idx_prev_curr   ON previous_applications(sk_id_curr);
CREATE INDEX idx_repay_curr  ON repayments(sk_id_curr);
CREATE INDEX idx_repay_prev  ON repayments(sk_id_prev);


-- Data Quality Checks
-- DQ1 Missing values in key columns

SELECT
	COUNT(*) as total,
	COUNT(*) - COUNT(amt_credit) as null_given,
	COUNT(*) - COUNT(amt_annuity) as null_annunity,
	COUNT(*) - COUNT(cnt_payment) as null_term,
	COUNT(*) FILTER (WHERE amt_application = 0) AS asked_zero,
	COUNT(*) FILTER (WHERE amt_credit=0) AS given_zero,
	COUNT(*) FILTER (WHERE amt_credit>amt_application) as given_more_than_asked
FROM previous_applications;

/*
Result:
total                  : 1413701
null_given             : 1
null_annunity          : 307218
null_term              : 307213
asked_zero             : 325302
given_zero             : 276577
given_more_than_asked  : 560467
*/

-- DQ2 Zero-amount applications: what status do they have?

SELECT name_contract_status, name_contract_type, COUNT(*)
FROM previous_applications
WHERE amt_application=0
GROUP BY 1,2
ORDER BY 3 DESC;

/* Result
| name_contract_status | name_contract_type | count  |
|----------------------|--------------------|--------|
| Canceled             | Cash loans         | 212031 |
| Approved             | Revolving loans    | 39484  |
| Canceled             | Revolving loans    | 37036  |
| Refused              | Cash loans         | 22053  |
| Refused              | Revolving loans    | 12758  |
| Canceled             | Consumer loans     | 1133   |
| Unused offer         | Cash loans         | 427    |
| Canceled             | XNA                | 284    |
| Refused              | Consumer loans     | 63     |
| Refused              | XNA                | 29     |
| Unused offer         | Revolving loans    | 4      |
*/

-- DQ3 Are the null-term rows the same as the null-annunity rows, and what status are they?
SELECT name_contract_status, COUNT(*)
FROM previous_applications
WHERE cnt_payment IS NULL
GROUP BY 1
ORDER BY 2 DESC;

/* Result
| name_contract_status | count  |
|----------------------|--------|
| Canceled             | 250681 |
| Refused              | 34541  |
| Unused offer         | 21988  |
| Approved             | 3      |
*/

-- DQ4 "Given More than asked", but only where it's a fair comparison
SELECT COUNT(*) AS fair_rows,
	COUNT(*) FILTER (WHERE amt_credit > amt_application) AS given_more,
       COUNT(*) FILTER (WHERE amt_credit < amt_application) AS given_less,
       COUNT(*) FILTER (WHERE amt_credit = amt_application) AS given_exact
FROM previous_applications
WHERE amt_application > 0 AND amt_credit>0
AND name_contract_status = 'Approved';

/* Result
| fair_rows | given_more | given_less | given_exact |
|-----------|------------|------------|-------------|
| 846615    | 402384     | 280404     | 163827      |
*/

-- DQ5 Placeholder codes (XNA = not available, XAP = not applicable)
SELECT
  COUNT(*) FILTER (WHERE name_client_type = 'XNA')        AS xna_client_type,
  COUNT(*) FILTER (WHERE name_yield_group = 'XNA')        AS xna_yield_group,
  COUNT(*) FILTER (WHERE name_contract_type = 'XNA')      AS xna_contract_type,
  COUNT(*) FILTER (WHERE name_cash_loan_purpose IN ('XNA','XAP')) AS no_purpose,
  COUNT(*) FILTER (WHERE channel_type = 'XNA')            AS xna_channel
FROM previous_applications;

/*
Result:

| xna_client_type | xna_yield_group | xna_contract_type | no_purpose | xna_channel |
|-----------------|-----------------|-------------------|------------|-------------|
| 1543            | 429198          | 313               | 1354288    | 0           |
*/

-- DQ6 Do reject reasons line up with status?
SELECT name_contract_status, code_reject_reason, COUNT(*)
FROM previous_applications
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
/*
Result:

| name_contract_status | code_reject_reason | count  |
|----------------------|-------------------|--------|
| Approved             | XAP               | 886091 |
| Approved             | XNA               | 8      |
| Canceled             | XAP               | 259441 |
| Refused              | HC                | 145984 |
| Refused              | LIMIT             | 47773  |
| Refused              | SCO               | 32636  |
| Refused              | SCOFR             | 10875  |
| Refused              | XNA               | 4370   |
| Refused              | VERIF             | 3079   |
| Refused              | SYSTEM            | 672    |
| Refused              | XAP               | 1      |
| Unused offer         | CLIENT            | 22771  |
*/

-- DQ7 How far back do decisions go?
SELECT MIN(days_decision) AS oldest, MAX(days_decision) AS newest,
       ROUND(MIN(days_decision) / -365.0, 1) AS oldest_years_back
FROM previous_applications;
/*
Result:

| oldest | newest | oldest_years_back |
|--------|--------|-------------------|
| -2922  | -1     | 8.0               |
*/

-- DQ8 Customers and loans
SELECT
  COUNT(*)                                          AS total,
  COUNT(*) FILTER (WHERE days_employed = 365243)    AS employed_placeholder,
  COUNT(*) FILTER (WHERE code_gender = 'XNA')       AS gender_unknown,
  COUNT(*) FILTER (WHERE occupation_type IS NULL)   AS no_occupation,
  COUNT(*) FILTER (WHERE l.amt_annuity IS NULL)     AS no_annuity,
  ROUND(100.0 * AVG(l.target), 2)                   AS default_rate_pct
FROM customers c
JOIN loans l USING (sk_id_curr);
/*
Result:

| total  | employed_placeholder | gender_unknown | no_occupation | no_annuity | default_rate_pct |
|--------|----------------------|----------------|---------------|------------|------------------|
| 307511 | 55374                | 4              | 96391         | 12         | 8.07             |
*/

-- DQ9 Missing payments and zero-due instalments
SELECT
  COUNT(*)                                            AS total,
  COUNT(*) FILTER (WHERE amt_payment IS NULL)         AS no_payment,
  COUNT(*) FILTER (WHERE amt_instalment = 0)          AS zero_due,
  MIN(days_entry_payment - days_instalment)           AS earliest_days,
  MAX(days_entry_payment - days_instalment)           AS latest_days
FROM repayments;
/*
Result:

| total    | no_payment | zero_due | earliest_days | latest_days |
|----------|------------|----------|---------------|-------------|
| 11591592 | 2583       | 269      | -3189         | 2884        |
*/

-- DQ10 Instalments paid in several parts (the split-payment trap)
SELECT COUNT(*) as installments,
		COUNT(*) FILTER (WHERE n >1) AS split_instalments
FROM(
	select
	sk_id_prev,
	num_instalment_version,
	num_instalment_number,
	COUNT(*) as n
	FROM repayments
	GROUP BY 1,2,3
) t;

/*
Result:

| installments | split_instalments |
|--------------|-------------------|
| 11026627     | 553925            |
*/





