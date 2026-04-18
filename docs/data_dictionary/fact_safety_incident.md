# `fact_safety_incident`

*Group:* Other  
*Grain:* One row per reported safety incident  
*Rows:* 418

Patient safety incidents reported on a ward during a spell. Low-volume
table, useful for incident-rate analyses against ward-days.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 418 | 9445 – 598768 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 418 | 2023-02-20 05:07:30 → 2025-12-28 20:20:40 | Time the incident was reported. |
| `event_sequence` | `BIGINT` | 0 | 418 | 10677 – 625513 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 411 | `PAT_0002839`, `PAT_0003782`, `PAT_0004916`, … | Patient involved in the incident. *(→ `dim_patient.id`)* |
| `ward_id` | `VARCHAR` | 0 | 10 | `WARD_010`, `WARD_005`, `WARD_002`, `WARD_009`, `WARD_004`, … | Ward on which the incident occurred. *(→ `dim_ward.id`)* |
| `spell_id` | `VARCHAR` | 0 | 418 | `inst_03353`, `inst_07398`, `inst_11501`, … | Inpatient spell during which the incident occurred. |
| `state` | `VARCHAR` | 0 | 1 | `incident` | State label. Constant `incident` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `ward_id` → `dim_ward.id`
