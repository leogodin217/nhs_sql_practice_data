# `fact_appointment_attended`

*Group:* Outpatient facts  
*Grain:* One row per attended outpatient appointment  
*Rows:* 23,975

Attended outpatient appointments. Linked to the originating referral
via `pathway_id`. A single pathway can have multiple attended
appointments (review, follow-up, etc.).

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 23,975 | 1817 – 602246 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 23,964 | 2023-01-09 13:54:13 → 2025-12-31 16:19:29 | Appointment attendance time. |
| `event_sequence` | `BIGINT` | 0 | 23,975 | 2228 – 629095 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 9,055 | `PAT_0000432`, `PAT_0000029`, `PAT_0000131`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 25 | `CON_012`, `CON_002`, `CON_001`, `CON_003`, `CON_013`, … | Consultant who saw the patient. *(→ `dim_consultant.id`)* |
| `pathway_id` | `VARCHAR` | 0 | 13,378 | `inst_00259`, `inst_00226`, `inst_00195`, … | Outpatient pathway identifier. Matches `fact_referral_created`. |
| `state` | `VARCHAR` | 0 | 1 | `attended` | State label. Constant `attended` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
