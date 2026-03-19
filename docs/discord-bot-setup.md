# Configuración de bot propio para tickets privados desde la web

Esta guía es para el caso en que quieres que:

- el usuario entre a tu web,
- presione **Comprar**,
- complete el formulario,
- y se cree un **ticket privado en Discord**
- visible **solo para tus usuarios admin y para ese comprador**.

> **Importante:** este flujo ahora quedó **solo con bot propio**. Ya no dependas de webhook para oro. La function `create-gold-ticket` crea el canal privado usando tu bot y los `permission_overwrites` para admins configurados + comprador.

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

Dónde pegas esos comandos:

1. Abre una terminal en tu PC o servidor donde tengas instalado **Supabase CLI**.
2. Ve a la carpeta de este proyecto.
3. Si todavía no has vinculado el proyecto, ejecuta `supabase link --project-ref TU_PROJECT_REF`.
4. Luego pega ahí mismo los comandos `supabase secrets set ...`.

Si prefieres no usar terminal, también puedes poner esos mismos secrets desde el panel de Supabase en:

**Project Settings → Edge Functions / Secrets**.

Para tickets privados con bot propio, configura estos secrets:

```bash
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

> Si cambiaste el código local pero **no** ejecutaste `supabase functions deploy create-gold-ticket`, Supabase seguirá usando la versión vieja de la function. Ese es el motivo más común cuando parece que “todavía usa webhook” aunque ya hayas cambiado los secrets.

## Paso 9: desactivar webhook y dejar solo tu bot

Para oro, la function ya quedó preparada para trabajar **solo con tu bot**.

Entonces:

- no necesitas `DISCORD_WEBHOOK_URL`,
- no necesitas `DISCORD_TICKET_MODE`,
- y no necesitas configurar nada de webhook para este flujo.

Con que cargues los secrets del bot y despliegues la function, el flujo de oro ya usará únicamente tu bot.

## Paso 10: qué debe hacer el usuario en la web

Cuando el usuario pulse **Comprar**:

1. Selecciona juego.
2. Selecciona servidor.
3. Selecciona cantidad.
4. Completa facción, personaje y tipo de trade.
5. Selecciona un **método de pago** de los que configuraste en el panel admin.
6. Pulsa **Crear ticket**.

La web enviará el método de pago elegido al ticket para que el admin vea cómo continuar el cobro.

## Paso 11: qué crea exactamente el bot en Discord

Cuando llega el pedido:

1. El bot crea un canal nuevo dentro de la categoría configurada.
2. El canal queda oculto para `@everyone`.
3. El canal queda visible para:
   - tus usuarios admin configurados.
4. El bot publica el embed con:
   - juego,
   - servidor,
   - cantidad,
   - precio,
   - facción,
   - trade,
   - personaje,
   - método de pago,
   - y dato del método de pago.
5. Opcionalmente avisa en el canal de logs.

## Paso 12: prueba completa real

Haz esta prueba de punta a punta:

1. Desde la web, crea un pedido de oro.
2. Selecciona un método de pago válido.
3. Envía el ticket.
4. Verifica que:
   - los admins configurados vean el canal,
   - el ticket traiga el método de pago correcto,
   - y que otro usuario normal del servidor **no** lo vea.

## Paso 13: si todavía “parece webhook” aunque ya pusiste el bot

Si ya configuraste los secrets del bot y aún ves el comportamiento viejo, revisa esto en este orden:

1. **Redespliega la function**:

   ```bash
   supabase functions deploy create-gold-ticket
   ```

2. **Confirma que estás editando el proyecto correcto**:

   ```bash
   supabase link --project-ref TU_PROJECT_REF
   supabase functions list
   ```

3. **Vuelve a guardar los secrets** del bot por si quedaron en otro proyecto o ambiente.
4. **No dependas de `DISCORD_TICKET_MODE`** para oro: el código actual ya no usa ese switch.
5. **No pongas `DISCORD_WEBHOOK_URL`** para este flujo: ya no hace falta en oro.
6. Si el ticket sigue viéndose “viejo”, casi seguro Supabase sigue ejecutando una versión anterior de `create-gold-ticket`.

## Seguridad importante

Si alguna vez pegas tu `DISCORD_BOT_TOKEN` en un chat, captura o lugar público, debes **rotarlo inmediatamente** en Discord Developer Portal y luego actualizarlo en Supabase. Un token expuesto permite controlar tu bot.

## Problemas comunes

### 1. El ticket no aparece en Discord
Revisa:

- que `create-gold-ticket` esté desplegada,
- que `DISCORD_BOT_TOKEN`, `DISCORD_GUILD_ID`, `DISCORD_WEB_CATEGORY_ID` y `DISCORD_WEB_ADMIN_IDS` estén bien cargados,
- que el bot siga dentro del servidor,
- y que el bot tenga permisos para crear canales y enviar mensajes.

### 2. El ticket se crea pero no lo ven los admins
Revisa:

- que los IDs puestos en `DISCORD_WEB_ADMIN_IDS` sean los correctos,
- que esos usuarios pertenezcan a tu servidor,
- y que el bot haya podido aplicar los overwrites al canal.

### 3. El método de pago no sale en el ticket
Revisa:

- que ya agregaste métodos de pago desde el panel admin,
- que el usuario seleccionó uno antes de enviar,
- y que aplicaste la tabla `payment_methods` en Supabase.

## Checklist final

- [ ] Bot creado en Discord Developer Portal.
- [ ] Bot invitado a tu servidor.
- [ ] Categoría privada para tickets creada.
- [ ] IDs de los admins copiados.
- [ ] Canal de logs creado.
- [ ] IDs copiados con modo desarrollador.
- [ ] Secrets cargados en Supabase.
- [ ] Function `create-gold-ticket` desplegada.
- [ ] Métodos de pago cargados desde el panel admin.
- [ ] Prueba real hecha seleccionando un método de pago.
- [ ] Confirmado que solo admins configurados ven el ticket.
