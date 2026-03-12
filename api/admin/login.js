const jwt = require('jsonwebtoken');

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { username, password } = req.body || {};
  const adminUser = process.env.ADMIN_USER || 'admin';
  const adminPass = process.env.ADMIN_PASSWORD;
  const jwtSecret = process.env.ADMIN_JWT_SECRET;

  if (!adminPass) {
    return res.status(500).json({ error: 'Missing ADMIN_PASSWORD environment variable' });
  }

  if (!jwtSecret) {
    return res.status(500).json({ error: 'Missing ADMIN_JWT_SECRET environment variable' });
  }

  if (username !== adminUser || password !== adminPass) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const token = jwt.sign({ role: 'admin', username: adminUser }, jwtSecret, {
    expiresIn: '12h'
  });

  return res.status(200).json({ token });
};
