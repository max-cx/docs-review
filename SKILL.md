---
name: docs-review
description: Parallel style guide review workflow using multiple Markdown source files. Reviews PRs, commits, or files against style guide rules. Use with arguments like PR URLs (#123), commit refs (HEAD~1), or file paths. Analyzes content against style guide line ranges in parallel for faster review.
---

<!--
Use this skill with the following arguments:

- /skill:docs-review https://github.com/org/repo/pull/123 - review a PR by URL
- /skill:docs-review #123 or /skill:docs-review 123 - review a PR by number
- /skill:docs-review HEAD~1 - review a commit
- /skill:docs-review path/to/file.adoc - review a file
- /skill:docs-review - review the latest commit (default)
-->

# Parallel Style Guide Review Workflow

This skill performs a parallelized style guide review where independent line ranges from multiple Markdown source files are analyzed concurrently.

## Skill Directory

All supporting files (scripts, sources, reports, temp) live in the directory that contains this `SKILL.md`. Pi tells you where that directory is. In the commands below, `<skill-dir>` stands for its absolute path.

Every `bash` call runs in a fresh shell, so shell variables do not persist between calls. Substitute the absolute path for `<skill-dir>` in every command.

## Content to Review

The text that follows `/skill:docs-review` in the user's request is the content to review. If no arguments were provided, review the latest commit (`HEAD`).

Interpret the argument as follows:
- If it's a GitHub PR URL (e.g., `https://github.com/org/repo/pull/123`): use `gh pr diff <number>` to get the diff
- If it's a PR number (e.g., `#123` or `123`): use `gh pr diff <number>` to get the diff
- If it's a commit reference (e.g., `HEAD`, `HEAD~1`, `abc123`): review that commit's diff
- If it's a commit range (e.g., `HEAD~3..HEAD`): review the diff for that range
- If it's a file path (e.g., `docs/guide.adoc`): review that file's content
- If it's a glob pattern (e.g., `modules/**/*.adoc`): review all matching files
- If empty or not provided: review the latest commit (HEAD)

## Style Guide Source Configuration

- **Source directory:** `<skill-dir>/sources/` (contains style guide `.md` files)
- **Processing order:** Alphanumerical (e.g., `a-style.md` before `b-style.md`)
- **Minimum lines:** None — process ALL source files regardless of size, even single-line files
- **Lines per range:** 1000 (files with fewer lines use 1 range)
- **First line number:** 1 (will be updated if source file has a header to skip)

### Important: Source File Types

Style guide source files may take different forms:

1. **Embedded rules files:** Direct style guide content with rules, headings, and TOC structure
2. **URL reference files:** May contain a link to download the actual style guide (e.g., a URL to a GitHub raw content link)
3. **Tool instruction files:** May contain instructions on how to run a linting tool (e.g., Vale) that validates against style rules

**CRITICAL INSTRUCTION:** Do NOT skip a style guide source file just because it doesn't contain embedded rules. Instead:
- If a source file contains a URL reference, fetch the actual style guide content with `curl` in the `bash` tool
- If a source file contains tool instructions, follow those instructions explicitly (e.g., run `vale` command, read external README files)
- Follow all instructions in the source file to perform the style guide review
- Always complete the review for every source file in the sources directory

## Overview

**CRITICAL - Minimizing User Confirmations:**
This skill is designed to minimize user confirmations. Follow these rules strictly:
1. **Style guide selection:** Present a menu upfront for the user to choose style guide(s)
2. **Setup phase:** Use exactly 2 Bash commands (consolidated)
3. **Per style guide:** Use a small fixed number of tool calls:
   - 1 Bash command to create agent copies
   - 1 delegation call (or 1 pass over the ranges when working without subagents)
4. **NEVER** delegate the same style guide's ranges in multiple sequential messages when a single parallel call can hold them
5. **NEVER** run additional Bash commands between copy creation and analysis

**Expected confirmations per style guide:** 2 (one Bash, one analysis batch)

This workflow offers two modes based on user selection:

**Mode A: Single Style Guide** - User selects one specific style guide from the menu
- Processes only the selected style guide
- No per-style-guide prompts (direct processing)

**Mode B: All Style Guides Sequentially** - User selects "Review against all style guides sequentially"
- Processes style guides **one at a time in alphanumerical order**
- Prompts the user before each style guide with options to review, skip, pause, or quit

For each style guide processed, the analysis handles line ranges:
1. Calculates the number of 1000-line ranges needed
2. Analyzes each range (in parallel when subagents are available)
3. Collects findings and appends them to the unified review report
4. After all selected style guides are processed, finalizes the single review report

## Instructions

### Phase 0: Style Guide Selection Menu

Before starting the review, present the user with a menu to select which style guide(s) to use.

**Step 1:** Run the discovery script to find available style guide source files:

```bash
"<skill-dir>/scripts/discover-sources.sh"
```

**If output contains "NO_SOURCES_FOUND":**
- Display the path shown after NO_SOURCES_FOUND to the user
- Ask the user in chat, with a short numbered list, to choose between: "Done - I added the file(s)" and "Skip - proceed without style guide review"
- If the user chose to skip, end the review
- If the user added files, re-run the discovery command to verify and list sources

**Step 2:** Once source files are discovered, ask the user in chat to choose from a **first-level menu** with exactly two options:

- **"Review against all style guides"**: Review the content against all available style guides sequentially
- **"Review against one style guide"**: Select a specific style guide to review against

Ask the question, then stop and wait for the user's reply. Do not continue until the user answers.

**Step 3:** Handle first-level menu selection:

- **If user selects "Review against all style guides":**
  - List the discovered style guide files to the user (display the filenames from Step 1)
  - Proceed to Phase 1 (Setup) and then Phase 2 in Mode B (sequential processing with per-style-guide prompts)

- **If user selects "Review against one style guide":**
  - Present a **second-level menu** in chat with dynamically generated options based on the discovery command output:
    - **One option per style guide:** For each filename printed by the discovery command (in alphanumerical order), create an option labeled "Review against <filename>" where `<filename>` is the name without the `.md` extension
  - The menu options are NOT hardcoded — they are generated dynamically from whatever `.md` files exist in the sources directory at runtime
  - When the user selects a specific style guide, set a variable `SELECTED_STYLE_GUIDE` to the chosen filename (with `.md` extension) and proceed to Phase 1 (Setup) and then Phase 2 in Mode A (single style guide, no per-style-guide prompts)

### Phase 1: Setup (Consolidated)

Run the setup scripts to list files with line counts and prepare the commit diff:

```bash
"<skill-dir>/scripts/list-sources.sh"
```

```bash
"<skill-dir>/scripts/setup-diff.sh" "<repo path>"
```

Replace `<repo path>` with the repository that contains the content to review, for example the working directory the user is reviewing or the local clone of the repository in a PR URL.

Then:
1. Create the report file by running the `create-report.sh` script:
   ```bash
   REPORT_FILE=$("<skill-dir>/scripts/create-report.sh" "<user's request>" "<commit hash>" "<commit subject>")
   ```
   The script creates a timestamped report file under `<skill-dir>/reports/` with the standard header and prints the file path to stdout. Use the printed path for all subsequent report operations.

2. Initialize a running issue counter starting at 1. This counter will be used across all style guides to ensure sequential issue numbering in the final report.

### Parallel Execution Model

This skill analyzes independent line ranges. How you run them depends on the tools available in the current Pi session:

- **Preferred:** If the `subagent` tool is available (Pi subagent extension), delegate each line range to a subagent. Call `subagent` once per batch with a `tasks` array of `{ agent, task }` items, using a general-purpose agent such as `worker`. Parallel mode accepts at most 8 tasks per call and runs 4 concurrently, so split large style guides into batches of up to 8 ranges and wait for a batch before starting the next one.
- **Fallback:** If no `subagent` tool is available, analyze the line ranges yourself, one range at a time, in the current session. Collect findings in the same format and continue until all ranges are done.

Either way, finish every range of one style guide before starting the next style guide.

Subagents inherit the dispatching session's model unless the agent definition sets one. Do not choose or override a model for this skill; use whatever model the session or agent definition already provides.

### Phase 2: Style Guide Processing

Process style guide(s) based on the user's selection from Phase 0.

**Mode A: Single Style Guide Selected**

If the user selected a specific style guide in Phase 0:
- Process ONLY the selected style guide (stored in `SELECTED_STYLE_GUIDE`)
- Skip directly to step 2 below (no per-style-guide prompts needed)
- After completing the selected style guide, proceed directly to Phase 3

**Mode B: All Style Guides Sequentially**

If the user selected "Review against all style guides sequentially" in Phase 0:
- Process each style guide **one at a time** in alphanumerical order
- For each source file, follow the prompting workflow below

**For each source file to process (in alphanumerical order):**

1. **(Mode B only)** **Before processing each style guide**, ask the user in chat to choose from these options:
   - **"Review <filename>"**: Proceed with reviewing against this style guide source (replace `<filename>` with the actual source file name, e.g., "Review ibm-style-guide.md")
   - **"Pause to review issues"**: Pause to let the user review issues found in the previous style guide before continuing (only show this option if at least one style guide has already been processed)
   - **"Skip <filename>"**: Skip this style guide source and move to the next one (replace `<filename>` with the actual source file name)
   - **"Quit review"**: End the review process entirely

   Ask the question, then stop and wait for the user's reply.

   **Handle user choice:**
   - If user chooses **"Review <filename>"**: Continue with steps 2-7 below
   - If user chooses **"Pause to review issues"**:
     - Inform the user they can review the current report at the report file path
     - Wait for the user to indicate they are ready to continue
     - Then present the same choice again for the current style guide
   - If user chooses **"Skip <filename>"**: Skip to the next style guide in the alphanumerical list
   - If user chooses **"Quit review"**: Jump to Phase 3's final steps (append "End of report" and clean up temp files), then end the workflow

2. Calculate the number of ranges needed for this style guide:
   - Lines per range: 1000
   - Number of ranges = ceiling(total_lines / 1000)
   - Each range covers: range 1 reads lines 1-1000, range 2 reads lines 1001-2000, etc.

3. Create dedicated copies of the style guide source for each range:
   ```bash
   "<skill-dir>/scripts/create-agent-copies.sh" "<SOURCE_FILENAME>" <NUM_RANGES>
   ```
   Replace `<SOURCE_FILENAME>` with the actual filename (e.g., `ibm-style-guide.md`) and `<NUM_RANGES>` with the calculated number of ranges.

4. Analyze the ranges for this style guide only, following the Parallel Execution Model above.

**Analysis Prompt Template** (use for each range, whether delegated to a subagent or performed directly):
```text
You are analyzing documentation content for style guide violations.

1. Read lines <START_LINE> to <END_LINE> from your dedicated style guide source file:
   <skill-dir>/temp/<SOURCE_FILENAME_WITHOUT_EXT>/agent-<AGENT_NUMBER>.md

   Use the read tool with offset=<START_LINE> and limit=1000.

2. Read the commit diff: <skill-dir>/temp/commit-diff.txt

3. Analyze every sentence in the commit diff against ALL rules in your assigned line range.

4. For each violation found, determine the TOC path:
   - Check the Table of Contents in your dedicated source file to identify the hierarchy of headings.
   - Construct the full TOC path from the headings hierarchy.

5. Return your findings in your response (do NOT write to any files). Use this format:

   SOURCE: <SOURCE_FILENAME>
   LINES: <START_LINE>-<END_LINE>
   VIOLATIONS_FOUND: <number>

   If violations found, list each one:
   ---VIOLATION---
   FILE: <filename>
   CURRENT: <sentence where violation appears>
   SUGGESTED: <corrected sentence>
   RULE: <first sentence of the style rule>
   TOCPATH: <Style Guide Name> > <Section> > <Subsection>
   ---END---

   If no violations found, return:
   SOURCE: <SOURCE_FILENAME>
   LINES: <START_LINE>-<END_LINE>
   VIOLATIONS_FOUND: 0
   NO_VIOLATIONS_REASON: <brief explanation of what rules were checked>
```

When delegating with the `subagent` tool, set `agent` to a general-purpose agent (for example `worker`) and put the rendered prompt in `task`. Include all ranges of the current batch in a single call:

```json
{
  "tasks": [
    { "agent": "worker", "task": "<rendered prompt for range 1>" },
    { "agent": "worker", "task": "<rendered prompt for range 2>" }
  ]
}
```

5. **Wait for all ranges for this style guide to complete** before proceeding.

6. Parse the findings and append them to the review report (see Phase 3).

7. **Only after completing the current style guide**, move to the next style guide in the alphanumerical list.

**Execution rules (within each style guide) - CRITICAL:**
- **MUST** batch all ranges of the current batch into ONE `subagent` call (up to 8 tasks per call)
- **MUST** include every range (e.g., 22 ranges for a 21,335-line file, split across 3 calls of at most 8)
- Each range covers exactly one 1000-line window
- Ranges return findings in their response (no file writes needed)
- Do NOT analyze ranges for multiple style guides simultaneously
- Do NOT split a batch across multiple delegation calls when it fits in one

**Confirmation Budget:** Each style guide should require exactly 1 user confirmation for the delegation batch. If you find yourself needing more confirmations, you are not batching correctly.

### Phase 3: Merge Results

**After each style guide's ranges complete (within Phase 2 loop):**

1. Parse each set of findings to extract violations:
   - Look for the `---VIOLATION---` markers in the results
   - Extract SOURCE, FILE, CURRENT, SUGGESTED, RULE, TOCPATH fields
   - Skip results with `VIOLATIONS_FOUND: 0`

2. Append findings from this style guide to the review report file:
   - Use the running issue counter to number issues sequentially (continuing from previous style guides)
   - **CRITICAL:** Convert each violation to the exact format specified in the "Review Report Format" section below - do NOT use any other format
   - Deduplicate issues that flag the same sentence within this style guide
   - Increment the running issue counter for each new issue added

3. Continue to the next style guide (return to Phase 2).

**After ALL style guides have been processed:**

4. Use the `edit` tool to append "End of report" to the review report file, then clean up temporary files:
   ```bash
   "<skill-dir>/scripts/cleanup-temp.sh"
   ```

**Note:** The final review report contains all issues from all style guides, numbered sequentially in the order they were found (style guides processed in alphanumerical order).

### Phase 4: Check for false positives among the issues

1. Re-check each identified issue to determine if it is a false positive.

2. Remove all false positives from the report file.

## Review Report Format

Start every response with a line "AI review report".
On the next line after "AI review report", add a line "(Do not use preview to read this report unless your previews are set to a monospace font.)

End every response with a line "End of report".

Each of the other attached sources contains a plurality of rules.

You must review every sentence of the entered text separately, sentence by sentence for violations of all rules (issues) in the sentence.

Number the issues in the order in which you add them.

If you detect only one violation in a sentence, then use the following format to document the violation:

*   **Issue 1**
    *   **File:** <filename from the last line of the entered text that contains `--- a`> (skip this line if there are no instances of `--- a` in the text)
    *   **Current sentence:** `<sentence where the violation appears>` (enclose this sentence with opening and closing `)
    *   **Suggested change:** `<sentence of violation updated to resolve the violation>` (enclose this sentence with opening and closing `)(do not emphasize the changes)
    *   **Style rule:** <copy the first sentence of the style rule>
    *   **TOC path:** *<Source Title>* > *<CHAPTER>* > *<Section>* > *<Subsection>* (include all TOC levels)

(start the next list item, which is for the next sentence, after a blank line)

If you detect multiple violations in a sentence, then use the following format to document the violations for that particular sentence:

*   **Issue 2**
    *   **File:** <filename from the last line of the entered text that contains `--- a`> (skip this line if there are no instances of `--- a` in the text)
    *   **Current sentence:** `<sentence where the violation appears>` (enclose this sentence with opening and closing `)
    *   **Suggested change:** `<sentence of violation updated to resolve the violation>` (enclose this sentence with opening and closing `)(do not emphasize the changes)
    *   **⚠ WARNING!** Sentence with multiple issues! Evaluate suggestions one by one!
    *   **Style rule:** <copy the first sentence of the style rule>
    *   **TOC path:** *<Source Title>* > *<CHAPTER>* > *<Section>* > *<Subsection>* (include all TOC levels)
*   **Issue 3**
    *   **Current sentence:** `<sentence where the violation appears>` (enclose this sentence with opening and closing `)
    *   **Suggested change:** `<sentence of violation updated to resolve the violation>` (enclose this sentence with opening and closing `)(do not emphasize the changes)
    *   **⚠ WARNING!** Sentence with multiple issues! Evaluate suggestions one by one!
    *   **Style rule:** <copy_the_first_sentence_of_the_style_rule>
    *   **TOC path:** *<Source Title>* > *<CHAPTER>* > *<Section>* > *<Subsection>* (include all TOC levels)

(start the next list item, which is for the next sentence, after a blank line)

## Phase 4: Interactive Issue Resolution

After completing all review tasks and generating the report:

1. **Check if issues were found**: If at least one issue was detected during the review, proceed to step 2. If no issues were found, skip this phase.

2. **Prompt the user**: Ask the user in chat whether they want to review and fix the issues one by one, offering:
   - "Yes - go through issues one by one"
   - "No - keep the report as-is"

   Stop and wait for the user's reply.

3. **If the user chooses to go through issues**: For each issue in the report, present the issue details in the Review Report Format and offer three choices:
   - **Apply**: Apply the suggested change to the source file
   - **Skip**: Leave the original text unchanged and move to the next issue
   - **Modify**: Allow the user to provide a custom fix (different from the suggested change)

   Stop and wait for the user's reply before moving to the next issue.

4. **Process user choices**:
   - **Apply**: Use the `edit` tool to replace the current sentence with the suggested change in the source file
   - **Skip**: Take no action and proceed to the next issue
   - **Modify**: Wait for the user to provide their custom text, then use the `edit` tool to apply their modification

5. **Continue until all issues are processed** or the user requests to stop.
