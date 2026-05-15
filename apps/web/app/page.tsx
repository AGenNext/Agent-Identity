const modules = ['Agent Universal Directory','Lifecycle Management','Usage Metering','Agent Pay','FinOps','Optimize','Audit','Evaluation','Integrations'];
const platformAgents = ['Autonomyx Customer Success Agent','Customer Onboarding Agent','Integration Agent','Customer Account Manager Agent','Agent FinOps Agent','Agent Optimize Agent'];
const nav = ['Platform','Integrations','MCP','SDKs','Reports','Autonomyx'];

export default function Home() {
  return (
    <main>
      <div className="container">
        <nav className="nav">
          <strong>Agent Identity</strong>
          {nav.map((item) => <a key={item} href={`#${item.toLowerCase()}`}>{item}</a>)}
        </nav>

        <section className="hero">
          <p style={{ color: '#6b7280', fontWeight: 600 }}>AGENT IDENTITY PLATFORM</p>
          <h1>The Identity Control Plane for AI Agents</h1>
          <p>
            Register, govern, evaluate, and optimize AI agents as digital workers. Manage lifecycle,
            usage, pay, audit, and integrations through APIs, SDKs, and MCP.
          </p>
        </section>

        <section id="platform" className="section">
          <h2>Platform Modules</h2>
          <div className="grid">
            {modules.map((module) => <div key={module} className="card"><strong>{module}</strong></div>)}
          </div>
        </section>

        <section id="integrations" className="section">
          <h2>Integration-First Adoption</h2>
          <p>Connect any IdP, IGA, PAM, SaaS application, runtime platform, finance system, or evaluation tool.</p>
        </section>

        <section id="mcp" className="section">
          <h2>MCP for Agents</h2>
          <p>Agents can access identity, lifecycle, usage, audit, and policy context through MCP tools.</p>
        </section>

        <section id="sdks" className="section">
          <h2>SDKs and APIs</h2>
          <p>TypeScript and Python SDKs make it easy to embed Agent Identity into any product.</p>
        </section>

        <section id="reports" className="section">
          <h2>Reports and Dashboards</h2>
          <p>The UI focuses on inventory, lifecycle, usage, pay, FinOps, audit, and evaluation reports.</p>
        </section>

        <section id="autonomyx" className="section">
          <h2>Built with Autonomyx Agent Framework</h2>
          <p>Autonomyx builds and orchestrates enterprise agents. Agent Identity provides the identity control plane.</p>
          <pre className="code">{`Autonomyx Agent Framework\n  -> builds and orchestrates agents\n\nAgent Identity Platform\n  -> identity control plane\n\nAccess Control Plane\n  -> authentication, authorization, IGA, PAM`}</pre>
        </section>

        <section className="section">
          <h2>Flagship Platform Agents</h2>
          <div className="grid">
            {platformAgents.map((agent) => <div key={agent} className="card"><strong>{agent}</strong></div>)}
          </div>
        </section>
      </div>
    </main>
  );
}
