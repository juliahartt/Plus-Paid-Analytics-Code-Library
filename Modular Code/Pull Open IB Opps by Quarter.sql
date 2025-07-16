-- =========================================================================
-- OPEN INBOUND OPPORTUNITIES BY QUARTER START (Q1, Q2, Q3 2025)
-- Each opportunity is counted only once per as_of_date, prioritizing "Qualified SAL"
-- =========================================================================

WITH quarter_starts AS (
  SELECT DATE '2025-01-01' AS as_of_date UNION ALL
  SELECT DATE '2025-04-01' UNION ALL
  SELECT DATE '2025-07-01'
),
base_opps AS (
  SELECT
    opportunity_id,  -- assuming there is a unique id
    sales_region,
    ops_market_segment,
    value,
    value_type,
    sf_created_date,
    qualified_sal_date,
    sf_close_date
  FROM `sdp-for-analysts-platform.rev_ops_prod.modelled_rad`
  WHERE
    dataset = "Actuals"
    AND opportunity_type = "New Business"
    AND ops_lead_source = "Inbound"
    AND ops_market_segment IN ('Mid Market', 'Large Accounts', 'Enterprise', 'SMB Acquisition')
    AND value_type = 'Total Revenue'
),
opps_with_status AS (
  SELECT
    q.as_of_date,
    b.opportunity_id,
    b.sales_region,
    b.ops_market_segment,
    b.value,
    -- Assign status based on most advanced stage as of as_of_date
    CASE
      WHEN b.qualified_sal_date IS NOT NULL AND DATE(b.qualified_sal_date) <= q.as_of_date THEN 'Qualified SAL'
      WHEN b.sf_created_date IS NOT NULL AND DATE(b.sf_created_date) <= q.as_of_date THEN 'Created'
      ELSE NULL
    END AS metric
  FROM base_opps b
  CROSS JOIN quarter_starts q
  WHERE
    -- Not closed as of as_of_date
    (b.sf_close_date IS NULL OR DATE(b.sf_close_date) > q.as_of_date)
),
final_opps AS (
  SELECT
    as_of_date,
    metric,
    sales_region,
    ops_market_segment,
    value,
    opportunity_id
  FROM opps_with_status
  WHERE metric IS NOT NULL
)

SELECT
  as_of_date,
  metric,
  sales_region,
  ops_market_segment,
  SUM(value) AS total_revenue,
  COUNT(DISTINCT opportunity_id) AS open_opportunity_count
FROM final_opps
GROUP BY as_of_date, metric, sales_region, ops_market_segment
ORDER BY as_of_date, metric, sales_region, ops_market_segment;
-- ========================================================================= 