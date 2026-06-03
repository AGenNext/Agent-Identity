"""Delegation: scope-attenuation guard."""
import pytest

pytestmark = pytest.mark.integration


def test_over_broad_delegation_rejected(surreal):
    errs = surreal.errors(
        'RELATE agent_identity:research_agent->delegates_to->agent_identity:summary_agent '
        'SET scope = ["admin:everything"];'
    )
    assert any("Scope attenuation violated" in e for e in errs)


def test_subset_delegation_allowed(surreal):
    res = surreal.run(
        'RELATE agent_identity:research_agent->delegates_to->agent_identity:summary_agent '
        'SET scope = ["agent.registry.read"], attenuated = true;'
    )
    assert all(r.get("status") == "OK" for r in res)
