# `fact_ward_assignment`

*Group:* Inpatient facts  
*Grain:* One row per ward/bed assignment within a spell  
*Rows:* 6,899

Ward and bed assignments during a spell. A spell can have multiple
rows as patients transfer between wards or beds.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 6,899 | 632 – 602384 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 6,899 | 2023-01-02 14:29:45 → 2025-12-31 23:52:30 | Time the patient was assigned to this ward/bed. |
| `bed_number` | `BIGINT` | 0 | 30 | 1 – 30 | Bed number within the ward (1–30). |
| `event_sequence` | `BIGINT` | 0 | 6,899 | 898 – 629235 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 4,671 | `PAT_0000020`, `PAT_0000052`, `PAT_0000216`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `ward_id` | `VARCHAR` | 0 | 10 | `WARD_010`, `WARD_002`, `WARD_001`, `WARD_003`, `WARD_004`, … | Ward the patient was assigned to. *(→ `dim_ward.id`)* |
| `spell_id` | `VARCHAR` | 0 | 6,899 | `inst_00138`, `inst_00162`, `inst_00852`, … | Inpatient spell identifier. Matches `fact_admission`. |
| `state` | `VARCHAR` | 0 | 1 | `admission_ward` | State label. Constant `admission_ward` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `ward_id` → `dim_ward.id`
