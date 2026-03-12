const { query } = require('./_lib/db');

async function safeSelect(sql) {
  try {
    return await query(sql);
  } catch (error) {
    if (error && error.code === '42P01') {
      return { rows: [] };
    }
    throw error;
  }
}

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
      customerReferences,
      services
    ] = await Promise.all([
      safeSelect('select * from settings order by updated_at desc limit 1'),
      safeSelect('select * from gold_categories order by created_at desc'),
      safeSelect('select * from game_servers order by game asc, name asc'),
      safeSelect('select * from gold order by created_at desc'),
      safeSelect('select * from accounts order by created_at desc'),
      safeSelect('select * from customer_references order by created_at desc'),
      safeSelect('select * from services order by created_at desc')
    ]);

    return res.status(200).json({
      settings: settings.rows[0] || null,
      gold_categories: goldCategories.rows,
      game_servers: gameServers.rows,
      gold: gold.rows,
      accounts: accounts.rows,
      customer_references: customerReferences.rows,
      services: services.rows
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Database error while fetching catalog',
      detail: error.message
    });
  }
};
