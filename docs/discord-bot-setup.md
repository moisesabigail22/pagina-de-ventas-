# Configuración simple de Discord para pedidos web

## Recomendación
La forma más fácil es **NO usar bot**.

Usa un **webhook de Discord** para cada flujo que quieras separar en la web.

## Canales recomendados
Crea estos canales o foros en Discord:
- `tickets-oro`
- `tickets-cuentas`
- `tickets-servicios`

Si usas **Forum Channel**, cada pedido puede aparecer como publicación separada.
Si usas canales normales, llegarán como mensajes embed.

## Webhooks / secrets recomendados
### Oro
- Edge Function: `create-gold-ticket`
- Secret: `DISCORD_WEBHOOK_URL`
- Opcionales:
  - `DISCORD_TICKET_MODE=webhook`
  - `DISCORD_TICKET_PREFIX=Ticket Oro`

### Cuentas
- Edge Function: `create-account-ticket`
- Secret: `DISCORD_ACCOUNTS_WEBHOOK_URL`
- Opcional: `DISCORD_ACCOUNTS_TICKET_PREFIX=Ticket Cuenta`

### Servicios
- Edge Function: `create-service-ticket`
- Secret: `DISCORD_SERVICES_WEBHOOK_URL`
- Opcional: `DISCORD_SERVICES_TICKET_PREFIX=Ticket Servicio`

## Comandos sugeridos
```bash
supabase secrets set DISCORD_WEBHOOK_URL="tu_webhook_oro"
supabase secrets set DISCORD_TICKET_MODE=webhook
supabase secrets set DISCORD_TICKET_PREFIX="Ticket Oro"
supabase secrets set DISCORD_ACCOUNTS_WEBHOOK_URL="tu_webhook_cuentas"
supabase secrets set DISCORD_ACCOUNTS_TICKET_PREFIX="Ticket Cuenta"
supabase secrets set DISCORD_SERVICES_WEBHOOK_URL="tu_webhook_servicios"
supabase secrets set DISCORD_SERVICES_TICKET_PREFIX="Ticket Servicio"
```

## Deploy de las funciones
```bash
supabase functions deploy create-gold-ticket
supabase functions deploy create-account-ticket
supabase functions deploy create-service-ticket
```

## Qué hace cada flujo
### Oro
- La web construye el pedido y llama a `create-gold-ticket`.
- La función usa `DISCORD_WEBHOOK_URL` y publica el ticket en Discord.

### Cuentas
- La tarjeta de cuenta envía un ticket con la cuenta seleccionada.
- La función usa `DISCORD_ACCOUNTS_WEBHOOK_URL`.

### Servicios
- La tarjeta de servicio envía un ticket con el servicio seleccionado.
- La función usa `DISCORD_SERVICES_WEBHOOK_URL`.

## Checklist rápido
- [ ] Canal o foro para oro creado.
- [ ] Canal o foro para cuentas creado.
- [ ] Canal o foro para servicios creado.
- [ ] Webhook de oro creado.
- [ ] Webhook de cuentas creado.
- [ ] Webhook de servicios creado.
- [ ] Secrets cargados en Supabase.
- [ ] Functions desplegadas.
- [ ] Prueba real desde la web.
