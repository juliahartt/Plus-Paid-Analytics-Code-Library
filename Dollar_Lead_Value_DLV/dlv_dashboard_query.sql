-- Ramin Amin
-- June 10, 2025
-- Step 1: I aggregate weekly DLV per campaign
WITH weekly_data AS (
  SELECT
    PARSE_DATE('%G-%V', FORMAT_DATE('%G-%V', date)) AS week_start,
    campaign_name,
    SUM(adjusted_dollar_lead_value_usd) AS weekly_dlv
  FROM `shopify-dw.mart_commercial_optimization.dollar_lead_value_payback`
  GROUP BY 1, 2
),

-- Step 1.1: I also aggregate weekly DLV per campaign and region
weekly_data_region AS (
  SELECT
    PARSE_DATE('%G-%V', FORMAT_DATE('%G-%V', date)) AS week_start,
    campaign_name,
    campaign_region,
    SUM(adjusted_dollar_lead_value_usd) AS weekly_dlv
  FROM `shopify-dw.mart_commercial_optimization.dollar_lead_value_payback`
  GROUP BY 1, 2, 3
),

-- Step 2: Here I am rolling CVs at campaign level
rolling_cv AS (
  SELECT
    week_start,
    campaign_name,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
    ) AS cv_2w,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
    ) AS cv_3w,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)
    ) AS cv_4w,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW)
    ) AS cv_5w,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name ORDER BY week_start 
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW)
    ) AS cv_6w

  FROM weekly_data
),

-- Step 2.1: RI am also rolling CVs at campaign and region level
rolling_cv_region AS (
  SELECT
    week_start,
    campaign_name,
    campaign_region,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
    ) AS cv_2w_region,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
    ) AS cv_3w_region,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)
    ) AS cv_4w_region,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW)
    ) AS cv_5w_region,

    SAFE_DIVIDE(
      STDDEV_POP(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW),
      AVG(CAST(weekly_dlv AS FLOAT64)) OVER (
        PARTITION BY campaign_name, campaign_region ORDER BY week_start 
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW)
    ) AS cv_6w_region

  FROM weekly_data_region
)

-- Step 3: Final join to base data
SELECT
  cv.week_start,
  base.*,
  cv.cv_2w,
  cv.cv_3w,
  cv.cv_4w,
  cv.cv_5w,
  cv.cv_6w,
  cv_r.cv_2w_region,
  cv_r.cv_3w_region,
  cv_r.cv_4w_region,
  cv_r.cv_5w_region,
  cv_r.cv_6w_region

FROM `shopify-dw.mart_commercial_optimization.dollar_lead_value_payback` AS base

LEFT JOIN rolling_cv AS cv
  ON cv.campaign_name = base.campaign_name
     AND cv.week_start = PARSE_DATE('%G-%V', FORMAT_DATE('%G-%V', base.date))

LEFT JOIN rolling_cv_region AS cv_r
  ON cv_r.campaign_name = base.campaign_name
     AND cv_r.campaign_region = base.campaign_region
     AND cv_r.week_start = PARSE_DATE('%G-%V', FORMAT_DATE('%G-%V', base.date))

WHERE --base.campaign_name = 'Brand - Core Brand'
 -- AND spend_cost_center_sub_group = 'Plus'
  --AND cv.week_start = '2025-04-21'
base.date >= '2024-01-01'
