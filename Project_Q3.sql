-- Account Inactivity Alert

WITH LastTxn AS (
  SELECT
    p.id                                AS plan_id,
    p.owner_id,
    CASE
      WHEN p.is_regular_savings = 1 THEN 'Savings'
      WHEN p.is_a_fund         = 1 THEN 'Investment'
    END                                  AS type,
    MAX(s.transaction_date)             AS last_transaction_date,
    p.created_on
  FROM plans_plan p
  LEFT JOIN savings_savingsaccount s
    ON p.id = s.plan_id
   AND s.confirmed_amount > 0           -- only count real deposits
  WHERE (p.is_regular_savings = 1      -- only savings or investment plans
         OR p.is_a_fund        = 1)
    AND p.is_deleted    = 0             -- only active plans
    AND p.is_archived   = 0
  GROUP BY p.id, p.owner_id, type, p.created_on
)
SELECT
  plan_id,
  owner_id,
  type,
  last_transaction_date,
  DATEDIFF(
    CURRENT_DATE,
    COALESCE(last_transaction_date, created_on)
  )                                     AS inactivity_days
FROM LastTxn
WHERE COALESCE(last_transaction_date, created_on)
      < DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY)  -- no transactions in past year
ORDER BY inactivity_days DESC;
