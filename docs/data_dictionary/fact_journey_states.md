# `fact_journey_states`

*Group:* Pathway traces  
*Grain:* One row per journey-state transition  
*Rows:* 432,000

State-by-state trace of every patient journey — every intermediate
state the simulator emits as a patient moves through A&E, inpatient,
outpatient, surgical, cancer, and diagnostic pathways. Shipped as a
CSV in the repo but not loaded into the default DuckDB build.

## Notes

Useful for advanced temporal analyses (time-in-state distributions,
bottleneck detection, Sankey-style flow diagrams) that need every
intermediate state rather than just the clock-start/clock-stop events
captured by the other fact tables.

## Columns

| Column | Type | Null % | Distinct | Range / sample values | Description |
|---|---|---:|---:|---|---|
| `actor_type` | `VARCHAR` | 0 | 1 | `patient` | Entity whose journey is traced. Currently always `patient`. |
| `actor_id` | `VARCHAR` | 0 | 16,341 | `PAT_0015623`, `PAT_0015642`, `PAT_0015645`, … | Identifier of the acting entity (e.g. `PAT_0004273`). |
| `journey_type` | `VARCHAR` | 0 | 9 | `outpatient_pathway`, `patient_intake`, `inpatient_spell`, … | Journey type: `patient_intake`, `inpatient_spell`, `outpatient_pathway`, `cancer_pathway`, `surgical_pathway`, `diagnostic_request`, etc. |
| `journey_instance_id` | `VARCHAR` | 0 | 116,915 | `inst_67023`, `inst_67035`, `inst_66394`, … | Instance identifier for this specific journey (matches `spell_id`, `pathway_id`, `attendance_id`, etc. in the corresponding fact table). |
| `state` | `VARCHAR` | 0 | 52 | `icu_hdu`, `elective_routed`, `admitted`, … | Named state within the journey (e.g. `assessment`, `icu_hdu`, `discharged_ed`). |
| `entered_at` | `TIMESTAMP` | 0 | 419,420 | 2023-01-01 00:22:29 → 2026-01-01 01:03:33 | Time the entity entered this state. |
| `exited_at` | `TIMESTAMP` | 27.1 | 314,159 | 2023-01-01 00:22:31 → 2026-01-01 01:03:33 | Time the entity exited this state. NULL for the current (terminal) state. |
