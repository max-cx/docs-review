# Contributing to AI Review

Thank you for interest in improving the AI Review skill! This document explains how to contribute.

## Adding New Style Guides

### Step 1: Prepare Your Style Guide File

Create a new markdown file in the `sources/` directory with a numeric prefix:

```bash
sources/6-your-style-guide.md
```

The numeric prefix controls processing order (1, 2, 3... are processed first).

### Step 2: Choose a Format

Your style guide file can be one of three types:

#### Type 1: Embedded Rules (Recommended)
Include the full style guide content directly in the markdown file. This allows the skill to process rules offline without external dependencies.

Example structure:
```markdown
# Your Style Guide Name

## Section 1: Grammar
Rule text here...

### Subsection
More rules...

## Section 2: Formatting
Rule text here...
```

**Best for**: Complete, self-contained style guides

#### Type 2: URL Reference
Include a single URL that points to downloadable style guide content. The skill will use WebFetch to retrieve the actual rules.

Example:
```markdown
# Your Style Guide Name

[Download the complete style guide](https://example.com/style-guide/raw.md)
```

**Best for**: External style guides, frequently updated sources

#### Type 3: Tool Instructions
Include instructions on running an external linting tool (e.g., Vale, markdownlint).

Example:
```markdown
# Vale Linting Rules

Run the following command to validate against Vale rules:
```bash
vale <file>
```
```

**Best for**: Integration with existing linting tools

### Step 3: Format Guidelines

Whatever format you choose:

1. **Use clear headings** - The skill extracts TOC paths from heading hierarchy
2. **Number your rules** or use clear rule titles for identification
3. **Include the first sentence** - The skill extracts the first sentence as the rule summary
4. **Keep structure consistent** - Nested headings (H2 > H3 > H4) work best

Example:
```markdown
## Grammar

### Sentence Structure

Do not omit verbs from coordinate clauses. When you write a sentence 
that includes two coordinate clauses, do not omit the verb from the 
second clause.

Example: ✗ Bad: "The pod runs on Node A, while other pods do."
Example: ✓ Good: "The pod runs on Node A, while other pods run on Node B."
```

### Step 4: Test Your Style Guide

1. Place your file in `sources/`
2. Run the skill with test content:
   ```
   /docs-review "Test sentence about your style guide topic"
   ```
3. Check the generated report in `reports/`
4. Verify that:
   - Your style guide was discovered
   - Rules were correctly parsed
   - TOC paths are accurate
   - Issues are properly identified

### Step 5: Document Your Style Guide

Add an entry to the README.md `sources/` section:

```markdown
| File | Type | Content | Lines |
|------|------|---------|-------|
| your-style-guide.md | Embedded Rules | Complete style guide content | 1,234 |
```

## Improving Existing Style Guides

### Adding Rules

1. Open the source file (e.g., `sources/2-ibm-style-documentation.md`)
2. Add your new rule under the appropriate heading
3. Follow the existing format and structure
4. Test with sample content

### Updating Documentation

1. Follow heading hierarchy conventions
2. Keep first sentences clear (these become rule summaries)
3. Include examples where helpful
4. Update README.md if structure changes

## Modifying the Skill Logic

The skill's behavior is defined in `SKILL.md`. Key sections:

### Phase 0: Discovery
- Source discovery mechanism
- Menu generation

### Phase 1: Setup
- Report initialization
- Temporary directory creation

### Phase 2: Processing
- Agent spawning logic
- Lines per agent calculation (default: 1000)
- Model selection (default: haiku)

### Phase 3: Results Merging
- Issue deduplication
- Report formatting
- Numbering logic

### Phase 4: Interactive Resolution
- Issue presentation
- Fix application

### To modify:
1. Edit the relevant phase in SKILL.md
2. Document the change clearly
3. Test with multiple style guides
4. Update README.md if user-facing behavior changes

## Code Style

- Use clear, descriptive variable names
- Comment complex logic
- Follow existing formatting patterns
- Test changes with real style guide files

## Testing

### Test Checklist

Before submitting changes:

- [ ] Source file is properly formatted as markdown
- [ ] Numeric prefix follows naming convention
- [ ] File can be discovered by the discovery script
- [ ] Skill processes file without errors
- [ ] Generated report accurately identifies issues
- [ ] TOC paths are correct
- [ ] README.md is updated
- [ ] No files committed to `reports/` directory

### Test Commands

```bash
# List discovered style guides
ls -la sources/

# Check markdown validity
file sources/your-guide.md

# Test with sample content
/docs-review "Sample text about your style guide"

# Review generated report
cat reports/review-*.md

# Clean up test reports
rm reports/review-*.md
```

## Submission Guidelines

When contributing:

1. **Follow the directory structure** - Place source files in `sources/`, keep reports out of version control
2. **Use numeric prefixes** - Ensures consistent ordering
3. **Test thoroughly** - Run the skill with real content
4. **Document changes** - Update README.md and CONTRIBUTING.md as needed
5. **Keep files self-contained** - Avoid external dependencies when possible

## Questions?

Refer to:
- **README.md** - Usage and features overview
- **SKILL.md** - Detailed workflow phases and configuration
- **Generated reports** - Examples of expected output format

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).
