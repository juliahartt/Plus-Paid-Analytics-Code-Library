-- =========================================================================
-- MODULAR PAID CLASSIFICATION LOGIC
-- =========================================================================
-- This module can be inserted into other queries to classify leads as 
-- paid vs non-paid based on Shopify's IB Leads logic
-- 
-- REQUIRED FIELDS in your base table/CTE:
-- - lead_source_original
-- - lead_source_original_category  
-- - commercial_channel
-- - marketing_subchannel
-- - UTM_Source__c (from raw Salesforce Banff lead table)
--
-- USAGE: Replace {YOUR_BASE_TABLE} with your actual table/CTE name
-- =========================================================================

-- Step 1: Channel Classification

CASE
    WHEN lead_source_original = 'Content Syndication' THEN 'content syndication'
    WHEN lead_source_original = 'Content' AND (
        LOWER(UTM_Source__c) LIKE '%madisonlogic%'
        OR LOWER(UTM_Source__c) LIKE '%techtarget%'
        OR LOWER(UTM_Source__c) LIKE '%integrate%'
    ) THEN 'content syndication'
    WHEN lead_source_original_category = "Marketing" 
        AND LOWER(commercial_channel) LIKE '%paid%' 
        AND marketing_subchannel = 'content syndication' THEN 'content syndication'
    WHEN lead_source_original_category = "Marketing" 
        AND LOWER(commercial_channel) LIKE '%paid%' 
        AND marketing_subchannel <> 'content syndication' THEN 'paid'
    WHEN lead_source_original_category = "Marketing" 
        AND LOWER(commercial_channel) NOT LIKE '%paid%' THEN 'non-paid'
    ELSE 'null' 
END AS channel,

-- Step 2: Channel Category (Paid vs Non-Paid)

CASE 
    WHEN (
        CASE
            WHEN lead_source_original = 'Content Syndication' THEN 'content syndication'
            WHEN lead_source_original = 'Content' AND (
                LOWER(UTM_Source__c) LIKE '%madisonlogic%'
                OR LOWER(UTM_Source__c) LIKE '%techtarget%'
                OR LOWER(UTM_Source__c) LIKE '%integrate%'
            ) THEN 'content syndication'
            WHEN lead_source_original_category = "Marketing" 
                AND LOWER(commercial_channel) LIKE '%paid%' 
                AND marketing_subchannel = 'content syndication' THEN 'content syndication'
            WHEN lead_source_original_category = "Marketing" 
                AND LOWER(commercial_channel) LIKE '%paid%' 
                AND marketing_subchannel <> 'content syndication' THEN 'paid'
            WHEN lead_source_original_category = "Marketing" 
                AND LOWER(commercial_channel) NOT LIKE '%paid%' THEN 'non-paid'
            ELSE 'null' 
        END
    ) = 'non-paid' THEN 'non-paid'
    ELSE 'paid' 
END AS channel_category

-- =========================================================================
-- FILTER CONDITION (add to WHERE clause)
-- =========================================================================
-- This ensures only leads with valid channel classifications are included

AND CASE
    WHEN lead_source_original = 'Content Syndication' THEN 'content syndication'
    WHEN lead_source_original = 'Content' AND (
        LOWER(UTM_Source__c) LIKE '%madisonlogic%'
        OR LOWER(UTM_Source__c) LIKE '%techtarget%'
        OR LOWER(UTM_Source__c) LIKE '%integrate%'
    ) THEN 'content syndication'
    WHEN lead_source_original_category = "Marketing" 
        AND LOWER(commercial_channel) LIKE '%paid%' 
        AND marketing_subchannel = 'content syndication' THEN 'content syndication'
    WHEN lead_source_original_category = "Marketing" 
        AND LOWER(commercial_channel) LIKE '%paid%' 
        AND marketing_subchannel <> 'content syndication' THEN 'paid'
    WHEN lead_source_original_category = "Marketing" 
        AND LOWER(commercial_channel) NOT LIKE '%paid%' THEN 'non-paid'
    ELSE NULL 
END IS NOT NULL

-- =========================================================================
-- SIMPLIFIED VERSION (if you only need channel_category)
-- =========================================================================
CASE 
    WHEN lead_source_original_category = "Marketing" 
        AND LOWER(commercial_channel) NOT LIKE '%paid%' THEN 'non-paid'
    WHEN lead_source_original_category = "Marketing" 
        AND LOWER(commercial_channel) LIKE '%paid%' THEN 'paid'
    WHEN lead_source_original = 'Content Syndication' THEN 'paid'
    WHEN lead_source_original = 'Content' AND (
        LOWER(UTM_Source__c) LIKE '%madisonlogic%'
        OR LOWER(UTM_Source__c) LIKE '%techtarget%'
        OR LOWER(UTM_Source__c) LIKE '%integrate%'
    ) THEN 'paid'
    ELSE 'paid' 
END AS channel_category_simplified 

-- =========================================================================
-- Key Components
-- =========================================================================
-- Channel Classification - Categorizes leads into:
    -- content syndication
    -- paid
    -- non-paid
    -- null
-- Channel Category - Final classification into paid vs non-paid
-- Filter Condition - Ensures only valid classifications are included
-- Simplified Version - A streamlined version if you only need the final paid/non-paid categorization

-- =========================================================================
-- Required Fields
-- =========================================================================
-- lead_source_original
-- lead_source_original_category
-- commercial_channel
-- marketing_subchannel
-- UTM_Source__c (from raw Salesforce Banff lead table)

-- =========================================================================
-- Key Logic
-- =========================================================================
-- Content syndication (direct or via specific UTM sources) = paid
-- Marketing leads with paid commercial channel = paid
-- Marketing leads with non-paid commercial channel = non-paid
-- Everything else defaults to paid

/* =============================================================================
MODULAR DLV ANALYSIS BY CATEGORICAL FIELD
=============================================================================

DESCRIPTION: 
This query pulls Dollar Lead Value (DLV) metrics grouped by any categorical 
field from the dollar_lead_value_payback dataset. 

CUSTOMIZATION:
Replace [CATEGORICAL_FIELD] with any categorical dimension from the dataset.
Common options include:
- campaign_targeting_type
- campaign_type  
- channel
- market
- product_line
- audience_segment
- ad_format
- [any other categorical field in the dataset]

METRICS RETURNED:
- total_spend: Total spend in USD
- created_leads: Total attributed leads
- adj_dlv: Total adjusted dollar lead value in USD

FILTERS:
- Date range: Modify the date >= condition as needed
- Cost center: Currently filtered to 'Plus' - adjust as needed
=============================================================================
*/

-- STEP 1: Replace [CATEGORICAL_FIELD] with your desired categorical dimension
SELECT 
  [CATEGORICAL_FIELD],                          -- <-- CUSTOMIZE THIS FIELD
  SUM(spend_usd) AS total_spend,
  SUM(leads_attributed) AS created_leads,
  SUM(adjusted_dollar_lead_value_usd) AS adj_dlv,
  
  -- OPTIONAL: Add calculated metrics
  SAFE_DIVIDE(SUM(spend_usd), (SUM(adjusted_dollar_lead_value_usd) / 36)) AS payback,
  SAFE_DIVIDE(SUM(spend_usd), SUM(leads_attributed)) AS cost_per_lead

FROM `shopify-dw.mart_commercial_optimization.dollar_lead_value_payback`

WHERE 1=1
  AND date >= '2025-01-01'                      -- <-- CUSTOMIZE DATE RANGE
  AND spend_cost_center_sub_group = 'Plus'     -- <-- CUSTOMIZE COST CENTER

GROUP BY [CATEGORICAL_FIELD]                    -- <-- ENSURE THIS MATCHES FIELD ABOVE

ORDER BY adj_dlv DESC                          -- <-- OPTIONAL: ORDER BY PREFERRED METRIC

/*
=============================================================================
EXAMPLE USAGE:

To analyze by campaign targeting type:
Replace [CATEGORICAL_FIELD] with: campaign_targeting_type

To analyze by channel:
Replace [CATEGORICAL_FIELD] with: channel

To analyze by market:
Replace [CATEGORICAL_FIELD] with: market
=============================================================================
*/

/* =========================================================================
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
