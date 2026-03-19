const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};

type AccountTicketPayload = {
  category?: string;
  server?: string;
  name?: string;
  price?: string;
  description?: string;
  image?: string;
  source?: string;
  created_at?: string;
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json'
    }
  });
}

function sanitizeThreadSegment(value: string, fallback: string) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9\s-]/g, '')
    .trim()
    .slice(0, 45) || fallback;
}

function isHttpUrl(value: string) {
  return /^https?:\/\//i.test(value);
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const webhookUrl = (Deno.env.get('DISCORD_ACCOUNTS_WEBHOOK_URL') || '').trim();
  const ticketPrefix = (Deno.env.get('DISCORD_ACCOUNTS_TICKET_PREFIX') || 'Ticket Cuenta').trim();
  if (!webhookUrl) {
    return jsonResponse({ error: 'Missing DISCORD_ACCOUNTS_WEBHOOK_URL secret' }, 500);
  }

  let payload: AccountTicketPayload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const requiredFields = ['category', 'name', 'price'] as const;
  for (const field of requiredFields) {
    if (!payload[field] || !String(payload[field]).trim()) {
      return jsonResponse({ error: `Missing field: ${field}` }, 400);
    }
  }

  const safePayload = {
    category: String(payload.category).trim(),
    server: String(payload.server || 'No especificado').trim(),
    name: String(payload.name).trim(),
    price: String(payload.price).trim(),
    description: String(payload.description || 'Sin descripción').trim().slice(0, 1000),
    image: String(payload.image || '').trim(),
    source: String(payload.source || 'web_account_order').trim(),
    created_at: String(payload.created_at || new Date().toISOString())
  };

  const threadName = `${sanitizeThreadSegment(ticketPrefix, 'Ticket Cuenta')} • ${sanitizeThreadSegment(safePayload.name, 'Cuenta')}`.slice(0, 90);
  const validImage = isHttpUrl(safePayload.image) ? safePayload.image : '';

  const discordBody = {
    content: `Nueva consulta de cuenta para **${safePayload.name}**`,
    thread_name: threadName,
    embeds: [
      {
        title: 'Nuevo ticket de cuenta',
        color: 0x4f8cff,
        fields: [
          { name: 'Categoría', value: safePayload.category, inline: true },
          { name: 'Servidor', value: safePayload.server, inline: true },
          { name: 'Cuenta', value: safePayload.name, inline: true },
          { name: 'Precio', value: safePayload.price, inline: true },
          { name: 'Origen', value: safePayload.source, inline: true },
          { name: 'Descripción', value: safePayload.description || 'Sin descripción', inline: false }
        ],
        image: validImage ? { url: validImage } : undefined,
        timestamp: safePayload.created_at,
        footer: {
          text: 'Epic Gold Shop · Accounts'
        }
      }
    ]
  };

  const discordResponse = await fetch(webhookUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(discordBody)
  });

  if (!discordResponse.ok) {
    const errorText = await discordResponse.text();
    return jsonResponse({ error: 'Discord webhook failed', details: errorText }, 502);
  }

  return jsonResponse({ ok: true, mode: 'webhook', thread_name: threadName });
});
