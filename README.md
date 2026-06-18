# AI Review Skill

A standalone Claude skill for using the Haiku model to perform comprehensive style guide reviews on documentation content using parallel AI agents.

## Features

- **Multi-style guide support**: Review content against multiple style guides simultaneously or sequentially
- **Parallel processing**: Uses multiple agents to analyze large style guides efficiently (1000 lines per agent)
- **Flexible input**: Review PRs, commits, files, or raw text
- **Comprehensive reporting**: Generates detailed reports with issue numbering, TOC paths, and suggested fixes
- **Interactive resolution**: Review and apply fixes one by one

## Installation

This is a standalone skill that can be used as a Claude Code skill. To use it:

1. Clone or copy this repository to your Claude Code installation by running `git clone git@github.com:max-cx/docs-review.git` from the `~/.claude/skills/` directory
2. Ensure the `sources/` directory contains your style guide markdown files
3. The skill will automatically discover and process all `.md` files in `sources/`
4. Invoke with `/docs-review` command

## Directory Structure

```
ai-review/
├── README.md                              # This file
├── SKILL.md                               # Skill definition and instructions
├── sources/                               # Style guide source files
│   ├── 1-grammar_spelling_punctuation.md
│   ├── 2-ibm-style-documentation.md
│   ├── 3-supplementary_style_guide.md
│   ├── 4-vale_linter.md
│   └── 5-foolproofing.md
└── reports/                               # Generated review reports (created at runtime)
```

## Usage

### With Claude Code

Invoke the skill directly:
```
/docs-review "Your text to review"
/docs-review path/to/file.md
/docs-review HEAD~1
/docs-review #123
```

### Skill Parameters

The skill accepts the following input types:

- **Raw text**: Any quoted text to review
- **File path**: Path to a documentation file (e.g., `docs/guide.adoc`)
- **Glob pattern**: Multiple files (e.g., `modules/**/*.adoc`)
- **Commit reference**: Git commit hash or ref (e.g., `HEAD`, `HEAD~1`, `abc123`)
- **Commit range**: Multiple commits (e.g., `HEAD~3..HEAD`)
- **GitHub PR**: PR URL or number (e.g., `https://github.com/org/repo/pull/123` or `#123`)
- **Nothing**: Reviews latest commit by default

## How It Works

### Phase 0: Style Guide Selection
The skill discovers all markdown files in the `sources/` directory and presents a menu:
- Review against all style guides sequentially
- Review against one specific style guide

### Phase 1: Setup
- Initializes temporary directories
- Creates report file with metadata
- Sets up commit/file information

### Phase 2: Style Guide Processing
- Calculates number of agents needed (1 per 1000 lines)
- Creates copies of each style guide for parallel processing
- Spawns agents to analyze content against specific line ranges
- Collects violations and appends to report

### Phase 3: Results Merging
- Consolidates findings across all agents
- Deduplicates issues within each style guide
- Maintains sequential issue numbering
- Cleans up temporary files

### Phase 4: Interactive Resolution (Optional)
- Presents found issues to the user
- Allows applying, skipping, or customizing each fix
- Generates corrected version of content

## Style Guide Source Files

The skill supports three types of source files in `sources/`:

### 1. Embedded Rules Files
Direct style guide content with rules, headings, and table of contents structure. The largest, most common type.

Example: `2-ibm-style-documentation.md` (26,880 lines)

### 2. URL Reference Files
Contains a URL pointing to downloadable style guide content. The skill uses WebFetch to retrieve the actual rules.

Example: `4-vale_linter.md` (11 lines)

### 3. Tool Instruction Files
Contains instructions on how to run external linting tools (e.g., Vale). The skill follows these instructions explicitly.

## Customization

### Adding New Style Guides

1. Create a new markdown file in `sources/` directory
2. Name it with a numeric prefix for sorting (e.g., `6-custom-guide.md`)
3. Add your style guide content, rules, or URL reference
4. The skill will automatically discover and process it on next run

### Naming Convention

Source files are processed in alphanumerical order:
- `1-grammar_spelling_punctuation.md` (processed first)
- `2-ibm-style-documentation.md` (processed second)
- etc.

Use numeric prefixes to control processing order.

### Adjusting Agent Configuration

Edit the constants in SKILL.md Phase 2:
- **Lines per agent**: Change from 1000 to another value
- **Agent type**: Modify `subagent_type` in agent prompts
- **Model**: Change from `haiku` to `sonnet` or `opus` for larger workloads

## Output

### Review Reports

Generated in `reports/` directory with timestamp:
```
reports/review-2026-06-04-current.md
```

Each report contains:
- User request details
- Issues organized by style guide
- Issue numbers, current text, suggestions, rules, and TOC paths
- Summary with no violations

### Report Format

```markdown
AI review report
(Do not use preview to read this report unless your previews are set to a monospace font.)

**User request:** <request details>

## Style Guide: <name>

*   **Issue 1**
    *   **Current sentence:** `<text>`
    *   **Suggested change:** `<correction>`
    *   **Style rule:** <rule description>
    *   **TOC path:** <path to rule in style guide>

...

End of report
```

## Requirements

- Claude Code with Agent support
- Git (for commit-based reviews)
- GitHub CLI `gh` (for PR-based reviews, optional)

## Performance

- **Large style guides**: Processed in parallel across multiple agents
- **Processing speed**: ~45 seconds for full 26,880-line IBM style guide (27 parallel agents)
- **Minimal overhead**: Temporary files cleaned up automatically after each run

## Contributing

To enhance this skill:

1. Add or update style guide files in `sources/`
2. Test with sample content using `/review`
3. Review generated reports in `reports/`
4. Adjust agent prompts or processing logic as needed

## License

This skill is provided as-is for use with Claude Code.

## Support

For issues or improvements, document them in the report files and refer to the skill definition in SKILL.md for configuration details.
