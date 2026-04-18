# `fact_surgery_performed`

*Group:* Surgical facts  
*Grain:* One row per completed surgery  
*Rows:* 7,142

Completed surgery event. Carries the theatre it was performed in. Use
with `fact_pre_op_assessment` (via `surgical_episode_id`) to recover
the procedure and its tariff for surgical-income analyses.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 7,142 | 3889 – 602208 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 7,142 | 2023-01-23 11:00:50 → 2025-12-31 17:50:54 | Time the surgery completed. |
| `event_sequence` | `BIGINT` | 0 | 7,142 | 4552 – 629057 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 5,173 | `PAT_0000399`, `PAT_0000432`, `PAT_0000029`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `theatre_id` | `VARCHAR` | 0 | 5 | `THTR_004`, `THTR_001`, `THTR_002`, `THTR_003`, `THTR_005` | Theatre in which the surgery was performed. *(→ `dim_theatre.id`)* |
| `surgical_episode_id` | `VARCHAR` | 0 | 7,142 | `inst_01330`, `inst_02286`, `inst_02314`, … | Surgical episode identifier. Matches the pre-op assessment row. |
| `state` | `VARCHAR` | 0 | 1 | `surgery_performed` | State label. Constant `surgery_performed` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `theatre_id` → `dim_theatre.id`
