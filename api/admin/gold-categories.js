const { query } = require('../_lib/db');
const { verifyAdmin } = require('../_lib/auth');

module.exports = async function handler(req, res) {
  if (!verifyAdmin(req, res)) return;

  try {
    if (req.method === 'POST') {
      const { game, server = 'Global', description = '', image = null } = req.body || {};
      if (!game) return res.status(400).json({ error: 'game is required' });

      const result = await query(
        `insert into gold_categories (game, server, description, image)
         values ($1, $2, $3, $4)
         returning *`,
        [game, server, description, image]
      );
      return res.status(201).json(result.rows[0]);
    }

    if (req.method === 'PUT') {
      const { id, game, server, description, image } = req.body || {};
      if (!id) return res.status(400).json({ error: 'id is required' });

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

      if (!result.rows[0]) return res.status(404).json({ error: 'category not found' });
      return res.status(200).json(result.rows[0]);
    }

    if (req.method === 'DELETE') {
      const id = req.query.id || req.body?.id;
      if (!id) return res.status(400).json({ error: 'id is required' });

      await query('delete from gold_categories where id = $1', [id]);
      return res.status(200).json({ ok: true });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    return res.status(500).json({ error: 'Database error', detail: error.message });
  }
};
