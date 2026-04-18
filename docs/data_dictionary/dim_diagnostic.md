# `dim_diagnostic`

*Group:* Clinical dimensions  
*Grain:* One row per diagnostic test type  
*Primary key:* `id`, `valid_from`  
*Rows:* 12

Diagnostic test catalogue (imaging, pathology, cardiology) with cost
and expected turnaround. Used with DM01 6-week wait analysis.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `id` | `VARCHAR` | 0 | 12 | `DIAG_004`, `DIAG_008`, `DIAG_011`, `DIAG_002`, `DIAG_010`, … | Synthetic diagnostic test identifier (e.g. `DIAG_004`). |
| `test_name` | `VARCHAR` | 0 | 12 | `Ultrasound`, `X-Ray`, `Upper GI Endoscopy`, … | Test name (e.g. `Ultrasound`, `Full Blood Count`, `MRI Scan`). |
| `test_type` | `VARCHAR` | 0 | 8 | `blood`, `other`, `ct`, `mri`, `pathology`, `endoscopy`, … | Modality: `blood`, `pathology`, `xray`, `ct`, `mri`, `ultrasound`, `cardiology`, `other`. |
| `cost` | `DOUBLE` | 0 | 12 | 12.0 – 700.0 | Unit cost per test (£). |
| `turnaround_days` | `BIGINT` | 0 | 6 | 0 – 10 | Expected days from order to result. |
| `valid_from` | `TIMESTAMP` | 0 | 1 | 2023-01-01 00:00:00 → 2023-01-01 00:00:00 | SCD-2 version start timestamp. |
| `valid_to` | `VARCHAR` | 100.0 | 0 |  | SCD-2 version end. Empty string for the current version. |
