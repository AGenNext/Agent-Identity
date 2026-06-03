"""Knowledge graph: assign a role and traverse the edge."""
import pytest

pytestmark = pytest.mark.integration


def test_assign_role_and_traverse(surreal):
    surreal.run("RELATE agent_identity:research_agent->assigned_role->role:analyst;")
    res = surreal.result("SELECT ->assigned_role->role.name AS roles FROM agent_identity:research_agent;")
    assert res and "Analyst" in (res[0]["roles"] or [])


def test_seed_account_on_source(surreal):
    res = surreal.result(
        "SELECT ->holds_account->account->account_on_source->source.name AS sources "
        "FROM agent_identity:research_agent;"
    )
    assert res and "CRM" in (res[0]["sources"] or [])
