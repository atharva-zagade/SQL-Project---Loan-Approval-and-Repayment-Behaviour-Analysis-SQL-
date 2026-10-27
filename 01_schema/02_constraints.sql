-- Scheme : Create/Check Constraints
-- 02_check_constraints
-- Schema-level validation. Run the sanity check first: every number must be 0
-- (all were 0 when run), otherwise an ALTER below will fail on existing rows.
-- NULLs pass CHECK constraints, so missing ext_source values are unaffected.

-- SANITY CHECK(preview)

SELECT
	-- customers/loans
	(SELECT COUNT(*) FROM loans WHERE target NOT IN(0,1))                  as bad_target,
	(SELECT COUNT(*) FROM loans WHERE amt_credit<=0)                       as bad_credit,
	(SELECT COUNT(*) - COUNT(DISTINCT sk_id_curr) FROM loans)              as dup_loan_customers,
	(SELECT COUNT(*) FROM customers WHERE amt_income_total<=0)             as bad_income,
	(SELECT COUNT(*) FROM customers WHERE days_birth>=0)                   as bad_birth,
	(SELECT COUNT(*) FROM customers WHERE ext_source_1 NOT BETWEEN 0 AND 1
                                      OR ext_source_2 NOT BETWEEN 0 AND 1
                                      OR ext_source_3 NOT BETWEEN 0 AND 1) as bad_ext,
	-- previous_applications(yours)
	(SELECT COUNT(*) FROM previous_applications
		WHERE name_contract_status NOT IN ('Approved','Refused','Canceled','Unused offer')) as bad_status,
	(SELECT COUNT(*) FROM previous_applications WHERE amt_application < 0) as bad_asked,
	(SELECT COUNT(*) FROM previous_applications WHERE amt_credit<0) as bad_given,
	(SELECT COUNT(*) FROM previous_applications WHERE cnt_payment<0) as bad_term,
	(SELECT COUNT(*) FROM previous_applications WHERE days_decision >=0) AS bad_decision_day,
	(SELECT COUNT(*) FROM repayments WHERE amt_instalment < 0) as bad_due,
	(SELECT COUNT(*) FROM repayments WHERE amt_payment<0) as bad_paid,
	(SELECT COUNT(*) FROM repayments WHERE num_instalment_number<1) as bad_instalment_no;
								

-- customers / Loans
ALTER TABLE loans ADD CONSTRAINT chk_loans_target CHECK(target IN (0,1));
ALTER TABLE loans ADD CONSTRAINT chk_loans_credit CHECK(amt_credit > 0);
ALTER TABLE loans ADD CONSTRAINT uq_loans_customers UNIQUE (sk_id_curr);
ALTER TABLE customers ADD CONSTRAINT chk_cust_income CHECK (amt_income_total>0);
ALTER TABLE customers ADD CONSTRAINT chk_cust_birth CHECK(days_birth<0);
ALTER TABLE customers ADD CONSTRAINT chk_cust_ext
	CHECK(ext_source_1 BETWEEN 0 and 1 AND ext_source_2 BETWEEN 0 and 1 AND ext_source_3 BETWEEN 0 AND 1);

-- previous_applications
ALTER TABLE previous_applications ADD CONSTRAINT chk_prev_status
  CHECK (name_contract_status IN ('Approved','Refused','Canceled','Unused offer'));
ALTER TABLE previous_applications ADD CONSTRAINT chk_prev_amounts
  CHECK (amt_application >= 0 AND amt_credit >= 0);
ALTER TABLE previous_applications ADD CONSTRAINT chk_prev_term     CHECK (cnt_payment >= 0);
ALTER TABLE previous_applications ADD CONSTRAINT chk_prev_decision CHECK (days_decision < 0);

-- repayments
ALTER TABLE repayments ADD CONSTRAINT chk_repay_amounts
	CHECK (amt_instalment >=0 AND amt_payment >=0);
ALTER TABLE repayments ADD CONSTRAINT chk_repay_number CHECK (num_instalment_number >= 1);

	

	
