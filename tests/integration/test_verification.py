"""Identity verification: request then mark verified."""
import pytest

pytestmark = pytest.mark.integration


def test_request_then_verify(surreal):
    surreal.run(
        'CREATE identity_verification:test_v CONTENT { '
        'identity: agent_identity:research_agent, verifier: "test", '
        'method: "did", status: "pending" };'
    )
    surreal.run('UPDATE identity_verification:test_v SET status = "verified", verified_at = time::now();')
    assert surreal.result("SELECT VALUE status FROM identity_verification:test_v;") == ["verified"]


def test_seed_registry_verification_present(surreal):
    res = surreal.result(
        'SELECT count() FROM identity_verification '
        'WHERE identity = agent_identity:research_agent AND status = "verified" GROUP ALL;'
    )
    assert res and res[0].get("count", 0) >= 1
