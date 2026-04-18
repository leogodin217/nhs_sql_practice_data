# `fact_diagnostic_performed`

*Group:* Diagnostics  
*Grain:* One row per completed diagnostic test  
*Rows:* 6,026

Completed diagnostic test event. Match to `fact_diagnostic_ordered` on
`request_id` to compute time-to-test. Not every order has a matching
performed row within the window — right-censored cases remain open.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 6,026 | 3316 – 602325 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 6,026 | 2023-01-19 14:41:31 → 2025-12-31 16:52:41 | Time the test was performed. DM01 clock stop. |
| `event_sequence` | `BIGINT` | 0 | 6,026 | 3905 – 629174 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 4,185 | `PAT_0000268`, `PAT_0000713`, `PAT_0001235`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `diagnostic_id` | `VARCHAR` | 0 | 12 | `DIAG_005`, `DIAG_012`, `DIAG_007`, `DIAG_003`, `DIAG_006`, … | Test performed. *(→ `dim_diagnostic.id`)* |
| `request_id` | `VARCHAR` | 0 | 6,026 | `inst_03479`, `inst_03626`, `inst_03903`, … | Request identifier. Matches `fact_diagnostic_ordered`. |
| `state` | `VARCHAR` | 0 | 1 | `performed` | State label. Constant `performed` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `diagnostic_id` → `dim_diagnostic.id`
