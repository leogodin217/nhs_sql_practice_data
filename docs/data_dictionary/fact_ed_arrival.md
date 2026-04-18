# `fact_ed_arrival`

*Group:* A&E facts  
*Grain:* One row per ED arrival event  
*Rows:* 10,710

Emergency Department arrival events. The first event in an A&E
attendance — records when a patient presents at A&E and is registered.
Subsequent events in the same attendance (triage, clinical assessment)
share the `attendance_id`.

The dataset does not include an ED departure event. Time-to-assessment
(via `fact_ed_assessment.wait_minutes`) is the closest usable proxy for
the NHS 4-hour A&E standard, which officially measures arrival-to-
departure.

## Notes

`attendance_id` is the grain that links `fact_ed_arrival`, `fact_triage`,
and `fact_ed_assessment`. Not every attendance becomes an inpatient
spell: roughly 1,100 ED patients per year are treated and sent home
without generating a `spell_id`.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 10,710 | 112 – 602450 | Synthetic monotonic event identifier across all fact tables. Useful for ordering events. |
| `timestamp` | `TIMESTAMP` | 0 | 10,709 | 2023-01-01 00:27:11 → 2025-12-31 21:57:55 | Event timestamp. Day-of-week shows the classic Monday-peak pattern in A&E. |
| `event_sequence` | `BIGINT` | 0 | 10,710 | 352 – 629301 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 5,850 | `PAT_0000006`, `PAT_0000041`, `PAT_0000045`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 25 | `CON_012`, `CON_002`, `CON_001`, `CON_005`, `CON_007`, … | Consultant who registered the arrival (typically the receiving clinician). *(→ `dim_consultant.id`)* |
| `attendance_id` | `VARCHAR` | 0 | 10,710 | `inst_00115`, `inst_00351`, `inst_00708`, … | Attendance identifier unique to this A&E visit. Links arrival, triage, and assessment rows for the same attendance. |
| `state` | `VARCHAR` | 0 | 1 | `arrival` | State label. Constant `arrival` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
