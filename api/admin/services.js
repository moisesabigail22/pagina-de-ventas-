const { query } = require('../_lib/db');
const { verifyAdminToken } = require('../_lib/auth');

module.exports = async function handler(req, res) {
  const auth = verifyAdminToken(req);
  if (!auth.ok) {
    return res.status(401).json({ error: auth.error });
  }

  try {
    if (req.method === 'POST') {
      const { category, game = null, server = null, name, description = null, price = null } = req.body || {};
      if (!category || !name) {
        return res.status(400).json({ error: 'category and name are required' });
      }

      const result = await query(
        `insert into services (category, game, server, name, description, price, created_at, updated_at)
         values ($1, $2, $3, $4, $5, $6, now(), now())
         returning *`,
        [category, game, server, name, description, price]
      );

      return res.status(201).json(result.rows[0]);
    }

    if (req.method === 'PUT') {
      const { id, category, game, server, name, description, price } = req.body || {};
      if (!id) {
        return res.status(400).json({ error: 'id is required' });
      }

      const result = await query(
        `update services
         set category = coalesce($2, category),
             game = coalesce($3, game),
             server = coalesce($4, server),
             name = coalesce($5, name),
             description = coalesce($6, description),
             price = coalesce($7, price),
             updated_at = now()
         where id = $1
         returning *`,
        [id, category, game, server, name, description, price]
      );

      if (!result.rows[0]) {
        return res.status(404).json({ error: 'service row not found' });
      }

      return res.status(200).json(result.rows[0]);
    }

    if (req.method === 'DELETE') {
      const id = req.query.id || (req.body && req.body.id);
      if (!id) {
        return res.status(400).json({ error: 'id is required' });
      }

      const result = await query('delete from services where id = $1 returning id', [id]);
      if (!result.rows[0]) {
        return res.status(404).json({ error: 'service row not found' });
      }

      return res.status(200).json({ deleted: result.rows[0].id });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    return res.status(500).json({ error: 'Database operation failed', detail: error.message });
  }
};
