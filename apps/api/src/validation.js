export function requireFields(body, fields) {
  const missing = fields.filter((field) => body[field] === undefined || body[field] === null || body[field] === '');
  if (missing.length > 0) {
    const error = new Error(`Missing required fields: ${missing.join(', ')}`);
    error.statusCode = 400;
    throw error;
  }
}

export function validateAgent(body) {
  requireFields(body, ['name']);
}

export function validateCredential(body) {
  requireFields(body, ['subject', 'type']);
}

export function validateDelegation(body) {
  requireFields(body, ['principal', 'agent']);
}

export function validatePolicy(body) {
  requireFields(body, ['name']);
}

export function validateAuthorize(body) {
  requireFields(body, ['agent', 'action', 'resource']);
}

export function validateTokenIssue(body) {
  requireFields(body, ['principal', 'agent']);
}
