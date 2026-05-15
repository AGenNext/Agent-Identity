import { verifyToken } from './jwt.js';

export async function requireBearerToken(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');

    if (scheme !== 'Bearer' || !token) {
      return res.status(401).json({ error: 'Missing bearer token' });
    }

    req.auth = await verifyToken(token);
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid bearer token' });
  }
}
