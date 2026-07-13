---
name: chinese-mpa-evidence-pipeline
description: Convert Chinese MPA thesis case materials into traceable evidence tables, figures, appendices, citations, and synchronized Markdown/Word outputs. Use when working with internal workbooks, warning logs, supervision-item lists, case documents, evidence manifests, citation ledgers, anonymization, 图表化, 附录模板, 引文同步, or final export verification, especially when claims must stay within strict evidence boundaries.
---

# Chinese MPA Evidence Pipeline

Turn case materials into auditable thesis evidence without overstating what the materials prove.

## Start From The Live Workspace

1. Read the workspace `AGENTS.md` and obey local encoding, naming, theory, anonymization, and export rules.
2. Inspect the current `plan/`, `chapters/`, `refs/`, source workbooks/documents, scripts, and generated outputs before editing.
3. Read the latest task packet, progress log, notes, citation ledger, and evidence manifest if they exist.
4. Recalculate current counts and statuses. Treat prior counts as examples, not constants.
5. Use UTF-8 explicitly for Chinese text and avoid printing long files or tables to the console.

## Map Materials To Claims Before Writing

Do not impose a fixed evidence-layer taxonomy from another thesis. Derive the role of each material from the current research question and study design.

For every source, record:

1. the unit of analysis and time or population coverage;
2. the content directly observable in the material;
3. the claim for which the material will be used;
4. the inference the material cannot support on its own;
5. its provenance, anonymization, and verification state.

Treat labels such as `规则设计材料`, `运行线索材料`, or `闭环材料` as project-specific analytical decisions. Use them only when the current manuscript has established and justified those categories. State each source's proving scope near the relevant table, figure, or claim. Read [references/evidence-workflow.md](references/evidence-workflow.md) when mapping claims, planning outputs, or validating artifacts.

## Create A Task Contract

Before a substantial evidence update, create or refresh a task packet containing:

- scope and source files;
- files allowed to change;
- classification and aggregation rules;
- generated artifacts;
- rejection checks for privacy, unsupported claims, and stale outputs;
- exact validation commands.

Keep manuscript facts, workflow notes, and review records in their established locations. Do not leak process language into formal chapters.

## Build Reproducible Evidence

1. Use structured parsers for XLS/XLSX, DOCX, CSV, and Markdown. Do not derive structured statistics with ad hoc string slicing when a parser is available.
2. Desensitize raw operational material before analysis or publication. Remove real place names, full personal names, enterprise/project identifiers, and traceable business numbers according to project rules.
3. If the analysis uses classification, encode the current study's classification rules explicitly in a script. For a primary-category summary, assign one primary class per item; disclose how compound cases are handled.
4. Add assertions for expected row counts, totals, missing classifications, required columns, and output existence. Fail loudly when source structure changes.
5. Write machine-readable derived data first, then generate figures and narrative from the same data.
6. Preserve traceability with a manifest linking each figure/table to its derived data file, source, generation script, and output.

Prefer these output roles when the workspace supports them:

- UTF-8-SIG CSV for reviewable statistics;
- high-resolution PNG for Word embedding;
- SVG as an optional scalable companion;
- XLSX templates for later data completion;
- a Markdown manifest for provenance and evidence limits.

## Integrate With The Thesis

1. Introduce each table or figure with its statistical scope, denominator, and any applicable classification rule.
2. Follow it with interpretation, not a repetition of labels.
3. Keep the evidence limit close to the claim: `线索不等于结论`, `典型案例不代表全部事项`, and `材料缺失不等于工作未开展` when applicable.
4. Cite internal materials as formal sources when they support正文 claims.
5. Place appendices after the conclusion and before the references unless the school template requires another order.
6. Split wide appendix tables into linked tables suitable for the Word text area; use six columns or fewer as a conservative default when no template-specific limit exists.
7. Use either Markdown-generated captions or manual captions consistently so exported Word files do not duplicate titles.

## Keep The Citation System Synchronized

For every added or removed source, update all applicable layers together:

-正文 citation;
- references chapter;
- citation-verification CSV;
- local verification/original-material directory;
- merged manuscript and exported Word files.

Mark internal or desensitized material as locally checked only when the files were actually inspected. Keep manual verification as `否` until the user performs it. Never promote incomplete metadata or local machine checks to user-confirmed verification.

## Refresh Outputs In Dependency Order

After chapter or evidence changes, run the workspace's existing equivalents in this order:

1. regenerate desensitized/derived data and figures;
2. synchronize citation locations and per-reference notes;
3. merge chapters;
4. export the formatted Word document;
5. verify copied/root deliverables are identical when the project maintains duplicates.

Reuse project scripts and naming conventions. Do not create a parallel pipeline unless the existing one cannot represent the required artifact.

## Verify Before Claiming Completion

Check at least:

- source totals equal derived-data totals and figure totals;
-正文 citations, references, and ledger rows have matching numbers;
- no citation location is blank and no manual-verification state changed unintentionally;
- anonymized outputs contain no prohibited identifiers;
- charts are legible, correctly sized, and genuinely embedded in DOCX;
- figure captions occur once, appendix tables fit the target layout, and references remain last;
- merged Markdown and Word outputs were regenerated after the latest source edit;
- duplicated deliverables have matching hashes when expected;
- style checks and targeted scans find no process contamination or banned theory labels;
- residual limits are reported, including missing full-population logs, pending manual checks, and absent page-render inspection.

If Word or LibreOffice rendering is unavailable, report that structural DOCX checks passed but page-level visual inspection remains outstanding.

## Report The Result

Lead with what changed. Report artifact paths, record counts, figure/table counts, citation totals, verification states, and remaining evidence limits. Do not print large generated tables or document bodies to the console.
