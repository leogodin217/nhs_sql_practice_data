# Exercise Results

## Exercise 1: "How many patients does the trust serve?"

### Using DISTINCT

```sql
SELECT COUNT(DISTINCT id) AS patient_count
FROM dim_patient;
```

| patient_count |
|---------------|
| 5360          |


### Only current patients

```sql
SELECT COUNT(*) AS current_patients
FROM dim_patient
WHERE valid_to IS NULL;
```

| current_patients |
|------------------|
| 5360             |


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
SELECT DISTINCT entity_type
FROM fact_admission
UNION
SELECT DISTINCT entity_type FROM fact_ed_arrival
UNION
SELECT DISTINCT entity_type FROM fact_surgery_performed
UNION
SELECT DISTINCT entity_type FROM fact_appointment_attended;
```

| entity_type |
|-------------|
| theatre     |
| consultant  |


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
| elective     | 2943     |
| emergency    | 1885     |
| cancer       | 532      |


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
| cardiac           | 1203     |
| respiratory       | 958      |
| ortho             | 810      |
| GI                | 809      |
| neuro             | 625      |
| infectious        | 545      |
| obstetric         | 410      |


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
| 1          | 509      |
| 2          | 547      |
| 3          | 501      |
| 4          | 556      |
| 5          | 589      |
| 6          | 536      |
| 7          | 527      |
| 8          | 525      |
| 9          | 562      |
| 10         | 508      |


---

## Exercise 5: "Are we hitting the 4-hour A&E target?"

### Join arrival to assessment on journey_instance_id

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
    ON arr.journey_instance_id = ea.journey_instance_id;
```

| assessed_patients | avg_minutes | within_4h | pct_within_4h |
|-------------------|-------------|-----------|---------------|
| 2022              | 145         | 1703      | 84.2          |


---

## Exercise 6: "How long are patients staying?"

### ALOS for completed spells

```sql
WITH spells AS (
    SELECT
        a.journey_instance_id,
        MIN(a.timestamp) AS admission_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d
        ON a.journey_instance_id = d.journey_instance_id
    GROUP BY a.journey_instance_id
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
| 1073             | 5.5           | 5.1             |


### ALOS by primary condition

```sql
WITH spells AS (
    SELECT
        a.journey_instance_id,
        a.actor_id,
        MIN(a.timestamp) AS admission_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d
        ON a.journey_instance_id = d.journey_instance_id
    GROUP BY a.journey_instance_id, a.actor_id
)
SELECT
    p.primary_condition,
    COUNT(*) AS spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (s.discharge_ts - s.admission_ts)) / 86400.0), 1) AS mean_los
FROM spells s
JOIN dim_patient p ON s.actor_id = p.id AND p.valid_to IS NULL
GROUP BY p.primary_condition
ORDER BY mean_los DESC;
```

| primary_condition | spells | mean_los |
|-------------------|--------|----------|
| neuro             | 114    | 5.9      |
| obstetric         | 88     | 5.7      |
| infectious        | 132    | 5.6      |
| cardiac           | 233    | 5.5      |
| ortho             | 157    | 5.4      |
| GI                | 165    | 5.4      |
| respiratory       | 184    | 5.3      |


---

## Exercise 7: "How many referrals actually turn into appointments?"

### Outpatient funnel

```sql
SELECT
    'referrals' AS stage,
    COUNT(DISTINCT journey_instance_id) AS journey_instances
FROM fact_referral_created
UNION ALL
SELECT
    'attended',
    COUNT(DISTINCT journey_instance_id)
FROM fact_appointment_attended
ORDER BY journey_instances DESC;
```

| stage     | journey_instances |
|-----------|-------------------|
| referrals | 3248              |
| attended  | 2527              |


### Referral volume by month

```sql
SELECT
    DATE_TRUNC('month', timestamp)::DATE AS month,
    COUNT(DISTINCT journey_instance_id) AS referrals
FROM fact_referral_created
GROUP BY month
ORDER BY month;
```

| month      | referrals |
|------------|-----------|
| 2023-01-01 | 132       |
| 2023-02-01 | 77        |
| 2023-03-01 | 100       |
| 2023-04-01 | 66        |
| 2023-05-01 | 78        |
| 2023-06-01 | 87        |
| 2023-07-01 | 87        |
| 2023-08-01 | 72        |
| 2023-09-01 | 85        |
| 2023-10-01 | 78        |
| 2023-11-01 | 83        |
| 2023-12-01 | 80        |
| 2024-01-01 | 109       |
| 2024-02-01 | 80        |
| 2024-03-01 | 87        |
| 2024-04-01 | 90        |
| 2024-05-01 | 105       |
| 2024-06-01 | 99        |
| 2024-07-01 | 103       |
| 2024-08-01 | 93        |
| 2024-09-01 | 107       |
| 2024-10-01 | 94        |
| 2024-11-01 | 130       |
| 2024-12-01 | 135       |
| 2025-01-01 | 138       |
| 2025-02-01 | 118       |
| 2025-03-01 | 110       |
| 2025-04-01 | 83        |
| 2025-05-01 | 88        |
| 2025-06-01 | 101       |
| 2025-07-01 | 90        |
| 2025-08-01 | 92        |
| 2025-09-01 | 127       |
| 2025-10-01 | 101       |
| 2025-11-01 | 109       |
| 2025-12-01 | 103       |


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
| 3                    | 150       | 15.6 |
| 4                    | 339       | 35.3 |
| 5                    | 320       | 33.3 |
| 6                    | 151       | 15.7 |


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
| 960             | 810      | 84.4          |


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
JOIN dim_consultant c ON a.entity_id = c.id
GROUP BY c.id, c.specialty_group, c.grade
ORDER BY admissions DESC;
```

| id      | specialty_group  | grade      | admissions |
|---------|------------------|------------|------------|
| CON_006 | respiratory      | consultant | 182        |
| CON_009 | respiratory      | registrar  | 167        |
| CON_007 | respiratory      | consultant | 167        |
| CON_008 | respiratory      | consultant | 157        |
| CON_003 | cardiac          | consultant | 143        |
| CON_002 | cardiac          | consultant | 138        |
| CON_001 | cardiac          | consultant | 131        |
| CON_022 | general          | consultant | 127        |
| CON_021 | general          | consultant | 122        |
| CON_010 | respiratory      | SHO        | 119        |
| CON_023 | general          | consultant | 117        |
| CON_004 | cardiac          | registrar  | 117        |
| CON_005 | cardiac          | SHO        | 106        |
| CON_011 | musculoskeletal  | consultant | 102        |
| CON_018 | gastrointestinal | consultant | 93         |
| CON_016 | gastrointestinal | consultant | 93         |
| CON_024 | general          | registrar  | 92         |
| CON_013 | musculoskeletal  | consultant | 87         |
| CON_019 | gastrointestinal | registrar  | 81         |
| CON_012 | musculoskeletal  | consultant | 79         |
| CON_017 | gastrointestinal | consultant | 74         |
| CON_014 | musculoskeletal  | registrar  | 74         |
| CON_025 | general          | SHO        | 65         |
| CON_015 | musculoskeletal  | SHO        | 57         |
| CON_020 | gastrointestinal | SHO        | 55         |


### Workload by specialty group

```sql
SELECT
    c.specialty_group,
    COUNT(*) AS total_admissions,
    COUNT(DISTINCT a.actor_id) AS unique_patients
FROM fact_admission a
JOIN dim_consultant c ON a.entity_id = c.id
GROUP BY c.specialty_group
ORDER BY total_admissions DESC;
```

| specialty_group  | total_admissions | unique_patients |
|------------------|------------------|-----------------|
| respiratory      | 792              | 442             |
| cardiac          | 635              | 340             |
| general          | 523              | 291             |
| musculoskeletal  | 399              | 222             |
| gastrointestinal | 396              | 236             |


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
JOIN dim_procedure proc ON f.entity_id = proc.id
GROUP BY proc.procedure_name, proc.complexity, proc.tariff, proc.specialty_group
ORDER BY proc.tariff DESC
LIMIT 10;
```

| procedure_name           | complexity | tariff | specialty_group  | times_performed |
|--------------------------|------------|--------|------------------|-----------------|
| Aortic valve replacement | complex    | 14000  | cardiac          | 75              |
| CABG                     | complex    | 12500  | cardiac          | 81              |
| Lung resection           | complex    | 11000  | respiratory      | 102             |
| Total hip replacement    | complex    | 10500  | musculoskeletal  | 58              |
| Total knee replacement   | complex    | 10200  | musculoskeletal  | 57              |
| Bowel resection          | complex    | 9800   | gastrointestinal | 56              |
| Thoracotomy              | major      | 9500   | respiratory      | 104             |
| Coronary angioplasty     | complex    | 8500   | cardiac          | 74              |
| Hip hemiarthroplasty     | major      | 7800   | musculoskeletal  | 64              |
| Spinal decompression     | major      | 7200   | musculoskeletal  | 61              |


---

## Exercise 11: "Are cancer patients being seen fast enough?"

### Cancer 28-day FDS

```sql
WITH cancer_times AS (
    SELECT
        cr.journey_instance_id,
        MIN(cr.timestamp) AS referral_ts,
        MIN(fs.timestamp) AS first_seen_ts
    FROM fact_cancer_referral cr
    JOIN fact_cancer_first_seen fs
        ON cr.journey_instance_id = fs.journey_instance_id
    GROUP BY cr.journey_instance_id
)
SELECT
    COUNT(*) AS journeys_seen,
    ROUND(AVG(EXTRACT(EPOCH FROM (first_seen_ts - referral_ts)) / 86400.0), 0) AS avg_days,
    SUM(CASE WHEN EXTRACT(EPOCH FROM (first_seen_ts - referral_ts)) / 86400.0 <= 28
        THEN 1 ELSE 0 END) AS within_28d,
    ROUND(100.0 * SUM(CASE WHEN EXTRACT(EPOCH FROM (first_seen_ts - referral_ts)) / 86400.0 <= 28
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_fds
FROM cancer_times;
```

| journeys_seen | avg_days | within_28d | pct_fds |
|---------------|----------|------------|---------|
| 612           | 22       | 448        | 73.2    |


---

## Exercise 12: "How are the diagnostics team performing?"

### Diagnostic 6-week compliance

```sql
WITH diag_times AS (
    SELECT
        do2.journey_instance_id,
        MIN(do2.timestamp) AS ordered_ts,
        MIN(dp.timestamp) AS performed_ts
    FROM fact_diagnostic_ordered do2
    JOIN fact_diagnostic_performed dp
        ON do2.journey_instance_id = dp.journey_instance_id
    GROUP BY do2.journey_instance_id
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
| 1249            | 36       | 1034       | 82.8           |


### By test type

```sql
WITH diag_times AS (
    SELECT
        do2.journey_instance_id,
        do2.entity_id,
        MIN(do2.timestamp) AS ordered_ts,
        MIN(dp.timestamp) AS performed_ts
    FROM fact_diagnostic_ordered do2
    JOIN fact_diagnostic_performed dp
        ON do2.journey_instance_id = dp.journey_instance_id
    GROUP BY do2.journey_instance_id, do2.entity_id
)
SELECT
    d.test_type,
    COUNT(*) AS completed,
    ROUND(AVG(EXTRACT(EPOCH FROM (dt.performed_ts - dt.ordered_ts)) / 86400.0), 0) AS avg_days
FROM diag_times dt
JOIN dim_diagnostic d ON dt.entity_id = d.id
GROUP BY d.test_type
ORDER BY avg_days DESC;
```

| test_type  | completed | avg_days |
|------------|-----------|----------|
| xray       | 404       | 35       |
| blood      | 1207      | 35       |
| other      | 1199      | 35       |
| ultrasound | 392       | 34       |
| ct         | 421       | 34       |
| mri        | 402       | 34       |
| pathology  | 408       | 34       |
| endoscopy  | 417       | 34       |


---

## Exercise 13: "What happens to A&E patients after they're admitted?"

### Link ED arrivals to inpatient spells via temporal proximity

```sql
WITH ed_patients AS (
    SELECT actor_id, journey_instance_id AS ed_instance, timestamp AS ed_arrival_ts
    FROM fact_ed_arrival
),
ip_spells AS (
    SELECT
        a.actor_id,
        a.journey_instance_id AS ip_instance,
        MIN(a.timestamp) AS admit_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d ON a.journey_instance_id = d.journey_instance_id
    GROUP BY a.actor_id, a.journey_instance_id
)
SELECT
    COUNT(*) AS ed_admitted_spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (ip.discharge_ts - ip.admit_ts)) / 86400.0), 1) AS ed_alos,
    (SELECT ROUND(AVG(EXTRACT(EPOCH FROM (discharge_ts - admit_ts)) / 86400.0), 1) FROM ip_spells) AS overall_alos
FROM ed_patients e
JOIN ip_spells ip
    ON e.actor_id = ip.actor_id
    AND ip.admit_ts BETWEEN e.ed_arrival_ts AND e.ed_arrival_ts + INTERVAL '24 hours';
```

| ed_admitted_spells | ed_alos | overall_alos |
|--------------------|---------|--------------|
| 196                | 5.6     | 5.5          |


---

## Exercise 14: "Are we readmitting too many patients?"

### 30-day readmission rate

```sql
WITH spells AS (
    SELECT
        a.actor_id,
        a.journey_instance_id,
        MIN(a.timestamp) AS admit_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d ON a.journey_instance_id = d.journey_instance_id
    GROUP BY a.actor_id, a.journey_instance_id
)
SELECT
    COUNT(DISTINCT s2.journey_instance_id) AS readmissions,
    (SELECT COUNT(*) FROM spells) AS total_completed_spells,
    ROUND(100.0 * COUNT(DISTINCT s2.journey_instance_id)
        / (SELECT COUNT(*) FROM spells), 1) AS readmission_pct
FROM spells s1
JOIN spells s2
    ON s1.actor_id = s2.actor_id
    AND s2.admit_ts > s1.discharge_ts
    AND EXTRACT(EPOCH FROM (s2.admit_ts - s1.discharge_ts)) / 86400.0 <= 30;
```

| readmissions | total_completed_spells | readmission_pct |
|--------------|------------------------|-----------------|
| 67           | 1073                   | 6.2             |


---

## Exercise 15: "Which patients cost the most?"

### Procedure costs per patient

```sql
SELECT
    f.actor_id,
    p.primary_condition,
    SUM(proc.tariff) AS total_procedure_cost,
    COUNT(*) AS procedures_performed
FROM fact_pre_op_assessment f
JOIN dim_procedure proc ON f.entity_id = proc.id
JOIN dim_patient p ON f.actor_id = p.id AND p.valid_to IS NULL
GROUP BY f.actor_id, p.primary_condition
ORDER BY total_procedure_cost DESC
LIMIT 15;
```

| actor_id    | primary_condition | total_procedure_cost | procedures_performed |
|-------------|-------------------|----------------------|----------------------|
| PAT_0000496 | cardiac           | 67400                | 6                    |
| PAT_0000416 | cardiac           | 59200                | 8                    |
| PAT_0000066 | cardiac           | 57100                | 6                    |
| PAT_0000296 | cardiac           | 56050                | 7                    |
| PAT_0003069 | cardiac           | 53300                | 5                    |
| PAT_0000005 | infectious        | 52000                | 7                    |
| PAT_0002188 | ortho             | 49500                | 7                    |
| PAT_0000045 | cardiac           | 49000                | 5                    |
| PAT_0000309 | cardiac           | 48800                | 5                    |
| PAT_0001971 | cardiac           | 48200                | 6                    |
| PAT_0002100 | ortho             | 47300                | 5                    |
| PAT_0002391 | ortho             | 46800                | 7                    |
| PAT_0001835 | cardiac           | 45650                | 5                    |
| PAT_0001294 | ortho             | 45600                | 6                    |
| PAT_0004506 | cardiac           | 44450                | 5                    |


### Bed-day costs for completed spells

```sql
WITH spell_los AS (
    SELECT
        a.actor_id,
        a.journey_instance_id,
        MIN(a.timestamp) AS admit_ts,
        MIN(d.timestamp) AS discharge_ts,
        EXTRACT(EPOCH FROM (MIN(d.timestamp) - MIN(a.timestamp))) / 86400.0 AS los_days
    FROM fact_admission a
    JOIN fact_discharge d ON a.journey_instance_id = d.journey_instance_id
    GROUP BY a.actor_id, a.journey_instance_id
),
ward_costs AS (
    SELECT
        wa.journey_instance_id,
        AVG(w.cost_per_bed_day) AS avg_bed_cost
    FROM fact_ward_assignment wa
    JOIN dim_ward w ON wa.entity_id = w.id
    GROUP BY wa.journey_instance_id
)
SELECT
    sl.actor_id,
    ROUND(sl.los_days, 1) AS los_days,
    ROUND(wc.avg_bed_cost, 0) AS avg_bed_cost_per_day,
    ROUND(sl.los_days * wc.avg_bed_cost, 0) AS total_bed_cost
FROM spell_los sl
JOIN ward_costs wc ON sl.journey_instance_id = wc.journey_instance_id
ORDER BY total_bed_cost DESC
LIMIT 15;
```

| actor_id    | los_days | avg_bed_cost_per_day | total_bed_cost |
|-------------|----------|----------------------|----------------|
| PAT_0000145 | 11       | 1800                 | 19812          |
| PAT_0004099 | 18.4     | 1040                 | 19087          |
| PAT_0003736 | 9.9      | 1800                 | 17834          |
| PAT_0001917 | 8.2      | 1800                 | 14783          |
| PAT_0000818 | 14       | 1050                 | 14691          |
| PAT_0000080 | 7.9      | 1800                 | 14141          |
| PAT_0000007 | 10.7     | 1293                 | 13799          |
| PAT_0003095 | 11.8     | 1090                 | 12857          |
| PAT_0002728 | 11.4     | 1110                 | 12677          |
| PAT_0005292 | 6.9      | 1800                 | 12486          |
| PAT_0004129 | 6.9      | 1800                 | 12411          |
| PAT_0001083 | 11       | 1125                 | 12389          |
| PAT_0000484 | 6.9      | 1800                 | 12366          |
| PAT_0003324 | 6.4      | 1800                 | 11471          |
| PAT_0004504 | 9.2      | 1243                 | 11369          |


---

## Exercise 16: "Do deprived patients have worse outcomes?"

### ALOS by deprivation

```sql
WITH spells AS (
    SELECT
        a.actor_id,
        a.journey_instance_id,
        MIN(a.timestamp) AS admit_ts,
        MIN(d.timestamp) AS discharge_ts
    FROM fact_admission a
    JOIN fact_discharge d ON a.journey_instance_id = d.journey_instance_id
    GROUP BY a.actor_id, a.journey_instance_id
)
SELECT
    p.imd_decile,
    COUNT(*) AS spells,
    ROUND(AVG(EXTRACT(EPOCH FROM (s.discharge_ts - s.admit_ts)) / 86400.0), 1) AS avg_los
FROM spells s
JOIN dim_patient p ON s.actor_id = p.id AND p.valid_to IS NULL
GROUP BY p.imd_decile
ORDER BY p.imd_decile;
```

| imd_decile | spells | avg_los |
|------------|--------|---------|
| 1          | 94     | 5.6     |
| 2          | 126    | 5.6     |
| 3          | 96     | 5.7     |
| 4          | 128    | 5.4     |
| 5          | 112    | 5.3     |
| 6          | 113    | 5.5     |
| 7          | 98     | 5.4     |
| 8          | 99     | 5.8     |
| 9          | 103    | 5.3     |
| 10         | 104    | 5.5     |


### Referral-to-attendance ratio by deprivation

```sql
WITH referrals AS (
    SELECT r.actor_id, COUNT(DISTINCT r.journey_instance_id) AS ref_count
    FROM fact_referral_created r
    GROUP BY r.actor_id
),
attended AS (
    SELECT a.actor_id, COUNT(DISTINCT a.journey_instance_id) AS att_count
    FROM fact_appointment_attended a
    GROUP BY a.actor_id
)
SELECT
    p.imd_decile,
    SUM(r.ref_count) AS referrals,
    COALESCE(SUM(a.att_count), 0) AS attended,
    ROUND(100.0 * COALESCE(SUM(a.att_count), 0) / SUM(r.ref_count), 1) AS attendance_pct
FROM referrals r
JOIN dim_patient p ON r.actor_id = p.id AND p.valid_to IS NULL
LEFT JOIN attended a ON r.actor_id = a.actor_id
GROUP BY p.imd_decile
ORDER BY p.imd_decile;
```

| imd_decile | referrals | attended | attendance_pct |
|------------|-----------|----------|----------------|
| 1          | 313       | 239      | 76.4           |
| 2          | 338       | 258      | 76.3           |
| 3          | 300       | 228      | 76             |
| 4          | 330       | 262      | 79.4           |
| 5          | 366       | 294      | 80.3           |
| 6          | 327       | 252      | 77.1           |
| 7          | 293       | 227      | 77.5           |
| 8          | 336       | 258      | 76.8           |
| 9          | 334       | 267      | 79.9           |
| 10         | 311       | 242      | 77.8           |


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
           COUNT(DISTINCT journey_instance_id) AS admissions
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
| 2023-01-01 | 84          | 32         | 15         | 3          | 0         |
| 2023-02-01 | 38          | 29         | 10         | 2          | 1         |
| 2023-03-01 | 53          | 50         | 25         | 13         | 78        |
| 2023-04-01 | 41          | 42         | 19         | 4          | 41        |
| 2023-05-01 | 45          | 42         | 25         | 9          | 73        |
| 2023-06-01 | 55          | 40         | 18         | 4          | 53        |
| 2023-07-01 | 35          | 33         | 21         | 3          | 108       |
| 2023-08-01 | 38          | 50         | 30         | 8          | 88        |
| 2023-09-01 | 45          | 43         | 24         | 4          | 113       |
| 2023-10-01 | 53          | 60         | 44         | 3          | 136       |
| 2023-11-01 | 63          | 47         | 22         | 9          | 153       |
| 2023-12-01 | 52          | 44         | 30         | 4          | 122       |
| 2024-01-01 | 50          | 45         | 26         | 9          | 121       |
| 2024-02-01 | 45          | 50         | 32         | 6          | 95        |
| 2024-03-01 | 65          | 48         | 29         | 0          | 79        |
| 2024-04-01 | 65          | 55         | 36         | 14         | 148       |
| 2024-05-01 | 56          | 44         | 21         | 15         | 89        |
| 2024-06-01 | 45          | 42         | 30         | 3          | 84        |
| 2024-07-01 | 76          | 53         | 27         | 4          | 132       |
| 2024-08-01 | 53          | 63         | 28         | 14         | 119       |
| 2024-09-01 | 53          | 37         | 24         | 9          | 141       |
| 2024-10-01 | 56          | 47         | 28         | 5          | 118       |
| 2024-11-01 | 80          | 66         | 33         | 4          | 140       |
| 2024-12-01 | 78          | 66         | 37         | 5          | 189       |
| 2025-01-01 | 95          | 90         | 44         | 14         | 176       |
| 2025-02-01 | 79          | 87         | 58         | 16         | 165       |
| 2025-03-01 | 80          | 52         | 34         | 0          | 128       |
| 2025-04-01 | 52          | 49         | 32         | 18         | 169       |
| 2025-05-01 | 70          | 84         | 46         | 21         | 184       |
| 2025-06-01 | 50          | 48         | 29         | 4          | 162       |
| 2025-07-01 | 69          | 73         | 41         | 4          | 147       |
| 2025-08-01 | 70          | 53         | 30         | 10         | 141       |
| 2025-09-01 | 65          | 55         | 32         | 7          | 110       |
| 2025-10-01 | 65          | 49         | 32         | 8          | 127       |
| 2025-11-01 | 56          | 56         | 33         | 13         | 140       |
| 2025-12-01 | 51          | 57         | 28         | 0          | 139       |


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
| 2025-01-13 | 9        |
| 2025-01-31 | 9        |
| 2025-02-21 | 8        |
| 2025-02-20 | 8        |
| 2024-11-08 | 8        |
| 2024-12-20 | 7        |
| 2025-02-06 | 7        |
| 2025-01-10 | 7        |
| 2025-03-05 | 7        |


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
| 2023 | summer | 312      | 45             |
| 2023 | winter | 290      | 58             |
| 2024 | summer | 404      | 58             |
| 2024 | winter | 318      | 64             |
| 2025 | summer | 441      | 63             |
| 2025 | winter | 361      | 72             |


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
| 3                    | 150       | 15.6 |
| 4                    | 339       | 35.3 |
| 5                    | 320       | 33.3 |
| 6                    | 151       | 15.7 |


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
| 960             | 151            | 150                |


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
JOIN dim_theatre t ON sp.entity_id = t.id
GROUP BY t.theatre_name, t.specialty
ORDER BY surgeries DESC;
```

| theatre_name        | specialty                    | surgeries | per_day |
|---------------------|------------------------------|-----------|---------|
| Cardiac Theatre     | Cardiology / Cardiac Surgery | 859       | 0.8     |
| Obstetric Theatre   | Obstetrics                   | 853       | 0.8     |
| Main Theatre 1      | General Surgery              | 840       | 0.8     |
| Main Theatre 2      | Trauma & Orthopaedics        | 833       | 0.8     |
| Day Surgery Theatre | General / Mixed              | 824       | 0.8     |


### Revenue by procedure complexity

```sql
WITH surgery_procedures AS (
    SELECT
        sp.journey_instance_id,
        proc.procedure_name,
        proc.complexity,
        proc.tariff,
        proc.specialty_group
    FROM fact_surgery_performed sp
    JOIN fact_pre_op_assessment po
        ON sp.journey_instance_id = po.journey_instance_id
    JOIN dim_procedure proc ON po.entity_id = proc.id
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
| complex    | 1323      | 11058      | 14629300      |
| major      | 1870      | 6546       | 12240100      |
| moderate   | 1846      | 1946       | 3592300       |
| minor      | 1357      | 677        | 918950        |


---

## Exercise 20: "Are we keeping patients, or just cycling through them?"

### Inpatient spells per patient

```sql
SELECT
    spells_per_patient,
    COUNT(*) AS patients
FROM (
    SELECT actor_id, COUNT(DISTINCT journey_instance_id) AS spells_per_patient
    FROM fact_admission
    GROUP BY actor_id
)
GROUP BY spells_per_patient
ORDER BY spells_per_patient;
```

| spells_per_patient | patients |
|--------------------|----------|
| 1                  | 1270     |
| 2                  | 217      |
| 3                  | 36       |
| 4                  | 8        |


### Most complex patients (multi-pathway)

```sql
WITH patient_journeys AS (
    SELECT actor_id, 'ed' AS pathway, journey_instance_id FROM fact_ed_arrival
    UNION ALL
    SELECT actor_id, 'inpatient', journey_instance_id FROM fact_admission
    UNION ALL
    SELECT actor_id, 'outpatient', journey_instance_id FROM fact_referral_created
    UNION ALL
    SELECT actor_id, 'surgical', journey_instance_id FROM fact_pre_op_assessment
    UNION ALL
    SELECT actor_id, 'cancer', journey_instance_id FROM fact_cancer_referral
)
SELECT
    actor_id,
    COUNT(DISTINCT journey_instance_id) AS total_journeys,
    COUNT(DISTINCT pathway) AS pathway_types
FROM patient_journeys
GROUP BY actor_id
ORDER BY total_journeys DESC
LIMIT 15;
```

| actor_id    | total_journeys | pathway_types |
|-------------|----------------|---------------|
| PAT_0001173 | 8              | 3             |
| PAT_0000078 | 8              | 3             |
| PAT_0001316 | 8              | 3             |
| PAT_0002283 | 8              | 3             |
| PAT_0000151 | 7              | 3             |
| PAT_0000299 | 7              | 3             |
| PAT_0000064 | 7              | 3             |
| PAT_0000659 | 7              | 3             |
| PAT_0000645 | 7              | 3             |
| PAT_0003740 | 7              | 3             |
| PAT_0002726 | 7              | 3             |
| PAT_0001762 | 7              | 3             |
| PAT_0002622 | 7              | 3             |
| PAT_0002626 | 7              | 3             |
| PAT_0000088 | 7              | 3             |


### Condition profile of high-frequency patients

```sql
WITH patient_spells AS (
    SELECT actor_id, COUNT(DISTINCT journey_instance_id) AS spell_count
    FROM fact_admission
    GROUP BY actor_id
    HAVING COUNT(DISTINCT journey_instance_id) >= 3
)
SELECT
    p.primary_condition,
    p.comorbidity_count,
    AVG(ps.spell_count) AS avg_spells,
    COUNT(*) AS patients
FROM patient_spells ps
JOIN dim_patient p ON ps.actor_id = p.id AND p.valid_to IS NULL
GROUP BY p.primary_condition, p.comorbidity_count
ORDER BY avg_spells DESC;
```

| primary_condition | comorbidity_count | avg_spells | patients |
|-------------------|-------------------|------------|----------|
| respiratory       | 0                 | 4          | 1        |
| obstetric         | 7                 | 4          | 1        |
| cardiac           | 4                 | 3.5        | 2        |
| obstetric         | 3                 | 3.5        | 2        |
| infectious        | 2                 | 3.5        | 2        |
| ortho             | 1                 | 3.3333     | 3        |
| cardiac           | 2                 | 3.25       | 4        |
| cardiac           | 3                 | 3.25       | 4        |
| neuro             | 2                 | 3          | 1        |
| obstetric         | 4                 | 3          | 1        |
| ortho             | 3                 | 3          | 2        |
| infectious        | 0                 | 3          | 2        |
| cardiac           | 1                 | 3          | 3        |
| neuro             | 1                 | 3          | 1        |
| GI                | 2                 | 3          | 1        |
| respiratory       | 2                 | 3          | 1        |
| respiratory       | 1                 | 3          | 2        |
| infectious        | 3                 | 3          | 3        |
| GI                | 4                 | 3          | 2        |
| respiratory       | 3                 | 3          | 2        |
| infectious        | 1                 | 3          | 1        |
| GI                | 0                 | 3          | 2        |
| respiratory       | 4                 | 3          | 1        |


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
    ON arr.journey_instance_id = ea.journey_instance_id
GROUP BY quarter
ORDER BY quarter;
```

| quarter    | assessed | pct_within_4h |
|------------|----------|---------------|
| 2023-01-01 | 169      | 82.8          |
| 2023-04-01 | 135      | 85.2          |
| 2023-07-01 | 108      | 83.3          |
| 2023-10-01 | 159      | 78            |
| 2024-01-01 | 153      | 82.4          |
| 2024-04-01 | 156      | 85.3          |
| 2024-07-01 | 172      | 82.6          |
| 2024-10-01 | 205      | 83.9          |
| 2025-01-01 | 241      | 86.7          |
| 2025-04-01 | 167      | 86.8          |
| 2025-07-01 | 194      | 90.2          |
| 2025-10-01 | 163      | 81            |


### Cancer 28-day FDS by quarter

```sql
WITH cancer_times AS (
    SELECT
        cr.journey_instance_id,
        MIN(cr.timestamp) AS referral_ts,
        MIN(fs.timestamp) AS first_seen_ts
    FROM fact_cancer_referral cr
    JOIN fact_cancer_first_seen fs
        ON cr.journey_instance_id = fs.journey_instance_id
    GROUP BY cr.journey_instance_id
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
| 2023-01-01 | 63       | 69.8    |
| 2023-04-01 | 39       | 66.7    |
| 2023-07-01 | 54       | 79.6    |
| 2023-10-01 | 38       | 89.5    |
| 2024-01-01 | 52       | 73.1    |
| 2024-04-01 | 41       | 68.3    |
| 2024-07-01 | 46       | 80.4    |
| 2024-10-01 | 73       | 75.3    |
| 2025-01-01 | 69       | 66.7    |
| 2025-04-01 | 56       | 66.1    |
| 2025-07-01 | 49       | 71.4    |
| 2025-10-01 | 32       | 78.1    |


### Diagnostic 6-week compliance by quarter

```sql
WITH diag_times AS (
    SELECT
        do2.journey_instance_id,
        MIN(do2.timestamp) AS ordered_ts,
        MIN(dp.timestamp) AS performed_ts
    FROM fact_diagnostic_ordered do2
    JOIN fact_diagnostic_performed dp
        ON do2.journey_instance_id = dp.journey_instance_id
    GROUP BY do2.journey_instance_id
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
| 2023-01-01 | 40              | 82.5           |
| 2023-04-01 | 80              | 81.3           |
| 2023-07-01 | 100             | 86             |
| 2023-10-01 | 99              | 82.8           |
| 2024-01-01 | 110             | 81.8           |
| 2024-04-01 | 106             | 85.8           |
| 2024-07-01 | 102             | 82.4           |
| 2024-10-01 | 143             | 79.7           |
| 2025-01-01 | 138             | 87             |
| 2025-04-01 | 145             | 80.7           |
| 2025-07-01 | 119             | 82.4           |
| 2025-10-01 | 67              | 80.6           |


---

## Exercise 22: "Do our patients come back?"

### Build the 2023 cohort and track across years

```sql
WITH all_activity AS (
    SELECT actor_id, timestamp FROM fact_ed_arrival
    UNION ALL
    SELECT actor_id, timestamp FROM fact_admission
    UNION ALL
    SELECT actor_id, timestamp FROM fact_referral_created
    UNION ALL
    SELECT actor_id, timestamp FROM fact_pre_op_assessment
    UNION ALL
    SELECT actor_id, timestamp FROM fact_cancer_referral
    UNION ALL
    SELECT actor_id, timestamp FROM fact_appointment_attended
),
first_activity AS (
    SELECT actor_id, MIN(timestamp) AS first_ts
    FROM all_activity
    GROUP BY actor_id
),
cohort_2023 AS (
    SELECT actor_id
    FROM first_activity
    WHERE EXTRACT(YEAR FROM first_ts) = 2023
)
SELECT
    EXTRACT(YEAR FROM a.timestamp)::INTEGER AS activity_year,
    COUNT(DISTINCT a.actor_id) AS patients_active
FROM all_activity a
JOIN cohort_2023 c ON a.actor_id = c.actor_id
GROUP BY activity_year
ORDER BY activity_year;
```

| activity_year | patients_active |
|---------------|-----------------|
| 2023          | 1691            |
| 2024          | 493             |
| 2025          | 187             |


---
