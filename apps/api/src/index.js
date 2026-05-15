import express from 'express';

const app = express();
app.use(express.json());

const agents = [
  {
    id: 'agent:research_assistant',
    name: 'Research Assistant',
    provider: 'OpenAI',
    model: 'gpt-5',
    version: '1.0.0',
    status: 'active'
  }
];

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'agent-identity-api' });
});

app.get('/agents', (_req, res) => {
  res.json({ data: agents });
});

app.post('/agents', (req, res) => {
  const agent = {
    id: `agent:${Date.now()}`,
    ...req.body,
    status: req.body.status || 'active'
  };

  agents.push(agent);
  res.status(201).json({ data: agent });
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Agent Identity API listening on port ${port}`);
});
