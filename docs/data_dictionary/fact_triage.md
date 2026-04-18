# `fact_triage`

*Group:* A&E facts  
*Grain:* One row per triage event  
*Rows:* 10,710

Triage assessment event within an A&E attendance. Carries the
Manchester-style triage category (1–5) that drives clinical priority.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 10,710 | 114 – 602452 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 10,708 | 2023-01-01 00:59:27 → 2025-12-31 22:37:05 | Triage event timestamp. |
| `triage_category` | `BIGINT` | 0 | 5 | 1 – 5 | Triage category 1 (immediate / resuscitation) through 5 (non-urgent). |
| `event_sequence` | `BIGINT` | 0 | 10,710 | 354 – 629303 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 5,850 | `PAT_0000020`, `PAT_0000052`, `PAT_0000104`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 25 | `CON_012`, `CON_002`, `CON_001`, `CON_005`, `CON_007`, … | Clinician performing triage. *(→ `dim_consultant.id`)* |
| `attendance_id` | `VARCHAR` | 0 | 10,710 | `inst_00143`, `inst_00273`, `inst_00346`, … | A&E attendance identifier. Matches the arrival row in `fact_ed_arrival`. |
| `state` | `VARCHAR` | 0 | 1 | `triage` | State label. Constant `triage` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
