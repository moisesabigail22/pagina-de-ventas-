#!/usr/bin/env python3
"""Convierte backup de localStorage de EpicGoldShop a SQL para Supabase."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def sql_quote(value: Any) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value).replace("'", "''")
    return f"'{text}'"


def parse_json_field(payload: dict[str, Any], key: str, default: Any) -> Any:
    raw = payload.get(key)
    if raw in (None, "", "null"):
        return default
    if isinstance(raw, (dict, list)):
        return raw
    try:
        return json.loads(raw)
    except Exception:
        return default


def normalize_references(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for r in rows:
        out.append(
            {
                "name": r.get("name") or r.get("userName") or "Cliente",
                "comment": r.get("comment") or r.get("text") or "",
                "rating": r.get("rating") if isinstance(r.get("rating"), int) else None,
                "image": r.get("image"),
            }
        )
    return out


def build_sql(payload: dict[str, Any]) -> str:
    settings = parse_json_field(payload, "epicgoldshop_settings", {})
    account_categories = parse_json_field(payload, "epicgoldshop_categories", [])
    gold_categories = parse_json_field(payload, "epicgoldshop_gold_categories", [])
    game_servers = parse_json_field(payload, "epicgoldshop_game_servers", [])
    gold = parse_json_field(payload, "epicgoldshop_gold", [])
    accounts = parse_json_field(payload, "epicgoldshop_accounts", [])
    references = normalize_references(parse_json_field(payload, "epicgoldshop_references", []))
    services = parse_json_field(payload, "epicgoldshop_services", [])

    lines: list[str] = []
    lines.append("begin;")
    lines.append("\n-- limpieza para restaurar exactamente el backup")
    lines.append("delete from public.gold;")
    lines.append("delete from public.gold_categories;")
    lines.append("delete from public.game_servers;")
    lines.append("delete from public.accounts;")
    lines.append("delete from public.account_categories;")
    lines.append("delete from public.customer_references;")
    lines.append("delete from public.settings;")
    if services:
        lines.append("delete from public.services;")

    lines.append("\n-- settings")
    lines.append(
        "insert into public.settings (discord, whatsapp, tiktok, email, site) values "
        f"({sql_quote(settings.get('discord'))}, {sql_quote(settings.get('whatsapp'))}, {sql_quote(settings.get('tiktok'))}, {sql_quote(settings.get('email'))}, {sql_quote(settings.get('site'))});"
    )

    if gold_categories:
        lines.append("\n-- gold_categories")
        values = []
        for r in gold_categories:
            values.append(
                f"({sql_quote(r.get('name') or r.get('game'))}, {sql_quote(r.get('game'))}, {sql_quote(r.get('server'))}, {sql_quote(r.get('description'))}, {sql_quote(r.get('image'))})"
            )
        lines.append(
            "insert into public.gold_categories (name, game, server, description, image) values\n  "
            + ",\n  ".join(values)
            + ";"
        )

    if game_servers:
        lines.append("\n-- game_servers")
        values = []
        for r in game_servers:
            values.append(f"({sql_quote(r.get('game'))}, {sql_quote(r.get('name'))})")
        lines.append(
            "insert into public.game_servers (game, name) values\n  "
            + ",\n  ".join(values)
            + ";"
        )

    if gold:
        lines.append("\n-- gold")
        values = []
        for r in gold:
            amount = r.get("amount")
            if isinstance(amount, str) and amount.isdigit():
                amount = int(amount)
            values.append(
                f"({sql_quote(r.get('game'))}, {sql_quote(r.get('server'))}, {sql_quote(amount)}, {sql_quote(r.get('price'))})"
            )
        lines.append(
            "insert into public.gold (game, server, amount, price) values\n  "
            + ",\n  ".join(values)
            + ";"
        )

    if services:
        lines.append("\n-- services")
        values = []
        for r in services:
            values.append(
                f"({sql_quote(r.get('category'))}, {sql_quote(r.get('game'))}, {sql_quote(r.get('name'))}, {sql_quote(r.get('description'))}, {sql_quote(r.get('price'))}, {sql_quote(r.get('image'))})"
            )
        lines.append(
            "insert into public.services (category, game, name, description, price, image) values\n  "
            + ",\n  ".join(values)
            + ";"
        )

    if accounts:
        lines.append("\n-- accounts")
        values = []
        for r in accounts:
            tags = r.get("tags")
            tags_json = json.dumps(tags if isinstance(tags, list) else [])
            values.append(
                f"({sql_quote(r.get('type'))}, {sql_quote(r.get('category'))}, {sql_quote(r.get('server'))}, {sql_quote(r.get('name'))}, {sql_quote(r.get('description'))}, {sql_quote(r.get('price'))}, {sql_quote(r.get('image'))}, {sql_quote(tags_json)}::jsonb)"
            )
        lines.append(
            "insert into public.accounts (type, category, server, name, description, price, image, tags) values\n  "
            + ",\n  ".join(values)
            + ";"
        )

    normalized_account_categories = []
    for row in account_categories:
        if isinstance(row, str):
            category_name = row.strip()
        elif isinstance(row, dict):
            category_name = str(row.get("name") or row.get("category") or "").strip()
        else:
            category_name = ""
        if category_name:
            normalized_account_categories.append(category_name)

    for row in accounts:
        category_name = str(row.get("category") or "").strip()
        if category_name:
            normalized_account_categories.append(category_name)

    normalized_account_categories = sorted(set(normalized_account_categories))

    if normalized_account_categories:
        lines.append("\n-- account_categories")
        values = [f"({sql_quote(category_name)})" for category_name in normalized_account_categories]
        lines.append(
            "insert into public.account_categories (name) values\n  "
            + ",\n  ".join(values)
            + "\non conflict (name) do nothing;"
        )

    if references:
        lines.append("\n-- customer_references")
        values = []
        for r in references:
            values.append(
                f"({sql_quote(r.get('name'))}, {sql_quote(r.get('comment'))}, {sql_quote(r.get('rating'))}, {sql_quote(r.get('image'))})"
            )
        lines.append(
            "insert into public.customer_references (name, comment, rating, image) values\n  "
            + ",\n  ".join(values)
            + ";"
        )

    lines.append("\ncommit;")
    lines.append(
        """

select 'settings' as table_name, count(*) as total from public.settings
union all select 'gold_categories', count(*) from public.gold_categories
union all select 'game_servers', count(*) from public.game_servers
union all select 'gold', count(*) from public.gold
union all select 'services', count(*) from public.services
union all select 'accounts', count(*) from public.accounts
union all select 'account_categories', count(*) from public.account_categories
union all select 'customer_references', count(*) from public.customer_references
order by table_name;
""".strip()
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Convierte backup localStorage de EpicGoldShop a SQL")
    parser.add_argument("backup_json", help="Ruta al JSON exportado de localStorage")
    parser.add_argument("--out", default="supabase/restore_from_localstorage.sql", help="Archivo SQL de salida")
    args = parser.parse_args()

    backup = json.loads(Path(args.backup_json).read_text(encoding="utf-8"))
    sql = build_sql(backup)
    out_path = Path(args.out)
    out_path.write_text(sql, encoding="utf-8")
    print(f"SQL generado: {out_path}")


if __name__ == "__main__":
    main()
