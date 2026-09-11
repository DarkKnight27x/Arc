-- Arc prototype schema: client-facing training, meals, rehab and marketplace.
-- Questionnaire/preferences intentionally excluded until the final questions are supplied.

create extension if not exists pgcrypto;

create type public.account_type as enum ('client', 'provider');
create type public.plan_type as enum ('training', 'rehab');
create type public.plan_status as enum ('draft', 'active', 'archived');
create type public.verification_status as enum ('pending', 'approved', 'rejected');
create type public.booking_status as enum ('requested', 'confirmed', 'completed', 'cancelled');
create type public.provider_type as enum ('trainer', 'physiotherapist');

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_path text,
  account_type public.account_type not null default 'client',
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create table public.exercise_library (
  id uuid primary key default gen_random_uuid(),
  source_external_id text unique,
  name text not null,
  body_part text not null,
  target_muscle text,
  secondary_muscles text[] not null default '{}',
  equipment text not null default 'bodyweight',
  difficulty text,
  instructions text[] not null default '{}',
  gif_path text,
  tags text[] not null default '{}',
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  plan_type public.plan_type not null default 'training',
  name text not null,
  status public.plan_status not null default 'draft',
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index one_active_plan_per_type
  on public.workout_plans(user_id, plan_type) where status = 'active';

create table public.workout_days (
  id uuid primary key default gen_random_uuid(),
  workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  title text not null,
  estimated_minutes smallint check (estimated_minutes > 0),
  notes text,
  unique (workout_plan_id, weekday)
);

create table public.workout_day_exercises (
  id uuid primary key default gen_random_uuid(),
  workout_day_id uuid not null references public.workout_days(id) on delete cascade,
  exercise_id uuid not null references public.exercise_library(id),
  sort_order smallint not null check (sort_order >= 0),
  sets smallint check (sets > 0),
  reps text,
  rest_seconds integer check (rest_seconds >= 0),
  notes text,
  unique (workout_day_id, sort_order)
);

create table public.foods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  serving_amount numeric not null check (serving_amount > 0),
  serving_unit text not null,
  calories_kcal numeric not null check (calories_kcal >= 0),
  protein_g numeric not null default 0 check (protein_g >= 0),
  carbs_g numeric not null default 0 check (carbs_g >= 0),
  fat_g numeric not null default 0 check (fat_g >= 0),
  dietary_tags text[] not null default '{}',
  allergen_tags text[] not null default '{}',
  is_published boolean not null default true
);

create table public.meals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  description text,
  recipe_steps text[] not null default '{}',
  image_path text,
  dietary_tags text[] not null default '{}',
  is_published boolean not null default true
);

create table public.meal_ingredients (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null references public.meals(id) on delete cascade,
  food_id uuid not null references public.foods(id),
  quantity numeric not null check (quantity > 0),
  unit text not null,
  sort_order smallint not null check (sort_order >= 0),
  unique (meal_id, sort_order)
);

create table public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  name text not null,
  status public.plan_status not null default 'draft',
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index one_active_meal_plan_per_user
  on public.meal_plans(user_id) where status = 'active';

create table public.meal_plan_items (
  id uuid primary key default gen_random_uuid(),
  meal_plan_id uuid not null references public.meal_plans(id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  meal_id uuid not null references public.meals(id),
  servings numeric not null default 1 check (servings > 0),
  notes text,
  unique (meal_plan_id, weekday, meal_type)
);

create table public.rehab_cases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  body_region text,
  description text not null,
  status text not null default 'active' check (status in ('active', 'improving', 'resolved', 'needs_review')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.medical_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  rehab_case_id uuid references public.rehab_cases(id) on delete set null,
  document_type text not null check (document_type in ('doctor_prescription', 'physio_prescription', 'report', 'other')),
  storage_path text not null unique,
  original_filename text not null,
  mime_type text not null,
  byte_size bigint not null check (byte_size > 0),
  status text not null default 'uploaded' check (status in ('uploaded', 'processing', 'reviewed', 'rejected')),
  uploaded_at timestamptz not null default now()
);

create table public.provider_profiles (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  provider_type public.provider_type not null,
  public_name text not null,
  bio text,
  specialties text[] not null default '{}',
  session_price numeric not null check (session_price >= 0),
  currency text not null default 'AED',
  service_mode text[] not null default '{online}',
  city text,
  is_listed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.provider_verifications (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(user_id) on delete cascade,
  certificate_path text not null,
  certificate_filename text not null,
  status public.verification_status not null default 'pending',
  reviewer_note text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(user_id) on delete cascade,
  provider_id uuid not null references public.provider_profiles(user_id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null check (ends_at > starts_at),
  service_type text not null check (service_type in ('training', 'physiotherapy', 'consultation')),
  price numeric not null check (price >= 0),
  currency text not null default 'AED',
  status public.booking_status not null default 'requested',
  client_note text,
  created_at timestamptz not null default now()
);

-- Generic server-side timestamp trigger. Tables in this schema deliberately avoid
-- client-controlled updated_at values.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
create trigger profiles_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();
create trigger workout_plans_updated_at before update on public.workout_plans for each row execute procedure public.set_updated_at();
create trigger meal_plans_updated_at before update on public.meal_plans for each row execute procedure public.set_updated_at();
create trigger rehab_cases_updated_at before update on public.rehab_cases for each row execute procedure public.set_updated_at();
create trigger provider_profiles_updated_at before update on public.provider_profiles for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.exercise_library enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_days enable row level security;
alter table public.workout_day_exercises enable row level security;
alter table public.foods enable row level security;
alter table public.meals enable row level security;
alter table public.meal_ingredients enable row level security;
alter table public.meal_plans enable row level security;
alter table public.meal_plan_items enable row level security;
alter table public.rehab_cases enable row level security;
alter table public.medical_documents enable row level security;
alter table public.provider_profiles enable row level security;
alter table public.provider_verifications enable row level security;
alter table public.bookings enable row level security;

create policy "users manage own profile" on public.profiles for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "read published exercises" on public.exercise_library for select to authenticated using (is_published);
create policy "read published foods" on public.foods for select to authenticated using (is_published);
create policy "read published meals" on public.meals for select to authenticated using (is_published);
create policy "read ingredients of published meals" on public.meal_ingredients for select to authenticated using (exists (select 1 from public.meals m where m.id = meal_id and m.is_published));

create policy "users manage own workout plans" on public.workout_plans for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users access own workout days" on public.workout_days for all to authenticated using (exists (select 1 from public.workout_plans p where p.id = workout_plan_id and p.user_id = auth.uid())) with check (exists (select 1 from public.workout_plans p where p.id = workout_plan_id and p.user_id = auth.uid()));
create policy "users access own workout exercises" on public.workout_day_exercises for all to authenticated using (exists (select 1 from public.workout_days d join public.workout_plans p on p.id = d.workout_plan_id where d.id = workout_day_id and p.user_id = auth.uid())) with check (exists (select 1 from public.workout_days d join public.workout_plans p on p.id = d.workout_plan_id where d.id = workout_day_id and p.user_id = auth.uid()));

create policy "users manage own meal plans" on public.meal_plans for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users access own meal plan items" on public.meal_plan_items for all to authenticated using (exists (select 1 from public.meal_plans p where p.id = meal_plan_id and p.user_id = auth.uid())) with check (exists (select 1 from public.meal_plans p where p.id = meal_plan_id and p.user_id = auth.uid()));
create policy "users manage own rehab cases" on public.rehab_cases for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage own medical document metadata" on public.medical_documents for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "view listed providers" on public.provider_profiles for select to authenticated using (is_listed);
create policy "providers view own profile" on public.provider_profiles for select to authenticated using (user_id = auth.uid());
create policy "providers create own unlisted profile" on public.provider_profiles for insert to authenticated with check (user_id = auth.uid() and is_listed = false);
create policy "unlisted providers edit own profile" on public.provider_profiles for update to authenticated using (user_id = auth.uid() and is_listed = false) with check (user_id = auth.uid() and is_listed = false);
create policy "providers view own verification uploads" on public.provider_verifications for select to authenticated using (provider_id = auth.uid());
create policy "providers submit pending verification uploads" on public.provider_verifications for insert to authenticated with check (provider_id = auth.uid() and status = 'pending');
create policy "clients create and view own bookings" on public.bookings for all to authenticated using (client_id = auth.uid()) with check (client_id = auth.uid() and exists (select 1 from public.provider_profiles p where p.user_id = provider_id and p.is_listed));
create policy "providers view their bookings" on public.bookings for select to authenticated using (provider_id = auth.uid());
create policy "providers update their bookings" on public.bookings for update to authenticated using (provider_id = auth.uid()) with check (provider_id = auth.uid());

-- Private upload buckets. Object names must begin with the authenticated user's UUID.
insert into storage.buckets (id, name, public)
values ('medical-documents', 'medical-documents', false), ('provider-certificates', 'provider-certificates', false)
on conflict (id) do update set public = false;

create policy "users upload own medical documents" on storage.objects for insert to authenticated
  with check (bucket_id = 'medical-documents' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users read own medical documents" on storage.objects for select to authenticated
  using (bucket_id = 'medical-documents' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users delete own medical documents" on storage.objects for delete to authenticated
  using (bucket_id = 'medical-documents' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "providers upload own certificates" on storage.objects for insert to authenticated
  with check (bucket_id = 'provider-certificates' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "providers read own certificates" on storage.objects for select to authenticated
  using (bucket_id = 'provider-certificates' and (storage.foldername(name))[1] = auth.uid()::text);
