"""Economic layer: mandate, transaction, and the amount-limit guard."""
import pytest

pytestmark = pytest.mark.integration


def test_transaction_within_limit_settles(surreal):
    surreal.run(
        'CREATE payment_mandate:test_m CONTENT { identity: agent_identity:research_agent, '
        'principal: "user:alice", type: "intent", status: "signed", '
        'amount_limit: 2000, currency: "USD" };'
    )
    surreal.run(
        'CREATE agent_transaction:test_tx CONTENT { identity: agent_identity:research_agent, '
        'mandate: payment_mandate:test_m, amount: 1500, currency: "USD", status: "pending" };'
    )
    surreal.run('UPDATE agent_transaction:test_tx SET status = "settled", settled_at = time::now();')
    assert surreal.result("SELECT VALUE status FROM agent_transaction:test_tx;") == ["settled"]


def test_transaction_over_limit_rejected(surreal):
    errs = surreal.errors(
        'CREATE agent_transaction CONTENT { identity: agent_identity:research_agent, '
        'mandate: payment_mandate:test_m, amount: 9999, currency: "USD" };'
    )
    assert any("exceeds the mandate's amount_limit" in e for e in errs)


def test_transaction_missing_mandate_rejected(surreal):
    errs = surreal.errors(
        'CREATE agent_transaction CONTENT { identity: agent_identity:research_agent, '
        'mandate: payment_mandate:does_not_exist, amount: 1, currency: "USD" };'
    )
    assert any("non-existent payment_mandate" in e for e in errs)


def test_over_limit_update_rejected(surreal):
    # A within-limit transaction cannot be mutated above the mandate limit afterwards.
    surreal.run(
        'CREATE agent_transaction:test_tx2 CONTENT { identity: agent_identity:research_agent, '
        'mandate: payment_mandate:test_m, amount: 100, currency: "USD", status: "pending" };'
    )
    errs = surreal.errors('UPDATE agent_transaction:test_tx2 SET amount = 9999;')
    assert any("exceeds the mandate's amount_limit" in e for e in errs)
