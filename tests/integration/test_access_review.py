"""Access review / certification: open then certify."""
import pytest

pytestmark = pytest.mark.integration


def test_open_and_certify(surreal):
    surreal.run(
        'CREATE access_review:test_ar CONTENT { '
        'identity: agent_identity:research_agent, reviewer: "owner", '
        'reviewed_entitlements: ["agent.registry.read"], decision: "pending" };'
    )
    surreal.run('UPDATE access_review:test_ar SET decision = "certified", decided_at = time::now();')
    assert surreal.result("SELECT VALUE decision FROM access_review:test_ar;") == ["certified"]


def test_invalid_decision_rejected(surreal):
    errs = surreal.errors(
        'CREATE access_review:test_bad CONTENT { '
        'identity: agent_identity:research_agent, reviewer: "owner", decision: "approved" };'
    )
    assert errs  # ASSERT on decision rejects values outside the enum
