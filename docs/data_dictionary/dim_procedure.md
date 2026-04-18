# `dim_procedure`

*Group:* Clinical dimensions  
*Grain:* One row per procedure type  
*Primary key:* `id`, `valid_from`  
*Rows:* 35

Surgical procedure catalogue with OPCS-4 clinical codes, HRG payment
codes, complexity tier, and tariff. Drives procedure cost and surgical
income analyses.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `id` | `VARCHAR` | 0 | 35 | `PROC_011`, `PROC_022`, `PROC_030`, … | Synthetic procedure identifier (e.g. `PROC_011`). |
| `procedure_name` | `VARCHAR` | 0 | 35 | `Lung resection`, `Spinal decompression`, … | Procedure name (e.g. `Lung resection`, `Spinal decompression`). |
| `opcs4_code` | `VARCHAR` | 0 | 35 | `K33.4`, `E55.4`, `G45.1`, … | OPCS-4.10 clinical procedure code. |
| `hrg_code` | `VARCHAR` | 0 | 35 | `DZ03B`, `HN13C`, `HN23Z`, … | Healthcare Resource Group code that drives NHS payment. |
| `tariff` | `DOUBLE` | 0 | 29 | 500.0 – 14000.0 | Payment tariff (£) per case. |
| `complexity` | `VARCHAR` | 0 | 4 | `major`, `moderate`, `minor`, `complex` | Complexity tier: `minor`, `moderate`, `major`, `complex`. |
| `specialty_group` | `VARCHAR` | 0 | 5 | `general`, `gastrointestinal`, `cardiac`, `respiratory`, … | Specialty that typically performs the procedure. |
| `valid_from` | `TIMESTAMP` | 0 | 1 | 2023-01-01 00:00:00 → 2023-01-01 00:00:00 | SCD-2 version start timestamp. |
| `valid_to` | `VARCHAR` | 100.0 | 0 |  | SCD-2 version end. Empty string for the current version. |
