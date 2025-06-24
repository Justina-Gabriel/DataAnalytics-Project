-- Transaction Frequency Analysis

WITH 
  -- 1. Count each customer’s total transactions and capture their first & last transaction dates
  CustomerTxns AS (
    SELECT
      s.owner_id,
      COUNT(*)                          AS total_txns,
      MIN(s.transaction_date)           AS first_txn_date,
      MAX(s.transaction_date)           AS last_txn_date
    FROM savings_savingsaccount s
    GROUP BY s.owner_id
  ),

  -- 2. Compute months active and average txns/month per customer
  CustomerFreq AS (
    SELECT
      owner_id,
      total_txns,
      -- Months between first and last transaction, inclusive
      TIMESTAMPDIFF(
        MONTH,
        first_txn_date,
        last_txn_date
      ) + 1                             AS months_active,
      -- Guard against division by zero
      total_txns / NULLIF(
        TIMESTAMPDIFF(
          MONTH,
          first_txn_date,
          last_txn_date
        ) + 1,
        0
      )                                  AS avg_txns_per_month
    FROM CustomerTxns
  )

-- 3. Bucket customers into frequency categories and aggregate
SELECT
  CASE
    WHEN avg_txns_per_month >= 10 THEN 'High Frequency'
    WHEN avg_txns_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
    ELSE 'Low Frequency'
  END                                    AS frequency_category,
  COUNT(*)                              AS customer_count,
  ROUND(AVG(avg_txns_per_month), 1)     AS avg_transactions_per_month
FROM CustomerFreq
GROUP BY frequency_category
-- Optional: order in logical High → Medium → Low
ORDER BY 
  CASE frequency_category
    WHEN 'High Frequency'   THEN 1
    WHEN 'Medium Frequency' THEN 2
    WHEN 'Low Frequency'    THEN 3
  END;
