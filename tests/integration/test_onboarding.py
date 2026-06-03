"""Onboarding: run the end-to-end orchestration from a testdata fixture."""
import json

import pytest

from surreal_client import load_testdata

pytestmark = pytest.mark.integration


def test_onboard_end_to_end(surreal):
    a = load_testdata("agent_onboarding.json")
    ident = a["identity"]

    surreal.run(
        f'CREATE agent_identity:{ident} CONTENT '
        f'{{ subject: {json.dumps(a["subject"])}, status: "active" }};'
    )
    surreal.run(
        f'CREATE agent_lifecycle CONTENT {{ identity: agent_identity:{ident}, '
        f'state: "provisioned", owners: {json.dumps(a["owners"])}, '
        f'entitlements: {json.dumps(a["entitlements"])} }};'
    )
    surreal.run(
        'UPDATE agent_lifecycle SET previous_state = state, state = "active" '
        f"WHERE identity = agent_identity:{ident};"
    )
    surreal.run(
        f'LET $v = (CREATE ONLY identity_verification CONTENT {{ '
        f'identity: agent_identity:{ident}, verifier: {json.dumps(a["verifier"])}, '
        f'method: {json.dumps(a["verification_method"])}, '
        f'status: "verified", verified_at: time::now() }}); '
        f"RELATE agent_identity:{ident}->verified_by->$v.id;"
    )
    surreal.run(f"RELATE agent_identity:{ident}->assigned_role->role:{a['role']};")
    surreal.run(
        f"RELATE agent_identity:{ident}->operates_in->trust_domain:{a['trust_domain']};"
    )

    assert surreal.result(
        f"SELECT VALUE state FROM agent_lifecycle WHERE identity = agent_identity:{ident};"
    ) == ["active"]
    verified = surreal.result(
        f'SELECT count() FROM identity_verification '
        f'WHERE identity = agent_identity:{ident} AND status = "verified" GROUP ALL;'
    )
    assert verified and verified[0].get("count", 0) >= 1
    roles = surreal.result(
        f"SELECT ->assigned_role->role.name AS roles FROM agent_identity:{ident};"
    )
    assert roles and roles[0]["roles"]
