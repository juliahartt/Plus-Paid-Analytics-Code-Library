WITH Q2_CW_actuals AS (
  SELECT
    rad.metric,
    rad.value_type,
    DATE_TRUNC(
      CASE
        WHEN rad.metric = 'Closed Won' THEN DATE(rad.sf_close_date)
        WHEN rad.metric = 'Closed Lost' THEN DATE(rad.sf_close_date)
        WHEN rad.metric = 'Created' THEN DATE(rad.sf_created_date)
        WHEN rad.metric = 'Qualified SAL' THEN DATE(rad.qualified_sal_date)
        ELSE NULL END,
      QUARTER
    ) AS quarter_start,
    rad.quarter,
    rad.year,
    rad.ops_lead_source,
    rad.sales_region,
    rad.ops_market_segment,
    rad.opportunity_type,
    rad.opportunity_id,
    opp.total_revenue_usd
  FROM `sdp-for-analysts-platform.rev_ops_prod.modelled_rad` rad
  LEFT JOIN `shopify-dw.sales.sales_opportunities` opp
    ON opp.opportunity_id = rad.opportunity_id
  WHERE
    rad.dataset = 'Actuals'
    AND rad.metric = 'Closed Won'
    AND rad.value_type = 'Opportunity Deal Count'
    AND rad.year = 2025
    AND rad.quarter = 'Q2'
    AND rad.ops_lead_source = 'Inbound'
    AND rad.opportunity_type = 'New Business'
    AND rad.ops_market_segment IN ('Mid Market','Large Accounts','Enterprise')
),

leads_with_channel AS (
  SELECT
    l.converted_opportunity_id,
    l.lead_source_original,
    bl.UTM_Source__c,
    l.lead_source_original_category,
    lv.commercial_channel,
    lv.marketing_subchannel,
    CASE
      WHEN l.lead_source_original = 'Content Syndication' THEN 'content syndication'
      WHEN l.lead_source_original = 'Content' AND (
        LOWER(bl.UTM_Source__c) LIKE '%madisonlogic%' OR
        LOWER(bl.UTM_Source__c) LIKE '%techtarget%' OR
        LOWER(bl.UTM_Source__c) LIKE '%integrate%') THEN 'content syndication'
      WHEN l.lead_source_original_category = 'Marketing' AND LOWER(lv.commercial_channel) LIKE '%paid%' AND lv.marketing_subchannel = 'content syndication' THEN 'content syndication'
      WHEN l.lead_source_original_category = 'Marketing' AND LOWER(lv.commercial_channel) LIKE '%paid%' AND lv.marketing_subchannel <> 'content syndication' THEN 'paid'
      WHEN l.lead_source_original_category = 'Marketing' AND LOWER(lv.commercial_channel) NOT LIKE '%paid%' THEN 'non-paid'
      ELSE NULL
    END AS channel_category
  FROM `shopify-dw.mart_commercial_optimization.dollar_lead_value_attribution` lv
  JOIN `shopify-dw.sales.sales_leads` l
    ON lv.lead_id = l.lead_id
  JOIN `shopify-dw.raw_salesforce_banff.lead` bl
    ON lv.lead_id = bl.id
  WHERE
    lv.is_last_touchpoint = TRUE
    AND lv.product IN ('Plus', 'Commerce Components')
    AND l.converted_opportunity_id IS NOT NULL
)

SELECT
DISTINCT
  q2.*,
  COALESCE(lwc.channel_category, 'uncategorized') AS channel_category,
  CASE
    WHEN lwc.channel_category = 'content syndication' AND lwc.lead_source_original = 'Content Syndication' THEN 'Lead source original = Content Syndication'
    WHEN lwc.channel_category = 'content syndication' AND LOWER(lwc.UTM_Source__c) LIKE '%madisonlogic%' THEN 'UTM source matched madisonlogic'
    WHEN lwc.channel_category = 'content syndication' AND LOWER(lwc.UTM_Source__c) LIKE '%techtarget%' THEN 'UTM source matched techtarget'
    WHEN lwc.channel_category = 'content syndication' AND LOWER(lwc.UTM_Source__c) LIKE '%integrate%' THEN 'UTM source matched integrate'
    WHEN lwc.channel_category = 'content syndication' AND lwc.marketing_subchannel = 'content syndication' THEN 'Marketing + Paid + content syndication subchannel'
    WHEN lwc.channel_category = 'paid' THEN 'Marketing + Paid + non-content-syndication subchannel'
    WHEN lwc.channel_category = 'non-paid' THEN 'Marketing + Non-paid channel'
    ELSE 'No matching lead or unable to classify due to missing fields'
  END AS channel_reason
FROM Q2_CW_actuals q2
LEFT JOIN leads_with_channel lwc
  ON q2.opportunity_id = lwc.converted_opportunity_id
ORDER BY q2.sales_region, q2.ops_market_segment, q2.opportunity_id