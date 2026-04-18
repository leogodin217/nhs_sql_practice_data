# `fact_dtoc_assessment`

*Group:* Inpatient facts  
*Grain:* One row per delayed-transfer-of-care assessment  
*Rows:* 6,540

Delayed Transfer of Care (DTOC) assessments. Marks the moment a patient
is declared medically fit for discharge. The gap between this timestamp
and the matching `fact_discharge.timestamp` is the DTOC delay — time
the patient occupies an acute bed waiting for community or social-care
provision.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 6,540 | 922 – 602356 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 6,540 | 2023-01-03 22:29:59 → 2025-12-31 23:14:23 | Time the patient was declared medically fit for discharge. |
| `event_sequence` | `BIGINT` | 0 | 6,540 | 1213 – 629207 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 4,467 | `PAT_0000020`, `PAT_0000052`, `PAT_0000216`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `ward_id` | `VARCHAR` | 0 | 10 | `WARD_010`, `WARD_002`, `WARD_001`, `WARD_003`, `WARD_004`, … | Ward the patient is in at the time of assessment. *(→ `dim_ward.id`)* |
| `spell_id` | `VARCHAR` | 0 | 6,540 | `inst_00162`, `inst_00852`, `inst_01035`, … | Inpatient spell. Matches `fact_admission` / `fact_discharge`. |
| `state` | `VARCHAR` | 0 | 1 | `medically_fit` | State label. Constant `medically_fit` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `ward_id` → `dim_ward.id`
