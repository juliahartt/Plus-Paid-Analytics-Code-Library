-- =========================================================================
-- MODULAR INBOUND OPPORTUNITIES QUERY
-- =========================================================================
-- This module can be used to pull inbound opportunities for any desired 
-- time period and opportunity stage based on Shopify's IB BOFU logic
-- 
-- PARAMETERS TO CUSTOMIZE:
-- 1. Replace {START_DATE} and {END_DATE} with your desired date range
-- 2. Replace {OPPORTUNITY_STAGES} with desired metrics/stages
-- 3. Replace {TIME_GRANULARITY} with WEEK, MONTH, QUARTER, or DAY
-- 4. Adjust market segments, opportunity types, and other filters as needed
--
-- DATA SOURCE: sdp-for-analysts-platform.rev_ops_prod.modelled_rad
-- =========================================================================

WITH opportunity_data AS (
  SELECT
    metric,
    value_type,
    
    -- Dynamic date field based on metric/stage
    CASE
      WHEN metric = "Closed Won" THEN sf_close_date
      WHEN metric = "Closed Lost" THEN sf_close_date  
      WHEN metric = "Created" THEN sf_created_date
      WHEN metric = "Qualified SAL" THEN qualified_sal_date
      -- Add other metrics as needed:
      -- WHEN metric = "Stage X" THEN stage_x_date
    END AS relevant_date,
    
    -- Time period aggregation (customizable)
    CASE
      WHEN metric = "Closed Won" THEN DATE_TRUNC(DATE(sf_close_date), {TIME_GRANULARITY})
      WHEN metric = "Closed Lost" THEN DATE_TRUNC(DATE(sf_close_date), {TIME_GRANULARITY})
      WHEN metric = "Created" THEN DATE_TRUNC(DATE(sf_created_date), {TIME_GRANULARITY})
      WHEN metric = "Qualified SAL" THEN DATE_TRUNC(DATE(qualified_sal_date), {TIME_GRANULARITY})
    END AS time_period,
    
    quarter,
    year,
    ops_lead_source,
    sales_region,
    ops_market_segment,
    opportunity_type,
    SUM(value) as total_value
    
  FROM `sdp-for-analysts-platform.rev_ops_prod.modelled_rad`
  
  WHERE
    dataset = "Actuals" 
    AND metric IN ({OPPORTUNITY_STAGES})  -- e.g., ('Closed Won','Created','Qualified SAL','Closed Lost')
    AND value_type IN ('Total Revenue', 'Opportunity Deal Count')  -- Customize as needed
    AND ops_lead_source = "Inbound"  -- Focus on inbound opportunities
    AND opportunity_type = "New Business"  -- Focus on new business only
    AND ops_market_segment IN ('Mid Market', 'Large Accounts', 'Enterprise', 'SMB')  -- Customize as needed
    
    -- Date range filter (customize based on metric)
    AND (
      (metric = "Closed Won" AND DATE(sf_close_date) BETWEEN '{START_DATE}' AND '{END_DATE}')
      OR (metric = "Closed Lost" AND DATE(sf_close_date) BETWEEN '{START_DATE}' AND '{END_DATE}')
      OR (metric = "Created" AND DATE(sf_created_date) BETWEEN '{START_DATE}' AND '{END_DATE}')
      OR (metric = "Qualified SAL" AND DATE(qualified_sal_date) BETWEEN '{START_DATE}' AND '{END_DATE}')
    )
    
  GROUP BY ALL
)

SELECT
  metric,
  value_type,
  time_period,
  quarter,
  year,
  ops_lead_source,
  sales_region,
  ops_market_segment,
  opportunity_type,
  total_value
FROM opportunity_data
WHERE time_period IS NOT NULL  -- Exclude records with null dates
ORDER BY metric, value_type, time_period

-- =========================================================================
-- USAGE EXAMPLES
-- =========================================================================

-- Example 1: Closed Won opportunities for Q1 2024, weekly aggregation
/*
Replace:
{OPPORTUNITY_STAGES} → 'Closed Won'
{TIME_GRANULARITY} → WEEK
{START_DATE} → '2024-01-01'
{END_DATE} → '2024-03-31'
*/

-- Example 2: All opportunity stages for 2024, monthly aggregation
/*
Replace:
{OPPORTUNITY_STAGES} → 'Closed Won','Created','Qualified SAL','Closed Lost'
{TIME_GRANULARITY} → MONTH
{START_DATE} → '2024-01-01'
{END_DATE} → '2024-12-31'
*/

-- Example 3: Created opportunities for last 6 months, daily aggregation
/*
Replace:
{OPPORTUNITY_STAGES} → 'Created'
{TIME_GRANULARITY} → DAY
{START_DATE} → DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
{END_DATE} → CURRENT_DATE()
*/

-- =========================================================================
-- SIMPLIFIED VERSION (Single Stage)
-- =========================================================================
/*
SELECT
  metric,
  value_type,
  DATE_TRUNC(DATE(sf_close_date), WEEK) AS week_start,  -- Adjust date field and granularity
  quarter,
  year,
  ops_lead_source,
  sales_region,
  ops_market_segment,
  opportunity_type,
  SUM(value) as total_value

FROM `sdp-for-analysts-platform.rev_ops_prod.modelled_rad`

WHERE
  dataset = "Actuals" 
  AND metric = 'Closed Won'  -- Single stage
  AND value_type IN ('Total Revenue', 'Opportunity Deal Count')
  AND ops_lead_source = "Inbound"
  AND opportunity_type = "New Business"
  AND ops_market_segment IN ('Mid Market', 'Large Accounts', 'Enterprise', 'SMB')
  AND DATE(sf_close_date) BETWEEN '2024-01-01' AND '2024-12-31'  -- Date range
  
GROUP BY ALL
ORDER BY week_start
*/

-- =========================================================================
-- AVAILABLE FILTERS (Customize as needed)
-- =========================================================================
/*
METRICS/STAGES:
- 'Closed Won'
- 'Closed Lost' 
- 'Created'
- 'Qualified SAL'

VALUE_TYPES:
- 'Total Revenue'
- 'Opportunity Deal Count'

OPS_LEAD_SOURCE:
- 'Inbound'
- 'Outbound'

OPPORTUNITY_TYPE:
- 'New Business'

OPS_MARKET_SEGMENT:
- 'Mid Market'
- 'Large Accounts'
- 'Enterprise'
- 'SMB'

TIME_GRANULARITY:
- DAY
- WEEK
- MONTH
- QUARTER
- YEAR
*/ 
