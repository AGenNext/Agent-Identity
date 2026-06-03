# Crossplane & the Agent Identity Control Plane

[Crossplane](https://docs.crossplane.io/v2.3/) is the canonical CNCF example of building a
**control plane by composition**: you declare high-level APIs, and the control plane continuously
**reconciles** them to desired state by composing lower-level resources. Agent Identity is the
same shape, applied to *agent identity* instead of cloud infrastructure — the "AI" rung of the
Linux → Kubernetes → AI control-plane ladder.

Background/reference, not enforced vocabulary. (Crossplane's docs blocked automated fetch; this
reflects its established, documented model.)

## Concept mapping

| Crossplane | What it is | Analogue in Agent Identity |
| --- | --- | --- |
| **Composite Resource (XR) / XRD** | A high-level, declarative API for a thing you want. | An **agent definition** (ADL) — the declarative spec of an agent. |
| **Composition** | The template that realizes an XR from many managed resources. | The **onboarding flow** that realizes an agent from its definition (identity → DID → verify → provision → access). |
| **Managed Resources** | The granular pieces an XR composes. | `agent_identity`, `did_document`, `identity_verification`, `agent_lifecycle`, `assigned_access`, … |
| **Providers** | Packages that teach the control plane to talk to an external API. | Integration connectors: **Okta, SailPoint, CyberArk, SPIFFE/SPIRE (Unboxd)**. |
| **Reconciliation to desired state** | Continuously converge actual → desired. | The **lifecycle state machine** + **access reviews** keep an agent's state and entitlements aligned with what was granted. |
| **Composition Functions** | Programmatic steps in the composition pipeline. | The `DEFINE EVENT` guards (grammar, scope attenuation) and flows that enforce/realize the model in-transaction. |

## Why this matters

The control-plane pattern is what makes the model *operable* rather than just a schema:

- An agent is declared once (its definition), and the system composes its identity, credentials,
  lifecycle, and access from grounded building blocks.
- External identity systems plug in as **providers**, so the control plane meets organizations
  where they are instead of replacing them.
- Desired state is continuously enforced — illegal lifecycle transitions and over-broad
  delegations are rejected, and access reviews re-converge entitlements on a schedule.

In short: Crossplane composes infrastructure control planes; Agent Identity composes the
**identity control plane for the agentic web** — vendor-neutral, declarative, and reconciled.
