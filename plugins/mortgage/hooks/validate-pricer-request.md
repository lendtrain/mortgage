# Pre-Pricer Request Validation

Before this tool call proceeds, validate the request against the following mandatory business rules. If ANY check fails, you MUST block the tool call and inform the borrower with the specified error message. Do NOT call the pricer with invalid data.

## 1. State Licensing (CRITICAL — Regulatory)

The licensed states are: AL, FL, GA, KY, NC, OR, SC, TN, TX, UT.

If the `state` field is NOT in this list, BLOCK the tool call and respond:

> "I appreciate your interest, but LendTrain is not currently licensed to originate loans in [state]. You can view the full list of states where we are licensed at atlantichm.com/legal."

Do NOT proceed. Do NOT call the pricer. This is a criminal regulatory violation if ignored.

## 2. VA Funding Fee Type Required

If `productType` is `'va'` (or if using `calculate_all_pricing` and the borrower has a VA loan), the `vaFundingFeeType` field MUST be present and set to one of: `'firstTime'`, `'subsequent'`, or `'exempt'`.

If `vaFundingFeeType` is missing for a VA loan, BLOCK the tool call and ask:

> "Before I can price VA options, I need to know your VA funding fee status. Is this your first time using your VA loan benefit, or have you used it before? And do you have a VA disability rating of 10% or higher?"

Do NOT default `vaFundingFeeType` without explicit borrower input. The fee varies from 0% to 3.3%.

## 3. Property Value >= Loan Amount (Rate-Term Refi)

If `loanPurpose` is `'rateTermRefi'` and `propertyValue` < `loanAmount`, BLOCK the tool call and respond:

> "I noticed that the property value you provided ($[propertyValue]) is lower than your current loan balance ($[loanAmount]). This would mean you owe more than the home is worth. Could you double-check that estimate?"

Exception: VA IRRRL allows 100% LTV, so if `productType` is `'va'` and `loanPurpose` is `'rateTermRefi'`, allow `propertyValue` equal to `loanAmount`.

## 4. LTV Limit Validation

Calculate LTV: `ltv = (loanAmount / propertyValue) * 100`

Check against product-specific limits:

| Product | Loan Purpose | Max LTV |
|---------|-------------|---------|
| Conventional | All | 97% |
| FHA | rateTermRefi | 96.5% |
| FHA | cashOutRefi | 80% |
| VA | rateTermRefi (IRRRL) | 100% |
| VA | cashOutRefi | 80% |

If LTV exceeds the limit, BLOCK the tool call and inform the borrower of the maximum available. For cash-out, calculate the maximum cash-out amount within the LTV limit.

## 5. FHA Escrow Mandatory

If `productType` is `'fha'`, ensure `escrowWaiver` is NOT set to `true`. FHA loans require escrow. If `escrowWaiver` is `true`, silently override it to `false` before the tool call.

## 6. Required Fields Present

Verify these fields are present and valid before the tool call:
- `loanAmount` > 0
- `propertyValue` > 0
- `creditScore` is an integer between 300 and 850
- `loanPurpose` is `'rateTermRefi'` or `'cashOutRefi'`
- `propertyType` is one of: `'singleFamily'`, `'condo'`, `'townhouse'`, `'multiUnit'`, `'manufactured'`
- `occupancy` is one of: `'primary'`, `'secondHome'`, `'investment'`
- `state` is a 2-letter uppercase code
- `loanTerm` is one of: 10, 15, 20, 25, 30

If any required field is missing, BLOCK the tool call and ask the borrower for the missing information. Do NOT guess or default required fields.
