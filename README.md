# SQL Practice: NHS Hospital Analytics

21 SQL exercises using a simulated NHS acute trust dataset. Exercises are framed as real operational questions, progressing in difficulty from beginner to intermediate.

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

### Patient Dimension

| Table | Rows | Description |
|-------|------|-------------|
| `dim_patient` | 25,947 | Patient demographics (SCD-2, 16,659 distinct patients) |

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
| `fact_ed_arrival` | 10,700 | Emergency department arrivals |
| `fact_triage` | 10,700 | Triage assessments (category 1-5) |
| `fact_ed_assessment` | 10,174 | Clinical assessments (includes wait_minutes) |

### Inpatient Facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_admission` | 8,128 | Hospital admissions |
| `fact_ward_assignment` | 5,616 | Ward and bed assignments |
| `fact_medication_administered` | 23,303 | Medication events |
| `fact_icu_care` | 452 | ICU/HDU escalations |
| `fact_discharge` | 5,403 | Discharges |
| `fact_dtoc_assessment` | 3,439 | Delayed transfer of care assessments |

### Outpatient Facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_referral_created` | 9,611 | Outpatient referrals |
| `fact_appointment_attended` | 4,939 | Attended appointments |

### Surgical Facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_pre_op_assessment` | 3,704 | Pre-operative assessments (links to procedure) |
| `fact_surgeon_assigned` | 3,463 | Surgeon assignments |
| `fact_surgery_performed` | 3,358 | Completed surgeries (links to theatre) |

### Cancer Facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_cancer_referral` | 1,848 | Cancer pathway referrals |
| `fact_cancer_first_seen` | 726 | First consultant appointments |

### Diagnostics

| Table | Rows | Description |
|-------|------|-------------|
| `fact_diagnostic_ordered` | 5,126 | Diagnostic test orders |
| `fact_diagnostic_performed` | 1,371 | Completed tests |

### Other

| Table | Rows | Description |
|-------|------|-------------|
| `fact_fft_response` | 4,597 | Friends and Family Test responses (recommendation_score) |
| `fact_safety_incident` | 103 | Safety incidents |
| `fact_death_record` | 119 | In-hospital deaths |

16,659 distinct patients across 3 years (2023-2025). Generated with [Fabulexa](https://github.com/leogodin217/fabulexa_sim) (a configurable synthetic data generator).

A 27th table (`fact_journey_states`) is available as a CSV in `data/` but not loaded into the database. It contains detailed state-by-state patient pathway data. Advanced users can load it manually for richer temporal analysis.

## Use of AI

I use LLMs every day. At work. At home. AI is integrated in my workflows and this project is no different. This is how I build these types of practice exercises. (Currently completed step 4.)

1. I used Claude Code to build a configurable synthetic data generator. (Took eight months and many failed experiments)
2. Used Claude to vet my idea for good practice exercises. Vague questions. Business scenarios. All on the same database. Hints. Etc.
3. Back and forth with Claude until it understood exactly what I wanted.
4. Let Claude generate the dataset, questions and queries.
5. Reviewed, analyzed, and iterated until I got exactly what I wanted.
6. Hand edited the rest.

## What's Next

More datasets. The synthetic data generator can produce healthcare, retail, SaaS, education -- any domain you can describe in YAML. More repos like this one are coming. And eventually, LLM-assisted tutoring that helps you through the exercises without just giving answers.
