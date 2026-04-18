# `fact_diagnostic_ordered`

*Group:* Diagnostics  
*Grain:* One row per diagnostic test order  
*Rows:* 8,325

Diagnostic test order event. Paired with `fact_diagnostic_performed`
via `request_id` to measure turnaround and DM01 6-week compliance.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 8,325 | 2382 – 602316 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 8,323 | 2023-01-12 10:49:11 → 2025-12-31 16:34:01 | Order time. DM01 clock start. |
| `event_sequence` | `BIGINT` | 0 | 8,325 | 2869 – 629165 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 5,223 | `PAT_0000268`, `PAT_0000132`, `PAT_0000713`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `diagnostic_id` | `VARCHAR` | 0 | 12 | `DIAG_005`, `DIAG_010`, `DIAG_012`, `DIAG_001`, `DIAG_007`, … | Test ordered. *(→ `dim_diagnostic.id`)* |
| `request_id` | `VARCHAR` | 0 | 8,325 | `inst_03479`, `inst_03622`, `inst_03626`, … | Request identifier. Matches the performed row. |
| `state` | `VARCHAR` | 0 | 1 | `ordered` | State label. Constant `ordered` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `diagnostic_id` → `dim_diagnostic.id`
