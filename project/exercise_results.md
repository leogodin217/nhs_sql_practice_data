# Exercise Results

## Exercise 1: "How many patients does the trust serve?"

### Using DISTINCT

```sql
SELECT COUNT(DISTINCT id) AS patient_count
FROM dim_patient;
```

| patient_count |
|---------------|
| 16341         |


### Only current patients

```sql
SELECT COUNT(*) AS current_patients
FROM dim_patient
WHERE valid_to IS NULL;
```

| current_patients |
|------------------|
| 16341            |


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
| 2025-12-12 | Friday      | 25       |
| 2024-12-30 | Monday      | 25       |
| 2025-08-26 | Tuesday     | 24       |
| 2025-09-10 | Wednesday   | 23       |
| 2025-11-20 | Thursday    | 22       |
| 2025-09-30 | Tuesday     | 22       |
| 2025-10-07 | Tuesday     | 22       |
| 2025-07-21 | Monday      | 22       |
| 2025-12-16 | Tuesday     | 22       |


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
| Monday      | 1       | 1886           | 12          |
| Tuesday     | 2       | 1609           | 10.2        |
| Wednesday   | 3       | 1620           | 10.3        |
| Thursday    | 4       | 1530           | 9.8         |
| Friday      | 5       | 1573           | 10.1        |
| Saturday    | 6       | 1294           | 8.3         |
| Sunday      | 7       | 1198           | 7.8         |


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
| Monday      | 1       | 1886           | 157      | 12                   |
| Tuesday     | 2       | 1609           | 157      | 10.2                 |
| Wednesday   | 3       | 1620           | 157      | 10.3                 |
| Thursday    | 4       | 1530           | 156      | 9.8                  |
| Friday      | 5       | 1573           | 156      | 10.1                 |
| Saturday    | 6       | 1294           | 156      | 8.3                  |
| Sunday      | 7       | 1198           | 154      | 7.8                  |


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
| 2023 | Monday      | 1       | 8.5          |
| 2023 | Tuesday     | 2       | 7.1          |
| 2023 | Wednesday   | 3       | 7.1          |
| 2023 | Thursday    | 4       | 6.5          |
| 2023 | Friday      | 5       | 7            |
| 2023 | Saturday    | 6       | 5.2          |
| 2023 | Sunday      | 7       | 4.6          |
| 2024 | Monday      | 1       | 12.4         |
| 2024 | Tuesday     | 2       | 10.2         |
| 2024 | Wednesday   | 3       | 10.3         |
| 2024 | Thursday    | 4       | 10           |
| 2024 | Friday      | 5       | 9.8          |
| 2024 | Saturday    | 6       | 8.3          |
| 2024 | Sunday      | 7       | 7.5          |
| 2025 | Monday      | 1       | 15.1         |
| 2025 | Tuesday     | 2       | 13.5         |
| 2025 | Wednesday   | 3       | 13.5         |
| 2025 | Thursday    | 4       | 12.9         |
| 2025 | Friday      | 5       | 13.4         |
| 2025 | Saturday    | 6       | 11.5         |
| 2025 | Sunday      | 7       | 11.1         |


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
| elective     | 8917     |
| emergency    | 5850     |
| cancer       | 1574     |


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
| cardiac           | 3598     |
| respiratory       | 2995     |
| GI                | 2514     |
| ortho             | 2413     |
| neuro             | 1898     |
| infectious        | 1595     |
| obstetric         | 1328     |


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
| 1          | 1900     |
| 2          | 1605     |
| 3          | 2157     |
| 4          | 2548     |
| 5          | 2540     |
| 6          | 2158     |
| 7          | 1568     |
| 8          | 903      |
| 9          | 579      |
| 10         | 383      |


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
| 10151             | 142         | 8572      | 84.4          |


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
| 9275             | 5.3           | 4.6             |


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
| neuro             | 1115   | 6.2      |
| cardiac           | 2022   | 5.6      |
| respiratory       | 1705   | 5.6      |
| obstetric         | 713    | 5.2      |
| GI                | 1328   | 5.1      |
| infectious        | 901    | 4.9      |
| ortho             | 1491   | 4.1      |


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
| referrals | 18577    |
| attended  | 13378    |


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
| 2023-01-01 | 335       |
| 2023-02-01 | 302       |
| 2023-03-01 | 312       |
| 2023-04-01 | 251       |
| 2023-05-01 | 340       |
| 2023-06-01 | 296       |
| 2023-07-01 | 335       |
| 2023-08-01 | 374       |
| 2023-09-01 | 342       |
| 2023-10-01 | 389       |
| 2023-11-01 | 376       |
| 2023-12-01 | 403       |
| 2024-01-01 | 521       |
| 2024-02-01 | 459       |
| 2024-03-01 | 465       |
| 2024-04-01 | 511       |
| 2024-05-01 | 495       |
| 2024-06-01 | 468       |
| 2024-07-01 | 545       |
| 2024-08-01 | 509       |
| 2024-09-01 | 511       |
| 2024-10-01 | 553       |
| 2024-11-01 | 499       |
| 2024-12-01 | 665       |
| 2025-01-01 | 733       |
| 2025-02-01 | 625       |
| 2025-03-01 | 644       |
| 2025-04-01 | 676       |
| 2025-05-01 | 634       |
| 2025-06-01 | 612       |
| 2025-07-01 | 696       |
| 2025-08-01 | 648       |
| 2025-09-01 | 753       |
| 2025-10-01 | 735       |
| 2025-11-01 | 691       |
| 2025-12-01 | 874       |


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
| 1                    | 3         | 0    |
| 2                    | 71        | 0.8  |
| 3                    | 1030      | 12   |
| 4                    | 3542      | 41.2 |
| 5                    | 3948      | 45.9 |


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
| 8594            | 7490     | 87.2          |


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
| CON_002 | cardiac          | consultant | 1106       |
| CON_001 | cardiac          | consultant | 1007       |
| CON_012 | musculoskeletal  | consultant | 961        |
| CON_005 | respiratory      | consultant | 883        |
| CON_007 | respiratory      | consultant | 791        |
| CON_006 | respiratory      | consultant | 775        |
| CON_021 | general          | consultant | 688        |
| CON_020 | general          | consultant | 627        |
| CON_022 | general          | consultant | 589        |
| CON_013 | musculoskeletal  | consultant | 564        |
| CON_017 | gastrointestinal | consultant | 516        |
| CON_015 | gastrointestinal | consultant | 427        |
| CON_016 | gastrointestinal | consultant | 423        |
| CON_008 | respiratory      | consultant | 255        |


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
| respiratory      | 2704             | 1654            |
| cardiac          | 2113             | 1268            |
| general          | 1904             | 1168            |
| musculoskeletal  | 1525             | 894             |
| gastrointestinal | 1366             | 848             |


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
| Aortic valve replacement | complex    | 14000  | cardiac          | 266             |
| CABG                     | complex    | 12500  | cardiac          | 281             |
| Lung resection           | complex    | 11000  | respiratory      | 273             |
| Total hip replacement    | complex    | 10500  | musculoskeletal  | 195             |
| Total knee replacement   | complex    | 10200  | musculoskeletal  | 199             |
| Bowel resection          | complex    | 9800   | gastrointestinal | 166             |
| Thoracotomy              | major      | 9500   | respiratory      | 302             |
| Coronary angioplasty     | complex    | 8500   | cardiac          | 287             |
| Hip hemiarthroplasty     | major      | 7800   | musculoskeletal  | 208             |
| Pacemaker insertion      | major      | 7200   | cardiac          | 270             |


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
| 2796          | 20       | 2142       | 76.6    |


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
| 6026            | 12       | 5730       | 95.1           |


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
| mri        | 114       | 63       |
| ct         | 218       | 40       |
| ultrasound | 345       | 26       |
| other      | 1386      | 19       |
| endoscopy  | 492       | 18       |
| pathology  | 697       | 4        |
| xray       | 681       | 4        |
| blood      | 2093      | 4        |


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

| medication_name  | bnf_category                         | route   | times_administered |
|------------------|--------------------------------------|---------|--------------------|
| Aspirin          | 2.9 Antiplatelet drugs               | oral    | 491                |
| Amiodarone       | 2.3.2 Drugs for arrhythmias          | oral    | 478                |
| Atorvastatin     | 2.12 Lipid-regulating drugs          | oral    | 469                |
| Clopidogrel      | 2.9 Antiplatelet drugs               | oral    | 468                |
| Bisoprolol       | 2.4 Beta-adrenoceptor blocking drugs | oral    | 465                |
| Ramipril         | 2.5.5.1 ACE inhibitors               | oral    | 433                |
| Prednisolone     | 6.3.2 Glucocorticoid therapy         | oral    | 338                |
| Amoxicillin      | 5.1.1.3 Broad-spectrum penicillins   | oral    | 321                |
| Ipratropium      | 3.1.2 Antimuscarinic bronchodilators | inhaled | 319                |
| Doxycycline      | 5.1.3 Tetracyclines                  | oral    | 319                |
| Phenytoin        | 4.8.1 Control of epilepsy            | oral    | 317                |
| Dexamethasone    | 6.3.2 Glucocorticoid therapy         | iv      | 317                |
| Sodium valproate | 4.8.1 Control of epilepsy            | oral    | 315                |
| Tiotropium       | 3.1.2 Antimuscarinic bronchodilators | inhaled | 314                |
| Salbutamol       | 3.1.1.1 Selective beta2 agonists     | inhaled | 300                |


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

| primary_condition | bnf_category                                 | administrations |
|-------------------|----------------------------------------------|-----------------|
| GI                | 4.6 Drugs used in nausea and vertigo         | 433             |
| GI                | 1.6.4 Osmotic laxatives                      | 237             |
| GI                | 5.1.12 Quinolones                            | 214             |
| GI                | 1.5.1 Aminosalicylates                       | 210             |
| GI                | 1.3.5 Proton pump inhibitors                 | 197             |
| cardiac           | 2.9 Antiplatelet drugs                       | 959             |
| cardiac           | 2.3.2 Drugs for arrhythmias                  | 478             |
| cardiac           | 2.12 Lipid-regulating drugs                  | 469             |
| cardiac           | 2.4 Beta-adrenoceptor blocking drugs         | 465             |
| cardiac           | 2.5.5.1 ACE inhibitors                       | 433             |
| infectious        | 5.1.4 Aminoglycosides                        | 177             |
| infectious        | 5.1.2 Cephalosporins and carbapenems         | 169             |
| infectious        | 5.1.1.2 Penicillinase-resistant penicillins  | 166             |
| infectious        | 5.1.1.3 Broad-spectrum penicillins           | 158             |
| infectious        | 5.1.7 Glycopeptide antibiotics               | 151             |
| neuro             | 4.8.1 Control of epilepsy                    | 1221            |
| neuro             | 4.7.3 Neuropathic pain                       | 291             |
| neuro             | 4.8.2 Drugs used in status epilepticus       | 283             |
| obstetric         | 2.6.2 Calcium-channel blockers               | 152             |
| obstetric         | 4.8.2 Drugs used in status epilepticus       | 142             |
| obstetric         | 5.1.1.3 Broad-spectrum penicillins           | 139             |
| obstetric         | 7.1.1 Prostaglandins and oxytocics           | 139             |
| obstetric         | 2.4 Beta-adrenoceptor blocking drugs         | 122             |
| ortho             | 10.1.1 Non-steroidal anti-inflammatory drugs | 613             |
| ortho             | 4.7.2 Opioid analgesics                      | 399             |
| ortho             | 2.8.1 Parenteral anticoagulants              | 214             |
| ortho             | 4.7.1 Non-opioid analgesics                  | 209             |
| respiratory       | 6.3.2 Glucocorticoid therapy                 | 655             |
| respiratory       | 3.1.2 Antimuscarinic bronchodilators         | 633             |
| respiratory       | 5.1.1.3 Broad-spectrum penicillins           | 321             |
| respiratory       | 5.1.3 Tetracyclines                          | 319             |
| respiratory       | 3.1.1.1 Selective beta2 agonists             | 300             |


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
| inst_32061  | PAT_0002466 | 147            | 4               |
| inst_51600  | PAT_0009327 | 141.8          | 6               |
| inst_38775  | PAT_0001943 | 135            | 3               |
| inst_109797 | PAT_0003911 | 130.5          | 4               |
| inst_63430  | PAT_0010818 | 130.5          | 4               |
| inst_92716  | PAT_0010925 | 128.5          | 3               |
| inst_54865  | PAT_0004770 | 128.5          | 3               |
| inst_31581  | PAT_0002084 | 125.3          | 6               |
| inst_62647  | PAT_0009913 | 115.5          | 3               |
| inst_53584  | PAT_0008130 | 112.6          | 8               |
| inst_93749  | PAT_0014142 | 104.8          | 4               |
| inst_28040  | PAT_0005807 | 102.8          | 3               |
| inst_79157  | PAT_0003654 | 98.5           | 3               |
| inst_100546 | PAT_0006123 | 96.3           | 3               |
| inst_83253  | PAT_0011891 | 92.6           | 4               |


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
| 1599               | 5.3     | 5.3          |


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
| 1347         | 9275                   | 14.5            |


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
| 0                 | 1505         | 184          | 12.2            |
| 1                 | 2703         | 315          | 11.7            |
| 2                 | 2465         | 408          | 16.6            |
| 3                 | 1469         | 236          | 16.1            |
| 4                 | 717          | 122          | 17              |
| 5                 | 297          | 61           | 20.5            |
| 6                 | 95           | 18           | 18.9            |
| 7                 | 19           | 2            | 10.5            |
| 8                 | 5            | 1            | 20              |


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
| 263    | 9612         | 2.74          |


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
| neuro             | 1175         | 45     | 3.83          |
| cardiac           | 2113         | 72     | 3.41          |
| respiratory       | 1778         | 59     | 3.32          |
| GI                | 1366         | 30     | 2.2           |
| infectious        | 926          | 20     | 2.16          |
| ortho             | 1525         | 28     | 1.84          |
| obstetric         | 729          | 9      | 1.23          |


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
| 2023 | 1928         | 52     | 2.7           |
| 2024 | 3274         | 85     | 2.6           |
| 2025 | 4410         | 126    | 2.86          |


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
| 2023-01-01 | 84         | 0         | 0                  |
| 2023-02-01 | 89         | 2         | 22.5               |
| 2023-03-01 | 133        | 4         | 30.1               |
| 2023-04-01 | 154        | 3         | 19.5               |
| 2023-05-01 | 168        | 6         | 35.7               |
| 2023-06-01 | 174        | 7         | 40.2               |
| 2023-07-01 | 153        | 9         | 58.8               |
| 2023-08-01 | 187        | 6         | 32.1               |
| 2023-09-01 | 181        | 11        | 60.8               |
| 2023-10-01 | 182        | 8         | 44                 |
| 2023-11-01 | 201        | 12        | 59.7               |
| 2023-12-01 | 222        | 10        | 45                 |
| 2024-01-01 | 217        | 10        | 46.1               |
| 2024-02-01 | 234        | 12        | 51.3               |
| 2024-03-01 | 238        | 15        | 63                 |
| 2024-04-01 | 277        | 13        | 46.9               |
| 2024-05-01 | 262        | 13        | 49.6               |
| 2024-06-01 | 275        | 12        | 43.6               |
| 2024-07-01 | 245        | 13        | 53.1               |
| 2024-08-01 | 309        | 9         | 29.1               |
| 2024-09-01 | 273        | 11        | 40.3               |
| 2024-10-01 | 297        | 9         | 30.3               |
| 2024-11-01 | 330        | 17        | 51.5               |
| 2024-12-01 | 317        | 20        | 63.1               |
| 2025-01-01 | 353        | 19        | 53.8               |
| 2025-02-01 | 316        | 13        | 41.1               |
| 2025-03-01 | 335        | 12        | 35.8               |
| 2025-04-01 | 353        | 17        | 48.2               |
| 2025-05-01 | 371        | 17        | 45.8               |
| 2025-06-01 | 340        | 14        | 41.2               |
| 2025-07-01 | 376        | 15        | 39.9               |
| 2025-08-01 | 374        | 9         | 24.1               |
| 2025-09-01 | 396        | 14        | 35.4               |
| 2025-10-01 | 427        | 21        | 49.2               |
| 2025-11-01 | 370        | 14        | 37.8               |
| 2025-12-01 | 399        | 21        | 52.6               |


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
| Acute Medical Unit (AMU) | assessment | 99        |
| Critical Care Unit       | icu_hdu    | 51        |
| Lister Ward              | general    | 45        |
| Rainbow Ward             | paediatric | 43        |
| Jenner Ward              | general    | 41        |
| Fleming Ward             | general    | 35        |
| High Dependency Unit     | icu_hdu    | 33        |
| Nightingale Ward         | general    | 28        |
| Midwifery Unit           | maternity  | 26        |
| Cavell Ward              | step_down  | 17        |


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
| summer | 5774             | 237             | 41                 |
| winter | 3838             | 181             | 47.2               |


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
| 6520        | 2.1            | 1.6               | 18.1           | 227              |


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
| Critical Care Unit       | critical_care  | 358         | 2.3            |
| High Dependency Unit     | critical_care  | 287         | 2.3            |
| Jenner Ward              | surgery        | 721         | 2.2            |
| Acute Medical Unit (AMU) | medicine       | 970         | 2.2            |
| Lister Ward              | medicine       | 900         | 2.1            |
| Rainbow Ward             | women_children | 518         | 2.1            |
| Nightingale Ward         | medicine       | 826         | 2.1            |
| Cavell Ward              | medicine       | 589         | 2.1            |
| Midwifery Unit           | women_children | 585         | 2.1            |
| Fleming Ward             | medicine       | 766         | 2.1            |


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
| 1          | 722         | 3.4            |
| 2          | 671         | 3.2            |
| 3          | 843         | 2.3            |
| 4          | 979         | 2.4            |
| 5          | 1065        | 1.8            |
| 6          | 920         | 1.8            |
| 7          | 591         | 1.3            |
| 8          | 370         | 1.3            |
| 9          | 207         | 1              |
| 10         | 152         | 1              |


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
| Acute Medical Unit (AMU) | assessment | 11         | 1034              |
| Lister Ward              | general    | 10         | 939               |
| Nightingale Ward         | general    | 10         | 872               |
| Fleming Ward             | general    | 9          | 806               |
| Jenner Ward              | general    | 8          | 769               |
| Cavell Ward              | step_down  | 7          | 631               |
| Midwifery Unit           | maternity  | 7          | 629               |
| Rainbow Ward             | paediatric | 6          | 549               |
| Critical Care Unit       | icu_hdu    | 4          | 375               |
| High Dependency Unit     | icu_hdu    | 3          | 295               |


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
| 2023-01-01 | Acute Medical Unit (AMU) | 11         | 7           | 0.6                 |
| 2023-01-01 | Cavell Ward              | 7          | 8           | 1.1                 |
| 2023-01-01 | Critical Care Unit       | 4          | 2           | 0.5                 |
| 2023-01-01 | Fleming Ward             | 9          | 6           | 0.7                 |
| 2023-01-01 | High Dependency Unit     | 3          | 2           | 0.7                 |
| 2023-01-01 | Jenner Ward              | 8          | 3           | 0.4                 |
| 2023-01-01 | Lister Ward              | 10         | 11          | 1.1                 |
| 2023-01-01 | Midwifery Unit           | 7          | 6           | 0.9                 |
| 2023-01-01 | Nightingale Ward         | 10         | 6           | 0.6                 |
| 2023-01-01 | Rainbow Ward             | 6          | 3           | 0.5                 |
| 2023-02-01 | Acute Medical Unit (AMU) | 11         | 12          | 1.1                 |
| 2023-02-01 | Cavell Ward              | 7          | 5           | 0.7                 |
| 2023-02-01 | Critical Care Unit       | 4          | 4           | 1                   |
| 2023-02-01 | Fleming Ward             | 9          | 7           | 0.8                 |
| 2023-02-01 | High Dependency Unit     | 3          | 2           | 0.7                 |
| 2023-02-01 | Jenner Ward              | 8          | 5           | 0.6                 |
| 2023-02-01 | Lister Ward              | 10         | 10          | 1                   |
| 2023-02-01 | Midwifery Unit           | 7          | 5           | 0.7                 |
| 2023-02-01 | Nightingale Ward         | 10         | 8           | 0.8                 |
| 2023-02-01 | Rainbow Ward             | 6          | 8           | 1.3                 |
| 2023-03-01 | Acute Medical Unit (AMU) | 11         | 17          | 1.5                 |
| 2023-03-01 | Cavell Ward              | 7          | 8           | 1.1                 |
| 2023-03-01 | Critical Care Unit       | 4          | 4           | 1                   |
| 2023-03-01 | Fleming Ward             | 9          | 17          | 1.9                 |
| 2023-03-01 | High Dependency Unit     | 3          | 3           | 1                   |
| 2023-03-01 | Jenner Ward              | 8          | 10          | 1.3                 |
| 2023-03-01 | Lister Ward              | 10         | 7           | 0.7                 |
| 2023-03-01 | Midwifery Unit           | 7          | 9           | 1.3                 |
| 2023-03-01 | Nightingale Ward         | 10         | 8           | 0.8                 |
| 2023-03-01 | Rainbow Ward             | 6          | 12          | 2                   |
| 2023-04-01 | Acute Medical Unit (AMU) | 11         | 20          | 1.8                 |
| 2023-04-01 | Cavell Ward              | 7          | 12          | 1.7                 |
| 2023-04-01 | Critical Care Unit       | 4          | 3           | 0.8                 |
| 2023-04-01 | Fleming Ward             | 9          | 11          | 1.2                 |
| 2023-04-01 | High Dependency Unit     | 3          | 5           | 1.7                 |
| 2023-04-01 | Jenner Ward              | 8          | 16          | 2                   |
| 2023-04-01 | Lister Ward              | 10         | 21          | 2.1                 |
| 2023-04-01 | Midwifery Unit           | 7          | 9           | 1.3                 |
| 2023-04-01 | Nightingale Ward         | 10         | 18          | 1.8                 |
| 2023-04-01 | Rainbow Ward             | 6          | 4           | 0.7                 |
| 2023-05-01 | Acute Medical Unit (AMU) | 11         | 18          | 1.6                 |
| 2023-05-01 | Cavell Ward              | 7          | 14          | 2                   |
| 2023-05-01 | Critical Care Unit       | 4          | 9           | 2.3                 |
| 2023-05-01 | Fleming Ward             | 9          | 13          | 1.4                 |
| 2023-05-01 | High Dependency Unit     | 3          | 8           | 2.7                 |
| 2023-05-01 | Jenner Ward              | 8          | 12          | 1.5                 |
| 2023-05-01 | Lister Ward              | 10         | 14          | 1.4                 |
| 2023-05-01 | Midwifery Unit           | 7          | 8           | 1.1                 |
| 2023-05-01 | Nightingale Ward         | 10         | 8           | 0.8                 |
| 2023-05-01 | Rainbow Ward             | 6          | 11          | 1.8                 |
| 2023-06-01 | Acute Medical Unit (AMU) | 11         | 16          | 1.5                 |
| 2023-06-01 | Cavell Ward              | 7          | 12          | 1.7                 |
| 2023-06-01 | Critical Care Unit       | 4          | 6           | 1.5                 |
| 2023-06-01 | Fleming Ward             | 9          | 15          | 1.7                 |
| 2023-06-01 | High Dependency Unit     | 3          | 3           | 1                   |
| 2023-06-01 | Jenner Ward              | 8          | 21          | 2.6                 |
| 2023-06-01 | Lister Ward              | 10         | 20          | 2                   |
| 2023-06-01 | Midwifery Unit           | 7          | 11          | 1.6                 |
| 2023-06-01 | Nightingale Ward         | 10         | 9           | 0.9                 |
| 2023-06-01 | Rainbow Ward             | 6          | 8           | 1.3                 |
| 2023-07-01 | Acute Medical Unit (AMU) | 11         | 15          | 1.4                 |
| 2023-07-01 | Cavell Ward              | 7          | 6           | 0.9                 |
| 2023-07-01 | Critical Care Unit       | 4          | 3           | 0.8                 |
| 2023-07-01 | Fleming Ward             | 9          | 16          | 1.8                 |
| 2023-07-01 | High Dependency Unit     | 3          | 5           | 1.7                 |
| 2023-07-01 | Jenner Ward              | 8          | 14          | 1.8                 |
| 2023-07-01 | Lister Ward              | 10         | 19          | 1.9                 |
| 2023-07-01 | Midwifery Unit           | 7          | 10          | 1.4                 |
| 2023-07-01 | Nightingale Ward         | 10         | 18          | 1.8                 |
| 2023-07-01 | Rainbow Ward             | 6          | 6           | 1                   |
| 2023-08-01 | Acute Medical Unit (AMU) | 11         | 25          | 2.3                 |
| 2023-08-01 | Cavell Ward              | 7          | 13          | 1.9                 |
| 2023-08-01 | Critical Care Unit       | 4          | 7           | 1.8                 |
| 2023-08-01 | Fleming Ward             | 9          | 13          | 1.4                 |
| 2023-08-01 | High Dependency Unit     | 3          | 6           | 2                   |
| 2023-08-01 | Jenner Ward              | 8          | 12          | 1.5                 |
| 2023-08-01 | Lister Ward              | 10         | 21          | 2.1                 |
| 2023-08-01 | Midwifery Unit           | 7          | 10          | 1.4                 |
| 2023-08-01 | Nightingale Ward         | 10         | 20          | 2                   |
| 2023-08-01 | Rainbow Ward             | 6          | 11          | 1.8                 |
| 2023-09-01 | Acute Medical Unit (AMU) | 11         | 26          | 2.4                 |
| 2023-09-01 | Cavell Ward              | 7          | 9           | 1.3                 |
| 2023-09-01 | Critical Care Unit       | 4          | 9           | 2.3                 |
| 2023-09-01 | Fleming Ward             | 9          | 15          | 1.7                 |
| 2023-09-01 | High Dependency Unit     | 3          | 3           | 1                   |
| 2023-09-01 | Jenner Ward              | 8          | 18          | 2.3                 |
| 2023-09-01 | Lister Ward              | 10         | 21          | 2.1                 |
| 2023-09-01 | Midwifery Unit           | 7          | 8           | 1.1                 |
| 2023-09-01 | Nightingale Ward         | 10         | 15          | 1.5                 |
| 2023-09-01 | Rainbow Ward             | 6          | 15          | 2.5                 |
| 2023-10-01 | Acute Medical Unit (AMU) | 11         | 23          | 2.1                 |
| 2023-10-01 | Cavell Ward              | 7          | 10          | 1.4                 |
| 2023-10-01 | Critical Care Unit       | 4          | 8           | 2                   |
| 2023-10-01 | Fleming Ward             | 9          | 6           | 0.7                 |
| 2023-10-01 | High Dependency Unit     | 3          | 5           | 1.7                 |
| 2023-10-01 | Jenner Ward              | 8          | 16          | 2                   |
| 2023-10-01 | Lister Ward              | 10         | 16          | 1.6                 |
| 2023-10-01 | Midwifery Unit           | 7          | 12          | 1.7                 |
| 2023-10-01 | Nightingale Ward         | 10         | 14          | 1.4                 |
| 2023-10-01 | Rainbow Ward             | 6          | 8           | 1.3                 |
| 2023-11-01 | Acute Medical Unit (AMU) | 11         | 24          | 2.2                 |
| 2023-11-01 | Cavell Ward              | 7          | 9           | 1.3                 |
| 2023-11-01 | Critical Care Unit       | 4          | 6           | 1.5                 |
| 2023-11-01 | Fleming Ward             | 9          | 14          | 1.6                 |
| 2023-11-01 | High Dependency Unit     | 3          | 9           | 3                   |
| 2023-11-01 | Jenner Ward              | 8          | 19          | 2.4                 |
| 2023-11-01 | Lister Ward              | 10         | 20          | 2                   |
| 2023-11-01 | Midwifery Unit           | 7          | 14          | 2                   |
| 2023-11-01 | Nightingale Ward         | 10         | 21          | 2.1                 |
| 2023-11-01 | Rainbow Ward             | 6          | 13          | 2.2                 |
| 2023-12-01 | Acute Medical Unit (AMU) | 11         | 25          | 2.3                 |
| 2023-12-01 | Cavell Ward              | 7          | 12          | 1.7                 |
| 2023-12-01 | Critical Care Unit       | 4          | 11          | 2.8                 |
| 2023-12-01 | Fleming Ward             | 9          | 17          | 1.9                 |
| 2023-12-01 | High Dependency Unit     | 3          | 10          | 3.3                 |
| 2023-12-01 | Jenner Ward              | 8          | 19          | 2.4                 |
| 2023-12-01 | Lister Ward              | 10         | 17          | 1.7                 |
| 2023-12-01 | Midwifery Unit           | 7          | 16          | 2.3                 |
| 2023-12-01 | Nightingale Ward         | 10         | 21          | 2.1                 |
| 2023-12-01 | Rainbow Ward             | 6          | 7           | 1.2                 |
| 2024-01-01 | Acute Medical Unit (AMU) | 11         | 23          | 2.1                 |
| 2024-01-01 | Cavell Ward              | 7          | 19          | 2.7                 |
| 2024-01-01 | Critical Care Unit       | 4          | 12          | 3                   |
| 2024-01-01 | Fleming Ward             | 9          | 12          | 1.3                 |
| 2024-01-01 | High Dependency Unit     | 3          | 6           | 2                   |
| 2024-01-01 | Jenner Ward              | 8          | 20          | 2.5                 |
| 2024-01-01 | Lister Ward              | 10         | 18          | 1.8                 |
| 2024-01-01 | Midwifery Unit           | 7          | 11          | 1.6                 |
| 2024-01-01 | Nightingale Ward         | 10         | 21          | 2.1                 |
| 2024-01-01 | Rainbow Ward             | 6          | 9           | 1.5                 |
| 2024-02-01 | Acute Medical Unit (AMU) | 11         | 22          | 2                   |
| 2024-02-01 | Cavell Ward              | 7          | 22          | 3.1                 |
| 2024-02-01 | Critical Care Unit       | 4          | 7           | 1.8                 |
| 2024-02-01 | Fleming Ward             | 9          | 19          | 2.1                 |
| 2024-02-01 | High Dependency Unit     | 3          | 9           | 3                   |
| 2024-02-01 | Jenner Ward              | 8          | 22          | 2.8                 |
| 2024-02-01 | Lister Ward              | 10         | 22          | 2.2                 |
| 2024-02-01 | Midwifery Unit           | 7          | 16          | 2.3                 |
| 2024-02-01 | Nightingale Ward         | 10         | 23          | 2.3                 |
| 2024-02-01 | Rainbow Ward             | 6          | 15          | 2.5                 |
| 2024-03-01 | Acute Medical Unit (AMU) | 11         | 21          | 1.9                 |
| 2024-03-01 | Cavell Ward              | 7          | 14          | 2                   |
| 2024-03-01 | Critical Care Unit       | 4          | 7           | 1.8                 |
| 2024-03-01 | Fleming Ward             | 9          | 20          | 2.2                 |
| 2024-03-01 | High Dependency Unit     | 3          | 7           | 2.3                 |
| 2024-03-01 | Jenner Ward              | 8          | 17          | 2.1                 |
| 2024-03-01 | Lister Ward              | 10         | 32          | 3.2                 |
| 2024-03-01 | Midwifery Unit           | 7          | 20          | 2.9                 |
| 2024-03-01 | Nightingale Ward         | 10         | 22          | 2.2                 |
| 2024-03-01 | Rainbow Ward             | 6          | 12          | 2                   |
| 2024-04-01 | Acute Medical Unit (AMU) | 11         | 28          | 2.5                 |
| 2024-04-01 | Cavell Ward              | 7          | 15          | 2.1                 |
| 2024-04-01 | Critical Care Unit       | 4          | 11          | 2.8                 |
| 2024-04-01 | Fleming Ward             | 9          | 32          | 3.6                 |
| 2024-04-01 | High Dependency Unit     | 3          | 13          | 4.3                 |
| 2024-04-01 | Jenner Ward              | 8          | 26          | 3.3                 |
| 2024-04-01 | Lister Ward              | 10         | 21          | 2.1                 |
| 2024-04-01 | Midwifery Unit           | 7          | 25          | 3.6                 |
| 2024-04-01 | Nightingale Ward         | 10         | 24          | 2.4                 |
| 2024-04-01 | Rainbow Ward             | 6          | 13          | 2.2                 |
| 2024-05-01 | Acute Medical Unit (AMU) | 11         | 32          | 2.9                 |
| 2024-05-01 | Cavell Ward              | 7          | 15          | 2.1                 |
| 2024-05-01 | Critical Care Unit       | 4          | 13          | 3.3                 |
| 2024-05-01 | Fleming Ward             | 9          | 19          | 2.1                 |
| 2024-05-01 | High Dependency Unit     | 3          | 5           | 1.7                 |
| 2024-05-01 | Jenner Ward              | 8          | 24          | 3                   |
| 2024-05-01 | Lister Ward              | 10         | 25          | 2.5                 |
| 2024-05-01 | Midwifery Unit           | 7          | 27          | 3.9                 |
| 2024-05-01 | Nightingale Ward         | 10         | 19          | 1.9                 |
| 2024-05-01 | Rainbow Ward             | 6          | 15          | 2.5                 |
| 2024-06-01 | Acute Medical Unit (AMU) | 11         | 26          | 2.4                 |
| 2024-06-01 | Cavell Ward              | 7          | 16          | 2.3                 |
| 2024-06-01 | Critical Care Unit       | 4          | 8           | 2                   |
| 2024-06-01 | Fleming Ward             | 9          | 19          | 2.1                 |
| 2024-06-01 | High Dependency Unit     | 3          | 5           | 1.7                 |
| 2024-06-01 | Jenner Ward              | 8          | 26          | 3.3                 |
| 2024-06-01 | Lister Ward              | 10         | 36          | 3.6                 |
| 2024-06-01 | Midwifery Unit           | 7          | 15          | 2.1                 |
| 2024-06-01 | Nightingale Ward         | 10         | 22          | 2.2                 |
| 2024-06-01 | Rainbow Ward             | 6          | 22          | 3.7                 |
| 2024-07-01 | Acute Medical Unit (AMU) | 11         | 23          | 2.1                 |
| 2024-07-01 | Cavell Ward              | 7          | 18          | 2.6                 |
| 2024-07-01 | Critical Care Unit       | 4          | 6           | 1.5                 |
| 2024-07-01 | Fleming Ward             | 9          | 27          | 3                   |
| 2024-07-01 | High Dependency Unit     | 3          | 8           | 2.7                 |
| 2024-07-01 | Jenner Ward              | 8          | 15          | 1.9                 |
| 2024-07-01 | Lister Ward              | 10         | 16          | 1.6                 |
| 2024-07-01 | Midwifery Unit           | 7          | 22          | 3.1                 |
| 2024-07-01 | Nightingale Ward         | 10         | 23          | 2.3                 |
| 2024-07-01 | Rainbow Ward             | 6          | 13          | 2.2                 |
| 2024-08-01 | Acute Medical Unit (AMU) | 11         | 30          | 2.7                 |
| 2024-08-01 | Cavell Ward              | 7          | 24          | 3.4                 |
| 2024-08-01 | Critical Care Unit       | 4          | 10          | 2.5                 |
| 2024-08-01 | Fleming Ward             | 9          | 21          | 2.3                 |
| 2024-08-01 | High Dependency Unit     | 3          | 14          | 4.7                 |
| 2024-08-01 | Jenner Ward              | 8          | 22          | 2.8                 |
| 2024-08-01 | Lister Ward              | 10         | 36          | 3.6                 |
| 2024-08-01 | Midwifery Unit           | 7          | 22          | 3.1                 |
| 2024-08-01 | Nightingale Ward         | 10         | 27          | 2.7                 |
| 2024-08-01 | Rainbow Ward             | 6          | 17          | 2.8                 |
| 2024-09-01 | Acute Medical Unit (AMU) | 11         | 26          | 2.4                 |
| 2024-09-01 | Cavell Ward              | 7          | 16          | 2.3                 |
| 2024-09-01 | Critical Care Unit       | 4          | 10          | 2.5                 |
| 2024-09-01 | Fleming Ward             | 9          | 23          | 2.6                 |
| 2024-09-01 | High Dependency Unit     | 3          | 7           | 2.3                 |
| 2024-09-01 | Jenner Ward              | 8          | 28          | 3.5                 |
| 2024-09-01 | Lister Ward              | 10         | 26          | 2.6                 |
| 2024-09-01 | Midwifery Unit           | 7          | 17          | 2.4                 |
| 2024-09-01 | Nightingale Ward         | 10         | 30          | 3                   |
| 2024-09-01 | Rainbow Ward             | 6          | 16          | 2.7                 |
| 2024-10-01 | Acute Medical Unit (AMU) | 11         | 30          | 2.7                 |
| 2024-10-01 | Cavell Ward              | 7          | 19          | 2.7                 |
| 2024-10-01 | Critical Care Unit       | 4          | 14          | 3.5                 |
| 2024-10-01 | Fleming Ward             | 9          | 27          | 3                   |
| 2024-10-01 | High Dependency Unit     | 3          | 6           | 2                   |
| 2024-10-01 | Jenner Ward              | 8          | 26          | 3.3                 |
| 2024-10-01 | Lister Ward              | 10         | 25          | 2.5                 |
| 2024-10-01 | Midwifery Unit           | 7          | 19          | 2.7                 |
| 2024-10-01 | Nightingale Ward         | 10         | 24          | 2.4                 |
| 2024-10-01 | Rainbow Ward             | 6          | 13          | 2.2                 |
| 2024-11-01 | Acute Medical Unit (AMU) | 11         | 36          | 3.3                 |
| 2024-11-01 | Cavell Ward              | 7          | 25          | 3.6                 |
| 2024-11-01 | Critical Care Unit       | 4          | 10          | 2.5                 |
| 2024-11-01 | Fleming Ward             | 9          | 34          | 3.8                 |
| 2024-11-01 | High Dependency Unit     | 3          | 6           | 2                   |
| 2024-11-01 | Jenner Ward              | 8          | 18          | 2.3                 |
| 2024-11-01 | Lister Ward              | 10         | 39          | 3.9                 |
| 2024-11-01 | Midwifery Unit           | 7          | 17          | 2.4                 |
| 2024-11-01 | Nightingale Ward         | 10         | 30          | 3                   |
| 2024-11-01 | Rainbow Ward             | 6          | 24          | 4                   |
| 2024-12-01 | Acute Medical Unit (AMU) | 11         | 33          | 3                   |
| 2024-12-01 | Cavell Ward              | 7          | 18          | 2.6                 |
| 2024-12-01 | Critical Care Unit       | 4          | 15          | 3.8                 |
| 2024-12-01 | Fleming Ward             | 9          | 29          | 3.2                 |
| 2024-12-01 | High Dependency Unit     | 3          | 14          | 4.7                 |
| 2024-12-01 | Jenner Ward              | 8          | 20          | 2.5                 |
| 2024-12-01 | Lister Ward              | 10         | 32          | 3.2                 |
| 2024-12-01 | Midwifery Unit           | 7          | 18          | 2.6                 |
| 2024-12-01 | Nightingale Ward         | 10         | 26          | 2.6                 |
| 2024-12-01 | Rainbow Ward             | 6          | 18          | 3                   |
| 2025-01-01 | Acute Medical Unit (AMU) | 11         | 33          | 3                   |
| 2025-01-01 | Cavell Ward              | 7          | 25          | 3.6                 |
| 2025-01-01 | Critical Care Unit       | 4          | 10          | 2.5                 |
| 2025-01-01 | Fleming Ward             | 9          | 29          | 3.2                 |
| 2025-01-01 | High Dependency Unit     | 3          | 14          | 4.7                 |
| 2025-01-01 | Jenner Ward              | 8          | 32          | 4                   |
| 2025-01-01 | Lister Ward              | 10         | 37          | 3.7                 |
| 2025-01-01 | Midwifery Unit           | 7          | 27          | 3.9                 |
| 2025-01-01 | Nightingale Ward         | 10         | 36          | 3.6                 |
| 2025-01-01 | Rainbow Ward             | 6          | 21          | 3.5                 |
| 2025-02-01 | Acute Medical Unit (AMU) | 11         | 32          | 2.9                 |
| 2025-02-01 | Cavell Ward              | 7          | 28          | 4                   |
| 2025-02-01 | Critical Care Unit       | 4          | 8           | 2                   |
| 2025-02-01 | Fleming Ward             | 9          | 29          | 3.2                 |
| 2025-02-01 | High Dependency Unit     | 3          | 9           | 3                   |
| 2025-02-01 | Jenner Ward              | 8          | 20          | 2.5                 |
| 2025-02-01 | Lister Ward              | 10         | 24          | 2.4                 |
| 2025-02-01 | Midwifery Unit           | 7          | 18          | 2.6                 |
| 2025-02-01 | Nightingale Ward         | 10         | 43          | 4.3                 |
| 2025-02-01 | Rainbow Ward             | 6          | 16          | 2.7                 |
| 2025-03-01 | Acute Medical Unit (AMU) | 11         | 35          | 3.2                 |
| 2025-03-01 | Cavell Ward              | 7          | 21          | 3                   |
| 2025-03-01 | Critical Care Unit       | 4          | 11          | 2.8                 |
| 2025-03-01 | Fleming Ward             | 9          | 36          | 4                   |
| 2025-03-01 | High Dependency Unit     | 3          | 11          | 3.7                 |
| 2025-03-01 | Jenner Ward              | 8          | 24          | 3                   |
| 2025-03-01 | Lister Ward              | 10         | 32          | 3.2                 |
| 2025-03-01 | Midwifery Unit           | 7          | 27          | 3.9                 |
| 2025-03-01 | Nightingale Ward         | 10         | 35          | 3.5                 |
| 2025-03-01 | Rainbow Ward             | 6          | 19          | 3.2                 |
| 2025-04-01 | Acute Medical Unit (AMU) | 11         | 43          | 3.9                 |
| 2025-04-01 | Cavell Ward              | 7          | 30          | 4.3                 |
| 2025-04-01 | Critical Care Unit       | 4          | 15          | 3.8                 |
| 2025-04-01 | Fleming Ward             | 9          | 21          | 2.3                 |
| 2025-04-01 | High Dependency Unit     | 3          | 14          | 4.7                 |
| 2025-04-01 | Jenner Ward              | 8          | 26          | 3.3                 |
| 2025-04-01 | Lister Ward              | 10         | 26          | 2.6                 |
| 2025-04-01 | Midwifery Unit           | 7          | 22          | 3.1                 |
| 2025-04-01 | Nightingale Ward         | 10         | 29          | 2.9                 |
| 2025-04-01 | Rainbow Ward             | 6          | 20          | 3.3                 |
| 2025-05-01 | Acute Medical Unit (AMU) | 11         | 43          | 3.9                 |
| 2025-05-01 | Cavell Ward              | 7          | 30          | 4.3                 |
| 2025-05-01 | Critical Care Unit       | 4          | 23          | 5.8                 |
| 2025-05-01 | Fleming Ward             | 9          | 26          | 2.9                 |
| 2025-05-01 | High Dependency Unit     | 3          | 8           | 2.7                 |
| 2025-05-01 | Jenner Ward              | 8          | 30          | 3.8                 |
| 2025-05-01 | Lister Ward              | 10         | 37          | 3.7                 |
| 2025-05-01 | Midwifery Unit           | 7          | 26          | 3.7                 |
| 2025-05-01 | Nightingale Ward         | 10         | 31          | 3.1                 |
| 2025-05-01 | Rainbow Ward             | 6          | 22          | 3.7                 |
| 2025-06-01 | Acute Medical Unit (AMU) | 11         | 33          | 3                   |
| 2025-06-01 | Cavell Ward              | 7          | 19          | 2.7                 |
| 2025-06-01 | Critical Care Unit       | 4          | 12          | 3                   |
| 2025-06-01 | Fleming Ward             | 9          | 28          | 3.1                 |
| 2025-06-01 | High Dependency Unit     | 3          | 8           | 2.7                 |
| 2025-06-01 | Jenner Ward              | 8          | 23          | 2.9                 |
| 2025-06-01 | Lister Ward              | 10         | 38          | 3.8                 |
| 2025-06-01 | Midwifery Unit           | 7          | 20          | 2.9                 |
| 2025-06-01 | Nightingale Ward         | 10         | 32          | 3.2                 |
| 2025-06-01 | Rainbow Ward             | 6          | 22          | 3.7                 |
| 2025-07-01 | Acute Medical Unit (AMU) | 11         | 35          | 3.2                 |
| 2025-07-01 | Cavell Ward              | 7          | 16          | 2.3                 |
| 2025-07-01 | Critical Care Unit       | 4          | 16          | 4                   |
| 2025-07-01 | Fleming Ward             | 9          | 37          | 4.1                 |
| 2025-07-01 | High Dependency Unit     | 3          | 13          | 4.3                 |
| 2025-07-01 | Jenner Ward              | 8          | 27          | 3.4                 |
| 2025-07-01 | Lister Ward              | 10         | 36          | 3.6                 |
| 2025-07-01 | Midwifery Unit           | 7          | 25          | 3.6                 |
| 2025-07-01 | Nightingale Ward         | 10         | 30          | 3                   |
| 2025-07-01 | Rainbow Ward             | 6          | 23          | 3.8                 |
| 2025-08-01 | Acute Medical Unit (AMU) | 11         | 37          | 3.4                 |
| 2025-08-01 | Cavell Ward              | 7          | 28          | 4                   |
| 2025-08-01 | Critical Care Unit       | 4          | 20          | 5                   |
| 2025-08-01 | Fleming Ward             | 9          | 31          | 3.4                 |
| 2025-08-01 | High Dependency Unit     | 3          | 13          | 4.3                 |
| 2025-08-01 | Jenner Ward              | 8          | 28          | 3.5                 |
| 2025-08-01 | Lister Ward              | 10         | 36          | 3.6                 |
| 2025-08-01 | Midwifery Unit           | 7          | 26          | 3.7                 |
| 2025-08-01 | Nightingale Ward         | 10         | 37          | 3.7                 |
| 2025-08-01 | Rainbow Ward             | 6          | 27          | 4.5                 |
| 2025-09-01 | Acute Medical Unit (AMU) | 11         | 44          | 4                   |
| 2025-09-01 | Cavell Ward              | 7          | 18          | 2.6                 |
| 2025-09-01 | Critical Care Unit       | 4          | 20          | 5                   |
| 2025-09-01 | Fleming Ward             | 9          | 37          | 4.1                 |
| 2025-09-01 | High Dependency Unit     | 3          | 10          | 3.3                 |
| 2025-09-01 | Jenner Ward              | 8          | 25          | 3.1                 |
| 2025-09-01 | Lister Ward              | 10         | 36          | 3.6                 |
| 2025-09-01 | Midwifery Unit           | 7          | 26          | 3.7                 |
| 2025-09-01 | Nightingale Ward         | 10         | 33          | 3.3                 |
| 2025-09-01 | Rainbow Ward             | 6          | 10          | 1.7                 |
| 2025-10-01 | Acute Medical Unit (AMU) | 11         | 39          | 3.5                 |
| 2025-10-01 | Cavell Ward              | 7          | 28          | 4                   |
| 2025-10-01 | Critical Care Unit       | 4          | 14          | 3.5                 |
| 2025-10-01 | Fleming Ward             | 9          | 35          | 3.9                 |
| 2025-10-01 | High Dependency Unit     | 3          | 13          | 4.3                 |
| 2025-10-01 | Jenner Ward              | 8          | 32          | 4                   |
| 2025-10-01 | Lister Ward              | 10         | 41          | 4.1                 |
| 2025-10-01 | Midwifery Unit           | 7          | 25          | 3.6                 |
| 2025-10-01 | Nightingale Ward         | 10         | 39          | 3.9                 |
| 2025-10-01 | Rainbow Ward             | 6          | 31          | 5.2                 |
| 2025-11-01 | Acute Medical Unit (AMU) | 11         | 48          | 4.4                 |
| 2025-11-01 | Cavell Ward              | 7          | 27          | 3.9                 |
| 2025-11-01 | Critical Care Unit       | 4          | 13          | 3.3                 |
| 2025-11-01 | Fleming Ward             | 9          | 36          | 4                   |
| 2025-11-01 | High Dependency Unit     | 3          | 8           | 2.7                 |
| 2025-11-01 | Jenner Ward              | 8          | 37          | 4.6                 |
| 2025-11-01 | Lister Ward              | 10         | 30          | 3                   |
| 2025-11-01 | Midwifery Unit           | 7          | 22          | 3.1                 |
| 2025-11-01 | Nightingale Ward         | 10         | 33          | 3.3                 |
| 2025-11-01 | Rainbow Ward             | 6          | 23          | 3.8                 |
| 2025-12-01 | Acute Medical Unit (AMU) | 11         | 54          | 4.9                 |
| 2025-12-01 | Cavell Ward              | 7          | 22          | 3.1                 |
| 2025-12-01 | Critical Care Unit       | 4          | 18          | 4.5                 |
| 2025-12-01 | Fleming Ward             | 9          | 29          | 3.2                 |
| 2025-12-01 | High Dependency Unit     | 3          | 13          | 4.3                 |
| 2025-12-01 | Jenner Ward              | 8          | 36          | 4.5                 |
| 2025-12-01 | Lister Ward              | 10         | 41          | 4.1                 |
| 2025-12-01 | Midwifery Unit           | 7          | 18          | 2.6                 |
| 2025-12-01 | Nightingale Ward         | 10         | 37          | 3.7                 |
| 2025-12-01 | Rainbow Ward             | 6          | 22          | 3.7                 |


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
| PAT_0002873 | cardiac           | 59950                | 7                    |
| PAT_0000334 | ortho             | 56100                | 7                    |
| PAT_0002417 | ortho             | 51800                | 6                    |
| PAT_0000693 | ortho             | 50700                | 6                    |
| PAT_0000910 | ortho             | 50700                | 6                    |
| PAT_0000323 | cardiac           | 48800                | 5                    |
| PAT_0004096 | cardiac           | 46000                | 4                    |
| PAT_0000373 | cardiac           | 44800                | 5                    |
| PAT_0002040 | cardiac           | 44650                | 5                    |
| PAT_0002060 | cardiac           | 44400                | 5                    |
| PAT_0000012 | ortho             | 44200                | 5                    |
| PAT_0000813 | cardiac           | 42950                | 4                    |
| PAT_0007475 | cardiac           | 41450                | 5                    |
| PAT_0000309 | cardiac           | 41400                | 5                    |
| PAT_0001849 | cardiac           | 41400                | 5                    |


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
| PAT_0009405 | 17.9     | 1800                 | 32240          |
| PAT_0004342 | 16.5     | 1800                 | 29779          |
| PAT_0003493 | 15.3     | 1800                 | 27590          |
| PAT_0003399 | 14.9     | 1800                 | 26898          |
| PAT_0003168 | 14.9     | 1800                 | 26786          |
| PAT_0005096 | 14.3     | 1800                 | 25802          |
| PAT_0005807 | 13.6     | 1800                 | 24536          |
| PAT_0011627 | 13.4     | 1800                 | 24101          |
| PAT_0008140 | 13.3     | 1800                 | 23970          |
| PAT_0008142 | 13.3     | 1800                 | 23881          |
| PAT_0000496 | 12.9     | 1800                 | 23252          |
| PAT_0007175 | 12.9     | 1800                 | 23176          |
| PAT_0003408 | 12.8     | 1800                 | 23001          |
| PAT_0014499 | 12.7     | 1800                 | 22876          |
| PAT_0003214 | 12.5     | 1800                 | 22476          |


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
| 1          | 1038   | 6.6     |
| 2          | 921    | 6.3     |
| 3          | 1184   | 5.4     |
| 4          | 1375   | 5.5     |
| 5          | 1534   | 5       |
| 6          | 1289   | 4.8     |
| 7          | 868    | 4.4     |
| 8          | 534    | 4.4     |
| 9          | 316    | 4.1     |
| 10         | 216    | 4.1     |


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
| 1          | 2166      | 1418     | 65.5           |
| 2          | 1845      | 1222     | 66.2           |
| 3          | 2497      | 1773     | 71             |
| 4          | 2836      | 1955     | 68.9           |
| 5          | 2896      | 2137     | 73.8           |
| 6          | 2437      | 1832     | 75.2           |
| 7          | 1800      | 1383     | 76.8           |
| 8          | 1010      | 788      | 78             |
| 9          | 656       | 532      | 81.1           |
| 10         | 434       | 338      | 77.9           |


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
| 2023-01-01 | 228         | 84         | 65         | 5          | 2         |
| 2023-02-01 | 158         | 89         | 88         | 5          | 24        |
| 2023-03-01 | 175         | 133        | 123        | 9          | 60        |
| 2023-04-01 | 155         | 154        | 140        | 9          | 76        |
| 2023-05-01 | 177         | 168        | 164        | 9          | 102       |
| 2023-06-01 | 198         | 174        | 166        | 14         | 113       |
| 2023-07-01 | 180         | 153        | 157        | 13         | 122       |
| 2023-08-01 | 201         | 187        | 175        | 22         | 125       |
| 2023-09-01 | 218         | 181        | 172        | 9          | 121       |
| 2023-10-01 | 185         | 182        | 176        | 14         | 143       |
| 2023-11-01 | 249         | 201        | 200        | 21         | 153       |
| 2023-12-01 | 259         | 222        | 212        | 15         | 154       |
| 2024-01-01 | 248         | 217        | 209        | 22         | 155       |
| 2024-02-01 | 265         | 234        | 234        | 19         | 167       |
| 2024-03-01 | 295         | 238        | 214        | 24         | 175       |
| 2024-04-01 | 295         | 277        | 279        | 18         | 206       |
| 2024-05-01 | 283         | 262        | 250        | 18         | 221       |
| 2024-06-01 | 267         | 275        | 267        | 25         | 219       |
| 2024-07-01 | 278         | 245        | 249        | 22         | 194       |
| 2024-08-01 | 286         | 309        | 289        | 20         | 235       |
| 2024-09-01 | 325         | 273        | 274        | 30         | 200       |
| 2024-10-01 | 321         | 297        | 273        | 21         | 219       |
| 2024-11-01 | 331         | 330        | 306        | 20         | 261       |
| 2024-12-01 | 385         | 317        | 326        | 24         | 251       |
| 2025-01-01 | 366         | 353        | 332        | 28         | 270       |
| 2025-02-01 | 365         | 316        | 319        | 27         | 229       |
| 2025-03-01 | 375         | 335        | 334        | 35         | 275       |
| 2025-04-01 | 365         | 353        | 338        | 30         | 286       |
| 2025-05-01 | 375         | 371        | 354        | 29         | 308       |
| 2025-06-01 | 364         | 340        | 344        | 29         | 278       |
| 2025-07-01 | 392         | 376        | 345        | 36         | 289       |
| 2025-08-01 | 383         | 374        | 372        | 33         | 306       |
| 2025-09-01 | 417         | 396        | 367        | 22         | 303       |
| 2025-10-01 | 440         | 427        | 413        | 33         | 324       |
| 2025-11-01 | 436         | 370        | 376        | 19         | 265       |
| 2025-12-01 | 470         | 399        | 373        | 33         | 311       |


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
| 2024-12-30 | 25       |
| 2025-12-12 | 25       |
| 2025-08-26 | 24       |
| 2025-09-10 | 23       |
| 2025-07-21 | 22       |
| 2025-09-30 | 22       |
| 2025-10-07 | 22       |
| 2025-11-20 | 22       |
| 2025-12-16 | 22       |


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
| 2023 | summer | 1314     | 188            |
| 2023 | winter | 1069     | 214            |
| 2024 | summer | 2055     | 294            |
| 2024 | winter | 1524     | 305            |
| 2025 | summer | 2736     | 391            |
| 2025 | winter | 2012     | 402            |


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
| Day Surgery Theatre | General / Mixed              | 2007      | 1.9     |
| Main Theatre 1      | General Surgery              | 1533      | 1.4     |
| Main Theatre 2      | Trauma & Orthopaedics        | 1478      | 1.4     |
| Cardiac Theatre     | Cardiology / Cardiac Surgery | 1065      | 1       |
| Obstetric Theatre   | Obstetrics                   | 1059      | 1       |


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
| complex    | 1517      | 11020      | 16717100     |
| major      | 2059      | 6473       | 13327700     |
| moderate   | 2047      | 1994       | 4081700      |
| minor      | 1519      | 689        | 1046700      |


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
| 1                  | 3601     |
| 2                  | 1319     |
| 3                  | 534      |
| 4                  | 219      |
| 5                  | 96       |
| 6                  | 43       |
| 7                  | 11       |
| 8                  | 4        |
| 9                  | 3        |
| 10                 | 1        |
| 11                 | 1        |


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
| PAT_0001852 | 26             | 4             |
| PAT_0002417 | 26             | 4             |
| PAT_0000169 | 24             | 4             |
| PAT_0000228 | 24             | 4             |
| PAT_0000693 | 24             | 4             |
| PAT_0002753 | 22             | 4             |
| PAT_0000910 | 21             | 4             |
| PAT_0001404 | 21             | 4             |
| PAT_0001660 | 21             | 3             |
| PAT_0001720 | 21             | 4             |
| PAT_0003096 | 21             | 3             |
| PAT_0000012 | 20             | 4             |
| PAT_0002714 | 20             | 4             |
| PAT_0002873 | 20             | 4             |
| PAT_0004057 | 20             | 4             |


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
| infectious        | 5                 | 5.5        | 2        |
| GI                | 4                 | 4.4545     | 11       |
| GI                | 3                 | 4.4545     | 22       |
| cardiac           | 6                 | 4.3333     | 3        |
| GI                | 5                 | 4.25       | 4        |
| ortho             | 5                 | 4.25       | 4        |
| neuro             | 2                 | 4.0732     | 41       |
| cardiac           | 3                 | 4.0323     | 31       |
| obstetric         | 5                 | 4          | 6        |
| ortho             | 0                 | 3.92       | 25       |
| infectious        | 2                 | 3.8889     | 27       |
| respiratory       | 2                 | 3.881      | 42       |
| cardiac           | 4                 | 3.8667     | 15       |
| infectious        | 0                 | 3.8        | 15       |
| ortho             | 1                 | 3.7959     | 49       |
| neuro             | 5                 | 3.75       | 4        |
| neuro             | 0                 | 3.7273     | 11       |
| respiratory       | 1                 | 3.6981     | 53       |
| respiratory       | 0                 | 3.6957     | 23       |
| GI                | 1                 | 3.68       | 25       |
| cardiac           | 0                 | 3.6667     | 36       |
| neuro             | 3                 | 3.6667     | 18       |
| respiratory       | 5                 | 3.6667     | 6        |
| respiratory       | 4                 | 3.6471     | 17       |
| ortho             | 2                 | 3.625      | 48       |
| cardiac           | 1                 | 3.6119     | 67       |
| infectious        | 3                 | 3.6        | 15       |
| obstetric         | 0                 | 3.5714     | 14       |
| respiratory       | 3                 | 3.5714     | 21       |
| ortho             | 3                 | 3.5652     | 23       |
| GI                | 0                 | 3.5625     | 16       |
| neuro             | 4                 | 3.5455     | 11       |
| cardiac           | 2                 | 3.5217     | 46       |
| GI                | 2                 | 3.5135     | 37       |
| obstetric         | 3                 | 3.4286     | 7        |
| ortho             | 4                 | 3.4        | 15       |
| obstetric         | 2                 | 3.4        | 15       |
| obstetric         | 4                 | 3.3333     | 3        |
| respiratory       | 6                 | 3.3333     | 3        |
| neuro             | 1                 | 3.2812     | 32       |
| infectious        | 1                 | 3.2778     | 18       |
| infectious        | 4                 | 3.25       | 8        |
| obstetric         | 1                 | 3.2308     | 13       |
| cardiac           | 5                 | 3.1667     | 6        |
| neuro             | 6                 | 3          | 1        |
| infectious        | 6                 | 3          | 1        |
| neuro             | 7                 | 3          | 1        |
| cardiac           | 8                 | 3          | 1        |


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
| 2023-01-01 | 532      | 84.2          |
| 2023-04-01 | 513      | 83            |
| 2023-07-01 | 573      | 83.2          |
| 2023-10-01 | 659      | 83.5          |
| 2024-01-01 | 757      | 83.4          |
| 2024-04-01 | 802      | 86.4          |
| 2024-07-01 | 843      | 84.5          |
| 2024-10-01 | 989      | 85.7          |
| 2025-01-01 | 1040     | 82.6          |
| 2025-04-01 | 1042     | 86.8          |
| 2025-07-01 | 1131     | 85            |
| 2025-10-01 | 1270     | 83.7          |


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
| 2023-01-01 | 142      | 69      |
| 2023-04-01 | 134      | 76.1    |
| 2023-07-01 | 145      | 75.2    |
| 2023-10-01 | 184      | 79.3    |
| 2024-01-01 | 228      | 78.5    |
| 2024-04-01 | 222      | 72.5    |
| 2024-07-01 | 240      | 72.9    |
| 2024-10-01 | 300      | 77.3    |
| 2025-01-01 | 308      | 73.4    |
| 2025-04-01 | 305      | 75.7    |
| 2025-07-01 | 321      | 77.3    |
| 2025-10-01 | 267      | 88      |


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
| 2023-01-01 | 115             | 96.5           |
| 2023-04-01 | 239             | 97.9           |
| 2023-07-01 | 297             | 94.3           |
| 2023-10-01 | 367             | 95.6           |
| 2024-01-01 | 472             | 94.3           |
| 2024-04-01 | 502             | 96.6           |
| 2024-07-01 | 537             | 95.5           |
| 2024-10-01 | 608             | 95.6           |
| 2025-01-01 | 649             | 92.1           |
| 2025-04-01 | 795             | 94.2           |
| 2025-07-01 | 747             | 93.3           |
| 2025-10-01 | 698             | 98.3           |


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
| 2023          | 5349            |
| 2024          | 3399            |
| 2025          | 3004            |


---
