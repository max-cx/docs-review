# Changelog

All notable changes to the AI Review skill are documented in this file.

## [1.0.0] - 2026-06-08

### Added

- **Initial Release**: Standalone AI Review skill for comprehensive style guide analysis
- **Multi-style guide support**: Simultaneous or sequential review against multiple style guides
- **Parallel processing**: 1000-line agents for efficient large-scale style guide processing
- **Flexible input**: Support for PRs, commits, files, glob patterns, and raw text
- **Interactive resolution**: Review and apply fixes one by one
- **Comprehensive reporting**: Detailed reports with issue numbering, TOC paths, and suggestions

### Features

- **Phase 0: Discovery** - Automatic detection of style guides in `sources/` directory
- **Phase 1: Setup** - Report initialization and temporary directory creation
- **Phase 2: Processing** - Parallel agent-based analysis across style guide line ranges
- **Phase 3: Merging** - Consolidated results with deduplication and sequential numbering
- **Phase 4: Resolution** - Interactive interface for reviewing and applying fixes

### Documentation

- **README.md** - Complete feature overview and usage guide
- **QUICKSTART.md** - 5-minute setup and first review guide
- **CONTRIBUTING.md** - Guidelines for adding custom style guides
- **SKILL.md** - Detailed workflow phases and configuration
- **LICENSE** - MIT License
- **CHANGELOG.md** - This file

### Style Guides Included

1. **grammar_spelling_punctuation.md** (3 lines)
   - American English grammar and spelling rules

2. **ibm-style-documentation.md** (26,880 lines)
   - Comprehensive IBM Style Guide covering:
     - Grammar and punctuation
     - Formatting and structure
     - Word usage and terminology
     - References and citations
     - Legal information and claims
     - Technical elements and UI

3. **supplementary_style_guide.md** (2 lines)
   - Additional formatting conventions

4. **vale_linter.md** (11 lines)
   - Red Hat Vale linter configuration rules

5. **foolproofing.md** (1 line)
   - Content foolproofing checks (copy-paste errors, duplicates)

### Project Structure

```
ai-review/
├── .claude-plugin/
│   └── plugin.json              # Plugin configuration
├── .gitignore                   # Git ignore rules
├── CHANGELOG.md                 # This file
├── CONTRIBUTING.md              # Contribution guidelines
├── LICENSE                      # MIT License
├── QUICKSTART.md                # Quick start guide
├── README.md                    # Feature overview
├── SKILL.md                     # Skill definition
├── reports/
│   └── .gitkeep                 # Reports directory (generated at runtime)
└── sources/
    ├── 1-grammar_spelling_punctuation.md
    ├── 2-ibm-style-documentation.md
    ├── 3-supplementary_style_guide.md
    ├── 4-vale_linter.md
    └── 5-foolproofing.md
```

### Configuration

- **Agent model**: `haiku` (configurable in SKILL.md)
- **Lines per agent**: 1000 (configurable in Phase 2)
- **Processing order**: Alphanumerical (based on numeric prefixes in filenames)
- **Report location**: `reports/review-YYYY-MM-DD-timestamp.md`

### Performance

- **IBM Style Guide (26,880 lines)**: ~45 seconds with 27 parallel agents
- **Total agents per run**: Equal to ceiling(total_lines / 1000) across all selected guides
- **Report generation**: Includes deduplication and sequential numbering

### Dependencies

- Claude Code with Agent support
- Optional: Git (for commit-based reviews)
- Optional: GitHub CLI `gh` (for PR-based reviews)

### Known Limitations

- Temporary files require manual cleanup if interrupted (see SKILL.md Phase 3)
- Agent prompts assume style guide files contain rule definitions
- URL reference guides require WebFetch (external network access)
- Tool instruction guides require external linting tools to be installed

### Future Enhancements

- Automated cleanup on interruption
- Caching mechanism for frequently reviewed style guides
- Custom report templates
- Integration with CI/CD pipelines
- Visualization of issue distribution
- Batch review mode for multiple documents

---

For usage details, see [README.md](README.md)
For contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md)
For quick setup, see [QUICKSTART.md](QUICKSTART.md)
