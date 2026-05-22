-- Identity Flow: register_agent_identity
CREATE agent_identity CONTENT {
  subject: $subject,
  did: $did,
  did_method: $did_method,
  did_controller: $did_controller,
  did_document_url: $did_document_url,
  oidc_issuer: $oidc_issuer,
  oidc_subject: $oidc_subject,
  oidc_audiences: $oidc_audiences,
  oidc_scopes: $oidc_scopes,
  claims: $claims,
  external_identity_provider: $external_identity_provider,
  external_identity_provider_ref: $external_identity_provider_ref,
  issuer: $issuer,
  status: "active",
  created_at: time::now(),
  updated_at: time::now()
};

-- Identity Flow: bind_did
UPDATE agent_identity:$identity SET
  did = $did,
  did_method = $did_method,
  did_controller = $did_controller,
  did_document_url = $did_document_url,
  updated_at = time::now();

-- Identity Flow: bind_oidc_subject
UPDATE agent_identity:$identity SET
  oidc_issuer = $oidc_issuer,
  oidc_subject = $oidc_subject,
  oidc_audiences = $oidc_audiences,
  oidc_scopes = $oidc_scopes,
  updated_at = time::now();

-- Identity Flow: verify_identity
CREATE identity_verification CONTENT {
  identity: agent_identity:$identity,
  verifier: $verifier,
  method: $method,
  evidence_ref: $evidence_ref,
  status: "verified",
  verified_at: time::now(),
  created_at: time::now()
};

-- Identity Flow: revoke_verification
UPDATE identity_verification:$verification SET
  status = "revoked";

-- Identity Flow: suspend_identity
UPDATE agent_identity:$identity SET
  status = "suspended",
  updated_at = time::now();

-- Identity Flow: reactivate_identity
UPDATE agent_identity:$identity SET
  status = "active",
  updated_at = time::now();

-- Identity Flow: link_registry_credential
CREATE credential_subject CONTENT {
  identity: agent_identity:$identity,
  subject_id: $subject_id,
  subject_type: "agent",
  claims: {
    registry_credential_ref: $registry_credential_ref
  },
  created_at: time::now()
};

-- Identity Flow: resolve_identity_by_subject
SELECT * FROM agent_identity
WHERE subject = $subject;

-- Identity Flow: resolve_identity_by_did
SELECT * FROM agent_identity
WHERE did = $did;

-- Identity Flow: resolve_identity_by_oidc
SELECT * FROM agent_identity
WHERE oidc_issuer = $oidc_issuer
  AND oidc_subject = $oidc_subject;
