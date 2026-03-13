# QA Review — Exercises & Data


## Data Should Change

### Ex 6: ALOS by condition too uniform

**Question:** "How long are patients staying?"

**Problem:** All conditions cluster at 5.7-6.0 days mean LOS. In reality, obstetric stays average 1-2 days (normal delivery), ortho joint replacements 3-4 days, while respiratory/neuro/cardiac can be 5-10+ days. The uniformity removes the analytical payoff of the by-condition breakdown.

**Query used:**
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

**Current results:**

| primary_condition | spells | mean_los |
|-------------------|--------|----------|
| neuro             | 711    | 6        |
| obstetric         | 428    | 6        |
| GI                | 820    | 5.9      |
| cardiac           | 1124   | 5.9      |
| infectious        | 551    | 5.9      |
| respiratory       | 982    | 5.9      |
| ortho             | 787    | 5.7      |

**Expected:** Obstetric ~2 days, ortho ~3-4 days, respiratory/neuro ~6-8 days. A clear spread that rewards the by-condition analysis.

---

### Ex 8: FFT scores have no data quality issue to find

**Question:** "Are patients satisfied with their care?"

**Problem:** The discussion sets up a data quality teaching moment ("scores above 5 shouldn't exist") but the data is clean. Either inject bad data or rewrite the discussion (listed in both sections — pick one approach).

**Query used:**
```sql
SELECT
    recommendation_score,
    COUNT(*) AS responses,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM fact_fft_response
GROUP BY recommendation_score
ORDER BY recommendation_score;
```

**Current results:**

| recommendation_score | responses | pct  |
|----------------------|-----------|------|
| 1                    | 4         | 0.1  |
| 2                    | 54        | 1.2  |
| 3                    | 642       | 14   |
| 4                    | 2017      | 43.9 |
| 5                    | 1880      | 40.9 |

**Expected:** A handful of score-6 records (e.g. 15-20) so learners can discover the anomaly.

---

### Ex 9: SHOs and registrars appear as admitting clinicians

**Question:** "Which consultants carry the heaviest load?"

**Problem:** `consultant_id` in fact_admission references SHOs and registrars. In real NHS practice, patients are admitted under a named consultant (consultant-grade doctor only). SHOs and registrars work under supervision. Having CON_004 (SHO) with 339 admissions is clinically misleading.

**Query used:**
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

**Current results (excerpt):**

| id      | specialty_group | grade | admissions |
|---------|-----------------|-------|------------|
| CON_004 | cardiac         | SHO   | 339        |
| CON_011 | respiratory     | SHO   | 288        |
| CON_025 | general         | SHO   | 247        |
| CON_019 | gastrointestinal| SHO   | 166        |

**Expected:** Only consultant-grade doctors should appear in fact_admission.consultant_id. SHOs and registrars should appear in tables like fact_surgeon_assigned where they work under supervision.

---

### Ex 11: Cancer FDS compliance unrealistically high

**Question:** "Are cancer patients being seen fast enough?"

**Problem:** 97.1% compliance vs 75% national target. Real NHS trusts struggle to hit 75%. At 97%, there's no problem to investigate and the exercise loses its edge.

**Query used:**
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

**Current results:**

| pathways_seen | avg_days | within_28d | pct_fds |
|---------------|----------|------------|---------|
| 726           | 10       | 705        | 97.1    |

**Expected:** ~75-80% compliance with some quarterly variation, so learners see a trust near the target threshold and can investigate which quarters breach.

---

### Ex 13: ED ALOS identical to overall ALOS

**Question:** "What happens to A&E patients after they're admitted?"

**Problem:** ED-origin ALOS = 5.9 days, overall ALOS = 5.9 days. No difference. The exercise asks learners to compare emergency vs elective admissions, but the data gives them nothing to find. In real NHS data, emergency admissions are typically longer.

**Query used:**
```sql
WITH ed_patients AS (
    SELECT patient_id, attendance_id AS ed_instance, timestamp AS ed_arrival_ts
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

**Current results:**

| ed_admitted_spells | ed_alos | overall_alos |
|--------------------|---------|--------------|
| 1132               | 5.9     | 5.9          |

**Expected:** ED ALOS ~6.5-7 days vs overall ~5.5 days, reflecting the higher acuity and complexity of emergency admissions.

---

### Ex 14: Readmission rate too low

**Question:** "Are we readmitting too many patients?"

**Problem:** 6.3% vs 12-14% NHS benchmark. Too low to prompt investigation. The answer is simply "no."

**Query used:**
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

**Current results:**

| readmissions | total_completed_spells | readmission_pct |
|--------------|------------------------|-----------------|
| 342          | 5403                   | 6.3             |

**Expected:** ~12-15% overall, with variation by condition (respiratory/cardiac higher, ortho lower).

---

### Ex 20: Performance metrics too stable

**Question:** "Are we getting better or worse?"

**Problem:** A&E 4h ranges 82.9-85.8%, cancer FDS 92.5-100%, diagnostics 93.5-100%. All stable or slightly improving despite doubling volume. There's no compelling "getting worse" story for learners to find. At least one metric should show degradation under volume pressure.

**Query used (A&E example):**
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

**Current results (A&E):**

| quarter    | assessed | pct_within_4h |
|------------|----------|---------------|
| 2023-01-01 | 532      | 82.9          |
| 2023-04-01 | 486      | 85.4          |
| ...        | ...      | ...           |
| 2025-10-01 | 1264     | 85.8          |

**Expected:** A&E 4h should degrade in winter quarters (e.g. dipping below 78% in Q1 2025). Diagnostics could show MRI/CT wait times breaching 42 days in later quarters as demand grows. This gives the board question real stakes.
