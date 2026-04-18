# SQL Practice: NHS Hospital Analytics

27 SQL exercises using an NHS acute trust dataset. Exercises are framed as real operational questions, progressing in difficulty from beginner to intermediate.

## Running Locally

Both the SQL and Python practice tools run entirely in your browser via WebAssembly — no backend server required. You just need to serve the files over HTTP (browsers block local file access for security).

```bash
# Clone the repo
git clone https://github.com/leogodin217/nhs_sql_practice_data.git
cd nhs_sql_practice_data

# Serve with Python's built-in HTTP server
python -m http.server 8000
```

Then open:
- **SQL Practice:** [http://localhost:8000/](http://localhost:8000/)
- **Python Practice:** [http://localhost:8000/python.html](http://localhost:8000/python.html)

The Python version uses [Pyodide](https://pyodide.org) to run pandas, matplotlib, seaborn, scipy, and scikit-learn in the browser. First load takes 15-30 seconds while packages download.

## Why?

NHS hospitals generate mountains of data -- admissions, discharges, referrals, theatre bookings, diagnostic orders, patient surveys. Analysts working with this data need to understand how clinical processes connect, how to compute national performance targets, and how to spot data quality issues.

These exercises use deliberately vague, real-world questions -- the kind a Medical Director, Finance lead, or operations manager would actually ask. Your job is to figure out what data answers the question, then write SQL to get it. There is no single right answer for most of these.

## Setup

### Run in Your Broswer (Easiest)

Go [here](https://leogodin217.github.io/nhs_sql_practice_data/)

### DuckDB with DBeaver (Recommended)

**Requires:** [DuckDB CLI](https://duckdb.org/docs/installation/)

**Option A: Build from CSV**

```bash
duckdb nhsdb.duckdb < build_db.sql
```

**Option B: Download pre-built DB**

Download `nhsdb.duckdb` from the [latest release](../../releases/latest).

### DBeaver

DBeaver is a free, open-source SQL editor. It is very popular and works well with DuckDB.

[DBeaver Instructions](https://duckdb.org/docs/stable/guides/sql_editors/dbeaver)

### Roll Your Own

These exercises were tested on DuckDB and should work. Alternatively, feel free to import the CSVs into any DBMS you want. Some of the answers might need tweaking to work, but that's a good learning experience.

## Usage

Open the database and start querying:

```bash
duckdb nhsdb.duckdb  # If you are a masochist
```

**DBeaver**

1. Database > New Database Connection
2. Select DuckDB
3. Browse to nhsdb.duckdb
4. Play around. Explore

Exercises are in [exercises.md](exercises.md) -- each one includes collapsible hints, solutions, and discussion sections.

Some useful commands to get oriented:

```sql
-- What tables exist?
SHOW TABLES;

-- What columns does a table have?
DESCRIBE nhsdb.main.dim_patient;

-- What does the data look like?
SELECT * FROM nhsdb.main.dim_patient LIMIT 10;
```

## Dataset

Column-level reference for every table, with live stats (null %, distinct counts, ranges, sample values), is in [`docs/data_dictionary/index.md`](docs/data_dictionary/index.md). Regenerate it with `python scripts/gen_data_dictionary.py` after rebuilding the CSVs.

### Patient Dimension

| Table | Rows | Description |
|-------|------|-------------|
| `dim_patient` | 26,441 | Patient demographics (SCD-2, 16,364 distinct patients) |

### Clinical Dimensions

| Table | Rows | Description |
|-------|------|-------------|
| `dim_consultant` | 25 | Consultants across 5 specialty groups |
| `dim_ward` | 10 | Hospital wards (75 total beds) |
| `dim_procedure` | 35 | Surgical procedures with OPCS-4 codes and tariffs |
| `dim_medication` | 30 | Medications with BNF categories |
| `dim_diagnostic` | 12 | Diagnostic tests (MRI, CT, blood, etc.) |
| `dim_theatre` | 5 | Operating theatres |

### A&E Facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_ed_arrival` | 10,695 | Emergency department arrivals |
| `fact_triage` | 10,695 | Triage assessments (category 1-5) |
| `fact_ed_assessment` | 10,171 | Clinical assessments (includes wait_minutes) |

### Inpatient Facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_admission` | 9,347 | Hospital admissions |
| `fact_ward_assignment` | 6,760 | Ward and bed assignments |
| `fact_medication_administered` | 10,605 | Medication events |
| `fact_icu_care` | 730 | ICU/HDU escalations |
| `fact_discharge` | 9,045 | Discharges |
| `fact_dtoc_assessment` | 6,472 | Delayed transfer of care assessments |

### Outpatient Facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_referral_created` | 14,914 | Outpatient referrals |
| `fact_appointment_attended` | 21,716 | Attended appointments |

### Surgical Facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_pre_op_assessment` | 7,239 | Pre-operative assessments (links to procedure) |
| `fact_surgeon_assigned` | 7,224 | Surgeon assignments |
| `fact_surgery_performed` | 6,582 | Completed surgeries (links to theatre) |

### Cancer Facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_cancer_referral` | 2,888 | Cancer pathway referrals |
| `fact_cancer_first_seen` | 2,810 | First consultant appointments |

### Diagnostics

| Table | Rows | Description |
|-------|------|-------------|
| `fact_diagnostic_ordered` | 7,895 | Diagnostic test orders |
| `fact_diagnostic_performed` | 5,592 | Completed tests |

### Other

| Table | Rows | Description |
|-------|------|-------------|
| `fact_fft_response` | 8,423 | Friends and Family Test responses (recommendation_score) |
| `fact_safety_incident` | 272 | Safety incidents |
| `fact_death_record` | 233 | In-hospital deaths |

16,364 distinct patients across 3 years (2023-2025). Generated with Fabulexa (A generalized synthetic data generator)


## NHS Metrics

The dataset is calibrated to produce operationally meaningful results for the following NHS performance and quality measures:

**Access and performance targets**

- [A&E 4-hour standard](https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/) (target: 78% by March 2026, 95% constitutional)
- [Cancer 28-day Faster Diagnosis Standard](https://www.england.nhs.uk/statistics/statistical-work-areas/cancer-waiting-times/) (target: 75%, rising to 80% by March 2026)
- [Diagnostic 6-week wait / DM01](https://www.england.nhs.uk/statistics/statistical-work-areas/diagnostics-waiting-times-and-activity/monthly-diagnostics-waiting-times-and-activity/) (target: ≥99% within 42 days)

**Quality and outcome measures**

- [30-day emergency readmission rate](https://digital.nhs.uk/data-and-information/publications/statistical/compendium-emergency-readmissions/current) (benchmark: 12–14%)
- [In-hospital mortality rate — SHMI](https://digital.nhs.uk/data-and-information/publications/statistical/shmi) (context for SHMI / HSMR)
- [Delayed Transfer of Care (DTOC) delay](https://www.england.nhs.uk/statistics/statistical-work-areas/delayed-transfers-of-care/) (discontinued Feb 2020; successor: [Discharge Delays](https://www.england.nhs.uk/statistics/statistical-work-areas/discharge-delays/acute-discharge-situation-report/))
- [Friends and Family Test (FFT) recommendation rate](https://www.england.nhs.uk/fft/friends-and-family-test-data/)

Note on the 4-hour standard: the data does not include an ED departure event, so time-to-assessment is used as a proxy.

See [project/metric_definitions.md](project/metric_definitions.md) for full definitions, targets, and calculation details per metric.

## Use of AI

I use LLMs every day. At work. At home. AI is integrated in my workflows and this project is no different. This is how I build these types of practice exercises. 

1. I used Claude Code to build Fabulexa; a configurable synthetic data generator. (Took eight months and many failed experiments)
2. Used Claude to vet my idea for good practice exercises. Vague questions. Business scenarios. All on the same database. Hints. Etc.
3. Back and forth with Claude until it understood exactly what I wanted.
4. Let Claude generate the dataset with  questions and queries.
5. Reviewed, analyzed, and iterated until I got exactly what I wanted.
6. Hand edited the rest.

## What's Next

More datasets. The synthetic data generator can produce healthcare, retail, SaaS, education -- any domain you can describe in YAML. More repos like this one are coming. 
