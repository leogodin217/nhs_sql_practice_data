# `fact_pre_op_assessment`

*Group:* Surgical facts  
*Grain:* One row per pre-operative assessment  
*Rows:* 7,883

Pre-operative assessment. First event on a surgical episode — links the
patient to the planned procedure and opens the `surgical_episode_id`
that joins the later surgeon-assignment and surgery-performed events.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 7,883 | 2845 – 602214 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 7,883 | 2023-01-16 09:07:09 → 2025-12-31 16:50:27 | Pre-op assessment time. |
| `event_sequence` | `BIGINT` | 0 | 7,883 | 3385 – 629063 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 5,570 | `PAT_0000399`, `PAT_0000432`, `PAT_0000029`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `procedure_id` | `VARCHAR` | 0 | 35 | `PROC_011`, `PROC_022`, `PROC_016`, … | Planned procedure. *(→ `dim_procedure.id`)* |
| `surgical_episode_id` | `VARCHAR` | 0 | 7,883 | `inst_01330`, `inst_02286`, `inst_02314`, … | Surgical episode identifier. Links pre-op, surgeon assignment, and surgery performed. |
| `state` | `VARCHAR` | 0 | 1 | `pre_op_procedure` | State label. Constant `pre_op_procedure` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `procedure_id` → `dim_procedure.id`
