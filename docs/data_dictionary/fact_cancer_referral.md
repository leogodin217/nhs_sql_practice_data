# `fact_cancer_referral`

*Group:* Cancer facts  
*Grain:* One row per cancer referral  
*Rows:* 2,865

Cancer pathway referral. Start of the 28-day Faster Diagnosis Standard
(FDS) clock. Paired with `fact_cancer_first_seen` via
`cancer_pathway_id` to measure days from referral to first consultant
appointment.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `decision_id` | `BIGINT` | 0 | 2,865 | 625 – 602378 | Synthetic event identifier. |
| `timestamp` | `TIMESTAMP` | 0 | 2,864 | 2023-01-02 12:14:30 → 2025-12-31 10:30:33 | Time the cancer referral was received. FDS clock start. |
| `event_sequence` | `BIGINT` | 0 | 2,865 | 891 – 629229 | Per-patient event sequence counter. |
| `patient_id` | `VARCHAR` | 0 | 1,582 | `PAT_0000268`, `PAT_0000394`, `PAT_0000713`, … | Patient identifier. *(→ `dim_patient.id`)* |
| `consultant_id` | `VARCHAR` | 0 | 25 | `CON_012`, `CON_002`, `CON_005`, `CON_007`, `CON_001`, … | Receiving consultant. *(→ `dim_consultant.id`)* |
| `cancer_pathway_id` | `VARCHAR` | 0 | 2,865 | `inst_00395`, `inst_00888`, `inst_00945`, … | Cancer pathway identifier. Matches `fact_cancer_first_seen`. |
| `state` | `VARCHAR` | 0 | 1 | `referral_received` | State label. Constant `referral_received` in current data. |

## Relationships

- `patient_id` → `dim_patient.id`
- `consultant_id` → `dim_consultant.id`
