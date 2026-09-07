-- ============================================================================
-- Goals.
--
-- Four columns on profiles that shape the daily energy target: what the user
-- is trying to do with their weight, where they want it to end up, how fast,
-- and how they like their energy split. The target itself is not stored
-- here — it is recomputed on the phone from the latest reading, so it moves
-- as the weight does. Column names match app/lib/core/data/db/tables.dart.
-- ============================================================================

create type goal_kind as enum ('lose', 'maintain', 'gain');
create type macro_split as enum ('balanced', 'high_protein', 'low_carb');

alter table public.profiles
  add column goal             goal_kind not null default 'maintain',
  -- Null while maintaining, or not chosen yet.
  add column target_weight_kg numeric(5,1)
    check (target_weight_kg between 20 and 300),
  -- Kilograms a week. Below a quarter kilo the change is inside the scale's
  -- day-to-day noise; above a kilo the deficit is clamped by the resting
  -- rate on the phone anyway. Null means the default pace.
  add column pace_kg_per_week numeric(3,2)
    check (pace_kg_per_week between 0.25 and 1.0),
  add column macro_split      macro_split not null default 'balanced';

comment on column public.profiles.goal is
  'What the daily target is shaped towards. The target is derived on device '
  'from the latest reading; it is never stored on the profile.';
