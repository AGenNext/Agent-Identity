"""Lifecycle state machine: grammar guard, create guard, audit log."""
import pytest

pytestmark = pytest.mark.integration


def test_seed_agent_is_active(surreal):
    assert surreal.result("SELECT VALUE state FROM agent_lifecycle:research_agent;") == ["active"]


def test_illegal_transition_rejected(surreal):
    errs = surreal.errors('UPDATE agent_lifecycle:research_agent SET state = "provisioned";')
    assert any("Illegal lifecycle transition" in e for e in errs)


def test_create_must_start_provisioned(surreal):
    # summary_agent has no lifecycle record, so this isolates the CREATE guard.
    errs = surreal.errors(
        'CREATE agent_lifecycle CONTENT { identity: agent_identity:summary_agent, state: "revoked" };'
    )
    assert any("must start in 'provisioned'" in e for e in errs)


def test_audit_log_recorded(surreal):
    res = surreal.result("SELECT count() FROM lifecycle_audit_log GROUP ALL;")
    assert res and res[0].get("count", 0) >= 1
