---
min_recommendation_score: 6
min_monthly_savings_threshold: 50
max_breakeven_months: 48
default_lock_period: 30
---

# Lendtrain Org-Specific Configuration

This file contains organization-specific configuration values referenced by the `mortgage-loan-officer` skill. These values control recommendation thresholds and pricing defaults.

## Configuration Reference

### Closing cost figures

Closing costs are NOT configured here. They come exclusively from the `~~pricer calculate_closing_cost` MCP tool, which returns deterministic per-state, per-product numbers from the mortgage-pricer service. Never estimate closing costs as a percentage of the loan amount — even as a fallback. If the pricer tool is unavailable or the state is unsupported, the skill must say so explicitly rather than invent a figure. See the `mortgage-loan-officer` SKILL.md, "Estimated Closing Costs" section.

### `min_recommendation_score`

Minimum score on a 1-10 scale required to recommend refinancing and offer to submit an application. Quotes that score below this threshold will still be presented to the borrower with a transparent explanation, but the agent will not proactively suggest proceeding with an application.

**Current value**: 6

### `min_monthly_savings_threshold`

Minimum monthly payment savings, in dollars, to consider a refinance worthwhile. If the projected monthly savings fall below this amount, the recommendation score is reduced accordingly and the agent communicates that the savings may not justify the cost and effort of refinancing.

**Current value**: 50

### `max_breakeven_months`

Maximum acceptable breakeven period in months. The breakeven period represents how long it takes for cumulative monthly savings to offset total closing costs. Longer breakeven periods lower the recommendation score. Scenarios exceeding this threshold receive a significantly reduced score and a clear explanation to the borrower.

**Current value**: 48

### `default_lock_period`

Default rate lock period in days when calling the pricer API. This determines how long the quoted rate is guaranteed. Shorter lock periods may yield slightly better rates; longer periods provide more time to close. This value is used as the default unless the borrower specifies a different preference.

**Current value**: 30

