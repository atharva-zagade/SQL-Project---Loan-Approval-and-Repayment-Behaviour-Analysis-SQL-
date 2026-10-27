-- Loading the data

INSERT INTO customers (
    sk_id_curr, code_gender, days_birth, cnt_children, cnt_fam_members,
    name_family_status, name_education_type, name_housing_type,
    flag_own_car, flag_own_realty, amt_income_total, name_income_type,
    occupation_type, organization_type, days_employed,
    ext_source_1, ext_source_2, ext_source_3,
    def_30_cnt_social_circle, def_60_cnt_social_circle,
    obs_30_cnt_social_circle, obs_60_cnt_social_circle,
    amt_req_credit_bureau_day, amt_req_credit_bureau_week,
    amt_req_credit_bureau_mon, amt_req_credit_bureau_qrt, amt_req_credit_bureau_year,
    region_population_relative, days_last_phone_change,
    reg_city_not_live_city, reg_city_not_work_city
)
SELECT
    sk_id_curr::integer,
    code_gender,
    days_birth::integer,
    cnt_children::integer,
    cnt_fam_members::numeric,
    name_family_status,
    name_education_type,
    name_housing_type,
    flag_own_car,
    flag_own_realty,
    amt_income_total::numeric,
    name_income_type,
    occupation_type,
    organization_type,
    days_employed::integer,
    ext_source_1::numeric,
    ext_source_2::numeric,
    ext_source_3::numeric,
    def_30_cnt_social_circle::numeric,
    def_60_cnt_social_circle::numeric,
    obs_30_cnt_social_circle::numeric,
    obs_60_cnt_social_circle::numeric,
    amt_req_credit_bureau_day::numeric,
    amt_req_credit_bureau_week::numeric,
    amt_req_credit_bureau_mon::numeric,
    amt_req_credit_bureau_qrt::numeric,
    amt_req_credit_bureau_year::numeric,
    region_population_relative::numeric,
    days_last_phone_change::numeric::integer,   -- stored as "-1134.0", so two-step cast
    reg_city_not_live_city::smallint,
    reg_city_not_work_city::smallint
FROM stg_application_train;

INSERT INTO loans (
    sk_id_curr, name_contract_type, amt_credit, amt_annuity,
    amt_goods_price, region_rating_client, target
)
SELECT
    sk_id_curr::integer,
    name_contract_type,
    amt_credit::numeric,
    amt_annuity::numeric,
    amt_goods_price::numeric,
    region_rating_client::smallint,
    target::smallint
FROM stg_application_train;  -- was "staging_application_train"

INSERT INTO repayments (
    sk_id_prev, sk_id_curr, num_instalment_version, num_instalment_number,
    days_instalment, days_entry_payment, amt_instalment, amt_payment
)
SELECT
    i.sk_id_prev::integer,
    i.sk_id_curr::integer,
    i.num_instalment_version::numeric,
    i.num_instalment_number::numeric::integer,
    i.days_instalment::numeric::integer,       -- stored like "-1180.0"
    i.days_entry_payment::numeric::integer,
    i.amt_instalment::numeric,
    i.amt_payment::numeric
FROM stg_installments_payments i
WHERE EXISTS (
    SELECT 1 FROM customers c
    WHERE c.sk_id_curr = i.sk_id_curr::integer   -- keep only known customers
);
INSERT INTO previous_applications
SELECT
    p.sk_id_prev::integer,
    p.sk_id_curr::integer,
    p.name_contract_type,
    p.amt_application::numeric,
    p.amt_credit::numeric,
    p.amt_annuity::numeric,
    p.cnt_payment::numeric,
    p.name_contract_status,
    p.code_reject_reason,
    p.name_cash_loan_purpose,
    p.name_client_type,
    p.channel_type,
    p.name_yield_group,
    p.days_decision::numeric::integer
FROM stg_previous_application p
WHERE EXISTS (
    SELECT 1 FROM customers c WHERE c.sk_id_curr = p.sk_id_curr::integer
);


SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM loans;
SELECT COUNT(*) FROM repayments;
SELECT COUNT(*) FROM previous_applications;

-- check count all the table rows

SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL SELECT 'loans', COUNT(*) FROM loans
UNION ALL SELECT 'repayments', COUNT(*) FROM repayments
UNION ALL SELECT 'previous_applications', COUNT(*) FROM previous_applications;

