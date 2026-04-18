# `fact_cancer_first_seen`

*Group:* Cancer facts  
*Grain:* One row per first consultant appointment on a cancer pathway  
*Rows:* 2,796

First consultant appointment on a cancer pathway. FDS clock stop event.
Not every referral has a first-seen row within the reporting window —
right-censored cases remain open at the cutoff.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 2,796 | 1833 – 602331 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 2,796 | 2023-01-09 09:35:45 → 2025-12-31 15:50:41 | Time of the first appointment. FDS clock stop. |
| `event_sequence` | `BIGINT` | 0 | 2,796 | 2244 – 629180 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 1,552 | `PAT_0000268`, `PAT_0000728`, `PAT_0000713`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 25 | `CON_012`, `CON_002`, `CON_005`, `CON_007`, `CON_001`, … | Consultant who saw the patient. *(→ `dim_consultant.id`)* |
| `cancer_pathway_id` | `VARCHAR` | 0 | 2,796 | `inst_00395`, `inst_00945`, `inst_00989`, … | Cancer pathway identifier. Matches `fact_cancer_referral`. |
| `state` | `VARCHAR` | 0 | 1 | `first_seen` | State label. Constant `first_seen` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
