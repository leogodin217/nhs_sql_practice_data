# AI-Powered Interactive Education Platform

Concept exploration from 2026-03-11. How to enable educators to create interactive tutorials, courses, and blog posts with minimal technical effort — using AI for content generation and tutoring, WASM for in-browser execution.

---

## The Problem

Creating interactive educational content today requires:

1. **Data** — finding or generating realistic datasets
2. **Exercise design** — writing good questions with proper difficulty progression
3. **Solution authoring** — hints, multiple solutions, discussion for every exercise
4. **Building the app** — WASM integration, UI, editor, results rendering
5. **Student support** — can't be there for every learner at scale
6. **QA** — checking for data/narrative mismatches, terminology issues, ordering bugs
7. **Distribution** — getting content into Medium, WordPress, LMS, course platforms
8. **Maintenance** — keeping content updated as tools and data evolve

The NHS SQL Practice project solved 1-6 in about four days using Claude and Fabulexa (a configurable synthetic data generator that took 8 months to build). The dataset, exercises, QA, and interactive app were all created in that short window — the heavy investment was in the tooling (Fabulexa), not the content. The question: what if other educators could leverage similar tooling without the 8-month build?

---

## Core Insight

The pieces already exist:

- **Fabulexa** — configurable synthetic data generator that can produce healthcare, retail, SaaS, education, or any domain described in YAML
- **Claude** — content generation, pedagogical design, QA, and live tutoring
- **WASM runtimes** — sql.js, DuckDB-WASM, Pyodide, webR all run in-browser with no backend
- **Embedding standards** — oEmbed (Medium, WordPress) and LTI (Canvas, Moodle, Blackboard) enable universal distribution

The gap: nobody has assembled these into a system where an educator provides domain expertise and the system handles everything else.

---

## Concept 1: AI Content Compiler ("Describe and Deploy")

### What the Educator Provides

```yaml
# course.yaml
title: "SQL for Healthcare Analysts"
domain: nhs_acute_trust
language: sql
runtime: duckdb
difficulty: beginner_to_intermediate
exercises: 20
style: vague_real_world_questions
topics:
  - joins and relationships
  - window functions
  - CTEs
  - data quality detection
  - performance metrics (4-hour target, cancer waits)
dataset:
  generator: fabulexa
  config: nhs.yaml
  patients: 5000
  years: [2023, 2024, 2025]
```

### What the System Produces

1. **Synthetic dataset** — Fabulexa generates realistic data matching the domain config
2. **Exercises** — Claude generates progressive exercises with:
   - Deliberately vague, real-world questions (the way a manager would ask)
   - Multiple solution approaches per exercise
   - Collapsible hints that teach without giving away the answer
   - Discussion sections with real-world context
   - Appropriate difficulty progression
3. **QA pass** — Claude checks for:
   - Data/narrative mismatches (like Exercise 18's "scores above 5" that don't exist)
   - Terminology issues (revenue vs income, $ vs GBP)
   - Non-deterministic query ordering on tied values
   - Implausible data distributions
4. **Interactive app** — static site with WASM runtime, CodeMirror editor, results panel
5. **Deployable output** — GitHub Pages, Netlify, or any static host
6. **Embed links** — ready to paste into Medium, WordPress, LMS

### The Iteration Loop

The educator reviews the generated content and iterates in conversation with Claude:

- "Make exercise 7 harder"
- "The FFT scores look inverted — fix the data generator config"
- "Add a question about readmissions"
- "The discussion for exercise 10 uses American terminology — make it NHS-specific"
- "Add a capstone exercise that ties together concepts from exercises 5, 11, and 14"

Each iteration takes minutes, not days. The educator's role shifts from author to editor and domain expert.

### Implementation

Could be built as:
- A CLI tool (most aligned with current workflow)
- A Claude Code workflow with custom slash commands
- A web app with a conversational interface

Minimum viable version: a set of Claude prompts + templates that take course.yaml and produce the same file structure as the NHS project (exercises.md, build_db.sql, data/, index.html). The NHS project was created in ~4 days with this general approach — the AI Content Compiler formalizes and streamlines that process for any educator.

---

## Concept 2: AI Tutor Inside the Exercise

### The Experience

Static hints are limited. An AI tutor adapts to what the student actually tried.

**Example interaction:**

```
Student writes:  SELECT COUNT(*) FROM dim_patient;
                 → 7,380

Student asks:    "Why is this different from 5,386?"

AI Tutor:        "Good question. Look at the table description — it says
                  SCD-2. What does that mean for row counts? Try:
                  SELECT id, COUNT(*) FROM dim_patient
                  GROUP BY id HAVING COUNT(*) > 1 LIMIT 5;
                  What do you notice?"
```

The tutor doesn't give answers. It asks the next question that leads the student to the insight — the way a good teacher would.

**Another example:**

```
Student writes:  SELECT * FROM fact_admission
                 WHERE timestamp > '2024-12-01';
                 → 847 rows

Student asks:    "How do I find the busiest day?"

AI Tutor:        "You've got the right data filtered. Now think about
                  what 'busiest' means — admissions per day. Which SQL
                  clause groups rows into buckets? And which function
                  counts them?"
```

### Architecture

```
┌─────────────────────────────────────────────┐
│  Browser                                     │
│                                              │
│  ┌──────────────┐    ┌────────────────────┐ │
│  │ SQL Editor    │    │ Results Table      │ │
│  │ (CodeMirror)  │    │ (rendered locally) │ │
│  └──────┬───────┘    └────────────────────┘ │
│         │                                    │
│         ▼                                    │
│  ┌──────────────┐                           │
│  │ WASM Runtime  │  ← All SQL runs locally  │
│  │ (DuckDB)      │    No server needed       │
│  └──────────────┘    Free, instant           │
│                                              │
│  ┌──────────────┐                           │
│  │ Tutor Chat    │  ← Small text payloads   │
│  │ Panel         │    to Claude API          │
│  └──────┬───────┘                           │
│         │                                    │
└─────────┼────────────────────────────────────┘
          │
          ▼
┌──────────────────┐
│ Claude API        │
│                   │
│ Context:          │
│ - Exercise prompt │
│ - Student's query │
│ - Query results   │
│ - Error messages  │
│ - Hint history    │
│                   │
│ System prompt:    │
│ "You are a SQL    │
│  tutor. Never     │
│  give the answer. │
│  Ask questions    │
│  that lead to     │
│  understanding."  │
└──────────────────┘
```

**Key design decisions:**
- SQL execution is always local (WASM) — fast, free, no data leaves the browser
- Only the tutoring conversation hits the API — small text payloads
- The tutor has full context: exercise description, student's query, results, error messages
- System prompt enforces pedagogical approach (Socratic, never gives answers directly)

### Cost Model

A typical tutoring exchange is ~500-1,500 tokens. At Claude API pricing:
- ~$0.001-0.005 per interaction
- A student doing 22 exercises with heavy tutoring: ~$0.10-0.50 total
- 1,000 students completing a full course: ~$100-500

**Pricing tiers:**
- **Free tier**: Static hints only (fully WASM, no API calls, no cost)
- **Tutored tier**: AI tutor enabled (~$5/month or per-course fee)
- **Institutional tier**: Bulk pricing for universities/bootcamps

### Tutor Capabilities Beyond Q&A

- **Error explanation**: Student gets a SQL error → tutor explains it in context of what they were trying to do
- **Query review**: Student gets the right answer → tutor asks "could you do this without a subquery?" or "what happens if there are ties?"
- **Adaptive hints**: If the student is stuck after 3 attempts, hints become more specific
- **Progress awareness**: Tutor knows which exercises the student has completed and can reference prior concepts
- **Misconception detection**: Common SQL mistakes (GROUP BY without aggregate, comparing to NULL with =) get targeted explanations

---

## Concept 3: Universal Interactive Content Blocks

### The Idea

Don't build whole apps. Build embeddable blocks that any educator can drop into any platform.

```
Blog post text here...

[Interactive SQL Block]
  Dataset: dim_ward, fact_admission
  Starter query: SELECT ward_name, total_beds FROM dim_ward
  Challenge: Which ward has the highest occupancy rate?
  Hints: enabled
  AI Tutor: enabled
[/Interactive SQL Block]

More blog post text explaining the concept...
```

The block is self-contained: CodeMirror editor + WASM runtime + dataset + optional AI tutor. Hosted centrally, embedded via iframe/oEmbed.

### Where It Works

| Platform | Embedding Method |
|----------|-----------------|
| Medium | oEmbed via CodeSandbox/Observable, or custom Embedly provider registration |
| WordPress | Custom Gutenberg block, or iframe embed |
| Ghost | HTML card with iframe |
| Substack | Embed link (limited) |
| Canvas/Moodle/Blackboard | LTI integration |
| Any website | iframe or Web Component (`<wasm-exercise />`) |

### Block Types

**SQL Exercise Block**
- Dataset + editor + results table
- Optional: hints, solution reveal, AI tutor

**Python Exercise Block**
- Pyodide runtime + editor + output panel
- Supports pandas, matplotlib, plotly output
- Optional: test assertions for grading

**R Exercise Block**
- webR runtime + editor + output/plot panel
- Supports ggplot2, dplyr, tidyr
- Optional: grading via testthat-style assertions

**Visualization Block**
- Read-only or editable D3/Plotly/Observable Plot
- Student modifies parameters, sees result update
- Good for teaching chart design, statistical concepts

**Multi-Step Exercise Block**
- Chained exercises where output of step N feeds into step N+1
- Progress tracking across steps
- Good for building up complex queries incrementally

### Educator Authoring

Educators don't write code. They describe the block in a simple config (YAML, form UI, or conversation with Claude), and the system generates it.

```yaml
# block.yaml
type: sql_exercise
dataset:
  tables: [dim_ward, fact_admission, fact_discharge]
  source: nhsdb  # references a published dataset
challenge: "Which ward has the highest occupancy rate?"
starter_query: "SELECT ward_name, total_beds FROM dim_ward"
hints:
  - "Occupancy = patients / beds. Where do you find current patient counts?"
  - "Think about which patients are admitted but not yet discharged."
  - "You'll need to join admissions to ward assignments."
tutor: true
difficulty: intermediate
```

---

## What Makes This Different From Existing Tools

| Aspect | Existing Tools | This Concept |
|--------|---------------|-------------|
| Who it's for | Developers who teach | Educators who may not code |
| Content creation | Manual authoring | AI-assisted generation + educator review |
| Student support | Static hints | Adaptive AI tutor |
| Data | Bring your own | AI-generated synthetic data (Fabulexa) |
| QA | Manual testing | AI QA pass (data/narrative consistency) |
| Platform | One (Quarto, Jupyter, etc.) | Embeddable anywhere (Medium, WP, LMS) |
| Languages | Usually one per tool | SQL, Python, R from one system |
| Cost to student | Free (no server) or paid (server) | Free for execution, optional paid tutoring |
| Setup for educator | Install tools, learn build system | Describe what you want to teach |

---

## The Stack

```
Content Generation:
  └─ Claude API — exercise design, hints, solutions, QA
  └─ Fabulexa — synthetic data for any domain (YAML-configured)

Execution (Client-Side, Free):
  └─ sql.js / DuckDB-WASM — SQL
  └─ Pyodide — Python
  └─ webR — R
  └─ D3 / Plotly.js / Observable Plot — visualization (native JS)

Editor:
  └─ CodeMirror 6 — syntax highlighting, autocomplete, themes

Tutoring:
  └─ Claude API — Socratic tutoring with exercise context

Embedding:
  └─ oEmbed — Medium, WordPress, and 300+ Embedly providers
  └─ LTI — Canvas, Moodle, Blackboard, Brightspace
  └─ iframe / Web Component — everything else

Hosting:
  └─ Static content: GitHub Pages, Netlify, Vercel, Cloudflare Pages
  └─ Tutor API: lightweight proxy to Claude API (auth + rate limiting)

Auth:
  └─ Clerk / Auth.js — user authentication
  └─ Signed JWTs with expiry — for embed URLs and API access
  └─ Stripe — payments for tutored tier
```

---

## Phased Build Plan

### Phase 1: AI Content Compiler (MVP)

Build a CLI tool or Claude Code workflow that takes `course.yaml` and produces a deployable interactive site — the same structure as the NHS project but generated in minutes.

- Input: course.yaml + Fabulexa domain config
- Output: exercises.md, build_db.sql, data/, index.html, qa.md
- Educator reviews and iterates via conversation with Claude
- Deploy to GitHub Pages
- Embed in Medium via CodeSandbox or Observable

**Proves the concept. The NHS project already demonstrates this is viable — dataset + 22 exercises + interactive app + QA in ~4 days. The compiler formalizes the process so it's repeatable by anyone.**

### Phase 2: Embeddable Widget Service

Extract the interactive exercise into a hosted, embeddable widget.

- Widget builder: config → embed URL
- oEmbed provider registration (enables native Medium/WordPress embeds)
- Auth layer for gated content (signed, expiring URLs)
- Multiple runtime support (SQL, Python, R)

**Unlocks distribution. Any educator can embed exercises in any platform.**

### Phase 3: AI Tutor Integration

Add the Claude-powered tutor to the widget.

- Tutor chat panel in the exercise UI
- Lightweight API proxy (auth, rate limiting, system prompt injection)
- Free tier (static hints) + tutored tier (AI tutor)
- Stripe integration for payments

**The differentiator. Static exercises are commoditized. Adaptive tutoring is not.**

### Phase 4: LTI Provider (Institutional)

Wrap the widget in the LTI protocol for LMS integration.

- LTI 1.3 provider
- Grade passback (exercise completion → LMS gradebook)
- Analytics dashboard for instructors
- Bulk licensing for institutions

**Revenue at scale. Universities and bootcamps pay for LMS-integrated tools.**

### Phase 5: Educator Marketplace

Let educators publish and sell their own interactive content through the platform.

- Educator creates content via AI Content Compiler
- Publishes to marketplace (free or paid)
- Revenue share model
- Community ratings and reviews
- Domain coverage expands without you creating every course

---

## Open Questions

1. **Offline / export**: Should students be able to download exercises for offline use? WASM apps can work offline via service workers, but the AI tutor needs connectivity.

2. **Progress persistence**: Where does student progress live? LocalStorage (simple, no account needed), or server-side (requires auth, enables cross-device)?

3. **Multi-language exercises**: Same dataset, same question, solve in SQL then Python then R? Valuable for teaching the same concept across languages.

4. **Collaborative exercises**: Could two students work on the same exercise simultaneously? WebRTC for state sync, no server needed.

5. **Assessment / certification**: Could exercise completion feed into verifiable credentials or certificates?

6. **Content licensing**: If Claude generates exercises, who owns them? The educator who prompted, the platform, or public domain?

7. **Accessibility**: Screen reader support for the editor and results. Keyboard navigation. High-contrast themes.

8. **Internationalization**: Exercises in multiple languages. Claude can translate, but domain-specific terminology needs expert review.
