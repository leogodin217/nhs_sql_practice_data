# `dim_ward`

*Group:* Clinical dimensions  
*Grain:* One row per ward-version  
*Primary key:* `id`, `valid_from`  
*Rows:* 10

Hospital wards with capacity, department, and bed-day cost. 10 wards
totalling 75 beds across two sites.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `id` | `VARCHAR` | 0 | 10 | `WARD_009`, `WARD_010`, `WARD_001`, `WARD_006`, `WARD_002`, … | Synthetic ward identifier (e.g. `WARD_001`). |
| `ward_name` | `VARCHAR` | 0 | 10 | `Lister Ward`, `Jenner Ward`, `High Dependency Unit`, … | Human-readable ward name (e.g. `Jenner Ward`, `High Dependency Unit`). |
| `ward_type` | `VARCHAR` | 0 | 6 | `general`, `icu_hdu`, `assessment`, `paediatric`, … | Operational type: `general`, `assessment`, `step_down`, `icu_hdu`, `maternity`, `paediatric`. |
| `department` | `VARCHAR` | 0 | 4 | `medicine`, `critical_care`, `women_children`, `surgery` | Owning department: `medicine`, `surgery`, `critical_care`, `women_children`. |
| `site_code` | `VARCHAR` | 0 | 2 | `RXH01`, `RXH02` | Hospital site code (`RXH01` or `RXH02`). |
| `total_beds` | `BIGINT` | 0 | 8 | 3 – 11 | Number of beds on the ward. |
| `cost_per_bed_day` | `DOUBLE` | 0 | 8 | 280.0 – 1800.0 | Daily cost per occupied bed (£). Used for spell cost analysis. |
| `valid_from` | `TIMESTAMP` | 0 | 1 | 2023-01-01 00:00:00 → 2023-01-01 00:00:00 | SCD-2 version start timestamp. |
| `valid_to` | `VARCHAR` | 100.0 | 0 |  | SCD-2 version end. Empty string for the current version. |
