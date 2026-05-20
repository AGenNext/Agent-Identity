-- Query: Get agent identity by subject
SELECT * FROM agent_identity
WHERE subject = $subject;

-- Query: Get agent identity by DID
SELECT * FROM agent_identity
WHERE did = $did;

-- Query: Get issuer for agent identity
SELECT
  ->issued_by->identity_issuer.*
FROM agent_identity:$identity;

-- Query: Get verification records for agent identity
SELECT
  ->verified_by->identity_verification.*
FROM agent_identity:$identity;

-- Query: Get trust domains for agent identity
SELECT
  ->trusted_by->trust_domain.*
FROM agent_identity:$identity;

-- Query: Get credential subject for identity
SELECT * FROM credential_subject
WHERE identity = agent_identity:$identity;

-- Query: Resolve identity graph
SELECT
  *,
  ->issued_by->identity_issuer.* AS issuers,
  ->verified_by->identity_verification.* AS verifications,
  ->trusted_by->trust_domain.* AS trust_domains
FROM agent_identity:$identity;
