/*
-----new analysis on June 10
The forecast uses data from the DLV attribution table, which contains only new leads.
Data is filtered to include only leads with PPI in ('Plus', 'Commerce Components').
After filtering:
Paid Leads: 36K
Non-Paid Leads: 10K


Whereas, My Analysis includes both new leads (with DLV) and existing leads (without DLV).
Leads and DLV are further broken down by paid/non-paid, new/existing lead, and new/existing account.
Data is filtered for PPI in ('Plus', 'Commerce Components', 'B2B'), so the number of leads increases.
Paid Leads: 39K
Non-Paid Leads: 33K
*/
------------segment and PPI from 1st sub, used last touch attribution method
with lfs as (
    SELECT
    sub.lead_id,
    sub.routing_segment,
     CASE
        WHEN REGEXP_CONTAINS(sl.region,"AMER") THEN "AMER"
        WHEN REGEXP_CONTAINS(sl.region,"APAC") THEN "APAC"
        WHEN REGEXP_CONTAINS(sl.region,"EMEA") THEN "EMEA"
        WHEN REGEXP_CONTAINS(sl.region,"LATAM|Unknown") THEN "LATAM+(Unknown)"
      ELSE
      "null"
    END
      AS region,
    
    sl.converted_contact_id,
    sl.converted_account_id,
    CASE WHEN sub.is_shopify_customer is true then "Existing Lead" else "New Lead" end as lead_type,
    sl.created_at,
    sl.lead_source_original_category,
    sl.lead_source_original,
    UTM_Source__c 
  FROM `shopify-dw.sales.sales_lead_submissions`  sub join `shopify-dw.sales.sales_leads` sl on sub.lead_id=sl.lead_id join `shopify-dw.raw_salesforce_banff.lead` bl on bl.Id=sub.lead_id
  
  WHERE lead_id_submission_index = 1
  and sl.created_at  between '2025-01-01' and '2025-03-31'
  and sub.primary_product_interest in ('Plus','Commerce Components','B2B') 

)
,last_touch as (
  select
  lfs.*,
  att.marketing_channel,
  att.marketing_subchannel,
  att.marketing_type,
  att.commercial_channel,
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
  from lfs
  join `shopify-dw.sales.sales_lead_attribution_v1` att 
    ON lfs.lead_id = att.lead_id
  WHERE att.is_valid_for_lead_created
  QUALIFY ROW_NUMBER() OVER(PARTITION BY lfs.lead_id ORDER BY att.touchpoint_timestamp desc) = 1 
),
final as (
select
l.*,
l.created_at as lead_created,
ac.CreatedDate as account_created,
CASE WHEN ac.CreatedDate < l.created_at THEN 'Existing Account' else 'New Account' END  account_type

from last_touch l
LEFT JOIN `shopify-dw.raw_salesforce_banff.contact` c
ON c.id=l.converted_contact_id
LEFT JOIN `shopify-dw.raw_salesforce_banff.account` ac
ON c.AccountId=ac.id
)
select
f.*,last_touch_dlv_usd
from final f left join `shopify-dw.mart_commercial_optimization.dollar_lead_value_attribution` dlv on f.lead_id=dlv.lead_id
and is_last_touchpoint = True;

