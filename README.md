# Mortgage Plugin for Claude Code

The first mortgage refinance pricing plugin for Claude Code. Get live rate quotes, savings analysis, and loan application submission — all within the chat interface.

Technology by Nexus Digital Group LLC. Mortgage origination by Atlantic Home Mortgage LLC dba [Lendtrain](https://www.lendtrain.com) (NMLS# 1844873).

## Install

Install from GitHub:

```
/plugin marketplace add lendtrain/mortgage
/plugin install mortgage@mortgage
```

**Coming soon** — install from the Anthropic Plugin Directory:

```
/plugin install mortgage@anthropic
```

Then run:

```
/mortgage:refi-quote
```

## What It Does

Upload your mortgage statement or answer a few questions, and the plugin:

- **Prices your refinance** using live wholesale rate data for Conventional, FHA, and VA loans
- **Detects FHA Streamline and VA IRRRL eligibility** automatically from your mortgage statement
- **Calculates itemized closing costs** specific to your state
- **Runs a savings analysis** with monthly payment comparison, breakeven timeline, and total interest savings
- **Scores your refinance** from 1-10 with a weighted recommendation based on savings, breakeven, rate improvement, and goal alignment
- **Connects you to apply** if the numbers make sense — or honestly tells you if they don't

## Licensed States

Alabama, Florida, Georgia, Kentucky, North Carolina, Oregon, South Carolina, Tennessee, Texas, Utah

## How It Works

The plugin bundles domain expertise as Claude Code skills:

| Skill | What It Does |
|-------|-------------|
| `mortgage-loan-officer` | Interview methodology, credit score tiers, DTI thresholds, field mappings |
| `mortgage-compliance` | TRID, RESPA, TILA, ECOA rules and required disclosures |
| `closing-costs` | Itemized state-specific fee schedules for all 10 licensed states |
| `security-guardrails` | Prompt injection defense and data collection boundaries |
| `about-atlantic-home-mortgage` | Organization context, licensing, and contact information |

The `/mortgage:refi-quote` command orchestrates the full workflow: interview the borrower, collect loan details, call the pricing engine, run the analysis, and present results with proper compliance disclosures.

Live pricing is provided by a separate MCP server that ingests daily wholesale rate sheets. The plugin connects to it automatically via the `.mcp.json` configuration — no API keys or setup required.

## Pricing Engine

The plugin connects to a mortgage pricing MCP server that exposes three tools:

| Tool | Description |
|------|-------------|
| `calculate_pricing` | Price a single loan product (Conventional, FHA, or VA) |
| `calculate_all_pricing` | Price all eligible products simultaneously and compare |
| `get_effective_date` | Check when the current rate sheet was published |

See [CONNECTORS.md](CONNECTORS.md) for full API schemas, request/response fields, and integration details.

## Compliance

This plugin is designed for TRID, RESPA, TILA, and ECOA compliance:

- Never collects SSN, DOB, bank account numbers, or passwords
- Uses "estimate" and "quote" — never "pre-approval" or "guaranteed"
- Presents APR alongside note rate on all quotes
- Includes required settlement services disclosure
- Directs borrowers to secure application portal for sensitive data
- Provides Equal Housing Opportunity notice

## Contact

- **Phone:** 678-643-4242
- **Email:** team@lendtrain.com
- **Website:** [lendtrain.com](https://www.lendtrain.com)
- **Application portal:** [Apply here](https://atlantichm.my1003app.com/register)
- **NMLS#:** 1844873

## License

Proprietary — see [LICENSE](LICENSE) for full terms.

Technology owned by Nexus Digital Group LLC. "Lendtrain" is a registered trademark of Atlantic Home Mortgage LLC. Mortgage origination services provided by Atlantic Home Mortgage LLC dba Lendtrain (NMLS# 1844873). Equal Housing Opportunity.
