# Exercise Results

## Exercise 1: "How many patients does the trust serve?"

### Using DISTINCT

```sql
SELECT COUNT(DISTINCT id) AS patient_count
FROM dim_patient;
```

| patient_count |
|---------------|
| 5386          |


### Only current patients

```sql
SELECT COUNT(*) AS current_patients
FROM dim_patient
WHERE valid_to IS NULL;
```

| current_patients |
|------------------|
| 5386             |


---

## Exercise 2: "What does this hospital look like?"

### Ward summary

```sql
SELECT ward_name, ward_type, department, total_beds, cost_per_bed_day
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
SELECT specialty_group, grade, COUNT(*) AS consultants
FROM dim_consultant
GROUP BY specialty_group, grade
ORDER BY specialty_group, grade;
```

| specialty_group  | grade      | consultants |
|------------------|------------|-------------|
| cardiac          | SHO        | 1           |
| cardiac          | consultant | 3           |
| cardiac          | registrar  | 1           |
| gastrointestinal | SHO        | 1           |
| gastrointestinal | consultant | 3           |
| gastrointestinal | registrar  | 1           |
| general          | SHO        | 1           |
| general          | consultant | 3           |
| general          | registrar  | 1           |
| musculoskeletal  | SHO        | 1           |
| musculoskeletal  | consultant | 3           |
| musculoskeletal  | registrar  | 1           |
| respiratory      | SHO        | 1           |
| respiratory      | consultant | 3           |
| respiratory      | registrar  | 1           |


### Theatre summary

```sql
SELECT theatre_name, specialty, sessions_per_day
FROM dim_theatre;
```

| theatre_name        | specialty                    | sessions_per_day |
|---------------------|------------------------------|------------------|
| Main Theatre 1      | General Surgery              | 3                |
| Main Theatre 2      | Trauma & Orthopaedics        | 3                |
| Cardiac Theatre     | Cardiology / Cardiac Surgery | 2                |
| Day Surgery Theatre | General / Mixed              | 4                |
| Obstetric Theatre   | Obstetrics                   | 2                |


### Orphan check -- does dim_clinic appear in any fact table?

```sql
SELECT table_name, column_name
FROM information_schema.columns
WHERE column_name = 'clinic_id'
ORDER BY table_name;
```

| table_name | column_name |
|------------|-------------|

*(No rows -- no fact table references a clinic dimension.)*


---

## Exercise 3: "What happened on A&E's busiest day?"

### Find the busiest day and break down by triage category

```sql
WITH busiest AS (
    SELECT timestamp::DATE AS day, COUNT(*) AS arrivals
    FROM fact_ed_arrival
    GROUP BY day
    ORDER BY arrivals DESC
    LIMIT 1
)
SELECT
    t.triage_category,
    COUNT(*) AS patients
FROM fact_triage t
WHERE t.timestamp::DATE = (SELECT day FROM busiest)
GROUP BY t.triage_category
ORDER BY t.triage_category;
```

| triage_category | patients |
|-----------------|----------|
| 1               | 7        |
| 2               | 8        |
| 3               | 3        |
| 4               | 4        |
| 5               | 6        |


---

## Exercise 4: "Where do our patients come from?"

### Pathway split

```sql
SELECT pathway_type, COUNT(*) AS patients
FROM dim_patient
WHERE valid_to IS NULL
GROUP BY pathway_type
ORDER BY patients DESC;
```

| pathway_type | patients |
|--------------|----------|
| elective     | 2909     |
| emergency    | 1937     |
| cancer       | 540      |


### Primary condition breakdown

```sql
SELECT primary_condition, COUNT(*) AS patients
FROM dim_patient
WHERE valid_to IS NULL
GROUP BY primary_condition
ORDER BY patients DESC;
```

| primary_condition | patients |
|-------------------|----------|
| cardiac           | 1201     |
| respiratory       | 990      |
| ortho             | 799      |
| GI                | 785      |
| neuro             | 614      |
| infectious        | 535      |
| obstetric         | 462      |


### IMD decile distribution

```sql
SELECT imd_decile, COUNT(*) AS patients
FROM dim_patient
WHERE valid_to IS NULL
GROUP BY imd_decile
ORDER BY imd_decile;
```

| imd_decile | patients |
|------------|----------|
| 1          | 511      |
| 2          | 540      |
| 3          | 516      |
| 4          | 574      |
| 5          | 560      |
| 6          | 530      |
| 7          | 541      |
| 8          | 540      |
| 9          | 556      |
| 10         | 518      |


---

## Exercise 5: "Are we hitting the 4-hour A&E target?"

### Join arrival to assessment on attendance_id

```sql
SELECT
    COUNT(*) AS assessed_patients,
    ROUND(AVG(EXTRACT(EPOCH FROM (ea.timestamp - arr.timestamp)) / 60), 0) AS avg_minutes,
    SUM(CASE WHEN EXTRACT(EPOCH FROM (ea.timestamp - arr.timestamp)) / 60 <= 240
        THEN 1 ELSE 0 END) AS within_4h,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (ea.timestamp - arr.timestamp)) / 60 <= 240
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_within_4h
FROM fact_ed_arrival arr
JOIN fact_ed_assessment ea
    ON arr.attendance_id = ea.attendance_id;
```

| assessed_patients | avg_minutes | within_4h | pct_within_4h |
|-------------------|-------------|-----------|---------------|
| 2056              | 141.0       | 1758      | 85.5          |


---

## Exercise 6: "How long are patients staying?"

### ALOS for completed spells

```sql
WITH spells AS (
    SELECT
        a.spell_id,
        MIN(a.timestamp) AS admission_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d
        ON a.spell_id = d.spell_id
    GROUP BY a.spell_id
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
| 1124             | 5.5           | 5.1             |


### ALOS by primary condition

```sql
WITH spells AS (
    SELECT
        a.spell_id,
        a.patient_id,
        MIN(a.timestamp) AS admission_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d
        ON a.spell_id = d.spell_id
    GROUP BY a.spell_id, a.patient_id
)
SELECT
    p.primary_condition,
    COUNT(*) AS spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (s.discharge_ts - s.admission_ts)) / 86400.0), 1) AS mean_los
FROM spells s
JOIN dim_patient p ON s.patient_id = p.id AND p.valid_to IS NULL
GROUP BY p.primary_condition
ORDER BY mean_los DESC;
```

| primary_condition | spells | mean_los |
|-------------------|--------|----------|
| ortho             | 185    | 5.7      |
| GI                | 161    | 5.6      |
| cardiac           | 227    | 5.5      |
| respiratory       | 196    | 5.5      |
| neuro             | 139    | 5.3      |
| infectious        | 116    | 5.3      |
| obstetric         | 100    | 5.2      |


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
| referrals | 3242     |
| attended  | 2568     |


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
| 2023-01-01 | 124       |
| 2023-02-01 | 85        |
| 2023-03-01 | 76        |
| 2023-04-01 | 77        |
| 2023-05-01 | 92        |
| 2023-06-01 | 104       |
| 2023-07-01 | 83        |
| 2023-08-01 | 89        |
| 2023-09-01 | 73        |
| 2023-10-01 | 93        |
| 2023-11-01 | 90        |
| 2023-12-01 | 85        |
| 2024-01-01 | 110       |
| 2024-02-01 | 82        |
| 2024-03-01 | 81        |
| 2024-04-01 | 107       |
| 2024-05-01 | 115       |
| 2024-06-01 | 68        |
| 2024-07-01 | 95        |
| 2024-08-01 | 89        |
| 2024-09-01 | 93        |
| 2024-10-01 | 97        |
| 2024-11-01 | 141       |
| 2024-12-01 | 142       |
| 2025-01-01 | 122       |
| 2025-02-01 | 123       |
| 2025-03-01 | 122       |
| 2025-04-01 | 107       |
| 2025-05-01 | 100       |
| 2025-06-01 | 87        |
| 2025-07-01 | 98        |
| 2025-08-01 | 65        |
| 2025-09-01 | 102       |
| 2025-10-01 | 101       |
| 2025-11-01 | 86        |
| 2025-12-01 | 113       |


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
| 1                    | 332       | 35.2 |
| 2                    | 423       | 44.8 |
| 3                    | 165       | 17.5 |
| 4                    | 23        | 2.4  |
| 5                    | 1         | 0.1  |


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
| 944             | 24       | 2.5           |


---

## Exercise 9: "Which consultants carry the heaviest load?"

### Admissions by consultant

```sql
SELECT
    c.id,
    c.specialty_group,
    c.grade,
    COUNT(*) AS admissions
FROM fact_admission a
JOIN dim_consultant c ON a.consultant_id = c.id
GROUP BY c.id, c.specialty_group, c.grade
ORDER BY admissions DESC;
```

| id      | specialty_group  | grade      | admissions |
|---------|------------------|------------|------------|
| CON_006 | respiratory      | consultant | 187        |
| CON_008 | respiratory      | consultant | 186        |
| CON_009 | respiratory      | registrar  | 160        |
| CON_007 | respiratory      | consultant | 148        |
| CON_010 | respiratory      | SHO        | 127        |
| CON_024 | general          | registrar  | 126        |
| CON_001 | cardiac          | consultant | 124        |
| CON_011 | musculoskeletal  | consultant | 117        |
| CON_021 | general          | consultant | 113        |
| CON_022 | general          | consultant | 113        |
| CON_004 | cardiac          | registrar  | 111        |
| CON_003 | cardiac          | consultant | 111        |
| CON_023 | general          | consultant | 108        |
| CON_002 | cardiac          | consultant | 104        |
| CON_016 | gastrointestinal | consultant | 102        |
| CON_012 | musculoskeletal  | consultant | 101        |
| CON_013 | musculoskeletal  | consultant | 93         |
| CON_017 | gastrointestinal | consultant | 88         |
| CON_014 | musculoskeletal  | registrar  | 85         |
| CON_018 | gastrointestinal | consultant | 78         |
| CON_019 | gastrointestinal | registrar  | 75         |
| CON_025 | general          | SHO        | 73         |
| CON_005 | cardiac          | SHO        | 72         |
| CON_020 | gastrointestinal | SHO        | 65         |
| CON_015 | musculoskeletal  | SHO        | 57         |


### Workload by specialty group

```sql
SELECT
    c.specialty_group,
    COUNT(*) AS total_admissions,
    COUNT(DISTINCT a.patient_id) AS unique_patients
FROM fact_admission a
JOIN dim_consultant c ON a.consultant_id = c.id
GROUP BY c.specialty_group
ORDER BY total_admissions DESC;
```

| specialty_group  | total_admissions | unique_patients |
|------------------|------------------|-----------------|
| respiratory      | 808              | 423             |
| general          | 533              | 301             |
| cardiac          | 522              | 312             |
| musculoskeletal  | 453              | 248             |
| gastrointestinal | 408              | 231             |


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
FROM fact_pre_op_assessment f
JOIN dim_procedure proc ON f.procedure_id = proc.id
GROUP BY proc.procedure_name, proc.complexity, proc.tariff, proc.specialty_group
ORDER BY proc.tariff DESC
LIMIT 10;
```

| procedure_name           | complexity | tariff  | specialty_group  | times_performed |
|--------------------------|------------|---------|------------------|-----------------|
| Aortic valve replacement | complex    | 14000.0 | cardiac          | 80              |
| CABG                     | complex    | 12500.0 | cardiac          | 88              |
| Lung resection           | complex    | 11000.0 | respiratory      | 122             |
| Total hip replacement    | complex    | 10500.0 | musculoskeletal  | 77              |
| Total knee replacement   | complex    | 10200.0 | musculoskeletal  | 67              |
| Bowel resection          | complex    | 9800.0  | gastrointestinal | 46              |
| Thoracotomy              | major      | 9500.0  | respiratory      | 100             |
| Coronary angioplasty     | complex    | 8500.0  | cardiac          | 81              |
| Hip hemiarthroplasty     | major      | 7800.0  | musculoskeletal  | 71              |
| Spinal decompression     | major      | 7200.0  | musculoskeletal  | 72              |


---

## Exercise 11: "Are cancer patients being seen fast enough?"

### Cancer 28-day FDS

```sql
WITH cancer_times AS (
    SELECT
        cr.cancer_pathway_id,
        MIN(cr.timestamp) AS referral_ts,
        MIN(fs.timestamp) AS first_seen_ts
    FROM fact_cancer_referral cr
    JOIN fact_cancer_first_seen fs
        ON cr.cancer_pathway_id = fs.cancer_pathway_id
    GROUP BY cr.cancer_pathway_id
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
| 605           | 22.0     | 452        | 74.7    |


---

## Exercise 12: "How are the diagnostics team performing?"

### Diagnostic 6-week compliance

```sql
WITH diag_times AS (
    SELECT
        do2.request_id,
        MIN(do2.timestamp) AS ordered_ts,
        MIN(dp.timestamp) AS performed_ts
    FROM fact_diagnostic_ordered do2
    JOIN fact_diagnostic_performed dp
        ON do2.request_id = dp.request_id
    GROUP BY do2.request_id
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
| 1303            | 36.0     | 1064       | 81.7           |


### By test type

```sql
WITH diag_times AS (
    SELECT
        do2.request_id,
        do2.diagnostic_id,
        MIN(do2.timestamp) AS ordered_ts,
        MIN(dp.timestamp) AS performed_ts
    FROM fact_diagnostic_ordered do2
    JOIN fact_diagnostic_performed dp
        ON do2.request_id = dp.request_id
    GROUP BY do2.request_id, do2.diagnostic_id
)
SELECT
    d.test_type,
    COUNT(*) AS completed,
    ROUND(AVG(EXTRACT(EPOCH FROM (dt.performed_ts - dt.ordered_ts)) / 86400.0), 0) AS avg_days
FROM diag_times dt
JOIN dim_diagnostic d ON dt.diagnostic_id = d.id
GROUP BY d.test_type
ORDER BY avg_days DESC;
```

| test_type  | completed | avg_days |
|------------|-----------|----------|
| blood      | 1261      | 35.0     |
| mri        | 416       | 35.0     |
| ultrasound | 415       | 35.0     |
| endoscopy  | 405       | 35.0     |
| pathology  | 425       | 34.0     |
| xray       | 449       | 34.0     |
| other      | 1256      | 34.0     |
| ct         | 407       | 34.0     |


---

## Exercise 13: "What happens to A&E patients after they're admitted?"

### Link ED arrivals to inpatient spells via temporal proximity

```sql
WITH ed_patients AS (
    SELECT patient_id, attendance_id AS ed_instance, timestamp AS ed_arrival_ts
    FROM fact_ed_arrival
),
ip_spells AS (
    SELECT
        a.patient_id,
        a.spell_id AS ip_instance,
        MIN(a.timestamp) AS admit_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d ON a.spell_id = d.spell_id
    GROUP BY a.patient_id, a.spell_id
)
SELECT
    COUNT(*) AS ed_admitted_spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (ip.discharge_ts - ip.admit_ts)) / 86400.0), 1) AS ed_alos,
    (SELECT ROUND(AVG(EXTRACT(EPOCH FROM (discharge_ts - admit_ts)) / 86400.0), 1) FROM ip_spells) AS overall_alos
FROM ed_patients e
JOIN ip_spells ip
    ON e.patient_id = ip.patient_id
    AND ip.admit_ts BETWEEN e.ed_arrival_ts AND e.ed_arrival_ts + INTERVAL '24 hours';
```

| ed_admitted_spells | ed_alos | overall_alos |
|--------------------|---------|--------------|
| 195                | 5.4     | 5.5          |


---

## Exercise 14: "Are we readmitting too many patients?"

### 30-day readmission rate

```sql
WITH spells AS (
    SELECT
        a.patient_id,
        a.spell_id,
        MIN(a.timestamp) AS admit_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d ON a.spell_id = d.spell_id
    GROUP BY a.patient_id, a.spell_id
)
SELECT
    COUNT(DISTINCT s2.spell_id) AS readmissions,
    (SELECT COUNT(*) FROM spells) AS total_completed_spells,
    ROUND(100.0 * COUNT(DISTINCT s2.spell_id)
        / (SELECT COUNT(*) FROM spells), 1) AS readmission_pct
FROM spells s1
JOIN spells s2
    ON s1.patient_id = s2.patient_id
    AND s2.admit_ts > s1.discharge_ts
    AND EXTRACT(EPOCH FROM (s2.admit_ts - s1.discharge_ts)) / 86400.0 <= 30;
```

| readmissions | total_completed_spells | readmission_pct |
|--------------|------------------------|-----------------|
| 78           | 1124                   | 6.9             |


---

## Exercise 15: "Which patients cost the most?"

### Procedure costs per patient

```sql
SELECT
    f.patient_id,
    p.primary_condition,
    SUM(proc.tariff) AS total_procedure_cost,
    COUNT(*) AS procedures_performed
FROM fact_pre_op_assessment f
JOIN dim_procedure proc ON f.procedure_id = proc.id
JOIN dim_patient p ON f.patient_id = p.id AND p.valid_to IS NULL
GROUP BY f.patient_id, p.primary_condition
ORDER BY total_procedure_cost DESC
LIMIT 15;
```

| patient_id  | primary_condition | total_procedure_cost | procedures_performed |
|-------------|-------------------|----------------------|----------------------|
| PAT_0001957 | ortho             | 72300.0              | 10                   |
| PAT_0003864 | ortho             | 67200.0              | 9                    |
| PAT_0001941 | ortho             | 57900.0              | 7                    |
| PAT_0000126 | cardiac           | 57250.0              | 8                    |
| PAT_0003487 | ortho             | 53900.0              | 7                    |
| PAT_0001395 | cardiac           | 53300.0              | 6                    |
| PAT_0000766 | ortho             | 52700.0              | 6                    |
| PAT_0003623 | ortho             | 52100.0              | 6                    |
| PAT_0000943 | cardiac           | 50900.0              | 6                    |
| PAT_0001951 | cardiac           | 49950.0              | 6                    |
| PAT_0004892 | ortho             | 48700.0              | 7                    |
| PAT_0002707 | ortho             | 47700.0              | 6                    |
| PAT_0003978 | ortho             | 47300.0              | 6                    |
| PAT_0001135 | cardiac           | 47150.0              | 5                    |
| PAT_0003928 | ortho             | 46500.0              | 5                    |


### Bed-day costs for completed spells

```sql
WITH spell_los AS (
    SELECT
        a.patient_id,
        a.spell_id,
        MIN(a.timestamp) AS admit_ts,
        MIN(d.timestamp) AS discharge_ts,
        EXTRACT(EPOCH FROM (MIN(d.timestamp) - MIN(a.timestamp))) / 86400.0 AS los_days
    FROM fact_admission a
    JOIN fact_discharge d ON a.spell_id = d.spell_id
    GROUP BY a.patient_id, a.spell_id
),
ward_costs AS (
    SELECT
        wa.spell_id,
        AVG(w.cost_per_bed_day) AS avg_bed_cost
    FROM fact_ward_assignment wa
    JOIN dim_ward w ON wa.ward_id = w.id
    GROUP BY wa.spell_id
)
SELECT
    sl.patient_id,
    ROUND(sl.los_days, 1) AS los_days,
    ROUND(wc.avg_bed_cost, 0) AS avg_bed_cost_per_day,
    ROUND(sl.los_days * wc.avg_bed_cost, 0) AS total_bed_cost
FROM spell_los sl
JOIN ward_costs wc ON sl.spell_id = wc.spell_id
ORDER BY total_bed_cost DESC
LIMIT 15;
```

| patient_id  | los_days | avg_bed_cost_per_day | total_bed_cost |
|-------------|----------|----------------------|----------------|
| PAT_0001914 | 8.7      | 1800.0               | 15741.0        |
| PAT_0000612 | 10.9     | 1375.0               | 14999.0        |
| PAT_0001709 | 14.1     | 1050.0               | 14773.0        |
| PAT_0002199 | 7.9      | 1800.0               | 14224.0        |
| PAT_0002668 | 12.2     | 1100.0               | 13382.0        |
| PAT_0002160 | 9.8      | 1350.0               | 13243.0        |
| PAT_0001445 | 7.0      | 1800.0               | 12607.0        |
| PAT_0002995 | 9.1      | 1375.0               | 12526.0        |
| PAT_0004665 | 9.8      | 1220.0               | 11940.0        |
| PAT_0002617 | 6.5      | 1800.0               | 11783.0        |
| PAT_0003039 | 8.5      | 1375.0               | 11716.0        |
| PAT_0001171 | 6.4      | 1800.0               | 11585.0        |
| PAT_0001249 | 16.9     | 675.0                | 11407.0        |
| PAT_0000101 | 8.0      | 1350.0               | 10825.0        |
| PAT_0000181 | 6.0      | 1800.0               | 10747.0        |


---

## Exercise 16: "Do deprived patients have worse outcomes?"

### ALOS by deprivation

```sql
WITH spells AS (
    SELECT
        a.patient_id,
        a.spell_id,
        MIN(a.timestamp) AS admit_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d ON a.spell_id = d.spell_id
    GROUP BY a.patient_id, a.spell_id
)
SELECT
    p.imd_decile,
    COUNT(*) AS spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (s.discharge_ts - s.admit_ts)) / 86400.0), 1) AS avg_los
FROM spells s
JOIN dim_patient p ON s.patient_id = p.id AND p.valid_to IS NULL
GROUP BY p.imd_decile
ORDER BY p.imd_decile;
```

| imd_decile | spells | avg_los |
|------------|--------|---------|
| 1          | 118    | 5.6     |
| 2          | 126    | 5.4     |
| 3          | 100    | 5.3     |
| 4          | 114    | 5.4     |
| 5          | 110    | 5.5     |
| 6          | 108    | 5.4     |
| 7          | 111    | 5.4     |
| 8          | 109    | 5.4     |
| 9          | 124    | 5.6     |
| 10         | 104    | 5.3     |


### Referral-to-attendance ratio by deprivation

```sql
WITH referrals AS (
    SELECT r.patient_id, COUNT(DISTINCT r.pathway_id) AS ref_count
    FROM fact_referral_created r
    GROUP BY r.patient_id
),
attended AS (
    SELECT a.patient_id, COUNT(DISTINCT a.pathway_id) AS att_count
    FROM fact_appointment_attended a
    GROUP BY a.patient_id
)
SELECT
    p.imd_decile,
    SUM(r.ref_count) AS referrals,
    COALESCE(SUM(a.att_count), 0) AS attended,
    ROUND(100.0 * COALESCE(SUM(a.att_count), 0) / SUM(r.ref_count), 1) AS attendance_pct
FROM referrals r
JOIN dim_patient p ON r.patient_id = p.id AND p.valid_to IS NULL
LEFT JOIN attended a ON r.patient_id = a.patient_id
GROUP BY p.imd_decile
ORDER BY p.imd_decile;
```

| imd_decile | referrals | attended | attendance_pct |
|------------|-----------|----------|----------------|
| 1          | 306       | 233      | 76.1           |
| 2          | 301       | 241      | 80.1           |
| 3          | 302       | 239      | 79.1           |
| 4          | 357       | 278      | 77.9           |
| 5          | 356       | 288      | 80.9           |
| 6          | 320       | 255      | 79.7           |
| 7          | 339       | 281      | 82.9           |
| 8          | 333       | 269      | 80.8           |
| 9          | 337       | 262      | 77.7           |
| 10         | 291       | 222      | 76.3           |


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
    e.month,
    e.ed_arrivals,
    COALESCE(a.admissions, 0) AS admissions,
    COALESCE(d.discharges, 0) AS discharges,
    COALESCE(i.icu_events, 0) AS icu_events,
    COALESCE(s.surgeries, 0) AS surgeries
FROM monthly_ed e
LEFT JOIN monthly_admits a ON e.month = a.month
LEFT JOIN monthly_discharges d ON e.month = d.month
LEFT JOIN monthly_icu i ON e.month = i.month
LEFT JOIN monthly_surgeries s ON e.month = s.month
ORDER BY e.month;
```

| month      | ed_arrivals | admissions | discharges | icu_events | surgeries |
|------------|-------------|------------|------------|------------|-----------|
| 2023-01-01 | 74          | 30         | 15         | 0          | 0         |
| 2023-02-01 | 43          | 23         | 12         | 6          | 2         |
| 2023-03-01 | 52          | 45         | 21         | 8          | 43        |
| 2023-04-01 | 64          | 57         | 37         | 7          | 79        |
| 2023-05-01 | 47          | 37         | 25         | 4          | 90        |
| 2023-06-01 | 48          | 50         | 26         | 6          | 107       |
| 2023-07-01 | 51          | 42         | 27         | 0          | 109       |
| 2023-08-01 | 50          | 42         | 27         | 0          | 127       |
| 2023-09-01 | 61          | 47         | 24         | 9          | 79        |
| 2023-10-01 | 53          | 47         | 29         | 8          | 90        |
| 2023-11-01 | 36          | 42         | 26         | 0          | 137       |
| 2023-12-01 | 60          | 45         | 26         | 3          | 94        |
| 2024-01-01 | 58          | 47         | 34         | 11         | 130       |
| 2024-02-01 | 55          | 41         | 24         | 0          | 143       |
| 2024-03-01 | 57          | 61         | 35         | 7          | 135       |
| 2024-04-01 | 51          | 54         | 38         | 5          | 144       |
| 2024-05-01 | 50          | 48         | 28         | 9          | 111       |
| 2024-06-01 | 50          | 47         | 30         | 10         | 149       |
| 2024-07-01 | 65          | 51         | 26         | 13         | 130       |
| 2024-08-01 | 61          | 52         | 30         | 6          | 165       |
| 2024-09-01 | 65          | 51         | 34         | 0          | 153       |
| 2024-10-01 | 38          | 45         | 29         | 6          | 172       |
| 2024-11-01 | 90          | 63         | 43         | 9          | 119       |
| 2024-12-01 | 85          | 68         | 39         | 22         | 133       |
| 2025-01-01 | 65          | 52         | 30         | 9          | 140       |
| 2025-02-01 | 91          | 75         | 32         | 2          | 124       |
| 2025-03-01 | 98          | 75         | 52         | 13         | 124       |
| 2025-04-01 | 55          | 68         | 43         | 8          | 147       |
| 2025-05-01 | 70          | 61         | 40         | 12         | 176       |
| 2025-06-01 | 53          | 63         | 37         | 21         | 194       |
| 2025-07-01 | 64          | 76         | 53         | 11         | 205       |
| 2025-08-01 | 62          | 49         | 30         | 3          | 130       |
| 2025-09-01 | 63          | 58         | 32         | 7          | 119       |
| 2025-10-01 | 61          | 60         | 39         | 10         | 165       |
| 2025-11-01 | 61          | 55         | 34         | 9          | 141       |
| 2025-12-01 | 63          | 38         | 17         | 8          | 128       |


### Daily ED arrivals to spot spikes

```sql
SELECT
    timestamp::DATE AS day,
    COUNT(*) AS arrivals
FROM fact_ed_arrival
GROUP BY day
ORDER BY arrivals DESC
LIMIT 10;
```

| day        | arrivals |
|------------|----------|
| 2023-01-01 | 30       |
| 2024-11-01 | 8        |
| 2024-12-09 | 8        |
| 2024-06-24 | 7        |
| 2024-07-03 | 7        |
| 2024-08-01 | 7        |
| 2025-02-19 | 7        |
| 2025-02-25 | 7        |
| 2025-03-17 | 7        |
| 2025-09-23 | 7        |


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
| 2023 | summer | 374      | 53.0           |
| 2023 | winter | 265      | 53.0           |
| 2024 | summer | 380      | 54.0           |
| 2024 | winter | 345      | 69.0           |
| 2025 | summer | 428      | 61.0           |
| 2025 | winter | 378      | 76.0           |


---

## Exercise 18: "Something looks wrong with the survey data."

### Score distribution

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
| 1                    | 332       | 35.2 |
| 2                    | 423       | 44.8 |
| 3                    | 165       | 17.5 |
| 4                    | 23        | 2.4  |
| 5                    | 1         | 0.1  |


### Affected records

```sql
SELECT
    COUNT(*) AS total_responses,
    SUM(CASE WHEN recommendation_score > 5 THEN 1 ELSE 0 END) AS invalid_scores,
    SUM(CASE WHEN recommendation_score < 4 THEN 1 ELSE 0 END) AS negative_responses
FROM fact_fft_response;
```

| total_responses | invalid_scores | negative_responses |
|-----------------|----------------|--------------------|
| 944             | 0              | 920                |




---

## Exercise 19: "The Finance Director wants to know our surgical revenue."

### Theatre utilisation

```sql
SELECT
    t.theatre_name,
    t.specialty,
    COUNT(*) AS surgeries,
    ROUND(COUNT(*) * 1.0 / DATEDIFF('day',
        (SELECT MIN(timestamp) FROM fact_surgery_performed),
        (SELECT MAX(timestamp) FROM fact_surgery_performed)
    ), 1) AS per_day
FROM fact_surgery_performed sp
JOIN dim_theatre t ON sp.theatre_id = t.id
GROUP BY t.theatre_name, t.specialty
ORDER BY surgeries DESC;
```

| theatre_name        | specialty                    | surgeries | per_day |
|---------------------|------------------------------|-----------|---------|
| Main Theatre 1      | General Surgery              | 928       | 0.9     |
| Main Theatre 2      | Trauma & Orthopaedics        | 905       | 0.9     |
| Day Surgery Theatre | General / Mixed              | 887       | 0.9     |
| Cardiac Theatre     | Cardiology / Cardiac Surgery | 866       | 0.8     |
| Obstetric Theatre   | Obstetrics                   | 848       | 0.8     |


### Revenue by procedure complexity

```sql
WITH surgery_procedures AS (
    SELECT
        sp.surgical_episode_id,
        proc.procedure_name,
        proc.complexity,
        proc.tariff,
        proc.specialty_group
    FROM fact_surgery_performed sp
    JOIN fact_pre_op_assessment po
        ON sp.surgical_episode_id = po.surgical_episode_id
    JOIN dim_procedure proc ON po.procedure_id = proc.id
)
SELECT
    complexity,
    COUNT(*) AS surgeries,
    ROUND(AVG(tariff), 0) AS avg_tariff,
    SUM(tariff) AS total_revenue
FROM surgery_procedures
GROUP BY complexity
ORDER BY total_revenue DESC;
```

| complexity | surgeries | avg_tariff | total_revenue |
|------------|-----------|------------|---------------|
| complex    | 1475      | 11049.0    | 16297100.0    |
| major      | 1924      | 6463.0     | 12433900.0    |
| moderate   | 2117      | 1978.0     | 4187800.0     |
| minor      | 1557      | 659.0      | 1026550.0     |


---

## Exercise 20: "Are we keeping patients, or just cycling through them?"

### Inpatient spells per patient

```sql
SELECT
    spells_per_patient,
    COUNT(*) AS patients
FROM (
    SELECT patient_id, COUNT(DISTINCT spell_id) AS spells_per_patient
    FROM fact_admission
    GROUP BY patient_id
)
GROUP BY spells_per_patient
ORDER BY spells_per_patient;
```

| spells_per_patient | patients |
|--------------------|----------|
| 1                  | 1234     |
| 2                  | 250      |
| 3                  | 24       |
| 4                  | 5        |
| 5                  | 2        |


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
ORDER BY total_journeys DESC
LIMIT 15;
```

| patient_id  | total_journeys | pathway_types |
|-------------|----------------|---------------|
| PAT_0000612 | 9              | 3             |
| PAT_0000115 | 9              | 3             |
| PAT_0001866 | 8              | 3             |
| PAT_0003438 | 7              | 3             |
| PAT_0000521 | 7              | 3             |
| PAT_0001748 | 7              | 3             |
| PAT_0002119 | 7              | 3             |
| PAT_0002242 | 7              | 3             |
| PAT_0003091 | 7              | 3             |
| PAT_0000605 | 7              | 3             |
| PAT_0000260 | 7              | 3             |
| PAT_0001941 | 7              | 3             |
| PAT_0001914 | 7              | 3             |
| PAT_0000042 | 7              | 3             |
| PAT_0003762 | 6              | 3             |


### Condition profile of high-frequency patients

```sql
WITH patient_spells AS (
    SELECT patient_id, COUNT(DISTINCT spell_id) AS spell_count
    FROM fact_admission
    GROUP BY patient_id
    HAVING COUNT(DISTINCT spell_id) >= 3
)
SELECT
    p.primary_condition,
    p.comorbidity_count,
    AVG(ps.spell_count) AS avg_spells,
    COUNT(*) AS patients
FROM patient_spells ps
JOIN dim_patient p ON ps.patient_id = p.id AND p.valid_to IS NULL
GROUP BY p.primary_condition, p.comorbidity_count
ORDER BY avg_spells DESC;
```

| primary_condition | comorbidity_count | avg_spells         | patients |
|-------------------|-------------------|--------------------|----------|
| GI                | 4                 | 5.0                | 1        |
| infectious        | 4                 | 5.0                | 1        |
| infectious        | 3                 | 4.0                | 1        |
| neuro             | 1                 | 4.0                | 1        |
| respiratory       | 0                 | 3.5                | 2        |
| cardiac           | 1                 | 3.5                | 2        |
| respiratory       | 3                 | 3.3333333333333335 | 3        |
| obstetric         | 3                 | 3.0                | 2        |
| neuro             | 3                 | 3.0                | 2        |
| ortho             | 6                 | 3.0                | 2        |
| cardiac           | 4                 | 3.0                | 1        |
| respiratory       | 1                 | 3.0                | 3        |
| ortho             | 1                 | 3.0                | 2        |
| neuro             | 6                 | 3.0                | 1        |
| ortho             | 3                 | 3.0                | 3        |
| cardiac           | 3                 | 3.0                | 1        |
| ortho             | 2                 | 3.0                | 1        |
| GI                | 6                 | 3.0                | 1        |
| neuro             | 0                 | 3.0                | 1        |


---

## Exercise 21: "Are we getting better or worse?"

### A&E 4-hour performance by quarter

```sql
SELECT
    DATE_TRUNC('quarter', arr.timestamp)::DATE AS quarter,
    COUNT(*) AS assessed,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (ea.timestamp - arr.timestamp)) / 60 <= 240
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_within_4h
FROM fact_ed_arrival arr
JOIN fact_ed_assessment ea
    ON arr.attendance_id = ea.attendance_id
GROUP BY quarter
ORDER BY quarter;
```

| quarter    | assessed | pct_within_4h |
|------------|----------|---------------|
| 2023-01-01 | 161      | 88.8          |
| 2023-04-01 | 152      | 86.2          |
| 2023-07-01 | 151      | 88.7          |
| 2023-10-01 | 142      | 81.7          |
| 2024-01-01 | 161      | 87.6          |
| 2024-04-01 | 138      | 86.2          |
| 2024-07-01 | 183      | 89.6          |
| 2024-10-01 | 202      | 85.1          |
| 2025-01-01 | 244      | 82.8          |
| 2025-04-01 | 169      | 84.6          |
| 2025-07-01 | 175      | 82.9          |
| 2025-10-01 | 178      | 83.1          |


### Cancer 28-day FDS by quarter

```sql
WITH cancer_times AS (
    SELECT
        cr.cancer_pathway_id,
        MIN(cr.timestamp) AS referral_ts,
        MIN(fs.timestamp) AS first_seen_ts
    FROM fact_cancer_referral cr
    JOIN fact_cancer_first_seen fs
        ON cr.cancer_pathway_id = fs.cancer_pathway_id
    GROUP BY cr.cancer_pathway_id
)
SELECT
    DATE_TRUNC('quarter', referral_ts)::DATE AS quarter,
    COUNT(*) AS journeys,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (first_seen_ts - referral_ts)) / 86400.0 <= 28
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_fds
FROM cancer_times
GROUP BY quarter
ORDER BY quarter;
```

| quarter    | journeys | pct_fds |
|------------|----------|---------|
| 2023-01-01 | 61       | 72.1    |
| 2023-04-01 | 47       | 72.3    |
| 2023-07-01 | 38       | 84.2    |
| 2023-10-01 | 38       | 68.4    |
| 2024-01-01 | 51       | 70.6    |
| 2024-04-01 | 44       | 72.7    |
| 2024-07-01 | 45       | 75.6    |
| 2024-10-01 | 60       | 71.7    |
| 2025-01-01 | 75       | 69.3    |
| 2025-04-01 | 56       | 75.0    |
| 2025-07-01 | 52       | 86.5    |
| 2025-10-01 | 38       | 84.2    |


### Diagnostic 6-week compliance by quarter

```sql
WITH diag_times AS (
    SELECT
        do2.request_id,
        MIN(do2.timestamp) AS ordered_ts,
        MIN(dp.timestamp) AS performed_ts
    FROM fact_diagnostic_ordered do2
    JOIN fact_diagnostic_performed dp
        ON do2.request_id = dp.request_id
    GROUP BY do2.request_id
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
| 2023-01-01 | 41              | 80.5           |
| 2023-04-01 | 72              | 86.1           |
| 2023-07-01 | 108             | 80.6           |
| 2023-10-01 | 105             | 79.0           |
| 2024-01-01 | 103             | 87.4           |
| 2024-04-01 | 134             | 81.3           |
| 2024-07-01 | 105             | 86.7           |
| 2024-10-01 | 115             | 75.7           |
| 2025-01-01 | 143             | 83.2           |
| 2025-04-01 | 156             | 79.5           |
| 2025-07-01 | 145             | 75.2           |
| 2025-10-01 | 76              | 92.1           |


---

## Exercise 22: "Do our patients come back?"

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
    SELECT patient_id, MIN(timestamp) AS first_ts
    FROM all_activity
    GROUP BY patient_id
),
cohort_2023 AS (
    SELECT patient_id
    FROM first_activity
    WHERE EXTRACT(YEAR FROM first_ts) = 2023
)
SELECT
    EXTRACT(YEAR FROM a.timestamp)::INTEGER AS activity_year,
    COUNT(DISTINCT a.patient_id) AS patients_active
FROM all_activity a
JOIN cohort_2023 c ON a.patient_id = c.patient_id
GROUP BY activity_year
ORDER BY activity_year;
```

| activity_year | patients_active |
|---------------|-----------------|
| 2023          | 1772            |
| 2024          | 519             |
| 2025          | 201             |


---
