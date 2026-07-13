# Evidence Workflow Reference

Use this reference when designing a case-evidence update, selecting claim strength, or validating generated artifacts.

## 1. Material-to-claim audit

Do not begin with predefined source categories. Build the mapping from the current thesis's research question, methods, and analytical framework.

For each material, complete an audit row:

| Field | Question |
| --- | --- |
| Material and provenance | What is the exact file, issuing/collecting body, date, and version? |
| Unit of analysis | What does one row, record, case, document, or observation represent? |
| Coverage | Which population, period, process, or selected cases are included and excluded? |
| Directly observable content | What can be read or calculated without additional assumptions? |
| Intended claim | Which precise正文 statement will this material support? |
| Unsupported inference | What stronger conclusion would exceed the material? |
| Processing state | Is it original, desensitized, derived, incomplete, or a blank template? |
| Verification state | Was it machine-checked, locally inspected, or manually confirmed by the user? |

Choose the narrowest verb warranted by that audit. Use `记录`, `显示`, `可计算`, `支持分析`, or similarly bounded wording according to what the current source actually contains. Do not use `证明整体有效`, `全面实现`, or `普遍形成` unless coverage and method genuinely support those conclusions.

Never reuse project-specific labels such as `规则设计材料` as universal evidence types. If the current thesis uses such a label, verify that its research design defines the category and explains why the source belongs to it.

## 2. Transformation contract

Define these items before coding:

1. Unit of analysis: item, warning, case, department, period, or transaction.
2. Denominator: full population, available sample, or selected typical cases.
3. Classification, if used: one primary category, multi-label, or hierarchical categories.
4. Compound-case treatment, if classification is used: primary category only, duplicate counting, or separate dimensions.
5. Missing-value treatment: preserve as `未明确` or `待补充`; do not force into a substantive class.
6. Privacy transformation: replacement rules for place, person, enterprise, project, and business identifiers.
7. Source version: path, modification time, sheet/table name, and optional hash.

Add invariants to the generator, for example:

```python
assert len(items) == expected_items
assert stats["count"].sum() == len(items)
assert not missing_required_columns
assert not unclassified_item_ids
```

If the source is expected to evolve, expose expected counts as configuration or compare them with a recorded manifest. Do not silently continue after a structural change.

## 3. Output contract

For each analytical object, prefer one reproducible chain:

```text
source material
  -> desensitized working copy when needed
  -> derived CSV
  -> PNG/SVG figure or Markdown table
  -> chapter interpretation and citation
  -> Word export
```

The manifest should record:

- display title;
- derived data path;
- data nature, such as real desensitized data or template;
- source material;
- generation script;
- output files;
- evidence-boundary note.

For Word-oriented figures, use a stable physical width and high-resolution PNG. A prior successful project used 450 DPI and approximately 14.82 cm image width inside a 16 cm text area; treat those values as a tested example and re-check the current school template.

## 4. Appendix design

Derive appendix contents from the current study's reproducibility and disclosure needs. Possible contents include source descriptions, coding rules, research instruments, supplementary tables, desensitized samples, or data-entry templates, but none is mandatory across all MPA theses.

Use `脱敏样例 + 可补录模板` only when it fits the study design and full records are unavailable. Separate a very wide process ledger into sequential tables linked by a stable record ID. Preserve empty cells as fields to be completed, not implied facts.

## 5. Citation and verification states

Maintain distinct states:

| State | Meaning |
| --- | --- |
| `待核验` | metadata or source content is incomplete |
| `本地材料初核通过` | local file and citation mapping were checked |
| `人工校验=是` | the user actually performed or confirmed manual verification |

When adding an internal-data reference:

1. Add its正文 citation.
2. Add the full reference entry.
3. Add one ledger row with the truthful verification state.
4. Save the original/desensitized file and a short source note under the matching reference ID when the project uses per-reference folders.
5. Resynchronize locations after line numbers move.

## 6. Build order and acceptance checks

Run the project equivalents of:

```text
desensitize -> generate data/figures -> sync citations -> merge chapters -> export Word -> verify
```

Acceptance checks:

1. Source, CSV, table, and figure totals agree.
2. Every generated artifact can be traced to a source and script.
3.正文/reference/CSV numbering agrees and has no unintended gaps.
4. Prohibited identifiers have zero hits in formal and derived outputs.
5. Warnings are described as leads, not findings.
6. Typical cases are not generalized to the full item population.
7. Template blanks are not narrated as completed work.
8. Captions are not duplicated in Word.
9. Images are embedded rather than externally linked.
10. Wide tables fit the page and references remain in the required final position.
11. The latest merged Markdown and Word files postdate the latest chapter/source edit.
12. Hashes match when two paths are intended to hold the same deliverable.

## 7. Common failures

- **Polished chart, weak provenance**: create the derived CSV and manifest before styling the chart.
- **One script run changes the paper but not the ledger**: treat citation sync, merge, and export as mandatory downstream dependencies.
- **A warning count becomes a performance claim**: restate it as distribution within the available warning records and disclose coverage.
- **A typical case becomes evidence of universal closure**: limit the claim to the documented case and list missing population-level ledgers.
- **A template looks like collected data**: label it as a template in the title, note, and manifest.
- **Manual verification counts rise after automation**: revert the status unless the user actually verified the source.
- **Word looks structurally valid but layout is unknown**: inspect page rendering when a renderer is available; otherwise report the gap explicitly.
- **Chinese paths fail in PowerShell**: discover paths from an ASCII parent and use UTF-8 script files instead of embedding Chinese literals in one-line commands.
