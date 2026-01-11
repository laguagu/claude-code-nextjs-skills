# Best Practices for Writing Skills

## Core Principles

### 1. Concise is Key

Claude is already very smart. Only add context Claude doesn't have.

**Challenge each piece:**
- "Does Claude really need this explanation?"
- "Can I assume Claude knows this?"
- "Does this justify its token cost?"

**Good (concise):**
```markdown
## Extract PDF text

Use pdfplumber:
\`\`\`python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
\`\`\`
```

**Bad (verbose):**
```markdown
## Extract PDF text

PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text, you'll need a library.
There are many options but we recommend pdfplumber because...
```

### 2. Set Appropriate Degrees of Freedom

Match specificity to task fragility.

**High freedom** (text instructions):
- Multiple valid approaches
- Decisions depend on context
```markdown
## Code review
1. Analyze structure
2. Check for bugs
3. Suggest improvements
```

**Medium freedom** (pseudocode):
- Preferred pattern exists
- Some variation acceptable
```markdown
## Generate report
Use this template, customize as needed:
\`\`\`python
def generate_report(data, format="markdown"):
    # Process data
    # Generate output
\`\`\`
```

**Low freedom** (exact scripts):
- Operations are fragile
- Consistency critical
```markdown
## Database migration
Run exactly this:
\`\`\`bash
python scripts/migrate.py --verify --backup
\`\`\`
Do not modify the command.
```

### 3. Progressive Disclosure

Keep SKILL.md lean, link to details.

```markdown
# My Skill

## Quick start
[Basic example]

## Advanced features
- **Forms**: See [references/forms.md](references/forms.md)
- **API**: See [references/api.md](references/api.md)
```

**Pattern: Domain-specific organization**
```
skill/
├── SKILL.md (overview)
└── references/
    ├── finance.md
    ├── sales.md
    └── product.md
```

## Content Guidelines

### Avoid Time-Sensitive Information
```yaml
# Bad
If before August 2025, use old API.

# Good - use "old patterns" section
## Current method
Use v2 API.

## Old patterns (deprecated)
<details>
<summary>Legacy v1 API</summary>
Old endpoint was...
</details>
```

### Use Consistent Terminology
Pick one term and stick with it:
- Always "API endpoint" (not "URL", "route", "path")
- Always "field" (not "box", "element", "control")

### Avoid Multiple Options
```markdown
# Bad
You can use pypdf, or pdfplumber, or PyMuPDF...

# Good - provide default
Use pdfplumber for text extraction.
For scanned PDFs requiring OCR, use pdf2image instead.
```

## Templates and Examples

### Template Pattern
```markdown
## Report structure

Use this template:
\`\`\`markdown
# [Title]

## Summary
[One paragraph]

## Findings
- Finding 1
- Finding 2

## Recommendations
1. Action item
\`\`\`
```

### Examples Pattern
```markdown
## Commit messages

**Example 1:**
Input: Added user auth
Output: `feat(auth): implement JWT authentication`

**Example 2:**
Input: Fixed date bug
Output: `fix(reports): correct timezone conversion`
```

## Checklist

Before deploying:
- [ ] Description includes what AND when
- [ ] SKILL.md under 500 lines
- [ ] No time-sensitive info
- [ ] Consistent terminology
- [ ] Examples are concrete
- [ ] References one level deep
- [ ] Tested with real scenarios
