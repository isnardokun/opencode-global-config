---
name: docx
description: Create, read, edit, and analyze Word documents (.docx files). Triggers: any mention of 'Word doc', 'word document', '.docx', or requests to produce professional documents with tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx files, inserting images, performing find-and-replace, working with tracked changes or comments, or converting content into a polished Word document. Do NOT use for PDFs, spreadsheets, or Google Docs. Adapted from anthropics/skills for opencode-global-config (uses python-docx, not docx-js/npm; runtime detection with graceful degradation).
---

# DOCX — create, read, edit, analyze

Adapted from `anthropics/skills/skills/docx/SKILL.md` (2026-06-28). The original used `docx-js` (npm) for new documents and unpacked/repacked XML for editing. This version uses `python-docx` (Python) which is more portable and already installed in most Linux/macOS systems.

## Tool detection

Run this at the start of any session:

```bash
echo "TOOL_PYTHON_DOCX=$(python3 -c 'import docx' 2>/dev/null && echo yes || echo no)"
echo "TOOL_OPENPYXL=$(python3 -c 'import openpyxl' 2>/dev/null && echo yes || echo no)"
echo "TOOL_PANDOC=$(command -v pandoc >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_LIBREOFFICE=$(command -v soffice >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_LXML=$(python3 -c 'import lxml' 2>/dev/null && echo yes || echo no)"
```

Tier the workflow by what's available:

| Tools | Tier | What you can do |
|-------|------|-----------------|
| `python-docx` | 1 (core) | Create, read, edit .docx (paragraphs, tables, images, styles) |
| + `lxml` | 2 (advanced) | Tracked changes, comments, footnotes, fields via raw XML |
| + `pandoc` | 3 (convert) | Convert .docx ↔ markdown/html, extract text with tracked changes |
| + `libreoffice` | 4 (PDF/image) | Convert .docx → PDF/PNG for review or distribution |

If `python-docx` is missing, prompt the user to install: `pip install python-docx` (lightweight, ~5 MB, no native deps).

## Quick reference

| Task | Approach |
|------|----------|
| Read/analyze content | `python-docx` `Document` API or `pandoc` for text extraction |
| Create new document | `python-docx` — see "Creating new documents" below |
| Edit existing document | `python-docx` for content edits; raw XML via `lxml` for tracked changes/comments |
| Convert .doc → .docx | `libreoffice --headless --convert-to docx` |
| Convert to images | `libreoffice --headless --convert-to pdf` then `pdftoppm` |
| Extract tracked changes | `pandoc --track-changes=all input.docx -o output.md` |

## Provenance

Adapted from `anthropics/skills/skills/docx/SKILL.md`. Original `license: Proprietary` dropped. Frontmatter minimized (only `name` + `description`, which is all opencode preserves). The original used `docx-js` (npm) for new documents; this version uses `python-docx` which is more portable. The `Critical Rules for docx-js` section is replaced with `Critical Rules for python-docx` below.

---

## Creating new documents with `python-docx`

```python
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

doc = Document()

# Page size (US Letter) — python-docx default is also Letter for en-US locale,
# but set explicitly for cross-platform consistency
section = doc.sections[0]
section.page_width = Inches(8.5)
section.page_height = Inches(11)
section.top_margin = Inches(1)
section.bottom_margin = Inches(1)
section.left_margin = Inches(1)
section.right_margin = Inches(1)

# Add a heading
doc.add_heading('Title', level=1)

# Add a paragraph
p = doc.add_paragraph('Hello world. ')
p.add_run('This is bold. ').bold = True
p.add_run('This is italic.').italic = True

# Add a table
table = doc.add_table(rows=2, cols=2)
table.cell(0, 0).text = 'Cell 1'
table.cell(0, 1).text = 'Cell 2'
table.cell(1, 0).text = 'Cell 3'
table.cell(1, 1).text = 'Cell 4'

# Save
doc.save('output.docx')
```

### Critical rules for python-docx

- **Use `add_heading(text, level=N)`** — never style a paragraph manually to look like a heading. This is what python-docx's `level` is for.
- **Tables need explicit widths**: `table.style = 'Table Grid'` and `cell.width = Inches(N)`. Without widths, tables render with auto-sized columns that may overflow.
- **Run formatting** is set on `Run` objects, not paragraphs: `run.bold = True`, `run.font.size = Pt(12)`, `run.font.color.rgb = RGBColor(0xFF, 0x00, 0x00)`.
- **Images** require `python-docx[full]` (or `pip install pillow`): `doc.add_picture('image.png', width=Inches(4))`.
- **Page breaks**: `doc.add_page_break()` (deprecated, but works) or `run.add_break(WD_BREAK.PAGE)`.
- **Styles override**: `doc.styles['Normal'].font.name = 'Arial'` (universally supported). Avoid Unicode-only fonts.

### Lists

```python
# Numbered list (manual — python-docx doesn't have a high-level list API)
for i, item in enumerate(items, 1):
    doc.add_paragraph(f'{i}. {item}')

# Bulleted list (manual)
for item in items:
    p = doc.add_paragraph(item, style='List Bullet')
```

For advanced list configuration (multi-level, custom markers), use raw XML via `lxml`.

### Headers and footers

```python
section = doc.sections[0]
header = section.header
header.paragraphs[0].text = 'My Document Header'

footer = section.footer
footer.paragraphs[0].text = 'Page '
# Add page number to footer
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
run = footer.paragraphs[0].add_run()
fldChar = OxmlElement('w:fldChar')
fldChar.set(qn('w:fldCharType'), 'begin')
run._r.append(fldChar)
instrText = OxmlElement('w:instrText')
instrText.text = 'PAGE'
run._r.append(instrText)
fldChar2 = OxmlElement('w:fldChar')
fldChar2.set(qn('w:fldCharType'), 'end')
run._r.append(fldChar2)
```

### Tables of contents (TOC)

```python
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

# Add a TOC field — Word/LO will populate it when the doc is opened
p = doc.add_paragraph()
run = p.add_run()
fldChar = OxmlElement('w:fldChar')
fldChar.set(qn('w:fldCharType'), 'begin')
run._r.append(fldChar)
instrText = OxmlElement('w:instrText')
instrText.text = r'TOC \o "1-3" \h \z \u'
run._r.append(instrText)
fldChar2 = OxmlElement('w:fldChar')
fldChar2.set(qn('w:fldCharType'), 'separate')
run._r.append(fldChar2)
# Placeholder text
placeholder = OxmlElement('w:t')
placeholder.text = 'Right-click and "Update Field" in Word/LO.'
run._r.append(placeholder)
fldChar3 = OxmlElement('w:fldChar')
fldChar3.set(qn('w:fldCharType'), 'end')
run._r.append(fldChar3)
```

The TOC will be empty until the document is opened in Word/LibreOffice and the field is updated. Add a clear instruction to the user.

---

## Reading and analyzing content

```python
from docx import Document

doc = Document('input.docx')

# All paragraphs
for para in doc.paragraphs:
    print(f'[{para.style.name}] {para.text}')

# All tables
for i, table in enumerate(doc.tables):
    print(f'Table {i}: {len(table.rows)} rows x {len(table.columns)} cols')
    for row in table.rows:
        for cell in row.cells:
            print(f'  {cell.text}')

# Headers/footers
for section in doc.sections:
    print(f'Header: {section.header.paragraphs[0].text}')
    print(f'Footer: {section.footer.paragraphs[0].text}')
```

For text extraction with tracked changes (if `pandoc` is available):

```bash
pandoc --track-changes=all input.docx -o output.md
```

---

## Editing existing documents

### Simple edits (python-docx)

```python
from docx import Document

doc = Document('existing.docx')

# Edit existing paragraph
for para in doc.paragraphs:
    if 'old text' in para.text:
        # Replace text while preserving the paragraph
        for run in para.runs:
            if 'old text' in run.text:
                run.text = run.text.replace('old text', 'new text')

# Add content at the end
doc.add_paragraph('New content')

# Save to a new file (preserve original)
doc.save('modified.docx')
```

### Advanced edits (raw XML via lxml)

For tracked changes, comments, footnotes, or fields, you need to drop down to raw XML. The `.docx` file is a ZIP archive of XML files. Use `lxml` for parsing.

```python
import zipfile
from lxml import etree

# Read the document XML
with zipfile.ZipFile('input.docx', 'r') as z:
    document_xml = z.read('word/document.xml')

# Parse
NSMAP = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
tree = etree.fromstring(document_xml)

# Modify (e.g., add a tracked change insertion)
# See "XML reference" in the original Anthropic docx skill for full schemas
```

If you need full tracked-changes / comments / footnote support, fall back to the original Anthropic docx skill's workflow (which is what they were designed for). The python-docx + lxml approach covers ~80% of common docx work.

### Inserting and replacing images

```python
from docx import Document
from docx.shared import Inches

doc = Document('input.docx')
# Add a new paragraph with the image
doc.add_picture('image.png', width=Inches(4))

# To REPLACE an image: find the paragraph containing the image,
# clear the paragraph's runs, and add the new image
for para in doc.paragraphs:
    if para.runs and any(run.element.findall('.//{http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing}inline') for run in para.runs):
        # Clear runs
        for run in para.runs:
            run.text = ''
        # Add new image (this adds a new run)
        para.add_run().add_picture('new_image.png', width=Inches(4))

doc.save('modified.docx')
```

---

## Converting .doc to .docx

Legacy `.doc` files require conversion:

```bash
# If libreoffice is available:
soffice --headless --convert-to docx old.doc
```

This produces `old.docx` in the current directory.

---

## Converting to images (for review)

```bash
# Requires libreoffice + poppler-utils
soffice --headless --convert-to pdf input.docx
pdftoppm -jpeg -r 150 input.pdf page
```

Produces `page-1.jpg`, `page-2.jpg`, etc. in the current directory.

---

## What you cannot do without `libreoffice`

- Convert .doc → .docx
- Convert .docx → PDF
- Convert .docx → images
- Update fields (TOC, page numbers) — the user must open the file in Word/LO and press F9 / right-click → "Update Field"

For these, fall back to producing a manual checklist for the user.

---

## Anti-patterns

- **Hardcoding XML strings**. Use python-docx's API where possible; use lxml with namespaces when you must drop to XML.
- **Skipping the page size setup**. python-docx's defaults depend on locale; always set page_width/page_height explicitly.
- **Style names that don't exist**. python-docx's `add_paragraph(text, style=...)` will fail silently if the style isn't in the document. Use `doc.styles.add_style(...)` to add custom styles first, or stick to built-ins.
- **Assuming Word will render the same as LibreOffice**. Word and LO handle fields, sections, and some formatting differently. If cross-app compatibility is critical, generate a PDF preview with `soffice` and inspect.
- **Reinventing tracked changes / comments from scratch**. The XML schema is complex. If you need full support, follow the original Anthropic docx skill (which uses `docx-js` and the unpack/pack workflow) rather than rolling your own.
