import { Surreal } from '@surrealdb/surrealdb';

const db = new Surreal();
let connected = false;

export async function connectDb() {
  if (connected) return db;

  const url = process.env.SURREAL_URL || 'http://127.0.0.1:8000/rpc';
  const user = process.env.SURREAL_USER || 'root';
  const pass = process.env.SURREAL_PASS || 'root';
  const namespace = process.env.SURREAL_NS || 'agent_identity';
  const database = process.env.SURREAL_DB || 'dev';

  await db.connect(url, {
    auth: { user, pass },
    namespace,
    database
  });

  connected = true;
  return db;
}

export async function healthCheck() {
  try {
    await connectDb();
    return true;
  } catch {
    return false;
  }
}
