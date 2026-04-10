# Closing Costs

This skill is a **presentation guide** for showing itemized refinance closing costs to borrowers. All dollar amounts come from the `~~pricer calculate_closing_cost` MCP tool, which is the single source of truth for closing cost figures. This skill tells you how to format and present those numbers, how to explain them to the borrower, and which compliance disclosures to attach.

**DO NOT compute closing costs in this skill. DO NOT use rule-of-thumb percentages (e.g. "1.2% of the loan amount"). DO NOT sum the per-state reference tables below manually.** Call the pricer tool and present its response verbatim.

**Scope**: Refinance transactions only. Purchase transactions are not supported in this phase.

**Licensed states**: Georgia (GA), Alabama (AL), Florida (FL), Kentucky (KY), North Carolina (NC), Oregon (OR), South Carolina (SC), Tennessee (TN), Texas (TX), Utah (UT).

**Products**: Conventional, FHA, FHA Streamline, VA IRRRL, VA Cash-Out.

**Integration**: This skill is referenced by the `mortgage-loan-officer` skill when presenting closing cost estimates as part of a refinance quote. The `mortgage-loan-officer` skill calls `~~pricer calculate_closing_cost` and passes the result to this skill for presentation.

---

## Data Source: `~~pricer calculate_closing_cost` MCP Tool

Every closing cost number in the borrower-facing quote MUST come from the `calculate_closing_cost` MCP tool on the `~~pricer` connector. The tool wraps the deterministic `ClosingCostCalculator` in the mortgage-pricer service and returns a `ClosingCostBreakdown` with per-category subtotals and a `total` field.

**Tool call**:

```
~~pricer calculate_closing_cost
  state: <2-letter code>
  loanAmount: <base loan amount in dollars>
  productType: <"conventional" | "fha" | "va">
  isStreamline: <true for FHA Streamline or VA IRRRL, false otherwise>
  discountPointsDollar: <dollar cost of discount points on the selected rate, or 0>
  monthsSinceEndorsement: <FHA streamline only — full months since the existing loan's endorsement date>
  previousUfmipAmount: <FHA streamline only — UFMIP paid on the existing FHA loan>
```

**Tool response shape** (fields you will map into the itemized table):

```json
{
  "total": 4170.50,
  "lenderFees": {
    "underwriting": 1290,
    "discountPoints": 0
  },
  "thirdPartyFees": {
    "creditReport": 150,
    "appraisal": 550,
    "floodCert": 8,
    "taxService": 85,
    "subtotal": 793
  },
  "titleSettlement": {
    "settlementFee": 350,
    "titleInsurance": 1697.50,
    "cpl": 0,
    "subtotal": 2047.50
  },
  "governmentRecording": {
    "recordingFees": 40,
    "stateTaxes": 0,
    "taxDescription": "No mortgage tax",
    "subtotal": 40
  },
  "productSpecific": {
    "fhaUpfrontMip": 5250,            // FHA only
    "vaFundingFee": 1500,             // VA only
    "fhaStreamlineUfmipRefund": 2900  // FHA streamline only, when applicable
  }
}
```

Map each field directly into the itemized presentation table described below. Use the field values VERBATIM — do not round further, recompute, or "sanity check" them.

**Unsupported states**: If the property is in a state not covered by the calculator (anything other than AL/FL/GA/KY/NC/OR/SC/TN/TX/UT), the tool returns an error. In that case, do NOT invent a figure, do NOT fall back to a percentage heuristic, and do NOT use the per-state reference tables below. Defer to the `mortgage-compliance` skill: Lendtrain is not currently licensed in that state. See `refi-quote.md` for the standard unlicensed-state reply.

**Required inputs from the conversation** (to build the tool call):
1. Property state
2. Loan amount
3. Product type (Conventional, FHA, or VA)
4. For VA loans only: the `vaFundingFeeType` (`'firstTime'`, `'subsequent'`, or `'exempt'`) — used by the `mortgage-loan-officer` skill and passed into the pricer's main pricing call; the closing-cost tool infers the funding fee from `productType` + `isStreamline`
5. For FHA Streamline: borrower's mortgage statement (for UPB, current rate, origination date, monthly MIP) — the origination date yields `monthsSinceEndorsement`, and the current monthly MIP helps estimate the original UFMIP (`previousUfmipAmount`)
6. For VA IRRRL: borrower's mortgage statement (for UPB, current rate, origination date/first payment date) — required for seasoning, not for the closing cost calc itself

---

## Section A -- Lender Fees (All States, All Products)

| Fee | Amount |
|-----|--------|
| Underwriting fee | $1,290 |
| Discount points | Per rate selection (from pricer response) -- $0 if no points |

---

## Section B -- Third-Party Fees (All States, All Products)

| Fee | Amount |
|-----|--------|
| Credit report | $150 |
| Appraisal | $550 |
| Flood certification | $8 |
| Tax service fee | $85 |

**Section B total**: $793

**FHA Streamline and VA IRRRL exception**: No appraisal is required for FHA Streamline or VA IRRRL refinances. For these products, remove the $550 appraisal fee.

| Fee | Amount |
|-----|--------|
| Credit report | $150 |
| Flood certification | $8 |
| Tax service fee | $85 |

**Section B total (FHA Streamline / VA IRRRL)**: $243

---

## Product-Specific Fees

### Conventional

No additional product-specific closing cost fees.

**Note on mortgage insurance**: For conventional loans with LTV > 80%, the pricer returns `conventionalMI` with a monthly premium (`monthlyMI` on each rate option). This is an ongoing monthly cost, NOT a closing cost. Do NOT include conventional MI in the closing cost total. Present it separately as part of the monthly payment breakdown: "Monthly MI: $XXX/mo (drops off when LTV reaches 80%)".

### FHA -- Upfront Mortgage Insurance Premium (UFMIP)

- Amount: 1.75% of the base loan amount
- This fee is typically financed into the loan (added to the loan balance), not paid out of pocket
- Present as: "FHA Upfront MIP: $X (typically financed into the loan -- not paid out of pocket)"
- Example: $300,000 loan x 1.75% = $5,250 financed

**Integration note**: The pricer returns `financedFees.ufmip` for FHA loans. Use this exact amount rather than recalculating 1.75% manually. The pricer also returns `monthlyMip` on each rate option — use this for the monthly MIP line item.

### FHA Streamline -- UFMIP with Refund Netting

FHA Streamline refinances are FHA-to-FHA only (non-credit qualifying). The new UFMIP is 1.75% of the base mortgage amount, but the borrower may receive a partial refund of the UFMIP paid on the existing FHA loan, which is netted against the new UFMIP.

**UFMIP Refund Calculation**:

1. Determine `monthsSinceEndorsement`: the number of full months from the existing loan's origination date (endorsement date) to today.
2. Calculate refund percentage:
   - If monthsSinceEndorsement > 36: refundPercent = 0% (no refund)
   - If monthsSinceEndorsement <= 36: refundPercent = 82 - (2 * monthsSinceEndorsement), minimum 10%
   - Earliest streamline is month 7 (68% refund)
3. Calculate UFMIP refund amount: `ufmipRefundAmount = originalUFMIP * (refundPercent / 100)`
4. Net the refund against the new UFMIP:
   - `ufmipRefundCredit = min(ufmipRefundAmount, newUFMIP)`
   - If the refund exceeds the new UFMIP, the excess is refunded directly to the borrower by HUD (not applied to the loan)
   - `netUFMIP = newUFMIP - ufmipRefundCredit`

**Refund schedule reference** (months since endorsement → refund percent):

| Month | Refund % | Month | Refund % | Month | Refund % |
|-------|----------|-------|----------|-------|----------|
| 1 | 80% | 13 | 56% | 25 | 32% |
| 2 | 78% | 14 | 54% | 26 | 30% |
| 3 | 76% | 15 | 52% | 27 | 28% |
| 4 | 74% | 16 | 50% | 28 | 26% |
| 5 | 72% | 17 | 48% | 29 | 24% |
| 6 | 70% | 18 | 46% | 30 | 22% |
| 7 | 68% | 19 | 44% | 31 | 20% |
| 8 | 66% | 20 | 42% | 32 | 18% |
| 9 | 64% | 21 | 40% | 33 | 16% |
| 10 | 62% | 22 | 38% | 34 | 14% |
| 11 | 60% | 23 | 36% | 35 | 12% |
| 12 | 58% | 24 | 34% | 36 | 10% |
| >36 | 0% | | | | |

Present as: "FHA Upfront MIP: $X (new UFMIP) minus $Y (refund credit from existing UFMIP) = $Z net UFMIP (financed into the loan)"

**FHA Streamline Max Loan Amount** (HUD 4000.1 Streamline Worksheet):

The max loan amount for an FHA Streamline is calculated as follows:

1. **Calculate Outstanding Principal Balance (OPB)**:
   - `calculatedOPB = currentUPB + interestCharge + proratedMIP`
   - `interestCharge` = one month's interest on the UPB (non-delinquent interest only)
   - `proratedMIP` = up to 2 months of monthly MIP (prorated from last paid-through date)
   - CANNOT include: delinquent interest, late charges, escrow shortages

2. **Calculate Base Mortgage**:
   - `baseMortgage = calculatedOPB - ufmipRefundCredit`

3. **Calculate New UFMIP**:
   - `newUFMIP = baseMortgage * 0.0175`

4. **Calculate Total Mortgage**:
   - `totalMortgage = baseMortgage + newUFMIP`

5. **County Loan Limit Check**:
   - If `totalMortgage > countyFHALoanLimit`: `maxLoan = min(countyFHALoanLimit, originalPrincipalBalance)`
   - Otherwise: `maxLoan = totalMortgage`

**FHA Streamline Closing Costs -- CANNOT Be Financed**:

Unlike standard FHA refinances, closing costs on FHA Streamline refinances CANNOT be rolled into the loan. They must be paid either:
- Out of pocket by the borrower, OR
- Via lender credit (premium pricing -- pricing at a slightly above-market rate to generate a lender credit that covers closing costs)

Most FHA Streamline borrowers prefer $0 or minimal cash to close. When presenting FHA Streamline quotes, prioritize rate options that generate enough lender credit to cover the estimated closing costs.

### VA -- Funding Fee

Check the `vaFundingFeeType` from the scenario context (collected during the borrower interview in the refi-quote workflow, Section 1.3.3.1). This field is set during Phase 1 data collection — do not ask the borrower again.

**Funding fee rates:**
- If `vaFundingFeeType: 'exempt'`: Funding fee = $0
- If **VA IRRRL (rateTermRefi)**: Funding fee = 0.5% of loan amount (financed), unless exempt
- If **VA cash-out** and `vaFundingFeeType: 'firstTime'`: Funding fee = 2.15% of loan amount (financed)
- If **VA cash-out** and `vaFundingFeeType: 'subsequent'`: Funding fee = 3.3% of loan amount (financed)
- Present as: "VA Funding Fee: $X (typically financed into the loan -- not paid out of pocket)"

**Integration note**: The pricer returns `financedFees.vaFundingFee` for all VA loans — use this exact amount rather than recalculating the percentage. When exempt, the pricer returns `vaFundingFee: 0` and `totalFinanced: 0`. The `vaFundingFeeType` field is a pricer input — the closing costs skill should read it from the scenario context rather than asking the borrower separately.

**VA IRRRL Closing Costs -- CAN Be Financed**:

Unlike FHA Streamline refinances, closing costs on VA IRRRL refinances CAN be financed into the new loan amount.

---

## State Fee Schedules (Historical Reference Only — NOT Authoritative)

**IMPORTANT:** The per-state fee schedules below are historical reference material maintained for human review. **They are NOT the source of truth for dollar amounts in borrower quotes.** The authoritative numbers live in the mortgage-pricer service's `ClosingCostCalculator` and are returned by the `~~pricer calculate_closing_cost` MCP tool.

The pricer's per-state formulas may differ from these reference tables (different settlement fees, CPL amounts, title insurance bracket formulas, or refi discounts), and the pricer numbers are the ones that match the production quoting flow. **Always call the tool — do not sum these tables manually.**

If a figure from the tool surprises you, that is a signal to investigate in the pricer repo (`server/src/services/closingCostCalculator.ts`), not a reason to override the tool with the numbers below.

Each state schedule below contains:
- **Section C**: Settlement/closing fee, Closing Protection Letter (CPL), lender's title insurance
- **Section E**: Recording fees, state-specific taxes

---

### Georgia (GA)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement fee | $675 |
| Closing Protection Letter (CPL) | $50 |
| Lender's title insurance | See formula below |

**GA Lender's Title Insurance -- Basic Loan Policy (CTICGA rates, effective 3/1/2024):**

| Loan Amount Range | Rate |
|-------------------|------|
| $0 -- $50,000 | $200 minimum |
| $50,001 -- $100,000 | $200 + $4.00 per $1,000 over $50,000 |
| $100,001 -- $500,000 | $400 + $3.30 per $1,000 over $100,000 |
| $500,001+ | $1,720 + $2.95 per $1,000 over $500,000 |

Calculate in brackets -- each tier applies only to the amount within that range.

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Georgia Intangible Tax | $3.00 per $1,000 of new loan amount |
| GRMA | $10 |
| Recording | $60 |

---

### Alabama (AL)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement fee | $600 (estimate) |
| CPL | $25 |
| Lender's title insurance | ~0.5% of loan amount (filed rates vary by underwriter; use 0.5% as estimate) |

Note: Alabama is a filed-rate state. Exact bracket schedules vary by underwriter. The 0.5% estimate with a 30% reissue discount for refinances is the industry norm.

**Reissue discount**: 30-40% off base rate when prior policy exists (automatic for refinances).

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Mortgage recordation tax | $1.50 per $1,000 of new loan amount ($0.15 per $100) |
| Recording fees | $75 (estimate; varies by county) |

---

### Florida (FL)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement fee | $750 |
| CPL | $45 |
| Lender's title insurance | See formula below |

**FL Lender's Title Insurance -- Promulgated Rates (standalone loan policy, no simultaneous issue):**

| Loan Amount Range | Rate per $1,000 |
|-------------------|-----------------|
| $0 -- $100,000 | $5.75 |
| $100,001 -- $1,000,000 | $5.00 |

Minimum premium: $100. Calculate in brackets -- each tier applies only to the amount within that range.

**Reissue rate** (if prior policy exists -- no expiration on eligibility):

| Loan Amount Range | Reissue Rate per $1,000 |
|-------------------|------------------------|
| $0 -- $100,000 | $3.30 |
| $100,001 -- $1,000,000 | $3.00 |

Any amount exceeding the prior policy amount is charged at the full basic rate.

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Documentary stamp tax | $3.50 per $1,000 of new loan amount |
| Intangible tax | $2.00 per $1,000 of new loan amount |
| Recording fees | $175 (estimate; $10 first page + $8.50/additional) |

**Combined FL state taxes: $5.50 per $1,000 of loan amount.** This applies to the full new loan amount for refinances with a new lender (which is the standard case for broker-originated refinances).

---

### Kentucky (KY)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement fee | $450 |
| CPL | $50 |
| Lender's title insurance | See formula below |

**KY Lender's Title Insurance -- Filed Rates (Stewart, effective 3/3/2023):**

| Loan Amount Range | Rate |
|-------------------|------|
| $0 -- $100,000 | $500 flat |
| $100,001 -- $300,000 | $500 + $3.85 per $1,000 over $100,000 |
| $300,001 -- $1,000,000 | $1,270 + $2.00 per $1,000 over $300,000 |

**Reissue/refinance rate**: 70% of standard rate (30% discount). Applies when borrower is refinancing an existing loan.

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Transfer/mortgage tax | $0 (not applicable on refinance) |
| Recording fees | $100 (estimate; $46 base most counties + per-page charges) |

---

### North Carolina (NC)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement/attorney fee | $900 (NC is attorney-closing state; includes title search) |
| CPL | $25 |
| Title commitment fee | $16.50 |
| Lender's title insurance | See formula below |

**NC Lender's Title Insurance -- State-Filed Uniform Rates (effective 10/1/2025):**

| Loan Amount Range | Rate per $1,000 |
|-------------------|-----------------|
| $0 -- $100,000 | $2.78 |
| $100,001 -- $500,000 | $2.17 |
| $500,001 -- $2,000,000 | $1.41 |

Minimum premium: $56. Calculate in brackets -- each tier applies only to the amount within that range.

**Reissue rate**: 50% of regular rate if prior policy exists within 15 years. Applies up to the prior policy amount; any excess at full rate.

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Excise tax / revenue stamps | $0 (exempt on refinance -- DOT is not a conveyance) |
| Recording -- deed of trust | $64 flat |

---

### Oregon (OR)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement/escrow fee | $600 (estimate) |
| CPL | $35 |
| Lender's title insurance | See table below |

**OR Lender's Title Insurance -- OTIRO Rates (table-based, effective 9/4/2023):**

| Loan Amount | Standard Premium |
|-------------|-----------------|
| $100,000 | $500 |
| $150,000 | $625 |
| $200,000 | $750 |
| $250,000 | $875 |
| $300,000 | $975 |
| $400,000 | $1,150 |
| $500,000 | $1,350 |

For amounts between table values, interpolate linearly. For amounts over $500,000, use approximately $2.50-$3.50 per additional $1,000.

**Substitution rate (refinance discount)**: ~70-75% of standard rate when replacing an existing loan policy on the same property.

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Mortgage/transfer tax | $0 (Oregon has no mortgage recording tax) |
| Recording -- trust deed | $175 (estimate; $86-$93 first page + $5/additional page, varies by county) |

---

### South Carolina (SC)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement/attorney fee | $750 (SC is attorney-closing state) |
| CPL | $35 |
| Lender's title insurance | See formula below |

**SC Lender's Title Insurance -- Filed Rates (WFG schedule):**

| Loan Amount Range | Rate per $1,000 |
|-------------------|-----------------|
| $0 -- $50,000 | $4.32 |
| $50,001 -- $100,000 | $3.60 |
| $100,001 -- $500,000 | $2.52 |
| $500,001+ | $2.16 |

Calculate in brackets -- each tier applies only to the amount within that range.

**Reissue rate**: 50% of base premium if prior policy exists within 10 years. Prior policy must be furnished.

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Deed recording fee / transfer tax | $0 (not applicable on refinance) |
| Recording -- deed of trust | $25 |
| Recording -- release of prior mortgage | $25 |

---

### Tennessee (TN)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement fee | $550 |
| CPL | $25 |
| Lender's title insurance | See formula below |

**TN Lender's Title Insurance -- Filed Rates:**

| Loan Amount Range | Rate per $1,000 |
|-------------------|-----------------|
| $0 -- $50,000 | $2.50 |
| $50,001 -- $100,000 | $2.00 |
| $100,001 -- $500,000 | $1.75 |
| $500,001+ | $1.50 |

Minimum premium: $25. Calculate in brackets -- each tier applies only to the amount within that range.

**Reissue rate** (by age of prior policy):
- 3-4 years: 40% of original rate
- 4-5 years: 50% of original rate
- 5-10 years: 60% of original rate
- Over 10 years: 100% (no discount)

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Tennessee indebtedness (mortgage) tax | $1.15 per $1,000 of new loan amount (first $2,000 exempt) |
| Recording -- deed of trust | $80 (estimate; $12 base + $5/page for ~15 pages + $1 register fee) |

Formula for TN mortgage tax: `(loanAmount - 2000) / 100 * 0.115`

Quick approximation: `loanAmount * 0.00115`

---

### Texas (TX)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement fee | $500 |
| CPL (Insured Closing Letter) | $25 |
| Lender's title insurance | See formula below |

**TX Lender's Title Insurance -- TDI Promulgated Rates (effective 3/1/2026, -6.2% from 2019):**

For loan amounts over $100,000:
```
basicPremium2019 = (loanAmount - 100000) * 0.00527 + 832
premium2026 = basicPremium2019 * 0.938
```

For loan amounts $100,000 and under: $832 * 0.938 = $780.42 (use $780)

**R-8 Refinance Credit:**
- Prior loan policy within 0-4 years: 50% credit off basic premium
- Prior loan policy within 4-8 years: 25% credit off basic premium
- Prior loan policy over 8 years: no credit

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Mortgage/transfer tax | $0 (Texas has no mortgage recording tax) |
| Recording -- deed of trust | $75 (estimate; $25 first page + $4/additional page) |

---

### Utah (UT)

#### Section C -- Title and Settlement Fees

| Fee | Amount |
|-----|--------|
| Settlement fee | $600 (estimate) |
| CPL | $25 |
| Lender's title insurance | See table below |

**UT Lender's Title Insurance -- Competitive Market (Stewart rates, effective 4/10/2023):**

| Loan Amount Range | Rate |
|-------------------|------|
| $0 -- $10,000 | $200 flat |
| $10,001 -- $100,000 | $200 + $5.50 per $1,000 over $10,000 |
| $100,001 -- $200,000 | $695 + $5.00 per $1,000 over $100,000 (approx) |
| $200,001 -- $500,000 | $1,195 + $4.00 per $1,000 over $200,000 (approx) |
| $500,001+ | $2,395 + $2.00 per $1,000 over $500,000 (approx) |

**Refinance discount**: 50% of basic schedule for standard coverage loan policy.

#### Section E -- Recording and Taxes

| Fee | Amount |
|-----|--------|
| Mortgage/transfer tax | $0 (Utah has no mortgage tax) |
| Recording -- new deed of trust | $40 flat |
| Recording -- reconveyance | $40 flat |

---

## Presentation Procedure

Follow these steps in order when presenting closing costs. **All dollar amounts come from the `~~pricer calculate_closing_cost` MCP tool response — never from the per-state reference tables above, never from a percentage of the loan amount.**

1. **Validate property state.** Confirm the borrower's property state is in the licensed states list (GA, AL, FL, KY, NC, OR, SC, TN, TX, UT). If not, stop and defer to the `mortgage-compliance` skill. Do not estimate fees for unlicensed states — not even as a rough figure.

2. **Determine product type.** Identify whether the loan is Conventional, FHA, FHA Streamline, VA IRRRL, or VA Cash-Out. If the borrower has an existing FHA loan and wants a rate/term refinance, the product is FHA Streamline. If the borrower has an existing VA loan and wants a rate/term refinance, the product is VA IRRRL.

3. **If VA, confirm funding fee type.** Read `vaFundingFeeType` from the scenario context (set during Phase 1 data collection). If not already set, ask the borrower about first-time vs. subsequent use and disability exemption (see mortgage-loan-officer skill, Section 3).

4. **Call `~~pricer calculate_closing_cost`** with the scenario data:

   ```
   ~~pricer calculate_closing_cost
     state: <borrower's property state>
     loanAmount: <base loan amount — for FHA Streamline this is the new base mortgage after UFMIP refund netting, per the HUD 4000.1 worksheet>
     productType: <"conventional" | "fha" | "va">
     isStreamline: <true for FHA Streamline or VA IRRRL>
     discountPointsDollar: <dollar cost of discount points on the selected rate, or 0>
     monthsSinceEndorsement: <FHA streamline only>
     previousUfmipAmount: <FHA streamline only>
   ```

5. **Map the response into the itemized table.** Use field values VERBATIM — do not recompute, do not round, do not cross-check against the per-state reference tables below (those are historical reference only and may differ from the pricer's canonical numbers).

   - **Section A — Lender Fees**: `lenderFees.underwriting` + `lenderFees.discountPoints`
   - **Section B — Third-Party Fees**: `thirdPartyFees.creditReport`, `thirdPartyFees.appraisal`, `thirdPartyFees.floodCert`, `thirdPartyFees.taxService`, subtotal = `thirdPartyFees.subtotal`
   - **Section C — Title and Settlement Fees**: `titleSettlement.settlementFee`, `titleSettlement.titleInsurance`, `titleSettlement.cpl`, subtotal = `titleSettlement.subtotal`
   - **Section E — Recording and Taxes**: `governmentRecording.recordingFees`, `governmentRecording.stateTaxes` (with label = `governmentRecording.taxDescription`), subtotal = `governmentRecording.subtotal`

6. **Grand total** = `response.total`. This is the out-of-pocket closing cost figure. **Do not re-sum the sections yourself.** If you want to sanity-check, verify that `lenderFees.underwriting + lenderFees.discountPoints + thirdPartyFees.subtotal + titleSettlement.subtotal + governmentRecording.subtotal == total`, but always present `total` verbatim.

7. **Product-specific financed fees** come from `response.productSpecific` and are presented as SEPARATE line items outside the grand total:
   - **Conventional**: `productSpecific` is `undefined` — no financed fees.
   - **FHA (standard)**: `productSpecific.fhaUpfrontMip` = 1.75% of the base loan amount. Present as "FHA Upfront MIP: $X (typically financed into the loan — not paid out of pocket)".
   - **FHA Streamline**: `productSpecific.fhaUpfrontMip` is the new UFMIP and `productSpecific.fhaStreamlineUfmipRefund` is the refund credit from the existing UFMIP (when applicable). Present as: "FHA Upfront MIP: $X (new UFMIP) minus $Y (refund credit from existing UFMIP) = $Z net UFMIP (financed into the loan)". Note the FHA Streamline max loan amount per the HUD 4000.1 worksheet (see above) is computed upstream in the `mortgage-loan-officer` skill when building the scenario.
   - **VA IRRRL**: `productSpecific.vaFundingFee` = 0.5% of the loan amount unless exempt. Present as "VA Funding Fee: $X (typically financed into the loan — not paid out of pocket)". Note that VA IRRRL closing costs CAN also be financed into the new loan amount (presentation only; the pricer `total` still reflects out-of-pocket).
   - **VA Cash-Out**: `productSpecific.vaFundingFee` = 2.15% (firstTime) or 3.3% (subsequent). Present the same way.
   - **VA exempt**: The pricer returns `vaFundingFee: 0` — present "VA Funding Fee: $0 (exempt due to service-connected disability)".

8. **Grand total handling by product**:
   - **FHA Streamline**: The `total` is the amount that must be covered by lender credit or paid out of pocket — it CANNOT be financed into the new loan.
   - **VA IRRRL**: The `total` can be financed into the new loan amount if the borrower prefers, or paid out of pocket.
   - All others: `total` is paid at closing.

---

## Presentation Rules

### Itemized Table Format

Present fees in a clear itemized table grouped by section:

- **Section A -- Lender Fees**: Underwriting fee, discount points
- **Section B -- Third-Party Fees**: Credit report, appraisal, flood certification, tax service fee
- **Section C -- Title and Settlement Fees**: Settlement fee, CPL, lender's title insurance (and title commitment fee if applicable)
- **Section E -- Recording and Taxes**: Recording fees, state-specific taxes

Show subtotals per section and a grand total of estimated out-of-pocket closing costs.

If the loan is FHA or VA, show the financed fee (UFMIP or VA Funding Fee) as a separate line item below the grand total, clearly marked as "typically financed -- not paid out of pocket."

### FHA Streamline Presentation

For FHA Streamline quotes, present closing costs with a note about how they will be covered:
- "FHA Streamline closing costs cannot be financed into the loan. The estimated closing costs of $X can be covered by a lender credit if you select a rate with lender credit, or paid out of pocket."
- Show the UFMIP refund netting calculation: original UFMIP, refund percentage, refund credit, and net UFMIP.
- If max loan amount is a constraint, note it.

### VA IRRRL Presentation

For VA IRRRL quotes, note that closing costs can be financed:
- "VA IRRRL closing costs of $X can be financed into the new loan amount, or paid out of pocket."

### Required Compliance Disclosures

Include all of the following after the itemized table:

- "Fees shown are estimates and may change. Certain fees are subject to regulatory tolerance limits. You will receive an official Loan Estimate after submitting a full application."
- "Title insurance premium shown is an estimate. You have the right to shop for title services."
- If a reissue/refinance discount on title insurance may apply: "A refinance discount on title insurance may be available if a prior title policy exists on the property."

### Rules

- **All dollar amounts in a borrower quote MUST come from the `~~pricer calculate_closing_cost` MCP tool response.** Do NOT use percentage-of-loan heuristics (e.g. "~1.2% of loan amount"). Do NOT sum the per-state reference tables above manually. Do NOT round or adjust the tool's `total`.
- If the pricer tool returns an error or the borrower's state is not supported (anything other than AL/FL/GA/KY/NC/OR/SC/TN/TX/UT), STOP. Do not invent a closing cost figure. Defer to the `mortgage-compliance` skill and the unlicensed-state copy in `refi-quote.md`.
- Defer all regulatory questions to the `mortgage-compliance` skill.
- Do NOT include escrows (homeowners insurance, property taxes) or prepaid interest in the closing cost total. These are not costs of the refinance.
- Do NOT combine or simplify the itemized breakdown. Always present the full line-item detail.
- If a state has a $0 tax (e.g., no mortgage recording tax), still list it in the table with "$0" so the borrower sees it was considered.
