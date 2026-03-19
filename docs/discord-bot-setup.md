# Configuración de bot propio para tickets privados desde la web

Esta guía es para el caso en que quieres que:

- el usuario entre a tu web,
- presione **Comprar**,
- complete el formulario,
- y se cree un **ticket privado en Discord**
- visible **solo para tus usuarios admin y para ese comprador**.

> **Importante:** este flujo **NO debe usar webhook**. Debe usar tu **bot propio** porque el código crea permisos privados por usuario dentro de Discord. En el código actual eso depende de `DISCORD_TICKET_MODE` y de los `permission_overwrites` que se agregan al canal. Si usas webhook, el comprador no se agrega automáticamente al ticket privado.

## Cómo funciona el flujo actual

Cuando el usuario compra oro en la web:

1. La web recoge los datos del pedido.
2. También recoge un identificador del comprador en Discord.
   - puede ser su **ID**,
   - una **mención** tipo `<@123...>`,
   - o un **link de perfil** de Discord.
3. La web llama a la Edge Function `create-gold-ticket`.
4. La función convierte ese valor a un **Discord user ID real**.
5. La función crea un canal privado en tu servidor.
6. La función deja acceso a:
   - tus usuarios admin configurados,
   - y el usuario de Discord indicado en el formulario.
7. La función devuelve la URL del canal para abrir Discord directamente.

## Lo que necesitas antes de empezar

Necesitas tener:

- un servidor de Discord tuyo,
- una aplicación/bot de Discord tuyo,
- acceso al panel de Discord Developer Portal,
- acceso al panel o CLI de Supabase,
- el proyecto web desplegado con estas functions.

## Paso 1: crear tu bot en Discord

1. Entra a: <https://discord.com/developers/applications>
2. Crea una nueva aplicación.
3. Ve a la pestaña **Bot**.
4. Pulsa **Add Bot**.
5. Copia el token del bot. Ese valor será tu `DISCORD_BOT_TOKEN`.
6. Activa estos ajustes si aparecen en tu portal:
   - **MESSAGE CONTENT INTENT** no es obligatorio para este flujo.
   - **SERVER MEMBERS INTENT** no es obligatorio para esta implementación actual.

## Paso 2: invitar el bot a tu servidor

Invita el bot a tu servidor con permisos suficientes para:

- ver canales,
- crear canales,
- enviar mensajes,
- leer historial,
- gestionar canales.

Si quieres construir la URL manualmente, necesitas el **Client ID** de la aplicación y permisos de bot adecuados.

Permisos recomendados para el bot:

- View Channels
- Send Messages
- Read Message History
- Manage Channels

## Paso 3: crear la categoría donde caerán los tickets

En tu servidor de Discord:

1. Crea una categoría, por ejemplo:
   - `Tickets Web`
2. Dentro de esa categoría **no hace falta** crear los tickets manualmente.
3. El bot creará un canal nuevo por cada compra.

Guarda el **ID de la categoría**.
Ese valor será `DISCORD_WEB_CATEGORY_ID`.

## Paso 4: definir qué admins verán los tickets

1. Decide qué usuarios concretos de Discord verán los tickets privados.
2. Copia el **ID de usuario** de cada admin.
3. Guarda esos IDs separados por coma en el secret `DISCORD_WEB_ADMIN_IDS`.

Ejemplo:

```
123456789012345678,234567890123456789
```

## Paso 5: crear un canal de logs opcional

Crea un canal donde quieras que el bot publique aviso de nuevos tickets, por ejemplo:

- `logs-web`

Guarda el **ID del canal**.
Ese valor será `DISCORD_WEB_LOG_CHANNEL_ID`.

> Si no quieres logs separados, puedes usar otro canal privado solo para admins.

## Paso 6: obtener los IDs que te pide el sistema

Necesitas estos IDs:

- **Guild ID** → `DISCORD_GUILD_ID`
- **Category ID** → `DISCORD_WEB_CATEGORY_ID`
- **Admin User IDs** → `DISCORD_WEB_ADMIN_IDS` (lista separada por comas)
- **Log Channel ID** → `DISCORD_WEB_LOG_CHANNEL_ID`

Para obtenerlos:

1. En Discord abre **Configuración avanzada**.
2. Activa **Modo desarrollador**.
3. Haz clic derecho sobre servidor / categoría / usuario admin / canal.
4. Usa **Copiar ID**.

## Paso 7: configurar los secrets en Supabase

Para tickets privados con bot propio, configura estos secrets:

```bash
supabase secrets set DISCORD_TICKET_MODE=bot
supabase secrets set DISCORD_BOT_TOKEN="TU_BOT_TOKEN"
supabase secrets set DISCORD_GUILD_ID="TU_GUILD_ID"
supabase secrets set DISCORD_WEB_CATEGORY_ID="TU_CATEGORY_ID"
supabase secrets set DISCORD_WEB_LOG_CHANNEL_ID="TU_LOG_CHANNEL_ID"
supabase secrets set DISCORD_WEB_ADMIN_IDS="ID_ADMIN_1,ID_ADMIN_2"
supabase secrets set DISCORD_TICKET_PREFIX="Ticket Oro"
```

## Paso 8: desplegar la function

```bash
supabase functions deploy create-gold-ticket
```

Si también usarás tickets para cuentas y servicios, despliega esas functions aparte:

```bash
supabase functions deploy create-account-ticket
supabase functions deploy create-service-ticket
```

## Paso 9: verificar que NO estás usando webhook

Para tickets privados por usuario, **no** debes depender del modo webhook.

La function `create-gold-ticket` usa dos caminos:

- `webhook` → crea publicación/hilo, pero **no agrega automáticamente al comprador** al ticket privado.
- `bot` → crea un canal privado y le da permisos a los admins configurados y al usuario de Discord indicado.

Para tu caso, el valor correcto es:

```bash
DISCORD_TICKET_MODE=bot
```

## Paso 10: qué debe hacer el usuario en la web

Cuando el usuario pulse **Comprar**:

1. Selecciona juego.
2. Selecciona servidor.
3. Selecciona cantidad.
4. Completa facción, personaje y tipo de trade.
5. En el campo de Discord pega una de estas opciones:
   - su ID,
   - su mención,
   - o su link de perfil.
6. Pulsa **Crear ticket**.

La web enviará `discord_user_id` a la function y la function extraerá el ID real del usuario.

## Paso 11: qué crea exactamente el bot en Discord

Cuando llega el pedido:

1. El bot crea un canal nuevo dentro de la categoría configurada.
2. El canal queda oculto para `@everyone`.
3. El canal queda visible para:
   - tus usuarios admin configurados,
   - y el usuario de Discord del comprador.
4. El bot publica el embed con:
   - juego,
   - servidor,
   - cantidad,
   - precio,
   - facción,
   - trade,
   - personaje,
   - usuario de Discord.
5. Opcionalmente avisa en el canal de logs.

## Paso 12: prueba completa real

Haz esta prueba de punta a punta:

1. Usa una cuenta real de Discord de prueba.
2. Asegúrate de que esa cuenta esté dentro de tu servidor.
   - Esto es clave: si el usuario no está en tu servidor, Discord no podrá mostrarle el canal privado.
3. Desde la web, crea un pedido de oro.
4. En el campo de Discord pega la mención o link de ese usuario.
5. Envía el ticket.
6. Verifica que:
   - los admins configurados vean el canal,
   - el usuario de prueba vea el canal,
   - otro usuario normal del servidor **no** lo vea.

## Problemas comunes

### 1. El ticket se crea pero el comprador no lo ve
Revisa:

- que `DISCORD_TICKET_MODE=bot`,
- que el usuario sí esté dentro de tu servidor,
- que el bot tenga permisos para crear canales,
- que el ID copiado pertenezca al usuario correcto,
- que los IDs puestos en `DISCORD_WEB_ADMIN_IDS` sean los correctos,
- que el bot tenga permisos suficientes.

### 2. El sistema abre Discord pero no muestra el canal
Puede pasar si:

- el usuario no tiene acceso al canal,
- el usuario no pertenece al servidor,
- el bot no pudo aplicar bien el overwrite,
- el ticket fue creado en otro servidor distinto al esperado.

### 3. El usuario escribe solo su `@usuario`
Eso no garantiza permisos privados.
El sistema necesita resolver un **user ID real**.
Por eso el formulario ahora acepta mejor:

- ID,
- mención,
- o link de perfil.

## Checklist final

- [ ] Bot creado en Discord Developer Portal.
- [ ] Bot invitado a tu servidor.
- [ ] Categoría privada para tickets creada.
- [ ] IDs de los admins copiados.
- [ ] Canal de logs creado.
- [ ] IDs copiados con modo desarrollador.
- [ ] Secrets cargados en Supabase.
- [ ] `DISCORD_TICKET_MODE=bot` configurado.
- [ ] Function `create-gold-ticket` desplegada.
- [ ] Prueba real hecha con un usuario dentro del servidor.
- [ ] Confirmado que solo admins configurados + comprador ven el ticket.

## Recomendación práctica

Si quieres que esto sea todavía más fácil para tus compradores, el siguiente paso ideal sería integrar **Discord OAuth** para que el sistema detecte automáticamente quién es el usuario y ya no tenga que pegar ni mención ni link ni ID.
