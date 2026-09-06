-- ============================================================================
-- Observations, and the columns the offline sync needs.
--
-- Two things happen here.
--
-- 1. The observations table. Every raw measurement — a scale reading today, a
--    night's HRV or a ferritin result later — is one row with a kind, a value,
--    a unit, a source and a reference range. A cut-down FHIR Observation. New
--    sources are new `source` values, never new tables. body_measurements
--    keeps the *derived* composition figures and their provenance.
--
-- 2. Sync columns. The app is local-first: rows are created in SQLite with a
--    client-generated uuid and pushed later. Last-write-wins needs updated_at
--    on every synced table, and a deletion made offline needs a tombstone
--    (deleted_at) to reach the other devices, so those are added wherever
--    0001 did not already have them. Tombstones are for sync, not retention:
--    account deletion still cascades and removes every row for real.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Observations
-- ---------------------------------------------------------------------------

create table public.observations (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  taken_at         timestamptz not null,
  -- 'weight_kg', 'impedance_ohm', 'body_fat_pct', 'resting_hr_bpm',
  -- 'hrv_rmssd_ms', 'sleep_min', 'steps', 'vitamin_d_25oh_nmol_l', ...
  kind             text not null,
  value            numeric not null,
  unit             text not null,
  -- 'mananu_body_scale', 'mananu_kitchen_scale', 'simulated_scale',
  -- 'apple_health', 'health_connect', 'oura', 'whoop', 'garmin',
  -- 'partner_lab:<name>'
  source           text not null,
  device_id        uuid references public.devices(id) on delete set null,
  -- For derived values, the equation that produced them, e.g. 'sun2003'.
  method           text,
  confidence       text,
  -- For lab and clinical values. Shown beside the value, always — see
  -- CLAUDE.md rule 8.
  reference_low    numeric,
  reference_high   numeric,
  reference_source text,
  -- The source payload, never discarded.
  raw              jsonb,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz
);

create index observations_user_kind_time_idx
  on public.observations (user_id, kind, taken_at desc);

comment on table public.observations is
  'One row per raw measurement from any source. Scale, wearable and lab data '
  'share this shape; a new source is a new adapter, never a new table.';

alter table public.observations enable row level security;

create policy "own observations" on public.observations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create trigger observations_touch before update on public.observations
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Sync columns on the tables 0001 created
-- ---------------------------------------------------------------------------

alter table public.body_measurements
  add column updated_at timestamptz not null default now(),
  add column deleted_at timestamptz,
  -- What the user was told about this reading, verbatim, so history shows
  -- what history showed.
  add column notes      jsonb not null default '[]'::jsonb;

create trigger body_measurements_touch before update on public.body_measurements
  for each row execute function public.touch_updated_at();

alter table public.meals
  add column updated_at timestamptz not null default now(),
  add column deleted_at timestamptz;

create trigger meals_touch before update on public.meals
  for each row execute function public.touch_updated_at();

alter table public.meal_components
  add column updated_at  timestamptz not null default now(),
  add column deleted_at  timestamptz,
  -- Denormalised with food_name for the same reason: the identification
  -- error term depends on whether the per-100 g figures came from a reference
  -- dataset or a model's guess, and a deleted catalogue row must not change
  -- the answer.
  add column food_source food_source,
  add column sugar_g     numeric(7,2),
  add column saturates_g numeric(7,2),
  add column fibre_g     numeric(7,2),
  add column salt_g      numeric(7,2);

create trigger meal_components_touch before update on public.meal_components
  for each row execute function public.touch_updated_at();

alter table public.foods
  add column updated_at timestamptz not null default now(),
  add column deleted_at timestamptz;

create trigger foods_touch before update on public.foods
  for each row execute function public.touch_updated_at();

alter table public.recipes
  add column deleted_at timestamptz;

-- daily_targets: a uuid primary key like every other synced table, with the
-- (user, day) pair kept unique.
alter table public.daily_targets
  add column id         uuid not null default gen_random_uuid(),
  add column updated_at timestamptz not null default now(),
  add column deleted_at timestamptz;

alter table public.daily_targets drop constraint daily_targets_pkey;
alter table public.daily_targets add primary key (id);
alter table public.daily_targets add unique (user_id, effective_from);

create trigger daily_targets_touch before update on public.daily_targets
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Trend helper: read raw weights from observations too
-- ---------------------------------------------------------------------------

-- Same shape as body_fat_trend, over the general store, for any kind. This is
-- the query a ferritin chart will run unchanged.
create or replace function public.observation_daily_median(
  p_kind text,
  p_from timestamptz default now() - interval '90 days'
)
returns table (day date, median_value numeric)
language sql
stable
security invoker
as $$
  select date_trunc('day', taken_at)::date as day,
         percentile_cont(0.5) within group (order by value)
  from public.observations
  where user_id = auth.uid()
    and kind = p_kind
    and deleted_at is null
    and taken_at >= p_from
  group by 1
  order by 1;
$$;
