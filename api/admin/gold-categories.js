const { query } = require('../_lib/db');
const { verifyAdminToken } = require('../_lib/auth');

module.exports = async function handler(req, res) {
  const auth = verifyAdminToken(req);
  if (!auth.ok) {
    return res.status(401).json({ error: auth.error });
  }

  try {
    if (req.method === 'POST') {
      const { game, server = null, description = null, image = null } = req.body || {};
      if (!game) {
        return res.status(400).json({ error: 'game is required' });
      }

      const result = await query(
        `insert into gold_categories (game, server, description, image, created_at, updated_at)
         values ($1, $2, $3, $4, now(), now())
         returning *`,
        [game, server, description, image]
      );

      return res.status(201).json(result.rows[0]);
    }

    if (req.method === 'PUT') {
      const { id, game, server, description, image } = req.body || {};
      if (!id) {
        return res.status(400).json({ error: 'id is required' });
      }

      const result = await query(
        `update gold_categories
         set game = coalesce($2, game),
             server = coalesce($3, server),
             description = coalesce($4, description),
             image = coalesce($5, image),
             updated_at = now()
         where id = $1
         returning *`,
        [id, game, server, description, image]
      );

      if (!result.rows[0]) {
        return res.status(404).json({ error: 'gold category row not found' });
      }

      return res.status(200).json(result.rows[0]);
    }

    if (req.method === 'DELETE') {
      const id = req.query.id || (req.body && req.body.id);
      if (!id) {
        return res.status(400).json({ error: 'id is required' });
      }

      const result = await query('delete from gold_categories where id = $1 returning id', [id]);
      if (!result.rows[0]) {
        return res.status(404).json({ error: 'gold category row not found' });
      }

      return res.status(200).json({ deleted: result.rows[0].id });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    return res.status(500).json({ error: 'Database operation failed', detail: error.message });
  }
};
