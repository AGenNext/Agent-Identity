-- AGenNext Agent Identity: base namespace and database bootstrap.
DEFINE NAMESPACE agent_identity;
DEFINE DATABASE dev;

DEFINE TABLE agent SCHEMAFULL;
DEFINE FIELD name ON agent TYPE string;
DEFINE FIELD description ON agent TYPE option<string>;
DEFINE FIELD owner ON agent TYPE record;
DEFINE FIELD provider ON agent TYPE option<string>;
DEFINE FIELD model ON agent TYPE option<string>;
DEFINE FIELD version ON agent TYPE option<string>;
DEFINE FIELD lifecycle_status ON agent TYPE string
  ASSERT $value IN [
    'requisition_open',
    'sourcing',
    'screening',
    'interviewing',
    'offer_pending',
    'offer_accepted',
    'onboarding',
    'active',
    'probation',
    'leave',
    'suspended',
    'offboarding',
    'terminated',
    'alumni',
    'archived'
  ]
  DEFAULT 'onboarding';
DEFINE FIELD status ON agent TYPE string DEFAULT lifecycle_status;
DEFINE FIELD created_at ON agent TYPE datetime DEFAULT time::now();
DEFINE FIELD activated_at ON agent TYPE option<datetime>;
DEFINE FIELD suspended_at ON agent TYPE option<datetime>;
DEFINE FIELD offboarded_at ON agent TYPE option<datetime>;
DEFINE FIELD terminated_at ON agent TYPE option<datetime>;
DEFINE FIELD archived_at ON agent TYPE option<datetime>;

DEFINE TABLE credential SCHEMAFULL;
DEFINE FIELD subject ON credential TYPE record;
DEFINE FIELD type ON credential TYPE string;
DEFINE FIELD algorithm ON credential TYPE option<string>;
DEFINE FIELD expires_at ON credential TYPE option<datetime>;
DEFINE FIELD revoked ON credential TYPE bool DEFAULT false;
DEFINE FIELD created_at ON credential TYPE datetime DEFAULT time::now();

DEFINE TABLE capability SCHEMAFULL;
DEFINE FIELD name ON capability TYPE string;
DEFINE FIELD description ON capability TYPE option<string>;

DEFINE TABLE policy SCHEMAFULL;
DEFINE FIELD name ON policy TYPE string;
DEFINE FIELD rules ON policy TYPE object;

DEFINE TABLE audit SCHEMAFULL;
DEFINE FIELD actor ON audit TYPE record;
DEFINE FIELD principal ON audit TYPE option<record>;
DEFINE FIELD action ON audit TYPE string;
DEFINE FIELD resource ON audit TYPE option<string>;
DEFINE FIELD decision ON audit TYPE option<string>;
DEFINE FIELD metadata ON audit TYPE option<object>;
DEFINE FIELD created_at ON audit TYPE datetime DEFAULT time::now();

DEFINE TABLE delegates_to TYPE RELATION;
DEFINE TABLE has_credential TYPE RELATION;
DEFINE TABLE has_capability TYPE RELATION;
DEFINE TABLE governed_by TYPE RELATION;
