# `fact_medication_administered`

*Group:* Inpatient facts  
*Grain:* One row per medication administration event  
*Rows:* 11,068

Medication administration events during an inpatient spell. One row per
dose given, linked to the medication catalogue via `medication_id`.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 11,068 | 634 – 602354 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 11,068 | 2023-01-02 20:56:19 → 2025-12-31 23:06:43 | Time the dose was administered. |
| `event_sequence` | `BIGINT` | 0 | 11,068 | 900 – 629205 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 4,422 | `PAT_0000020`, `PAT_0000216`, `PAT_0000399`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `medication_id` | `VARCHAR` | 0 | 42 | `MED_029`, `MED_015`, `MED_022`, … | Medication administered. *(→ `dim_medication.id`)* |
| `spell_id` | `VARCHAR` | 0 | 6,366 | `inst_00852`, `inst_00978`, `inst_01262`, … | Inpatient spell during which the dose was given. |
| `state` | `VARCHAR` | 0 | 1 | `specialty_care` | State label. Constant `specialty_care` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `medication_id` → `dim_medication.id`
