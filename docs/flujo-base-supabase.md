# Flujo actual de la base (Supabase)

## 1. Tablas que usa la web
- `settings`: enlaces y datos de contacto.
- `gold_categories`: juegos/categorías visibles en la compra de oro.
- `game_servers`: servidores por juego.
- `gold`: paquetes de oro y su precio en USD.
- `accounts`: cuentas.
- `account_categories`: categorías de cuentas.
- `customer_references`: referencias/testimonios.
- `services`: servicios.
- `payment_methods`: métodos de pago visibles en la compra de oro.

## 2. Flujo público de carga
1. La web carga `settings`, `gold_categories`, `game_servers`, `gold`, `accounts`, `account_categories`, `customer_references`, `services` y `payment_methods` desde Supabase.
2. Si `gold_categories`, `game_servers` o `gold` fallan temporalmente, la web reutiliza la última caché válida guardada en el navegador.
3. El modal de compra de oro toma:
   - juegos desde `gold_categories`
   - servidores desde `game_servers`
   - cantidades/precios desde `gold`

## 3. Flujo admin para servidores
- Cuando agregas un servidor en admin, se guarda en `game_servers` y la web actualiza en vivo:
  - selects de categorías/servidores
  - modal de compra de oro
  - formularios admin de precios de oro
- Cuando eliminas un servidor, se refresca el mismo flujo sin necesidad de recargar.

## 4. Flujo admin para oro
- Al abrir “Nuevo Oro”, la cantidad base ahora queda en `100` por defecto.
- La intención es que cada registro nuevo arranque como paquete base de **100g** con su precio en **USD**.
- Desde ese paquete base puedes luego generar o cargar otros paquetes (200g, 300g, 500g, 1000g, etc.).

## 5. Regla recomendada para precios
- Guarda siempre el precio en dólares (`USD`).
- La UI ya normaliza valores tipo `2.5`, `2.50` o `$2.50` para mostrarlos correctamente como `$2.50`.
- Si quieres anclar un servidor, lo más limpio es crear primero su paquete base de `100g`.

## 6. Flujo recomendado para cargar un juego nuevo
1. Crear/editar la categoría en `gold_categories`.
2. Crear los servidores en `game_servers`.
3. Crear al menos un paquete base de `100g` en `gold` por cada servidor.
4. Si quieres, usar `supabase/generar_paquetes_oro.sql` para sacar más paquetes a partir del de 100g.

## 7. SQL útil relacionado
- `supabase/schema.sql`
- `supabase/TABLAS_SUPABASE.sql`
- `supabase/PEGAR_EN_SUPABASE.sql`
- `supabase/generar_paquetes_oro.sql`
