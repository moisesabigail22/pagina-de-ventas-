-- Solo tablas (reinicio limpio)
-- Pega este archivo completo en Supabase SQL Editor.

create extension if not exists "pgcrypto";

create table if not exists public.settings (
  id uuid primary key default gen_random_uuid(),
  discord text,
  whatsapp text,
  tiktok text,
  email text,
  site text,
  updated_at timestamptz not null default now()
);

create table if not exists public.gold_categories (
  id uuid primary key default gen_random_uuid(),
  name text,
  game text not null,
  server text,
  description text,
  image text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.gold_categories
  add column if not exists name text;

create table if not exists public.game_servers (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.gold (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  server text not null,
  amount integer not null default 0,
  price numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.gold
  drop column if exists delivery,
  drop column if exists stock;

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  type text default 'account',
  category text,
  server text,
  name text not null,
  description text,
  price text,
  image text,
  tags jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.accounts
  add column if not exists image text;

create table if not exists public.account_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_references (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  comment text,
  rating integer check (rating between 1 and 5),
  image text,
  created_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  category text,
  game text,
  name text not null,
  description text,
  price numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
