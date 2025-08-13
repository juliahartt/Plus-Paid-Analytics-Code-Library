WITH base_data AS (
  SELECT
    date,
    campaign_name,
    campaign_id,
    campaign_lob,
    campaign_targeting_type,
    campaign_tactic,
    campaign_action_objective,
    campaign_creative_type,
    ad_name,
    adset_name,
    ad_id,
    adset_id,
    marketing_channel,
    marketing_subchannel,
    campaign_region,
    campaign_subregion,
    cost_center_sub_group,
    spend_usd,
    leads_attributed,
    ileads,                           -- <? added
    lead_dollar_value_adjusted,
    dollar_lead_value_iadjusted,      -- added earlier so it can be summed later
    CONCAT(
      FORMAT_DATE('%b %e, %Y', MIN(date) OVER (PARTITION BY 
        campaign_name,
        campaign_id,
        campaign_lob,
        campaign_targeting_type,
        campaign_tactic,
        campaign_action_objective,
        campaign_creative_type,
        ad_name,
        ad_id,
        adset_id,
        marketing_channel,
        marketing_subchannel,
        campaign_region,
        campaign_subregion,
        cost_center_sub_group
      )),
      ' - ',
      FORMAT_DATE('%b %e, %Y', MAX(date) OVER (PARTITION BY 
        campaign_name,
        campaign_id,
        campaign_lob,
        campaign_targeting_type,
        campaign_tactic,
        campaign_action_objective,
        campaign_creative_type,
        ad_name,
        ad_id,
        adset_id,
        marketing_channel,
        marketing_subchannel,
        campaign_region,
        campaign_subregion,
        cost_center_sub_group
      ))
    ) AS date_range
  FROM `shopify-dw.scratch.revmkt_dollar_lead_value_ad_attribution_spend`
  WHERE 
    date >= '2025-01-01'
    AND cost_center_sub_group = 'Plus'
    AND campaign_region = 'AMER'
)

SELECT
  date_range,
  campaign_name,
  campaign_id,
  campaign_lob,
  campaign_targeting_type,
  campaign_tactic,
  campaign_action_objective,
  campaign_creative_type,
  ad_name,
  ad_id,
  adset_id,
  adset_name,
  marketing_channel,
  marketing_subchannel,
  campaign_region,
  campaign_subregion,
  cost_center_sub_group,
  SUM(spend_usd) AS spend,
  SUM(leads_attributed) AS leads_attributed,
  SUM(ileads) AS ileads,                            -- <? summed ileads
  SAFE_DIVIDE(SUM(spend_usd), SUM(leads_attributed)) AS CPL,
  SUM(lead_dollar_value_adjusted) AS adjusted_DLV,
  SUM(dollar_lead_value_iadjusted) AS iDLV,        -- new measure
  SAFE_DIVIDE(SUM(lead_dollar_value_adjusted), SUM(leads_attributed)) AS DLV_Per_Lead,
  SAFE_DIVIDE(SUM(spend_usd), (SUM(lead_dollar_value_adjusted) / 36)) AS payback
FROM base_data
GROUP BY
  date_range,
  campaign_name,
  campaign_id,
  campaign_lob,
  campaign_targeting_type,
  campaign_tactic,
  campaign_action_objective,
  campaign_creative_type,
  ad_name,
  adset_name,
  ad_id,
  adset_id,
  marketing_channel,
  marketing_subchannel,
  campaign_region,
  campaign_subregion,
  cost_center_sub_group;