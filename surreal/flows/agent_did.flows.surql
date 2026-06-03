-- AGenNext Agent Identity
-- DID document flows (W3C DID 1.1). Execute against surreal/schema/agent_did.surql.
-- Property names are the exact W3C DID 1.1 §5 terms.

-- DID Flow: create_did_document  (§5.1)
CREATE did_document CONTENT {
  identity: agent_identity:$identity,
  id: $did,
  controller: $controller,
  alsoKnownAs: $alsoKnownAs
};

-- DID Flow: add_verification_method  (§5.2)
-- Creates the method, links it, and appends it to the document's verificationMethod set.
LET $vm = (CREATE ONLY verification_method CONTENT {
  document: did_document:$document,
  id: $vm_id,
  type: $type,
  controller: $controller,
  publicKeyJwk: $publicKeyJwk,
  publicKeyMultibase: $publicKeyMultibase
});
RELATE did_document:$document->has_verification_method->$vm.id;
UPDATE did_document:$document SET verificationMethod += $vm.id;

-- DID Flow: add_service  (§5.4)
LET $svc = (CREATE ONLY service CONTENT {
  document: did_document:$document,
  id: $svc_id,
  type: $type,
  serviceEndpoint: $serviceEndpoint
});
RELATE did_document:$document->has_service->$svc.id;
UPDATE did_document:$document SET service += $svc.id;

-- DID Flow: set_authentication  (§5.3.1) — reference a verification method id
UPDATE did_document:$document SET authentication += $vm_id;

-- DID Flow: set_assertion_method  (§5.3.2)
UPDATE did_document:$document SET assertionMethod += $vm_id;

-- DID Flow: set_key_agreement  (§5.3.3)
UPDATE did_document:$document SET keyAgreement += $vm_id;

-- DID Flow: set_capability_invocation  (§5.3.4)
UPDATE did_document:$document SET capabilityInvocation += $vm_id;

-- DID Flow: set_capability_delegation  (§5.3.5)
UPDATE did_document:$document SET capabilityDelegation += $vm_id;

-- DID Flow: get_did_document
SELECT *,
  ->has_verification_method->verification_method.* AS verificationMethods,
  ->has_service->service.* AS services
FROM did_document
WHERE identity = agent_identity:$identity;
