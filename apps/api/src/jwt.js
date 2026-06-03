import { SignJWT, jwtVerify } from 'jose';

const DEV_FALLBACK_SECRET = 'agent-identity-dev-secret-change-me';

// Fail closed: a missing JWT_SECRET in production would otherwise silently fall
// back to a publicly-known secret, letting anyone forge valid tokens.
if (!process.env.JWT_SECRET && process.env.NODE_ENV === 'production') {
  throw new Error('JWT_SECRET must be set in production');
}
if (!process.env.JWT_SECRET) {
  console.warn('[auth] JWT_SECRET is not set; using an insecure development secret.');
}

const secret = new TextEncoder().encode(process.env.JWT_SECRET || DEV_FALLBACK_SECRET);
const ALG = 'HS256';

export async function issueToken(payload) {
  return await new SignJWT(payload)
    .setProtectedHeader({ alg: ALG })
    .setIssuedAt()
    .setExpirationTime('24h')
    .sign(secret);
}

export async function verifyToken(token) {
  // Pin the algorithm to prevent algorithm-confusion attacks.
  const { payload } = await jwtVerify(token, secret, { algorithms: [ALG] });
  return payload;
}
