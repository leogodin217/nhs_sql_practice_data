# WASM for Interactive Educational Content

Research summary from 2026-03-11. Exploring how far WebAssembly can be pushed for SQL, Python, R, and visualization tutorials/courses/blog posts.

---

## WASM Runtimes Available Today

| Runtime | Language | Bundle (gzip) | First Load | Cached | Maturity |
|---------|----------|--------------|------------|--------|----------|
| sql.js | SQLite | ~1.5 MB | <1s | <0.5s | Excellent |
| DuckDB-WASM | SQL (analytical) | ~2-3 MB | 1-3s | ~1s | Excellent |
| Pyodide | Python (CPython) | ~6.4 MB core | ~5s | ~2s | Good |
| webR | R | ~20-30 MB | 3-5s | ~2s | Good |
| Wasmoon | Lua | <1 MB | <0.5s | <0.2s | Niche |

Additional package sizes when loaded on-demand (Python): NumPy ~7.5 MB, pandas ~13 MB, matplotlib ~11.5 MB, scikit-learn varies.

### Visualization

- **matplotlib** (via Pyodide): Works. Renders to PNG/SVG. Interactive backends limited.
- **Plotly** (via Pyodide): Works well. Python generates JSON specs, Plotly.js (native JS) renders. Interactive charts fully functional. Dash apps can run client-side (wasmdash.vercel.app).
- **ggplot2** (via webR): Works. Quarto Live and Shinylive both support it.
- **D3.js / Observable Plot**: Already native JS -- no WASM needed. Zero overhead. Best option for browser visualization.

---

## Hard Technical Limits

### Memory
- **4 GB hard ceiling** (wasm32, 32-bit pointers).
- Practical browser limits: some mobile browsers cap at 1-2 GB.
- WASM64 (Memory64): Part of WASM 3.0 (finalized Sept 2025). Chrome and Firefox support it, Safari does not. 10-100% performance penalty. Not recommended unless >4 GB is genuinely needed.
- **Memory never shrinks**: Once WASM linear memory grows, it cannot be returned to the OS. Peak usage = consumed for module lifetime. Only recovery is tearing down the module.

### Threading
- Requires **SharedArrayBuffer**, which requires two HTTP headers:
  - `Cross-Origin-Opener-Policy: same-origin`
  - `Cross-Origin-Embedder-Policy: require-corp`
- All cross-origin resources on the page must then opt in via CORS headers.
- GitHub Pages cannot set these headers natively (service worker hack exists: coi-serviceworker).
- **Single-threaded variants of DuckDB-WASM and Pyodide work without these headers.**

### Other Limits
- **No raw sockets** -- only fetch/WebSocket via JS bridge. HTTP(S) only.
- **No real filesystem** -- Emscripten virtual FS (MEMFS, IDBFS, OPFS). OPFS provides persistence but with browser-specific quotas.
- **Package gaps** -- anything requiring system libraries (database drivers, GPU, GUI toolkits) or native threading won't work.
- **CSP** -- WASM execution needs `wasm-unsafe-eval` in Content Security Policy (safer than `unsafe-eval`).

---

## Practical Impact for Educational Content

For datasets under ~50 MB (our largest is 8 MB CSV), **memory and load time are non-issues**:
- 8 MB CSV inflates to ~30-50 MB in memory = <2% of the 4 GB ceiling.
- Load time is solved by lazy loading + progress bar. Readers are reading text while WASM initializes.

| Use Case | Feasibility | Best Runtime |
|----------|-------------|-------------|
| SQL tutorials/courses | Excellent | sql.js or DuckDB-WASM |
| Python data science | Good (5s startup is main friction) | Pyodide |
| R/tidyverse | Good (heavier download) | webR |
| Interactive visualizations | Excellent | JS-native (D3/Plotly) + WASM data layer |
| ML model training | Limited (no threading, 4 GB) | Pyodide for small models only |
| Multi-language in one page | Possible but heavy | Pick one primary runtime |

---

## Existing Platforms

- **Quarto Live** -- closest to a cookie-cutter. R/Python code blocks with exercises, hints, solutions, grading. Static HTML output. No native SQL support.
- **JupyterLite** -- full Jupyter in-browser via Pyodide. Static site deployable.
- **Shinylive** -- R/Python Shiny apps running entirely client-side via WASM.
- **marimo** -- reactive Python notebooks exportable as standalone WASM HTML files.
- **Observable** -- native JS notebooks, integrates DuckDB-WASM for SQL.
- **sql-workbench-embedded** -- lightweight JS library (9.5 KB gzip) that transforms static SQL code blocks into interactive DuckDB-WASM execution environments. Designed for blogs/docs.

---

## Embedding in Medium (and Other CMS Platforms)

### Medium Specifics

Medium uses **Embedly** for embeds. Paste a URL on a blank line -- if it matches a whitelisted provider, it becomes an interactive iframe. **No arbitrary iframes, no custom HTML, no script tags.**

**Platforms that embed in Medium AND can host WASM apps:**

| Platform | WASM Works? | Notes |
|----------|------------|-------|
| CodeSandbox | Yes | DuckDB-WASM examples already exist |
| CodePen | Yes | Good for single-file demos |
| StackBlitz | Yes | Best COOP/COEP support, Node.js-focused |
| Replit | Yes | Full environments, heavier |
| Observable | Yes | Best for data viz + DuckDB-WASM, clean embed UX |
| Glitch | Yes | Full server control |

**Not embeddable in Medium**: GitHub Pages, self-hosted sites, arbitrary URLs (render as link cards only).

### Practical Workflow for Medium

1. Build interactive exercise as static HTML (like our index.html).
2. Host on CodeSandbox (Browser Sandbox) or Observable.
3. Paste URL into Medium post -- auto-embeds.
4. Use single-threaded WASM builds (no special headers needed).

**Observable may be the better fit** for Medium -- embeds cleanly, supports DuckDB-WASM natively, output looks like a polished interactive article rather than a code playground.

**Limitation**: Medium/Embedly caches embed settings. Can't pass query parameters to customize the CodeSandbox embed view.

### General CMS Integration

The most practical approach for any CMS: **host the WASM app separately, embed via iframe.**

- WordPress, Ghost, HubSpot, Contentful all support iframe embeds or custom HTML blocks.
- Direct embedding hits walls with COOP/COEP headers and CSP policies.
- Headless CMS (Contentful, Strapi) are easiest since you control the frontend.

---

## Architecture Options for a Reusable Framework

### Option 1: Embeddable Widget (CMS-Agnostic)

Build once, embed anywhere. Host a service that serves WASM apps via authenticated, expiring URLs. Any CMS embeds via iframe. Most flexible but requires hosting a service.

### Option 2: WordPress Gutenberg Block

Custom block: "Interactive Exercise" with language selector, dataset upload, exercise editor. WordPress handles auth natively. Biggest reach (~40% of web) but WordPress-only.

### Option 3: Headless CMS + Framework Component

Contentful/Strapi content type for exercises + Next.js/Astro frontend with `<WasmExercise />` component. Most control but most engineering work.

### Option 4: LMS Plugin (LTI)

Target LearnDash, Moodle, Canvas via LTI (Learning Tools Interoperability). Build an LTI provider once, works with all major LMS platforms. Auth, payments, progress tracking already exist.

### Recommended Phased Approach

```
Phase 1: Static cookie-cutter (open content)
  - CLI tool: config.yaml + dataset/ + exercises.yaml -> static site
  - Deploy to GitHub Pages / Netlify
  - Embed in Medium via CodeSandbox/Observable

Phase 2: Embeddable widget service (gated content)
  - Same WASM frontend
  - API serves datasets behind auth (signed, expiring URLs)
  - Stripe for payments

Phase 3: LTI provider (institutional)
  - Wrap widget in LTI protocol
  - Sell to universities/bootcamps using Canvas/Moodle
```

**Recommended tech stack**: Astro (static site framework) + CodeMirror 6 (editor) + pluggable WASM runtimes (sql.js/DuckDB-WASM/Pyodide/webR). Auth via Clerk or Auth.js when needed.

---

## Security Considerations

| Concern | Mitigation |
|---------|-----------|
| Content protection | Serve datasets via authenticated, expiring URLs -- not bundled in static HTML |
| XSS from query results | HTML-escape all rendered output |
| CSP for WASM | Set `script-src 'wasm-unsafe-eval'` |
| COOP/COEP | Only needed for threading; iframe from controlled origin solves this |
| Dataset privacy | Anything client-side is extractable. Use synthetic data for sensitive domains. |
| Token security | Signed JWTs with short expiry for embed URLs |
| WASM module integrity | Subresource Integrity (SRI) hashes on CDN-hosted WASM files |
