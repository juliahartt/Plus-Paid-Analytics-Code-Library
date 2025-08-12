SELECT lead_id,
created_at,
new_sales_ready_at,
converted_contact_id,
converted_opportunity_id
FROM `shopify-dw.sales.sales_leads`
WHERE converted_contact_id IS NOT NULL 
AND converted_opportunity_id IS NULL AND created_at>= '2025-08-01'