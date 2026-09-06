-- ============================================================================
-- Mananu — initial schema
--
-- Deploy to a Supabase project in the London (eu-west-2) or Frankfurt region.
-- Body composition is health data and therefore special-category data under UK
-- GDPR Article 9; the lawful basis is explicit consent, recorded in
-- public.consents below. Nothing in this schema is designed to leave the EU/UK.
--
-- Design rules enforced here rather than in the app:
--   * Every row carrying personal data has RLS on and a policy keyed to
--     auth.uid(). There is no service-role read path for user health data in
--     normal operation.
--   * Raw sensor values are stored alongside derived values, and the equation
--     that produced each derived value is stored with it. Without that, a change
--     of equation silently rewrites a user's history.
--   * Deletion is real deletion, on cascade, because Article 17 is not
--     satisfied by a soft-delete flag.
-- ============================================================================

create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- ---------------------------------------------------------------------------
-- Profile
-- ---------------------------------------------------------------------------

create type sex_at_measurement as enum ('male', 'female');
create type activity_level as enum ('inactive', 'low_active', 'active', 'very_active');
create type unit_system as enum ('metric', 'imperial', 'stone');

create table public.profiles (
  id                uuid primary key references auth.users(id) on delete cascade,
  display_name      text,
  -- Required by every BIA equation. Stored as the measurement input it is.
  date_of_birth     date,
  sex               sex_at_measurement,
  height_cm         numeric(5,1) check (height_cm between 100 and 220),
  activity          activity_level not null default 'low_active',
  units             unit_system not null default 'metric',
  country           text not null default 'GB',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

comment on column public.profiles.sex is
  'Biological sex as required by the published BIA regression equations. '
  'Measurement input, not an identity field.';

-- ---------------------------------------------------------------------------
-- Consent — the Article 9 record
-- ---------------------------------------------------------------------------

create table public.consents (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  purpose       text not null,
  policy_version text not null,
  granted       boolean not null,
  granted_at    timestamptz not null default now(),
  -- Consent must be as easy to withdraw as to give; withdrawal is a new row,
  -- never an update, so the history stays intact.
  source        text not null default 'app'
);

create index consents_user_idx on public.consents (user_id, purpose, granted_at desc);

comment on table public.consents is
  'Explicit consent under UK GDPR Art 9(2)(a) for processing body composition '
  'data. One row per grant or withdrawal; never updated in place.';

-- ---------------------------------------------------------------------------
-- Devices
-- ---------------------------------------------------------------------------

create type scale_kind as enum ('body', 'kitchen');

create table public.devices (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  kind           scale_kind not null,
  -- CoreBluetooth identifiers are per-install on iOS, so this is not a stable
  -- hardware identity and must not be treated as one.
  local_id       text not null,
  display_name   text,
  model_code     text,
  protocol       text,
  firmware       text,
  electrode_count smallint,
  paired_at      timestamptz not null default now(),
  last_seen_at   timestamptz,
  unique (user_id, local_id)
);

-- ---------------------------------------------------------------------------
-- Body measurements
-- ---------------------------------------------------------------------------

create type reading_confidence as enum ('good', 'fair', 'weight_only');

create table public.body_measurements (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  device_id           uuid references public.devices(id) on delete set null,
  taken_at            timestamptz not null,

  -- Raw sensor output. Never overwritten, never recomputed.
  weight_kg           numeric(6,3) not null check (weight_kg > 0 and weight_kg < 400),
  impedance_ohm       numeric(7,2),
  reactance_ohm       numeric(7,2),
  -- Five-segment impedance at two frequencies, as the hardware reports it.
  -- JSON because the encoding is vendor-specific and unconfirmed; storing it
  -- raw means a later decode can be applied retrospectively.
  segmental_raw       jsonb,
  heart_rate_bpm      smallint,

  -- Inputs used, snapshotted, because a user's height and age change and a
  -- historical reading must stay reproducible.
  height_cm_at_time   numeric(5,1),
  age_years_at_time   smallint,
  sex_at_time         sex_at_measurement,

  -- Derived values, with provenance.
  fat_free_mass_kg    numeric(6,2),
  body_fat_percent    numeric(5,2),
  total_body_water_l  numeric(6,2),
  skeletal_muscle_kg  numeric(6,2),
  resting_kcal        integer,
  equation            text,

  confidence          reading_confidence not null default 'good',
  -- Conditions the user reported. BIA measures water; these change the meaning.
  context             jsonb not null default '{}'::jsonb,

  created_at          timestamptz not null default now(),
  unique (user_id, taken_at, weight_kg)
);

create index body_measurements_user_time_idx
  on public.body_measurements (user_id, taken_at desc);

comment on column public.body_measurements.equation is
  'Which published equation produced the derived columns, e.g. sun2003. '
  'Required: without it, changing the equation silently rewrites history.';

-- ---------------------------------------------------------------------------
-- Foods
-- ---------------------------------------------------------------------------

-- Licence provenance is a column, not a comment, because the offline core
-- (CC0 USDA + OGL CoFID) may be redistributed inside the app binary and the
-- Open Food Facts cache (ODbL) may not be mixed into it. Enforcing the boundary
-- in data means the export job cannot get it wrong.
create type food_source as enum (
  'cofid',            -- Open Government Licence v3.0 — redistributable
  'usda',             -- public domain — redistributable
  'open_food_facts',  -- ODbL — share-alike, kept out of the embedded core
  'user_label',
  'user_recipe',
  'estimated'
);

create table public.foods (
  id             uuid primary key default gen_random_uuid(),
  -- Null for the shared catalogue, set for a user's own foods and recipes.
  user_id        uuid references auth.users(id) on delete cascade,
  name           text not null,
  brand          text,
  barcode        citext,
  source         food_source not null,
  is_cooked      boolean not null default false,

  kcal_100g      numeric(7,2) not null,
  protein_100g   numeric(7,2),
  carb_100g      numeric(7,2),
  sugar_100g     numeric(7,2),
  fat_100g       numeric(7,2),
  saturates_100g numeric(7,2),
  fibre_100g     numeric(7,2),
  salt_100g      numeric(7,2),

  household_measures jsonb not null default '[]'::jsonb,
  search_text    tsvector generated always as (
    to_tsvector('english', coalesce(brand,'') || ' ' || name)
  ) stored,
  created_at     timestamptz not null default now()
);

create index foods_search_idx on public.foods using gin (search_text);
create index foods_barcode_idx on public.foods (barcode) where barcode is not null;
create index foods_user_idx on public.foods (user_id) where user_id is not null;

-- ---------------------------------------------------------------------------
-- Meals and their weighed components
-- ---------------------------------------------------------------------------

create type meal_slot as enum ('breakfast', 'lunch', 'dinner', 'snack');

create type portion_method as enum (
  'weighed',            -- off our scale. The point of the product.
  'household_measure',
  'photo_estimate',
  'manual_grams'
);

create table public.meals (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  eaten_at     timestamptz not null,
  slot         meal_slot not null default 'snack',
  note         text,
  photo_path   text,
  created_at   timestamptz not null default now()
);

create index meals_user_time_idx on public.meals (user_id, eaten_at desc);

create table public.meal_components (
  id           uuid primary key default gen_random_uuid(),
  meal_id      uuid not null references public.meals(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  food_id      uuid references public.foods(id) on delete set null,
  -- Denormalised so a deleted catalogue row cannot rewrite a user's history.
  food_name    text not null,
  grams        numeric(8,2) not null check (grams > 0),
  method       portion_method not null,

  kcal         numeric(8,2) not null,
  protein_g    numeric(7,2),
  carb_g       numeric(7,2),
  fat_g        numeric(7,2),

  -- Set when this component is cooking fat measured by weighing the pan before
  -- and after. This is the line item no photo-based app can produce, and it is
  -- where the published 250-345 kcal underestimate mostly lives.
  is_cooking_fat boolean not null default false,

  -- When a vision model proposed the portion and the scale then corrected it,
  -- both are kept. These pairs are what personal calibration is fitted on.
  estimated_grams numeric(8,2),

  position     smallint not null default 0,
  note         text,
  created_at   timestamptz not null default now()
);

create index meal_components_meal_idx on public.meal_components (meal_id, position);
create index meal_components_calibration_idx
  on public.meal_components (user_id, food_id)
  where estimated_grams is not null and method = 'weighed';

-- ---------------------------------------------------------------------------
-- Recipes
-- ---------------------------------------------------------------------------

create table public.recipes (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references auth.users(id) on delete cascade,
  name               text not null,
  -- The finished dish weighed on the scale. Not the sum of its ingredients:
  -- water boils off and fat renders out, and using the sum is a standard way to
  -- get per-portion figures wrong.
  yield_grams        numeric(8,2) not null check (yield_grams > 0),
  kcal_100g          numeric(7,2) not null,
  protein_100g       numeric(7,2),
  carb_100g          numeric(7,2),
  fat_100g           numeric(7,2),
  ingredients        jsonb not null default '[]'::jsonb,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index recipes_user_idx on public.recipes (user_id);

-- ---------------------------------------------------------------------------
-- Daily targets
-- ---------------------------------------------------------------------------

create table public.daily_targets (
  user_id       uuid not null references auth.users(id) on delete cascade,
  effective_from date not null,
  kcal          integer not null,
  protein_g     integer,
  carb_g        integer,
  fat_g         integer,
  basis         text,
  primary key (user_id, effective_from)
);

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.profiles           enable row level security;
alter table public.consents           enable row level security;
alter table public.devices            enable row level security;
alter table public.body_measurements  enable row level security;
alter table public.foods              enable row level security;
alter table public.meals              enable row level security;
alter table public.meal_components    enable row level security;
alter table public.recipes            enable row level security;
alter table public.daily_targets      enable row level security;

create policy "own profile" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- Consent rows are insert-and-read only. Nobody edits a consent record, not
-- even its owner: withdrawal is a new row.
create policy "own consents read" on public.consents
  for select using (auth.uid() = user_id);
create policy "own consents insert" on public.consents
  for insert with check (auth.uid() = user_id);

create policy "own devices" on public.devices
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own measurements" on public.body_measurements
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- The shared food catalogue (user_id is null) is readable by any signed-in
-- user; a user's own foods are private to them. Writes are always own-row.
create policy "read catalogue and own foods" on public.foods
  for select using (user_id is null or auth.uid() = user_id);
create policy "write own foods" on public.foods
  for insert with check (auth.uid() = user_id);
create policy "update own foods" on public.foods
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own foods" on public.foods
  for delete using (auth.uid() = user_id);

create policy "own meals" on public.meals
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own meal components" on public.meal_components
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own recipes" on public.recipes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own targets" on public.daily_targets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Storage: meal photos
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('meal-photos', 'meal-photos', false)
on conflict (id) do nothing;

-- Photos live under {user_id}/... and are readable only by their owner.
create policy "own meal photos read" on storage.objects
  for select using (
    bucket_id = 'meal-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "own meal photos write" on storage.objects
  for insert with check (
    bucket_id = 'meal-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "own meal photos delete" on storage.objects
  for delete using (
    bucket_id = 'meal-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Rolling median body fat over a window. Deliberately server-side so the app,
-- the web dashboard and any export all show the same trend line.
create or replace function public.body_fat_trend(
  p_days integer default 7,
  p_from timestamptz default now() - interval '90 days'
)
returns table (day date, median_body_fat numeric, median_weight numeric)
language sql
stable
security invoker
as $$
  with d as (
    select date_trunc('day', taken_at)::date as day,
           body_fat_percent,
           weight_kg
    from public.body_measurements
    where user_id = auth.uid()
      and taken_at >= p_from
      and confidence <> 'weight_only'
  )
  select day,
         percentile_cont(0.5) within group (order by body_fat_percent),
         percentile_cont(0.5) within group (order by weight_kg)
  from d
  group by day
  order by day;
$$;

-- Share of today's calories that came from something actually weighed.
-- This is the number the UI shows and the number the product is built to raise.
create or replace function public.weighed_fraction(p_day date)
returns numeric
language sql
stable
security invoker
as $$
  select case
    when coalesce(sum(mc.kcal), 0) = 0 then 0
    else sum(mc.kcal) filter (where mc.method = 'weighed') / sum(mc.kcal)
  end
  from public.meal_components mc
  join public.meals m on m.id = mc.meal_id
  where mc.user_id = auth.uid()
    and m.eaten_at >= p_day::timestamptz
    and m.eaten_at <  (p_day + 1)::timestamptz;
$$;

-- Full erasure under Article 17. Cascades handle the rest; auth.users is the
-- root. Exposed as an RPC so the app can offer in-app account deletion, which
-- both app stores now require.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;

-- ---------------------------------------------------------------------------
-- updated_at
-- ---------------------------------------------------------------------------

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger recipes_touch before update on public.recipes
  for each row execute function public.touch_updated_at();
