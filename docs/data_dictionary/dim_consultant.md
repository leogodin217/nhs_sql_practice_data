# `dim_consultant`

*Group:* Clinical dimensions  
*Grain:* One row per consultant-version  
*Primary key:* `id`, `valid_from`  
*Rows:* 25

Consultant workforce — 25 consultants spread across 5 specialty groups,
with grade, capacity, and quality attributes. SCD-2 capable but the
supplied data contains a single current version per consultant.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `id` | `VARCHAR` | 0 | 25 | `CON_013`, `CON_022`, `CON_005`, `CON_003`, `CON_020`, … | Synthetic consultant identifier (e.g. `CON_012`). |
| `consultant_code` | `VARCHAR` | 0 | 25 | `C3010303`, `C3000101`, `C3400606`, `C1100303`, `C3010202`, … | External consultant code used in NHS reporting. |
| `main_specialty` | `BIGINT` | 0 | 5 | 110 – 340 | NHS main specialty code (integer, e.g. 110 = gastroenterology). |
| `grade` | `VARCHAR` | 0 | 3 | `consultant`, `registrar`, `SHO` | Clinical grade: `consultant`, `registrar`, or `SHO`. |
| `quality_rating` | `DOUBLE` | 0 | 21 | 0.58 – 0.95 | Internal quality rating (0.0–1.0). |
| `session_count` | `BIGINT` | 0 | 7 | 3 – 12 | Contracted sessions per week. |
| `capacity_strain` | `DOUBLE` | 0 | 6 | 0.10 – 0.90 | Ratio of demand to capacity. Higher = more stretched. |
| `specialty_group` | `VARCHAR` | 0 | 5 | `respiratory`, `general`, `gastrointestinal`, `cardiac`, … | Broad specialty grouping: `cardiac`, `respiratory`, `gastrointestinal`, `general`, `musculoskeletal`. |
| `valid_from` | `TIMESTAMP` | 0 | 1 | 2023-01-01 00:00:00 → 2023-01-01 00:00:00 | SCD-2 version start timestamp. |
| `valid_to` | `VARCHAR` | 100.0 | 0 |  | SCD-2 version end. Empty string for the current version. |
