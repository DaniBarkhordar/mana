-- ============================================================================
-- Vision: cache, metering and entitlements.
--
-- The cache is the main cost control. Users photograph the same breakfast for
-- weeks; identical bytes must never be paid for twice. It holds no personal
-- data — only an image hash and a food name list — so it is shared across
-- users, which makes it far more effective than a per-user cache would be.
-- ============================================================================

create table public.vision_cache (
  cache_key   text primary key,
  result      jsonb not null,
  hits        integer not null default 0,
  created_at  timestamptz not null default now(),
  last_hit_at timestamptz
);

comment on table public.vision_cache is
  'Keyed on a hash of the downscaled image bytes. Contains no user identifier '
  'and no personal data, so it is deliberately shared across all users.';

-- Metering rows carry a user id, so they are personal data and get RLS.
create table public.vision_usage (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index vision_usage_user_day_idx on public.vision_usage (user_id, created_at desc);

create type entitlement_tier as enum ('free', 'plus');

create table public.entitlements (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  tier         entitlement_tier not null default 'free',
  -- Mirrored from RevenueCat webhooks. The app never decides its own tier.
  expires_at   timestamptz,
  source       text,
  updated_at   timestamptz not null default now()
);

alter table public.vision_usage  enable row level security;
alter table public.entitlements  enable row level security;
alter table public.vision_cache  enable row level security;

create policy "own usage" on public.vision_usage
  for select using (auth.uid() = user_id);

create policy "own entitlement" on public.entitlements
  for select using (auth.uid() = user_id);

-- The cache is readable by any signed-in user and written only by the edge
-- function's service role.
create policy "read cache" on public.vision_cache
  for select using (auth.role() = 'authenticated');

create or replace function public.bump_cache_hit(p_key text)
returns void language sql security definer set search_path = public as $$
  update public.vision_cache
     set hits = hits + 1, last_hit_at = now()
   where cache_key = p_key;
$$;
