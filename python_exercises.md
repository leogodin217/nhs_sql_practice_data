# Python Data Analysis Practice

**Dataset:** Millbrook NHS Trust
**Runtime:** Pyodide (Python in WebAssembly)

## Getting Started

All tables are available as CSVs in `data/`. Load any table with pandas:

```python
import pandas as pd
patients = pd.read_csv('data/dim_patient.csv')
patients.head()
```

### Available Tables

| Group | Tables |
|-------|--------|
| Dimensions | `dim_patient`, `dim_ward`, `dim_consultant`, `dim_procedure`, `dim_medication`, `dim_diagnostic`, `dim_theatre` |
| A&E | `fact_ed_arrival`, `fact_triage`, `fact_ed_assessment` |
| Inpatient | `fact_admission`, `fact_discharge`, `fact_ward_assignment`, `fact_medication_administered`, `fact_icu_care`, `fact_dtoc_assessment`, `fact_death_record`, `fact_safety_incident` |
| Outpatient | `fact_referral_created`, `fact_appointment_attended` |
| Surgical | `fact_pre_op_assessment`, `fact_surgeon_assigned`, `fact_surgery_performed` |
| Cancer | `fact_cancer_referral`, `fact_cancer_first_seen` |
| Diagnostics | `fact_diagnostic_ordered`, `fact_diagnostic_performed` |
| Other | `fact_fft_response` |

### Libraries Available

`pandas`, `numpy`, `matplotlib`, `seaborn`, `scipy`, `scikit-learn`

### Tips

- DataFrames returned as the last expression are rendered as tables automatically
- Matplotlib figures are captured and displayed — call `plt.show()` as normal
- Variables persist between runs — load data once, reuse it later
- Use `print()` for text output

---

## Exercise 1: Explore the Data

*Library: **pandas***

Load `dim_patient` and get oriented. How many unique patients does the trust serve? What's the breakdown by primary condition and pathway type?

<details>
<summary>Hints</summary>

- `pd.read_csv()` to load, `.head()` to preview
- `.shape` gives (rows, columns), `.dtypes` shows column types
- `.nunique()` counts distinct values in a column
- `.value_counts()` shows frequency distributions
- The table uses SCD-2: filter to `valid_to` being null for current patients

</details>

<details>
<summary>Solution</summary>

```python
import pandas as pd

patients = pd.read_csv('data/dim_patient.csv')
current = patients[patients['valid_to'].isna()]

print(f"Total rows:       {len(patients)}")
print(f"Current patients: {len(current)}")
print(f"Unique IDs:       {current['id'].nunique()}")
print(f"\nBy primary condition:")
print(current['primary_condition'].value_counts().to_string())
print(f"\nBy pathway type:")
print(current['pathway_type'].value_counts().to_string())
```

</details>

<details>
<summary>Discussion</summary>

`dim_patient` uses Type-2 Slowly Changing Dimensions — when tracked properties change, a new row is created. That's why `len(patients)` exceeds the real patient count. Filtering to `valid_to` being null gives the current snapshot.

pandas makes this kind of exploratory analysis quick. Compare to the SQL equivalent (`SELECT COUNT(DISTINCT id) FROM dim_patient`) — pandas gives you multiple views in a few lines, with no schema knowledge needed upfront.

</details>

---

## Exercise 2: Visualise the Patient Population

*Libraries: **pandas**, **matplotlib***

Create charts showing patients by primary condition and by IMD deprivation decile.

<details>
<summary>Hints</summary>

- `.value_counts()` returns a Series you can plot directly
- `.plot.barh()` for horizontal bars, `.plot.bar()` for vertical
- `fig, (ax1, ax2) = plt.subplots(1, 2)` for side-by-side charts
- NHS blue is `#005EB8`

</details>

<details>
<summary>Solution</summary>

```python
import pandas as pd
import matplotlib.pyplot as plt

patients = pd.read_csv('data/dim_patient.csv')
current = patients[patients['valid_to'].isna()]

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 4))

current['primary_condition'].value_counts().plot.barh(
    ax=ax1, color='#005EB8')
ax1.set_xlabel('Patients')
ax1.set_title('By Condition')

current['imd_decile'].value_counts().sort_index().plot.bar(
    ax=ax2, color='#005EB8')
ax2.set_xlabel('IMD Decile (1=most deprived)')
ax2.set_ylabel('Patients')
ax2.set_title('By Deprivation')

plt.tight_layout()
plt.show()
```

</details>

<details>
<summary>Discussion</summary>

The IMD distribution skews heavily toward deprived deciles — roughly 5x more patients in decile 1 than decile 10. This is typical for urban acute trusts serving deprived catchment areas.

The `value_counts().plot()` pattern is one of the most used in pandas. matplotlib gives you full control over layout, labels, and styling.

</details>

---

## Exercise 3: The Monday Effect

*Libraries: **pandas**, **seaborn***

A&E staff say Mondays are significantly worse. Create a box plot showing the distribution of daily A&E arrivals by day of week.

<details>
<summary>Hints</summary>

- Convert timestamps: `pd.to_datetime(df['timestamp'])`
- `.dt.day_name()` extracts day names, `.dt.date` extracts dates
- Group by date first to get daily totals, then plot by day name
- `sns.boxplot()` with `order=` controls day ordering

</details>

<details>
<summary>Solution</summary>

```python
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

ed = pd.read_csv('data/fact_ed_arrival.csv')
ed['timestamp'] = pd.to_datetime(ed['timestamp'], format='ISO8601')
ed['day_name'] = ed['timestamp'].dt.day_name()
ed['date'] = ed['timestamp'].dt.date

daily = ed.groupby(['date', 'day_name']).size().reset_index(name='arrivals')

day_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
             'Friday', 'Saturday', 'Sunday']

fig, ax = plt.subplots(figsize=(8, 4))
sns.boxplot(data=daily, x='day_name', y='arrivals',
            order=day_order, color='#005EB8', ax=ax)
ax.set_xlabel('Day of Week')
ax.set_ylabel('Daily Arrivals')
ax.set_title('A&E Arrivals by Day of Week')
plt.xticks(rotation=30)
plt.tight_layout()
plt.show()
```

</details>

<details>
<summary>Discussion</summary>

Seaborn's `boxplot` shows distribution shape that a simple average would hide — median, spread, and outliers for each day. Monday should show a clearly higher median, with weekends noticeably lower.

Compare writing this in pure matplotlib: you'd need to manually group data, compute quartiles, and draw boxes. Seaborn handles the statistical aggregation and rendering in one call.

</details>

---

## Exercise 4: Is It Statistically Significant?

*Library: **scipy***

The box plot looks convincing, but is the Monday effect real? Run a one-way ANOVA and pairwise t-tests to find out.

<details>
<summary>Hints</summary>

- `scipy.stats.f_oneway()` runs one-way ANOVA across multiple groups
- Split daily arrivals into separate arrays by day of week
- A p-value < 0.05 means the differences are unlikely due to chance
- Use `scipy.stats.ttest_ind()` for pairwise Monday-vs-other comparisons

</details>

<details>
<summary>Solution</summary>

```python
import pandas as pd
from scipy import stats

ed = pd.read_csv('data/fact_ed_arrival.csv')
ed['timestamp'] = pd.to_datetime(ed['timestamp'], format='ISO8601')
ed['day_name'] = ed['timestamp'].dt.day_name()
ed['date'] = ed['timestamp'].dt.date

daily = ed.groupby(['date', 'day_name']).size().reset_index(name='arrivals')

groups = [g['arrivals'].values for _, g in daily.groupby('day_name')]
f_stat, p_value = stats.f_oneway(*groups)

print(f"ANOVA: F = {f_stat:.2f}, p = {p_value:.6f}")
print(f"Significant at 0.05? {'Yes' if p_value < 0.05 else 'No'}\n")

monday = daily[daily['day_name'] == 'Monday']['arrivals']
for day in ['Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']:
    other = daily[daily['day_name'] == day]['arrivals']
    t, p = stats.ttest_ind(monday, other)
    sig = '*' if p < 0.05 else ' '
    print(f"  Monday vs {day:9s}  t={t:6.2f}  p={p:.4f} {sig}")
```

</details>

<details>
<summary>Discussion</summary>

The ANOVA tests whether *any* day differs significantly. The pairwise t-tests show *which* days differ from Monday specifically. You should find Monday is significantly different from most days, and Saturday/Sunday differ in the opposite direction.

scipy turns "it looks like Monday is busier" into "Monday averages X more arrivals with p < 0.001." This is the difference between an observation and evidence.

</details>

---

## Exercise 5: Length of Stay Distribution

*Libraries: **pandas**, **matplotlib**, **numpy***

Compute inpatient length of stay for completed spells. Plot the distribution and annotate key statistics.

<details>
<summary>Hints</summary>

- Join `fact_admission` to `fact_discharge` on `spell_id`
- Use `.groupby('spell_id')['timestamp'].min()` to get earliest event per spell
- Merge the two results on `spell_id`, then subtract timestamps to get LOS in days
- The distribution will be right-skewed: mean and median will diverge

</details>

<details>
<summary>Solution</summary>

```python
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

admissions = pd.read_csv('data/fact_admission.csv')
admissions['timestamp'] = pd.to_datetime(admissions['timestamp'], format='ISO8601')
discharges = pd.read_csv('data/fact_discharge.csv')
discharges['timestamp'] = pd.to_datetime(discharges['timestamp'], format='ISO8601')

admit = (admissions.groupby('spell_id')['timestamp']
         .min().reset_index(name='admit_ts'))
discharge = (discharges.groupby('spell_id')['timestamp']
             .min().reset_index(name='discharge_ts'))

spells = admit.merge(discharge, on='spell_id')
spells['los_days'] = (spells['discharge_ts'] - spells['admit_ts']).dt.total_seconds() / 86400

fig, ax = plt.subplots(figsize=(8, 4))
ax.hist(spells['los_days'], bins=30, color='#005EB8', edgecolor='white', alpha=0.8)
ax.axvline(spells['los_days'].mean(), color='#d5281b', ls='--',
           label=f'Mean: {spells["los_days"].mean():.1f} days')
ax.axvline(spells['los_days'].median(), color='#f0ad4e', ls='--',
           label=f'Median: {spells["los_days"].median():.1f} days')
ax.set_xlabel('Length of Stay (days)')
ax.set_ylabel('Completed Spells')
ax.set_title('Inpatient Length of Stay Distribution')
ax.legend()
plt.tight_layout()
plt.show()

print(f"Spells:  {len(spells)}")
print(f"Mean:    {spells['los_days'].mean():.1f} days")
print(f"Median:  {spells['los_days'].median():.1f} days")
print(f"P90:     {np.percentile(spells['los_days'], 90):.1f} days")
```

</details>

<details>
<summary>Discussion</summary>

LOS distributions are almost always right-skewed — most patients stay a few days, but some stay much longer. That's why the median is more useful than the mean for operational planning. The NHS benchmark is 4-5 days average LOS.

The right tail matters disproportionately: a small number of long-stay patients consume significant bed capacity. This is where pandas data wrangling (merge, groupby) combines naturally with matplotlib for visual insight.

</details>

---

## Exercise 6: Deprivation & Outcomes

*Libraries: **pandas**, **seaborn**, **scipy***

Is there a relationship between deprivation (IMD decile) and length of stay? Compute average LOS by decile, test for correlation, and visualise.

<details>
<summary>Hints</summary>

- Build on Exercise 5's LOS calculation
- Merge with `dim_patient` (current rows only) to get `imd_decile`
- `scipy.stats.pearsonr()` tests linear correlation
- IMD decile 1 = most deprived, 10 = least deprived

</details>

<details>
<summary>Solution</summary>

```python
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from scipy import stats

patients = pd.read_csv('data/dim_patient.csv')
current = patients[patients['valid_to'].isna()][['id', 'imd_decile']]

admissions = pd.read_csv('data/fact_admission.csv')
admissions['timestamp'] = pd.to_datetime(admissions['timestamp'], format='ISO8601')
discharges = pd.read_csv('data/fact_discharge.csv')
discharges['timestamp'] = pd.to_datetime(discharges['timestamp'], format='ISO8601')

spells = (admissions.groupby(['spell_id', 'patient_id'])['timestamp']
          .min().reset_index(name='admit_ts'))
dis = (discharges.groupby('spell_id')['timestamp']
       .min().reset_index(name='discharge_ts'))

spells = spells.merge(dis, on='spell_id')
spells['los'] = (spells['discharge_ts'] - spells['admit_ts']).dt.total_seconds() / 86400

merged = spells.merge(current, left_on='patient_id', right_on='id')
by_imd = merged.groupby('imd_decile')['los'].mean().reset_index()

r, p = stats.pearsonr(by_imd['imd_decile'], by_imd['los'])
print(f"Pearson r = {r:.3f} (p = {p:.4f})")
print(f"{'Significant' if p < 0.05 else 'Not significant'} at 0.05\n")

fig, ax = plt.subplots(figsize=(8, 4))
sns.barplot(data=by_imd, x='imd_decile', y='los', color='#005EB8', ax=ax)
ax.set_xlabel('IMD Decile (1 = most deprived)')
ax.set_ylabel('Average LOS (days)')
ax.set_title('Length of Stay by Deprivation')
plt.tight_layout()
plt.show()
```

</details>

<details>
<summary>Discussion</summary>

You should see a clear deprivation gradient — patients from deciles 1-3 stay nearly twice as long as those from deciles 8-10. The Pearson correlation confirms this statistically.

This is well-documented in NHS data: deprived patients have more comorbidities, fewer community support options, and more complex discharge needs. This exercise combines three libraries naturally: pandas for wrangling, scipy for the statistical test, and seaborn for the chart.

</details>

---

## Exercise 7: Predict Readmission Risk

*Library: **scikit-learn***

Build a logistic regression model to predict 30-day readmission using patient characteristics. Which features matter most?

<details>
<summary>Hints</summary>

- A readmission = same patient admitted within 30 days of a prior discharge
- Use `.shift(-1)` within groups to find the next admission per patient
- Features: `imd_decile`, `comorbidity_count`, `frailty_score`
- `LogisticRegression` from scikit-learn, `.coef_` for feature importance

</details>

<details>
<summary>Solution</summary>

```python
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

patients = pd.read_csv('data/dim_patient.csv')
current = patients[patients['valid_to'].isna()]

admissions = pd.read_csv('data/fact_admission.csv')
admissions['timestamp'] = pd.to_datetime(admissions['timestamp'], format='ISO8601')
discharges = pd.read_csv('data/fact_discharge.csv')
discharges['timestamp'] = pd.to_datetime(discharges['timestamp'], format='ISO8601')

admit = (admissions.groupby(['spell_id', 'patient_id'])['timestamp']
         .min().reset_index(name='admit_ts'))
dis = (discharges.groupby('spell_id')['timestamp']
       .min().reset_index(name='discharge_ts'))

spells = admit.merge(dis, on='spell_id')
spells = spells.sort_values(['patient_id', 'admit_ts'])
spells['next_admit'] = spells.groupby('patient_id')['admit_ts'].shift(-1)
spells['days_gap'] = (spells['next_admit'] - spells['discharge_ts']).dt.total_seconds() / 86400
spells['readmit_30d'] = (spells['days_gap'] <= 30).astype(int)

features = ['imd_decile', 'comorbidity_count', 'frailty_score']
data = spells.merge(current[['id'] + features], left_on='patient_id', right_on='id')
data = data.dropna(subset=features + ['readmit_30d'])

X = data[features]
y = data['readmit_30d']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

model = LogisticRegression(max_iter=1000)
model.fit(X_train, y_train)

print("Feature coefficients:")
for f, c in zip(features, model.coef_[0]):
    print(f"  {f:25s} {c:+.4f}")
print(f"\nAccuracy: {model.score(X_test, y_test):.3f}")
print(f"Baseline: {1 - y.mean():.3f}  (always predict no readmission)")
print(f"\n{classification_report(y_test, model.predict(X_test), zero_division=0)}")
```

</details>

<details>
<summary>Discussion</summary>

The model accuracy may not beat the baseline much — 30-day readmission is hard to predict from demographics alone. Real NHS predictive models use clinical features (blood results, vital signs, diagnoses) for better performance.

But the coefficients are informative: higher comorbidity count likely increases risk, while higher IMD decile (less deprived) likely decreases it. scikit-learn makes it easy to go from hypothesis to trained model in a few lines.

</details>

---
