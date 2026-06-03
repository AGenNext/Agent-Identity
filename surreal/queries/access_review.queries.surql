-- AGenNext Agent Identity
-- Access review / certification queries. Grounded in SailPoint Certifications
-- and the OpenID whitepaper §2.12 (IGA) / §2.9.

-- Query: All reviews for an agent, newest first
SELECT * FROM access_review
WHERE identity = agent_identity:$identity
ORDER BY created_at DESC;

-- Query: Pending reviews (awaiting a decision)
SELECT * FROM access_review
WHERE decision = "pending";

-- Query: Overdue reviews (still pending past their due date)
SELECT * FROM access_review
WHERE decision = "pending" AND due_at != NONE AND due_at < time::now();

-- Query: Agents whose access was revoked by a review (should be revoked in lifecycle too)
SELECT identity, reviewer, reason, decided_at FROM access_review
WHERE decision = "revoked"
ORDER BY decided_at DESC;

-- Query: Latest decision per agent
SELECT identity, math::max(created_at) AS latest FROM access_review
GROUP BY identity;
