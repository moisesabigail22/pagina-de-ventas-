#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

function normalizePrice(value) {
  if (value === null || value === undefined || value === '') return 0;
  if (typeof value === 'number') return value;
  const cleaned = String(value).replace(/\$/g, '').trim();
  const n = Number(cleaned);
  return Number.isFinite(n) ? n : 0;
}

function loadJson(filePath) {
  const fullPath = path.resolve(process.cwd(), filePath);
  if (!fs.existsSync(fullPath)) {
    throw new Error(`No existe el archivo: ${fullPath}`);
  }
  return JSON.parse(fs.readFileSync(fullPath, 'utf8'));
}

function ensureArray(value) {
  return Array.isArray(value) ? value : [];
}

function pickReferences(payload) {
  if (Array.isArray(payload.customer_references)) return payload.customer_references;
  if (Array.isArray(payload.references)) return payload.references;
  return [];
}

async function main() {
  const fileArg = process.argv[2] || 'data/catalog.json';
  const resetArg = process.argv.includes('--no-reset') ? false : true;

  if (!process.env.DATABASE_URL) {
    throw new Error('Falta DATABASE_URL en variables de entorno');
  }

  const payload = loadJson(fileArg);
  const settings = payload.settings || null;
  const goldCategories = ensureArray(payload.gold_categories || payload.goldCategories);
  const gameServers = ensureArray(payload.game_servers || payload.gameServers);
  const gold = ensureArray(payload.gold);
  const accounts = ensureArray(payload.accounts);
  const customerReferences = ensureArray(pickReferences(payload));
  const services = ensureArray(payload.services);

  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const client = await pool.connect();

  try {
    await client.query('begin');

    if (resetArg) {
      await client.query('delete from services');
      await client.query('delete from customer_references');
      await client.query('delete from accounts');
      await client.query('delete from gold');
      await client.query('delete from game_servers');
      await client.query('delete from gold_categories');
      await client.query('delete from settings');
    }

    if (settings) {
      await client.query(
        `insert into settings (discord, whatsapp, tiktok, email, site, updated_at)
         values ($1, $2, $3, $4, $5, now())`,
        [
          settings.discord || null,
          settings.whatsapp || null,
          settings.tiktok || null,
          settings.email || null,
          settings.site || null
        ]
      );
    }

    for (const row of goldCategories) {
      await client.query(
        `insert into gold_categories (game, server, description, image, created_at, updated_at)
         values ($1, $2, $3, $4, now(), now())`,
        [row.game || '', row.server || null, row.description || null, row.image || null]
      );
    }

    for (const row of gameServers) {
      await client.query(
        `insert into game_servers (game, name, created_at)
         values ($1, $2, now())`,
        [row.game || '', row.name || row.server || 'Unknown']
      );
    }

    for (const row of gold) {
      await client.query(
        `insert into gold (game, server, amount, price, delivery, stock, created_at, updated_at)
         values ($1, $2, $3, $4, $5, $6, now(), now())`,
        [
          row.game || '',
          row.server || '',
          Number(row.amount || 0),
          normalizePrice(row.price),
          row.delivery || null,
          row.stock !== undefined && row.stock !== null ? String(row.stock) : null
        ]
      );
    }

    for (const row of accounts) {
      await client.query(
        `insert into accounts (type, category, server, name, description, price, image, tags, created_at, updated_at)
         values ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, now(), now())`,
        [
          row.type || 'account',
          row.category || null,
          row.server || null,
          row.name || 'Account',
          row.description || null,
          row.price !== undefined && row.price !== null ? String(row.price) : null,
          row.image || null,
          JSON.stringify(Array.isArray(row.tags) ? row.tags : [])
        ]
      );
    }

    for (const row of customerReferences) {
      await client.query(
        `insert into customer_references (name, comment, rating, image, created_at)
         values ($1, $2, $3, $4, now())`,
        [
          row.name || 'Cliente',
          row.comment || null,
          row.rating !== undefined && row.rating !== null ? Number(row.rating) : null,
          row.image || null
        ]
      );
    }

    for (const row of services) {
      await client.query(
        `insert into services (category, game, server, name, description, price, created_at, updated_at)
         values ($1, $2, $3, $4, $5, $6, now(), now())`,
        [
          row.category || 'General',
          row.game || null,
          row.server || null,
          row.name || 'Servicio',
          row.description || null,
          row.price !== undefined && row.price !== null ? String(row.price) : null
        ]
      );
    }

    await client.query('commit');

    console.log('Importación completada ✅');
    console.log(
      JSON.stringify(
        {
          settings: settings ? 1 : 0,
          gold_categories: goldCategories.length,
          game_servers: gameServers.length,
          gold: gold.length,
          accounts: accounts.length,
          customer_references: customerReferences.length,
          services: services.length
        },
        null,
        2
      )
    );
  } catch (error) {
    await client.query('rollback');
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('Error importando catálogo:', err.message);
  process.exit(1);
});
