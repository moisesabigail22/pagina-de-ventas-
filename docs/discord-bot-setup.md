# Configuración del bot de Discord para pedidos web

## 1. Qué ya deberías tener
- Un bot creado en <https://discord.com/developers/applications>.
- El bot invitado a tu servidor.
- Una categoría para tickets, por ejemplo `PEDIDOS WEB`.
- Un canal privado de log, por ejemplo `#web-orders-log`.
- Un rol de staff, por ejemplo `Soporte`.

## 2. Permisos que debe tener el bot
En el servidor, el bot debe tener como mínimo:
- Ver canales.
- Enviar mensajes.
- Leer historial de mensajes.
- Gestionar canales.
- Gestionar roles **no es obligatorio** para este flujo.
- Gestionar hilos **no es obligatorio** si usas modo `channel`.

## 3. IDs que tienes que copiar
Con `Developer Mode` activado en Discord, copia estos IDs:

1. `GUILD_ID`: clic derecho en el servidor → `Copiar ID`.
2. `CATEGORY_ID`: clic derecho en la categoría `PEDIDOS WEB` → `Copiar ID`.
3. `LOG_CHANNEL_ID`: clic derecho en `#web-orders-log` → `Copiar ID`.
4. `SUPPORT_ROLE_ID`: ajustes del servidor → roles → clic derecho sobre el rol de soporte → `Copiar ID`.

## 4. Secretos de Supabase que debes cargar
Configura estos secretos para la edge function `create-gold-ticket`:

- `DISCORD_BOT_TOKEN`
- `DISCORD_GUILD_ID`
- `DISCORD_WEB_CATEGORY_ID`
- `DISCORD_WEB_LOG_CHANNEL_ID`
- `DISCORD_WEB_SUPPORT_ROLE_ID`
- `DISCORD_TICKET_MODE=channel`
- `DISCORD_TICKET_PREFIX=ticket-oro` (opcional)

### Comandos sugeridos
```bash
supabase secrets set DISCORD_BOT_TOKEN=tu_token
supabase secrets set DISCORD_GUILD_ID=tu_guild_id
supabase secrets set DISCORD_WEB_CATEGORY_ID=tu_category_id
supabase secrets set DISCORD_WEB_LOG_CHANNEL_ID=tu_log_channel_id
supabase secrets set DISCORD_WEB_SUPPORT_ROLE_ID=tu_support_role_id
supabase secrets set DISCORD_TICKET_MODE=channel
supabase secrets set DISCORD_TICKET_PREFIX=ticket-oro
```

## 5. Deploy de la función
Después de cargar los secretos, despliega o vuelve a desplegar la función:

```bash
supabase functions deploy create-gold-ticket
```

## 6. Cómo funciona después de configurarlo
Cuando un cliente envía el formulario de oro:
1. La web llama a `create-gold-ticket`.
2. La función crea un canal privado dentro de `PEDIDOS WEB`.
3. El bot publica el embed con los datos del pedido.
4. El bot deja un aviso en `#web-orders-log`.
5. La web abre Discord con la URL del ticket creado.

## 7. Checklist rápido
- [ ] El bot está dentro del servidor.
- [ ] El bot puede ver la categoría de tickets.
- [ ] El bot puede crear canales.
- [ ] El rol de soporte existe.
- [ ] Copiaste los 4 IDs.
- [ ] Cargaste todos los secretos en Supabase.
- [ ] Redeployaste la función.
- [ ] Probaste un pedido desde la web.

## 8. Si falla
Revisa en este orden:
1. Token del bot incorrecto o vencido.
2. `GUILD_ID`, `CATEGORY_ID`, `LOG_CHANNEL_ID` o `SUPPORT_ROLE_ID` mal copiados.
3. El bot no tiene permiso `Manage Channels`.
4. La categoría no permite que el bot cree canales debajo de ella.
5. La función no fue redeployada después de cambiar secretos.

## 9. Modo alternativo heredado
La función todavía soporta `DISCORD_TICKET_MODE=webhook` para compatibilidad, pero el flujo recomendado es `channel` con bot propio.
