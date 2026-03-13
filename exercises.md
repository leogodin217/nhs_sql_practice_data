# NHS Practice Exercises

**Dataset:** Millbrook NHS Trust (simulated)
**Format:** DuckDB

## Getting Started

Build the database from the CSV files in `data/`, or download a pre-built `nhsdb.duckdb` from the [latest release](../../releases/latest):

```bash
duckdb nhsdb.duckdb < build_db.sql
```

Before diving into the exercises, spend a few minutes exploring what's in it.

Some useful commands to get oriented:

```sql
-- What tables exist?
SHOW TABLES;

-- What columns does a table have?
DESCRIBE nhsdb.main.dim_patient;

-- What does the data look like?
SELECT * FROM nhsdb.main.dim_patient LIMIT 10;
```

## About These Exercises

These exercises are framed as real operational questions -- deliberately vague, the way a Medical Director or Finance lead would actually ask them. Your job is to figure out what data answers the question, then write SQL to get it.

There is no single right answer for most of these. A query that answers the question in a reasonable way is a good query.

Each exercise includes collapsible **Hints**, **Solution**, and **Discussion** sections. Try to solve the exercise on your own before peeking. Solutions provided are one way to answer the question. You might find better solutions.

Pro Tip: You may want to dump some of your query results into Excel or Sheets then create a chart. Patterns are much easier to see visually.

Another Pro Tip: Feel free to let an LLM help you when you get stuck. There's nothing wrong with getting help wherever it exists. Just start with a prompt like "I am learning SQL and want a mentor who will teach me how to understand the needed query instead of simply providing an answer."

DuckDB: You may have never seen casting like `timestamp::date`. Some DBMS support this and some don't. Don't worry, it's just short for `cast(timestamp as date)`. Probably my favorite convenience that has become more popular in recent years.

---

## Warming Up

### Exercise 1: "How many patients does the trust serve?"

The Medical Director is prepping for a board meeting and needs a headcount.

<details>
<summary>Hints</summary>

- Where does patient data live?
- Could there be duplicate entries for the same patient?
- What is a "patient" in this context?

</details>

<details>
<summary>Solution</summary>

`dim_patient` uses Type-2 SCD -- when a patient's tracked properties change (status, admission_count, total_spell_tariff), a new row is created. A naive `COUNT(*)` returns all historical rows instead of the real patient count.

**Using DISTINCT:**

```sql
SELECT COUNT(DISTINCT id) AS patient_count
FROM dim_patient;
```

**Only current patients:**

```sql
SELECT COUNT(*) AS current_patients
FROM dim_patient
WHERE valid_to IS NULL;
```

</details>

<details>
<summary>Discussion</summary>

Both approaches give the same answer. The first deduplicates across all historical rows. The second counts only the latest version of each patient. If the Medical Director wants "how many patients do we have right now," the second is more appropriate.

The key question to ask yourself: "The table has significantly more rows than distinct patients. Why?" This leads naturally into SCD-2 concepts. The inflation comes from tracked properties that change over time -- each change creates a new row with updated `valid_from`/`valid_to` timestamps.

Side note: Stuff like this happens all the time. You'll often see inflated counts when someone does a naive `COUNT(*)` on a dimension table with history. Always check for SCD-2 patterns.

</details>

---

### Exercise 2: "What does this hospital look like?"

A new analyst just joined the team. Help them get oriented -- what resources does the trust have?

<details>
<summary>Hints</summary>

- What dimension tables describe hospital resources?
- How many wards, consultants, theatres, specialties are there?
- Is every dimension table actually used by the fact tables?

</details>

<details>
<summary>Solution</summary>

**Ward summary:**

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

**Consultant summary:**

```sql
SELECT
    specialty_group,
    grade,
    COUNT(*) AS consultants
FROM dim_consultant
GROUP BY specialty_group, grade
ORDER BY specialty_group, grade;
```

**Theatre summary:**

```sql
SELECT
    theatre_name,
    specialty,
    sessions_per_day
FROM dim_theatre;
```

**Quick inventory -- which dimension tables exist?**

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'main' AND table_name LIKE 'dim_%'
ORDER BY table_name;
```

</details>

<details>
<summary>Discussion</summary>

The trust has 10 wards (75 beds total), 25 consultants across 5 specialty groups (with respiratory the largest at 7 and musculoskeletal the smallest at 3 -- not every group has all three grades), 5 operating theatres, 12 diagnostic test types, 35 surgical procedures, and 30 medications.

Notice how each dimension table maps to a specific foreign key in the fact tables -- `consultant_id` references `dim_consultant`, `ward_id` references `dim_ward`, and so on. Understanding which dimension connects to which facts is the first step to writing useful queries.

</details>

---

### Exercise 3: "What happened on A&E's busiest day?"

The ops team wants a recap of the single busiest day in A&E -- how many arrivals and what triage categories.

<details>
<summary>Hints</summary>

- How do you find the busiest day if you don't know which day it is?
- Can you do this in one query, or do you need to find the day first?
- What does "busiest" mean -- most arrivals?

</details>

<details>
<summary>Solution</summary>

**Find the busiest day and break down by triage category:**

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

</details>

<details>
<summary>Discussion</summary>

Check which day comes out on top -- is it a date that makes clinical sense? A&E spikes often align with bank holidays, major events, or seasonal surges. The triage breakdown shows the distribution across categories 1 (immediate) through 5 (non-urgent).

Try running the top-10 busiest days to see the pattern. Do they cluster in certain seasons or around specific events?

</details>

---

### Exercise 4: "What does our patient population look like?"

The Population Health team wants a demographic profile of the trust's patients.

<details>
<summary>Hints</summary>

- What demographic fields does `dim_patient` have?
- Should you use all rows or just current patients?
- What's IMD and why might it matter?

</details>

<details>
<summary>Solution</summary>

**Pathway split:**

```sql
SELECT
    pathway_type,
    COUNT(*) AS patients
FROM dim_patient
WHERE valid_to IS NULL
GROUP BY pathway_type
ORDER BY patients DESC;
```

**Primary condition breakdown:**

```sql
SELECT
    primary_condition,
    COUNT(*) AS patients
FROM dim_patient
WHERE valid_to IS NULL
GROUP BY primary_condition
ORDER BY patients DESC;
```

**IMD decile distribution:**

```sql
SELECT
    imd_decile,
    COUNT(*) AS patients
FROM dim_patient
WHERE valid_to IS NULL
GROUP BY imd_decile
ORDER BY imd_decile;
```

</details>

<details>
<summary>Discussion</summary>

You should see roughly 55% elective, 35% emergency, and 10% cancer pathway patients. Cardiac is the most common primary condition, followed by respiratory and orthopaedic.

IMD (Index of Multiple Deprivation) deciles range from 1 (most deprived) to 10 (least deprived). The distribution here skews toward more deprived deciles, with roughly 5x more patients in decile 1 than decile 10. This kind of skew is common in urban acute trusts serving deprived catchment areas -- a London teaching hospital would look very different from a rural district general.

Keep the IMD data in mind -- we'll come back to it when looking at health inequalities later.

</details>

---

## Digging In

### Exercise 5: "Are we hitting the 4-hour A&E target?"

The Chief Operating Officer needs to know: what percentage of A&E patients are seen within 4 hours? The NHS target is 78% by March 2026.

<details>
<summary>Hints</summary>

- What fact tables capture the A&E pathway? What's the first event? The last?
- How do you connect an arrival to an assessment for the same patient visit?
- What column links events from the same A&E attendance?
- Not all arrivals have an assessment. What happened to those patients?
- The dataset spans multiple years. Does the COO want the all-time rate or a recent period?

</details>

<details>
<summary>Solution</summary>

**Join arrival to assessment on attendance_id:**

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

</details>

<details>
<summary>Discussion</summary>

Check the percentage against the 78% target. Is the trust hitting it?

Now compare row counts between the arrival and assessment tables. There's a gap -- patients who left before being seen. Should they count as a breach? In real NHS reporting, they do. The percentage above is optimistic because it only measures patients who actually got assessed.

A more complete calculation would include the denominator of all arrivals, treating "left before seen" as breaches. Try modifying the query to use a LEFT JOIN and see how the number changes.

Try filtering to the most recent 12 months and compare. A COO probably wants the latest quarter or year, not an all-time figure. Also worth exploring: break this down by month. Does winter performance differ from summer?

</details>

---

### Exercise 6: "How long are patients staying?"

The bed management team wants to know the average length of stay for inpatients. NHS benchmark is 4-5 days.

<details>
<summary>Hints</summary>

- Which fact tables mark the start and end of an inpatient spell?
- How do you link an admission to its discharge?
- Can you compute LOS in days from two timestamps?
- Will every admission have a discharge?

</details>

<details>
<summary>Solution</summary>

**ALOS for completed spells:**

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

**ALOS by primary condition:**

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

</details>

<details>
<summary>Discussion</summary>

Check against the NHS benchmark of 4-5 days. The `MIN()` aggregation is important here: some spells have multiple admission records (when a patient is transferred between consultant episodes within the same spell), so we need the earliest admission timestamp.

Compare completed spells to total admission `spell_id` values -- you'll see a significant gap. The difference represents "open" spells still in progress when the dataset ends. This is normal for a point-in-time snapshot -- you can only measure ALOS on completed spells.

Try segmenting by primary condition. Is there a meaningful difference between cardiac and orthopaedic patients? What about by comorbidity count?

</details>

---

### Exercise 7: "How many referrals actually turn into appointments?"

The outpatient services manager is worried about the gap between referrals and attended appointments.

<details>
<summary>Hints</summary>

- What fact tables track the outpatient pathway?
- `pathway_id` links events from the same pathway. How many distinct pathways appear in each table?
- What could explain the gap between referral count and attendance count?
- Recent referrals haven't had time to convert. How might this skew the funnel?

</details>

<details>
<summary>Solution</summary>

**Outpatient funnel:**

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

**Referral volume by month:**

```sql
SELECT
    DATE_TRUNC('month', timestamp)::DATE AS month,
    COUNT(DISTINCT pathway_id) AS referrals
FROM fact_referral_created
GROUP BY month
ORDER BY month;
```

</details>

<details>
<summary>Discussion</summary>

You should see a significant gap between referral pathways and attended pathways. But this doesn't mean all those patients DNA'd. The gap includes:

- Patients still waiting for their appointment (not yet attended)
- Cancelled appointments (by patient or hospital)
- Did Not Attend (DNA)
- Pathways that ended before an appointment was scheduled

The fact tables only capture events that happened. If a patient was referred but never attended, there's no row in `fact_appointment_attended` for that pathway. This is a common pattern in healthcare analytics: absence of data is itself informative.

Referrals from the most recent months inflate the dropout rate (right-censoring) -- those patients simply haven't had time to attend yet. Try limiting to earlier years and see if the conversion rate improves.

Note: `fact_appointment_attended` only records attended appointments. DNA and cancellation events aren't captured as fact table records in this dataset.

</details>

---

### Exercise 8: "Are patients satisfied with their care?"

The Patient Experience team needs the latest Friends and Family Test results for the board report.

<details>
<summary>Hints</summary>

- Which table captures FFT responses?
- What does `recommendation_score` represent?
- What range of scores exists in the data?
- NHS defines "positive" as score >= 4 (on a 1-5 scale). Do these scores look normal?
- The board report probably wants recent results. What time period makes sense?

</details>

<details>
<summary>Solution</summary>

**FFT overview:**

```sql
SELECT
    recommendation_score,
    COUNT(*) AS responses,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM fact_fft_response
GROUP BY recommendation_score
ORDER BY recommendation_score;
```

**FFT recommend rate:**

```sql
SELECT
    COUNT(*) AS total_responses,
    SUM(CASE WHEN recommendation_score >= 4 THEN 1 ELSE 0 END) AS positive,
    ROUND(100.0 * SUM(CASE WHEN recommendation_score >= 4 THEN 1 ELSE 0 END)
        / COUNT(*), 1) AS recommend_pct
FROM fact_fft_response;
```

</details>

<details>
<summary>Discussion</summary>

Check whether the score distribution looks reasonable. NHS FFT uses a 1-5 scale, so scores should fall within that range. Always verify the boundaries of survey data -- in real life, data entry errors, different survey versions, or system migrations can introduce out-of-range values. Running a quick distribution check is the first thing to do with any survey dataset.

The national average positive rate (scores 4-5) is typically around 85-90%. How does this trust compare? Try filtering to the most recent quarter -- does the distribution look different? The board probably cares most about the latest period.

</details>

---

## Putting Knowledge to Use

### Exercise 9: "Which consultants carry the heaviest load?"

The Clinical Director wants to understand workload distribution across the medical staff.

<details>
<summary>Hints</summary>

- Multiple fact tables reference consultants via `consultant_id`.
- Which events are the most meaningful for measuring workload -- admissions? surgeries? all events?
- Join to `dim_consultant` to get specialty and grade.
- Is total workload or recent workload more relevant for staffing?

</details>

<details>
<summary>Solution</summary>

**Admissions by consultant:**

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

**Workload by specialty group:**

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

</details>

<details>
<summary>Discussion</summary>

Respiratory consultants handle the most admissions, followed by general and cardiac. Try joining admissions to patient condition and consultant specialty to see how conditions align with specialty groups.

Notice the clinical coherence: cardiac patients are always seen by cardiac consultants, respiratory patients by respiratory consultants, and so on. This is a designed feature of the dataset -- try verifying it by joining admissions to patient condition and consultant specialty.

You could extend this by looking at surgeon workload (`fact_surgeon_assigned`), or by computing events-per-consultant to find if any individual is overloaded relative to peers.

Try grouping by year to see if workload patterns are shifting. A staffing decision based on three-year totals might miss a recent trend.

</details>

---

### Exercise 10: "What procedures generate the most income?"

Finance wants a breakdown of surgical procedure tariffs by complexity.

<details>
<summary>Hints</summary>

- `dim_procedure` has tariff and complexity columns.
- `fact_pre_op_assessment` links to procedures via `procedure_id`.
- HRG (Healthcare Resource Group) codes determine NHS payment. How do tariffs vary by complexity?

</details>

<details>
<summary>Solution</summary>

**Procedure tariffs by complexity:**

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

**Most expensive procedures actually performed:**

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

</details>

<details>
<summary>Discussion</summary>

There's a clear tariff gradient: complex procedures average ~£10,900, major ~£6,100, moderate ~£2,000, and minor ~£700. The 7 complex procedures (things like CABG, craniotomy, complex spinal fusion) generate the most income per case.

Try calculating total tariff income per specialty group by multiplying tariff by the number of times each procedure was performed. Which specialty generates the most income?

</details>

---

### Exercise 11: "Are cancer patients being seen fast enough?"

The Cancer Services lead needs to report on the 28-day Faster Diagnosis Standard. NHS target: 75% of urgently-referred cancer patients seen within 28 days.

<details>
<summary>Hints</summary>

- What tables capture the cancer pathway?
- `cancer_pathway_id` links a referral to its first-seen appointment.
- Cancer pathways can have multiple referral events per pathway. How should you handle that?
- Compute the gap in days between first referral and first appointment.
- NHS reports cancer performance quarterly. What time period should you use?

</details>

<details>
<summary>Solution</summary>

**Cancer 28-day FDS:**

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

</details>

<details>
<summary>Discussion</summary>

Compare your FDS percentage to the 75% national target. Is the trust hitting it?

The `MIN()` aggregation is crucial here. Always aggregate to the pathway level first when measuring elapsed time between events. Without it, duplicate rows per pathway would inflate your result set and skew the averages.

Try breaking down by quarter across all years to see the trend. Also try joining to `dim_patient` to check whether certain conditions or demographics correlate with longer waits.

</details>

---

### Exercise 12: "How are the diagnostics team performing?"

The Diagnostics lead wants to know: are we hitting the 6-week diagnostic wait target? NHS standard is 99% within 42 days.

<details>
<summary>Hints</summary>

- `fact_diagnostic_ordered` and `fact_diagnostic_performed` capture the two key events.
- Same `request_id` links an order to its completion.
- Not all ordered tests get performed. What percentage complete?
- Join to `dim_diagnostic` to break down by test type.
- NHS reports diagnostics monthly. Should you measure the entire dataset or a recent window?

</details>

<details>
<summary>Solution</summary>

**Diagnostic 6-week compliance:**

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

**By test type:**

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

</details>

<details>
<summary>Discussion</summary>

Compare compliance to the 99% standard. Is there a significant gap?

Many ordered tests never get performed -- they're still pending or were cancelled. The completion rate and the wait time are both worth flagging in a performance report.

Try the monthly breakdown to spot trends. Also break down by test type to identify which diagnostics are the bottleneck. Are MRI scans slower than blood tests? That's usually the case in real NHS trusts.

</details>

---

## This Is Getting Harder

### Exercise 13: "What happens to A&E patients after they're admitted?"

The Emergency Medicine consultant wants to understand: when an A&E patient gets admitted, how long is their inpatient stay? Are ED admissions different from elective admissions?

<details>
<summary>Hints</summary>

- There's no foreign key linking ED attendance to inpatient spells. How do real analysts link these?
- Same patient (`patient_id`), close in time. An ED attendance followed by an admission within hours.
- Compare ALOS for ED-origin admissions vs all admissions.

</details>

<details>
<summary>Solution</summary>

**Link ED arrivals to inpatient spells via temporal proximity:**

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

</details>

<details>
<summary>Discussion</summary>

This is a fuzzy temporal join -- the same technique used with real NHS data. There are no explicit foreign keys between ED attendance and inpatient spells. You link them by finding the same patient with an admission timestamp close to their ED arrival.

The 24-hour window is a reasonable heuristic. In real NHS data linkage, analysts often use shorter windows (4-8 hours) but the principle is the same. This kind of cross-process joining is one of the most important skills in healthcare analytics.

Compare the ALOS of ED-origin admissions to the overall figure. Are emergency admissions longer or shorter?

</details>

---

### Exercise 14: "Are we readmitting too many patients?"

The Quality Improvement team wants to know the 30-day readmission rate. NHS benchmark is 12-14% for emergency admissions.

<details>
<summary>Hints</summary>

- A readmission is a new admission for the same patient within 30 days of a prior discharge.
- You need completed spells (admission + discharge) to measure this.
- Link sequential spells for the same `patient_id` and check the time gap.
- Readmission rates can vary over time. Is the latest year more operationally relevant?

</details>

<details>
<summary>Solution</summary>

**30-day readmission rate:**

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

</details>

<details>
<summary>Discussion</summary>

Compare to the NHS benchmark of 12-14%. Is the trust within range?

This query self-joins the spells CTE to find patients where a second admission occurs within 30 days of a prior discharge. The `DISTINCT` on `s2.spell_id` is important because a single readmission spell could match multiple prior discharges.

Compare by year. Also consider right-censoring near the end of the dataset -- patients discharged in the final month haven't had a full 30-day window to be readmitted, which artificially lowers the rate.

Try extending this by joining to `dim_patient` to see whether patients with higher comorbidity counts or frailty scores are more likely to be readmitted. That's the clinical insight the Quality Improvement team really wants.

</details>

---

### Exercise 15: "Which patients cost the most?"

Finance wants to understand the highest-cost patient episodes. Consider procedure tariffs and bed-day costs.

<details>
<summary>Hints</summary>

- `dim_procedure.tariff` gives procedure costs. Link via `fact_pre_op_assessment.procedure_id`.
- `dim_ward.cost_per_bed_day` gives bed costs. Link via `fact_ward_assignment.ward_id`.
- LOS gives you the number of bed-days for completed spells.
- Can you combine these for a total cost per patient?

</details>

<details>
<summary>Solution</summary>

**Procedure costs per patient:**

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

**Bed-day costs for completed spells:**

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

</details>

<details>
<summary>Discussion</summary>

The highest-cost patients tend to be those with multiple procedures combined with long inpatient stays on high-cost wards (ICU at £1,800/day vs general at £350/day). Check which conditions appear most often in the top-cost patients -- it may not be what you expect.

This is a simplified cost model -- real NHS costing includes drug costs, diagnostic costs, staffing ratios, and overhead allocation. But it illustrates the principle: a small number of patients drive a disproportionate share of costs. This is the 80/20 rule in healthcare economics.

Try combining both procedure costs and bed-day costs for the same patient to get a total episode cost.

</details>

---

### Exercise 16: "Do deprived patients have worse outcomes?"

The Health Inequalities lead wants to know: is there a relationship between deprivation (IMD decile) and clinical outcomes like length of stay or readmission?

<details>
<summary>Hints</summary>

- Join your ALOS query to `dim_patient` and group by `imd_decile`.
- Do the same for readmission rate.
- IMD decile 1 = most deprived, 10 = least deprived.
- Remember the outpatient funnel from Exercise 7 -- does deprivation affect referral-to-attendance rates?

</details>

<details>
<summary>Solution</summary>

**ALOS by deprivation:**

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

**Referral-to-attendance ratio by deprivation:**

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

</details>

<details>
<summary>Discussion</summary>

ALOS shows a clear deprivation gradient -- patients from the most deprived areas (deciles 1-3) stay nearly twice as long as those from the least deprived (deciles 8-10). This is a significant finding and the kind of signal an inequalities dashboard should surface. In real NHS data, this pattern is well-documented and driven by comorbidities, social care delays, and housing issues affecting discharge.

The referral-to-attendance ratio is also worth exploring by deprivation. In real NHS data, deprived populations typically have higher DNA rates, though the pattern here may be less pronounced.

Health inequality analysis is a growing priority in NHS analytics. The tools you've used here -- joining clinical data to demographic data and stratifying by deprivation -- are exactly what real inequality dashboards do.

</details>

---

## The Capstone

### Exercise 17: "The Medical Director says this winter was the worst yet. Was it?"

The dataset spans multiple years. The Medical Director claims this most recent winter was the worst. Build a multi-metric seasonal analysis that compares winters across years.

<details>
<summary>Hints</summary>

- Monthly aggregation is your friend. Break key metrics down by month.
- What does "winter pressure" actually mean in NHS terms? More ED arrivals, more admissions, longer stays, more discharges, more ICU escalations?
- The patient population grows over the dataset's time span. How do you separate genuine seasonality from population growth?
- Compare the same winter months across different years. Label months with both month and year.
- Look for any sudden spikes that might indicate an outbreak or surge event.

</details>

<details>
<summary>Solution</summary>

**Monthly dashboard:**

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

**Daily ED arrivals to spot spikes:**

```sql
SELECT
    timestamp::DATE AS day,
    COUNT(*) AS arrivals
FROM fact_ed_arrival
GROUP BY day
ORDER BY arrivals DESC, day
LIMIT 10;
```

**Winter vs summer by year:**

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

</details>

<details>
<summary>Discussion</summary>

The monthly dashboard shows the overall shape of activity across the full dataset. But to answer "was this winter the worst?", you need to compare winters across years. The winter-vs-summer query labels each month by season and year, letting you compare directly.

However, the patient population grows over the dataset's time span, so later years naturally have more activity. A raw volume increase doesn't necessarily mean "worse" pressure. To separate genuine seasonality from population growth, compute per-capita rates (events per 1,000 active patients) by month. If the per-capita winter rate is climbing year over year, the Medical Director has a point.

The daily spike analysis reveals interesting outliers -- check whether the busiest days cluster around bank holidays or winter surges. This is the kind of multi-metric analysis that NHS boards actually review. Put it in a chart and it tells a compelling story.

</details>

---

## Data Detective

### Exercise 18: "The Finance Director wants to know our surgical income."

Calculate total surgical tariff income from theatre utilisation and procedure tariffs.

<details>
<summary>Hints</summary>

- `fact_surgery_performed` links to `dim_theatre` (which theatre was used).
- `fact_pre_op_assessment` links to `dim_procedure` (which procedure was planned).
- Can you link a surgery to its procedure? They share a `surgical_episode_id` within the surgical pathway.
- Total income = sum of procedure tariffs for all completed surgeries.

</details>

<details>
<summary>Solution</summary>

**Theatre utilisation:**

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

**Income by procedure complexity:**

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

</details>

<details>
<summary>Discussion</summary>

Is utilisation roughly even across theatres? The per-day figure gives you a sense of how busy each theatre is across the dataset's time span.

Linking surgeries to their procedures requires going through the `surgical_episode_id` -- the surgery fact and the pre-op assessment fact share the same surgical episode. The join gives you the procedure details (name, complexity, tariff) for each completed surgery.

Income concentrates in complex and major procedures. Check which specialty groups generate the most total income -- the answer depends on both the tariff per case and the volume of cases performed. This concentration pattern is typical of NHS trust finances.

</details>

---

### Exercise 19: "Are we keeping patients, or just cycling through them?"

The strategy team wants to understand service utilisation patterns. Do patients come back for multiple episodes of care, or is it mostly one-and-done?

<details>
<summary>Hints</summary>

- A patient can appear in multiple care episodes across different pathways.
- Count distinct episodes per patient to measure service utilisation.
- Which patients have the most complex care histories? What conditions?
- Consider both inpatient spells and outpatient pathways.

</details>

<details>
<summary>Solution</summary>

**Inpatient spells per patient:**

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

**Most complex patients (multi-pathway):**

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

**Condition profile of high-frequency patients:**

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

</details>

<details>
<summary>Discussion</summary>

Most patients have 1-2 inpatient spells. A small group of "frequent flyers" have 3+ spells and tend to appear across multiple pathways (ED, inpatient, surgical). These high-frequency patients are often the focus of clinical case management programs.

The multi-pathway query shows which patients have the most complex care histories. How many distinct pathway types do the top patients actually touch? The condition and comorbidity profile of these patients tells the clinical story: patients with multiple comorbidities and complex conditions use more services.

This is cohort analysis applied to healthcare. The same principle (who returns, who doesn't, and why) applies across industries.

</details>

---

## Multi-Year Analysis

### Exercise 20: "Are we getting better or worse?"

The board wants a performance dashboard showing quarterly trends for key NHS targets. Pick three targets we've already computed (A&E 4-hour, Cancer 28-day FDS, Diagnostic 6-week) and show how they trend over time.

<details>
<summary>Hints</summary>

- Reuse patterns from Exercises 5, 11, and 12 -- but add `DATE_TRUNC('quarter', ...)` to group by quarter.
- Show both the percentage and the volume alongside each other. A target met on 10 patients is different from a target met on 1,000.
- Think about how to present this. Three separate queries is fine.

</details>

<details>
<summary>Solution</summary>

**A&E 4-hour performance by quarter:**

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

**Cancer 28-day FDS by quarter:**

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

**Diagnostic 6-week compliance by quarter:**

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

</details>

<details>
<summary>Discussion</summary>

Trend direction matters more than any single point-in-time number. Look for quarters where multiple metrics dip simultaneously -- that suggests a systemic issue (staff shortages, winter pressure) rather than a one-off in a single pathway.

Present these as line charts with horizontal target lines (78% for A&E, 75% for cancer FDS, 99% for diagnostics). That visual format is exactly what NHS board packs use. If volume is growing but the percentage is stable, the trust is scaling well. If the percentage is dropping as volume grows, capacity isn't keeping up.

</details>

---

### Exercise 21: "Do our patients come back?"

Cohort analysis: of patients first seen in 2023, how many had activity in 2024? In 2025? This is about long-term continuity of care, not 30-day readmissions.

<details>
<summary>Hints</summary>

- Define "first appeared" using `MIN(timestamp)` across the major fact tables.
- Build a 2023 cohort -- patients whose earliest activity falls in 2023.
- Then check which years those same patients appear in across all fact tables.
- This is different from Exercise 19 (which looked at episode counts per patient). Here you're looking at year-over-year re-attendance.

</details>

<details>
<summary>Solution</summary>

**Build the 2023 cohort and track across years:**

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

</details>

<details>
<summary>Discussion</summary>

High re-attendance (many 2023 patients still appearing in 2024 and 2025) suggests chronic conditions needing ongoing management -- these patients aren't "cured and gone." Low re-attendance suggests acute, one-time encounters.

Try segmenting by primary condition or pathway type. Cardiac and respiratory patients likely have higher re-attendance than orthopaedic patients who come in for a single procedure. This connects back to Exercise 19 (service utilisation) but adds the time dimension -- are we seeing the same patients year after year, or is the population turning over?

</details>

---
