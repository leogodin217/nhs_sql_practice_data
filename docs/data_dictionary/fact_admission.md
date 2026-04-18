# `fact_admission`

*Group:* Inpatient facts  
*Grain:* One or more rows per inpatient spell (events during admission)  
*Rows:* 9,612

Inpatient admission events. A `spell_id` can have multiple rows here,
capturing sub-events in the admission process. For length-of-stay work
use the earliest `timestamp` per `spell_id` as the admission time.

## Notes

A `spell_id` in `fact_admission` is always also present in
`fact_discharge` once the spell has ended. Spells without a matching
discharge are in-progress at the reporting cutoff.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 9,612 | 620 – 602382 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 9,612 | 2023-01-02 02:49:21 → 2025-12-31 23:33:37 | Event timestamp. Use `MIN(timestamp)` per `spell_id` to get the admission time. |
| `event_sequence` | `BIGINT` | 0 | 9,612 | 886 – 629233 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 5,832 | `PAT_0000020`, `PAT_0000052`, `PAT_0000216`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 14 | `CON_002`, `CON_001`, `CON_012`, `CON_005`, `CON_007`, … | Admitting consultant. *(→ `dim_consultant.id`)* |
| `spell_id` | `VARCHAR` | 0 | 9,612 | `inst_00138`, `inst_00162`, `inst_00390`, … | Inpatient spell identifier. Links admission, ward assignments, medication, ICU care, and discharge for the same stay. |
| `state` | `VARCHAR` | 0 | 1 | `admission_triage` | State label for the event. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
