# `dim_patient`

*Group:* Patient dimension  
*Grain:* One row per patient-version  
*Primary key:* `id`, `valid_from`  
*Rows:* 26,720

Patient demographics, clinical flags, and tracked activity counters.
Uses Type-2 Slowly Changing Dimensions: a new row is written each time
a tracked attribute changes (for example `status`, `admission_count`, or
`surgical_referred`), with `valid_from` / `valid_to` bracketing the
version's lifetime. The current version of each patient has
`valid_to` IS NULL.

## Notes

A naive `COUNT(*)` returns historical versions, not patients. Use
`COUNT(DISTINCT id)` or filter to `valid_to IS NULL` for a current
snapshot. All fact tables reference `dim_patient.id` via `patient_id`.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `id` | `VARCHAR` | 0 | 16,341 | `PAT_0000006`, `PAT_0000019`, `PAT_0000041`, … | Synthetic patient identifier (e.g. `PAT_0000066`). Stable across SCD versions. |
| `name` | `VARCHAR` | 0 | 15,745 | `Mr Bryan Davidson`, `Alex Benson`, `Tom Patel-Lawrence`, … | Synthetic patient name. Not used analytically. |
| `person_gender_code` | `BIGINT` | 0 | 2 | 1 – 2 | NHS Data Dictionary gender code (integer). 1 = male, 2 = female, 9 = not specified (typical NHS convention). |
| `ethnic_category` | `VARCHAR` | 0 | 17 | `A`, `H`, `B`, `C`, `G`, `J`, `D`, `N`, … | NHS ethnic category code (A–Z range). |
| `imd_decile` | `BIGINT` | 0 | 10 | 1 – 10 | Index of Multiple Deprivation decile for the patient's lower-layer super output area. 1 = most deprived, 10 = least deprived. |
| `primary_condition` | `VARCHAR` | 0 | 7 | `cardiac`, `respiratory`, `ortho`, `GI`, `neuro`, … | Broad clinical grouping that drives a patient's expected pathway (e.g. respiratory, cardiac, gastrointestinal). |
| `comorbidity_count` | `BIGINT` | 0 | 10 | 0 – 9 | Count of significant comorbid conditions. Used in readmission and LOS stratification. |
| `frailty_score` | `BIGINT` | 0 | 9 | 1 – 9 | Ordinal frailty score. Higher = frailer. |
| `gp_practice_code` | `VARCHAR` | 0 | 20 | `G82001`, `G82002`, `G82003`, `G82005`, `G82004`, `G82009`, … | Referring GP practice code. |
| `pathway_type` | `VARCHAR` | 0 | 3 | `emergency`, `elective`, `cancer` | Dominant care pathway for the patient (elective, emergency, cancer, etc.). |
| `clinician_requirement` | `VARCHAR` | 0 | 1 | `consultant` | Clinician skill level required by the patient's primary condition. Currently constant at `consultant` in the data — the column exists for future grade variation. |
| `status` | `VARCHAR` | 0 | 4 | `active`, `discharged`, `admitted`, `deceased` | Patient lifecycle status (`active`, `admitted`, `discharged`, `deceased`). Changes drive new SCD rows. |
| `admission_count` | `BIGINT` | 0 | 15 | 0 – 14 | Running count of inpatient admissions for the patient at the time the version was written. |
| `total_spell_tariff` | `DOUBLE` | 0 | 1 | 0.0 – 0.0 | Running sum of spell tariffs (£) across the patient's completed spells at the time the version was written. Currently 0.0 for every row — tariff accumulation isn't yet populated by the generator. |
| `surgical_referred` | `BOOLEAN` | 0 | 2 | 1.0% true | Whether the patient has ever been referred for surgery. |
| `cancer_referred` | `BOOLEAN` | 0 | 2 | 0.1% true | Whether the patient has ever been referred on a cancer pathway. |
| `valid_from` | `TIMESTAMP` | 0 | 26,716 | 2023-01-01 00:22:29 → 2025-12-31 23:47:41 | SCD-2 version start timestamp (inclusive). |
| `valid_to` | `TIMESTAMP` | 61.2 | 10,379 | 2023-01-02 23:45:32 → 2025-12-31 23:46:23 | SCD-2 version end timestamp (exclusive). NULL for the current version. |
| `active` | `BOOLEAN` | 0 | 2 | 99.0% true | Whether the patient is an active patient of the trust as of the version's valid window. |
