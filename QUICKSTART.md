# Quick Start Guide

Get up and running with AI Review in 5 minutes.

## Installation

### Option 1: Clone the Repository (Recommended)

```bash
git clone https://github.com/your-org/ai-review.git
cd docs-review
```

### Option 2: Copy to Claude Code Skills

Copy the entire `docs-review/` directory to your Claude Code skills folder:
```bash
~/.claude/skills/docs-review/
```

## First Review

### 1. Basic Usage

Open Claude Code and run:

```
/docs-review "TempoStack gateway pods spread across nodes for high availability"
```

### 2. Select Style Guides

When prompted, choose one of:
- **Review against all style guides** - Checks against all available guides
- **Review against one style guide** - Pick a specific guide

### 3. Review Results

The skill generates a report in `reports/` with:
- Each issue numbered
- Current text and suggested fixes
- Style rule being violated
- TOC path to the rule in the style guide

### 4. Apply Fixes (Optional)

When asked, choose to:
- **Apply** - Accept the suggestion
- **Skip** - Keep the original text
- **Modify** - Provide a custom fix

## Common Tasks

### Review a File

```
/docs-review path/to/your/document.md
```

### Review a Git Commit

```
/docs-review HEAD~1
```

### Review a GitHub PR

```
/docs-review #123
/docs-review https://github.com/org/repo/pull/123
```

### Review Multiple Files

```
/docs-review docs/**/*.md
```

## Available Style Guides

The skill includes these style guides (located in `sources/`):

| Guide | Type | Coverage |
|-------|------|----------|
| **1-grammar_spelling_punctuation** | Grammar | Grammar and spelling rules |
| **2-ibm-style-documentation** | Comprehensive | 26,880-line IBM Style Guide (grammar, punctuation, formatting, legal, word usage, references, etc.) |
| **3-supplementary_style_guide** | Formatting | Document formatting conventions |
| **4-vale_linter** | Linting | Vale linter rules for Red Hat style |
| **5-foolproofing** | QA | Content foolproofing checks (copy-paste errors, duplicates) |

## Understanding the Report

A typical issue in the report looks like:

```markdown
*   **Issue 3**
    *   **Current sentence:** `As a result, all gateway replicas could be scheduled on the same node.`
    *   **Suggested change:** `As a result, the system could schedule all gateway replicas on the same node.`
    *   **Style rule:** Write in active voice and the present tense as much as possible.
    *   **TOC path:** *IBM Style* > *Grammar* > *Grammar*
```

### Reading the Fields

- **Issue N** - Sequential number across all style guides
- **Current sentence** - The exact text being flagged
- **Suggested change** - How the text should be corrected
- **Style rule** - First sentence of the rule from the style guide
- **TOC path** - Where to find the full rule in the style guide

## Performance Tips

### For Large Documents
Reviews are processed in parallel. A 26,880-line style guide is processed by 27 agents simultaneously (~45 seconds total).

### For Multiple Reviews
Store text in files to quickly review iterations:
```
/docs-review report-draft-v1.md
```

Then make changes and review again:
```
/docs-review report-draft-v2.md
```

## Adding Custom Style Guides

Want to add your own style guide?

1. Create `sources/6-my-guide.md`
2. Add your style guide content (rules, headings, examples)
3. Run `/docs-review` - it will automatically discover the new guide

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed instructions.

## Report Files

Review reports are saved to `reports/` with timestamps:

```
reports/review-2026-06-04-current.md
reports/review-2026-06-05-14-30-00.md
```

Each report contains:
- Complete issue list
- Issues organized by style guide
- All suggested fixes
- Summary statistics

## Troubleshooting

### "No style guides found"

Check that `sources/` directory contains `.md` files:
```bash
ls -la sources/
```

### Style guide not being processed

Ensure filename has numeric prefix:
- ✓ `1-my-guide.md` (will process)
- ✗ `my-guide.md` (may not process)

### Issues not appearing in report

1. Verify the style guide contains rules
2. Check that the text actually violates a rule
3. Review the agent output for error messages

### Custom style guide not discovered

1. Save file in `sources/` directory
2. Use numeric prefix (e.g., `6-`, `7-`)
3. Run `/docs-review` again to rediscover

## Next Steps

- Read [README.md](README.md) for full feature overview
- See [CONTRIBUTING.md](CONTRIBUTING.md) to add custom style guides
- Check [SKILL.md](SKILL.md) for advanced configuration
- Review generated reports in `reports/` directory

## Getting Help

- Check example reports in `reports/` directory
- Review README.md for detailed feature documentation
- Read SKILL.md for configuration details
- See CONTRIBUTING.md for extending functionality

## Example Workflow

```bash
# 1. Clone the repository
git clone https://github.com/your-org/ai-review.git
cd ai-review

# 2. Create a test document
echo "The TempoStack pods spread across nodes for high availability" > test.txt

# 3. Review it with Claude Code
/docs-review test.txt

# 4. Check the generated report
cat reports/review-*.md

# 5. See the suggested fixes
# Apply them as needed in your document
```

---

**That's it!** You're now ready to review documentation with AI Review.
