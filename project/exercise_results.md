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


### Top 10 busiest days -- what day of the week are they?

```sql
SELECT
    timestamp::DATE AS day,
    DAYNAME(timestamp) AS day_of_week,
    COUNT(*) AS arrivals
FROM fact_ed_arrival
GROUP BY day, day_of_week
ORDER BY arrivals DESC
LIMIT 10;
```

| day        | day_of_week | arrivals |
|------------|-------------|----------|
| 2023-01-01 | Sunday      | 41       |
| 2025-12-23 | Tuesday     | 26       |
| 2025-12-09 | Tuesday     | 25       |
| 2025-06-25 | Wednesday   | 25       |
| 2025-03-10 | Monday      | 25       |
| 2024-12-30 | Monday      | 25       |
| 2025-05-15 | Thursday    | 24       |
| 2024-03-29 | Friday      | 23       |
| 2025-12-29 | Monday      | 23       |
| 2025-11-24 | Monday      | 23       |


### Average arrivals by day of week

```sql
SELECT
    DAYNAME(timestamp) AS day_of_week,
    EXTRACT(ISODOW FROM timestamp)::INTEGER AS day_num,
    COUNT(*) AS total_arrivals,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT timestamp::DATE), 1) AS avg_per_day
FROM fact_ed_arrival
GROUP BY day_of_week, day_num
ORDER BY day_num;
```

| day_of_week | day_num | total_arrivals | avg_per_day |
|-------------|---------|----------------|-------------|
| Monday      | 1       | 1867           | 11.9        |
| Tuesday     | 2       | 1592           | 10.1        |
| Wednesday   | 3       | 1544           | 9.8         |
| Thursday    | 4       | 1668           | 10.7        |
| Friday      | 5       | 1616           | 10.4        |
| Saturday    | 6       | 1273           | 8.2         |
| Sunday      | 7       | 1140           | 7.3         |


---

## Exercise 4: "Why does the ops team dread Mondays?"

### Average daily arrivals by day of week

```sql
SELECT
    DAYNAME(timestamp) AS day_of_week,
    EXTRACT(ISODOW FROM timestamp)::INTEGER AS day_num,
    COUNT(*) AS total_arrivals,
    COUNT(DISTINCT timestamp::DATE) AS num_days,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT timestamp::DATE), 1) AS avg_arrivals_per_day
FROM fact_ed_arrival
GROUP BY day_of_week, day_num
ORDER BY day_num;
```

| day_of_week | day_num | total_arrivals | num_days | avg_arrivals_per_day |
|-------------|---------|----------------|----------|----------------------|
| Monday      | 1       | 1867           | 157      | 11.9                 |
| Tuesday     | 2       | 1592           | 157      | 10.1                 |
| Wednesday   | 3       | 1544           | 157      | 9.8                  |
| Thursday    | 4       | 1668           | 156      | 10.7                 |
| Friday      | 5       | 1616           | 156      | 10.4                 |
| Saturday    | 6       | 1273           | 155      | 8.2                  |
| Sunday      | 7       | 1140           | 156      | 7.3                  |


### Monday effect by year

```sql
SELECT
    EXTRACT(YEAR FROM timestamp)::INTEGER AS yr,
    DAYNAME(timestamp) AS day_of_week,
    EXTRACT(ISODOW FROM timestamp)::INTEGER AS day_num,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT timestamp::DATE), 1) AS avg_arrivals
FROM fact_ed_arrival
GROUP BY yr, day_of_week, day_num
ORDER BY yr, day_num;
```

| yr   | day_of_week | day_num | avg_arrivals |
|------|-------------|---------|--------------|
| 2023 | Monday      | 1       | 8.1          |
| 2023 | Tuesday     | 2       | 7            |
| 2023 | Wednesday   | 3       | 6.7          |
| 2023 | Thursday    | 4       | 7            |
| 2023 | Friday      | 5       | 7.2          |
| 2023 | Saturday    | 6       | 5.2          |
| 2023 | Sunday      | 7       | 4.8          |
| 2024 | Monday      | 1       | 12.4         |
| 2024 | Tuesday     | 2       | 9.9          |
| 2024 | Wednesday   | 3       | 9.7          |
| 2024 | Thursday    | 4       | 10.7         |
| 2024 | Friday      | 5       | 10.4         |
| 2024 | Saturday    | 6       | 7.1          |
| 2024 | Sunday      | 7       | 6.8          |
| 2025 | Monday      | 1       | 15.2         |
| 2025 | Tuesday     | 2       | 13.5         |
| 2025 | Wednesday   | 3       | 13           |
| 2025 | Thursday    | 4       | 14.3         |
| 2025 | Friday      | 5       | 13.5         |
| 2025 | Saturday    | 6       | 12.3         |
| 2025 | Sunday      | 7       | 10.4         |


---

## Exercise 5: "What does our patient population look like?"

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

## Exercise 6: "Are we hitting the 4-hour A&E target?"

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

## Exercise 7: "How long are patients staying?"

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

## Exercise 8: "How many referrals actually turn into appointments?"

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

## Exercise 9: "Are patients satisfied with their care?"

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

## Exercise 10: "Which consultants carry the heaviest load?"

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

## Exercise 11: "What procedures generate the most income?"

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
| Spinal decompression     | major      | 7200   | musculoskeletal  | 76              |


---

## Exercise 12: "Are cancer patients being seen fast enough?"

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

## Exercise 13: "How are the diagnostics team performing?"

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
| blood      | 489       | 3        |
| pathology  | 143       | 3        |


---

## Exercise 14: "What are we prescribing?"

### Top medications by volume

```sql
SELECT
    medication.medication_name,
    medication.bnf_category,
    medication.route,
    COUNT(*) AS times_administered
FROM fact_medication_administered administered
JOIN dim_medication medication
    ON administered.medication_id = medication.id
GROUP BY medication.medication_name, medication.bnf_category, medication.route
ORDER BY times_administered DESC
LIMIT 15;
```

| medication_name  | bnf_category                                  | route   | times_administered |
|------------------|-----------------------------------------------|---------|--------------------|
| Tiotropium       | 3.1.2 Antimuscarinic bronchodilators          | inhaled | 1122               |
| Salbutamol       | 3.1.1.1 Selective beta2 agonists              | inhaled | 1100               |
| Doxycycline      | 5.1.3 Tetracyclines                           | oral    | 1073               |
| Ipratropium      | 3.1.2 Antimuscarinic bronchodilators          | inhaled | 1065               |
| Amoxicillin      | 5.1.1.3 Broad-spectrum penicillins            | oral    | 1060               |
| Prednisolone     | 6.3.2 Glucocorticoid therapy                  | oral    | 1039               |
| Dexamethasone    | 6.3.2 Glucocorticoid therapy                  | iv      | 868                |
| Insulin glargine | 6.1.1.2 Intermediate and long-acting insulins | sc      | 856                |
| Morphine sulfate | 4.7.2 Opioid analgesics                       | iv      | 843                |
| Phenytoin        | 4.8.1 Control of epilepsy                     | oral    | 839                |
| Bisoprolol       | 2.4 Beta-adrenoceptor blocking drugs          | oral    | 837                |
| Levetiracetam    | 4.8.1 Control of epilepsy                     | oral    | 818                |
| Aspirin          | 2.9 Antiplatelet drugs                        | oral    | 816                |
| Metformin        | 6.1.2.2 Biguanides                            | oral    | 805                |
| Ramipril         | 2.5.5.1 ACE inhibitors                        | oral    | 799                |


### Prescribing by condition

```sql
SELECT
    patient.primary_condition,
    medication.bnf_category,
    COUNT(*) AS administrations
FROM fact_medication_administered administered
JOIN fact_admission admission
    ON administered.spell_id = admission.spell_id
JOIN dim_patient patient
    ON admission.patient_id = patient.id AND patient.valid_to IS NULL
JOIN dim_medication medication
    ON administered.medication_id = medication.id
GROUP BY patient.primary_condition, medication.bnf_category
ORDER BY patient.primary_condition, administrations DESC;
```

| primary_condition | bnf_category                                  | administrations |
|-------------------|-----------------------------------------------|-----------------|
| GI                | 4.6 Drugs used in nausea and vertigo          | 1083            |
| GI                | 1.3.5 Proton pump inhibitors                  | 560             |
| GI                | 5.1.12 Quinolones                             | 533             |
| GI                | 1.6.4 Osmotic laxatives                       | 533             |
| GI                | 1.5.1 Aminosalicylates                        | 527             |
| cardiac           | 2.9 Antiplatelet drugs                        | 1471            |
| cardiac           | 2.4 Beta-adrenoceptor blocking drugs          | 769             |
| cardiac           | 2.5.5.1 ACE inhibitors                        | 714             |
| cardiac           | 2.3.2 Drugs for arrhythmias                   | 705             |
| cardiac           | 2.12 Lipid-regulating drugs                   | 702             |
| infectious        | 3.1.2 Antimuscarinic bronchodilators          | 690             |
| infectious        | 3.1.1.1 Selective beta2 agonists              | 352             |
| infectious        | 5.1.1.3 Broad-spectrum penicillins            | 333             |
| infectious        | 6.3.2 Glucocorticoid therapy                  | 310             |
| infectious        | 5.1.3 Tetracyclines                           | 300             |
| neuro             | 4.8.1 Control of epilepsy                     | 917             |
| neuro             | 6.3.2 Glucocorticoid therapy                  | 487             |
| neuro             | 6.1.2.2 Biguanides                            | 465             |
| neuro             | 4.7.2 Opioid analgesics                       | 459             |
| neuro             | 6.1.1.2 Intermediate and long-acting insulins | 452             |
| obstetric         | 4.8.1 Control of epilepsy                     | 566             |
| obstetric         | 6.1.1.2 Intermediate and long-acting insulins | 300             |
| obstetric         | 4.7.2 Opioid analgesics                       | 295             |
| obstetric         | 6.3.2 Glucocorticoid therapy                  | 288             |
| obstetric         | 6.1.2.2 Biguanides                            | 255             |
| ortho             | 10.1.1 Non-steroidal anti-inflammatory drugs  | 1530            |
| ortho             | 4.7.2 Opioid analgesics                       | 506             |
| ortho             | 2.8.1 Parenteral anticoagulants               | 498             |
| ortho             | 4.7.1 Non-opioid analgesics                   | 496             |
| respiratory       | 3.1.2 Antimuscarinic bronchodilators          | 1268            |
| respiratory       | 5.1.3 Tetracyclines                           | 650             |
| respiratory       | 3.1.1.1 Selective beta2 agonists              | 617             |
| respiratory       | 6.3.2 Glucocorticoid therapy                  | 616             |
| respiratory       | 5.1.1.3 Broad-spectrum penicillins            | 608             |


### Estimated medication cost by spell

```sql
SELECT
    admission.spell_id,
    admission.patient_id,
    SUM(medication.daily_cost) AS total_med_cost,
    COUNT(*) AS administrations
FROM fact_medication_administered administered
JOIN fact_admission admission
    ON administered.spell_id = admission.spell_id
JOIN dim_medication medication
    ON administered.medication_id = medication.id
GROUP BY admission.spell_id, admission.patient_id
ORDER BY total_med_cost DESC
LIMIT 15;
```

| spell_id    | patient_id  | total_med_cost | administrations |
|-------------|-------------|----------------|-----------------|
| inst_39677  | PAT_0000310 | 24.3           | 6               |
| inst_101244 | PAT_0001887 | 23.95          | 6               |
| inst_100910 | PAT_0003912 | 23.35          | 7               |
| inst_64792  | PAT_0010340 | 23.2           | 4               |
| inst_95461  | PAT_0009100 | 23.2           | 4               |
| inst_98668  | PAT_0015281 | 22.8           | 8               |
| inst_32401  | PAT_0001182 | 22.75          | 7               |
| inst_20607  | PAT_0002239 | 21.7           | 6               |
| inst_72691  | PAT_0012707 | 20.95          | 5               |
| inst_06076  | PAT_0001405 | 20.75          | 5               |
| inst_55512  | PAT_0002405 | 20.6           | 4               |
| inst_80962  | PAT_0013092 | 20.3           | 7               |
| inst_71785  | PAT_0002586 | 20.3           | 7               |
| inst_59028  | PAT_0001078 | 19.9           | 7               |
| inst_54631  | PAT_0009445 | 19.9           | 4               |


---

## Exercise 15: "What happens to A&E patients after they're admitted?"

### Link ED arrivals to inpatient spells via temporal proximity

```sql
WITH ed_patients AS (
    SELECT
        patient_id,
        attendance_id AS ed_attendance,
        timestamp AS ed_arrival_ts
    FROM fact_ed_arrival
),
ip_spells AS (
    SELECT
        admission.patient_id,
        admission.spell_id AS ip_spell,
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

## Exercise 16: "Are we readmitting too many patients?"

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


### Readmission rate by comorbidity count

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
),
readmit_flags AS (
    SELECT DISTINCT readmit.spell_id AS readmit_spell_id
    FROM spells prior
    JOIN spells readmit
        ON prior.patient_id = readmit.patient_id
        AND readmit.admit_ts > prior.discharge_ts
        AND EXTRACT(EPOCH FROM (readmit.admit_ts - prior.discharge_ts)) / 86400.0 <= 30
)
SELECT
    patient.comorbidity_count,
    COUNT(DISTINCT spell.spell_id) AS total_spells,
    COUNT(DISTINCT readmit.readmit_spell_id) AS readmissions,
    ROUND(100.0 * COUNT(DISTINCT readmit.readmit_spell_id) / COUNT(DISTINCT spell.spell_id), 1) AS readmission_pct
FROM spells spell
JOIN dim_patient patient
    ON spell.patient_id = patient.id AND patient.valid_to IS NULL
LEFT JOIN readmit_flags readmit
    ON spell.spell_id = readmit.readmit_spell_id
GROUP BY patient.comorbidity_count
ORDER BY patient.comorbidity_count;
```

| comorbidity_count | total_spells | readmissions | readmission_pct |
|-------------------|--------------|--------------|-----------------|
| 0                 | 847          | 45           | 5.3             |
| 1                 | 1640         | 84           | 5.1             |
| 2                 | 1469         | 76           | 5.2             |
| 3                 | 842          | 74           | 8.8             |
| 4                 | 390          | 44           | 11.3            |
| 5                 | 157          | 13           | 8.3             |
| 6                 | 45           | 5            | 11.1            |
| 7                 | 9            | 0            | 0               |
| 8                 | 4            | 1            | 25              |


---

## Exercise 17: "What's our mortality rate?"

### Crude in-hospital mortality rate

```sql
SELECT
    (SELECT COUNT(DISTINCT spell_id) FROM fact_death_record) AS deaths,
    COUNT(DISTINCT spell_id) AS total_spells,
    ROUND(100.0 * (SELECT COUNT(DISTINCT spell_id) FROM fact_death_record)
        / COUNT(DISTINCT spell_id), 2) AS mortality_pct
FROM fact_admission;
```

| deaths | total_spells | mortality_pct |
|--------|--------------|---------------|
| 119    | 8128         | 1.46          |


### Mortality by primary condition

```sql
WITH spell_outcomes AS (
    SELECT
        admission.spell_id,
        admission.patient_id,
        CASE WHEN death.spell_id IS NOT NULL THEN 1 ELSE 0 END AS died
    FROM (SELECT DISTINCT spell_id, patient_id FROM fact_admission) admission
    LEFT JOIN (SELECT DISTINCT spell_id FROM fact_death_record) death
        ON admission.spell_id = death.spell_id
)
SELECT
    patient.primary_condition,
    COUNT(*) AS total_spells,
    SUM(outcome.died) AS deaths,
    ROUND(100.0 * SUM(outcome.died) / COUNT(*), 2) AS mortality_pct
FROM spell_outcomes outcome
JOIN dim_patient patient
    ON outcome.patient_id = patient.id AND patient.valid_to IS NULL
GROUP BY patient.primary_condition
ORDER BY mortality_pct DESC;
```

| primary_condition | total_spells | deaths | mortality_pct |
|-------------------|--------------|--------|---------------|
| ortho             | 1178         | 21     | 1.78          |
| neuro             | 1079         | 19     | 1.76          |
| obstetric         | 658          | 10     | 1.52          |
| respiratory       | 1462         | 21     | 1.44          |
| cardiac           | 1703         | 23     | 1.35          |
| infectious        | 799          | 10     | 1.25          |
| GI                | 1249         | 15     | 1.2           |


### Mortality trend by year

```sql
WITH spell_outcomes AS (
    SELECT
        admission.spell_id,
        EXTRACT(YEAR FROM MIN(admission.timestamp))::INTEGER AS yr,
        CASE WHEN death.spell_id IS NOT NULL THEN 1 ELSE 0 END AS died
    FROM fact_admission admission
    LEFT JOIN (SELECT DISTINCT spell_id FROM fact_death_record) death
        ON admission.spell_id = death.spell_id
    GROUP BY admission.spell_id, death.spell_id
)
SELECT
    yr,
    COUNT(*) AS total_spells,
    SUM(died) AS deaths,
    ROUND(100.0 * SUM(died) / COUNT(*), 2) AS mortality_pct
FROM spell_outcomes
GROUP BY yr
ORDER BY yr;
```

| yr   | total_spells | deaths | mortality_pct |
|------|--------------|--------|---------------|
| 2023 | 1636         | 23     | 1.41          |
| 2024 | 2715         | 38     | 1.4           |
| 2025 | 3777         | 58     | 1.54          |


---

## Exercise 18: "Are busy periods less safe?"

### Monthly incident rate

```sql
WITH monthly_incidents AS (
    SELECT DATE_TRUNC('month', timestamp)::DATE AS month, COUNT(*) AS incidents
    FROM fact_safety_incident GROUP BY month
),
monthly_admissions AS (
    SELECT DATE_TRUNC('month', timestamp)::DATE AS month, COUNT(DISTINCT spell_id) AS admissions
    FROM fact_admission GROUP BY month
)
SELECT
    a.month,
    a.admissions,
    COALESCE(i.incidents, 0) AS incidents,
    ROUND(1000.0 * COALESCE(i.incidents, 0) / a.admissions, 1) AS incidents_per_1000
FROM monthly_admissions a
LEFT JOIN monthly_incidents i
    ON a.month = i.month
ORDER BY a.month;
```

| month      | admissions | incidents | incidents_per_1000 |
|------------|------------|-----------|--------------------|
| 2023-01-01 | 75         | 4         | 53.3               |
| 2023-02-01 | 94         | 0         | 0                  |
| 2023-03-01 | 110        | 3         | 27.3               |
| 2023-04-01 | 134        | 0         | 0                  |
| 2023-05-01 | 137        | 3         | 21.9               |
| 2023-06-01 | 117        | 0         | 0                  |
| 2023-07-01 | 136        | 1         | 7.4                |
| 2023-08-01 | 145        | 1         | 6.9                |
| 2023-09-01 | 155        | 3         | 19.4               |
| 2023-10-01 | 155        | 0         | 0                  |
| 2023-11-01 | 199        | 0         | 0                  |
| 2023-12-01 | 179        | 1         | 5.6                |
| 2024-01-01 | 231        | 4         | 17.3               |
| 2024-02-01 | 191        | 6         | 31.4               |
| 2024-03-01 | 245        | 2         | 8.2                |
| 2024-04-01 | 203        | 2         | 9.9                |
| 2024-05-01 | 212        | 5         | 23.6               |
| 2024-06-01 | 212        | 6         | 28.3               |
| 2024-07-01 | 217        | 0         | 0                  |
| 2024-08-01 | 223        | 1         | 4.5                |
| 2024-09-01 | 220        | 4         | 18.2               |
| 2024-10-01 | 246        | 3         | 12.2               |
| 2024-11-01 | 252        | 0         | 0                  |
| 2024-12-01 | 263        | 5         | 19                 |
| 2025-01-01 | 304        | 3         | 9.9                |
| 2025-02-01 | 292        | 8         | 27.4               |
| 2025-03-01 | 328        | 7         | 21.3               |
| 2025-04-01 | 337        | 4         | 11.9               |
| 2025-05-01 | 285        | 3         | 10.5               |
| 2025-06-01 | 276        | 2         | 7.2                |
| 2025-07-01 | 318        | 1         | 3.1                |
| 2025-08-01 | 311        | 5         | 16.1               |
| 2025-09-01 | 329        | 3         | 9.1                |
| 2025-10-01 | 317        | 1         | 3.2                |
| 2025-11-01 | 319        | 6         | 18.8               |
| 2025-12-01 | 361        | 6         | 16.6               |


### Incidents by ward

```sql
SELECT
    ward.ward_name,
    ward.ward_type,
    COUNT(*) AS incidents
FROM fact_safety_incident incident
JOIN dim_ward ward
    ON incident.ward_id = ward.id
GROUP BY ward.ward_name, ward.ward_type
ORDER BY incidents DESC;
```

| ward_name                | ward_type  | incidents |
|--------------------------|------------|-----------|
| Fleming Ward             | general    | 14        |
| Midwifery Unit           | maternity  | 13        |
| Critical Care Unit       | icu_hdu    | 13        |
| Rainbow Ward             | paediatric | 12        |
| Jenner Ward              | general    | 11        |
| Acute Medical Unit (AMU) | assessment | 11        |
| High Dependency Unit     | icu_hdu    | 10        |
| Lister Ward              | general    | 7         |
| Cavell Ward              | step_down  | 6         |
| Nightingale Ward         | general    | 6         |


### Incident rate in winter vs summer

```sql
WITH incident_months AS (
    SELECT
        DATE_TRUNC('month', timestamp)::DATE AS month,
        EXTRACT(MONTH FROM timestamp)::INTEGER AS mo,
        COUNT(*) AS incidents
    FROM fact_safety_incident
    GROUP BY month, mo
),
admission_months AS (
    SELECT
        DATE_TRUNC('month', timestamp)::DATE AS month,
        EXTRACT(MONTH FROM timestamp)::INTEGER AS mo,
        COUNT(DISTINCT spell_id) AS admissions
    FROM fact_admission
    GROUP BY month, mo
)
SELECT
    CASE WHEN a.mo IN (11, 12, 1, 2, 3) THEN 'winter' ELSE 'summer' END AS season,
    SUM(a.admissions) AS total_admissions,
    COALESCE(SUM(i.incidents), 0) AS total_incidents,
    ROUND(1000.0 * COALESCE(SUM(i.incidents), 0) / SUM(a.admissions), 1) AS incidents_per_1000
FROM admission_months a
LEFT JOIN incident_months i
    ON a.month = i.month
GROUP BY season
ORDER BY season;
```

| season | total_admissions | total_incidents | incidents_per_1000 |
|--------|------------------|-----------------|--------------------|
| summer | 4685             | 48              | 10.2               |
| winter | 3443             | 55              | 16                 |


---

## Exercise 19: "Why can't we free up beds?"

### Overall DTOC delay

```sql
WITH dtoc_delays AS (
    SELECT
        dtoc.spell_id,
        dtoc.patient_id,
        dtoc.ward_id,
        MIN(dtoc.timestamp) AS medically_fit_ts,
        MIN(discharge.timestamp) AS discharge_ts,
        EXTRACT(EPOCH FROM (MIN(discharge.timestamp) - MIN(dtoc.timestamp))) / 86400.0 AS delay_days
    FROM fact_dtoc_assessment dtoc
    JOIN fact_discharge discharge
        ON dtoc.spell_id = discharge.spell_id
    GROUP BY dtoc.spell_id, dtoc.patient_id, dtoc.ward_id
)
SELECT
    COUNT(*) AS dtoc_spells,
    ROUND(AVG(delay_days), 1) AS avg_delay_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delay_days), 1) AS median_delay_days,
    ROUND(MAX(delay_days), 1) AS max_delay_days,
    SUM(CASE WHEN delay_days > 7 THEN 1 ELSE 0 END) AS delayed_over_1wk
FROM dtoc_delays;
```

| dtoc_spells | avg_delay_days | median_delay_days | max_delay_days | delayed_over_1wk |
|-------------|----------------|-------------------|----------------|------------------|
| 2117        | 1.3            | 1.2               | 4.2            | 0                |


### DTOC delay by ward

```sql
WITH dtoc_delays AS (
    SELECT
        dtoc.spell_id,
        dtoc.patient_id,
        dtoc.ward_id,
        MIN(dtoc.timestamp) AS medically_fit_ts,
        MIN(discharge.timestamp) AS discharge_ts,
        EXTRACT(EPOCH FROM (MIN(discharge.timestamp) - MIN(dtoc.timestamp))) / 86400.0 AS delay_days
    FROM fact_dtoc_assessment dtoc
    JOIN fact_discharge discharge
        ON dtoc.spell_id = discharge.spell_id
    GROUP BY dtoc.spell_id, dtoc.patient_id, dtoc.ward_id
)
SELECT
    ward.ward_name,
    ward.department,
    COUNT(*) AS dtoc_spells,
    ROUND(AVG(delay_days), 1) AS avg_delay_days
FROM dtoc_delays delay
JOIN dim_ward ward
    ON delay.ward_id = ward.id
GROUP BY ward.ward_name, ward.department
ORDER BY avg_delay_days DESC;
```

| ward_name                | department     | dtoc_spells | avg_delay_days |
|--------------------------|----------------|-------------|----------------|
| Jenner Ward              | surgery        | 210         | 1.4            |
| Critical Care Unit       | critical_care  | 197         | 1.3            |
| Fleming Ward             | medicine       | 224         | 1.3            |
| Acute Medical Unit (AMU) | medicine       | 207         | 1.3            |
| Nightingale Ward         | medicine       | 220         | 1.3            |
| High Dependency Unit     | critical_care  | 212         | 1.3            |
| Rainbow Ward             | women_children | 202         | 1.3            |
| Midwifery Unit           | women_children | 226         | 1.3            |
| Cavell Ward              | medicine       | 224         | 1.3            |
| Lister Ward              | medicine       | 195         | 1.2            |


### DTOC delay by deprivation

```sql
WITH dtoc_delays AS (
    SELECT
        dtoc.spell_id,
        dtoc.patient_id,
        MIN(dtoc.timestamp) AS medically_fit_ts,
        MIN(discharge.timestamp) AS discharge_ts,
        EXTRACT(EPOCH FROM (MIN(discharge.timestamp) - MIN(dtoc.timestamp))) / 86400.0 AS delay_days
    FROM fact_dtoc_assessment dtoc
    JOIN fact_discharge discharge
        ON dtoc.spell_id = discharge.spell_id
    GROUP BY dtoc.spell_id, dtoc.patient_id
)
SELECT
    patient.imd_decile,
    COUNT(*) AS dtoc_spells,
    ROUND(AVG(delay_days), 1) AS avg_delay_days
FROM dtoc_delays delay
JOIN dim_patient patient
    ON delay.patient_id = patient.id AND patient.valid_to IS NULL
GROUP BY patient.imd_decile
ORDER BY patient.imd_decile;
```

| imd_decile | dtoc_spells | avg_delay_days |
|------------|-------------|----------------|
| 1          | 234         | 1.9            |
| 2          | 192         | 1.9            |
| 3          | 290         | 1.9            |
| 4          | 323         | 1              |
| 5          | 349         | 1              |
| 6          | 310         | 1              |
| 7          | 180         | 1              |
| 8          | 128         | 1              |
| 9          | 67          | 1              |
| 10         | 44          | 0.9            |


---

## Exercise 20: "How many beds are we actually using?"

### Ward assignments by ward

```sql
SELECT
    ward.ward_name,
    ward.ward_type,
    ward.total_beds,
    COUNT(*) AS total_assignments
FROM fact_ward_assignment assignment
JOIN dim_ward ward
    ON assignment.ward_id = ward.id
GROUP BY ward.ward_name, ward.ward_type, ward.total_beds
ORDER BY total_assignments DESC;
```

| ward_name                | ward_type  | total_beds | total_assignments |
|--------------------------|------------|------------|-------------------|
| Critical Care Unit       | icu_hdu    | 4          | 586               |
| High Dependency Unit     | icu_hdu    | 3          | 582               |
| Cavell Ward              | step_down  | 7          | 581               |
| Midwifery Unit           | maternity  | 7          | 577               |
| Nightingale Ward         | general    | 10         | 570               |
| Fleming Ward             | general    | 9          | 568               |
| Jenner Ward              | general    | 8          | 561               |
| Lister Ward              | general    | 10         | 542               |
| Acute Medical Unit (AMU) | assessment | 11         | 531               |
| Rainbow Ward             | paediatric | 6          | 518               |


### Monthly ward activity as a proxy for utilisation

```sql
SELECT
    DATE_TRUNC('month', assignment.timestamp)::DATE AS month,
    ward.ward_name,
    ward.total_beds,
    COUNT(*) AS assignments,
    ROUND(COUNT(*) * 1.0 / ward.total_beds, 1) AS assignments_per_bed
FROM fact_ward_assignment assignment
JOIN dim_ward ward
    ON assignment.ward_id = ward.id
GROUP BY month, ward.ward_name, ward.total_beds
ORDER BY month, ward.ward_name;
```

| month      | ward_name                | total_beds | assignments | assignments_per_bed |
|------------|--------------------------|------------|-------------|---------------------|
| 2023-01-01 | Acute Medical Unit (AMU) | 11         | 4           | 0.4                 |
| 2023-01-01 | Cavell Ward              | 7          | 6           | 0.9                 |
| 2023-01-01 | Critical Care Unit       | 4          | 8           | 2                   |
| 2023-01-01 | Fleming Ward             | 9          | 3           | 0.3                 |
| 2023-01-01 | High Dependency Unit     | 3          | 4           | 1.3                 |
| 2023-01-01 | Jenner Ward              | 8          | 4           | 0.5                 |
| 2023-01-01 | Lister Ward              | 10         | 5           | 0.5                 |
| 2023-01-01 | Midwifery Unit           | 7          | 8           | 1.1                 |
| 2023-01-01 | Nightingale Ward         | 10         | 5           | 0.5                 |
| 2023-01-01 | Rainbow Ward             | 6          | 5           | 0.8                 |
| 2023-02-01 | Acute Medical Unit (AMU) | 11         | 8           | 0.7                 |
| 2023-02-01 | Cavell Ward              | 7          | 9           | 1.3                 |
| 2023-02-01 | Critical Care Unit       | 4          | 8           | 2                   |
| 2023-02-01 | Fleming Ward             | 9          | 2           | 0.2                 |
| 2023-02-01 | High Dependency Unit     | 3          | 10          | 3.3                 |
| 2023-02-01 | Jenner Ward              | 8          | 7           | 0.9                 |
| 2023-02-01 | Lister Ward              | 10         | 7           | 0.7                 |
| 2023-02-01 | Midwifery Unit           | 7          | 4           | 0.6                 |
| 2023-02-01 | Nightingale Ward         | 10         | 8           | 0.8                 |
| 2023-02-01 | Rainbow Ward             | 6          | 3           | 0.5                 |
| 2023-03-01 | Acute Medical Unit (AMU) | 11         | 8           | 0.7                 |
| 2023-03-01 | Cavell Ward              | 7          | 6           | 0.9                 |
| 2023-03-01 | Critical Care Unit       | 4          | 3           | 0.8                 |
| 2023-03-01 | Fleming Ward             | 9          | 3           | 0.3                 |
| 2023-03-01 | High Dependency Unit     | 3          | 10          | 3.3                 |
| 2023-03-01 | Jenner Ward              | 8          | 12          | 1.5                 |
| 2023-03-01 | Lister Ward              | 10         | 5           | 0.5                 |
| 2023-03-01 | Midwifery Unit           | 7          | 11          | 1.6                 |
| 2023-03-01 | Nightingale Ward         | 10         | 10          | 1                   |
| 2023-03-01 | Rainbow Ward             | 6          | 5           | 0.8                 |
| 2023-04-01 | Acute Medical Unit (AMU) | 11         | 6           | 0.5                 |
| 2023-04-01 | Cavell Ward              | 7          | 11          | 1.6                 |
| 2023-04-01 | Critical Care Unit       | 4          | 6           | 1.5                 |
| 2023-04-01 | Fleming Ward             | 9          | 11          | 1.2                 |
| 2023-04-01 | High Dependency Unit     | 3          | 12          | 4                   |
| 2023-04-01 | Jenner Ward              | 8          | 12          | 1.5                 |
| 2023-04-01 | Lister Ward              | 10         | 10          | 1                   |
| 2023-04-01 | Midwifery Unit           | 7          | 10          | 1.4                 |
| 2023-04-01 | Nightingale Ward         | 10         | 6           | 0.6                 |
| 2023-04-01 | Rainbow Ward             | 6          | 10          | 1.7                 |
| 2023-05-01 | Acute Medical Unit (AMU) | 11         | 8           | 0.7                 |
| 2023-05-01 | Cavell Ward              | 7          | 7           | 1                   |
| 2023-05-01 | Critical Care Unit       | 4          | 14          | 3.5                 |
| 2023-05-01 | Fleming Ward             | 9          | 8           | 0.9                 |
| 2023-05-01 | High Dependency Unit     | 3          | 11          | 3.7                 |
| 2023-05-01 | Jenner Ward              | 8          | 8           | 1                   |
| 2023-05-01 | Lister Ward              | 10         | 12          | 1.2                 |
| 2023-05-01 | Midwifery Unit           | 7          | 7           | 1                   |
| 2023-05-01 | Nightingale Ward         | 10         | 12          | 1.2                 |
| 2023-05-01 | Rainbow Ward             | 6          | 6           | 1                   |
| 2023-06-01 | Acute Medical Unit (AMU) | 11         | 6           | 0.5                 |
| 2023-06-01 | Cavell Ward              | 7          | 7           | 1                   |
| 2023-06-01 | Critical Care Unit       | 4          | 11          | 2.8                 |
| 2023-06-01 | Fleming Ward             | 9          | 11          | 1.2                 |
| 2023-06-01 | High Dependency Unit     | 3          | 11          | 3.7                 |
| 2023-06-01 | Jenner Ward              | 8          | 7           | 0.9                 |
| 2023-06-01 | Lister Ward              | 10         | 6           | 0.6                 |
| 2023-06-01 | Midwifery Unit           | 7          | 7           | 1                   |
| 2023-06-01 | Nightingale Ward         | 10         | 9           | 0.9                 |
| 2023-06-01 | Rainbow Ward             | 6          | 8           | 1.3                 |
| 2023-07-01 | Acute Medical Unit (AMU) | 11         | 12          | 1.1                 |
| 2023-07-01 | Cavell Ward              | 7          | 11          | 1.6                 |
| 2023-07-01 | Critical Care Unit       | 4          | 8           | 2                   |
| 2023-07-01 | Fleming Ward             | 9          | 6           | 0.7                 |
| 2023-07-01 | High Dependency Unit     | 3          | 7           | 2.3                 |
| 2023-07-01 | Jenner Ward              | 8          | 10          | 1.3                 |
| 2023-07-01 | Lister Ward              | 10         | 11          | 1.1                 |
| 2023-07-01 | Midwifery Unit           | 7          | 11          | 1.6                 |
| 2023-07-01 | Nightingale Ward         | 10         | 8           | 0.8                 |
| 2023-07-01 | Rainbow Ward             | 6          | 11          | 1.8                 |
| 2023-08-01 | Acute Medical Unit (AMU) | 11         | 8           | 0.7                 |
| 2023-08-01 | Cavell Ward              | 7          | 7           | 1                   |
| 2023-08-01 | Critical Care Unit       | 4          | 11          | 2.8                 |
| 2023-08-01 | Fleming Ward             | 9          | 21          | 2.3                 |
| 2023-08-01 | High Dependency Unit     | 3          | 9           | 3                   |
| 2023-08-01 | Jenner Ward              | 8          | 12          | 1.5                 |
| 2023-08-01 | Lister Ward              | 10         | 7           | 0.7                 |
| 2023-08-01 | Midwifery Unit           | 7          | 12          | 1.7                 |
| 2023-08-01 | Nightingale Ward         | 10         | 5           | 0.5                 |
| 2023-08-01 | Rainbow Ward             | 6          | 10          | 1.7                 |
| 2023-09-01 | Acute Medical Unit (AMU) | 11         | 10          | 0.9                 |
| 2023-09-01 | Cavell Ward              | 7          | 3           | 0.4                 |
| 2023-09-01 | Critical Care Unit       | 4          | 13          | 3.3                 |
| 2023-09-01 | Fleming Ward             | 9          | 14          | 1.6                 |
| 2023-09-01 | High Dependency Unit     | 3          | 12          | 4                   |
| 2023-09-01 | Jenner Ward              | 8          | 18          | 2.3                 |
| 2023-09-01 | Lister Ward              | 10         | 12          | 1.2                 |
| 2023-09-01 | Midwifery Unit           | 7          | 12          | 1.7                 |
| 2023-09-01 | Nightingale Ward         | 10         | 12          | 1.2                 |
| 2023-09-01 | Rainbow Ward             | 6          | 9           | 1.5                 |
| 2023-10-01 | Acute Medical Unit (AMU) | 11         | 12          | 1.1                 |
| 2023-10-01 | Cavell Ward              | 7          | 18          | 2.6                 |
| 2023-10-01 | Critical Care Unit       | 4          | 15          | 3.8                 |
| 2023-10-01 | Fleming Ward             | 9          | 7           | 0.8                 |
| 2023-10-01 | High Dependency Unit     | 3          | 11          | 3.7                 |
| 2023-10-01 | Jenner Ward              | 8          | 8           | 1                   |
| 2023-10-01 | Lister Ward              | 10         | 12          | 1.2                 |
| 2023-10-01 | Midwifery Unit           | 7          | 8           | 1.1                 |
| 2023-10-01 | Nightingale Ward         | 10         | 12          | 1.2                 |
| 2023-10-01 | Rainbow Ward             | 6          | 12          | 2                   |
| 2023-11-01 | Acute Medical Unit (AMU) | 11         | 9           | 0.8                 |
| 2023-11-01 | Cavell Ward              | 7          | 16          | 2.3                 |
| 2023-11-01 | Critical Care Unit       | 4          | 18          | 4.5                 |
| 2023-11-01 | Fleming Ward             | 9          | 12          | 1.3                 |
| 2023-11-01 | High Dependency Unit     | 3          | 16          | 5.3                 |
| 2023-11-01 | Jenner Ward              | 8          | 15          | 1.9                 |
| 2023-11-01 | Lister Ward              | 10         | 9           | 0.9                 |
| 2023-11-01 | Midwifery Unit           | 7          | 13          | 1.9                 |
| 2023-11-01 | Nightingale Ward         | 10         | 15          | 1.5                 |
| 2023-11-01 | Rainbow Ward             | 6          | 13          | 2.2                 |
| 2023-12-01 | Acute Medical Unit (AMU) | 11         | 11          | 1                   |
| 2023-12-01 | Cavell Ward              | 7          | 11          | 1.6                 |
| 2023-12-01 | Critical Care Unit       | 4          | 17          | 4.3                 |
| 2023-12-01 | Fleming Ward             | 9          | 8           | 0.9                 |
| 2023-12-01 | High Dependency Unit     | 3          | 16          | 5.3                 |
| 2023-12-01 | Jenner Ward              | 8          | 7           | 0.9                 |
| 2023-12-01 | Lister Ward              | 10         | 13          | 1.3                 |
| 2023-12-01 | Midwifery Unit           | 7          | 9           | 1.3                 |
| 2023-12-01 | Nightingale Ward         | 10         | 15          | 1.5                 |
| 2023-12-01 | Rainbow Ward             | 6          | 18          | 3                   |
| 2024-01-01 | Acute Medical Unit (AMU) | 11         | 13          | 1.2                 |
| 2024-01-01 | Cavell Ward              | 7          | 19          | 2.7                 |
| 2024-01-01 | Critical Care Unit       | 4          | 16          | 4                   |
| 2024-01-01 | Fleming Ward             | 9          | 15          | 1.7                 |
| 2024-01-01 | High Dependency Unit     | 3          | 20          | 6.7                 |
| 2024-01-01 | Jenner Ward              | 8          | 16          | 2                   |
| 2024-01-01 | Lister Ward              | 10         | 14          | 1.4                 |
| 2024-01-01 | Midwifery Unit           | 7          | 24          | 3.4                 |
| 2024-01-01 | Nightingale Ward         | 10         | 13          | 1.3                 |
| 2024-01-01 | Rainbow Ward             | 6          | 16          | 2.7                 |
| 2024-02-01 | Acute Medical Unit (AMU) | 11         | 9           | 0.8                 |
| 2024-02-01 | Cavell Ward              | 7          | 11          | 1.6                 |
| 2024-02-01 | Critical Care Unit       | 4          | 11          | 2.8                 |
| 2024-02-01 | Fleming Ward             | 9          | 17          | 1.9                 |
| 2024-02-01 | High Dependency Unit     | 3          | 16          | 5.3                 |
| 2024-02-01 | Jenner Ward              | 8          | 17          | 2.1                 |
| 2024-02-01 | Lister Ward              | 10         | 15          | 1.5                 |
| 2024-02-01 | Midwifery Unit           | 7          | 13          | 1.9                 |
| 2024-02-01 | Nightingale Ward         | 10         | 15          | 1.5                 |
| 2024-02-01 | Rainbow Ward             | 6          | 9           | 1.5                 |
| 2024-03-01 | Acute Medical Unit (AMU) | 11         | 17          | 1.5                 |
| 2024-03-01 | Cavell Ward              | 7          | 15          | 2.1                 |
| 2024-03-01 | Critical Care Unit       | 4          | 18          | 4.5                 |
| 2024-03-01 | Fleming Ward             | 9          | 18          | 2                   |
| 2024-03-01 | High Dependency Unit     | 3          | 11          | 3.7                 |
| 2024-03-01 | Jenner Ward              | 8          | 16          | 2                   |
| 2024-03-01 | Lister Ward              | 10         | 9           | 0.9                 |
| 2024-03-01 | Midwifery Unit           | 7          | 21          | 3                   |
| 2024-03-01 | Nightingale Ward         | 10         | 18          | 1.8                 |
| 2024-03-01 | Rainbow Ward             | 6          | 20          | 3.3                 |
| 2024-04-01 | Acute Medical Unit (AMU) | 11         | 13          | 1.2                 |
| 2024-04-01 | Cavell Ward              | 7          | 17          | 2.4                 |
| 2024-04-01 | Critical Care Unit       | 4          | 12          | 3                   |
| 2024-04-01 | Fleming Ward             | 9          | 13          | 1.4                 |
| 2024-04-01 | High Dependency Unit     | 3          | 12          | 4                   |
| 2024-04-01 | Jenner Ward              | 8          | 9           | 1.1                 |
| 2024-04-01 | Lister Ward              | 10         | 13          | 1.3                 |
| 2024-04-01 | Midwifery Unit           | 7          | 12          | 1.7                 |
| 2024-04-01 | Nightingale Ward         | 10         | 14          | 1.4                 |
| 2024-04-01 | Rainbow Ward             | 6          | 14          | 2.3                 |
| 2024-05-01 | Acute Medical Unit (AMU) | 11         | 16          | 1.5                 |
| 2024-05-01 | Cavell Ward              | 7          | 21          | 3                   |
| 2024-05-01 | Critical Care Unit       | 4          | 17          | 4.3                 |
| 2024-05-01 | Fleming Ward             | 9          | 15          | 1.7                 |
| 2024-05-01 | High Dependency Unit     | 3          | 19          | 6.3                 |
| 2024-05-01 | Jenner Ward              | 8          | 10          | 1.3                 |
| 2024-05-01 | Lister Ward              | 10         | 16          | 1.6                 |
| 2024-05-01 | Midwifery Unit           | 7          | 16          | 2.3                 |
| 2024-05-01 | Nightingale Ward         | 10         | 21          | 2.1                 |
| 2024-05-01 | Rainbow Ward             | 6          | 12          | 2                   |
| 2024-06-01 | Acute Medical Unit (AMU) | 11         | 11          | 1                   |
| 2024-06-01 | Cavell Ward              | 7          | 25          | 3.6                 |
| 2024-06-01 | Critical Care Unit       | 4          | 17          | 4.3                 |
| 2024-06-01 | Fleming Ward             | 9          | 15          | 1.7                 |
| 2024-06-01 | High Dependency Unit     | 3          | 23          | 7.7                 |
| 2024-06-01 | Jenner Ward              | 8          | 16          | 2                   |
| 2024-06-01 | Lister Ward              | 10         | 17          | 1.7                 |
| 2024-06-01 | Midwifery Unit           | 7          | 5           | 0.7                 |
| 2024-06-01 | Nightingale Ward         | 10         | 21          | 2.1                 |
| 2024-06-01 | Rainbow Ward             | 6          | 12          | 2                   |
| 2024-07-01 | Acute Medical Unit (AMU) | 11         | 13          | 1.2                 |
| 2024-07-01 | Cavell Ward              | 7          | 9           | 1.3                 |
| 2024-07-01 | Critical Care Unit       | 4          | 15          | 3.8                 |
| 2024-07-01 | Fleming Ward             | 9          | 17          | 1.9                 |
| 2024-07-01 | High Dependency Unit     | 3          | 16          | 5.3                 |
| 2024-07-01 | Jenner Ward              | 8          | 12          | 1.5                 |
| 2024-07-01 | Lister Ward              | 10         | 16          | 1.6                 |
| 2024-07-01 | Midwifery Unit           | 7          | 12          | 1.7                 |
| 2024-07-01 | Nightingale Ward         | 10         | 17          | 1.7                 |
| 2024-07-01 | Rainbow Ward             | 6          | 18          | 3                   |
| 2024-08-01 | Acute Medical Unit (AMU) | 11         | 22          | 2                   |
| 2024-08-01 | Cavell Ward              | 7          | 14          | 2                   |
| 2024-08-01 | Critical Care Unit       | 4          | 10          | 2.5                 |
| 2024-08-01 | Fleming Ward             | 9          | 12          | 1.3                 |
| 2024-08-01 | High Dependency Unit     | 3          | 14          | 4.7                 |
| 2024-08-01 | Jenner Ward              | 8          | 18          | 2.3                 |
| 2024-08-01 | Lister Ward              | 10         | 14          | 1.4                 |
| 2024-08-01 | Midwifery Unit           | 7          | 23          | 3.3                 |
| 2024-08-01 | Nightingale Ward         | 10         | 18          | 1.8                 |
| 2024-08-01 | Rainbow Ward             | 6          | 11          | 1.8                 |
| 2024-09-01 | Acute Medical Unit (AMU) | 11         | 16          | 1.5                 |
| 2024-09-01 | Cavell Ward              | 7          | 15          | 2.1                 |
| 2024-09-01 | Critical Care Unit       | 4          | 12          | 3                   |
| 2024-09-01 | Fleming Ward             | 9          | 17          | 1.9                 |
| 2024-09-01 | High Dependency Unit     | 3          | 11          | 3.7                 |
| 2024-09-01 | Jenner Ward              | 8          | 16          | 2                   |
| 2024-09-01 | Lister Ward              | 10         | 18          | 1.8                 |
| 2024-09-01 | Midwifery Unit           | 7          | 14          | 2                   |
| 2024-09-01 | Nightingale Ward         | 10         | 13          | 1.3                 |
| 2024-09-01 | Rainbow Ward             | 6          | 16          | 2.7                 |
| 2024-10-01 | Acute Medical Unit (AMU) | 11         | 21          | 1.9                 |
| 2024-10-01 | Cavell Ward              | 7          | 13          | 1.9                 |
| 2024-10-01 | Critical Care Unit       | 4          | 19          | 4.8                 |
| 2024-10-01 | Fleming Ward             | 9          | 16          | 1.8                 |
| 2024-10-01 | High Dependency Unit     | 3          | 20          | 6.7                 |
| 2024-10-01 | Jenner Ward              | 8          | 11          | 1.4                 |
| 2024-10-01 | Lister Ward              | 10         | 16          | 1.6                 |
| 2024-10-01 | Midwifery Unit           | 7          | 27          | 3.9                 |
| 2024-10-01 | Nightingale Ward         | 10         | 7           | 0.7                 |
| 2024-10-01 | Rainbow Ward             | 6          | 14          | 2.3                 |
| 2024-11-01 | Acute Medical Unit (AMU) | 11         | 7           | 0.6                 |
| 2024-11-01 | Cavell Ward              | 7          | 14          | 2                   |
| 2024-11-01 | Critical Care Unit       | 4          | 17          | 4.3                 |
| 2024-11-01 | Fleming Ward             | 9          | 17          | 1.9                 |
| 2024-11-01 | High Dependency Unit     | 3          | 12          | 4                   |
| 2024-11-01 | Jenner Ward              | 8          | 15          | 1.9                 |
| 2024-11-01 | Lister Ward              | 10         | 18          | 1.8                 |
| 2024-11-01 | Midwifery Unit           | 7          | 23          | 3.3                 |
| 2024-11-01 | Nightingale Ward         | 10         | 15          | 1.5                 |
| 2024-11-01 | Rainbow Ward             | 6          | 14          | 2.3                 |
| 2024-12-01 | Acute Medical Unit (AMU) | 11         | 12          | 1.1                 |
| 2024-12-01 | Cavell Ward              | 7          | 20          | 2.9                 |
| 2024-12-01 | Critical Care Unit       | 4          | 17          | 4.3                 |
| 2024-12-01 | Fleming Ward             | 9          | 14          | 1.6                 |
| 2024-12-01 | High Dependency Unit     | 3          | 21          | 7                   |
| 2024-12-01 | Jenner Ward              | 8          | 23          | 2.9                 |
| 2024-12-01 | Lister Ward              | 10         | 24          | 2.4                 |
| 2024-12-01 | Midwifery Unit           | 7          | 20          | 2.9                 |
| 2024-12-01 | Nightingale Ward         | 10         | 18          | 1.8                 |
| 2024-12-01 | Rainbow Ward             | 6          | 15          | 2.5                 |
| 2025-01-01 | Acute Medical Unit (AMU) | 11         | 27          | 2.5                 |
| 2025-01-01 | Cavell Ward              | 7          | 16          | 2.3                 |
| 2025-01-01 | Critical Care Unit       | 4          | 20          | 5                   |
| 2025-01-01 | Fleming Ward             | 9          | 17          | 1.9                 |
| 2025-01-01 | High Dependency Unit     | 3          | 13          | 4.3                 |
| 2025-01-01 | Jenner Ward              | 8          | 22          | 2.8                 |
| 2025-01-01 | Lister Ward              | 10         | 17          | 1.7                 |
| 2025-01-01 | Midwifery Unit           | 7          | 25          | 3.6                 |
| 2025-01-01 | Nightingale Ward         | 10         | 19          | 1.9                 |
| 2025-01-01 | Rainbow Ward             | 6          | 22          | 3.7                 |
| 2025-02-01 | Acute Medical Unit (AMU) | 11         | 22          | 2                   |
| 2025-02-01 | Cavell Ward              | 7          | 19          | 2.7                 |
| 2025-02-01 | Critical Care Unit       | 4          | 23          | 5.8                 |
| 2025-02-01 | Fleming Ward             | 9          | 22          | 2.4                 |
| 2025-02-01 | High Dependency Unit     | 3          | 22          | 7.3                 |
| 2025-02-01 | Jenner Ward              | 8          | 19          | 2.4                 |
| 2025-02-01 | Lister Ward              | 10         | 20          | 2                   |
| 2025-02-01 | Midwifery Unit           | 7          | 19          | 2.7                 |
| 2025-02-01 | Nightingale Ward         | 10         | 19          | 1.9                 |
| 2025-02-01 | Rainbow Ward             | 6          | 17          | 2.8                 |
| 2025-03-01 | Acute Medical Unit (AMU) | 11         | 21          | 1.9                 |
| 2025-03-01 | Cavell Ward              | 7          | 24          | 3.4                 |
| 2025-03-01 | Critical Care Unit       | 4          | 36          | 9                   |
| 2025-03-01 | Fleming Ward             | 9          | 18          | 2                   |
| 2025-03-01 | High Dependency Unit     | 3          | 26          | 8.7                 |
| 2025-03-01 | Jenner Ward              | 8          | 19          | 2.4                 |
| 2025-03-01 | Lister Ward              | 10         | 23          | 2.3                 |
| 2025-03-01 | Midwifery Unit           | 7          | 36          | 5.1                 |
| 2025-03-01 | Nightingale Ward         | 10         | 16          | 1.6                 |
| 2025-03-01 | Rainbow Ward             | 6          | 13          | 2.2                 |
| 2025-04-01 | Acute Medical Unit (AMU) | 11         | 29          | 2.6                 |
| 2025-04-01 | Cavell Ward              | 7          | 27          | 3.9                 |
| 2025-04-01 | Critical Care Unit       | 4          | 16          | 4                   |
| 2025-04-01 | Fleming Ward             | 9          | 30          | 3.3                 |
| 2025-04-01 | High Dependency Unit     | 3          | 23          | 7.7                 |
| 2025-04-01 | Jenner Ward              | 8          | 12          | 1.5                 |
| 2025-04-01 | Lister Ward              | 10         | 21          | 2.1                 |
| 2025-04-01 | Midwifery Unit           | 7          | 30          | 4.3                 |
| 2025-04-01 | Nightingale Ward         | 10         | 28          | 2.8                 |
| 2025-04-01 | Rainbow Ward             | 6          | 18          | 3                   |
| 2025-05-01 | Acute Medical Unit (AMU) | 11         | 17          | 1.5                 |
| 2025-05-01 | Cavell Ward              | 7          | 20          | 2.9                 |
| 2025-05-01 | Critical Care Unit       | 4          | 13          | 3.3                 |
| 2025-05-01 | Fleming Ward             | 9          | 28          | 3.1                 |
| 2025-05-01 | High Dependency Unit     | 3          | 23          | 7.7                 |
| 2025-05-01 | Jenner Ward              | 8          | 21          | 2.6                 |
| 2025-05-01 | Lister Ward              | 10         | 15          | 1.5                 |
| 2025-05-01 | Midwifery Unit           | 7          | 11          | 1.6                 |
| 2025-05-01 | Nightingale Ward         | 10         | 27          | 2.7                 |
| 2025-05-01 | Rainbow Ward             | 6          | 33          | 5.5                 |
| 2025-06-01 | Acute Medical Unit (AMU) | 11         | 13          | 1.2                 |
| 2025-06-01 | Cavell Ward              | 7          | 21          | 3                   |
| 2025-06-01 | Critical Care Unit       | 4          | 24          | 6                   |
| 2025-06-01 | Fleming Ward             | 9          | 15          | 1.7                 |
| 2025-06-01 | High Dependency Unit     | 3          | 22          | 7.3                 |
| 2025-06-01 | Jenner Ward              | 8          | 20          | 2.5                 |
| 2025-06-01 | Lister Ward              | 10         | 20          | 2                   |
| 2025-06-01 | Midwifery Unit           | 7          | 16          | 2.3                 |
| 2025-06-01 | Nightingale Ward         | 10         | 18          | 1.8                 |
| 2025-06-01 | Rainbow Ward             | 6          | 15          | 2.5                 |
| 2025-07-01 | Acute Medical Unit (AMU) | 11         | 25          | 2.3                 |
| 2025-07-01 | Cavell Ward              | 7          | 25          | 3.6                 |
| 2025-07-01 | Critical Care Unit       | 4          | 15          | 3.8                 |
| 2025-07-01 | Fleming Ward             | 9          | 27          | 3                   |
| 2025-07-01 | High Dependency Unit     | 3          | 20          | 6.7                 |
| 2025-07-01 | Jenner Ward              | 8          | 26          | 3.3                 |
| 2025-07-01 | Lister Ward              | 10         | 27          | 2.7                 |
| 2025-07-01 | Midwifery Unit           | 7          | 20          | 2.9                 |
| 2025-07-01 | Nightingale Ward         | 10         | 28          | 2.8                 |
| 2025-07-01 | Rainbow Ward             | 6          | 17          | 2.8                 |
| 2025-08-01 | Acute Medical Unit (AMU) | 11         | 19          | 1.7                 |
| 2025-08-01 | Cavell Ward              | 7          | 32          | 4.6                 |
| 2025-08-01 | Critical Care Unit       | 4          | 22          | 5.5                 |
| 2025-08-01 | Fleming Ward             | 9          | 27          | 3                   |
| 2025-08-01 | High Dependency Unit     | 3          | 24          | 8                   |
| 2025-08-01 | Jenner Ward              | 8          | 23          | 2.9                 |
| 2025-08-01 | Lister Ward              | 10         | 19          | 1.9                 |
| 2025-08-01 | Midwifery Unit           | 7          | 13          | 1.9                 |
| 2025-08-01 | Nightingale Ward         | 10         | 22          | 2.2                 |
| 2025-08-01 | Rainbow Ward             | 6          | 19          | 3.2                 |
| 2025-09-01 | Acute Medical Unit (AMU) | 11         | 20          | 1.8                 |
| 2025-09-01 | Cavell Ward              | 7          | 22          | 3.1                 |
| 2025-09-01 | Critical Care Unit       | 4          | 25          | 6.3                 |
| 2025-09-01 | Fleming Ward             | 9          | 21          | 2.3                 |
| 2025-09-01 | High Dependency Unit     | 3          | 15          | 5                   |
| 2025-09-01 | Jenner Ward              | 8          | 22          | 2.8                 |
| 2025-09-01 | Lister Ward              | 10         | 20          | 2                   |
| 2025-09-01 | Midwifery Unit           | 7          | 27          | 3.9                 |
| 2025-09-01 | Nightingale Ward         | 10         | 28          | 2.8                 |
| 2025-09-01 | Rainbow Ward             | 6          | 24          | 4                   |
| 2025-10-01 | Acute Medical Unit (AMU) | 11         | 17          | 1.5                 |
| 2025-10-01 | Cavell Ward              | 7          | 20          | 2.9                 |
| 2025-10-01 | Critical Care Unit       | 4          | 33          | 8.3                 |
| 2025-10-01 | Fleming Ward             | 9          | 22          | 2.4                 |
| 2025-10-01 | High Dependency Unit     | 3          | 28          | 9.3                 |
| 2025-10-01 | Jenner Ward              | 8          | 28          | 3.5                 |
| 2025-10-01 | Lister Ward              | 10         | 25          | 2.5                 |
| 2025-10-01 | Midwifery Unit           | 7          | 21          | 3                   |
| 2025-10-01 | Nightingale Ward         | 10         | 18          | 1.8                 |
| 2025-10-01 | Rainbow Ward             | 6          | 23          | 3.8                 |
| 2025-11-01 | Acute Medical Unit (AMU) | 11         | 27          | 2.5                 |
| 2025-11-01 | Cavell Ward              | 7          | 15          | 2.1                 |
| 2025-11-01 | Critical Care Unit       | 4          | 19          | 4.8                 |
| 2025-11-01 | Fleming Ward             | 9          | 17          | 1.9                 |
| 2025-11-01 | High Dependency Unit     | 3          | 18          | 6                   |
| 2025-11-01 | Jenner Ward              | 8          | 23          | 2.9                 |
| 2025-11-01 | Lister Ward              | 10         | 13          | 1.3                 |
| 2025-11-01 | Midwifery Unit           | 7          | 20          | 2.9                 |
| 2025-11-01 | Nightingale Ward         | 10         | 19          | 1.9                 |
| 2025-11-01 | Rainbow Ward             | 6          | 23          | 3.8                 |
| 2025-12-01 | Acute Medical Unit (AMU) | 11         | 22          | 2                   |
| 2025-12-01 | Cavell Ward              | 7          | 35          | 5                   |
| 2025-12-01 | Critical Care Unit       | 4          | 27          | 6.8                 |
| 2025-12-01 | Fleming Ward             | 9          | 32          | 3.6                 |
| 2025-12-01 | High Dependency Unit     | 3          | 24          | 8                   |
| 2025-12-01 | Jenner Ward              | 8          | 27          | 3.4                 |
| 2025-12-01 | Lister Ward              | 10         | 23          | 2.3                 |
| 2025-12-01 | Midwifery Unit           | 7          | 17          | 2.4                 |
| 2025-12-01 | Nightingale Ward         | 10         | 21          | 2.1                 |
| 2025-12-01 | Rainbow Ward             | 6          | 13          | 2.2                 |


---

## Exercise 21: "Which patients cost the most?"

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

## Exercise 22: "Do deprived patients have worse outcomes?"

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

## Exercise 23: "The Medical Director says this winter was the worst yet. Was it?"

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

## Exercise 24: "The Finance Director wants to know our surgical income."

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

## Exercise 25: "Are we keeping patients, or just cycling through them?"

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
WITH patient_episodes AS (
    SELECT patient_id, 'ed' AS pathway, attendance_id AS episode_id FROM fact_ed_arrival
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
    COUNT(DISTINCT episode_id) AS total_episodes,
    COUNT(DISTINCT pathway) AS pathway_types
FROM patient_episodes
GROUP BY patient_id
ORDER BY total_episodes DESC, patient_id
LIMIT 15;
```

| patient_id  | total_episodes | pathway_types |
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
| ortho             | 0                 | 4          | 10       |
| respiratory       | 6                 | 4          | 1        |
| GI                | 8                 | 4          | 1        |
| ortho             | 6                 | 4          | 1        |
| infectious        | 4                 | 4          | 4        |
| GI                | 6                 | 4          | 1        |
| ortho             | 5                 | 4          | 2        |
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
| infectious        | 3                 | 3.6667     | 6        |
| infectious        | 0                 | 3.6667     | 9        |
| neuro             | 5                 | 3.6667     | 3        |
| respiratory       | 3                 | 3.6        | 10       |
| ortho             | 2                 | 3.5556     | 18       |
| neuro             | 3                 | 3.5385     | 13       |
| GI                | 2                 | 3.5263     | 19       |
| GI                | 0                 | 3.5        | 12       |
| obstetric         | 4                 | 3.5        | 4        |
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
| respiratory       | 5                 | 3          | 3        |
| infectious        | 6                 | 3          | 1        |
| neuro             | 6                 | 3          | 2        |
| cardiac           | 6                 | 3          | 1        |
| obstetric         | 5                 | 3          | 2        |
| GI                | 7                 | 3          | 1        |


---

## Exercise 26: "Are we getting better or worse?"

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

## Exercise 27: "Do our patients come back?"

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
