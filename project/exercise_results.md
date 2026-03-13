# Exercise Results

## Exercise 1: "How many patients does the trust serve?"

### Using DISTINCT

```sql
SELECT COUNT(DISTINCT id) AS patient_count
FROM dim_patient;
```

| patient_count |
|---------------|
| 16659         |


### Only current patients

```sql
SELECT COUNT(*) AS current_patients
FROM dim_patient
WHERE valid_to IS NULL;
```

| current_patients |
|------------------|
| 16659            |


---

## Exercise 2: "What does this hospital look like?"

### Ward summary

```sql
SELECT
    ward_name,
    ward_type,
    department,
    total_beds,
    cost_per_bed_day
FROM dim_ward
ORDER BY total_beds DESC;
```

| ward_name                | ward_type  | department     | total_beds | cost_per_bed_day |
|--------------------------|------------|----------------|------------|------------------|
| Acute Medical Unit (AMU) | assessment | medicine       | 11         | 400              |
| Nightingale Ward         | general    | medicine       | 10         | 350              |
| Lister Ward              | general    | medicine       | 10         | 350              |
| Fleming Ward             | general    | medicine       | 9          | 380              |
| Jenner Ward              | general    | surgery        | 8          | 420              |
| Cavell Ward              | step_down  | medicine       | 7          | 280              |
| Midwifery Unit           | maternity  | women_children | 7          | 450              |
| Rainbow Ward             | paediatric | women_children | 6          | 420              |
| Critical Care Unit       | icu_hdu    | critical_care  | 4          | 1800             |
| High Dependency Unit     | icu_hdu    | critical_care  | 3          | 950              |


### Consultant summary

```sql
SELECT
    specialty_group,
    grade,
    COUNT(*) AS consultants
FROM dim_consultant
GROUP BY specialty_group, grade
ORDER BY specialty_group, grade;
```

| specialty_group  | grade      | consultants |
|------------------|------------|-------------|
| cardiac          | SHO        | 1           |
| cardiac          | consultant | 2           |
| cardiac          | registrar  | 1           |
| gastrointestinal | SHO        | 1           |
| gastrointestinal | consultant | 3           |
| gastrointestinal | registrar  | 1           |
| general          | SHO        | 1           |
| general          | consultant | 3           |
| general          | registrar  | 2           |
| musculoskeletal  | consultant | 2           |
| musculoskeletal  | registrar  | 1           |
| respiratory      | SHO        | 1           |
| respiratory      | consultant | 4           |
| respiratory      | registrar  | 2           |


### Theatre summary

```sql
SELECT
    theatre_name,
    specialty,
    sessions_per_day
FROM dim_theatre;
```

| theatre_name        | specialty                    | sessions_per_day |
|---------------------|------------------------------|------------------|
| Main Theatre 1      | General Surgery              | 3                |
| Main Theatre 2      | Trauma & Orthopaedics        | 3                |
| Cardiac Theatre     | Cardiology / Cardiac Surgery | 2                |
| Day Surgery Theatre | General / Mixed              | 4                |
| Obstetric Theatre   | Obstetrics                   | 2                |


### Quick inventory -- which dimension tables exist?

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'main' AND table_name LIKE 'dim_%'
ORDER BY table_name;
```

| table_name     |
|----------------|
| dim_consultant |
| dim_diagnostic |
| dim_medication |
| dim_patient    |
| dim_procedure  |
| dim_theatre    |
| dim_ward       |


---

## Exercise 3: "What happened on A&E's busiest day?"

### Find the busiest day and break down by triage category

```sql
WITH busiest AS (
    SELECT
        timestamp::DATE AS day,
        COUNT(*) AS arrivals
    FROM fact_ed_arrival
    GROUP BY day
    ORDER BY arrivals DESC
    LIMIT 1
)
SELECT
    triage.triage_category,
    COUNT(*) AS patients
FROM fact_triage triage
WHERE triage.timestamp::DATE = (SELECT day FROM busiest)
GROUP BY triage.triage_category
ORDER BY triage.triage_category;
```

| triage_category | patients |
|-----------------|----------|
| 1               | 3        |
| 2               | 8        |
| 3               | 7        |
| 4               | 16       |
| 5               | 5        |


---

## Exercise 4: "Where do our patients come from?"

### Pathway split

```sql
SELECT
    pathway_type,
    COUNT(*) AS patients
FROM dim_patient
WHERE valid_to IS NULL
GROUP BY pathway_type
ORDER BY patients DESC;
```

| pathway_type | patients |
|--------------|----------|
| elective     | 9194     |
| emergency    | 5783     |
| cancer       | 1682     |


### Primary condition breakdown

```sql
SELECT
    primary_condition,
    COUNT(*) AS patients
FROM dim_patient
WHERE valid_to IS NULL
GROUP BY primary_condition
ORDER BY patients DESC;
```

| primary_condition | patients |
|-------------------|----------|
| cardiac           | 3580     |
| respiratory       | 3083     |
| ortho             | 2515     |
| GI                | 2473     |
| neuro             | 1976     |
| infectious        | 1619     |
| obstetric         | 1413     |


### IMD decile distribution

```sql
SELECT
    imd_decile,
    COUNT(*) AS patients
FROM dim_patient
WHERE valid_to IS NULL
GROUP BY imd_decile
ORDER BY imd_decile;
```

| imd_decile | patients |
|------------|----------|
| 1          | 1976     |
| 2          | 1643     |
| 3          | 2204     |
| 4          | 2566     |
| 5          | 2567     |
| 6          | 2192     |
| 7          | 1550     |
| 8          | 1025     |
| 9          | 558      |
| 10         | 378      |


---

## Exercise 5: "Are we hitting the 4-hour A&E target?"

### Join arrival to assessment on attendance_id

```sql
SELECT
    COUNT(*) AS assessed_patients,
    ROUND(AVG(EXTRACT(EPOCH FROM (assessment.timestamp - arrival.timestamp)) / 60), 0) AS avg_minutes,
    SUM(CASE WHEN EXTRACT(EPOCH FROM (assessment.timestamp - arrival.timestamp)) / 60 <= 240
        THEN 1 ELSE 0 END) AS within_4h,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (assessment.timestamp - arrival.timestamp)) / 60 <= 240
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_within_4h
FROM fact_ed_arrival arrival
JOIN fact_ed_assessment assessment
    ON arrival.attendance_id = assessment.attendance_id;
```

| assessed_patients | avg_minutes | within_4h | pct_within_4h |
|-------------------|-------------|-----------|---------------|
| 10174             | 144         | 8554      | 84.1          |


---

## Exercise 6: "How long are patients staying?"

### ALOS for completed spells

```sql
WITH spells AS (
    SELECT
        admission.spell_id,
        MIN(admission.timestamp) AS admission_ts,
        MIN(discharge.timestamp) AS discharge_ts
    FROM fact_admission admission
    JOIN fact_discharge discharge
        ON admission.spell_id = discharge.spell_id
    GROUP BY admission.spell_id
)
SELECT
    COUNT(*) AS completed_spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (discharge_ts - admission_ts)) / 86400.0), 1) AS mean_los_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY EXTRACT(EPOCH FROM (discharge_ts - admission_ts)) / 86400.0
    ), 1) AS median_los_days
FROM spells;
```

| completed_spells | mean_los_days | median_los_days |
|------------------|---------------|-----------------|
| 5403             | 5.9           | 5.7             |


### ALOS by primary condition

```sql
WITH spells AS (
    SELECT
        admission.spell_id,
        admission.patient_id,
        MIN(admission.timestamp) AS admission_ts,
        MIN(discharge.timestamp) AS discharge_ts
    FROM fact_admission admission
    JOIN fact_discharge discharge
        ON admission.spell_id = discharge.spell_id
    GROUP BY admission.spell_id, admission.patient_id
)
SELECT
    patient.primary_condition,
    COUNT(*) AS spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (spell.discharge_ts - spell.admission_ts)) / 86400.0), 1) AS mean_los
FROM spells spell
JOIN dim_patient patient
    ON spell.patient_id = patient.id AND patient.valid_to IS NULL
GROUP BY patient.primary_condition
ORDER BY mean_los DESC, primary_condition;
```

| primary_condition | spells | mean_los |
|-------------------|--------|----------|
| neuro             | 711    | 6        |
| obstetric         | 428    | 6        |
| GI                | 820    | 5.9      |
| cardiac           | 1124   | 5.9      |
| infectious        | 551    | 5.9      |
| respiratory       | 982    | 5.9      |
| ortho             | 787    | 5.7      |


---

## Exercise 7: "How many referrals actually turn into appointments?"

### Outpatient funnel

```sql
SELECT
    'referrals' AS stage,
    COUNT(DISTINCT pathway_id) AS pathways
FROM fact_referral_created
UNION ALL
SELECT
    'attended',
    COUNT(DISTINCT pathway_id)
FROM fact_appointment_attended
ORDER BY pathways DESC;
```

| stage     | pathways |
|-----------|----------|
| referrals | 9611     |
| attended  | 3776     |


### Referral volume by month

```sql
SELECT
    DATE_TRUNC('month', timestamp)::DATE AS month,
    COUNT(DISTINCT pathway_id) AS referrals
FROM fact_referral_created
GROUP BY month
ORDER BY month;
```

| month      | referrals |
|------------|-----------|
| 2023-01-01 | 239       |
| 2023-02-01 | 176       |
| 2023-03-01 | 199       |
| 2023-04-01 | 137       |
| 2023-05-01 | 155       |
| 2023-06-01 | 150       |
| 2023-07-01 | 137       |
| 2023-08-01 | 191       |
| 2023-09-01 | 181       |
| 2023-10-01 | 190       |
| 2023-11-01 | 238       |
| 2023-12-01 | 217       |
| 2024-01-01 | 296       |
| 2024-02-01 | 245       |
| 2024-03-01 | 256       |
| 2024-04-01 | 251       |
| 2024-05-01 | 226       |
| 2024-06-01 | 216       |
| 2024-07-01 | 271       |
| 2024-08-01 | 286       |
| 2024-09-01 | 251       |
| 2024-10-01 | 293       |
| 2024-11-01 | 257       |
| 2024-12-01 | 354       |
| 2025-01-01 | 385       |
| 2025-02-01 | 347       |
| 2025-03-01 | 307       |
| 2025-04-01 | 320       |
| 2025-05-01 | 313       |
| 2025-06-01 | 340       |
| 2025-07-01 | 371       |
| 2025-08-01 | 327       |
| 2025-09-01 | 344       |
| 2025-10-01 | 388       |
| 2025-11-01 | 347       |
| 2025-12-01 | 410       |


---

## Exercise 8: "Are patients satisfied with their care?"

### FFT overview

```sql
SELECT
    recommendation_score,
    COUNT(*) AS responses,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM fact_fft_response
GROUP BY recommendation_score
ORDER BY recommendation_score;
```

| recommendation_score | responses | pct  |
|----------------------|-----------|------|
| 1                    | 4         | 0.1  |
| 2                    | 54        | 1.2  |
| 3                    | 642       | 14   |
| 4                    | 2017      | 43.9 |
| 5                    | 1880      | 40.9 |


### FFT recommend rate

```sql
SELECT
    COUNT(*) AS total_responses,
    SUM(CASE WHEN recommendation_score >= 4 THEN 1 ELSE 0 END) AS positive,
    ROUND(100.0 * SUM(CASE WHEN recommendation_score >= 4 THEN 1 ELSE 0 END)
        / COUNT(*), 1) AS recommend_pct
FROM fact_fft_response;
```

| total_responses | positive | recommend_pct |
|-----------------|----------|---------------|
| 4597            | 3897     | 84.8          |


---

## Exercise 9: "Which consultants carry the heaviest load?"

### Admissions by consultant

```sql
SELECT
    consultant.id,
    consultant.specialty_group,
    consultant.grade,
    COUNT(*) AS admissions
FROM fact_admission admission
JOIN dim_consultant consultant
    ON admission.consultant_id = consultant.id
GROUP BY consultant.id, consultant.specialty_group, consultant.grade
ORDER BY admissions DESC, consultant.id;
```

| id      | specialty_group  | grade      | admissions |
|---------|------------------|------------|------------|
| CON_012 | musculoskeletal  | consultant | 556        |
| CON_002 | cardiac          | consultant | 521        |
| CON_005 | respiratory      | consultant | 471        |
| CON_001 | cardiac          | consultant | 429        |
| CON_003 | cardiac          | registrar  | 414        |
| CON_007 | respiratory      | consultant | 390        |
| CON_006 | respiratory      | consultant | 380        |
| CON_021 | general          | consultant | 367        |
| CON_020 | general          | consultant | 345        |
| CON_013 | musculoskeletal  | consultant | 344        |
| CON_004 | cardiac          | SHO        | 339        |
| CON_009 | respiratory      | registrar  | 338        |
| CON_017 | gastrointestinal | consultant | 305        |
| CON_015 | gastrointestinal | consultant | 297        |
| CON_011 | respiratory      | SHO        | 288        |
| CON_024 | general          | registrar  | 283        |
| CON_014 | musculoskeletal  | registrar  | 278        |
| CON_010 | respiratory      | registrar  | 253        |
| CON_023 | general          | registrar  | 252        |
| CON_016 | gastrointestinal | consultant | 247        |
| CON_025 | general          | SHO        | 247        |
| CON_022 | general          | consultant | 243        |
| CON_018 | gastrointestinal | registrar  | 234        |
| CON_019 | gastrointestinal | SHO        | 166        |
| CON_008 | respiratory      | consultant | 141        |


### Workload by specialty group

```sql
SELECT
    consultant.specialty_group,
    COUNT(*) AS total_admissions,
    COUNT(DISTINCT admission.patient_id) AS unique_patients
FROM fact_admission admission
JOIN dim_consultant consultant
    ON admission.consultant_id = consultant.id
GROUP BY consultant.specialty_group
ORDER BY total_admissions DESC;
```

| specialty_group  | total_admissions | unique_patients |
|------------------|------------------|-----------------|
| respiratory      | 2261             | 1563            |
| general          | 1737             | 1151            |
| cardiac          | 1703             | 1178            |
| gastrointestinal | 1249             | 824             |
| musculoskeletal  | 1178             | 793             |


---

## Exercise 10: "What procedures cost the most?"

### Procedure tariffs by complexity

```sql
SELECT
    complexity,
    COUNT(*) AS procedures,
    ROUND(AVG(tariff), 0) AS avg_tariff,
    MIN(tariff) AS min_tariff,
    MAX(tariff) AS max_tariff
FROM dim_procedure
GROUP BY complexity
ORDER BY avg_tariff DESC;
```

| complexity | procedures | avg_tariff | min_tariff | max_tariff |
|------------|------------|------------|------------|------------|
| complex    | 7          | 10929      | 8500       | 14000      |
| major      | 11         | 6073       | 3200       | 9500       |
| moderate   | 10         | 2000       | 900        | 3500       |
| minor      | 7          | 686        | 500        | 950        |


### Most expensive procedures actually performed

```sql
SELECT
    proc.procedure_name,
    proc.complexity,
    proc.tariff,
    proc.specialty_group,
    COUNT(*) AS times_performed
FROM fact_pre_op_assessment assessment
JOIN dim_procedure proc
    ON assessment.procedure_id = proc.id
GROUP BY proc.procedure_name, proc.complexity, proc.tariff, proc.specialty_group
ORDER BY proc.tariff DESC
LIMIT 10;
```

| procedure_name           | complexity | tariff | specialty_group  | times_performed |
|--------------------------|------------|--------|------------------|-----------------|
| Aortic valve replacement | complex    | 14000  | cardiac          | 122             |
| CABG                     | complex    | 12500  | cardiac          | 104             |
| Lung resection           | complex    | 11000  | respiratory      | 158             |
| Total hip replacement    | complex    | 10500  | musculoskeletal  | 70              |
| Total knee replacement   | complex    | 10200  | musculoskeletal  | 94              |
| Bowel resection          | complex    | 9800   | gastrointestinal | 84              |
| Thoracotomy              | major      | 9500   | respiratory      | 140             |
| Coronary angioplasty     | complex    | 8500   | cardiac          | 123             |
| Hip hemiarthroplasty     | major      | 7800   | musculoskeletal  | 79              |
| Pacemaker insertion      | major      | 7200   | cardiac          | 108             |


---

## Exercise 11: "Are cancer patients being seen fast enough?"

### Cancer 28-day FDS

```sql
WITH cancer_times AS (
    SELECT
        referral.cancer_pathway_id,
        MIN(referral.timestamp) AS referral_ts,
        MIN(first_seen.timestamp) AS first_seen_ts
    FROM fact_cancer_referral referral
    JOIN fact_cancer_first_seen first_seen
        ON referral.cancer_pathway_id = first_seen.cancer_pathway_id
    GROUP BY referral.cancer_pathway_id
)
SELECT
    COUNT(*) AS pathways_seen,
    ROUND(AVG(EXTRACT(EPOCH FROM (first_seen_ts - referral_ts)) / 86400.0), 0) AS avg_days,
    SUM(CASE WHEN EXTRACT(EPOCH FROM (first_seen_ts - referral_ts)) / 86400.0 <= 28
        THEN 1 ELSE 0 END) AS within_28d,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (first_seen_ts - referral_ts)) / 86400.0 <= 28
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_fds
FROM cancer_times;
```

| pathways_seen | avg_days | within_28d | pct_fds |
|---------------|----------|------------|---------|
| 726           | 10       | 705        | 97.1    |


---

## Exercise 12: "How are the diagnostics team performing?"

### Diagnostic 6-week compliance

```sql
WITH diag_times AS (
    SELECT
        ordered.request_id,
        MIN(ordered.timestamp) AS ordered_ts,
        MIN(performed.timestamp) AS performed_ts
    FROM fact_diagnostic_ordered ordered
    JOIN fact_diagnostic_performed performed
        ON ordered.request_id = performed.request_id
    GROUP BY ordered.request_id
)
SELECT
    COUNT(*) AS tests_completed,
    ROUND(AVG(EXTRACT(EPOCH FROM (performed_ts - ordered_ts)) / 86400.0), 0) AS avg_days,
    SUM(CASE WHEN EXTRACT(EPOCH FROM (performed_ts - ordered_ts)) / 86400.0 <= 42
        THEN 1 ELSE 0 END) AS within_6wk,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (performed_ts - ordered_ts)) / 86400.0 <= 42
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_compliance
FROM diag_times;
```

| tests_completed | avg_days | within_6wk | pct_compliance |
|-----------------|----------|------------|----------------|
| 1371            | 11       | 1329       | 96.9           |


### By test type

```sql
WITH diag_times AS (
    SELECT
        ordered.request_id,
        ordered.diagnostic_id,
        MIN(ordered.timestamp) AS ordered_ts,
        MIN(performed.timestamp) AS performed_ts
    FROM fact_diagnostic_ordered ordered
    JOIN fact_diagnostic_performed performed
        ON ordered.request_id = performed.request_id
    GROUP BY ordered.request_id, ordered.diagnostic_id
)
SELECT
    diagnostic.test_type,
    COUNT(*) AS completed,
    ROUND(AVG(EXTRACT(EPOCH FROM (diag_time.performed_ts - diag_time.ordered_ts)) / 86400.0), 0) AS avg_days
FROM diag_times diag_time
JOIN dim_diagnostic diagnostic
    ON diag_time.diagnostic_id = diagnostic.id
GROUP BY diagnostic.test_type
ORDER BY avg_days DESC;
```

| test_type  | completed | avg_days |
|------------|-----------|----------|
| mri        | 51        | 40       |
| ultrasound | 41        | 39       |
| ct         | 37        | 36       |
| endoscopy  | 121       | 16       |
| other      | 346       | 16       |
| xray       | 143       | 3        |
| pathology  | 143       | 3        |
| blood      | 489       | 3        |


---

## Exercise 13: "What happens to A&E patients after they're admitted?"

### Link ED arrivals to inpatient spells via temporal proximity

```sql
WITH ed_patients AS (
    SELECT
        patient_id,
        attendance_id AS ed_instance,
        timestamp AS ed_arrival_ts
    FROM fact_ed_arrival
),
ip_spells AS (
    SELECT
        admission.patient_id,
        admission.spell_id AS ip_instance,
        MIN(admission.timestamp) AS admit_ts,
        MIN(discharge.timestamp) AS discharge_ts
    FROM fact_admission admission
    JOIN fact_discharge discharge
        ON admission.spell_id = discharge.spell_id
    GROUP BY admission.patient_id, admission.spell_id
)
SELECT
    COUNT(*) AS ed_admitted_spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (inpatient.discharge_ts - inpatient.admit_ts)) / 86400.0), 1) AS ed_alos,
    (SELECT ROUND(AVG(EXTRACT(EPOCH FROM (discharge_ts - admit_ts)) / 86400.0), 1) FROM ip_spells) AS overall_alos
FROM ed_patients ed
JOIN ip_spells inpatient
    ON ed.patient_id = inpatient.patient_id
    AND inpatient.admit_ts BETWEEN ed.ed_arrival_ts AND ed.ed_arrival_ts + INTERVAL '24 hours';
```

| ed_admitted_spells | ed_alos | overall_alos |
|--------------------|---------|--------------|
| 1132               | 5.9     | 5.9          |


---

## Exercise 14: "Are we readmitting too many patients?"

### 30-day readmission rate

```sql
WITH spells AS (
    SELECT
        admission.patient_id,
        admission.spell_id,
        MIN(admission.timestamp) AS admit_ts,
        MIN(discharge.timestamp) AS discharge_ts
    FROM fact_admission admission
    JOIN fact_discharge discharge
        ON admission.spell_id = discharge.spell_id
    GROUP BY admission.patient_id, admission.spell_id
)
SELECT
    COUNT(DISTINCT readmit.spell_id) AS readmissions,
    (SELECT COUNT(*) FROM spells) AS total_completed_spells,
    ROUND(100.0 * COUNT(DISTINCT readmit.spell_id)
        / (SELECT COUNT(*) FROM spells), 1) AS readmission_pct
FROM spells prior
JOIN spells readmit
    ON prior.patient_id = readmit.patient_id
    AND readmit.admit_ts > prior.discharge_ts
    AND EXTRACT(EPOCH FROM (readmit.admit_ts - prior.discharge_ts)) / 86400.0 <= 30;
```

| readmissions | total_completed_spells | readmission_pct |
|--------------|------------------------|-----------------|
| 342          | 5403                   | 6.3             |


---

## Exercise 15: "Which patients cost the most?"

### Procedure costs per patient

```sql
SELECT
    assessment.patient_id,
    patient.primary_condition,
    SUM(proc.tariff) AS total_procedure_cost,
    COUNT(*) AS procedures_performed
FROM fact_pre_op_assessment assessment
JOIN dim_procedure proc
    ON assessment.procedure_id = proc.id
JOIN dim_patient patient
    ON assessment.patient_id = patient.id AND patient.valid_to IS NULL
GROUP BY assessment.patient_id, patient.primary_condition
ORDER BY total_procedure_cost DESC, assessment.patient_id
LIMIT 15;
```

| patient_id  | primary_condition | total_procedure_cost | procedures_performed |
|-------------|-------------------|----------------------|----------------------|
| PAT_0000210 | ortho             | 38400                | 4                    |
| PAT_0000976 | cardiac           | 31600                | 5                    |
| PAT_0001001 | infectious        | 31500                | 3                    |
| PAT_0005178 | infectious        | 31500                | 3                    |
| PAT_0006273 | respiratory       | 31500                | 3                    |
| PAT_0006579 | ortho             | 31200                | 3                    |
| PAT_0000401 | ortho             | 29000                | 4                    |
| PAT_0000043 | GI                | 27900                | 4                    |
| PAT_0003260 | ortho             | 27600                | 3                    |
| PAT_0000491 | ortho             | 27200                | 3                    |
| PAT_0000995 | cardiac           | 26500                | 2                    |
| PAT_0002693 | cardiac           | 26500                | 2                    |
| PAT_0010127 | cardiac           | 26500                | 2                    |
| PAT_0005921 | ortho             | 25500                | 3                    |
| PAT_0001080 | ortho             | 24200                | 3                    |


### Bed-day costs for completed spells

```sql
WITH spell_los AS (
    SELECT
        admission.patient_id,
        admission.spell_id,
        MIN(admission.timestamp) AS admit_ts,
        MIN(discharge.timestamp) AS discharge_ts,
        EXTRACT(EPOCH FROM (MIN(discharge.timestamp) - MIN(admission.timestamp))) / 86400.0 AS los_days
    FROM fact_admission admission
    JOIN fact_discharge discharge
        ON admission.spell_id = discharge.spell_id
    GROUP BY admission.patient_id, admission.spell_id
),
ward_costs AS (
    SELECT
        assignment.spell_id,
        AVG(ward.cost_per_bed_day) AS avg_bed_cost
    FROM fact_ward_assignment assignment
    JOIN dim_ward ward
        ON assignment.ward_id = ward.id
    GROUP BY assignment.spell_id
)
SELECT
    spell.patient_id,
    ROUND(spell.los_days, 1) AS los_days,
    ROUND(cost.avg_bed_cost, 0) AS avg_bed_cost_per_day,
    ROUND(spell.los_days * cost.avg_bed_cost, 0) AS total_bed_cost
FROM spell_los spell
JOIN ward_costs cost
    ON spell.spell_id = cost.spell_id
ORDER BY total_bed_cost DESC
LIMIT 15;
```

| patient_id  | los_days | avg_bed_cost_per_day | total_bed_cost |
|-------------|----------|----------------------|----------------|
| PAT_0006030 | 13.5     | 1800                 | 24278          |
| PAT_0011226 | 10.8     | 1800                 | 19357          |
| PAT_0000624 | 10.7     | 1800                 | 19207          |
| PAT_0002385 | 10.4     | 1800                 | 18810          |
| PAT_0010880 | 10.3     | 1800                 | 18591          |
| PAT_0011671 | 10.1     | 1800                 | 18155          |
| PAT_0006316 | 10.1     | 1800                 | 18142          |
| PAT_0010725 | 9.9      | 1800                 | 17767          |
| PAT_0008334 | 9.8      | 1800                 | 17647          |
| PAT_0004487 | 9.8      | 1800                 | 17638          |
| PAT_0015530 | 9.8      | 1800                 | 17609          |
| PAT_0014279 | 9.4      | 1800                 | 16955          |
| PAT_0007965 | 9.3      | 1800                 | 16764          |
| PAT_0013019 | 8.9      | 1800                 | 15982          |
| PAT_0006435 | 8.9      | 1800                 | 15943          |


---

## Exercise 16: "Do deprived patients have worse outcomes?"

### ALOS by deprivation

```sql
WITH spells AS (
    SELECT
        admission.patient_id,
        admission.spell_id,
        MIN(admission.timestamp) AS admit_ts,
        MIN(discharge.timestamp) AS discharge_ts
    FROM fact_admission admission
    JOIN fact_discharge discharge
        ON admission.spell_id = discharge.spell_id
    GROUP BY admission.patient_id, admission.spell_id
)
SELECT
    patient.imd_decile,
    COUNT(*) AS spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (spell.discharge_ts - spell.admit_ts)) / 86400.0), 1) AS avg_los
FROM spells spell
JOIN dim_patient patient
    ON spell.patient_id = patient.id AND patient.valid_to IS NULL
GROUP BY patient.imd_decile
ORDER BY patient.imd_decile;
```

| imd_decile | spells | avg_los |
|------------|--------|---------|
| 1          | 567    | 7.3     |
| 2          | 522    | 7.4     |
| 3          | 729    | 7.3     |
| 4          | 850    | 5.3     |
| 5          | 881    | 5.4     |
| 6          | 767    | 5.3     |
| 7          | 458    | 5.3     |
| 8          | 332    | 4.3     |
| 9          | 178    | 4.3     |
| 10         | 119    | 4.3     |


### Referral-to-attendance ratio by deprivation

```sql
WITH referral_counts AS (
    SELECT
        referral.patient_id,
        COUNT(DISTINCT referral.pathway_id) AS ref_count
    FROM fact_referral_created referral
    GROUP BY referral.patient_id
),
attendance_counts AS (
    SELECT
        appointment.patient_id,
        COUNT(DISTINCT appointment.pathway_id) AS att_count
    FROM fact_appointment_attended appointment
    GROUP BY appointment.patient_id
)
SELECT
    patient.imd_decile,
    SUM(referral_counts.ref_count) AS referrals,
    COALESCE(SUM(attendance_counts.att_count), 0) AS attended,
    ROUND(100.0 * COALESCE(SUM(attendance_counts.att_count), 0)
        / SUM(referral_counts.ref_count), 1) AS attendance_pct
FROM referral_counts
JOIN dim_patient patient
    ON referral_counts.patient_id = patient.id AND patient.valid_to IS NULL
LEFT JOIN attendance_counts
    ON referral_counts.patient_id = attendance_counts.patient_id
GROUP BY patient.imd_decile
ORDER BY patient.imd_decile;
```

| imd_decile | referrals | attended | attendance_pct |
|------------|-----------|----------|----------------|
| 1          | 1191      | 460      | 38.6           |
| 2          | 897       | 338      | 37.7           |
| 3          | 1240      | 495      | 39.9           |
| 4          | 1512      | 604      | 39.9           |
| 5          | 1433      | 603      | 42.1           |
| 6          | 1330      | 483      | 36.3           |
| 7          | 909       | 342      | 37.6           |
| 8          | 612       | 262      | 42.8           |
| 9          | 291       | 115      | 39.5           |
| 10         | 196       | 74       | 37.8           |


---

## Exercise 17: "The Medical Director says this winter was the worst yet. Was it?"

### Monthly dashboard

```sql
WITH monthly_ed AS (
    SELECT DATE_TRUNC('month', timestamp)::DATE AS month, COUNT(*) AS ed_arrivals
    FROM fact_ed_arrival GROUP BY month
),
monthly_admits AS (
    SELECT DATE_TRUNC('month', MIN(timestamp))::DATE AS month,
           COUNT(DISTINCT spell_id) AS admissions
    FROM fact_admission GROUP BY DATE_TRUNC('month', timestamp)::DATE
),
monthly_discharges AS (
    SELECT DATE_TRUNC('month', timestamp)::DATE AS month, COUNT(*) AS discharges
    FROM fact_discharge GROUP BY month
),
monthly_icu AS (
    SELECT DATE_TRUNC('month', timestamp)::DATE AS month, COUNT(*) AS icu_events
    FROM fact_icu_care GROUP BY month
),
monthly_surgeries AS (
    SELECT DATE_TRUNC('month', timestamp)::DATE AS month, COUNT(*) AS surgeries
    FROM fact_surgery_performed GROUP BY month
)
SELECT
    monthly_ed.month,
    monthly_ed.ed_arrivals,
    COALESCE(monthly_admits.admissions, 0) AS admissions,
    COALESCE(monthly_discharges.discharges, 0) AS discharges,
    COALESCE(monthly_icu.icu_events, 0) AS icu_events,
    COALESCE(monthly_surgeries.surgeries, 0) AS surgeries
FROM monthly_ed
LEFT JOIN monthly_admits
    ON monthly_ed.month = monthly_admits.month
LEFT JOIN monthly_discharges
    ON monthly_ed.month = monthly_discharges.month
LEFT JOIN monthly_icu
    ON monthly_ed.month = monthly_icu.month
LEFT JOIN monthly_surgeries
    ON monthly_ed.month = monthly_surgeries.month
ORDER BY monthly_ed.month;
```

| month      | ed_arrivals | admissions | discharges | icu_events | surgeries |
|------------|-------------|------------|------------|------------|-----------|
| 2023-01-01 | 216         | 75         | 42         | 4          | 0         |
| 2023-02-01 | 185         | 94         | 61         | 5          | 9         |
| 2023-03-01 | 159         | 110        | 75         | 6          | 24        |
| 2023-04-01 | 168         | 134        | 84         | 6          | 31        |
| 2023-05-01 | 163         | 137        | 91         | 9          | 55        |
| 2023-06-01 | 176         | 117        | 78         | 6          | 49        |
| 2023-07-01 | 190         | 136        | 95         | 4          | 49        |
| 2023-08-01 | 194         | 145        | 83         | 3          | 62        |
| 2023-09-01 | 197         | 155        | 107        | 8          | 59        |
| 2023-10-01 | 210         | 155        | 111        | 8          | 75        |
| 2023-11-01 | 254         | 199        | 121        | 12         | 68        |
| 2023-12-01 | 272         | 179        | 124        | 9          | 78        |
| 2024-01-01 | 288         | 231        | 147        | 12         | 83        |
| 2024-02-01 | 249         | 191        | 135        | 8          | 73        |
| 2024-03-01 | 311         | 245        | 153        | 13         | 86        |
| 2024-04-01 | 235         | 203        | 138        | 18         | 92        |
| 2024-05-01 | 278         | 212        | 135        | 11         | 102       |
| 2024-06-01 | 282         | 212        | 138        | 16         | 87        |
| 2024-07-01 | 296         | 217        | 161        | 16         | 90        |
| 2024-08-01 | 276         | 223        | 133        | 8          | 97        |
| 2024-09-01 | 315         | 220        | 149        | 15         | 99        |
| 2024-10-01 | 294         | 246        | 164        | 12         | 98        |
| 2024-11-01 | 300         | 252        | 161        | 12         | 102       |
| 2024-12-01 | 384         | 263        | 163        | 12         | 104       |
| 2025-01-01 | 388         | 304        | 202        | 25         | 112       |
| 2025-02-01 | 364         | 292        | 195        | 10         | 110       |
| 2025-03-01 | 382         | 328        | 239        | 26         | 141       |
| 2025-04-01 | 372         | 337        | 243        | 19         | 163       |
| 2025-05-01 | 408         | 285        | 174        | 15         | 129       |
| 2025-06-01 | 379         | 276        | 188        | 16         | 151       |
| 2025-07-01 | 378         | 318        | 210        | 12         | 151       |
| 2025-08-01 | 411         | 311        | 187        | 20         | 150       |
| 2025-09-01 | 398         | 329        | 226        | 25         | 149       |
| 2025-10-01 | 413         | 317        | 218        | 12         | 121       |
| 2025-11-01 | 436         | 319        | 227        | 18         | 143       |
| 2025-12-01 | 479         | 361        | 245        | 21         | 166       |


### Daily ED arrivals to spot spikes

```sql
SELECT
    timestamp::DATE AS day,
    COUNT(*) AS arrivals
FROM fact_ed_arrival
GROUP BY day
ORDER BY arrivals DESC, day
LIMIT 10;
```

| day        | arrivals |
|------------|----------|
| 2023-01-01 | 41       |
| 2025-12-23 | 26       |
| 2024-12-30 | 25       |
| 2025-03-10 | 25       |
| 2025-06-25 | 25       |
| 2025-12-09 | 25       |
| 2025-05-15 | 24       |
| 2024-03-29 | 23       |
| 2025-11-24 | 23       |
| 2025-12-29 | 23       |


### Winter vs summer by year

```sql
WITH monthly_ed AS (
    SELECT
        DATE_TRUNC('month', timestamp)::DATE AS month,
        EXTRACT(YEAR FROM timestamp)::INTEGER AS yr,
        EXTRACT(MONTH FROM timestamp)::INTEGER AS mo,
        COUNT(*) AS ed_arrivals
    FROM fact_ed_arrival
    GROUP BY month, yr, mo
)
SELECT
    yr,
    CASE WHEN mo IN (11, 12, 1, 2, 3) THEN 'winter' ELSE 'summer' END AS season,
    SUM(ed_arrivals) AS total_ed,
    ROUND(AVG(ed_arrivals), 0) AS avg_monthly_ed
FROM monthly_ed
GROUP BY yr, season
ORDER BY yr, season;
```

| yr   | season | total_ed | avg_monthly_ed |
|------|--------|----------|----------------|
| 2023 | summer | 1298     | 185            |
| 2023 | winter | 1086     | 217            |
| 2024 | summer | 1976     | 282            |
| 2024 | winter | 1532     | 306            |
| 2025 | summer | 2759     | 394            |
| 2025 | winter | 2049     | 410            |


---

## Exercise 18: "The Finance Director wants to know our surgical income."

### Theatre utilisation

```sql
SELECT
    theatre.theatre_name,
    theatre.specialty,
    COUNT(*) AS surgeries,
    ROUND(COUNT(*) * 1.0 / DATEDIFF('day',
        (SELECT MIN(timestamp) FROM fact_surgery_performed),
        (SELECT MAX(timestamp) FROM fact_surgery_performed)
    ), 1) AS per_day
FROM fact_surgery_performed surgery
JOIN dim_theatre theatre
    ON surgery.theatre_id = theatre.id
GROUP BY theatre.theatre_name, theatre.specialty
ORDER BY surgeries DESC;
```

| theatre_name        | specialty                    | surgeries | per_day |
|---------------------|------------------------------|-----------|---------|
| Main Theatre 1      | General Surgery              | 702       | 0.7     |
| Day Surgery Theatre | General / Mixed              | 698       | 0.7     |
| Cardiac Theatre     | Cardiology / Cardiac Surgery | 666       | 0.6     |
| Main Theatre 2      | Trauma & Orthopaedics        | 666       | 0.6     |
| Obstetric Theatre   | Obstetrics                   | 626       | 0.6     |


### Income by procedure complexity

```sql
WITH surgery_procedures AS (
    SELECT
        surgery.surgical_episode_id,
        proc.procedure_name,
        proc.complexity,
        proc.tariff,
        proc.specialty_group
    FROM fact_surgery_performed surgery
    JOIN fact_pre_op_assessment pre_op
        ON surgery.surgical_episode_id = pre_op.surgical_episode_id
    JOIN dim_procedure proc
        ON pre_op.procedure_id = proc.id
)
SELECT
    complexity,
    COUNT(*) AS surgeries,
    ROUND(AVG(tariff), 0) AS avg_tariff,
    SUM(tariff) AS total_income
FROM surgery_procedures
GROUP BY complexity
ORDER BY total_income DESC;
```

| complexity | surgeries | avg_tariff | total_income |
|------------|-----------|------------|--------------|
| complex    | 344       | 11020      | 3791000      |
| major      | 470       | 6148       | 2889500      |
| moderate   | 510       | 1984       | 1012000      |
| minor      | 372       | 659        | 245150       |


---

## Exercise 19: "Are we keeping patients, or just cycling through them?"

### Inpatient spells per patient

```sql
SELECT
    spells_per_patient,
    COUNT(*) AS patients
FROM (
    SELECT
        patient_id,
        COUNT(DISTINCT spell_id) AS spells_per_patient
    FROM fact_admission
    GROUP BY patient_id
)
GROUP BY spells_per_patient
ORDER BY spells_per_patient;
```

| spells_per_patient | patients |
|--------------------|----------|
| 1                  | 3810     |
| 2                  | 1130     |
| 3                  | 347      |
| 4                  | 130      |
| 5                  | 65       |
| 6                  | 19       |
| 7                  | 6        |
| 8                  | 2        |


### Most complex patients (multi-pathway)

```sql
WITH patient_journeys AS (
    SELECT patient_id, 'ed' AS pathway, attendance_id AS journey_id FROM fact_ed_arrival
    UNION ALL
    SELECT patient_id, 'inpatient', spell_id FROM fact_admission
    UNION ALL
    SELECT patient_id, 'outpatient', pathway_id FROM fact_referral_created
    UNION ALL
    SELECT patient_id, 'surgical', surgical_episode_id FROM fact_pre_op_assessment
    UNION ALL
    SELECT patient_id, 'cancer', cancer_pathway_id FROM fact_cancer_referral
)
SELECT
    patient_id,
    COUNT(DISTINCT journey_id) AS total_journeys,
    COUNT(DISTINCT pathway) AS pathway_types
FROM patient_journeys
GROUP BY patient_id
ORDER BY total_journeys DESC, patient_id
LIMIT 15;
```

| patient_id  | total_journeys | pathway_types |
|-------------|----------------|---------------|
| PAT_0000401 | 16             | 3             |
| PAT_0000043 | 14             | 3             |
| PAT_0000976 | 14             | 3             |
| PAT_0001080 | 13             | 3             |
| PAT_0003231 | 13             | 3             |
| PAT_0004053 | 13             | 3             |
| PAT_0007411 | 13             | 3             |
| PAT_0000210 | 12             | 3             |
| PAT_0000499 | 12             | 3             |
| PAT_0001633 | 12             | 3             |
| PAT_0002664 | 12             | 3             |
| PAT_0003847 | 12             | 3             |
| PAT_0004945 | 12             | 3             |
| PAT_0005386 | 12             | 3             |
| PAT_0005387 | 12             | 3             |


### Condition profile of high-frequency patients

```sql
WITH patient_spells AS (
    SELECT
        patient_id,
        COUNT(DISTINCT spell_id) AS spell_count
    FROM fact_admission
    GROUP BY patient_id
    HAVING COUNT(DISTINCT spell_id) >= 3
)
SELECT
    patient.primary_condition,
    patient.comorbidity_count,
    AVG(patient_spells.spell_count) AS avg_spells,
    COUNT(*) AS patients
FROM patient_spells
JOIN dim_patient patient
    ON patient_spells.patient_id = patient.id AND patient.valid_to IS NULL
GROUP BY patient.primary_condition, patient.comorbidity_count
ORDER BY avg_spells DESC;
```

| primary_condition | comorbidity_count | avg_spells | patients |
|-------------------|-------------------|------------|----------|
| ortho             | 4                 | 4.3333     | 12       |
| neuro             | 0                 | 4.1667     | 12       |
| cardiac           | 4                 | 4.1667     | 6        |
| obstetric         | 3                 | 4.1111     | 9        |
| ortho             | 6                 | 4          | 1        |
| infectious        | 4                 | 4          | 4        |
| GI                | 6                 | 4          | 1        |
| ortho             | 5                 | 4          | 2        |
| ortho             | 0                 | 4          | 10       |
| respiratory       | 6                 | 4          | 1        |
| GI                | 8                 | 4          | 1        |
| ortho             | 1                 | 3.9091     | 22       |
| neuro             | 4                 | 3.875      | 8        |
| obstetric         | 2                 | 3.8571     | 7        |
| GI                | 3                 | 3.8261     | 23       |
| infectious        | 2                 | 3.8235     | 17       |
| ortho             | 3                 | 3.8182     | 11       |
| GI                | 5                 | 3.8        | 5        |
| respiratory       | 0                 | 3.7692     | 13       |
| respiratory       | 4                 | 3.75       | 4        |
| cardiac           | 3                 | 3.72       | 25       |
| obstetric         | 1                 | 3.7143     | 14       |
| cardiac           | 1                 | 3.6857     | 35       |
| infectious        | 0                 | 3.6667     | 9        |
| neuro             | 5                 | 3.6667     | 3        |
| infectious        | 3                 | 3.6667     | 6        |
| respiratory       | 3                 | 3.6        | 10       |
| ortho             | 2                 | 3.5556     | 18       |
| neuro             | 3                 | 3.5385     | 13       |
| GI                | 2                 | 3.5263     | 19       |
| obstetric         | 4                 | 3.5        | 4        |
| GI                | 0                 | 3.5        | 12       |
| GI                | 1                 | 3.4783     | 23       |
| neuro             | 1                 | 3.4737     | 19       |
| neuro             | 2                 | 3.4643     | 28       |
| GI                | 4                 | 3.4        | 10       |
| cardiac           | 2                 | 3.3929     | 28       |
| respiratory       | 2                 | 3.3793     | 29       |
| obstetric         | 0                 | 3.3636     | 11       |
| infectious        | 1                 | 3.35       | 20       |
| respiratory       | 1                 | 3.3448     | 29       |
| infectious        | 5                 | 3.3333     | 3        |
| cardiac           | 0                 | 3.2778     | 18       |
| cardiac           | 5                 | 3.25       | 4        |
| GI                | 7                 | 3          | 1        |
| respiratory       | 5                 | 3          | 3        |
| neuro             | 6                 | 3          | 2        |
| cardiac           | 6                 | 3          | 1        |
| infectious        | 6                 | 3          | 1        |
| obstetric         | 5                 | 3          | 2        |


---

## Exercise 20: "Are we getting better or worse?"

### A&E 4-hour performance by quarter

```sql
SELECT
    DATE_TRUNC('quarter', arrival.timestamp)::DATE AS quarter,
    COUNT(*) AS assessed,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (assessment.timestamp - arrival.timestamp)) / 60 <= 240
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_within_4h
FROM fact_ed_arrival arrival
JOIN fact_ed_assessment assessment
    ON arrival.attendance_id = assessment.attendance_id
GROUP BY quarter
ORDER BY quarter;
```

| quarter    | assessed | pct_within_4h |
|------------|----------|---------------|
| 2023-01-01 | 532      | 82.9          |
| 2023-04-01 | 486      | 85.4          |
| 2023-07-01 | 547      | 81.5          |
| 2023-10-01 | 700      | 83.7          |
| 2024-01-01 | 810      | 84.4          |
| 2024-04-01 | 743      | 83            |
| 2024-07-01 | 846      | 83.8          |
| 2024-10-01 | 942      | 83.7          |
| 2025-01-01 | 1071     | 83.8          |
| 2025-04-01 | 1108     | 84            |
| 2025-07-01 | 1125     | 84.9          |
| 2025-10-01 | 1264     | 85.8          |


### Cancer 28-day FDS by quarter

```sql
WITH cancer_times AS (
    SELECT
        referral.cancer_pathway_id,
        MIN(referral.timestamp) AS referral_ts,
        MIN(first_seen.timestamp) AS first_seen_ts
    FROM fact_cancer_referral referral
    JOIN fact_cancer_first_seen first_seen
        ON referral.cancer_pathway_id = first_seen.cancer_pathway_id
    GROUP BY referral.cancer_pathway_id
)
SELECT
    DATE_TRUNC('quarter', referral_ts)::DATE AS quarter,
    COUNT(*) AS pathways,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (first_seen_ts - referral_ts)) / 86400.0 <= 28
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_fds
FROM cancer_times
GROUP BY quarter
ORDER BY quarter;
```

| quarter    | pathways | pct_fds |
|------------|----------|---------|
| 2023-01-01 | 36       | 97.2    |
| 2023-04-01 | 40       | 100     |
| 2023-07-01 | 37       | 100     |
| 2023-10-01 | 37       | 94.6    |
| 2024-01-01 | 62       | 96.8    |
| 2024-04-01 | 50       | 94      |
| 2024-07-01 | 54       | 94.4    |
| 2024-10-01 | 80       | 100     |
| 2025-01-01 | 85       | 97.6    |
| 2025-04-01 | 67       | 92.5    |
| 2025-07-01 | 81       | 97.5    |
| 2025-10-01 | 97       | 99      |


### Diagnostic 6-week compliance by quarter

```sql
WITH diag_times AS (
    SELECT
        ordered.request_id,
        MIN(ordered.timestamp) AS ordered_ts,
        MIN(performed.timestamp) AS performed_ts
    FROM fact_diagnostic_ordered ordered
    JOIN fact_diagnostic_performed performed
        ON ordered.request_id = performed.request_id
    GROUP BY ordered.request_id
)
SELECT
    DATE_TRUNC('quarter', ordered_ts)::DATE AS quarter,
    COUNT(*) AS tests_completed,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (performed_ts - ordered_ts)) / 86400.0 <= 42
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_within_6wk
FROM diag_times
GROUP BY quarter
ORDER BY quarter;
```

| quarter    | tests_completed | pct_within_6wk |
|------------|-----------------|----------------|
| 2023-01-01 | 34              | 100            |
| 2023-04-01 | 60              | 98.3           |
| 2023-07-01 | 79              | 97.5           |
| 2023-10-01 | 75              | 98.7           |
| 2024-01-01 | 107             | 98.1           |
| 2024-04-01 | 138             | 93.5           |
| 2024-07-01 | 130             | 96.9           |
| 2024-10-01 | 140             | 94.3           |
| 2025-01-01 | 144             | 95.1           |
| 2025-04-01 | 179             | 98.3           |
| 2025-07-01 | 140             | 98.6           |
| 2025-10-01 | 145             | 97.9           |


---

## Exercise 21: "Do our patients come back?"

### Build the 2023 cohort and track across years

```sql
WITH all_activity AS (
    SELECT patient_id, timestamp FROM fact_ed_arrival
    UNION ALL
    SELECT patient_id, timestamp FROM fact_admission
    UNION ALL
    SELECT patient_id, timestamp FROM fact_referral_created
    UNION ALL
    SELECT patient_id, timestamp FROM fact_pre_op_assessment
    UNION ALL
    SELECT patient_id, timestamp FROM fact_cancer_referral
    UNION ALL
    SELECT patient_id, timestamp FROM fact_appointment_attended
),
first_activity AS (
    SELECT
        patient_id,
        MIN(timestamp) AS first_ts
    FROM all_activity
    GROUP BY patient_id
),
cohort_2023 AS (
    SELECT patient_id
    FROM first_activity
    WHERE EXTRACT(YEAR FROM first_ts) = 2023
)
SELECT
    EXTRACT(YEAR FROM activity.timestamp)::INTEGER AS activity_year,
    COUNT(DISTINCT activity.patient_id) AS patients_active
FROM all_activity activity
JOIN cohort_2023 cohort
    ON activity.patient_id = cohort.patient_id
GROUP BY activity_year
ORDER BY activity_year;
```

| activity_year | patients_active |
|---------------|-----------------|
| 2023          | 4575            |
| 2024          | 2345            |
| 2025          | 2162            |


---
