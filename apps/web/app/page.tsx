export default function Home() {
  const modules = [
    'Agent Universal Directory',
    'Lifecycle Management',
    'Usage Metering',
    'Agent Pay',
    'FinOps',
    'Optimize',
    'Audit',
    'Evaluation',
    'Integrations'
  ];

  const platformAgents = [
    'Autonomyx Customer Success Agent',
    'Customer Onboarding Agent',
    'Integration Agent',
    'Customer Account Manager Agent',
    'Agent FinOps Agent',
    'Agent Optimize Agent'
  ];

  return (
    <main style={{ fontFamily: 'Inter, sans-serif', padding: '48px', maxWidth: '1200px', margin: '0 auto', lineHeight: 1.6 }}>
      <section style={{ padding: '64px 0' }}>
        <p style={{ color: '#666', fontWeight: 600 }}>AGENT IDENTITY PLATFORM</p>
        <h1 style={{ fontSize: '56px', margin: '16px 0' }}>
          The Identity Control Plane for AI Agents
        </h1>
        <p style={{ fontSize: '22px', color: '#555', maxWidth: '900px' }}>
          Register, govern, evaluate, and optimize AI agents as digital workers.
          Manage lifecycle, usage, pay, audit, and integrations from one enterprise platform.
        </p>
      </section>

      <section style={{ padding: '32px 0' }}>
        <h2>Platform Modules</h2>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px' }}>
          {modules.map((module) => (
            <div key={module} style={{ border: '1px solid #e5e7eb', borderRadius: '16px', padding: '20px' }}>
              <strong>{module}</strong>
            </div>
          ))}
        </div>
      </section>

      <section style={{ padding: '32px 0' }}>
        <h2>Platform Agents Built with Autonomyx</h2>
        <ul>
          {platformAgents.map((agent) => (
            <li key={agent}>{agent}</li>
          ))}
        </ul>
      </section>

      <section style={{ padding: '32px 0' }}>
        <h2>Core Architecture</h2>
        <pre style={{ background: '#f9fafb', padding: '24px', borderRadius: '16px', overflowX: 'auto' }}>
{`Autonomyx Agent Framework
  -> builds and orchestrates agents

Agent Identity Platform
  -> identity control plane

Access Control Plane
  -> authentication, authorization, IGA, PAM
`}
        </pre>
      </section>

      <section style={{ padding: '32px 0' }}>
        <h2>API-First Platform</h2>
        <p>
          APIs, SDKs, and MCP tools are the primary interface. Dashboards and reports provide visibility for human stakeholders.
        </p>
      </section>
    </main>
  );
}
