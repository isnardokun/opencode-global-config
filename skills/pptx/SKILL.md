---
name: pptx
description: Create, read, edit, and analyze PowerPoint presentations (.pptx files). Triggers: any task involving a .pptx file as input or output (create slide decks, read or extract text, edit existing presentations, work with templates, layouts, speaker notes). Use whenever the user mentions "deck", "slides", "presentation", or references a .pptx filename. Adapted from anthropics/skills for opencode-global-config (uses python-pptx, runtime-detection with graceful degradation).
---

# PPTX — create, read, edit, analyze

Adapted from `anthropics/skills/skills/pptx/SKILL.md` (2026-06-28). Original used `pptxgenjs` (Node) for create and `markitdown` (Python) for read; this version uses `python-pptx` (Python) for both read and edit/create-from-template, with `markitdown` as opt-in for text extraction.

## Tool detection

Run this at the start of any session:

```bash
echo "TOOL_PYTHON_PPTX=$(python3 -c 'import pptx; print(pptx.__version__)' 2>/dev/null || echo no)"
echo "TOOL_MARKITDOWN=$(python3 -c 'import markitdown' 2>/dev/null && echo yes || echo no)"
echo "TOOL_LIBREOFFICE=$(command -v soffice >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_POPPLER=$(command -v pdftoppm >/dev/null 2>&1 && echo yes || echo no)"
```

Tier the workflow by what's available:

| Tools | Tier | What you can do |
|-------|------|-----------------|
| `python-pptx` | 1 (core) | Create, read, edit .pptx (slides, shapes, text, tables, speaker notes) |
| + `markitdown` | 2 (text) | Extract structured text/markdown from any .pptx |
| + `libreoffice` | 3 (PDF) | Convert .pptx → PDF for visual review |
| + `poppler` | 4 (images) | Convert PDF → per-slide JPGs for visual inspection |

If `python-pptx` is missing, prompt: `pip install python-pptx` (lightweight, ~5 MB).

## Quick reference

| Task | Approach |
|------|----------|
| Read/analyze content | `python-pptx` `Presentation` API or `markitdown` for markdown |
| Create from template | `python-pptx` — load template, add slides, save |
| Create from scratch | `python-pptx` — build slides with shapes and text frames |
| Edit existing | `python-pptx` — modify shapes, text, layouts in place |
| Convert to images | `libreoffice` + `poppler` (tier 3-4) for visual QA |

## Provenance

Adapted from `anthropics/skills/skills/pptx/SKILL.md`. Original used `pptxgenjs` (npm) for create-from-scratch and `markitdown` (Python) for read. This version uses `python-pptx` (Python) throughout, which is more portable and already familiar to users of `python-docx` (the `docx` skill). The `Design Ideas` section (color palettes, typography, layout) is ported verbatim because it is methodology, not tooling — and is genuinely useful guidance that the LLM benefits from. The original `pptxgenjs.md` reference (12KB of detailed API) and the four scripts (`add_slide.py`, `clean.py`, `thumbnail.py`, `office/unpack.py`) are not ported; `python-pptx` covers the same use cases without the JS dependency.

---

## Reading content

```python
from pptx import Presentation

prs = Presentation('input.pptx')

# All slides
for i, slide in enumerate(prs.slides, 1):
    print(f'--- Slide {i} ---')
    print(f'Layout: {slide.slide_layout.name}')
    for shape in slide.shapes:
        if shape.has_text_frame:
            for para in shape.text_frame.paragraphs:
                for run in para.runs:
                    print(f'  {run.text}')
```

For markdown extraction with structure (headings, lists, tables):

```bash
# Requires: pip install 'markitdown[pptx]'
python -m markitdown input.pptx
```

For finding placeholder text in templates:

```bash
python -m markitdown output.pptx | grep -iE "xxxx|lorem|ipsum|click.*to.*add"
```

## Creating from scratch

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

prs = Presentation()

# Use the default blank layout (index 6 in default template, or search by name)
blank_layout = None
for layout in prs.slide_layouts:
    if layout.name == 'Blank':
        blank_layout = layout
        break
if blank_layout is None:
    blank_layout = prs.slide_layouts[6]  # default blank

# Add a title slide
slide = prs.slides.add_slide(blank_layout)
title = slide.shapes.add_textbox(Inches(0.5), Inches(0.5), Inches(9), Inches(1))
title.text_frame.text = 'My Presentation'
title.text_frame.paragraphs[0].runs[0].font.size = Pt(44)
title.text_frame.paragraphs[0].runs[0].font.bold = True

# Add a content slide with bullet list
slide2 = prs.slides.add_slide(blank_layout)
body = slide2.shapes.add_textbox(Inches(0.5), Inches(1.5), Inches(9), Inches(5))
tf = body.text_frame
tf.text = 'First bullet'
p = tf.add_paragraph()
p.text = 'Second bullet'
p.level = 1
p = tf.add_paragraph()
p.text = 'Third bullet'
p.level = 1

prs.save('output.pptx')
```

## Creating from a template

```python
from pptx import Presentation

prs = Presentation('template.pptx')

# Find a layout by name
title_layout = None
content_layout = None
for layout in prs.slide_layouts:
    if layout.name == 'Title Slide':
        title_layout = layout
    elif 'Content' in layout.name and content_layout is None:
        content_layout = layout

# Add slides using the layouts
slide = prs.slides.add_slide(title_layout)
# Set placeholders
slide.placeholders[0].text = 'Title Here'
slide.placeholders[1].text = 'Subtitle Here'

slide2 = prs.slides.add_slide(content_layout)
slide2.placeholders[0].text = 'Content Title'
slide2.placeholders[1].text = 'Bullet one\nBullet two\nBullet three'

prs.save('output.pptx')
```

## Editing existing

```python
from pptx import Presentation

prs = Presentation('input.pptx')

# Replace text in a specific slide
for slide in prs.slides:
    for shape in slide.shapes:
        if shape.has_text_frame:
            for para in shape.text_frame.paragraphs:
                for run in para.runs:
                    if 'old text' in run.text:
                        run.text = run.text.replace('old text', 'new text')

# Add a new slide at a specific position
new_slide = prs.slides.add_slide(prs.slide_layouts[6])
new_slide.shapes.add_textbox(Inches(1), Inches(1), Inches(8), Inches(1)).text_frame.text = 'Inserted'

# Reorder slides
xml_slides = prs.slides._sldIdLst
slides_list = list(xml_slides)
xml_slides.remove(slides_list[2])  # remove slide 3
xml_slides.insert(0, slides_list[2])  # move it to the front

prs.save('output.pptx')
```

## Design Ideas (from original Anthropic skill)

**Don't create boring slides.** Plain bullets on a white background won't impress anyone.

### Before Starting

- **Pick a bold, content-informed color palette**: The palette should feel designed for THIS topic. If swapping your colors into a completely different presentation would still "work," you haven't made specific enough choices.
- **Dominance over equality**: One color should dominate (60-70% visual weight), with 1-2 supporting tones and one sharp accent. Never give all colors equal weight.
- **Dark/light contrast**: Dark backgrounds for title + conclusion slides, light for content ("sandwich" structure). Or commit to dark throughout for a premium feel.
- **Commit to a visual motif**: Pick ONE distinctive element and repeat it — rounded image frames, icons in colored circles, thick single-side borders. Carry it across every slide.

### Color Palettes

Choose colors that match your topic — don't default to generic blue.

| Theme | Primary | Secondary | Accent |
|-------|---------|-----------|--------|
| **Midnight Executive** | `1E2761` (navy) | `CADCFC` (ice blue) | `FFFFFF` (white) |
| **Forest & Moss** | `2C5F2D` (forest) | `97BC62` (moss) | `F5F5F5` (cream) |
| **Coral Energy** | `F96167` (coral) | `F9E795` (gold) | `2F3C7E` (navy) |
| **Warm Terracotta** | `B85042` (terracotta) | `E7E8D1` (sand) | `A7BEAE` (sage) |
| **Ocean Gradient** | `065A82` (deep blue) | `1C7293` (teal) | `21295C` (midnight) |
| **Charcoal Minimal** | `36454F` (charcoal) | `F2F2F2` (off-white) | `212121` (black) |
| **Teal Trust** | `028090` (teal) | `00A896` (seafoam) | `02C39A` (mint) |
| **Berry & Cream** | `6D2E46` (berry) | `A26769` (dusty rose) | `ECE2D0` (cream) |
| **Sage Calm** | `84B59F` (sage) | `69A297` (eucalyptus) | `50808E` (slate) |
| **Cherry Bold** | `Cherry Bold` | `FCF6F5` (off-white) | `2F3C7E` (navy) |

### For Each Slide

- **Every slide needs a visual element** — image, chart, icon, or shape. Text-only slides are forgettable.
- **Layout options**: two-column, icon+text rows, 2x2/2x3 grid, half-bleed image.
- **Data display**: large stat callouts (60-72pt), comparison columns, timeline/process flow.
- **Visual polish**: icons in colored circles next to headers, italic accent text for stats.

### Typography

- **Choose an interesting font pairing** — don't default to Arial. Pick a header font with personality.
- Slide titles: 36-44pt bold. Section headers: 20-24pt bold. Body: 14-16pt. Captions: 10-12pt muted.

### Spacing

- 0.5" minimum margins
- 0.3-0.5" between content blocks
- Leave breathing room — don't fill every inch

### Avoid (Common Mistakes)

- Don't repeat the same layout — vary columns, cards, callouts
- Don't center body text — left-align paragraphs and lists; center only titles
- Don't skimp on size contrast — titles need 36pt+ to stand out from 14-16pt body
- Don't default to blue — pick colors that reflect the specific topic
- Don't mix spacing randomly — choose 0.3" or 0.5" gaps and use consistently
- Don't style one slide and leave the rest plain — commit fully or keep it simple throughout
- Don't create text-only slides — add images, icons, charts, or visual elements
- **NEVER use accent lines under titles** — these are a hallmark of AI-generated slides; use whitespace or background color instead

## QA (Required)

**Assume there are problems. Your job is to find them.**

### Content QA

```bash
python -m markitdown output.pptx | grep -iE "xxxx|lorem|ipsum|this.*(page|slide).*layout"
```

If grep returns results, fix them before declaring success.

### Visual QA (when libreoffice + poppler available)

```bash
soffice --headless --convert-to pdf output.pptx
pdftoppm -jpeg -r 150 output.pdf slide
# Inspect slide-01.jpg, slide-02.jpg, etc.
```

**Look for:**
- Overlapping elements (text through shapes, lines through words)
- Text overflow or cut off at edges
- Decorative lines positioned for single-line text but title wrapped to two lines
- Source citations or footers colliding with content
- Elements too close (< 0.3" gaps) or cards nearly touching
- Uneven gaps (large empty area in one place, cramped in another)
- Insufficient margin from slide edges (< 0.5")
- Columns not aligned consistently
- Low-contrast text or icons
- Text boxes too narrow causing excessive wrapping
- Leftover placeholder content

### Verification Loop

1. Generate slides → Convert to images → Inspect
2. List issues found (if none found, look again more critically)
3. Fix issues
4. Re-verify affected slides
5. Repeat until a full pass reveals no new issues

**Do not declare success until you've completed at least one fix-and-verify cycle.**

## What you cannot do without `libreoffice`

- Convert .pptx → PDF
- Convert .pptx → images for visual QA
- Update fields

For these, fall back to producing a manual checklist for the user.

## Anti-patterns

- **Hardcoding slide indices for layouts.** Use `layout.name == '...'` to find layouts by name, not by index (the index varies by template).
- **Skipping visual QA.** Content QA catches missing text. Visual QA catches overlapping shapes, low contrast, and placeholder leftovers.
- **Defaulting to generic blue + Arial.** See the color palettes and typography tables above. Topic-informed choices > defaults.
- **Adding accent lines under titles.** This is a documented AI-tell that the LLM tends to add reflexively. Use whitespace or background color instead.
- **Text-only slides.** Every slide needs at least one visual element (image, icon, chart, or shape).
- **Skipping template placeholders.** When using a template, fill the placeholders, don't add free-floating text boxes over them.
