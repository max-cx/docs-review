# docs-review

A Pi skill that reviews documentation content — pull requests, commits, files, or globs of files — against a set of style guides, using parallel subagents to scan large guides quickly.

The skill ships as a directory containing `SKILL.md`, the style guide sources in `sources/`, and the helper scripts in `scripts/`. Everything it produces (reports, scratch copies of the style guides) stays inside the skill directory.

## How it works

1. **Discover style guides** — every `sources/*.md` file is listed, in alphanumerical order.
2. **Ask which guides to use** — one guide, or all of them sequentially.
3. **Split each guide into 1000-line ranges** and analyze each range against the content under review.
4. **Analyze in parallel** — one task per range via the Pi `subagent` tool (batches of at most 8 tasks, 4 run concurrently). Without the subagent extension, the ranges are analyzed one at a time in the current session.
5. **Merge findings** into one timestamped report with sequential issue numbers, then drop false positives.
6. **Optionally fix** issues one by one (apply / skip / modify).

Subagents inherit the dispatching session's model; the skill never pins a model.

## Requirements

| Dependency | Needed for |
|---|---|
| [Pi](https://github.com/earendil-works/pi) | Running the skill |
| `bash`, `git` | Diffing the content under review, scripts |
| `curl` | PR diffs, URL-based sources, GitHub REST API calls |
| `python3` | JSON digest in the `6-ocp-merge-review.md` workflow |
| [subagent extension](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/subagent) | Parallel range analysis (optional — falls back to sequential) |
| `vale` | Only for `sources/4-vale_linter.md`. The skill aborts that guide and asks you to install Vale if the command is missing |
| `gh` | Not required. `6-ocp-merge-review.md` explicitly warns that the CLI is usually absent and uses the GitHub REST API with `curl` instead |

## Installation

User-level (available in every project):

```bash
cd ~/.pi/agent/skills
git clone git@github.com:max-cx/docs-review.git
```

Project-level (available in one repository):

```bash
mkdir -p .pi/skills
git clone git@github.com:max-cx/docs-review.git .pi/skills/docs-review
```

Pi also discovers the Agent Skills locations `~/.agents/skills/` and `.agents/skills/`. Project-level skills are gated by project trust.

## Usage

```text
/skill:docs-review https://github.com/openshift/openshift-docs/pull/123698
/skill:docs-review 123698
/skill:docs-review HEAD~3..HEAD
/skill:docs-review modules/otel-collector-config-options.adoc
/skill:docs-review            # reviews the latest commit (HEAD)
```

Accepted arguments:

| Argument | Resolution |
|---|---|
| PR URL or number | PR diff |
| Commit ref (`HEAD`, `HEAD~1`, `abc123`) | `git diff` for that commit |
| Commit range (`HEAD~3..HEAD`) | Diff for the range |
| File path or glob (`modules/**/*.adoc`) | File contents |
| Nothing | Latest commit (`HEAD`) |

## Repository layout

```text
docs-review/
├── SKILL.md          # Skill definition: phases, prompts, report format
├── README.md         # This file
├── QUICKSTART.md     # Short walkthrough of a first review
├── CONTRIBUTING.md   # How to add or edit style guides
├── CHANGELOG.md      # Release history
├── LICENSE           # MIT
├── scripts/          # Helper scripts used by SKILL.md
│   ├── discover-sources.sh
│   ├── list-sources.sh
│   ├── setup-diff.sh
│   ├── create-agent-copies.sh
│   ├── create-report.sh
│   └── cleanup-temp.sh
├── sources/          # Style guide source files (see table below)
├── reports/          # Generated reports, review-YYYY-MM-DD-HH:MM:SS.md
└── temp/             # Scratch dir: commit-diff.txt and per-range guide copies
```

`reports/` and `temp/` are created at runtime; `temp/` is deleted by `cleanup-temp.sh` at the end of a run. `.gitignore` currently ignores `sources/`, so guides that are already committed stay tracked but newly added ones need `git add -f` (see [Adding a style guide](#adding-a-style-guide)).

## Style guide sources

| File | Type | Lines | Content |
|---|---|---|---|
| `1-grammar_spelling_punctuation.md` | Embedded rules | 3 | American English grammar, spelling, and punctuation |
| `2-ibm-style-documentation.md` | Embedded rules | 25,238 | IBM Style: table of contents plus full rule text |
| `3-supplementary_style_guide.md` | Embedded rules | 11,102 | Red Hat supplementary style guide for product documentation (overrides IBM Style where they differ) |
| `4-vale_linter.md` | Tool instructions | 11 | Runs Vale with the asciidoctor-dita-vale ruleset; links to that project's README |
| `5-foolproofing.md` | Embedded rule | 1 | Stray copy-paste errors, incomplete changes, duplicate content |
| `6-ocp-merge-review.md` | Tool instructions | 166 | OpenShift docs PR merge checklist, evaluated through the GitHub REST API (8 checklist items, each with a pass condition) |

Three guide shapes are supported, and the skill handles each differently:

- **Embedded rules** — the guide text itself is analyzed. Rules are read by line range; the TOC path in each finding comes from the heading hierarchy.
- **Tool instructions** — the guide describes commands to run. `4-vale_linter.md` runs Vale; `6-ocp-merge-review.md` collects PR metadata with `curl` plus `python3` and rates each checklist item ✔️ / ⚠️ / ❌.
- **URL reference** — a guide may just link to downloadable rules, which are fetched with `curl`. No source currently uses this shape on its own (`4-vale_linter.md` links to the Vale ruleset README as one step of its instructions).

## Scripts

| Script | Arguments | What it does |
|---|---|---|
| `discover-sources.sh` | — | Creates `sources/`, `reports/`, `temp/`; prints each source name without `.md`, or `NO_SOURCES_FOUND` plus the sources path when the directory is empty |
| `list-sources.sh` | — | Prints each source file with its line count (used to compute ranges) |
| `setup-diff.sh` | `<repo path>` | Prints the repo's last commit (`hash subject`), writes `git diff HEAD~1..HEAD` to `temp/commit-diff.txt`, prints the line count |
| `create-agent-copies.sh` | `<source file> <num ranges>` | Copies the guide into `temp/<guide>/agent-<n>.md`, one file per range |
| `create-report.sh` | `"<user request>" "<hash>" "<subject>"` | Creates `reports/review-YYYY-MM-DD-HH:MM:SS.md` with the report header and prints its path |
| `cleanup-temp.sh` | — | Deletes `temp/` |

## Workflow phases

| Phase | What happens |
|---|---|
| 0 | `discover-sources.sh`; a two-level menu asks for all guides or one specific guide (and re-prompts if no sources exist) |
| 1 | `list-sources.sh`, `setup-diff.sh`, `create-report.sh`; issue counter starts at 1 |
| 2 | Per guide: compute `ceil(lines / 1000)` ranges, `create-agent-copies.sh`, analyze every range in one delegation batch, wait for all ranges before the next guide |
| 3 | Parse `---VIOLATION---` blocks, deduplicate per guide, append numbered issues to the report, add "End of report", run `cleanup-temp.sh` |
| 4 | Re-check every issue and remove false positives |
| 4 (same number in `SKILL.md`) | Interactive resolution: for each issue, apply, skip, or modify |

## Report format

Reports are written to `reports/review-YYYY-MM-DD-HH:MM:SS.md`, one file per run:

```text
AI review report
(Do not use preview to read this report unless your previews are set to a monospace font.)

**User request:** <what was reviewed>

**Commit:** <sha>
**Subject:** <commit subject>

*   **Issue 1**
    *   **File:** <file containing the violation>
    *   **Current sentence:** `<flagged sentence>`
    *   **Suggested change:** `<corrected sentence>`
    *   **Style rule:** <first sentence of the rule>
    *   **TOC path:** *<Source title>* > *<Chapter>* > *<Section>*

End of report
```

When one sentence breaks several rules, the issues for that sentence are grouped and each repeat issue carries a `**⚠ WARNING!** Sentence with multiple issues! Evaluate suggestions one by one!` line. Issue numbers run sequentially across all guides in the order the guides were processed.

Deduplication applies within a single guide, so the same sentence is not reported twice for the same rule.

## Customization

- **Lines per range** — 1000, set in `SKILL.md` Phase 2. A 25,238-line guide becomes 26 ranges.
- **Batch size** — at most 8 ranges per `subagent` call; 4 run concurrently.
- **Agent** — the skill dispatches with `agent: worker`. Change the agent name in `SKILL.md` if you prefer another general-purpose agent.
- **Model** — not selected by the skill; switch models in Pi to change it.
- **Prompts and report format** — the analysis prompt template and the report layout live in `SKILL.md`.

## Adding a style guide

1. Create `sources/<n>-<name>.md` with a numeric prefix that puts it where you want it in the processing order.
2. Write embedded rules, tool instructions, or a URL reference (see `CONTRIBUTING.md` for examples of each).
3. Add the file to git explicitly, because `.gitignore` ignores `sources/`:

   ```bash
   git add -f sources/<n>-<name>.md
   ```

4. Run `/skill:docs-review` and confirm the guide is discovered, ranges are split correctly, and TOC paths resolve.

## Known limitations

- `setup-diff.sh` always diffs `HEAD~1..HEAD` in the repository you pass. It ignores the PR base branch. For a PR with more than one commit, or one based on a branch other than `main` (for example `standalone-otel-docs-main`), produce `temp/commit-diff.txt` yourself from `base.sha..head.sha` or from the PR's `.diff` URL — `6-ocp-merge-review.md` requires exactly that.
- PR review steps in `SKILL.md` mention `gh pr diff`, but `gh` is often not installed; the merge-review guide therefore uses the REST API and the public `.diff` URL with `curl`.
- `4-vale_linter.md` cannot run without `vale` installed, and `6-ocp-merge-review.md` cannot resolve PR review threads without a `GITHUB_TOKEN`/`GH_TOKEN` (it reports those checks as ⚠️ instead of guessing).
- Unauthenticated GitHub REST calls are limited to 60 requests per hour per IP.
- An interrupted run leaves `temp/` behind; `cleanup-temp.sh` only runs at the end of a completed review.
- Report file names use colons in the time part (`review-2026-11-02-18:34:21.md`), which is inconvenient on filesystems that reject `:` in file names.

## License

MIT — see [LICENSE](LICENSE).
