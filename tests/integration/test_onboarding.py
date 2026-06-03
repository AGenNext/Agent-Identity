"""Onboarding: run the end-to-end orchestration for a fresh agent."""
import pytest

pytestmark = pytest.mark.integration


def test_onboard_end_to_end(surreal):
    surreal.run('CREATE agent_identity:onb1 CONTENT { subject: "agent:onb1", status: "active" };')
    surreal.run(
        'CREATE agent_lifecycle CONTENT { identity: agent_identity:onb1, '
        'state: "provisioned", owners: ["AGenNext"], entitlements: ["agent.identity"] };'
    )
    surreal.run(
        'UPDATE agent_lifecycle SET previous_state = state, state = "active" '
        "WHERE identity = agent_identity:onb1;"
    )
    surreal.run(
        'LET $v = (CREATE ONLY identity_verification CONTENT { '
        'identity: agent_identity:onb1, verifier: "registry", method: "registry", '
        'status: "verified", verified_at: time::now() }); '
        "RELATE agent_identity:onb1->verified_by->$v.id;"
    )

    assert surreal.result(
        "SELECT VALUE state FROM agent_lifecycle WHERE identity = agent_identity:onb1;"
    ) == ["active"]
    verified = surreal.result(
        'SELECT count() FROM identity_verification '
        'WHERE identity = agent_identity:onb1 AND status = "verified" GROUP ALL;'
    )
    assert verified and verified[0].get("count", 0) >= 1
