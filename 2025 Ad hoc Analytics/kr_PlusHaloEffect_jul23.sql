CREATE OR REPLACE FUNCTION `shopify-dw.scratch.IsPlusCampaign`(
  
  campaign_name STRING,
  utm_content STRING,
  utm_term STRING
)
RETURNS BOOLEAN AS(

CASE
  -- Campaign id is entirely numeric
  WHEN REGEXP_CONTAINS(campaign_name, r'^\d+$') THEN TRUE

  -- Campaign name contains the word "plus"
  WHEN LOWER(campaign_name) LIKE '%plus%' or LOWER(utm_content) LIKE '%plus%'  THEN TRUE

  -- Campaign name contains "retail" or "pos" and UTM content/term contains "plus"
  WHEN (LOWER(campaign_name) LIKE '%retail%' OR LOWER(campaign_name) LIKE '%pos%')
       AND (LOWER(utm_content) LIKE '%plus%' OR LOWER(utm_term) LIKE '%plus%') THEN TRUE

  -- Default case
  ELSE FALSE
END
);
			
						
with leads AS(						
SELECT						
distinct lead_id,
created_at
											
FROM `shopify-dw.raw_salesforce_banff.lead` bl
LEFT JOIN `shopify-dw.sales.sales_leads` l 
ON l.lead_id=bl.id
WHERE l.lead_source_original_category="Marketing"
AND DATE(created_at) >= '2025-01-01'				
),	
first_submission AS(						
SELECT						
l.*,					
h.primary_product_interest ,			
CASE WHEN h.is_shopify_customer IS TRUE THEN "Upgrade" ELSE "New Business" END AS market_segment			
FROM `shopify-dw.base.base__monorail_horton_salesforce_record_1` h join leads as l on h.id=l.lead_id											
QUALIFY ROW_NUMBER() OVER(PARTITION BY h.id ORDER BY h.event_timestamp ASC) = 1						
)	,
final as(
		
SELECT						
fs.*,												
slt.marketing_channel,						
slt.marketing_subchannel,						
					
slt.campaign_name,slt.campaign_id,touchpoint_details,
regexp_extract(touchpoint_details, r'\butm_campaign=([^&]\d*)\b') as utm_campaign_id,
regexp_extract(touchpoint_details, r'\butm_content=([^&]*)\b') as utm_content,
regexp_extract(touchpoint_details, r'\butm_term=([^&]*)\b') as utm_term
FROM first_submission fs					
JOIN shopify-dw.sales.sales_lead_attribution_v1 slt						
ON fs.lead_id = slt.lead_id						
where slt.is_valid_for_lead_created		
and 		LOWER(commercial_channel) like '%paid%'
QUALIFY ROW_NUMBER() OVER(PARTITION BY fs.lead_id ORDER BY slt.touchpoint_timestamp desc) = 1	
)

select marketing_channel, marketing_subchannel,market_segment,primary_product_interest, count(distinct lead_id)as leads
from final 
where `shopify-dw.scratch.IsPlusCampaign`(campaign_name ,utm_content ,utm_term ) is true
and lower(marketing_channel) not like '%content syndication%'
group by 1,2,3,4
order by 1,2,3,4;

			
						


			
						