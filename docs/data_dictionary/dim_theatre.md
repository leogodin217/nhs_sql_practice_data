# `dim_theatre`

*Group:* Clinical dimensions  
*Grain:* One row per operating theatre  
*Primary key:* `id`, `valid_from`  
*Rows:* 5

Operating theatres and their scheduling capacity. 5 theatres covering
general surgery, cardiac, orthopaedic, and obstetric use.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `id` | `VARCHAR` | 0 | 5 | `THTR_003`, `THTR_005`, `THTR_001`, `THTR_002`, `THTR_004` | Synthetic theatre identifier (e.g. `THTR_001`). |
| `theatre_name` | `VARCHAR` | 0 | 5 | `Day Surgery Theatre`, `Cardiac Theatre`, … | Theatre name (e.g. `Cardiac Theatre`, `Main Theatre 2`). |
| `specialty` | `VARCHAR` | 0 | 5 | `Obstetrics`, `General / Mixed`, `Trauma & Orthopaedics`, … | Primary specialty served by the theatre. |
| `sessions_per_day` | `BIGINT` | 0 | 3 | 2 – 4 | Scheduled surgical sessions per operational day (2–4). |
| `valid_from` | `TIMESTAMP` | 0 | 1 | 2023-01-01 00:00:00 → 2023-01-01 00:00:00 | SCD-2 version start timestamp. |
| `valid_to` | `VARCHAR` | 100.0 | 0 |  | SCD-2 version end. Empty string for the current version. |
