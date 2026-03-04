const jwt = require('jsonwebtoken');

function getTokenFromHeader(req) {
  const header = req.headers.authorization || req.headers.Authorization;
  if (!header || !header.startsWith('Bearer ')) return null;
  return header.slice('Bearer '.length).trim();
}

function verifyAdminToken(req) {
  const token = getTokenFromHeader(req);
  if (!token) {
    return { ok: false, error: 'Missing bearer token' };
  }

  const secret = process.env.ADMIN_JWT_SECRET;
  if (!secret) {
    return { ok: false, error: 'Missing ADMIN_JWT_SECRET environment variable' };
  }

  try {
    const payload = jwt.verify(token, secret);
    return { ok: true, payload };
  } catch {
    return { ok: false, error: 'Invalid or expired token' };
  }
}

module.exports = { verifyAdminToken };
