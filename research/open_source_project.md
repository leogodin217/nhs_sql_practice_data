# Open Source Project: Interactive Education Framework

Concept exploration from 2026-03-11. What would an open source project look like that lets educators create interactive, WASM-powered tutorials, courses, and blog posts?

---

## What the Project Is

A static site generator purpose-built for interactive educational content. Educators provide a dataset and exercises in a standard format. The tool produces a deployable, browser-based learning environment with in-browser code execution.

Think Hugo or Eleventy, but for interactive exercises instead of blog posts.

```
educator provides:          the tool produces:
  content/                    dist/
    config.yaml                 index.html
    data/                       assets/
      patients.csv                runtime.wasm
      admissions.csv              editor.js
    exercises.md                  styles.css
                                data/
                                  patients.csv
                                  admissions.csv
```

One command:

```bash
npx learnql build
# or
learnql build --serve
```

Output is a static site. Deploy anywhere. No backend.

---

## Project Structure

```
learnql/                          # working name
├── packages/
│   ├── core/                     # build system, config parsing, exercise spec
│   ├── runtime-duckdb/           # DuckDB-WASM adapter
│   ├── runtime-sqlite/           # sql.js adapter
│   ├── runtime-pyodide/          # Pyodide adapter
│   ├── runtime-webr/             # webR adapter
│   ├── ui/                       # editor, results, hints, exercise chrome
│   ├── theme-default/            # default look and feel
│   └── plugin-tutor/             # optional AI tutor integration (Claude API)
├── templates/
│   ├── single-page/              # all exercises on one page (like NHS project)
│   ├── course/                   # multi-page with navigation and progress
│   └── embed/                    # minimal, designed for iframe embedding
├── content/                      # example content packages
│   ├── nhs-sql-practice/         # the NHS dataset (this project)
│   ├── starter-sql/              # simple intro SQL course
│   └── pandas-basics/            # intro Python/pandas course
├── docs/
│   ├── authoring-guide.md        # how to write exercises (for educators)
│   ├── content-spec.md           # formal exercise format specification
│   ├── runtime-guide.md          # how to add a new language runtime
│   └── theming.md                # how to customize appearance
└── create-learnql/               # scaffolding CLI (npx create-learnql)
```

Monorepo. Each package is independently versioned and published. Educators only install what they need — a SQL course doesn't pull in Pyodide.

---

## The Exercise Format (Content Spec)

This is the most important design decision. Get this right and the ecosystem builds itself. Get it wrong and nobody contributes.

### Principles

- **Markdown-first**: Educators already know Markdown. Exercises live in .md files with YAML frontmatter.
- **No code required**: An educator should never need to write JavaScript, HTML, or build configs.
- **Progressive disclosure**: Simple exercises need minimal config. Advanced features are opt-in.
- **Portable**: The format should be useful even without the tool — it's just readable Markdown.

### Minimal Exercise

```markdown
---
title: "How many patients does the trust serve?"
difficulty: beginner
---

The Chief Operating Officer asks: "How many patients does this trust actually serve?"

Write a query to answer this question.

:::hints
- Look at `dim_patient` — but how many rows does it really have vs. how many *patients*?
- The table uses SCD-2 (slowly changing dimension). The same patient can have multiple rows.
- `COUNT(DISTINCT id)` might be useful.
:::

:::solution
```sql
SELECT COUNT(DISTINCT id) AS patient_count
FROM dim_patient;
```
:::

:::discussion
This seems simple, but it tests whether you noticed the SCD-2 design.
The table has 7,380 rows but only 5,386 distinct patients. If you just
ran `COUNT(*)`, you'd overcount by 37%.

In real NHS data, patient master indexes have the same issue — merges,
splits, and historical records inflate row counts.
:::
```

### Full-Featured Exercise

```markdown
---
title: "Are we hitting the 4-hour A&E target?"
difficulty: intermediate
topics: [joins, timestamps, date-arithmetic, nhs-targets]
tables: [fact_ed_arrival, fact_ed_assessment, fact_discharge]
starter_query: |
  SELECT *
  FROM fact_ed_arrival
  LIMIT 10;
validation:
  # optional automated grading
  must_contain: ["COUNT", "4"]
  result_check:
    column: pct_within_4hrs
    expected_range: [70, 80]
---
```

### Config File

```yaml
# config.yaml
title: "SQL Practice: NHS Hospital Analytics"
subtitle: "Millbrook NHS Trust (simulated)"
language: sql
runtime: duckdb           # or: sqlite, pyodide, webr
theme: default            # or: minimal, nhs, custom
data:
  format: csv             # or: parquet, sqlite
  path: ./data/
exercises: ./exercises.md # single file, or ./exercises/ directory
options:
  show_tables_on_load: true
  max_query_timeout: 10000
  max_result_rows: 500
```

That's it. An educator creates config.yaml, drops CSVs in data/, writes exercises in Markdown, runs `learnql build`.

---

## What Each Package Does

### core

- Parses config.yaml and exercise files
- Validates content against the spec
- Orchestrates the build: selects runtime, assembles template, bundles assets
- CLI: `learnql build`, `learnql serve`, `learnql validate`

### runtime-* (pluggable adapters)

Each adapter implements a common interface:

```typescript
interface Runtime {
  name: string;
  init(data: DataSource[]): Promise<void>;
  execute(code: string): Promise<ExecutionResult>;
  reset(): Promise<void>;
  destroy(): Promise<void>;
}

interface ExecutionResult {
  columns: string[];
  rows: any[][];
  rowCount: number;
  executionTime: number;
  error?: string;
}
```

Adding a new language means implementing this interface and writing the WASM initialization logic. The rest of the system doesn't care what language is executing.

**Shipped runtimes:**
- `runtime-duckdb` — analytical SQL, Parquet support, window functions
- `runtime-sqlite` — standard SQL, lightweight, fast startup
- `runtime-pyodide` — Python with pandas, matplotlib, scikit-learn
- `runtime-webr` — R with tidyverse, ggplot2

**Community could add:**
- `runtime-lua` — via Wasmoon
- `runtime-go` — via Go WASM
- `runtime-rust` — via Rust WASM

### ui

Framework-agnostic UI components (vanilla JS or Web Components):
- Code editor (CodeMirror 6 with language-appropriate syntax highlighting)
- Results table (sortable, scrollable, NULL styling)
- Hints/solution/discussion collapsibles
- Exercise navigation
- Loading overlay with progress bar
- Error display

Themeable via CSS custom properties. The NHS project's blue header and layout is one theme. Educators can create their own.

### plugin-tutor (optional)

AI tutoring integration. Requires a Claude API key (educator provides their own, or uses a hosted proxy).

- Chat panel in the exercise UI
- Sends exercise context + student query + results to Claude
- System prompt enforces Socratic teaching approach
- Configurable in config.yaml:

```yaml
tutor:
  enabled: true
  provider: claude          # or: openai, local (future)
  model: claude-sonnet-4-6  # fast, cheap, good enough for tutoring
  style: socratic           # never gives answers directly
  api_key_env: CLAUDE_API_KEY
```

This is a plugin, not core. The tool works perfectly without it — just like the NHS project works today with static hints.

### create-learnql (scaffolding)

```bash
npx create-learnql my-sql-course

# Interactive prompts:
#   Language? [sql / python / r]
#   Runtime? [duckdb / sqlite]  (for sql)
#   Include example exercises? [yes / no]
#   Include AI tutor? [yes / no]

# Creates:
#   my-sql-course/
#     config.yaml
#     data/          (empty, or with example data)
#     exercises.md   (empty template, or example exercises)
#     README.md
```

---

## Content Packages (Shareable Courses)

A content package is just a directory with config.yaml + data + exercises. It can be:
- A git repo
- An npm package
- A zip file

### Registry

No centralized registry needed at first. Content packages are just GitHub repos. A curated list (awesome-learnql) links to community-created courses.

Later, if the ecosystem grows:
- `learnql install nhs-sql-practice` pulls a package from a registry
- Educators can publish: `learnql publish`
- Versioned, so exercises can be updated without breaking embedded links

### Example Content Packages

| Package | Language | Domain | Exercises | Level |
|---------|----------|--------|-----------|-------|
| nhs-sql-practice | SQL | Healthcare (NHS) | 22 | Beginner-Intermediate |
| retail-analytics | SQL | Retail / E-commerce | 15 | Beginner |
| saas-metrics | SQL | SaaS / Subscriptions | 18 | Intermediate |
| pandas-fundamentals | Python | General data science | 20 | Beginner |
| tidyverse-intro | R | General data science | 15 | Beginner |
| clinical-trials | Python | Pharma / Biostatistics | 12 | Advanced |

Fabulexa can generate the datasets for any of these domains. Pair it with Claude to generate the exercises. An educator with domain expertise could produce a complete course in days.

---

## Embedding and Distribution

### Static Hosting (Default)

`learnql build` produces a static site. Deploy to GitHub Pages, Netlify, Vercel, Cloudflare Pages. No server. Free hosting.

### Embeddable Mode

`learnql build --template embed` produces a minimal version designed for iframe embedding:
- No header, no navigation — just the exercise
- Accepts URL parameters: `?exercise=5`, `?theme=dark`
- PostMessage API for parent page communication (resize, completion events)
- Small footprint

### Medium / Blog Embedding

Two paths:
1. **Host on CodeSandbox or Observable** → paste URL in Medium → auto-embeds
2. **Register as an Embedly provider** → any URL from the hosted service auto-embeds in Medium, WordPress, and 300+ other platforms

### LMS Integration (LTI)

A separate package (`plugin-lti`) wraps the exercises in LTI 1.3:
- Works with Canvas, Moodle, Blackboard, Brightspace
- Grade passback (exercise completion → LMS gradebook)
- Roster integration
- Deep linking (instructor selects specific exercises)

---

## AI Integration Points (All Optional)

The framework works without any AI. But Claude enhances every stage:

### Authoring Time (Educator + Claude)

1. **Exercise generation**: Claude generates exercises from a topic list + dataset schema
2. **Hint writing**: Claude writes progressive hints that teach without revealing
3. **Solution generation**: Claude writes multiple solution approaches
4. **QA**: Claude checks data/narrative consistency, terminology, ordering issues
5. **Dataset generation**: Claude + Fabulexa produce realistic synthetic data from a domain description

These happen before the course is published. No API key needed at runtime. The output is plain Markdown.

### Runtime (Student + AI Tutor)

1. **Socratic tutoring**: Student asks questions, Claude guides without giving answers
2. **Error explanation**: Claude explains SQL/Python/R errors in context
3. **Query review**: Claude suggests improvements to working solutions
4. **Adaptive difficulty**: Claude adjusts hint specificity based on student attempts

This requires a Claude API key and costs money per interaction. It's a plugin, not core.

### The Separation Matters for Open Source

- Core framework: MIT license, no API dependencies, works offline, free forever
- AI plugins: Same license, but require API keys to function
- Content packages: Educator chooses their own license (CC-BY, CC-BY-SA, etc.)

Educators in resource-constrained settings (developing countries, underfunded schools) get the full framework and community content for free. AI tutoring is an enhancement, not a requirement.

---

## Technology Choices

| Component | Choice | Why |
|-----------|--------|-----|
| Build system | Vite | Fast, modern, good WASM support, familiar to contributors |
| Package management | pnpm workspaces | Monorepo-friendly, fast, disk-efficient |
| Language | TypeScript | Type safety for the framework, good editor support |
| Editor component | CodeMirror 6 | Best-in-class, extensible, language-agnostic |
| Markdown parsing | unified/remark | Extensible, supports custom directives (:::hints) |
| Templating | Plain HTML + CSS custom properties | No framework dependency in output, smallest bundle |
| Testing | Vitest | Fast, Vite-native, good for monorepo |
| Docs | VitePress or Starlight | Docs-as-code, familiar to JS ecosystem contributors |

### Why Not Astro/Next.js/etc?

The output should be framework-free. The generated site is vanilla HTML + JS + WASM. No React, no Vue, no Svelte in the output. This keeps the bundle small, avoids framework churn, and makes themes simple (just CSS). The build tool uses Vite internally, but the output has zero framework dependencies.

---

## Governance and Community

### License

MIT for the framework. Content packages choose their own license.

### Contribution Paths

Different people contribute different things:

| Contributor | What they add |
|-------------|--------------|
| Educators | Content packages (datasets + exercises) |
| Developers | Runtime adapters, plugins, themes, core features |
| Designers | Themes, accessibility improvements |
| Translators | Exercise translations, UI localization |
| Domain experts | QA on content packages (is the NHS terminology correct?) |

### What Makes People Contribute?

- **Educators contribute content** because they want a good interactive format for their teaching and they want their course to be discoverable.
- **Developers contribute code** because it's a well-scoped, useful project with clear contribution boundaries (write a runtime adapter, build a theme).
- **The NHS project is the flagship example** — it demonstrates what's possible and gives new contributors a concrete reference.

### Governance Model

Start simple: benevolent dictator (you) + a few maintainers for specific packages. Formalize later if the community grows. An RFC process for spec changes (exercise format, runtime interface) since those affect everyone.

---

## What Success Looks Like

### 6 Months

- CLI tool works: `learnql build` produces a working site from config + data + exercises
- 3-5 content packages (NHS, retail, one Python, one R)
- Runtimes: DuckDB-WASM, sql.js, Pyodide
- Documentation good enough for educators to use without help
- Deployed NHS project as the showcase

### 1 Year

- 20+ community content packages across domains
- webR runtime shipped
- AI tutor plugin working
- Embeddable mode with oEmbed support
- Used in at least one university course

### 2 Years

- LTI integration for LMS platforms
- Content marketplace or curated registry
- Multiple themes (accessibility-focused, dark mode, institutional branding)
- Recognized as the standard way to create interactive coding exercises

---

## Open Questions

1. **Name**: "learnql" is SQL-centric but the project supports Python and R. Alternatives: "learnbox", "codelearn", "wasm-exercises", "interactivist", or something entirely different. The name matters for discoverability and identity.

2. **Monorepo vs multi-repo**: Monorepo is easier to maintain early. Could split later if packages diverge significantly.

3. **Exercise format extensibility**: How do educators add custom exercise types (multiple choice, fill-in-the-blank, drag-and-drop) without forking the core?

4. **Grading API**: If exercises have automated validation, what does the grading interface look like? Simple (pass/fail) or rich (partial credit, feedback messages)?

5. **State persistence**: Where does student progress live? Options: localStorage (simplest), URL hash (shareable), IndexedDB (more storage), server (requires auth). Different templates may want different defaults.

6. **Offline support**: Service workers could make the entire site work offline (including WASM execution). Worth building in from day one or adding later?

7. **Content versioning**: If an educator updates their exercises, what happens to students mid-course? Semantic versioning of content packages?

8. **Internationalization**: The framework UI needs i18n. Exercise content i18n is harder — Claude can translate, but domain terminology needs expert review.

9. **Accessibility**: WCAG compliance for the editor, results table, and exercise navigation. CodeMirror 6 has good a11y foundations, but the surrounding UI needs careful attention.

10. **Python/R package management**: For Python exercises, which packages are pre-loaded vs loaded on demand? Educators need a way to declare dependencies (`requires: [pandas, matplotlib]`) without understanding Pyodide internals.
