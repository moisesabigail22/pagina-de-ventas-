# Configuración simple de Discord para pedidos web

## Recomendación
La forma más fácil es **NO usar bot**.

Usa un **webhook de Discord** apuntando a un canal donde quieras recibir los pedidos de la web.
Eso evita crear aplicación, bot token, roles especiales o permisos de `Manage Channels`.

## Opción simple recomendada: webhook

### 1. Crea o usa un canal en Discord
Puede ser, por ejemplo:
- `#pedidos-web`
- `#tickets-web`
- `#gold-orders`

Si quieres que cada pedido salga como publicación separada, puedes usar un **Forum Channel**.
Si usas un canal normal de texto, los pedidos llegarán como mensajes embebidos dentro de ese canal.

### 2. Crea el webhook del canal
En Discord:
1. Entra al canal.
2. `Editar canal`.
3. `Integrations` o `Integraciones`.
4. `Webhooks`.
5. `New Webhook`.
6. Copia la URL del webhook.

La URL se verá parecida a esta:
```text
https://discord.com/api/webhooks/1234567890/abcdefghijklmnopqrstuvwxyz
```

## 3. Secreto que debes cargar en Supabase
Para este flujo simple solo necesitas esto:

- `DISCORD_WEBHOOK_URL`

Opcionales:
- `DISCORD_TICKET_MODE=webhook`
- `DISCORD_TICKET_PREFIX=Ticket Oro`

### Comandos sugeridos
```bash
supabase secrets set DISCORD_WEBHOOK_URL="tu_webhook_url"
supabase secrets set DISCORD_TICKET_MODE=webhook
supabase secrets set DISCORD_TICKET_PREFIX="Ticket Oro"
```

## 4. Deploy de la función
Después de guardar el secreto, despliega o vuelve a desplegar la función:

```bash
supabase functions deploy create-gold-ticket
```

## 5. Cómo funciona después de configurarlo
Cuando un cliente envía el formulario de oro:
1. La web llama a `create-gold-ticket`.
2. La función manda el pedido al webhook de Discord.
3. Si el webhook apunta a un **forum channel**, Discord puede crear una publicación nueva con `thread_name`.
4. Si el webhook apunta a un canal normal, Discord publica el pedido como mensaje embed.
5. La web abre tu enlace general de Discord como fallback.

## 6. Qué tienes que hacer tú ahora
Checklist rápido:
- [ ] Crear o elegir el canal donde van a caer los pedidos.
- [ ] Crear el webhook de ese canal.
- [ ] Copiar la URL del webhook.
- [ ] Guardarla en Supabase como `DISCORD_WEBHOOK_URL`.
- [ ] Hacer deploy de `create-gold-ticket`.
- [ ] Probar un pedido desde la web.

## 7. Si falla
Revisa en este orden:
1. La URL del webhook está mal copiada.
2. El webhook fue borrado o regenerado en Discord.
3. La función no fue redeployada después de cambiar secretos.
4. El canal no acepta el tipo de publicación que esperas.

## 8. Opción avanzada
La función todavía soporta modo bot/canales privados como opción avanzada con `DISCORD_TICKET_MODE=channel`, pero **no hace falta usarlo** para que esto funcione.
