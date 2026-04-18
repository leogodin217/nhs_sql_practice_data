#!/usr/bin/env python3
"""Generate the markdown data dictionary from schema/tables.yaml and the CSVs.

Curated prose (table descriptions, column descriptions, relationships) lives in
schema/tables.yaml. Live statistics (row counts, null %, distinct counts,
ranges, sample values) are pulled from the CSVs with DuckDB and merged at
render time. Re-run after regenerating the dataset.
"""
from __future__ import annotations

from pathlib import Path

import duckdb
import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data"
OUT_DIR = REPO_ROOT / "docs" / "data_dictionary"
SCHEMA_FILE = REPO_ROOT / "schema" / "tables.yaml"

LOW_CARD_THRESHOLD = 25
MAX_SAMPLE_VALUES = 8
MAX_CELL_CHARS = 60

NUMERIC_TYPES = {"BIGINT", "INTEGER", "SMALLINT", "TINYINT", "HUGEINT",
                 "DOUBLE", "FLOAT", "REAL", "DECIMAL"}
TEMPORAL_TYPES = {"TIMESTAMP", "DATE", "TIME"}


def connect() -> duckdb.DuckDBPyConnection:
    con = duckdb.connect()
    for csv in sorted(DATA_DIR.glob("*.csv")):
        con.execute(
            f"CREATE VIEW {csv.stem} AS "
            f"SELECT * FROM read_csv_auto('{csv.as_posix()}')"
        )
    return con


def table_stats(con, table: str):
    total = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    schema = con.execute(f"DESCRIBE SELECT * FROM {table}").fetchall()

    cols = []
    for row in schema:
        cname, ctype = row[0], row[1]
        null_count, distinct = con.execute(
            f'SELECT SUM(CASE WHEN "{cname}" IS NULL THEN 1 ELSE 0 END), '
            f'COUNT(DISTINCT "{cname}") FROM {table}'
        ).fetchone()
        null_count = null_count or 0
        distinct = distinct or 0
        info = {
            "name": cname,
            "type": ctype,
            "null_count": null_count,
            "null_pct": (100.0 * null_count / total) if total else 0.0,
            "distinct": distinct,
        }

        base_type = ctype.split("(")[0].upper()

        if base_type in NUMERIC_TYPES or base_type in TEMPORAL_TYPES:
            mn, mx = con.execute(
                f'SELECT MIN("{cname}"), MAX("{cname}") FROM {table}'
            ).fetchone()
            info["min"] = mn
            info["max"] = mx
        elif base_type == "BOOLEAN":
            t_count = con.execute(
                f'SELECT SUM(CASE WHEN "{cname}" THEN 1 ELSE 0 END) FROM {table}'
            ).fetchone()[0] or 0
            info["true_pct"] = (100.0 * t_count / total) if total else 0.0
        elif base_type == "VARCHAR":
            if distinct <= LOW_CARD_THRESHOLD:
                rows = con.execute(
                    f'SELECT "{cname}", COUNT(*) AS n FROM {table} '
                    f'WHERE "{cname}" IS NOT NULL '
                    f"GROUP BY 1 ORDER BY n DESC LIMIT {MAX_SAMPLE_VALUES}"
                ).fetchall()
                info["samples"] = [r[0] for r in rows]
                info["samples_exhaustive"] = distinct <= len(info["samples"])
            else:
                rows = con.execute(
                    f'SELECT DISTINCT "{cname}" FROM {table} '
                    f'WHERE "{cname}" IS NOT NULL LIMIT 3'
                ).fetchall()
                info["samples"] = [r[0] for r in rows]
                info["samples_exhaustive"] = False
        cols.append(info)
    return total, cols


def format_scalar(v) -> str:
    if v is None:
        return ""
    if isinstance(v, float):
        if v.is_integer():
            return f"{v:.1f}"
        return f"{v:.2f}"
    return str(v)


def summarise_cell(info: dict) -> str:
    base = info["type"].split("(")[0].upper()
    if base in NUMERIC_TYPES:
        return f"{format_scalar(info.get('min'))} – {format_scalar(info.get('max'))}"
    if base in TEMPORAL_TYPES:
        mn = str(info.get("min") or "")[:19]
        mx = str(info.get("max") or "")[:19]
        return f"{mn} → {mx}" if mn or mx else ""
    if "true_pct" in info:
        return f"{info['true_pct']:.1f}% true"
    samples = info.get("samples") or []
    if samples:
        text = ", ".join(f"`{s}`" for s in samples)
        if not info.get("samples_exhaustive"):
            text += ", …"
        if len(text) > MAX_CELL_CHARS:
            text = text[:MAX_CELL_CHARS - 1].rsplit(",", 1)[0] + ", …"
        return text
    return ""


def render_pk(pk) -> str:
    if isinstance(pk, list):
        return ", ".join(f"`{c}`" for c in pk)
    return f"`{pk}`"


def render_table_page(tdef: dict, stats: list, total: int) -> str:
    name = tdef["name"]
    out = [f"# `{name}`\n"]

    meta = [f"*Group:* {tdef['group']}"]
    if tdef.get("grain"):
        meta.append(f"*Grain:* {tdef['grain']}")
    if tdef.get("primary_key"):
        meta.append(f"*Primary key:* {render_pk(tdef['primary_key'])}")
    meta.append(f"*Rows:* {total:,}")
    out.append("  \n".join(meta) + "\n")

    desc = (tdef.get("description") or "").strip()
    if desc:
        out.append(desc + "\n")

    if tdef.get("notes"):
        out.append("## Notes\n")
        out.append(tdef["notes"].strip() + "\n")

    out.append("## Columns\n")
    out.append("| Column | Type | Null % | Distinct | Range / sample values | Description |")
    out.append("|---|---|---:|---:|---|---|")

    yaml_cols = {c["name"]: c for c in tdef["columns"]}
    for col in stats:
        yc = yaml_cols.get(col["name"], {})
        description = (yc.get("description") or "").strip().replace("|", "\\|")
        ref = yc.get("references")
        if ref:
            if description and description != "TODO":
                description = f"{description} *(→ `{ref}`)*"
            else:
                description = f"FK → `{ref}`"
        if not description:
            description = "TODO"
        null_pct = f"{col['null_pct']:.1f}" if col["null_pct"] else "0"
        out.append(
            f"| `{col['name']}` | `{col['type']}` | {null_pct} | "
            f"{col['distinct']:,} | {summarise_cell(col)} | {description} |"
        )

    rels = [
        (c["name"], yaml_cols[c["name"]].get("references"))
        for c in stats
        if yaml_cols.get(c["name"], {}).get("references")
    ]
    if rels:
        out.append("\n## Relationships\n")
        for col, tgt in rels:
            out.append(f"- `{col}` → `{tgt}`")
        out.append("")

    return "\n".join(out).rstrip() + "\n"


def first_sentence(text: str) -> str:
    text = text.strip()
    if not text or text.startswith("TODO"):
        return "_TODO_"
    first_para = text.split("\n\n")[0].replace("\n", " ").strip()
    for sep in [". ", "; "]:
        if sep in first_para:
            return first_para.split(sep)[0] + "."
    return first_para


def render_index(spec: dict, totals: dict) -> str:
    out = ["# Data dictionary\n"]
    out.append(
        "Per-table reference pages for the Millbrook NHS Trust dataset. "
        "Generated from `schema/tables.yaml` and the CSVs in `data/` by "
        "`scripts/gen_data_dictionary.py` — re-run after any regeneration of "
        "the dataset.\n"
    )
    for group in spec["groups"]:
        group_tables = [t for t in spec["tables"] if t["group"] == group]
        if not group_tables:
            continue
        out.append(f"## {group}\n")
        out.append("| Table | Rows | Summary |")
        out.append("|---|---:|---|")
        for t in group_tables:
            total = totals.get(t["name"], 0)
            summary = first_sentence(t.get("description", ""))
            out.append(f"| [`{t['name']}`]({t['name']}.md) | {total:,} | {summary} |")
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def main() -> None:
    spec = yaml.safe_load(SCHEMA_FILE.read_text())
    con = connect()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    totals: dict[str, int] = {}
    for tdef in spec["tables"]:
        total, stats = table_stats(con, tdef["name"])
        totals[tdef["name"]] = total
        page = render_table_page(tdef, stats, total)
        (OUT_DIR / f"{tdef['name']}.md").write_text(page)
        print(f"wrote docs/data_dictionary/{tdef['name']}.md")

    index = render_index(spec, totals)
    (OUT_DIR / "index.md").write_text(index)
    print("wrote docs/data_dictionary/index.md")


if __name__ == "__main__":
    main()
