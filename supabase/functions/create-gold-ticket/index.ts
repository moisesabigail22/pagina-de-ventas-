const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};

// Nota:
// - Si el webhook apunta a un canal FORUM de Discord, `thread_name` crea un ticket/post nuevo.
// - Si el webhook apunta a un canal normal, publicará el pedido como mensaje estructurado.

type GoldTicketPayload = {
  game?: string;
  server?: string;
  amount?: string;
  price?: string;
  faction?: string;
  character?: string;
  trade?: string;
  custom_amount?: boolean;
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

  const webhookUrl = Deno.env.get('DISCORD_WEBHOOK_URL');
  const ticketPrefix = Deno.env.get('DISCORD_TICKET_PREFIX') || 'Ticket Oro';

  if (!webhookUrl) {
    return jsonResponse({ error: 'Missing DISCORD_WEBHOOK_URL secret' }, 500);
  }

  let payload: GoldTicketPayload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const requiredFields = ['game', 'server', 'amount', 'price', 'faction', 'character', 'trade'] as const;
  for (const field of requiredFields) {
    if (!payload[field] || !String(payload[field]).trim()) {
      return jsonResponse({ error: `Missing field: ${field}` }, 400);
    }
  }

  const safeCharacter = String(payload.character).trim().slice(0, 40);
  const threadName = `${ticketPrefix} • ${safeCharacter}`;

  const discordBody = {
    content: `Nueva solicitud de oro para **${payload.character}**`,
    thread_name: threadName,
    embeds: [
      {
        title: 'Nuevo ticket de compra de oro',
        color: 0xc8aa6d,
        fields: [
          { name: 'Juego', value: String(payload.game), inline: true },
          { name: 'Servidor', value: String(payload.server), inline: true },
          { name: 'Cantidad', value: String(payload.amount), inline: true },
          { name: 'Precio', value: String(payload.price), inline: true },
          { name: 'Facción', value: String(payload.faction), inline: true },
          { name: 'Trade', value: String(payload.trade), inline: true },
          { name: 'Personaje', value: String(payload.character), inline: true },
          { name: 'Tipo', value: payload.custom_amount ? 'Cantidad específica' : 'Paquete estándar', inline: true },
          { name: 'Origen', value: String(payload.source || 'web_gold_order'), inline: true }
        ],
        timestamp: payload.created_at || new Date().toISOString(),
        footer: {
          text: 'Epic Gold Shop'
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

  return jsonResponse({ ok: true, thread_name: threadName });
});
