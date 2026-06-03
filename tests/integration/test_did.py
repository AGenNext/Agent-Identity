"""DID documents: create, attach a verification method, traverse."""
import pytest

pytestmark = pytest.mark.integration


def test_create_did_and_verification_method(surreal):
    surreal.run(
        'CREATE did_document:test_doc CONTENT { '
        'identity: agent_identity:research_agent, '
        'id: "did:web:agents.agennext.dev:research-agent", '
        'controller: "did:web:agennext.dev" };'
    )
    surreal.run(
        'CREATE verification_method:test_vm CONTENT { '
        'document: did_document:test_doc, '
        'id: "did:web:agents.agennext.dev:research-agent#key-1", '
        'type: "Multikey", controller: "did:web:agennext.dev", '
        'publicKeyMultibase: "z6MkExampleKeyMaterial" };'
    )
    surreal.run("RELATE did_document:test_doc->has_verification_method->verification_method:test_vm;")
    res = surreal.result(
        "SELECT ->has_verification_method->verification_method.id AS vms FROM did_document:test_doc;"
    )
    assert res and res[0]["vms"]
