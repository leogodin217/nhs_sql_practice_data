# `fact_referral_created`

*Group:* Outpatient facts  
*Grain:* One row per outpatient referral  
*Rows:* 18,577

Outpatient referrals received by the trust — typically from a GP. First
event on a referral-to-treatment pathway, keyed by `pathway_id`.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 18,577 | 619 – 602385 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 18,570 | 2023-01-02 09:10:45 → 2025-12-31 16:32:41 | Time the referral was received. |
| `event_sequence` | `BIGINT` | 0 | 18,577 | 885 – 629236 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 11,116 | `PAT_0000106`, `PAT_0000029`, `PAT_0000069`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 25 | `CON_012`, `CON_002`, `CON_001`, `CON_003`, `CON_004`, … | Consultant the referral is addressed to. *(→ `dim_consultant.id`)* |
| `pathway_id` | `VARCHAR` | 0 | 18,577 | `inst_00195`, `inst_00217`, `inst_00238`, … | Outpatient pathway identifier. Unique per referral, shared with subsequent appointments in `fact_appointment_attended`. |
| `state` | `VARCHAR` | 0 | 1 | `referral_received` | State label. Constant `referral_received` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
