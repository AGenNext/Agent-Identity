import express from 'express';
import {
  seedStore,
  listAgents,
  createAgent,
  listCapabilities,
  createCapability,
  listCredentials,
  createCredential,
  revokeCredential,
  listDelegations,
  createDelegation,
  listPolicies,
  createPolicy,
  evaluatePolicy,
  listAudits
} from './store.js';

seedStore();

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'agent-identity-api' });
});

app.get('/agents', (_req, res) => res.json({ data: listAgents() }));
app.post('/agents', (req, res) => res.status(201).json({ data: createAgent(req.body) }));

app.get('/capabilities', (_req, res) => res.json({ data: listCapabilities() }));
app.post('/capabilities', (req, res) => res.status(201).json({ data: createCapability(req.body) }));

app.get('/credentials', (_req, res) => res.json({ data: listCredentials() }));
app.post('/credentials', (req, res) => res.status(201).json({ data: createCredential(req.body) }));
app.post('/credentials/:id/revoke', (req, res) => {
  const credential = revokeCredential(req.params.id);
  if (!credential) return res.status(404).json({ error: 'Credential not found' });
  res.json({ data: credential });
});

app.get('/delegations', (_req, res) => res.json({ data: listDelegations() }));
app.post('/delegations', (req, res) => res.status(201).json({ data: createDelegation(req.body) }));

app.get('/policies', (_req, res) => res.json({ data: listPolicies() }));
app.post('/policies', (req, res) => res.status(201).json({ data: createPolicy(req.body) }));

app.post('/authorize', (req, res) => {
  res.json({ data: evaluatePolicy(req.body) });
});

app.get('/audits', (_req, res) => res.json({ data: listAudits() }));

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Agent Identity API listening on port ${port}`);
});
