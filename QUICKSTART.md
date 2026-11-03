# Quick Start

Get from clone to a first review report in a few minutes.

## 1. Install

User-level (available in every project):

```bash
cd ~/.pi/agent/skills
git clone git@github.com:max-cx/docs-review.git
```

Project-level (available in one repository only):

```bash
mkdir -p .pi/skills
git clone git@github.com:max-cx/docs-review.git .pi/skills/docs-review
```

`~/.agents/skills/` and `.agents/skills/` also work. Project-level skills load only after the project is trusted.

Parallel analysis needs the Pi [subagent extension](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent/examples/extensions/subagent). Without it, the skill analyzes line ranges one at a time and takes much longer on the big guides.

## 2. Run a review

The argument after the command is what gets reviewed:

```text
/skill:docs-review https://github.com/openshift/openshift-docs/pull/123698
/skill:docs-review 123698
/skill:docs-review HEAD~1
/skill:docs-review HEAD~3..HEAD
/skill:docs-review modules/otel-collector-config-options.adoc
/skill:docs-review modules/*.adoc
```

With no argument, the skill reviews the latest commit (`HEAD`).

## 3. Pick the style guides

The skill lists everything in `sources/` and asks:

1. **Review against all style guides** — process every guide in alphanumerical order, asking before each one
2. **Review against one style guide** — then pick one from a generated list

The guides it can offer:

| File | What it checks | Lines |
|---|---|---|
| `1-grammar_spelling_punctuation.md` | American English grammar, spelling, punctuation | 3 |
| `2-ibm-style-documentation.md` | IBM Style | 25,238 |
| `3-supplementary_style_guide.md` | Red Hat supplementary guide (overrides IBM Style) | 11,102 |
| `4-vale_linter.md` | Runs Vale — **requires `vale` installed**, otherwise this guide aborts and asks you to install it | 11 |
| `5-foolproofing.md` | Copy-paste errors, incomplete changes, duplicates | 1 |
| `6-ocp-merge-review.md` | OpenShift docs PR merge checklist via the GitHub REST API | 166 |

`6-ocp-merge-review.md` checks PR metadata rather than prose: title/description format, single commit, versions + Jira + preview link, QE checkbox, peer approval, resolved conversations, WIP label, CI status. It needs `curl` and `python3`; a `GITHUB_TOKEN`/`GH_TOKEN` improves the checks that unauthenticated calls cannot verify.

## 4. Read the report

Each run creates one file in `<skill-dir>/reports/`, named with a timestamp:

```text
reports/review-2026-11-02-18:34:21.md
```

The report starts with `AI review report`, then the user request, commit hash, and subject, then numbered issues:

```markdown
*   **Issue 1**
    *   **File:** `modules/otel-processors-log-dedup-processor.adoc`
    *   **Current sentence:** `The processor deduplicates log records that have the same timestamp and body.`
    *   **Suggested change:** `The processor deduplicates log records that share a timestamp and body.`
    *   **Style rule:** <first sentence of the rule>
    *   **TOC path:** *IBM Style* > *Word usage* > *...*
```

- **Issue N** — sequential across all guides in the run
- **File** — the file the sentence came from
- **Current / Suggested** — the flagged sentence and a corrected version
- **Style rule** — first sentence of the violated rule
- **TOC path** — where that rule lives in the style guide

If one sentence breaks several rules, the issues for it are grouped and marked `⚠ WARNING! Sentence with multiple issues!`. After the review, the skill re-checks every issue and removes false positives, so numbers can have gaps.

The report ends with `End of report`. Reports are never overwritten by a later run, but two runs started in the same second would collide.

## 5. Apply fixes (optional)

If any issues were found, the skill offers:

- **Yes** — go through issues one by one
- **No** — keep the report as-is

For each issue you then choose **Apply**, **Skip**, or **Modify** (your own wording).

## Common tasks

### Review someone's PR

```text
/skill:docs-review https://github.com/openshift/openshift-docs/pull/123698
```

PR diffs are fetched from the public `.diff` URL with `curl`, so `gh` is not needed. For proper results on PRs with several commits or a base branch other than `main`, check the PR's `base.sha` — see "Known limitations" in the [README](README.md).

### Review one file, then again after editing

```text
/skill:docs-review modules/my-module.adoc
# edit the file
/skill:docs-review modules/my-module.adoc
```

### Review only the merge checklist

Choose **Review against one style guide** → `6-ocp-merge-review`.

## Troubleshooting

**"No style guides found"** — `sources/` has no `.md` files. The skill prints the path it checked:

```bash
ls -la ~/.pi/agent/skills/docs-review/sources/
```

**A guide was skipped** — `4-vale_linter.md` aborts when `vale` is not on `PATH`. Install Vale or skip that guide; the other guides still run.

**Review is slow** — the IBM guide alone is 26 ranges of 1000 lines. Install the subagent extension, or review against one guide instead of all of them.

**Something looks unverified in a merge review** — unauthenticated GitHub REST calls are capped at 60 per hour per IP, and review-thread resolution needs a token. The merge-review guide reports those items as ⚠️ rather than guessing.

**Leftover `temp/` files** — an interrupted run does not clean up. Remove them with:

```bash
rm -rf ~/.pi/agent/skills/docs-review/temp
# or
~/.pi/agent/skills/docs-review/scripts/cleanup-temp.sh
```

## Next steps

- [README.md](README.md) — full reference: scripts, phases, report format, limitations
- [SKILL.md](SKILL.md) — the workflow the model follows, including prompts
- [CONTRIBUTING.md](CONTRIBUTING.md) — adding or editing style guides
- `reports/` — past reports are useful examples of the output format
