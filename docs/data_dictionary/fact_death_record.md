# `fact_death_record`

*Group:* Other  
*Grain:* One row per in-hospital death  
*Rows:* 263

In-hospital death record. Linked to the spell the patient was in at
time of death. Used for crude mortality rate and HSMR context.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 263 | 1111 – 601304 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 263 | 2023-01-04 17:22:27 → 2025-12-30 19:22:48 | Time of death. |
| `event_sequence` | `BIGINT` | 0 | 263 | 1426 – 628129 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 263 | `PAT_0000399`, `PAT_0002641`, `PAT_0003395`, … | Deceased patient. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 14 | `CON_001`, `CON_002`, `CON_005`, `CON_007`, `CON_020`, … | Consultant of record at time of death. *(→ `dim_consultant.id`)* |
| `spell_id` | `VARCHAR` | 0 | 263 | `inst_00978`, `inst_10920`, `inst_11587`, … | Inpatient spell during which the death occurred. |
| `state` | `VARCHAR` | 0 | 1 | `deceased` | State label. Constant `deceased` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
