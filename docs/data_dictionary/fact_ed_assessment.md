# `fact_ed_assessment`

*Group:* A&E facts  
*Grain:* One row per clinical assessment in A&E  
*Rows:* 10,151

Clinical assessment event, performed after triage. Carries
`wait_minutes` — the elapsed time from arrival to this assessment — used
as the operational proxy for the 4-hour A&E standard.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 10,151 | 116 – 602454 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 10,150 | 2023-01-01 03:41:25 → 2026-01-01 00:37:46 | Assessment event timestamp. |
| `wait_minutes` | `BIGINT` | 0 | 407 | 10 – 958 | Minutes from arrival to clinical assessment. Proxy for the 4-hour standard (which officially measures arrival-to-departure). |
| `event_sequence` | `BIGINT` | 0 | 10,151 | 356 – 629305 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 5,683 | `PAT_0000020`, `PAT_0000052`, `PAT_0000104`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 25 | `CON_012`, `CON_002`, `CON_001`, `CON_005`, `CON_007`, … | Assessing clinician. *(→ `dim_consultant.id`)* |
| `attendance_id` | `VARCHAR` | 0 | 10,151 | `inst_00143`, `inst_00273`, `inst_00346`, … | A&E attendance identifier. Matches the arrival and triage rows. |
| `state` | `VARCHAR` | 0 | 1 | `assessment` | State label. Constant `assessment` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
