const { query } = require('../_lib/db');
const { verifyAdminToken } = require('../_lib/auth');

module.exports = async function handler(req, res) {
  const auth = verifyAdminToken(req);
  if (!auth.ok) {
    return res.status(401).json({ error: auth.error });
  }

  try {
    if (req.method === 'POST') {
      const { game, server, amount = 0, price = 0, delivery = null, stock = null } = req.body || {};
      if (!game || !server) {
        return res.status(400).json({ error: 'game and server are required' });
      }

      const result = await query(
        `insert into gold (game, server, amount, price, delivery, stock)
         values ($1, $2, $3, $4, $5, $6)
         returning *`,
        [game, server, amount, price, delivery, stock]
      );
      return res.status(201).json(result.rows[0]);
    }

    if (req.method === 'PUT') {
      const { id, game, server, amount, price, delivery, stock } = req.body || {};
      if (!id) {
        return res.status(400).json({ error: 'id is required' });
      }

      const result = await query(
        `update gold
         set game = coalesce($2, game),
             server = coalesce($3, server),
             amount = coalesce($4, amount),
             price = coalesce($5, price),
             delivery = coalesce($6, delivery),
             stock = coalesce($7, stock),
             updated_at = now()
         where id = $1
         returning *`,
        [id, game, server, amount, price, delivery, stock]
      );

      if (!result.rows[0]) {
        return res.status(404).json({ error: 'gold row not found' });
      }

      return res.status(200).json(result.rows[0]);
    }

    if (req.method === 'DELETE') {
      const id = req.query.id || (req.body && req.body.id);
      if (!id) {
        return res.status(400).json({ error: 'id is required' });
      }

      const result = await query('delete from gold where id = $1 returning id', [id]);
      if (!result.rows[0]) {
        return res.status(404).json({ error: 'gold row not found' });
      }

      return res.status(200).json({ deleted: result.rows[0].id });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    return res.status(500).json({ error: 'Database operation failed', detail: error.message });
  }
};
