-- AGenNext Agent Identity: base seed data.
USE NS agent_identity DB dev;

CREATE agent:research_assistant CONTENT {
  name: 'Research Assistant',
  description: 'Autonomous research agent',
  provider: 'OpenAI',
  model: 'gpt-5',
  version: '1.0.0',
  status: 'active'
};

CREATE capability:search_web CONTENT {
  name: 'search.web',
  description: 'Search the public web'
};

RELATE agent:research_assistant->has_capability->capability:search_web;
