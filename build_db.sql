-- Build nhsdb.duckdb from CSV files
-- Usage: duckdb nhsdb.duckdb < build_db.sql

-- Dimensions
CREATE TABLE dim_patient AS SELECT * FROM read_csv('data/dim_patient.csv', header=true, auto_detect=true);
CREATE TABLE dim_consultant AS SELECT * FROM read_csv('data/dim_consultant.csv', header=true, auto_detect=true);
CREATE TABLE dim_ward AS SELECT * FROM read_csv('data/dim_ward.csv', header=true, auto_detect=true);
CREATE TABLE dim_procedure AS SELECT * FROM read_csv('data/dim_procedure.csv', header=true, auto_detect=true);
CREATE TABLE dim_medication AS SELECT * FROM read_csv('data/dim_medication.csv', header=true, auto_detect=true);
CREATE TABLE dim_diagnostic AS SELECT * FROM read_csv('data/dim_diagnostic.csv', header=true, auto_detect=true);
CREATE TABLE dim_theatre AS SELECT * FROM read_csv('data/dim_theatre.csv', header=true, auto_detect=true);

-- A&E Facts
CREATE TABLE fact_ed_arrival AS SELECT * FROM read_csv('data/fact_ed_arrival.csv', header=true, auto_detect=true);
CREATE TABLE fact_triage AS SELECT * FROM read_csv('data/fact_triage.csv', header=true, auto_detect=true);
CREATE TABLE fact_ed_assessment AS SELECT * FROM read_csv('data/fact_ed_assessment.csv', header=true, auto_detect=true);

-- Inpatient Facts
CREATE TABLE fact_admission AS SELECT * FROM read_csv('data/fact_admission.csv', header=true, auto_detect=true);
CREATE TABLE fact_ward_assignment AS SELECT * FROM read_csv('data/fact_ward_assignment.csv', header=true, auto_detect=true);
CREATE TABLE fact_medication_administered AS SELECT * FROM read_csv('data/fact_medication_administered.csv', header=true, auto_detect=true);
CREATE TABLE fact_icu_care AS SELECT * FROM read_csv('data/fact_icu_care.csv', header=true, auto_detect=true);
CREATE TABLE fact_dtoc_assessment AS SELECT * FROM read_csv('data/fact_dtoc_assessment.csv', header=true, auto_detect=true);
CREATE TABLE fact_discharge AS SELECT * FROM read_csv('data/fact_discharge.csv', header=true, auto_detect=true);
CREATE TABLE fact_death_record AS SELECT * FROM read_csv('data/fact_death_record.csv', header=true, auto_detect=true);
CREATE TABLE fact_safety_incident AS SELECT * FROM read_csv('data/fact_safety_incident.csv', header=true, auto_detect=true);

-- Outpatient Facts
CREATE TABLE fact_referral_created AS SELECT * FROM read_csv('data/fact_referral_created.csv', header=true, auto_detect=true);
CREATE TABLE fact_appointment_attended AS SELECT * FROM read_csv('data/fact_appointment_attended.csv', header=true, auto_detect=true);

-- Surgical Facts
CREATE TABLE fact_pre_op_assessment AS SELECT * FROM read_csv('data/fact_pre_op_assessment.csv', header=true, auto_detect=true);
CREATE TABLE fact_surgeon_assigned AS SELECT * FROM read_csv('data/fact_surgeon_assigned.csv', header=true, auto_detect=true);
CREATE TABLE fact_surgery_performed AS SELECT * FROM read_csv('data/fact_surgery_performed.csv', header=true, auto_detect=true);

-- Cancer Facts
CREATE TABLE fact_cancer_referral AS SELECT * FROM read_csv('data/fact_cancer_referral.csv', header=true, auto_detect=true);
CREATE TABLE fact_cancer_first_seen AS SELECT * FROM read_csv('data/fact_cancer_first_seen.csv', header=true, auto_detect=true);

-- Diagnostics
CREATE TABLE fact_diagnostic_ordered AS SELECT * FROM read_csv('data/fact_diagnostic_ordered.csv', header=true, auto_detect=true);
CREATE TABLE fact_diagnostic_performed AS SELECT * FROM read_csv('data/fact_diagnostic_performed.csv', header=true, auto_detect=true);

-- Other
CREATE TABLE fact_fft_response AS SELECT * FROM read_csv('data/fact_fft_response.csv', header=true, auto_detect=true);
