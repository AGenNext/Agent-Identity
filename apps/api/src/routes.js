import express from 'express';
import { issueToken, verifyToken } from './jwt.js';
import {
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
  listAudits,
  recordAudit
} from './store.js';

export const router = express.Router();

router.get('/agents', (_req, res) => res.json({ data: listAgents() }));
router.post('/agents', (req, res) => res.status(201).json({ data: createAgent(req.body) }));

router.get('/capabilities', (_req, res) => res.json({ data: listCapabilities() }));
router.post('/capabilities', (req, res) => res.status(201).json({ data: createCapability(req.body) }));

router.get('/credentials', (_req, res) => res.json({ data: listCredentials() }));
router.post('/credentials', (req, res) => res.status(201).json({ data: createCredential(req.body) }));
router.post('/credentials/:id/revoke', (req, res) => {
  const credential = revokeCredential(req.params.id);
  if (!credential) return res.status(404).json({ error: 'Credential not found' });
  res.json({ data: credential });
});

router.get('/delegations', (_req, res) => res.json({ data: listDelegations() }));
router.post('/delegations', (req, res) => res.status(201).json({ data: createDelegation(req.body) }));

router.get('/policies', (_req, res) => res.json({ data: listPolicies() }));
router.post('/policies', (req, res) => res.status(201).json({ data: createPolicy(req.body) }));

router.post('/authorize', (req, res) => res.json({ data: evaluatePolicy(req.body) }));
router.get('/audits', (_req, res) => res.json({ data: listAudits() }));
router.post('/audits', (req, res) => res.status(201).json({ data: recordAudit(req.body) }));

router.post('/tokens/issue', async (req, res, next) => {
  try {
    const token = await issueToken({
      sub: req.body.principal,
      act: req.body.agent,
      scope: req.body.scopes || [],
      resource: req.body.resource || '*'
    });
    res.status(201).json({ data: { token, token_type: 'Bearer', expires_in: 86400 } });
  } catch (error) {
    next(error);
  }
});

router.post('/tokens/verify', async (req, res, next) => {
  try {
    const payload = await verifyToken(req.body.token);
    res.json({ data: { valid: true, payload } });
  } catch (error) {
    res.status(401).json({ data: { valid: false }, error: error.message });
  }
});
