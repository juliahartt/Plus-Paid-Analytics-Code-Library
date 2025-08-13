----------------------------------------------------------------------------------------------------------
----------------------------- USED IN REVOPS QBR DASHBOARD / MARKETING PAGE ------------------------------
-------------------------------------- SCRIPT: Mktg_QBR_Dash_TOFU ----------------------------------------
----------------------------------------------------------------------------------------------------------

-- Combined IB Leads and MQLs: Lead, MQL, and DLV by segment, date, region, channel_category, with previous period columns
-- To filter for a specific year_quarter, set the value of @filter_year_quarter (e.g., '2025 Q2')
WITH base AS (
  SELECT 
    lv.segment,
    CASE
      WHEN lead_source_original = 'Content Syndication' THEN 'content syndication'
      WHEN lead_source_original = 'Content' AND (
        LOWER(UTM_Source__c) LIKE '%madisonlogic%' OR
        LOWER(UTM_Source__c) LIKE '%techtarget%' OR
        LOWER(UTM_Source__c) LIKE '%integrate%') THEN 'content syndication'
      WHEN lead_source_original_category = 'Marketing' AND LOWER(commercial_channel) LIKE '%paid%' AND spend_marketing_subchannel = 'content syndication' THEN 'content syndication'
      WHEN lead_source_original_category = 'Marketing' AND LOWER(commercial_channel) LIKE '%paid%' AND spend_marketing_subchannel <> 'content syndication' THEN 'paid'
      WHEN lead_source_original_category = 'Marketing' AND LOWER(commercial_channel) NOT LIKE '%paid%' THEN 'non-paid'
      ELSE 'null' END AS channel,
    DATE_TRUNC(lv.lead_created_at, quarter) AS quarter,
    lv.region,
    1 AS lead,
    CASE WHEN DATE(l.new_sales_ready_at) IS NOT NULL THEN 1 ELSE 0 END AS mql,
    last_touch_adjusted_dlv_usd,
    l.created_at,
    l.new_sales_ready_at
  FROM `shopify-dw.mart_commercial_optimization.dollar_lead_value_attribution` lv
  JOIN `shopify-dw.sales.sales_leads` l ON lv.lead_id = l.lead_id
  JOIN `shopify-dw.raw_salesforce_banff.lead` bl ON lv.lead_id = bl.id
  WHERE lv.is_last_touchpoint IS TRUE
    AND lv.product IN ('Plus', 'Commerce Components')
    AND DATE(l.created_at) >= '2024-01-01'
    AND DATE(l.created_at) <= '2025-06-30'
    AND (
      CASE
        WHEN lead_source_original = 'Content Syndication' THEN 'content syndication'
        WHEN lead_source_original = 'Content' AND (
          LOWER(UTM_Source__c) LIKE '%madisonlogic%' OR
          LOWER(UTM_Source__c) LIKE '%techtarget%' OR
          LOWER(UTM_Source__c) LIKE '%integrate%') THEN 'content syndication'
        WHEN lead_source_original_category = 'Marketing' AND LOWER(commercial_channel) LIKE '%paid%' AND spend_marketing_subchannel = 'content syndication' THEN 'content syndication'
        WHEN lead_source_original_category = 'Marketing' AND LOWER(commercial_channel) LIKE '%paid%' AND spend_marketing_subchannel <> 'content syndication' THEN 'paid'
        WHEN lead_source_original_category = 'Marketing' AND LOWER(commercial_channel) NOT LIKE '%paid%' THEN 'non-paid'
        ELSE NULL END
    ) IS NOT NULL
    AND lv.segment IN ('Enterprise', 'Large', 'Mid-Mkt','SMB')
)

, agg AS (
  SELECT
    segment,
    channel,
    quarter,
    region,
    SUM(lead) AS lead,
    SUM(mql) AS mql,
    SUM(last_touch_adjusted_dlv_usd) AS dlv
  FROM base
  GROUP BY segment, channel, quarter, region
)

, with_channel_category AS (
  SELECT
    segment,
    DATE(quarter) AS date,
    region,
    CASE WHEN channel = 'non-paid' THEN 'non-paid' ELSE 'paid' END AS channel_category,
    SUM(lead) AS lead,
    SUM(mql) AS mql,
    SUM(dlv) AS dlv
  FROM agg
  GROUP BY segment, DATE(quarter), region, channel_category
)

, with_prev AS (
  SELECT
    curr.segment,
    curr.date,
    CONCAT(EXTRACT(YEAR FROM curr.date), ' Q', CAST(EXTRACT(QUARTER FROM curr.date) AS STRING)) AS year_quarter,
    curr.region,
    curr.channel_category,
    curr.lead,
    curr.mql,
    curr.dlv,
    prev_q.lead AS prev_quarter_lead,
    prev_yq.lead AS prev_year_quarter_lead,
    prev_q.mql AS prev_quarter_mql,
    prev_yq.mql AS prev_year_quarter_mql,
    prev_q.dlv AS prev_quarter_dlv,
    prev_yq.dlv AS prev_year_quarter_dlv
  FROM with_channel_category curr
  LEFT JOIN with_channel_category prev_q
    ON curr.segment = prev_q.segment
    AND curr.region = prev_q.region
    AND curr.channel_category = prev_q.channel_category
    AND curr.date = DATE_ADD(prev_q.date, INTERVAL 1 QUARTER)
  LEFT JOIN with_channel_category prev_yq
    ON curr.segment = prev_yq.segment
    AND curr.region = prev_yq.region
    AND curr.channel_category = prev_yq.channel_category
    AND curr.date = DATE_ADD(prev_yq.date, INTERVAL 1 YEAR)
)

SELECT
  segment,
  date,
  year_quarter,
  region,
  channel_category,
  lead,
  mql,
  dlv,
  prev_quarter_lead,
  prev_year_quarter_lead,
  prev_quarter_mql,
  prev_year_quarter_mql,
  prev_quarter_dlv,
  prev_year_quarter_dlv
FROM with_prev
ORDER BY segment, date, region, channel_category; 
