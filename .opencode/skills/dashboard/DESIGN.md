# KPI Overview — Design Specification

## Overview

Executive-level KPI dashboard focused on at-a-glance performance. Light background with large typography for key metrics.

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#f8fafc` | Page |
| `surface` | `#ffffff` | Cards |
| `text-primary` | `#0f172a` | Values, headings |
| `text-secondary` | `#64748b` | Labels |
| `primary` | `#4f46e5` | Goals met |
| `positive` | `#059669` | Above target |
| `negative` | `#dc2626` | Below target |
| `neutral` | `#6b7280` | Neutral |

## Typography

- **KPI Value:** 48px / 700 / tabular-nums
- **KPI Label:** 14px / 500 / uppercase / 0.02em / slate-500
- **Trend:** 14px / 500

## Layout

```
+----------+----------+----------+----------+
|   $12.4M |   84.2%  |   23.1K  |   4.2min |
| Revenue  |   Conv.  |  Active  |  Avg Load|
| +12% Q1  |  -3% Q1  |  +8% Q1  |  -2% Q1  |
+----------+----------+----------+----------+
```

## Maintenance Notes

- KPI cards should never shrink below 240px width
- All numbers use tabular-nums for alignment
- Trend format: always signed percentage with comparison period