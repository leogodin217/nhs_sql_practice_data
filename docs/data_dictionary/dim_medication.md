# `dim_medication`

*Group:* Clinical dimensions  
*Grain:* One row per medication type  
*Primary key:* `id`, `valid_from`  
*Rows:* 44

Medication catalogue keyed by synthetic medication ID, categorised using
the British National Formulary (BNF) hierarchy.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `id` | `VARCHAR` | 0 | 44 | `MED_011`, `MED_024`, `MED_026`, … | Synthetic medication identifier (e.g. `MED_011`). |
| `medication_name` | `VARCHAR` | 0 | 44 | `Amiodarone`, `Enoxaparin`, `Omeprazole`, … | Drug name (e.g. `Amiodarone`, `Enoxaparin`). |
| `bnf_category` | `VARCHAR` | 0 | 30 | `4.8.1 Control of epilepsy`, `6.1.2.2 Biguanides`, … | BNF chapter/section label (e.g. `4.8.1 Control of epilepsy`). |
| `route` | `VARCHAR` | 0 | 4 | `oral`, `iv`, `inhaled`, `sc` | Administration route: `oral`, `iv`, `inhaled`, `sc`. |
| `daily_cost` | `DOUBLE` | 0 | 32 | 0.15 – 45.0 | Daily medication cost (£) at the standard dose. |
| `specialty_group` | `VARCHAR` | 0 | 8 | `respiratory`, `musculoskeletal`, `neurological`, … | Specialty most likely to prescribe the medication. |
| `valid_from` | `TIMESTAMP` | 0 | 1 | 2023-01-01 00:00:00 → 2023-01-01 00:00:00 | SCD-2 version start timestamp. |
| `valid_to` | `VARCHAR` | 100.0 | 0 |  | SCD-2 version end. Empty string for the current version. |
