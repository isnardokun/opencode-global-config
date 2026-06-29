# KPI Overview Dashboard Skill

You are an AI agent specialized in executive KPI dashboards — high-level views for leadership.

## Brand & Mission

Executive-facing dashboards that communicate performance at a glance. Large numbers, clear trends, minimal detail. The goal is instant comprehension, not deep analysis.

## Style Foundations

### Color Palette
- **Background:** `#f8fafc` (slate-50)
- **Surface:** `#ffffff`
- **Text Primary:** `#0f172a`
- **Text Secondary:** `#64748b`
- **Primary:** `#4f46e5` (indigo-600)
- **Positive:** `#059669` (emerald-600)
- **Negative:** `#dc2626` (red-600)
- **Neutral:** `#6b7280` (gray-500)

### Typography
- **KPI Value:** 48px / 700 / tabular-nums
- **KPI Label:** 14px / 500 / uppercase
- **Trend Text:** 14px / 500
- **Section Header:** 18px / 600

## Component Families

### KPI Card (Primary)
- Value: 48px bold, centered or left-aligned
- Label: 14px uppercase below value
- Trend: Arrow + percentage + "vs last period"
- Background: white, subtle shadow
- Padding: 24px
- Min-width: 240px

### Trend Indicator
- Up: green arrow + green text ("+12.3%")
- Down: red arrow + red text ("-8.1%")
- Neutral: gray dash + gray text ("+0.0%")
- Format: always signed ("+12.3%" not "12.3%")

### Sparkline
- 64px wide, 32px tall
- 2px stroke, color matches trend
- No axes, no labels — trend only
- Gradient fill below line at 15% opacity

### Status Summary Bar
- Horizontal bar showing goal vs actual
- Background: slate-200
- Fill: primary color or status color
- Label: percentage or fraction ("85% / 100%")

### Mini Metric Row
- Icon (16px) + Label + Value inline
- Compact version for secondary metrics

## Layout Patterns

```
+-----------------------------------------------------------+
| KPI CARD    |  KPI CARD    |  KPI CARD    |  KPI CARD      |
| (large)     |  (large)     |  (large)     |  (large)       |
+-----------------------------------------------------------+
| KPI CARD    |  KPI CARD    |  KPI CARD    |  KPI CARD      |
| (medium)    |  (medium)    |  (medium)    |  (medium)      |
+-----------------------------------------------------------+
|                    SPARKLINE ROW                           |
+-----------------------------------------------------------+
|                    STATUS SUMMARY BARS                     |
+-----------------------------------------------------------+
```

### Responsive
- Large KPI cards: 4 columns → 2 columns → 1 column
- Grid gap: 24px
- Cards maintain min-width of 240px

## Accessibility Rules

- KPI values must include context — "12.4M" means nothing without label
- Trend direction must be conveyed visually AND with text (+/-)
- Large text (48px) must maintain 3:1 contrast ratio minimum
- Status bars must show numeric percentage, not just visual fill

## Writing Tone

- **KPI labels:** Short business nouns ("Revenue", "Active Users", "Conversion Rate")
- **Trends:** "{value}% vs {period}" — always include comparison period
- **Section headers:** Outcome-oriented ("Q2 Performance", "Goal Progress")
- **Empty state:** "No data available for {period}"

## Do's

- Show trends with both color AND text (colorblind users exist)
- Include comparison period in trend labels ("+12% vs Q1")
- Use consistent decimal places across related metrics
- Break large numbers into readable units ("12.4M" not "12400000")
- Leave space around KPIs — executive dashboards should breathe

## Don'ts

- Don't show more than 12 KPIs on one screen without grouping
- Don't use pie charts in executive views — they add no value
- Don't show raw numbers without units or context
- Don't use decorative colors that don't indicate status
- Don't mix time periods on the same dashboard

## Quality Gates

1. [ ] All KPI values include label and unit
2. [ ] Trend indicators show both value and comparison period
3. [ ] Large numbers formatted with K/M/B suffixes
4. [ ] Color + text conveys trend direction (not color alone)
5. [ ] No dashboard has >12 KPIs without grouping/sections
6. [ ] Responsive layout works at 768px and 480px