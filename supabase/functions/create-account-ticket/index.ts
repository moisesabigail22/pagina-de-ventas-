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
  customer_name?: string;
  customer_email?: string;
  customer_discord?: string;
  source?: string;
  created_at?: string;
};

type DiscordSnowflake = string;

type DiscordChannelResponse = {
  id: DiscordSnowflake;
  guild_id?: DiscordSnowflake;
  name?: string;
};

type DiscordBotUserResponse = {
  id: DiscordSnowflake;
  username?: string;
};

type DiscordMessageResponse = {
  id: DiscordSnowflake;
};

type DiscordPermissionOverwrite = {
  id: DiscordSnowflake;
  type: 0 | 1;
  allow: string;
  deny: string;
};

type DiscordVisibilityConfig = {
  adminRoleIds: DiscordSnowflake[];
  adminUserIds: DiscordSnowflake[];
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

function normalizeLabel(value: string, fallback: string) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80) || fallback;
}

function parseDiscordSnowflakeList(value: string) {
  return Array.from(new Set(
    String(value || '')
      .split(',')
      .map((entry) => {
        const match = String(entry || '').trim().match(/(\d{17,20})/);
        return match ? match[1] : '';
      })
      .filter(Boolean)
  ));
}

function isHttpUrl(value: string) {
  return /^https?:\/\//i.test(value);
}

function buildTicketName(ticketPrefix: string, accountName: string) {
  const prefix = normalizeLabel(ticketPrefix || 'ticket-cuenta', 'ticket-cuenta').slice(0, 24);
  const safeName = normalizeLabel(accountName, 'cuenta').slice(0, 60);
  return `${prefix}-${safeName}`.slice(0, 100);
}

function buildDiscordEmbed(payload: Required<AccountTicketPayload>) {
  const contactLines = [
    payload.customer_name ? `Nombre: ${payload.customer_name}` : '',
    payload.customer_email ? `Gmail: ${payload.customer_email}` : '',
    payload.customer_discord ? `Discord: ${payload.customer_discord}` : ''
  ].filter(Boolean).join('\n');

  return {
    title: 'Nuevo ticket de cuenta',
    color: 0x4f8cff,
    fields: [
      { name: 'Categoría', value: payload.category, inline: true },
      { name: 'Servidor', value: payload.server, inline: true },
      { name: 'Cuenta', value: payload.name, inline: true },
      { name: 'Precio', value: payload.price, inline: true },
      { name: 'Comprador', value: payload.customer_name || 'No indicado', inline: true },
      { name: 'Contacto', value: contactLines || 'No indicado', inline: false },
      { name: 'Origen', value: payload.source, inline: true },
      { name: 'Descripción', value: payload.description || 'Sin descripción', inline: false }
    ],
    image: isHttpUrl(payload.image) ? { url: payload.image } : undefined,
    timestamp: payload.created_at,
    footer: {
      text: 'Epic Gold Shop · Accounts'
    }
  };
}

function formatDiscordApiError(path: string, status: number, errorText: string) {
  if (status === 404 && path.includes('/guilds/') && path.endsWith('/channels')) {
    return `Discord respondió 404 al intentar crear el canal en ${path}. Revisa que DISCORD_GUILD_ID sea el ID del servidor correcto y que el bot siga dentro de ese servidor. Respuesta original: ${errorText}`;
  }

  if (status === 403 && path.includes('/channels/') && path.endsWith('/messages')) {
    return `Discord respondió 403 al intentar publicar el mensaje del ticket en ${path}. El canal se creó, pero el bot no tiene acceso para escribir ahí. Revisa los permisos heredados de la categoría. Respuesta original: ${errorText}`;
  }

  return `La API de Discord falló en ${path} (${status}). Respuesta: ${errorText}`;
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
    throw new Error(formatDiscordApiError(path, response.status, errorText));
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return await response.json() as T;
}

async function getBotUser(token: string) {
  return await discordApi<DiscordBotUserResponse>('/users/@me', token, { method: 'GET' });
}

async function createGuildChannel(
  token: string,
  guildId: string,
  parentId: string,
  visibilityConfig: DiscordVisibilityConfig,
  botUserId: DiscordSnowflake,
  channelName: string,
  payload: Required<AccountTicketPayload>
) {
  const everyoneAllow = '0';
  const everyoneDeny = DISCORD_PERMISSION_VIEW_CHANNEL.toString();
  const adminAllow = (
    DISCORD_PERMISSION_VIEW_CHANNEL |
    DISCORD_PERMISSION_SEND_MESSAGES |
    DISCORD_PERMISSION_READ_HISTORY |
    DISCORD_PERMISSION_MANAGE_CHANNELS
  ).toString();

  const permissionOverwrites: DiscordPermissionOverwrite[] = [
    {
      id: guildId,
      type: 0,
      allow: everyoneAllow,
      deny: everyoneDeny
    },
    {
      id: botUserId,
      type: 1,
      allow: adminAllow,
      deny: '0'
    }
  ];

  visibilityConfig.adminRoleIds.forEach((adminRoleId) => {
    permissionOverwrites.push({
      id: adminRoleId,
      type: 0,
      allow: adminAllow,
      deny: '0'
    });
  });

  visibilityConfig.adminUserIds.forEach((adminUserId) => {
    permissionOverwrites.push({
      id: adminUserId,
      type: 1,
      allow: adminAllow,
      deny: '0'
    });
  });

  return await discordApi<DiscordChannelResponse>(`/guilds/${guildId}/channels`, token, {
    method: 'POST',
    body: JSON.stringify({
      name: channelName,
      type: 0,
      parent_id: parentId,
      topic: `Cuenta web · ${payload.name} · ${payload.server}`.slice(0, 1024),
      permission_overwrites: permissionOverwrites
    })
  });
}

async function postChannelMessage(token: string, channelId: string, body: Record<string, unknown>) {
  return await discordApi<DiscordMessageResponse>(`/channels/${channelId}/messages`, token, {
    method: 'POST',
    body: JSON.stringify(body)
  });
}

async function createBotTicket(payload: Required<AccountTicketPayload>) {
  const botToken = getEnv('DISCORD_BOT_TOKEN');
  const guildId = getEnv('DISCORD_GUILD_ID');
  const categoryId = getEnv('DISCORD_ACCOUNTS_CATEGORY_ID', getEnv('DISCORD_WEB_CATEGORY_ID'));
  const logChannelId = getEnv('DISCORD_ACCOUNTS_LOG_CHANNEL_ID', getEnv('DISCORD_WEB_LOG_CHANNEL_ID'));
  const adminRoleIds = parseDiscordSnowflakeList(getEnv('DISCORD_ACCOUNTS_ADMIN_ROLE_IDS', getEnv('DISCORD_WEB_ADMIN_ROLE_IDS')));
  const adminUserIds = parseDiscordSnowflakeList(getEnv('DISCORD_ACCOUNTS_ADMIN_IDS', getEnv('DISCORD_WEB_ADMIN_IDS')));
  const ticketPrefix = getEnv('DISCORD_ACCOUNTS_TICKET_PREFIX', 'ticket-cuenta');

  const missingSecrets = [
    ['DISCORD_BOT_TOKEN', botToken],
    ['DISCORD_GUILD_ID', guildId],
    ['DISCORD_ACCOUNTS_CATEGORY_ID', categoryId]
  ].filter(([, value]) => !value).map(([name]) => name);

  if (missingSecrets.length > 0) {
    throw new Error(`Faltan secretos del bot de Discord para cuentas: ${missingSecrets.join(', ')}`);
  }

  if (adminRoleIds.length === 0 && adminUserIds.length === 0) {
    throw new Error('Falta la configuración de visibilidad para admins en cuentas: define DISCORD_ACCOUNTS_ADMIN_ROLE_IDS y/o DISCORD_ACCOUNTS_ADMIN_IDS.');
  }

  const visibilityConfig: DiscordVisibilityConfig = {
    adminRoleIds,
    adminUserIds
  };

  const botUserId = (await getBotUser(botToken)).id;
  const channelName = buildTicketName(ticketPrefix, payload.name);
  const channel = await createGuildChannel(botToken, guildId, categoryId, visibilityConfig, botUserId, channelName, payload);
  const embed = buildDiscordEmbed(payload);
  const adminRoleMentions = adminRoleIds.map((adminRoleId) => `<@&${adminRoleId}>`).join(' ');
  const adminUserMentions = adminUserIds.map((adminUserId) => `<@${adminUserId}>`).join(' ');
  const openingMessage = [adminRoleMentions, adminUserMentions].filter(Boolean).join(' ').trim() || 'Nueva consulta de cuenta desde la web.';

  const ticketMessage = await postChannelMessage(botToken, channel.id, {
    content: openingMessage,
    embeds: [embed]
  });

  if (logChannelId && logChannelId !== channel.id) {
    try {
      await postChannelMessage(botToken, logChannelId, {
        content: `Nuevo ticket de cuenta creado: <#${channel.id}>`,
        embeds: [embed]
      });
    } catch (error) {
      console.warn('Account log channel notification failed:', error);
    }
  }

  return {
    ok: true,
    mode: 'bot',
    channel_id: channel.id,
    channel_name: channel.name || channelName,
    discord_url: `https://discord.com/channels/${guildId}/${channel.id}`,
    discord_message_url: `https://discord.com/channels/${guildId}/${channel.id}/${ticketMessage.id}`,
    visibility_scope: {
      roles: adminRoleIds.length,
      users: adminUserIds.length
    }
  };
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Método no permitido' }, 405);
  }

  let payload: AccountTicketPayload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'El body JSON no es válido' }, 400);
  }

  const requiredFields = ['category', 'name', 'price'] as const;
  for (const field of requiredFields) {
    if (!payload[field] || !String(payload[field]).trim()) {
      return jsonResponse({ error: `Falta el campo requerido: ${field}` }, 400);
    }
  }

  const safePayload: Required<AccountTicketPayload> = {
    category: String(payload.category).trim(),
    server: String(payload.server || 'No especificado').trim(),
    name: String(payload.name).trim(),
    price: String(payload.price).trim(),
    description: String(payload.description || 'Sin descripción').trim().slice(0, 1000),
    image: String(payload.image || '').trim(),
    customer_name: String(payload.customer_name || '').trim().slice(0, 120),
    customer_email: String(payload.customer_email || '').trim().slice(0, 160),
    customer_discord: String(payload.customer_discord || '').trim().slice(0, 120),
    source: String(payload.source || 'web_account_order').trim(),
    created_at: String(payload.created_at || new Date().toISOString())
  };

  try {
    return jsonResponse(await createBotTicket(safePayload));
  } catch (error) {
    console.error(error);
    return jsonResponse({
      error: 'No se pudo crear el ticket de cuenta',
      details: error instanceof Error ? error.message : String(error),
      mode: 'bot'
    }, 502);
  }
});
