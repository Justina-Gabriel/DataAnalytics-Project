SELECT * FROM users_customuser LIMIT 5;
SELECT * FROM savings_savingsaccount LIMIT 5;
SELECT * FROM plans_plan LIMIT 5;
SELECT * FROM withdrawals_withdrawal LIMIT 5;


-- A: Customers with at least one funded savings plan

WITH 
  SavingsOwners AS (
    SELECT
      p.owner_id,
      COUNT(DISTINCT p.id) AS savings_count
    FROM plans_plan p
    JOIN savings_savingsaccount s
      ON p.id = s.plan_id
    WHERE
      p.is_regular_savings = 1
      AND s.confirmed_amount > 0
    GROUP BY p.owner_id
  ),

  InvestmentOwners AS (
    SELECT
      p.owner_id,
      COUNT(DISTINCT p.id) AS investment_count
    FROM plans_plan p
    JOIN savings_savingsaccount s
      ON p.id = s.plan_id
    WHERE
      p.is_a_fund = 1
      AND s.confirmed_amount > 0
    GROUP BY p.owner_id
  ),

  TotalDeposits AS (
    SELECT
      s.owner_id,
      SUM(s.confirmed_amount) AS total_deposits
    FROM savings_savingsaccount s
    GROUP BY s.owner_id
  )

SELECT
  u.id             AS owner_id,
  u.name           AS name,
  so.savings_count,
  io.investment_count,
  td.total_deposits
FROM SavingsOwners so
JOIN InvestmentOwners io
  ON so.owner_id = io.owner_id
JOIN TotalDeposits td
  ON so.owner_id = td.owner_id
JOIN users_customuser u
  ON u.id = so.owner_id
ORDER BY td.total_deposits DESC;
