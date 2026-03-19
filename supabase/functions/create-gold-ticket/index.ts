const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};

type GoldTicketPayload = {
  game?: string;
  server?: string;
  amount?: string;
  price?: string;
  faction?: string;
  character?: string;
  trade?: string;
  discord_user_id?: string;
  custom_amount?: boolean;
  source?: string;
  created_at?: string;
};

type DiscordSnowflake = string;

type DiscordChannelResponse = {
  id: DiscordSnowflake;
  guild_id?: DiscordSnowflake;
  name?: string;
};

type DiscordPermissionOverwrite = {
  id: DiscordSnowflake;
  type: 0 | 1;
  allow: string;
  deny: string;
};

const DISCORD_PERMISSION_VIEW_CHANNEL = 1n << 10n;
const DISCORD_PERMISSION_SEND_MESSAGES = 1n << 11n;
const DISCORD_PERMISSION_READ_HISTORY = 1n << 16n;
const DISCORD_PERMISSION_MANAGE_CHANNELS = 1n << 4n;

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json'
    }
  });
}

function getEnv(name: string, fallback = '') {
  return (Deno.env.get(name) || fallback).trim();
}

function normalizeCharacterName(value: string) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80) || 'pedido';
}

function buildTicketName(ticketPrefix: string, character: string) {
  const prefix = normalizeCharacterName(ticketPrefix || 'ticket-oro').slice(0, 18) || 'ticket-oro';
  const safeCharacter = normalizeCharacterName(character).slice(0, 60) || 'pedido';
  return `${prefix}-${safeCharacter}`.slice(0, 100);
}

function normalizeDiscordUserId(value: string) {
  const match = String(value || '').trim().match(/(\d{17,20})/);
  return match ? match[1] : '';
}

function parseDiscordUserIdList(value: string) {
  return Array.from(new Set(
    String(value || '')
      .split(',')
      .map((entry) => normalizeDiscordUserId(entry))
      .filter(Boolean)
  ));
}

function buildDiscordEmbed(payload: Required<GoldTicketPayload>) {
  return {
    title: 'Nuevo ticket de compra de oro',
    color: 0xc8aa6d,
    fields: [
      { name: 'Juego', value: payload.game, inline: true },
      { name: 'Servidor', value: payload.server, inline: true },
      { name: 'Cantidad', value: payload.amount, inline: true },
      { name: 'Precio', value: payload.price, inline: true },
      { name: 'Facción', value: payload.faction, inline: true },
      { name: 'Trade', value: payload.trade, inline: true },
      { name: 'Personaje', value: payload.character, inline: true },
      { name: 'Usuario Discord', value: `<@${payload.discord_user_id}> (${payload.discord_user_id})`, inline: false },
      { name: 'Tipo', value: payload.custom_amount ? 'Cantidad específica' : 'Paquete estándar', inline: true },
      { name: 'Origen', value: payload.source, inline: true }
    ],
    timestamp: payload.created_at,
    footer: {
      text: 'Epic Gold Shop'
    }
  };
}

async function discordApi<T>(path: string, token: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(`https://discord.com/api/v10${path}`, {
    ...init,
    headers: {
      Authorization: `Bot ${token}`,
      'Content-Type': 'application/json',
      ...(init.headers || {})
    }
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Discord API ${path} failed (${response.status}): ${errorText}`);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return await response.json() as T;
}

async function createGuildChannel(
  token: string,
  guildId: string,
  parentId: string,
  adminUserIds: DiscordSnowflake[],
  channelName: string,
  payload: Required<GoldTicketPayload>
) {
  const everyoneAllow = '0';
  const everyoneDeny = DISCORD_PERMISSION_VIEW_CHANNEL.toString();
  const adminAllow = (
    DISCORD_PERMISSION_VIEW_CHANNEL |
    DISCORD_PERMISSION_SEND_MESSAGES |
    DISCORD_PERMISSION_READ_HISTORY |
    DISCORD_PERMISSION_MANAGE_CHANNELS
  ).toString();
  const customerAllow = (
    DISCORD_PERMISSION_VIEW_CHANNEL |
    DISCORD_PERMISSION_SEND_MESSAGES |
    DISCORD_PERMISSION_READ_HISTORY
  ).toString();

  const permissionOverwrites: DiscordPermissionOverwrite[] = [
    {
      id: guildId,
      type: 0,
      allow: everyoneAllow,
      deny: everyoneDeny
    }
  ];

  adminUserIds.forEach((adminUserId) => {
    permissionOverwrites.push({
      id: adminUserId,
      type: 1,
      allow: adminAllow,
      deny: '0'
    });
  });

  if (payload.discord_user_id) {
    permissionOverwrites.push({
      id: payload.discord_user_id,
      type: 1,
      allow: customerAllow,
      deny: '0'
    });
  }

  return await discordApi<DiscordChannelResponse>(`/guilds/${guildId}/channels`, token, {
    method: 'POST',
    body: JSON.stringify({
      name: channelName,
      type: 0,
      parent_id: parentId,
      topic: `Pedido web · ${payload.character} · ${payload.game} · ${payload.server}`.slice(0, 1024),
      permission_overwrites: permissionOverwrites
    })
  });
}

async function postChannelMessage(token: string, channelId: string, body: Record<string, unknown>) {
  return await discordApi(`/channels/${channelId}/messages`, token, {
    method: 'POST',
    body: JSON.stringify(body)
  });
}

async function createBotTicket(payload: Required<GoldTicketPayload>) {
  const botToken = getEnv('DISCORD_BOT_TOKEN');
  const guildId = getEnv('DISCORD_GUILD_ID');
  const categoryId = getEnv('DISCORD_WEB_CATEGORY_ID');
  const logChannelId = getEnv('DISCORD_WEB_LOG_CHANNEL_ID');
  const adminUserIds = parseDiscordUserIdList(getEnv('DISCORD_WEB_ADMIN_IDS'));
  const ticketPrefix = getEnv('DISCORD_TICKET_PREFIX', 'ticket-oro');

  const missingSecrets = [
    ['DISCORD_BOT_TOKEN', botToken],
    ['DISCORD_GUILD_ID', guildId],
    ['DISCORD_WEB_CATEGORY_ID', categoryId]
  ].filter(([, value]) => !value).map(([name]) => name);

  if (missingSecrets.length > 0) {
    throw new Error(`Missing Discord bot secrets: ${missingSecrets.join(', ')}`);
  }

  if (adminUserIds.length === 0) {
    throw new Error('Missing Discord admin visibility config: set DISCORD_WEB_ADMIN_IDS with one or more admin user IDs.');
  }

  const channelName = buildTicketName(ticketPrefix, payload.character);
  const channel = await createGuildChannel(botToken, guildId, categoryId, adminUserIds, channelName, payload);
  const embed = buildDiscordEmbed(payload);
  const adminMentions = adminUserIds.map((adminUserId) => `<@${adminUserId}>`).join(' ');
  const openingMessage = adminMentions || 'Nuevo pedido desde la web.';

  await postChannelMessage(botToken, channel.id, {
    content: openingMessage,
    embeds: [embed]
  });

  if (logChannelId && logChannelId !== channel.id) {
    await postChannelMessage(botToken, logChannelId, {
      content: `Nuevo ticket creado: <#${channel.id}>`,
      embeds: [embed]
    });
  }

  return {
    ok: true,
    mode: 'bot',
    channel_id: channel.id,
    channel_name: channel.name || channelName,
    discord_url: `https://discord.com/channels/${guildId}/${channel.id}`,
    customer_visibility: payload.discord_user_id ? 'granted' : 'missing_discord_user_id'
  };
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  let payload: GoldTicketPayload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const requiredFields = ['game', 'server', 'amount', 'price', 'faction', 'character', 'trade', 'discord_user_id'] as const;
  for (const field of requiredFields) {
    if (!payload[field] || !String(payload[field]).trim()) {
      return jsonResponse({ error: `Missing field: ${field}` }, 400);
    }
  }

  const discordUserId = normalizeDiscordUserId(String(payload.discord_user_id));
  if (!discordUserId) {
    return jsonResponse({ error: 'Invalid discord_user_id. Provide a Discord user ID, mention, or profile link that contains the user ID.' }, 400);
  }

  const safePayload: Required<GoldTicketPayload> = {
    game: String(payload.game).trim(),
    server: String(payload.server).trim(),
    amount: String(payload.amount).trim(),
    price: String(payload.price).trim(),
    faction: String(payload.faction).trim(),
    character: String(payload.character).trim().slice(0, 80),
    trade: String(payload.trade).trim(),
    discord_user_id: discordUserId,
    custom_amount: Boolean(payload.custom_amount),
    source: String(payload.source || 'web_gold_order').trim(),
    created_at: String(payload.created_at || new Date().toISOString())
  };

  try {
    return jsonResponse(await createBotTicket(safePayload));
  } catch (error) {
    console.error(error);
    return jsonResponse({
      error: 'Ticket creation failed',
      details: error instanceof Error ? error.message : String(error),
      mode: 'bot'
    }, 502);
  }
});
