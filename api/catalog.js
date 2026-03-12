const { query } = require('./_lib/db');

module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const [
      settings,
      goldCategories,
      gameServers,
      gold,
      accounts,
      customerReferences
    ] = await Promise.all([
      query('select * from settings order by updated_at desc limit 1'),
      query('select * from gold_categories order by created_at desc'),
      query('select * from game_servers order by game asc, name asc'),
      query('select * from gold order by created_at desc'),
      query('select * from accounts order by created_at desc'),
      query('select * from customer_references order by created_at desc')
    ]);

    return res.status(200).json({
      settings: settings.rows[0] || null,
      gold_categories: goldCategories.rows,
      game_servers: gameServers.rows,
      gold: gold.rows,
      accounts: accounts.rows,
      customer_references: customerReferences.rows
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Database error while fetching catalog',
      detail: error.message
    });
  }
};
