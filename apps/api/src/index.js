import express from 'express';
import { router } from './routes.js';
import { healthCheck } from './db.js';
import { seedStore } from './store.js';

seedStore();

const app = express();
app.use(express.json());

app.get('/health', async (_req, res) => {
  const database = await healthCheck();
  res.json({ status: 'ok', service: 'agent-identity-api', database });
});

app.use(router);

app.use((error, _req, res, _next) => {
  console.error(error);
  res.status(500).json({ error: error.message || 'Internal server error' });
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Agent Identity API listening on port ${port}`);
});
