# Campaign Level & Regional DLV Volatility – Approach and Results  
**Prepared by:** Ramin Amin  
**Date:** June 10, 2025

## Objective  
The goal of this analysis is to assess the volatility of Dollar Lead Value (DLV) across campaigns and campaign-region combinations. Volatility, measured via the coefficient of variation (CV = standard deviation / mean), helps us understand how stable or unstable campaign performance is over time. Higher volatility means greater fluctuation week-over-week, which can impair forecasting and campaign management. Lower volatility indicates stability, making it easier to predict and optimize campaigns.

## Why We Calculated Volatility at Campaign and Region Levels
We calculated DLV volatility at two levels:

- Campaign level – to understand overall stability in performance over time

- Campaign + Region level – to uncover whether specific geographic regions within a campaign contribute to volatility

By measuring at both levels, we can better isolate performance fluctuations and make more informed decisions about where optimization is needed—whether at the global campaign level or within specific regional segments.



## Volatility Definition (CV)  
CV = Standard Deviation (σ) / Mean (μ)

CV is calculated across rolling weekly windows: 2-week, 3-week, 4-week, 5-week, and 6-week periods.

## Step-by-Step Approach  

### Step 1: Aggregate Weekly DLV  
We start by converting daily DLV data into weekly aggregates, using `PARSE_DATE('%G-%V', FORMAT_DATE('%G-%V', date))` to define the start of the week (Monday).

**Campaign-level aggregation:**
```sql
SELECT
  week_start,
  campaign_name,
  SUM(adjusted_dollar_lead_value_usd) AS weekly_dlv
```
Campaign + Region-level aggregation:
```sql
SELECT
  week_start,
  campaign_name,
  campaign_region,
  SUM(adjusted_dollar_lead_value_usd) AS weekly_dlv
```
### Step 2: Calculate Rolling CVs
To measure volatility, we calculate the Coefficient of Variation (CV) for each campaign and region over rolling weekly timeframes. This helps us understand how much Dollar Lead Value (DLV) has been fluctuating in recent weeks.

#### 2.1 Campaign-Level Rolling CVs
For each campaign and each week:

cv_2w: CV over the last 2 weeks

cv_3w: CV over the last 3 weeks

...

cv_6w: CV over the last 6 weeks

#### Example for clarity:
Let’s say we’re looking at week_start = 2025-04-28.

Here’s how each CV is calculated:

cv_2w: Looks at the DLV from the current week (2025-04-28) and the week before (2025-04-21). It calculates the standard deviation and mean across just these two weeks, then divides them to get CV.

cv_3w: Includes three weeks: 2025-04-14, 2025-04-21, and 2025-04-28.

cv_6w: Uses DLV from the last six weeks leading up to and including 2025-04-28.

At each week_start, we calculate these values freshly—so volatility is always based on the most recent data available for that week.

This rolling approach smooths short-term noise but still reacts to sudden spikes or drops in lead value.

Each is calculated like so:

```sql
SAFE_DIVIDE(
  STDDEV_POP(weekly_dlv) OVER (
    PARTITION BY campaign_name ORDER BY week_start 
    ROWS BETWEEN N PRECEDING AND CURRENT ROW
  ),
  AVG(weekly_dlv) OVER (
    PARTITION BY campaign_name ORDER BY week_start 
    ROWS BETWEEN N PRECEDING AND CURRENT ROW
  )
)

```
#### 2.2 Campaign + Region-Level Rolling CVs
We apply the same logic but partitioned by both campaign_name and campaign_region to capture regional volatility.

#### Outputs:

cv_2w_region, cv_3w_region, ..., cv_6w_region

### Step 3: Join CVs Back to Base Table
To enable dashboarding or further filtering, we join the CVs back to the original base table (which is still at the daily level). This provides full access to both daily performance data and rolling volatility metrics.

#### Join logic:

On campaign_name and week_start for campaign-level CVs

On campaign_name, campaign_region, and week_start for campaign-region CVs

## Final Output Includes:
Daily data from dollar_lead_value_payback

Weekly CV metrics at both campaign and campaign+region levels:

cv_2w, cv_3w, ..., cv_6w

cv_2w_region, cv_3w_region, ..., cv_6w_region

## Usage
This volatility framework helps:

Detect unstable campaigns or regions

Understand performance fluctuations over different time windows

Prioritize optimization based on consistency


