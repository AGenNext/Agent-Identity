-- AGenNext Agent Identity
-- Economic-layer queries. Grounded in the OpenID whitepaper §3.6.

-- Query: All mandates for an agent, newest first
SELECT * FROM payment_mandate
WHERE identity = agent_identity:$identity
ORDER BY created_at DESC;

-- Query: Active (signed) mandates for an agent
SELECT * FROM payment_mandate
WHERE identity = agent_identity:$identity AND status = "signed";

-- Query: All transactions for an agent with their authorizing mandate
SELECT *, mandate.type AS mandate_type, mandate.principal AS principal
FROM agent_transaction
WHERE identity = agent_identity:$identity
ORDER BY created_at DESC;

-- Query: Total settled spend per agent
SELECT identity, currency, math::sum(amount) AS settled_total
FROM agent_transaction
WHERE status = "settled"
GROUP BY identity, currency;

-- Query: Transactions over high-consequence APIs that were NOT FAPI-secured (risk surface)
SELECT * FROM agent_transaction
WHERE fapi_secured = false
ORDER BY created_at DESC;

-- Query: The audit chain for a transaction — transaction -> mandate -> principal
SELECT
  id, amount, currency, status,
  mandate.type AS mandate_type,
  mandate.principal AS authorized_by,
  mandate.vc_ref AS mandate_vc
FROM agent_transaction:$transaction;
