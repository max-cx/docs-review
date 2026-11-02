# Instructions for Openshift Product Merge Reviews

## Task: OpenShift Documentation Merge Review

Perform a comprehensive review of the pull request against the following checklist:

### OCP Docs Repo Merge Request Checklist

- [ ] The PR title and first comment are in the format that is described in the PR template, and a correctly formatted PR title and comment looks like this: https://github.com/openshift/openshift-docs/pull/51056
- [ ] PR contains only one commit
- [ ] The PR description specifies versions, includes a link to the JIRA issue and a deep link to the Netlify preview
- [ ] QE approval box is ticked, with following exceptions:
  - Non-technical updates (fixing broken links, basic typos, or formatting issues) do not need QE review
  - No QE or SME is required for core OCP z-stream release note PRs or core OCP y-stream release note bug fixes
- [ ] A peer review done and approval received
- [ ] All conversations in the PR marked as "Resolved"
- [ ] "WIP" label is removed from title or comments
- [ ] Check that all system tests have passed on the PR (the openshift-ci bot should say "all tests passed!")

## Pi execution notes

This file contains tool instructions, not prose rules. The checklist items above are the rule text: copy them verbatim into the `Style rule` field.

Constraints in a Pi session:

- Use the `bash` tool for all data collection. The `gh` CLI is usually not installed; do not depend on it.
- Do not call GitHub GraphQL (`statusCheckRollup`, `reviewThreads`) unless a token is available. Prefer the REST endpoints below.
- PR webpages are rendered client-side, so scraping them for `data-resolved` returns nothing. Grep them only if the marker is actually present (see "Conversations").
- Never assume the base branch is `main` and never use `git diff HEAD~1..HEAD`. The base branch varies (`main`, `standalone-otel-docs-main`, release branches). Always read `base.ref` and `base.sha` from the API.
- Do not edit repository files for this style guide. The findings concern PR metadata; report the required remediation steps instead.

## Step 1: Collect data in one `bash` call

Substitute the PR number and, optionally, the local clone path, then run this once. Do not re-fetch the same endpoint later.

```bash
PR=123698
REPO=openshift/openshift-docs
REPO_PATH=${REPO_PATH:-$PWD}   # local clone of the repo; leave as-is to use the current directory
OUT=/tmp/pr-$PR
mkdir -p "$OUT"
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
api() { if [ -n "$TOKEN" ]; then curl -sS -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" "$@"; else curl -sS -H "Accept: application/vnd.github+json" "$@"; fi; }

api "https://api.github.com/repos/$REPO/pulls/$PR"                       -o "$OUT/pr.json"
api "https://api.github.com/repos/$REPO/pulls/$PR/commits?per_page=100"  -o "$OUT/commits.json"
api "https://api.github.com/repos/$REPO/pulls/$PR/reviews?per_page=100"  -o "$OUT/reviews.json"
api "https://api.github.com/repos/$REPO/pulls/$PR/comments?per_page=100" -o "$OUT/review-comments.json"
api "https://api.github.com/repos/$REPO/issues/$PR/comments?per_page=100" -o "$OUT/issue-comments.json"

HEAD_SHA=$(python3 -c "import json;print(json.load(open('$OUT/pr.json'))['head']['sha'])")
BASE_SHA=$(python3 -c "import json;print(json.load(open('$OUT/pr.json'))['base']['sha'])")
api "https://api.github.com/repos/$REPO/commits/$HEAD_SHA/status"     -o "$OUT/status.json"
api "https://api.github.com/repos/$REPO/commits/$HEAD_SHA/check-runs" -o "$OUT/check-runs.json"

# Diff: use the PR's own base and head SHAs, never HEAD~1.
mkdir -p <skill-dir>/temp
if [ -n "$REPO_PATH" ] && git -C "$REPO_PATH" cat-file -e "$BASE_SHA^{commit}" 2>/dev/null; then
  git -C "$REPO_PATH" diff "$BASE_SHA" "$HEAD_SHA" > <skill-dir>/temp/commit-diff.txt
else
  curl -sSL "https://github.com/$REPO/pull/$PR.diff" > <skill-dir>/temp/commit-diff.txt
fi
wc -l <skill-dir>/temp/commit-diff.txt
```

If an endpoint returns a JSON object with a `message` key instead of a list, treat that check as **not verifiable** and report it as ⚠️, not ❌. The unauthenticated REST limit is 60 requests per hour per IP; check `message` for a rate-limit notice before retrying.

Handle the token carefully: never echo `$TOKEN`, never put it in a file name or in a command line that gets logged, and do not add `-v` to `curl`. When `REPO_PATH` does not point at a clone that contains the PR SHAs, the diff falls back to the public `.diff` URL, which needs no credentials.

## Step 2: Read a compact digest, not raw JSON

Print a digest in the same `bash` call and keep it small. Do not open the PR HTML page (about 300 KB) or the raw JSON files with `read`.

```bash
python3 - "$OUT" <<'PY'
import json, os, re, sys
out = sys.argv[1]
load = lambda n: json.load(open(os.path.join(out, n)))
pr = load("pr.json")
if isinstance(pr, dict) and pr.get("message"):
    print("PR_FETCH_ERROR:", pr["message"]); raise SystemExit
commits = load("commits.json"); reviews = load("reviews.json")
rc = load("review-comments.json"); ic = load("issue-comments.json")
status = load("status.json"); checks = load("check-runs.json")
print("TITLE:", pr["title"])
print("AUTHOR:", pr["user"]["login"], "| DRAFT:", pr["draft"], "| STATE:", pr["state"])
print("BASE:", pr["base"]["ref"], pr["base"]["sha"][:10])
print("HEAD:", pr["head"]["ref"], pr["head"]["sha"][:10])
print("COMMITS:", pr["commits"], "| FILES:", pr["changed_files"], "| +%s -%s" % (pr["additions"], pr["deletions"]))
print("LABELS:", [l["name"] for l in pr["labels"]])
print("REVIEW_DECISION:", pr.get("review_decision") if isinstance(pr, dict) else None)
body = pr["body"] or ""
print("BODY_FIELDS:", {k: bool(re.search(r"(?im)^\s*%s\b" % k, body)) for k in
      ["Version", "Issue", "Link to docs preview", "QE review", "Additional information"]})
print("TEMPLATE_PLACEHOLDERS_LEFT:", body.count("<!---"))
print("QE_CHECKBOXES:", re.findall(r"(?i)-\s*\[( |x)\]\s*QE[^\n]*", body))
print("VERSIONS_LINE:", [l.strip() for l in body.splitlines() if l.lower().startswith("version")])
print("JIRA_LINKS:", re.findall(r"https?://\S*(?:atlassian\.net|issues\.redhat\.com)\S*", body))
print("PREVIEW_LINKS:", re.findall(r"https?://\S*netlify\S*", body))
print("COMMIT_LIST:", [(c["sha"][:10], c["commit"]["message"].splitlines()[0]) for c in commits] if isinstance(commits, list) else commits)
print("REVIEWS:", [(r["user"]["login"], r["state"]) for r in reviews] if isinstance(reviews, list) else reviews)
print("REVIEW_COMMENTS:", len(rc) if isinstance(rc, list) else rc)
print("ISSUE_COMMENTS:", len(ic) if isinstance(ic, list) else ic)
if isinstance(ic, list):
    print("CI_BOT_COMMENTS:", [(c["user"]["login"], (c["body"] or "")[:120].replace("\n", " "))
                               for c in ic if "ci" in c["user"]["login"].lower()])
print("COMBINED_STATUS:", status.get("state"), [(s["context"], s["state"]) for s in status.get("statuses", [])])
print("CHECK_RUNS:", [(r["name"], r["status"], r["conclusion"]) for r in checks.get("check_runs", [])])
PY
```

## Step 3: Evaluate each checklist item

| Checklist item | Evidence to use | Pass condition |
| --- | --- | --- |
| Title and comment format | `TITLE`, `BODY_FIELDS` | Title matches `^[A-Z][A-Z0-9]+-\d+:\s+\S`; all template fields present |
| Only one commit | `COMMITS`, `COMMIT_LIST` | Exactly 1 commit |
| Versions, JIRA link, preview deep link | `VERSIONS_LINE`, `JIRA_LINKS`, `PREVIEW_LINKS` | All three present; preview URL points at the changed page section, not the site root |
| QE approval box | `QE_CHECKBOXES` | `x` next to "QE has approved"; otherwise fail unless the diff is only broken links, typos, or formatting |
| Peer review approval | `REVIEWS`, `REVIEW_DECISION` | At least one `APPROVED` review from a user other than `AUTHOR` |
| Conversations resolved | `REVIEW_COMMENTS`, `ISSUE_COMMENTS` | Both are 0, or every thread is resolved |
| WIP removed | `TITLE`, `LABELS`, `DRAFT` | No `WIP`/`DRAFT` token in title or labels, `DRAFT: False` |
| System tests passed | `COMBINED_STATUS`, `CHECK_RUNS`, `CI_BOT_COMMENTS` | Combined status `success` **and** an openshift-ci "all tests passed!" confirmation |

Conversations detail: the REST API does not expose review-thread resolution. Use this order:

1. If `REVIEW_COMMENTS` and `ISSUE_COMMENTS` are both 0, there are no threads, so the item passes (state this explicitly).
2. Otherwise, if a token is available, query GraphQL `pullRequest(number: $PR) { reviewThreads(first: 100) { nodes { isResolved } } }` and count `isResolved: false`.
3. Otherwise run `curl -s "https://github.com/$REPO/pull/$PR" -o /tmp/pr-$PR.html` and count with a fixed-string match: `grep -cF 'data-resolved="false"'`. If the count is 0 and the marker `data-resolved` is absent from the file, the page is client-rendered: report ⚠️ not verifiable and say so, instead of claiming the item passes.

Do not use `grep` patterns with escaped quotes such as `'data-resolved=\"false\"'`; Bash strips the backslashes and grep warns about a stray `\`. Use `grep -F` with single quotes.

## Step 4: Report findings

Return two sections in your response and write no intermediate files:

1. A markdown checklist that repeats each rule verbatim with `[✔]`, `[⚠️]`, or `[❌]` plus one line of concrete evidence (numbers, SHAs, logins, status contexts).
2. One `---VIOLATION---` block per failing (❌) or partial (⚠️) item, using the skill's standard fields:

```text
SOURCE: 6-ocp-merge-review.md
LINES: 1-<last line>
VIOLATIONS_FOUND: <number>
---VIOLATION---
FILE: <path of the changed file this item is about, or "PR metadata" for repository-wide items>
CURRENT: <what the PR currently shows, with concrete evidence>
SUGGESTED: <the specific action that makes the item pass, for example "Squash the 2 commits and force-push">
RULE: <checklist item text, verbatim>
TOCPATH: Instructions for Openshift Product Merge Reviews > Task: OpenShift Documentation Merge Review > OCP Docs Repo Merge Request Checklist
---END---
```

Rules for the violation blocks:

- Emit at most one block per checklist item. Never split one item into several blocks.
- `CURRENT` states observed facts, not assumptions. If data could not be fetched, use ⚠️ and say which endpoint failed.
- `SUGGESTED` is an action for the author, because these items cannot be fixed by editing files.
- Keep issue numbering sequential across style guides; the report assembler adds the numbers.
- Do not report the same root cause twice. If an unchecked QE box and a missing approving review stem from one pending review round, report both items but keep the remediation distinct.

## Step 5: Sanity check before returning

- Every checklist item has exactly one verdict; no item is skipped silently.
- Every ❌ cites evidence pulled from the digest.
- No raw JSON or HTML was read into context.
- The diff file under `<skill-dir>/temp/commit-diff.txt` was produced from `base.sha..head.sha`.
