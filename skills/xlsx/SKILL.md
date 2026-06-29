---
name: xlsx
description: Create, read, edit, and analyze Excel spreadsheets (.xlsx, .xlsm, .csv, .tsv). Triggers: any task involving a spreadsheet file as primary input or output (open, read, edit, fix .xlsx; add columns, compute formulas, format, chart, clean messy data); create a new spreadsheet from scratch; convert between tabular formats. The deliverable must be a spreadsheet file. Do NOT trigger when the primary deliverable is a Word doc, HTML report, standalone Python script, database pipeline, or Google Sheets API integration. Adapted from anthropics/skills for opencode-global-config (uses openpyxl + optional pandas, with runtime detection and graceful degradation).
---

# XLSX — create, read, edit, analyze

Adapted from `anthropics/skills/skills/xlsx/SKILL.md` (2026-06-28). The original used `openpyxl` and `pandas` (same as this version) but assumed LibreOffice for formula recalculation. This version adds explicit tool detection and graceful degradation: pure-Python workflows work without any system-level deps.

## Tool detection

Run this at the start of any session:

```bash
echo "TOOL_OPENPYXL=$(python3 -c 'import openpyxl; print(openpyxl.__version__)' 2>/dev/null || echo no)"
echo "TOOL_PANDAS=$(python3 -c 'import pandas; print(pandas.__version__)' 2>/dev/null || echo no)"
echo "TOOL_LIBREOFFICE=$(command -v soffice >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_CSVKIT=$(command -v csvkit >/dev/null 2>&1 && echo yes || echo no)"
```

Tier the workflow by what's available:

| Tools | Tier | What you can do |
|-------|------|-----------------|
| `openpyxl` | 1 (core) | Create, read, edit .xlsx; write formulas (not evaluated) |
| + `pandas` | 2 (data) | Bulk read/write, data analysis, transformation |
| + `libreoffice` | 3 (recalc) | Evaluate formulas, save calculated values into the file |
| + `csvkit` | 4 (csv) | Convert .xlsx ↔ .csv from CLI without Python |

If `openpyxl` is missing, prompt the user to install: `pip install openpyxl` (lightweight, ~5 MB, no native deps). `pandas` is heavier (~40 MB) — mark as opt-in for data-heavy work.

---

## Provenance

Adapted from `anthropics/skills/skills/xlsx/SKILL.md`. Original `license: Proprietary` dropped. Frontmatter minimized (only `name` + `description`, which is all opencode preserves). The financial-model color-coding standards from the original are kept (they're industry-standard, not proprietary) but moved to a separate section so they don't dominate the skill body.

---

## Requirements for outputs

### All Excel files

- **Professional font**: Use Arial or another universally available font unless the user says otherwise.
- **Zero formula errors**: Every file MUST be delivered with zero `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?` errors. Use `soffice --headless` to recalculate and verify.
- **Preserve existing templates**: When updating a template, study and EXACTLY match existing format, style, and conventions. Do not impose standardized formatting on files with established patterns.

### Financial models (optional, opt-in)

If the spreadsheet is a financial model, apply industry-standard color coding:

- **Blue text (0,0,255)**: Hardcoded inputs
- **Black text (0,0,0)**: Formulas
- **Green text (0,128,0)**: Cross-sheet links
- **Red text (255,0,0)**: External file links
- **Yellow background (255,255,0)**: Key assumptions

### Number formatting

- **Years**: text strings (`"2024"` not `2,024`)
- **Currency**: `$#,##0` with units in headers (`"Revenue ($mm)"`)
- **Zeros**: dashes via custom format (`$#,##0;($#,##0);-`)
- **Percentages**: `0.0%` (one decimal)
- **Multiples**: `0.0x`
- **Negative numbers**: parentheses `(123)` not `-123`

---

## Creating new Excel files

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment

wb = Workbook()
ws = wb.active

# Add data
ws['A1'] = 'Name'
ws['B1'] = 'Revenue ($mm)'
ws.append(['Acme Corp', 12.5])
ws.append(['Globex', 8.3])

# Add a formula
ws['B4'] = '=SUM(B2:B3)'

# Formatting
ws['A1'].font = Font(bold=True, name='Arial', size=11)
ws['B1'].font = Font(bold=True, name='Arial', size=11)
ws['B1'].number_format = '$#,##0.0'

# Column widths
ws.column_dimensions['A'].width = 20
ws.column_dimensions['B'].width = 18

wb.save('output.xlsx')
```

### Critical rules for openpyxl

- **Use formulas, not hardcoded values**: `ws['B10'] = '=SUM(B2:B9)'`, not `ws['B10'] = 5000`. The spreadsheet must be dynamic.
- **Cell indices are 1-based**: `ws.cell(row=1, column=1)` is A1.
- **`data_only=True` reads calculated values** but strips formulas on save. Only use for read-only analysis; never save with this flag set.
- **For large files**: `load_workbook(file, read_only=True)` for reads or `write_only=True` for writes.
- **Specify dtypes on read** to avoid pandas inference errors: `pd.read_excel(file, dtype={'id': str})`.

---

## Editing existing Excel files

```python
from openpyxl import load_workbook

wb = load_workbook('existing.xlsx')
ws = wb.active

# Read
for row in ws.iter_rows(values_only=True):
    print(row)

# Edit a specific cell
ws['A1'] = 'New Header'

# Insert or delete rows/columns
ws.insert_rows(2)        # Insert a row at position 2
ws.delete_cols(3)        # Delete column 3

# Add a new sheet
new_sheet = wb.create_sheet('Summary')
new_sheet['A1'] = 'Total'
new_sheet['B1'] = '=SUM(Sheet1!B2:B10)'

wb.save('modified.xlsx')
```

---

## Working with pandas (data tier)

```python
import pandas as pd

# Read
df = pd.read_excel('input.xlsx')                # First sheet
all_sheets = pd.read_excel('input.xlsx', sheet_name=None)  # All sheets as dict

# Inspect
print(df.head())
print(df.info())
print(df.describe())

# Transform
df['profit_margin'] = (df['revenue'] - df['cost']) / df['revenue']
df = df.dropna(subset=['email'])

# Write
df.to_excel('output.xlsx', index=False)

# Read specific columns for large files
df = pd.read_excel('big.xlsx', usecols=['A', 'C', 'E'])
```

---

## Recalculating formulas

`openpyxl` saves formulas as **strings** without calculated values. To produce a file with calculated values (so consumers see numbers instead of formulas), recalculate with `libreoffice` headless:

```bash
soffice --headless --calc --convert-to xlsx input.xlsx
# This produces input.xlsx (overwritten) with calculated values
```

Or use a Python wrapper for more control:

```python
import subprocess, sys, time, os

def recalc(path, timeout=60):
    """Recalculate all formulas in path using libreoffice headless."""
    abs_path = os.path.abspath(path)
    out_dir = os.path.dirname(abs_path) or '.'
    result = subprocess.run(
        ['soffice', '--headless', '--calc', '--convert-to', 'xlsx', '--outdir', out_dir, abs_path],
        capture_output=True, text=True, timeout=timeout
    )
    return result.returncode == 0
```

After recalculation, verify by re-opening with `openpyxl(data_only=True)` and checking for error strings (`#REF!`, `#DIV/0!`, etc.) in the cells.

If `libreoffice` is not available, the file will still have valid formulas — they just won't show calculated values until opened in Excel/LibreOffice. Tell the user.

---

## Formula verification

After saving a file with formulas, open it with `data_only=True` and scan for error strings:

```python
from openpyxl import load_workbook

wb = load_workbook('output.xlsx', data_only=True)
ERRORS = ('#REF!', '#DIV/0!', '#VALUE!', '#N/A', '#NAME?', '#NULL!', '#NUM!')

for sheet_name in wb.sheetnames:
    ws = wb[sheet_name]
    for row in ws.iter_rows():
        for cell in row:
            if cell.value and isinstance(cell.value, str):
                for err in ERRORS:
                    if err in cell.value:
                        print(f'ERROR in {sheet_name}!{cell.coordinate}: {cell.value}')
```

Fix the identified errors and re-run. Common errors:

- `#REF!`: Invalid cell references (renamed/deleted sheet, off-by-one)
- `#DIV/0!`: Division by zero — check denominators
- `#VALUE!`: Wrong data type in formula
- `#NAME?`: Unrecognized function name
- `#N/A`: Lookup function didn't find value

---

## CSV / TSV conversion

```python
import pandas as pd

df = pd.read_csv('input.csv')           # CSV
df = pd.read_csv('input.tsv', sep='\t') # TSV
df.to_excel('output.xlsx', index=False)

# Or with csvkit (CLI):
# in2csv input.xlsx > output.csv
# csvlook output.csv
```

---

## When to refuse

- If the user wants a complex financial model with macros, pivot tables, or VBA: this skill covers formulas and formatting, not those features. Recommend a dedicated tool (Excel itself, or a Python library like `xlwings` that requires Excel).
- If the user wants real-time collaborative editing: that's Google Sheets territory, not .xlsx.

---

## Anti-patterns

- **Hardcoding calculated values in Python**. The whole point of a spreadsheet is that the user can change inputs and see results. Always use formulas.
- **Skipping recalc**. If you save a file with formulas, the user opens it and sees `=SUM(A1:A10)` as text in every cell. Recalculate or tell the user to open in Excel/LO and press F9.
- **Assuming cell values are the formula**. With `data_only=True`, cells contain the last-calculated value. If the file was never opened in Excel, those values are `None` — you can't tell if a formula is correct just by reading.
- **Color-coding by guessing**. The financial-model color convention (blue=input, black=formula, etc.) only helps if applied consistently. If you're not sure whether something is an input or a formula, leave it default.
- **Wide rows without a header row**. Always add a header row with clear column names. Don't make the user guess what `=B2+C2` means.
