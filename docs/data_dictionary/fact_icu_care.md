# `fact_icu_care`

*Group:* Inpatient facts  
*Grain:* One row per ICU/HDU escalation event  
*Rows:* 762

ICU / HDU escalation events during an inpatient spell. Marks a transfer
into critical care for patients who deteriorate on a general ward.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 762 | 1345 – 600161 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 762 | 2023-01-05 09:36:59 → 2025-12-29 20:49:10 | Time of escalation to critical care. |
| `event_sequence` | `BIGINT` | 0 | 762 | 1683 – 626952 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 720 | `PAT_0000957`, `PAT_0001211`, `PAT_0001434`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `ward_id` | `VARCHAR` | 0 | 10 | `WARD_007`, `WARD_004`, `WARD_005`, `WARD_010`, `WARD_002`, … | Critical care or HDU ward. *(→ `dim_ward.id`)* |
| `spell_id` | `VARCHAR` | 0 | 762 | `inst_01292`, `inst_03726`, `inst_05004`, … | Inpatient spell during which the escalation occurred. |
| `state` | `VARCHAR` | 0 | 1 | `icu_hdu` | State label. Constant `icu_hdu` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `ward_id` → `dim_ward.id`
