# Data dictionary

Per-table reference pages for the Millbrook NHS Trust dataset. Generated from `schema/tables.yaml` and the CSVs in `data/` by `scripts/gen_data_dictionary.py` — re-run after any regeneration of the dataset.

## Patient dimension

| Table | Rows | Summary |
|---|---:|---|
| [`dim_patient`](dim_patient.md) | 26,720 | Patient demographics, clinical flags, and tracked activity counters. |

## Clinical dimensions

| Table | Rows | Summary |
|---|---:|---|
| [`dim_consultant`](dim_consultant.md) | 25 | Consultant workforce — 25 consultants spread across 5 specialty groups, with grade, capacity, and quality attributes. |
| [`dim_ward`](dim_ward.md) | 10 | Hospital wards with capacity, department, and bed-day cost. |
| [`dim_procedure`](dim_procedure.md) | 35 | Surgical procedure catalogue with OPCS-4 clinical codes, HRG payment codes, complexity tier, and tariff. |
| [`dim_medication`](dim_medication.md) | 44 | Medication catalogue keyed by synthetic medication ID, categorised using the British National Formulary (BNF) hierarchy. |
| [`dim_diagnostic`](dim_diagnostic.md) | 12 | Diagnostic test catalogue (imaging, pathology, cardiology) with cost and expected turnaround. |
| [`dim_theatre`](dim_theatre.md) | 5 | Operating theatres and their scheduling capacity. |

## A&E facts

| Table | Rows | Summary |
|---|---:|---|
| [`fact_ed_arrival`](fact_ed_arrival.md) | 10,710 | Emergency Department arrival events. |
| [`fact_triage`](fact_triage.md) | 10,710 | Triage assessment event within an A&E attendance. |
| [`fact_ed_assessment`](fact_ed_assessment.md) | 10,151 | Clinical assessment event, performed after triage. |

## Inpatient facts

| Table | Rows | Summary |
|---|---:|---|
| [`fact_admission`](fact_admission.md) | 9,612 | Inpatient admission events. |
| [`fact_ward_assignment`](fact_ward_assignment.md) | 6,899 | Ward and bed assignments during a spell. |
| [`fact_medication_administered`](fact_medication_administered.md) | 11,068 | Medication administration events during an inpatient spell. |
| [`fact_icu_care`](fact_icu_care.md) | 762 | ICU / HDU escalation events during an inpatient spell. |
| [`fact_discharge`](fact_discharge.md) | 9,275 | Inpatient discharge events. |
| [`fact_dtoc_assessment`](fact_dtoc_assessment.md) | 6,540 | Delayed Transfer of Care (DTOC) assessments. |

## Outpatient facts

| Table | Rows | Summary |
|---|---:|---|
| [`fact_referral_created`](fact_referral_created.md) | 18,577 | Outpatient referrals received by the trust — typically from a GP. |
| [`fact_appointment_attended`](fact_appointment_attended.md) | 23,975 | Attended outpatient appointments. |

## Surgical facts

| Table | Rows | Summary |
|---|---:|---|
| [`fact_pre_op_assessment`](fact_pre_op_assessment.md) | 7,883 | Pre-operative assessment. |
| [`fact_surgeon_assigned`](fact_surgeon_assigned.md) | 7,866 | Surgeon assignment to a surgical episode, after the pre-op assessment. |
| [`fact_surgery_performed`](fact_surgery_performed.md) | 7,142 | Completed surgery event. |

## Cancer facts

| Table | Rows | Summary |
|---|---:|---|
| [`fact_cancer_referral`](fact_cancer_referral.md) | 2,865 | Cancer pathway referral. |
| [`fact_cancer_first_seen`](fact_cancer_first_seen.md) | 2,796 | First consultant appointment on a cancer pathway. |

## Diagnostics

| Table | Rows | Summary |
|---|---:|---|
| [`fact_diagnostic_ordered`](fact_diagnostic_ordered.md) | 8,325 | Diagnostic test order event. |
| [`fact_diagnostic_performed`](fact_diagnostic_performed.md) | 6,026 | Completed diagnostic test event. |

## Other

| Table | Rows | Summary |
|---|---:|---|
| [`fact_fft_response`](fact_fft_response.md) | 8,594 | Friends and Family Test survey responses. |
| [`fact_safety_incident`](fact_safety_incident.md) | 418 | Patient safety incidents reported on a ward during a spell. |
| [`fact_death_record`](fact_death_record.md) | 263 | In-hospital death record. |

## Pathway traces

| Table | Rows | Summary |
|---|---:|---|
| [`fact_journey_states`](fact_journey_states.md) | 432,000 | State-by-state trace of every patient journey — every intermediate state the simulator emits as a patient moves through A&E, inpatient, outpatient, surgical, cancer, and diagnostic pathways. |
