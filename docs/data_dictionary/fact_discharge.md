# `fact_discharge`

*Group:* Inpatient facts  
*Grain:* One or more rows per completed inpatient spell  
*Rows:* 9,275

Inpatient discharge events. Records the end of an inpatient spell —
patient discharged home, to another provider, or deceased. The earliest
`timestamp` per `spell_id` is the discharge time.

## Notes

This is *not* an A&E departure record. `spell_id`s are shared with
`fact_admission` and only exist once a patient has been admitted as an
inpatient. Length-of-stay = `MIN(discharge.timestamp)` −
`MIN(admission.timestamp)` grouped by `spell_id`.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 9,275 | 915 – 602352 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 9,275 | 2023-01-03 12:10:56 → 2025-12-31 21:22:01 | Discharge event timestamp. Use `MIN(timestamp)` per `spell_id` for the discharge time. |
| `event_sequence` | `BIGINT` | 0 | 9,275 | 1206 – 629203 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 5,632 | `PAT_0000006`, `PAT_0000192`, `PAT_0000366`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 14 | `CON_002`, `CON_001`, `CON_012`, `CON_005`, `CON_007`, … | Discharging consultant. *(→ `dim_consultant.id`)* |
| `spell_id` | `VARCHAR` | 0 | 9,275 | `inst_00138`, `inst_00162`, `inst_00390`, … | Inpatient spell identifier. Always matches a `spell_id` in `fact_admission`. |
| `state` | `VARCHAR` | 0 | 1 | `discharged` | Discharge state (`discharged` in current data). |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
