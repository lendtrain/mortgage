# Closing Costs

This skill provides itemized estimated closing costs for refinance transactions. Use it to calculate and present state-specific, product-specific fee breakdowns based on the borrower's property state, loan amount, and product type (Conventional, FHA, VA).

**Scope**: Refinance transactions only. Purchase transactions are not supported in this phase.

**Licensed states**: Georgia (GA), Alabama (AL), Florida (FL), Kentucky (KY), North Carolina (NC), Oregon (OR), South Carolina (SC), Tennessee (TN), Texas (TX), Utah (UT).

**Products**: Conventional, FHA, FHA Streamline, VA IRRRL, VA Cash-Out.

**Integration**: This skill is referenced by the `mortgage-loan-officer` skill when presenting closing cost estimates as part of a refinance quote.

**Required inputs from the conversation**:
1. Property state
2. Loan amount
3. Product type (Conventional, FHA, or VA)
4. For VA loans only: the `vaFundingFeeType` (`'firstTime'`, `'subsequent'`, or `'exempt'`)
5. For FHA Streamline: borrower's mortgage statement (for UPB, current rate, origination date, monthly MIP)
6. For VA IRRRL: borrower's mortgage statement (for UPB, current rate, origination date/first payment date)

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

## State Fee Schedules

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

## Calculation Procedure

Follow these steps in order when calculating closing costs:

1. **Validate property state.** Confirm the borrower's property state is in the licensed states list (GA, AL, FL, KY, NC, OR, SC, TN, TX, UT). If not, stop and defer to the `mortgage-compliance` skill. Do not estimate fees for unlicensed states.

2. **Determine product type.** Identify whether the loan is Conventional, FHA, FHA Streamline, VA IRRRL, or VA Cash-Out. If the borrower has an existing FHA loan and wants a rate/term refinance, the product is FHA Streamline. If the borrower has an existing VA loan and wants a rate/term refinance, the product is VA IRRRL.

3. **If VA, confirm funding fee type.** Read `vaFundingFeeType` from the scenario context (set during Phase 1 data collection). If not already set, ask the borrower about first-time vs. subsequent use and disability exemption (see mortgage-loan-officer skill, Section 3).

4. **Look up the state fee schedule.** Locate the correct state section above for the borrower's property state.

5. **Calculate Section A fees.** Underwriting fee ($1,290) plus any discount points from the selected rate. If the rate has no points, discount points = $0.

6. **Calculate Section B fees.** For Conventional, FHA, and VA Cash-Out: fixed total $793 ($150 credit report + $550 appraisal + $8 flood certification + $85 tax service fee). For FHA Streamline and VA IRRRL: fixed total $243 ($150 credit report + $8 flood certification + $85 tax service fee) -- no appraisal required.

7. **Calculate Section C fees.** Use the state's settlement fee, CPL, and lender's title insurance formula with the borrower's loan amount. Apply the bracket/formula calculations exactly as specified. Do not apply reissue/refinance discounts unless the borrower confirms a prior title policy exists.

8. **Calculate Section E fees.** Use the state's recording fees and any applicable state taxes with the borrower's loan amount. Apply tax formulas exactly as specified.

9. **Calculate product-specific fees if applicable.**
   - **Conventional**: No additional fees.
   - **FHA (standard)**: 1.75% of loan amount (UFMIP, financed). Use `financedFees.ufmip` from the pricer response (1.75% of loan amount, financed).
   - **FHA Streamline**: Calculate UFMIP with refund netting (see "FHA Streamline -- UFMIP with Refund Netting" section above). Calculate max loan amount per the HUD 4000.1 worksheet formula. Use `financedFees.ufmip` from the pricer response. Calculate UFMIP refund netting per the existing formula. The pricer's `financedFees.totalLoanAmount` reflects the total after financed fees.
   - **VA IRRRL** (non-exempt): 0.5% of loan amount (financed). Closing costs may be financed into the loan. Use `financedFees.vaFundingFee` from the pricer response.
   - **VA Cash-Out** (firstTime): 2.15% of loan amount (financed). Use `financedFees.vaFundingFee` from the pricer response.
   - **VA Cash-Out** (subsequent): 3.3% of loan amount (financed). Use `financedFees.vaFundingFee` from the pricer response.
   - **VA exempt** (`vaFundingFeeType: 'exempt'`): $0 funding fee regardless of refinance type. The pricer returns `vaFundingFee: 0` and `totalFinanced: 0`.

10. **Sum all sections for total estimated closing costs.** Add Section A + Section B + Section C + Section E subtotals. For FHA Streamline: this is the amount that must be covered by lender credit or paid out of pocket (cannot be financed). For VA IRRRL: this amount can be financed into the new loan if the borrower prefers. Do not include financed fees (UFMIP, VA Funding Fee) in the out-of-pocket total.

11. **Separately note financed fees.** If FHA or VA, present the financed fee amount below the total with the note that it is typically financed into the loan and not paid out of pocket.

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

- Defer all regulatory questions to the `mortgage-compliance` skill.
- Do NOT include escrows (homeowners insurance, property taxes) or prepaid interest in the closing cost total. These are not costs of the refinance.
- Do NOT combine or simplify the itemized breakdown. Always present the full line-item detail.
- If a state has a $0 tax (e.g., no mortgage recording tax), still list it in the table with "$0" so the borrower sees it was considered.
