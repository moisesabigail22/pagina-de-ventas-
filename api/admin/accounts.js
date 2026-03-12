const { query } = require('../_lib/db');
const { verifyAdminToken } = require('../_lib/auth');

module.exports = async function handler(req, res) {
  const auth = verifyAdminToken(req);
  if (!auth.ok) {
    return res.status(401).json({ error: auth.error });
  }

  try {
    if (req.method === 'POST') {
      const { type = 'account', category = null, server = null, name, description = null, price = null, image = null, tags = [] } = req.body || {};
      if (!name) {
        return res.status(400).json({ error: 'name is required' });
      }

      const result = await query(
        `insert into accounts (type, category, server, name, description, price, image, tags, created_at, updated_at)
         values ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, now(), now())
         returning *`,
        [type, category, server, name, description, price, image, JSON.stringify(Array.isArray(tags) ? tags : [])]
      );

      return res.status(201).json(result.rows[0]);
    }

    if (req.method === 'PUT') {
      const { id, type, category, server, name, description, price, image, tags } = req.body || {};
      if (!id) {
        return res.status(400).json({ error: 'id is required' });
      }

      const result = await query(
        `update accounts
         set type = coalesce($2, type),
             category = coalesce($3, category),
             server = coalesce($4, server),
             name = coalesce($5, name),
             description = coalesce($6, description),
             price = coalesce($7, price),
             image = coalesce($8, image),
             tags = coalesce($9::jsonb, tags),
             updated_at = now()
         where id = $1
         returning *`,
        [id, type, category, server, name, description, price, image, tags !== undefined ? JSON.stringify(Array.isArray(tags) ? tags : []) : null]
      );

      if (!result.rows[0]) {
        return res.status(404).json({ error: 'account row not found' });
      }

      return res.status(200).json(result.rows[0]);
    }

    if (req.method === 'DELETE') {
      const id = req.query.id || (req.body && req.body.id);
      if (!id) {
        return res.status(400).json({ error: 'id is required' });
      }

      const result = await query('delete from accounts where id = $1 returning id', [id]);
      if (!result.rows[0]) {
        return res.status(404).json({ error: 'account row not found' });
      }

      return res.status(200).json({ deleted: result.rows[0].id });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    return res.status(500).json({ error: 'Database operation failed', detail: error.message });
  }
};
