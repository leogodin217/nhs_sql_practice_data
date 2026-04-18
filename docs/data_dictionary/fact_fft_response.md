# `fact_fft_response`

*Group:* Other  
*Grain:* One row per Friends and Family Test response  
*Rows:* 8,594

Friends and Family Test survey responses. Each row is a single
patient's rating on the standard NHS FFT 1–5 recommendation scale.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 8,594 | 850 – 602347 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 8,594 | 2023-01-03 22:54:07 → 2025-12-31 22:45:16 | Time the response was submitted. |
| `recommendation_score` | `BIGINT` | 0 | 5 | 1 – 5 | NHS FFT score (1–5). Convention varies by survey; check the distribution before interpreting direction. |
| `event_sequence` | `BIGINT` | 0 | 8,594 | 1140 – 629197 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 6,427 | `PAT_0000020`, `PAT_0000052`, `PAT_0000216`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 25 | `CON_013`, `CON_019`, `CON_023`, `CON_017`, `CON_021`, … | Consultant associated with the care episode being rated. *(→ `dim_consultant.id`)* |
| `survey_id` | `VARCHAR` | 0 | 8,594 | `inst_00588`, `inst_00689`, `inst_00434`, … | Survey response identifier. |
| `state` | `VARCHAR` | 0 | 1 | `responded` | State label. Constant `responded` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
