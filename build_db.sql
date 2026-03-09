-- Build nhsdb.duckdb from CSV files
-- Usage: duckdb nhsdb.duckdb < build_db.sql

-- ============================================================
-- Patient Dimension
-- ============================================================

CREATE TABLE dim_patient AS
SELECT
    id, name, person_gender_code, ethnic_category,
    imd_decile::INTEGER AS imd_decile,
    primary_condition,
    comorbidity_count::INTEGER AS comorbidity_count,
    frailty_score::INTEGER AS frailty_score,
    gp_practice_code, pathway_type, status,
    admission_count::INTEGER AS admission_count,
    total_spell_tariff::DOUBLE AS total_spell_tariff,
    valid_from::TIMESTAMP AS valid_from,
    valid_to::TIMESTAMP AS valid_to,
    active::BOOLEAN AS active
FROM read_csv('data/dim_patient.csv', header=true, auto_detect=true);

-- ============================================================
-- Clinical Dimensions
-- ============================================================

CREATE TABLE dim_consultant AS
SELECT
    id, consultant_code, main_specialty, grade,
    quality_rating::DOUBLE AS quality_rating,
    specialty_group,
    valid_from::TIMESTAMP AS valid_from,
    valid_to::TIMESTAMP AS valid_to
FROM read_csv('data/dim_consultant.csv', header=true, auto_detect=true);

CREATE TABLE dim_ward AS
SELECT
    id, ward_name, ward_type, department, site_code,
    total_beds::INTEGER AS total_beds,
    cost_per_bed_day::DOUBLE AS cost_per_bed_day,
    valid_from::TIMESTAMP AS valid_from,
    valid_to::TIMESTAMP AS valid_to
FROM read_csv('data/dim_ward.csv', header=true, auto_detect=true);

CREATE TABLE dim_procedure AS
SELECT
    id, procedure_name, opcs4_code, hrg_code,
    tariff::DOUBLE AS tariff,
    complexity, specialty_group,
    valid_from::TIMESTAMP AS valid_from,
    valid_to::TIMESTAMP AS valid_to
FROM read_csv('data/dim_procedure.csv', header=true, auto_detect=true);

CREATE TABLE dim_medication AS
SELECT
    id, medication_name, bnf_category, route,
    daily_cost::DOUBLE AS daily_cost,
    specialty_group,
    valid_from::TIMESTAMP AS valid_from,
    valid_to::TIMESTAMP AS valid_to
FROM read_csv('data/dim_medication.csv', header=true, auto_detect=true);

CREATE TABLE dim_diagnostic AS
SELECT
    id, test_name, test_type,
    cost::DOUBLE AS cost,
    turnaround_days::INTEGER AS turnaround_days,
    valid_from::TIMESTAMP AS valid_from,
    valid_to::TIMESTAMP AS valid_to
FROM read_csv('data/dim_diagnostic.csv', header=true, auto_detect=true);

CREATE TABLE dim_theatre AS
SELECT
    id, theatre_name, specialty,
    sessions_per_day::INTEGER AS sessions_per_day,
    valid_from::TIMESTAMP AS valid_from,
    valid_to::TIMESTAMP AS valid_to
FROM read_csv('data/dim_theatre.csv', header=true, auto_detect=true);

CREATE TABLE dim_clinic AS
SELECT
    id, clinic_name, specialty, clinic_type,
    valid_from::TIMESTAMP AS valid_from,
    valid_to::TIMESTAMP AS valid_to
FROM read_csv('data/dim_clinic.csv', header=true, auto_detect=true);

-- ============================================================
-- A&E Facts
-- ============================================================

CREATE TABLE fact_ed_arrival AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_ed_arrival.csv', header=true, auto_detect=true);

CREATE TABLE fact_triage AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    triage_category::INTEGER AS triage_category,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_triage.csv', header=true, auto_detect=true);

CREATE TABLE fact_ed_assessment AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    wait_minutes::INTEGER AS wait_minutes,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_ed_assessment.csv', header=true, auto_detect=true);

-- ============================================================
-- Inpatient Facts
-- ============================================================

CREATE TABLE fact_admission AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_admission.csv', header=true, auto_detect=true);

CREATE TABLE fact_ward_assignment AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    bed_number::INTEGER AS bed_number,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_ward_assignment.csv', header=true, auto_detect=true);

CREATE TABLE fact_medication_administered AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_medication_administered.csv', header=true, auto_detect=true);

CREATE TABLE fact_icu_care AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_icu_care.csv', header=true, auto_detect=true);

CREATE TABLE fact_discharge AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_discharge.csv', header=true, auto_detect=true);

CREATE TABLE fact_dtoc_assessment AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_dtoc_assessment.csv', header=true, auto_detect=true);

-- ============================================================
-- Outpatient Facts
-- ============================================================

CREATE TABLE fact_referral_created AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_referral_created.csv', header=true, auto_detect=true);

CREATE TABLE fact_appointment_attended AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_appointment_attended.csv', header=true, auto_detect=true);

-- ============================================================
-- Surgical Facts
-- ============================================================

CREATE TABLE fact_pre_op_assessment AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_pre_op_assessment.csv', header=true, auto_detect=true);

CREATE TABLE fact_surgeon_assigned AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_surgeon_assigned.csv', header=true, auto_detect=true);

CREATE TABLE fact_surgery_performed AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_surgery_performed.csv', header=true, auto_detect=true);

-- ============================================================
-- Cancer Facts
-- ============================================================

CREATE TABLE fact_cancer_referral AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_cancer_referral.csv', header=true, auto_detect=true);

CREATE TABLE fact_cancer_first_seen AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_cancer_first_seen.csv', header=true, auto_detect=true);

-- ============================================================
-- Diagnostics
-- ============================================================

CREATE TABLE fact_diagnostic_ordered AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_diagnostic_ordered.csv', header=true, auto_detect=true);

CREATE TABLE fact_diagnostic_performed AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_diagnostic_performed.csv', header=true, auto_detect=true);

-- ============================================================
-- Other
-- ============================================================

CREATE TABLE fact_fft_response AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    recommendation_score::INTEGER AS recommendation_score,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_fft_response.csv', header=true, auto_detect=true);

CREATE TABLE fact_safety_incident AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_safety_incident.csv', header=true, auto_detect=true);

CREATE TABLE fact_death_record AS
SELECT
    decision_id::INTEGER AS decision_id,
    timestamp::TIMESTAMP AS timestamp,
    actor_type, actor_id, entity_type, entity_id,
    event_sequence::INTEGER AS event_sequence,
    journey_type, journey_instance_id, journey_state
FROM read_csv('data/fact_death_record.csv', header=true, auto_detect=true);
