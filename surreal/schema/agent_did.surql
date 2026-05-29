-- AGenNext Agent Identity
-- SurrealQL schema for W3C Decentralized Identifier (DID) documents.
-- Source of truth: SurrealDB. Intended for execution through SurrealKit.
-- Execute after surreal/schema/agent_identity.surql
--
-- SOURCE GROUNDING
--   * Concept: "Identity Management for Agentic AI" (OpenID Foundation, Oct 2025),
--     §3.1 "Sovereign and Portable Agent Identity" ("schemes like DIDs").
--   * Property names: W3C "Decentralized Identifiers (DIDs) v1.1",
--     https://www.w3.org/TR/did-1.1/ , §5 Core Properties.
-- Every DID property below uses the exact W3C DID 1.1 term, annotated with its
-- spec section. No property name is invented.
--
-- DESIGN NOTE: only SurrealDB out-of-the-box features are used.

-- ---------------------------------------------------------------------------
-- DID document for an agent identity (W3C DID 1.1 §5 Core Properties).
-- ---------------------------------------------------------------------------
DEFINE TABLE did_document SCHEMAFULL PERMISSIONS NONE;

-- Links the DID document back to the agent identity that controls it.
DEFINE FIELD identity ON TABLE did_document TYPE record<agent_identity>;

-- "id": the DID subject. W3C DID 1.1 §5.1.1.
DEFINE FIELD id ON TABLE did_document TYPE string
  ASSERT string::starts_with($value, "did:");
-- "controller": W3C DID 1.1 §5.1.2.
DEFINE FIELD controller ON TABLE did_document TYPE option<string>;
-- "alsoKnownAs": W3C DID 1.1 §5.1.3.
DEFINE FIELD alsoKnownAs ON TABLE did_document TYPE array<string> DEFAULT [];

-- "verificationMethod": W3C DID 1.1 §5.2. References the embedded verification methods.
DEFINE FIELD verificationMethod ON TABLE did_document TYPE array<record<verification_method>> DEFAULT [];
-- "service": W3C DID 1.1 §5.4. References the embedded service endpoints.
DEFINE FIELD service ON TABLE did_document TYPE array<record<service>> DEFAULT [];

-- Verification relationships (W3C DID 1.1 §5.3) reference verification_method ids.
-- "authentication": §5.3.1.
DEFINE FIELD authentication ON TABLE did_document TYPE array<string> DEFAULT [];
-- "assertionMethod": §5.3.2.
DEFINE FIELD assertionMethod ON TABLE did_document TYPE array<string> DEFAULT [];
-- "keyAgreement": §5.3.3.
DEFINE FIELD keyAgreement ON TABLE did_document TYPE array<string> DEFAULT [];
-- "capabilityInvocation": §5.3.4.
DEFINE FIELD capabilityInvocation ON TABLE did_document TYPE array<string> DEFAULT [];
-- "capabilityDelegation": §5.3.5.
DEFINE FIELD capabilityDelegation ON TABLE did_document TYPE array<string> DEFAULT [];

DEFINE FIELD created_at ON TABLE did_document TYPE datetime
  VALUE $before.created_at OR time::now() DEFAULT time::now();
DEFINE FIELD updated_at ON TABLE did_document TYPE datetime VALUE time::now();

DEFINE INDEX did_document_id_idx ON TABLE did_document COLUMNS id UNIQUE;
DEFINE INDEX did_document_identity_idx ON TABLE did_document COLUMNS identity UNIQUE;

-- ---------------------------------------------------------------------------
-- Verification method (W3C DID 1.1 §5.2).
-- ---------------------------------------------------------------------------
DEFINE TABLE verification_method SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD document ON TABLE verification_method TYPE record<did_document>;
-- "id": §5.2.
DEFINE FIELD id ON TABLE verification_method TYPE string;
-- "type": §5.2 (e.g. "JsonWebKey", "Multikey").
DEFINE FIELD type ON TABLE verification_method TYPE string;
-- "controller": §5.2.
DEFINE FIELD controller ON TABLE verification_method TYPE string;
-- "publicKeyJwk": §5.2.1.
DEFINE FIELD publicKeyJwk ON TABLE verification_method TYPE option<object>;
-- "publicKeyMultibase": §5.2.1.
DEFINE FIELD publicKeyMultibase ON TABLE verification_method TYPE option<string>;

DEFINE INDEX verification_method_id_idx ON TABLE verification_method COLUMNS id UNIQUE;

-- ---------------------------------------------------------------------------
-- Service (W3C DID 1.1 §5.4).
-- ---------------------------------------------------------------------------
DEFINE TABLE service SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD document ON TABLE service TYPE record<did_document>;
-- "id": §5.4.
DEFINE FIELD id ON TABLE service TYPE string;
-- "type": §5.4.
DEFINE FIELD type ON TABLE service TYPE string;
-- "serviceEndpoint": §5.4 (string, map, or set).
DEFINE FIELD serviceEndpoint ON TABLE service TYPE string;

DEFINE INDEX service_id_idx ON TABLE service COLUMNS id UNIQUE;

-- Graph relations linking a DID document to its verification methods and services.
DEFINE TABLE has_verification_method TYPE RELATION IN did_document OUT verification_method SCHEMAFULL PERMISSIONS NONE;
DEFINE TABLE has_service TYPE RELATION IN did_document OUT service SCHEMAFULL PERMISSIONS NONE;
