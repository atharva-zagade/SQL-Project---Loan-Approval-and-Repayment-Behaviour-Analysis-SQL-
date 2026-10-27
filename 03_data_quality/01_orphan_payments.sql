SELECT COUNT(*) AS orphan_payments
FROM repayments r
WHERE NOT EXISTS (
    SELECT 1 FROM previous_applications p WHERE p.sk_id_prev = r.sk_id_prev
);

-- 2. Are these loans missing from the RAW file too?
SELECT COUNT(*) AS orphans_vs_raw
FROM repayments r
WHERE NOT EXISTS (
    SELECT 1 FROM stg_previous_application p
    WHERE p.sk_id_prev::integer = r.sk_id_prev
);

-- 3. How many distinct loans and customers are affected?
SELECT COUNT(DISTINCT r.sk_id_prev) AS orphan_loans,
       COUNT(DISTINCT r.sk_id_curr) AS affected_customers
FROM repayments r
WHERE NOT EXISTS (
    SELECT 1 FROM previous_applications p WHERE p.sk_id_prev = r.sk_id_prev
);
