--  Customer Lifetime Value (CLV).

WITH 
  -- 1. Combine all deposit and withdrawal transactions into one stream
  AllTxns AS (
    SELECT
      owner_id,
      transaction_date AS txn_date,
      confirmed_amount    AS txn_value
    FROM savings_savingsaccount
    WHERE confirmed_amount IS NOT NULL

    UNION ALL

    SELECT
      owner_id,
      transaction_date AS txn_date,
      amount_withdrawn     AS txn_value
    FROM withdrawals_withdrawal
    WHERE amount_withdrawn IS NOT NULL
  ),

  -- 2. Summarize per customer
  CustSummary AS (
    SELECT
      owner_id,
      COUNT(*)                       AS total_txns,
      AVG(txn_value)                 AS avg_txn_value,
      MIN(txn_date)                  AS first_txn_date,
      MAX(txn_date)                  AS last_txn_date
    FROM AllTxns
    GROUP BY owner_id
  ),

  -- 3. Calculate tenure and average profit per transaction
  CustMetrics AS (
    SELECT
      owner_id,
      total_txns,
      avg_txn_value,
      -- Tenure in months (inclusive)
      TIMESTAMPDIFF(
        MONTH,
        first_txn_date,
        last_txn_date
      ) + 1                          AS tenure_months,
      -- Assume profit per txn = 0.1% of txn value
      0.001 * avg_txn_value          AS avg_profit_per_txn
    FROM CustSummary
  ),

  -- 4. Compute annualized CLV
  CustCLV AS (
    SELECT
      owner_id,
      total_txns,
      tenure_months,
      avg_txn_value,
      avg_profit_per_txn,
      -- (txns per month * 12) * profit per txn
      (total_txns / NULLIF(tenure_months, 0)) * 12 * avg_profit_per_txn
        AS clv
    FROM CustMetrics
  )

SELECT
  u.id              AS customer_id,
  u.name            AS customer_name,
  c.total_txns,
  c.tenure_months,
  ROUND(c.avg_txn_value, 2)       AS avg_transaction_value,
  ROUND(c.avg_profit_per_txn, 4)  AS avg_profit_per_transaction,
  ROUND(c.clv, 2)                 AS customer_lifetime_value
FROM CustCLV c
JOIN users_customuser u
  ON u.id = c.owner_id
ORDER BY c.clv DESC;
