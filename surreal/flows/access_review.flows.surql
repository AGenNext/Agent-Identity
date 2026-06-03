-- AGenNext Agent Identity
-- Access review / certification flows. Execute against surreal/schema/access_review.surql.
--
-- SOURCE GROUNDING: SailPoint Certifications/Campaigns (periodic re-approval of
-- access) and the OpenID whitepaper §2.12 (IGA) / §2.9 (lifecycle governance).
-- A "revoked" decision should be followed by the lifecycle `revoke` flow.

-- Access Review Flow: open_review
-- Open a pending review of an agent's current entitlements, due by $due_at.
CREATE access_review CONTENT {
  identity: agent_identity:$identity,
  reviewer: $reviewer,
  reviewed_entitlements: $reviewed_entitlements,
  decision: "pending",
  due_at: $due_at
};

-- Access Review Flow: certify
-- Re-approve the reviewed access.
UPDATE access_review:$review SET
  decision = "certified",
  reason = $reason,
  decided_at = time::now();

-- Access Review Flow: revoke_decision
-- Decide that the access should be removed. Follow with the lifecycle `revoke`
-- flow to actually invalidate the agent's credentials.
UPDATE access_review:$review SET
  decision = "revoked",
  reason = $reason,
  decided_at = time::now();
