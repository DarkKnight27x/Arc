-- REVIEW ONLY / UNAPPLIED. Checkpoint 1 classification authority, not activation.
-- Requires ARC's existing exercise_library and Phase 2A/2B arc_private schema.
-- No seed, approval, plan creation, data rewrite, or session contract changes.
begin;

create table public.exercise_generation_profiles (
  exercise_id uuid not null references public.exercise_library(id) on delete restrict,
  version integer not null check (version > 0),
  primary_muscle text not null check (primary_muscle ~ '^[a-z][a-z0-9_]{0,63}$'),
  movement_patterns text[] not null check (cardinality(movement_patterns) > 0),
  required_equipment text[] not null check (cardinality(required_equipment) > 0),
  allowed_locations text[] not null default array['gym']::text[]
    check (cardinality(allowed_locations) > 0 and allowed_locations <@ array['gym','home']::text[]),
  minimum_experience integer not null check (minimum_experience between 0 and 2),
  work_seconds_per_set integer not null check (work_seconds_per_set between 10 and 180),
  source_snapshot jsonb not null default '{}'::jsonb check (jsonb_typeof(source_snapshot) = 'object'),
  review_status text not null default 'proposed' check (review_status in ('proposed','approved','retired')),
  enabled boolean not null default false,
  review_metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(review_metadata) = 'object'),
  primary key (exercise_id,version),
  check (not enabled or review_status = 'approved'),
  check (array_position(movement_patterns,null) is null),
  check (array_position(required_equipment,null) is null),
  check (array_position(allowed_locations,null) is null)
);
create unique index one_enabled_generation_profile_per_exercise
  on public.exercise_generation_profiles(exercise_id) where enabled;

alter table public.exercise_generation_profiles enable row level security;
-- Explicitly undo inherited/default broad grants on this new table only.
revoke all on table public.exercise_generation_profiles from public,anon,authenticated;
grant select on table public.exercise_generation_profiles to authenticated;
-- No client write policy. Approval is a privileged, separately reviewed operation.
create policy generation_profiles_read on public.exercise_generation_profiles
  for select to authenticated using (
    review_status = 'approved' and enabled and exists (
      select 1 from public.exercise_library l
      where l.id = exercise_id and l.is_published
        and source_snapshot = jsonb_build_object('name',l.name,'body_part',l.body_part,'target_muscle',l.target_muscle,'secondary_muscles',l.secondary_muscles,'equipment',l.equipment,'difficulty',l.difficulty,'instructions',l.instructions,'gif_path',l.gif_path,'tags',l.tags)
    )
  );

create function arc_private.validate_generation_profile()
returns trigger language plpgsql set search_path = '' as $function$
declare current_source jsonb;
begin
  if tg_op = 'DELETE' then
    if old.review_status in ('approved','retired') then
      raise exception 'Reviewed generation definitions cannot be deleted; retire instead' using errcode = '22023';
    end if;
    return old;
  end if;
  if tg_op = 'UPDATE' and old.review_status in ('approved','retired') then
    if (to_jsonb(old) - array['enabled','review_status']) is distinct from
       (to_jsonb(new) - array['enabled','review_status'])
       or new.review_status not in ('approved','retired')
       or (old.review_status = 'retired' and new.review_status <> 'retired') then
      raise exception 'Reviewed generation definition is frozen; create another version' using errcode = '22023';
    end if;
  end if;
  if exists(select 1 from unnest(new.movement_patterns || new.required_equipment) s
    where s !~ '^[a-z][a-z0-9_]{0,63}$')
    or cardinality(new.movement_patterns) <> (select count(distinct s) from unnest(new.movement_patterns) s)
    or cardinality(new.required_equipment) <> (select count(distinct s) from unnest(new.required_equipment) s)
    or cardinality(new.allowed_locations) <> (select count(distinct s) from unnest(new.allowed_locations) s) then
    raise exception 'Classification identifiers must be unique canonical IDs' using errcode = '22023';
  end if;
  if new.review_status = 'approved' and
    (tg_op = 'INSERT' or old.review_status <> 'approved' or (new.enabled and not old.enabled)) then
    if jsonb_typeof(new.review_metadata->'reviewer') is distinct from 'string'
      or nullif(btrim(new.review_metadata->>'reviewer'),'') is null
      or jsonb_typeof(new.review_metadata->'reference') is distinct from 'string'
      or nullif(btrim(new.review_metadata->>'reference'),'') is null
      or jsonb_typeof(new.review_metadata->'reviewed_at') is distinct from 'string'
      or nullif(btrim(new.review_metadata->>'reviewed_at'),'') is null then
      raise exception 'Programming review metadata is required' using errcode = '22023';
    end if;
    perform (new.review_metadata->>'reviewed_at')::timestamptz;
    select jsonb_build_object('name',l.name,'body_part',l.body_part,'target_muscle',l.target_muscle,'secondary_muscles',l.secondary_muscles,'equipment',l.equipment,'difficulty',l.difficulty,'instructions',l.instructions,'gif_path',l.gif_path,'tags',l.tags) into current_source
      from public.exercise_library l
      where l.id = new.exercise_id and l.is_published
        and cardinality(l.instructions) > 0
        and not exists(select 1 from unnest(l.instructions) instruction where instruction is null or btrim(instruction) = '');
    if not found or new.source_snapshot <> current_source then
      raise exception 'Review must match a published exercise with complete instructions' using errcode = '22023';
    end if;
  end if;
  return new;
end;
$function$;
revoke all on function arc_private.validate_generation_profile() from public,anon,authenticated;
create trigger generation_profile_review_guard
  before insert or update or delete on public.exercise_generation_profiles
  for each row execute function arc_private.validate_generation_profile();

comment on table public.exercise_generation_profiles is
  'Versioned exercise programming eligibility. Missing rows are unapproved. Publication is not generation approval. No automatic seed.';
commit;
