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
  customer_contact?: string;
  payment_method_name?: string;
  payment_method_label?: string;
  payment_method_value?: string;
  transaction_proof_name?: string;
  transaction_proof_data_url?: string;
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

type DiscordBotUserResponse = {
  id: DiscordSnowflake;
  username?: string;
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

type DiscordAttachmentInput = {
  fileName: string;
  mimeType: string;
  bytes: Uint8Array;
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

function normalizeDiscordSnowflake(value: string) {
  const match = String(value || '').trim().match(/(\d{17,20})/);
  return match ? match[1] : '';
}

function parseDiscordSnowflakeList(value: string) {
  return Array.from(new Set(
    String(value || '')
      .split(',')
      .map((entry) => normalizeDiscordSnowflake(entry))
      .filter(Boolean)
  ));
}

function buildDiscordEmbed(payload: Required<GoldTicketPayload>, proofFileName = '') {
  const embed: Record<string, unknown> = {
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
      { name: 'Correo o Discord', value: payload.customer_contact, inline: false },
      { name: 'Método de pago', value: payload.payment_method_name, inline: true },
      { name: payload.payment_method_label, value: payload.payment_method_value, inline: true },
      { name: 'Tipo', value: payload.custom_amount ? 'Cantidad específica' : 'Paquete estándar', inline: true },
      { name: 'Origen', value: payload.source, inline: true }
    ],
    timestamp: payload.created_at,
    footer: {
      text: 'Epic Gold Shop'
    }
  };

  if (proofFileName) {
    embed.image = {
      url: `attachment://${proofFileName}`
    };
  }

  return embed;
}

function formatDiscordApiError(path: string, status: number, errorText: string) {
  if (status === 404 && path.includes('/guilds/') && path.endsWith('/channels')) {
    return `Discord respondió 404 al intentar crear el canal en ${path}. Revisa que DISCORD_GUILD_ID sea el ID del servidor (guild) correcto y que el bot siga dentro de ese servidor. Respuesta original: ${errorText}`;
  }

  if (status === 403 && path.includes('/channels/') && path.endsWith('/messages')) {
    return `Discord respondió 403 al intentar publicar el mensaje del ticket en ${path}. El canal se creó, pero el bot no tiene acceso para escribir ahí. Revisa los permisos heredados de la categoría y asegúrate de que el bot conserve acceso al canal. Respuesta original: ${errorText}`;
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

function sanitizeFileName(value: string) {
  return String(value || 'capture-transaccion.png')
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80) || 'capture-transaccion.png';
}

function parseDataUrlAttachment(fileName: string, dataUrl: string): DiscordAttachmentInput {
  const match = String(dataUrl || '').trim().match(/^data:([^;]+);base64,(.+)$/);
  if (!match) {
    throw new Error('El capture de la transacción no tiene un formato Data URL válido.');
  }

  const mimeType = match[1].trim().toLowerCase();
  const extensionMap: Record<string, string> = {
    'image/png': 'png',
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/webp': 'webp',
    'image/gif': 'gif'
  };
  const extension = extensionMap[mimeType];
  if (!extension) {
    throw new Error('El capture de la transacción debe ser una imagen PNG, JPG, WEBP o GIF.');
  }

  const binary = atob(match[2]);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }

  const maxBytes = 7 * 1024 * 1024;
  if (bytes.byteLength > maxBytes) {
    throw new Error('El capture de la transacción supera el tamaño máximo permitido de 7 MB.');
  }

  const safeFileName = sanitizeFileName(fileName);
  const finalFileName = safeFileName.includes('.') ? safeFileName : `${safeFileName}.${extension}`;

  return {
    fileName: finalFileName,
    mimeType,
    bytes
  };
}

async function postChannelMessageWithAttachment(
  token: string,
  channelId: string,
  body: Record<string, unknown>,
  attachment: DiscordAttachmentInput
) {
  const formData = new FormData();
  formData.append('payload_json', JSON.stringify(body));
  formData.append('files[0]', new Blob([attachment.bytes], { type: attachment.mimeType }), attachment.fileName);

  const response = await fetch(`https://discord.com/api/v10/channels/${channelId}/messages`, {
    method: 'POST',
    headers: {
      Authorization: `Bot ${token}`
    },
    body: formData
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(formatDiscordApiError(`/channels/${channelId}/messages`, response.status, errorText));
  }

  if (response.status === 204) {
    return;
  }

  await response.json();
}

async function createBotTicket(payload: Required<GoldTicketPayload>) {
  const botToken = getEnv('DISCORD_BOT_TOKEN');
  const guildId = getEnv('DISCORD_GUILD_ID');
  const categoryId = getEnv('DISCORD_WEB_CATEGORY_ID');
  const logChannelId = getEnv('DISCORD_WEB_LOG_CHANNEL_ID');
  const adminRoleIds = parseDiscordSnowflakeList(getEnv('DISCORD_WEB_ADMIN_ROLE_IDS'));
  const adminUserIds = parseDiscordSnowflakeList(getEnv('DISCORD_WEB_ADMIN_IDS'));
  const ticketPrefix = getEnv('DISCORD_TICKET_PREFIX', 'ticket-oro');

  const missingSecrets = [
    ['DISCORD_BOT_TOKEN', botToken],
    ['DISCORD_GUILD_ID', guildId],
    ['DISCORD_WEB_CATEGORY_ID', categoryId]
  ].filter(([, value]) => !value).map(([name]) => name);

  if (missingSecrets.length > 0) {
    throw new Error(`Faltan secretos del bot de Discord: ${missingSecrets.join(', ')}`);
  }

  if (adminRoleIds.length === 0 && adminUserIds.length === 0) {
    throw new Error('Falta la configuración de visibilidad para admins: define DISCORD_WEB_ADMIN_ROLE_IDS y/o DISCORD_WEB_ADMIN_IDS con uno o más IDs de Discord.');
  }

  const visibilityConfig: DiscordVisibilityConfig = {
    adminRoleIds,
    adminUserIds
  };

  let botUserId = '';
  try {
    botUserId = (await getBotUser(botToken)).id;
  } catch (error) {
    throw new Error(`No se pudo identificar el bot de Discord: ${error instanceof Error ? error.message : String(error)}`);
  }

  const channelName = buildTicketName(ticketPrefix, payload.character);
  let channel: DiscordChannelResponse;
  try {
    channel = await createGuildChannel(botToken, guildId, categoryId, visibilityConfig, botUserId, channelName, payload);
  } catch (error) {
    throw new Error(`No se pudo crear el canal en Discord: ${error instanceof Error ? error.message : String(error)}`);
  }

  const proofAttachment = parseDataUrlAttachment(payload.transaction_proof_name, payload.transaction_proof_data_url);
  const embed = buildDiscordEmbed(payload, proofAttachment.fileName);
  const adminRoleMentions = adminRoleIds.map((adminRoleId) => `<@&${adminRoleId}>`).join(' ');
  const adminUserMentions = adminUserIds.map((adminUserId) => `<@${adminUserId}>`).join(' ');
  const openingMessage = [adminRoleMentions, adminUserMentions].filter(Boolean).join(' ').trim() || 'Nuevo pedido desde la web.';

  try {
    await postChannelMessageWithAttachment(botToken, channel.id, {
      content: openingMessage,
      embeds: [embed]
    }, proofAttachment);
  } catch (error) {
    throw new Error(`No se pudo publicar el mensaje inicial del ticket en Discord: ${error instanceof Error ? error.message : String(error)}`);
  }

  if (logChannelId && logChannelId !== channel.id) {
    try {
      await postChannelMessage(botToken, logChannelId, {
        content: `Nuevo ticket creado: <#${channel.id}>`,
        embeds: [embed]
      });
    } catch (error) {
      console.warn('Discord log channel notification failed:', error);
    }
  }

  return {
    ok: true,
    mode: 'bot',
    channel_id: channel.id,
    channel_name: channel.name || channelName,
    discord_url: `https://discord.com/channels/${guildId}/${channel.id}`,
    customer_visibility: 'admins_only',
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

  let payload: GoldTicketPayload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: 'El body JSON no es válido' }, 400);
  }

  const requiredFields = ['game', 'server', 'amount', 'price', 'faction', 'character', 'trade', 'customer_contact', 'payment_method_name', 'payment_method_label', 'payment_method_value', 'transaction_proof_name', 'transaction_proof_data_url'] as const;
  for (const field of requiredFields) {
    if (!payload[field] || !String(payload[field]).trim()) {
      return jsonResponse({ error: `Falta el campo requerido: ${field}` }, 400);
    }
  }

  const safePayload: Required<GoldTicketPayload> = {
    game: String(payload.game).trim(),
    server: String(payload.server).trim(),
    amount: String(payload.amount).trim(),
    price: String(payload.price).trim(),
    faction: String(payload.faction).trim(),
    character: String(payload.character).trim().slice(0, 80),
    trade: String(payload.trade).trim(),
    customer_contact: String(payload.customer_contact).trim().slice(0, 160),
    payment_method_name: String(payload.payment_method_name).trim(),
    payment_method_label: String(payload.payment_method_label).trim(),
    payment_method_value: String(payload.payment_method_value).trim(),
    transaction_proof_name: String(payload.transaction_proof_name).trim(),
    transaction_proof_data_url: String(payload.transaction_proof_data_url).trim(),
    custom_amount: Boolean(payload.custom_amount),
    source: String(payload.source || 'web_gold_order').trim(),
    created_at: String(payload.created_at || new Date().toISOString())
  };

  try {
    return jsonResponse(await createBotTicket(safePayload));
  } catch (error) {
    console.error(error);
    return jsonResponse({
      error: 'No se pudo crear el ticket',
      details: error instanceof Error ? error.message : String(error),
      mode: 'bot'
    }, 502);
  }
});
