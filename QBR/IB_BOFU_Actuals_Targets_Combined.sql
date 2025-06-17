-- Combined IB BOFU Actuals and IB Targets RAD: Pull both target and actuals data, with previous quarter and previous year quarter columns, and 'All' segment rollup
WITH combined AS (
  SELECT
    'Actuals' AS data_type,
    metric,
    value_type,
    CASE
      WHEN metric = 'Closed Won' THEN DATE_TRUNC(DATE(sf_close_date), WEEK)
      WHEN metric = 'Closed Lost' THEN DATE_TRUNC(DATE(sf_close_date), WEEK)
      WHEN metric = 'Created' THEN DATE_TRUNC(DATE(sf_created_date), WEEK)
      WHEN metric = 'Qualified SAL' THEN DATE_TRUNC(DATE(qualified_sal_date), WEEK)
      ELSE NULL END AS week_start,
    quarter,
    year,
    ops_lead_source,
    sales_region,
    ops_market_segment,
    opportunity_type,
    SUM(value) AS total_val
  FROM `sdp-for-analysts-platform.rev_ops_prod.modelled_rad`
  WHERE
    dataset = 'Actuals'
    AND metric IN ('Closed Won','Created','Qualified SAL','Closed Lost')
    AND value_type IN ('Total Revenue', 'Opportunity Deal Count')
    AND year IN (2024, 2025)
    AND ops_lead_source = 'Inbound'
    AND opportunity_type = 'New Business'
    AND ops_market_segment IN ('Mid Market','Large Accounts','Enterprise')
  GROUP BY ALL

  UNION ALL

  SELECT
    'Targets' AS data_type,
    metric,
    value_type,
    DATE_TRUNC(DATE(full_date), WEEK) AS week_start,
    quarter,
    year,
    ops_lead_source,
    sales_region,
    ops_market_segment,
    NULL AS opportunity_type,
    SUM(value) AS total_val
  FROM `sdp-for-analysts-platform.rev_ops_prod.modelled_rad`
  WHERE
    dataset = 'Targets'
    AND metric IN ('Created Lead','Qualified Lead','Created','Qualified SAL','Closed Won')
    AND value_type IN ('Lead Count','Lead Count','Total Revenue', 'Opportunity Deal Count')
    AND year = 2025
    AND ops_lead_source = 'Inbound'
    AND ops_market_segment IN ('Mid Market','Large Accounts','Enterprise')
  GROUP BY ALL
)

, with_prev AS (
  SELECT
    curr.*,
    prev_q.total_val AS prev_quarter_total_val,
    prev_yq.total_val AS prev_year_quarter_total_val
  FROM combined curr
  LEFT JOIN combined prev_q
    ON curr.data_type = prev_q.data_type
    AND curr.metric = prev_q.metric
    AND curr.value_type = prev_q.value_type
    AND curr.sales_region = prev_q.sales_region
    AND curr.ops_market_segment = prev_q.ops_market_segment
    AND curr.opportunity_type IS NOT DISTINCT FROM prev_q.opportunity_type
    AND curr.week_start = DATE_ADD(prev_q.week_start, INTERVAL 1 QUARTER)
  LEFT JOIN combined prev_yq
    ON curr.data_type = prev_yq.data_type
    AND curr.metric = prev_yq.metric
    AND curr.value_type = prev_yq.value_type
    AND curr.sales_region = prev_yq.sales_region
    AND curr.ops_market_segment = prev_yq.ops_market_segment
    AND curr.opportunity_type IS NOT DISTINCT FROM prev_yq.opportunity_type
    AND curr.week_start = DATE_ADD(prev_yq.week_start, INTERVAL 1 YEAR)
)

, with_all AS (
  SELECT * FROM with_prev
  UNION ALL
  SELECT
    data_type,
    metric,
    value_type,
    week_start,
    quarter,
    year,
    ops_lead_source,
    sales_region,
    'All' AS ops_market_segment,
    opportunity_type,
    SUM(total_val) AS total_val,
    SUM(prev_quarter_total_val) AS prev_quarter_total_val,
    SUM(prev_year_quarter_total_val) AS prev_year_quarter_total_val
  FROM with_prev
  WHERE ops_market_segment IN ('Enterprise', 'Large Accounts', 'Mid Market')
  GROUP BY data_type, metric, value_type, week_start, quarter, year, ops_lead_source, sales_region, opportunity_type
)

SELECT *
FROM with_all
ORDER BY data_type, metric, value_type, week_start, ops_market_segment; 