const { query } = require('../_lib/db');
const { verifyAdminToken } = require('../_lib/auth');

module.exports = async function handler(req, res) {
  const auth = verifyAdminToken(req);
  if (!auth.ok) {
    return res.status(401).json({ error: auth.error });
  }

  try {
    if (req.method === 'POST') {
      const { game, name } = req.body || {};
      if (!game || !name) {
        return res.status(400).json({ error: 'game and name are required' });
      }

      const result = await query(
        `insert into game_servers (game, name, created_at)
         values ($1, $2, now())
         returning *`,
        [game, name]
      );

      return res.status(201).json(result.rows[0]);
    }

    if (req.method === 'DELETE') {
      const id = req.query.id || (req.body && req.body.id);
      if (!id) {
        return res.status(400).json({ error: 'id is required' });
      }

      const result = await query('delete from game_servers where id = $1 returning id', [id]);
      if (!result.rows[0]) {
        return res.status(404).json({ error: 'game server row not found' });
      }

      return res.status(200).json({ deleted: result.rows[0].id });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    return res.status(500).json({ error: 'Database operation failed', detail: error.message });
  }
};
