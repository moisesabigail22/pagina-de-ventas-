const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};

type ServiceTicketPayload = {
  category?: string;
  game?: string;
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

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const webhookUrl = (Deno.env.get('DISCORD_SERVICES_WEBHOOK_URL') || '').trim();
  if (!webhookUrl) {
    return jsonResponse({ error: 'Missing DISCORD_SERVICES_WEBHOOK_URL secret' }, 500);
  }

  let payload: ServiceTicketPayload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const requiredFields = ['category', 'game', 'name', 'price'] as const;
  for (const field of requiredFields) {
    if (!payload[field] || !String(payload[field]).trim()) {
      return jsonResponse({ error: `Missing field: ${field}` }, 400);
    }
  }

  const safePayload = {
    category: String(payload.category).trim(),
    game: String(payload.game).trim(),
    name: String(payload.name).trim(),
    price: String(payload.price).trim(),
    description: String(payload.description || 'Sin descripción').trim().slice(0, 1000),
    image: String(payload.image || '').trim(),
    source: String(payload.source || 'web_service_order').trim(),
    created_at: String(payload.created_at || new Date().toISOString())
  };

  const discordBody = {
    content: `Nueva consulta de servicio para **${safePayload.name}**`,
    embeds: [
      {
        title: 'Nuevo ticket de servicio',
        color: 0xa86dff,
        fields: [
          { name: 'Categoría', value: safePayload.category, inline: true },
          { name: 'Juego', value: safePayload.game, inline: true },
          { name: 'Servicio', value: safePayload.name, inline: true },
          { name: 'Precio', value: `$${safePayload.price}`.replace('$$', '$'), inline: true },
          { name: 'Origen', value: safePayload.source, inline: true },
          { name: 'Descripción', value: safePayload.description || 'Sin descripción', inline: false }
        ],
        image: safePayload.image ? { url: safePayload.image } : undefined,
        timestamp: safePayload.created_at,
        footer: {
          text: 'Epic Gold Shop · Services'
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

  return jsonResponse({ ok: true, mode: 'webhook' });
});
