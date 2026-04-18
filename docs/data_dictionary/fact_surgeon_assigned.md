# `fact_surgeon_assigned`

*Group:* Surgical facts  
*Grain:* One row per surgeon assignment event  
*Rows:* 7,866

Surgeon assignment to a surgical episode, after the pre-op assessment.
Only consultants of surgical grade appear as the assigned consultant.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 7,866 | 3038 – 602306 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 7,865 | 2023-01-17 11:20:21 → 2025-12-31 17:58:59 | Time the surgeon was assigned. |
| `event_sequence` | `BIGINT` | 0 | 7,866 | 3595 – 629155 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 5,559 | `PAT_0000399`, `PAT_0000432`, `PAT_0000029`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 14 | `CON_002`, `CON_001`, `CON_012`, `CON_005`, `CON_021`, … | Assigned surgeon. *(→ `dim_consultant.id`)* |
| `surgical_episode_id` | `VARCHAR` | 0 | 7,866 | `inst_01330`, `inst_02286`, `inst_02314`, … | Surgical episode identifier. Matches the pre-op assessment row. |
| `state` | `VARCHAR` | 0 | 1 | `pre_op_surgeon` | State label. Constant `pre_op_surgeon` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
