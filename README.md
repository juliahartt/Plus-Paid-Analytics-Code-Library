# Plus-Paid-Analytics-Code-Library
This repo contains frequently referenced scripts for Plus Paid Media Analytics team (e.g., WBRs) and modularized code to expedite commonly used queries.

The Paid Media Analytics team defaults to using the below tables:
1. **For Sales Lead:** `shopify-dw.sales.sales_leads`
2. **For Opportunity Data:** `shopify-dw.sales.sales_opportunities`
3. **For DLV & Attribution:** `shopify-dw.mart_commercial_optimization.dollar_lead_value_payback`
4. **To Pull from RAD:** `sdp-for-analysts-platform.rev_ops_prod.modelled_rad`

The team will default to using the modelled tables (example: #1 and #2 above) and reference the below raw Salesforce Banff tables sparingly:
1. `shopify-dw.raw_salesforce_banff.lead`
2. `shopify-dw.raw_salesforce_banff.opportunity`
3. `shopify-dw.raw_salesforce_banff.account`
4. `shopify-dw.raw_salesforce_banff.contact`

To ensure alignment between Majority of Paid Media Analytics Team's queries should be limited to the following Primary Products of Interest:
1. Plus
2. Commerce Components (CCS)
3. B2B
