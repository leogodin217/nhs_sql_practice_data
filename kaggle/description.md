# Millbrook NHS Trust — A Synthetic Acute Care Data Warehouse

A synthetic, multi-table NHS acute-care dataset. 28 CSVs organised as a star schema with dimension and fact tables, modelled on an English acute trust. 16,341 distinct patients across three years (2023–2025). No real patient data.

## What Can You Do?

This data models a realistic(ish) NHS clinic from inception in 2023 through 2025. Patient journeys work from admission, through discharge. It was designed to produce everything needed to calculate the seven metrics below. You'll find a few surprises in seasonality, capacity constraints and outbreaks. While it was created out of a Reddit request for someone who wanted to get into NHS analytics, it is useful for anyone wanting to learn data warehousing, EDA or perform statistical analysis on a more complex dataset. Tracking metrics over time should provide plenty of opportunities for deeper analysis. You will find meaningful differences in metrics when slicing by demographics, care type, etc. 

**Access and performance targets**
- [A&E 4-hour standard](https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/) (national target: 78%)
- [Cancer 28-day Faster Diagnosis Standard](https://www.england.nhs.uk/statistics/statistical-work-areas/cancer-waiting-times/) (target: 75%)
- [Diagnostic 6-week wait / DM01](https://www.england.nhs.uk/statistics/statistical-work-areas/diagnostics-waiting-times-and-activity/monthly-diagnostics-waiting-times-and-activity/) (target: 99% within 42 days)

**Quality and outcome measures**

- [30-day emergency readmission rate](https://digital.nhs.uk/data-and-information/publications/statistical/compendium-emergency-readmissions/current) (benchmark: 12–14%)
- [In-hospital mortality rate — SHMI](https://digital.nhs.uk/data-and-information/publications/statistical/shmi) (context for HSMR)
- [Delayed Transfer of Care (DTOC) delay](https://www.england.nhs.uk/statistics/statistical-work-areas/delayed-transfers-of-care/) (discontinued Feb 2020; successor: [Discharge Delays](https://www.england.nhs.uk/statistics/statistical-work-areas/discharge-delays/acute-discharge-situation-report/))
- [Friends and Family Test (FFT) recommendation rate](https://www.england.nhs.uk/fft/friends-and-family-test-data/)

Note on the 4-hour standard: the data does not include an ED departure event, so time-to-assessment is used as an operational proxy. Not ideal, but good enough for practice and learning. 

Full data dictionary in the repo [github.com/leogodin217/nhs_sql_practice_data](https://github.com/leogodin217/nhs_sql_practice_data).


## Tables 

Dimension tables (`dim_*`) and fact tables (`fact_*`) linked by foreign keys. All files are CSV.

### Patient dimension

| Table | Rows | Description |
|-------|------|-------------|
| `dim_patient` | 26,720 | Patient demographics (SCD-2; 16,341 distinct patients) |

### Clinical dimensions

| Table | Rows | Description |
|-------|------|-------------|
| `dim_consultant` | 25 | Consultants across 5 specialty groups |
| `dim_ward` | 10 | Hospital wards (75 total beds) |
| `dim_procedure` | 35 | Surgical procedures with OPCS-4 codes and tariffs |
| `dim_medication` | 44 | Medications with BNF categories |
| `dim_diagnostic` | 12 | Diagnostic tests (MRI, CT, blood, etc.) |
| `dim_theatre` | 5 | Operating theatres |

### A&E facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_ed_arrival` | 10,710 | Emergency department arrivals |
| `fact_triage` | 10,710 | Triage assessments (category 1–5) |
| `fact_ed_assessment` | 10,151 | Clinical assessments (includes `wait_minutes`) |

### Inpatient facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_admission` | 9,612 | Hospital admissions |
| `fact_ward_assignment` | 6,899 | Ward and bed assignments |
| `fact_medication_administered` | 11,068 | Medication administration events |
| `fact_icu_care` | 762 | ICU/HDU escalations |
| `fact_discharge` | 9,275 | Discharges |
| `fact_dtoc_assessment` | 6,540 | Delayed transfer of care assessments |

### Outpatient facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_referral_created` | 18,577 | Outpatient referrals |
| `fact_appointment_attended` | 23,975 | Attended appointments |

### Surgical facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_pre_op_assessment` | 7,883 | Pre-operative assessments (links to procedure) |
| `fact_surgeon_assigned` | 7,866 | Surgeon assignments |
| `fact_surgery_performed` | 7,142 | Completed surgeries (links to theatre) |

### Cancer facts

| Table | Rows | Description |
|-------|------|-------------|
| `fact_cancer_referral` | 2,865 | Cancer pathway referrals |
| `fact_cancer_first_seen` | 2,796 | First consultant appointments |

### Diagnostics

| Table | Rows | Description |
|-------|------|-------------|
| `fact_diagnostic_ordered` | 8,325 | Diagnostic test orders |
| `fact_diagnostic_performed` | 6,026 | Completed tests |

### Other

| Table | Rows | Description |
|-------|------|-------------|
| `fact_fft_response` | 8,594 | Friends and Family Test responses (`recommendation_score`) |
| `fact_safety_incident` | 418 | Safety incidents |
| `fact_death_record` | 263 | In-hospital deaths |

## Quickstart

Two notebooks are attached:

- **Millbrook NHS — SQL Intro with DuckDB** — registers the CSVs as DuckDB views and walks through patient count (with SCD-2), the Monday effect, and length-of-stay.
- **Millbrook NHS — Python Intro** — pandas exploration, a seaborn boxplot of daily A&E arrivals, and a scipy ANOVA testing the Monday effect.

## Use of LLMs

I know data, but I don't know NHS data. When someone asked for this on Reddit, I used Claude to research metrics and data models. It generated the 3,000-line YAML needed to generate a complex dataset like this. Claude also helped with some of the artifacts needed for the dataset upload. I did multiple rounds of QA and editing throughout, but this was mostly Claude and a synthetic data generator.  

## License

CC BY-SA 4.0.
