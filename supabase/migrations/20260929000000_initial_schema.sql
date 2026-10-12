-- =============================================================================
-- Rahala — initial schema
--
-- Security model
--   * Row Level Security is enabled on EVERY table in `public`.
--   * Table privileges are granted explicitly (column-level where it matters),
--     so the client can only touch the columns it is supposed to.
--   * Catalog data (categories, destinations, packages) is world-readable.
--   * User data (profiles, favorites, bookings, device tokens, notifications)
--     is only visible to its owner: `user_id = auth.uid()`.
--   * Prices, booking references and statuses are computed server-side; the
--     client can never write them.
--   * The Flutter app only ever uses the publishable (anon) key.
--
-- Apply with the Supabase CLI (`supabase db push`) or paste into the
-- Dashboard → SQL Editor. The script is idempotent where practical.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Types
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.booking_status as enum ('confirmed', 'cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.notification_type as enum ('booking_confirmed', 'booking_cancelled', 'trip_reminder');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.device_platform as enum ('android', 'ios', 'web');
exception when duplicate_object then null; end $$;

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =============================================================================
-- PROFILES — one row per auth user, created by trigger on sign-up
-- =============================================================================
create table if not exists public.profiles (
  id               uuid primary key references auth.users (id) on delete cascade,
  full_name        text not null default '' check (char_length(full_name) <= 80),
  phone            text check (phone is null or phone ~ '^\+?[0-9 ()-]{6,20}$'),
  -- Path inside the private `avatars` bucket; must live in the owner's folder.
  avatar_path      text check (avatar_path is null or avatar_path like id::text || '/%'),
  preferred_locale text not null default 'en' check (preferred_locale in ('en', 'ar')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(left(btrim(new.raw_user_meta_data ->> 'full_name'), 80), ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;

drop policy if exists "profiles: owner can read" on public.profiles;
create policy "profiles: owner can read" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "profiles: owner can update" on public.profiles;
create policy "profiles: owner can update" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

revoke all on table public.profiles from anon, authenticated;
grant select on table public.profiles to authenticated;
grant update (full_name, phone, avatar_path, preferred_locale) on table public.profiles to authenticated;

-- =============================================================================
-- CATALOG — categories, destinations, packages (public read-only)
-- =============================================================================
create table if not exists public.categories (
  id         text primary key check (id ~ '^[a-z_]{2,32}$'),
  name_en    text not null,
  name_ar    text not null,
  icon       text not null,               -- icon key, mapped to an icon in the app
  sort_order smallint not null default 0
);

create table if not exists public.destinations (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique check (slug ~ '^[a-z0-9-]{2,64}$'),
  category_id    text not null references public.categories (id),
  name_en        text not null,
  name_ar        text not null,
  country_en     text not null,
  country_ar     text not null,
  summary_en     text not null,
  summary_ar     text not null,
  description_en text not null,
  description_ar text not null,
  best_season_en text,
  best_season_ar text,
  latitude       double precision not null check (latitude between -90 and 90),
  longitude      double precision not null check (longitude between -180 and 180),
  -- Absolute https URL, or an object path inside the public `destination-images` bucket.
  cover_image    text not null,
  gallery        text[] not null default '{}',
  -- Where the photos come from (e.g. "Photo: Jane Doe / Unsplash").
  image_credit   text,
  is_featured    boolean not null default false,
  is_published   boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists destinations_category_idx on public.destinations (category_id) where is_published;
create index if not exists destinations_featured_idx on public.destinations (is_featured) where is_published;

drop trigger if exists destinations_set_updated_at on public.destinations;
create trigger destinations_set_updated_at
  before update on public.destinations
  for each row execute function public.set_updated_at();

create table if not exists public.destination_packages (
  id               uuid primary key default gen_random_uuid(),
  destination_id   uuid not null references public.destinations (id) on delete cascade,
  name_en          text not null,
  name_ar          text not null,
  description_en   text not null,
  description_ar   text not null,
  duration_days    smallint not null check (duration_days between 1 and 60),
  price_per_person numeric(10, 2) not null check (price_per_person > 0),
  currency         char(3) not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
  max_travelers    smallint not null default 8 check (max_travelers between 1 and 20),
  includes_en      text[] not null default '{}',
  includes_ar      text[] not null default '{}',
  is_active        boolean not null default true,
  sort_order       smallint not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists destination_packages_destination_idx
  on public.destination_packages (destination_id) where is_active;

drop trigger if exists destination_packages_set_updated_at on public.destination_packages;
create trigger destination_packages_set_updated_at
  before update on public.destination_packages
  for each row execute function public.set_updated_at();

alter table public.categories enable row level security;
alter table public.destinations enable row level security;
alter table public.destination_packages enable row level security;

drop policy if exists "categories: public read" on public.categories;
create policy "categories: public read" on public.categories
  for select to anon, authenticated
  using (true);

drop policy if exists "destinations: public read published" on public.destinations;
create policy "destinations: public read published" on public.destinations
  for select to anon, authenticated
  using (is_published);

drop policy if exists "packages: public read active" on public.destination_packages;
create policy "packages: public read active" on public.destination_packages
  for select to anon, authenticated
  using (
    is_active
    and exists (
      select 1 from public.destinations d
      where d.id = destination_id and d.is_published
    )
  );

-- Catalog is managed from the dashboard / service role only.
revoke all on table public.categories, public.destinations, public.destination_packages from anon, authenticated;
grant select on table public.categories, public.destinations, public.destination_packages to anon, authenticated;

-- Card-friendly projection used by lists & search: destination + "from" price.
-- security_invoker makes the view respect the RLS policies of its base tables.
create or replace view public.destination_summaries
with (security_invoker = true) as
select
  d.id,
  d.slug,
  d.category_id,
  d.name_en,
  d.name_ar,
  d.country_en,
  d.country_ar,
  d.summary_en,
  d.summary_ar,
  d.cover_image,
  d.is_featured,
  d.latitude,
  d.longitude,
  d.created_at,
  p.from_price,
  p.currency,
  p.min_days,
  p.max_days,
  coalesce(p.package_count, 0)::int as package_count
from public.destinations d
left join lateral (
  select
    min(pk.price_per_person) as from_price,
    min(pk.currency)         as currency,
    min(pk.duration_days)    as min_days,
    max(pk.duration_days)    as max_days,
    count(*)                 as package_count
  from public.destination_packages pk
  where pk.destination_id = d.id and pk.is_active
) p on true
where d.is_published;

revoke all on table public.destination_summaries from anon, authenticated;
grant select on table public.destination_summaries to anon, authenticated;

-- Server-side search with safe parameter handling (no string-built filters on the client).
create or replace function public.search_destinations(
  p_query    text default null,
  p_category text default null,
  p_sort     text default 'recommended'   -- recommended | price_asc | price_desc | newest
)
returns setof public.destination_summaries
language sql
stable
security invoker
set search_path = ''
as $$
  with q as (
    select nullif(
      -- escape LIKE wildcards in user input
      replace(replace(replace(btrim(coalesce(p_query, '')), '\', '\\'), '%', '\%'), '_', '\_'),
      ''
    ) as term
  )
  select s.*
  from public.destination_summaries s, q
  where (p_category is null or s.category_id = p_category)
    and (
      q.term is null
      or s.name_en    ilike '%' || q.term || '%'
      or s.name_ar    ilike '%' || q.term || '%'
      or s.country_en ilike '%' || q.term || '%'
      or s.country_ar ilike '%' || q.term || '%'
    )
  order by
    case when p_sort = 'price_asc'  then s.from_price end asc nulls last,
    case when p_sort = 'price_desc' then s.from_price end desc nulls last,
    case when p_sort = 'newest'     then s.created_at end desc,
    s.is_featured desc,
    s.name_en asc;
$$;

revoke all on function public.search_destinations(text, text, text) from public;
grant execute on function public.search_destinations(text, text, text) to anon, authenticated;

-- =============================================================================
-- FAVORITES
-- =============================================================================
create table if not exists public.favorites (
  user_id        uuid not null default auth.uid() references auth.users (id) on delete cascade,
  destination_id uuid not null references public.destinations (id) on delete cascade,
  created_at     timestamptz not null default now(),
  primary key (user_id, destination_id)
);

create index if not exists favorites_destination_idx on public.favorites (destination_id);

alter table public.favorites enable row level security;

drop policy if exists "favorites: owner can read" on public.favorites;
create policy "favorites: owner can read" on public.favorites
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "favorites: owner can add" on public.favorites;
create policy "favorites: owner can add" on public.favorites
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "favorites: owner can remove" on public.favorites;
create policy "favorites: owner can remove" on public.favorites
  for delete to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.favorites from anon, authenticated;
grant select, delete on table public.favorites to authenticated;
grant insert (destination_id) on table public.favorites to authenticated;

-- =============================================================================
-- BOOKINGS
-- =============================================================================
create table if not exists public.bookings (
  id               uuid primary key default gen_random_uuid(),
  reference        text not null unique
                     default ('RH-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))),
  user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
  destination_id   uuid not null references public.destinations (id) on delete restrict,
  package_id       uuid not null references public.destination_packages (id) on delete restrict,
  travel_date      date not null,
  travelers        smallint not null check (travelers between 1 and 20),
  unit_price       numeric(10, 2) not null check (unit_price > 0),
  total_price      numeric(12, 2) not null check (total_price > 0),
  currency         char(3) not null check (currency ~ '^[A-Z]{3}$'),
  status           public.booking_status not null default 'confirmed',
  contact_name     text not null check (char_length(btrim(contact_name)) between 2 and 80),
  contact_phone    text not null check (contact_phone ~ '^\+?[0-9 ()-]{6,20}$'),
  special_requests text check (special_requests is null or char_length(special_requests) <= 500),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  cancelled_at     timestamptz,
  constraint bookings_total_matches check (total_price = unit_price * travelers),
  constraint bookings_cancelled_at_matches check ((status = 'cancelled') = (cancelled_at is not null))
);

create index if not exists bookings_user_travel_date_idx on public.bookings (user_id, travel_date desc);
create index if not exists bookings_destination_idx on public.bookings (destination_id);
create index if not exists bookings_package_idx on public.bookings (package_id);

drop trigger if exists bookings_set_updated_at on public.bookings;
create trigger bookings_set_updated_at
  before update on public.bookings
  for each row execute function public.set_updated_at();

-- Server-authoritative booking preparation: the client only sends what the
-- traveller chose; price, currency, owner and status are derived here.
create or replace function public.prepare_booking()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  pkg public.destination_packages;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  select * into pkg
  from public.destination_packages
  where id = new.package_id and is_active;

  if not found or pkg.destination_id <> new.destination_id then
    raise exception 'package_unavailable' using errcode = 'P0001';
  end if;

  if new.travelers > pkg.max_travelers then
    raise exception 'too_many_travelers' using errcode = 'P0001';
  end if;

  if new.travel_date < current_date + 1 or new.travel_date > current_date + 365 then
    raise exception 'invalid_travel_date' using errcode = 'P0001';
  end if;

  new.user_id      := auth.uid();
  new.unit_price   := pkg.price_per_person;
  new.currency     := pkg.currency;
  new.total_price  := pkg.price_per_person * new.travelers;
  new.status       := 'confirmed';
  new.cancelled_at := null;
  new.contact_name := btrim(new.contact_name);
  return new;
end;
$$;

drop trigger if exists bookings_prepare on public.bookings;
create trigger bookings_prepare
  before insert on public.bookings
  for each row execute function public.prepare_booking();

alter table public.bookings enable row level security;

drop policy if exists "bookings: owner can read" on public.bookings;
create policy "bookings: owner can read" on public.bookings
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "bookings: owner can create" on public.bookings;
create policy "bookings: owner can create" on public.bookings
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- No UPDATE/DELETE grants: bookings change only through cancel_booking().
revoke all on table public.bookings from anon, authenticated;
grant select on table public.bookings to authenticated;
grant insert (destination_id, package_id, travel_date, travelers, contact_name, contact_phone, special_requests)
  on table public.bookings to authenticated;

create or replace function public.cancel_booking(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.bookings;
begin
  update public.bookings
     set status = 'cancelled', cancelled_at = now()
   where id = p_booking_id
     and user_id = auth.uid()
     and status = 'confirmed'
     and travel_date > current_date
  returning * into result;

  if not found then
    raise exception 'booking_not_cancellable' using errcode = 'P0001';
  end if;

  return result;
end;
$$;

revoke all on function public.cancel_booking(uuid) from public, anon;
grant execute on function public.cancel_booking(uuid) to authenticated;

-- =============================================================================
-- DEVICE TOKENS (FCM) — written only via RPC so a token can move between
-- accounts on a shared device without exposing other users' rows.
-- =============================================================================
create table if not exists public.device_tokens (
  id           bigint generated always as identity primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  token        text not null unique check (char_length(token) between 20 and 4096),
  platform     public.device_platform not null,
  created_at   timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create index if not exists device_tokens_user_idx on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

drop policy if exists "device_tokens: owner can read" on public.device_tokens;
create policy "device_tokens: owner can read" on public.device_tokens
  for select to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.device_tokens from anon, authenticated;
grant select on table public.device_tokens to authenticated;

create or replace function public.register_device_token(p_token text, p_platform public.device_platform)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  insert into public.device_tokens (user_id, token, platform)
  values (auth.uid(), p_token, p_platform)
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        last_seen_at = now();
end;
$$;

create or replace function public.unregister_device_token(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.device_tokens where token = p_token and user_id = auth.uid();
$$;

revoke all on function public.register_device_token(text, public.device_platform) from public, anon;
revoke all on function public.unregister_device_token(text) from public, anon;
grant execute on function public.register_device_token(text, public.device_platform) to authenticated;
grant execute on function public.unregister_device_token(text) to authenticated;

-- =============================================================================
-- NOTIFICATIONS — in-app notification center, written by triggers only.
-- `data` carries raw values; the app renders localized text from `type`.
-- =============================================================================
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  type       public.notification_type not null,
  booking_id uuid references public.bookings (id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx on public.notifications (user_id, created_at desc);
create index if not exists notifications_user_unread_idx on public.notifications (user_id) where read_at is null;

alter table public.notifications enable row level security;

drop policy if exists "notifications: owner can read" on public.notifications;
create policy "notifications: owner can read" on public.notifications
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "notifications: owner can mark read" on public.notifications;
create policy "notifications: owner can mark read" on public.notifications
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "notifications: owner can delete" on public.notifications;
create policy "notifications: owner can delete" on public.notifications
  for delete to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.notifications from anon, authenticated;
grant select, delete on table public.notifications to authenticated;
grant update (read_at) on table public.notifications to authenticated;

create or replace function public.notify_booking_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  dest public.destinations;
  kind public.notification_type;
begin
  if tg_op = 'INSERT' then
    kind := 'booking_confirmed';
  elsif tg_op = 'UPDATE' and new.status = 'cancelled' and old.status <> 'cancelled' then
    kind := 'booking_cancelled';
  else
    return new;
  end if;

  select * into dest from public.destinations where id = new.destination_id;

  insert into public.notifications (user_id, type, booking_id, data)
  values (
    new.user_id,
    kind,
    new.id,
    jsonb_build_object(
      'reference', new.reference,
      'travel_date', new.travel_date,
      'destination_name_en', dest.name_en,
      'destination_name_ar', dest.name_ar
    )
  );
  return new;
end;
$$;

drop trigger if exists bookings_notify on public.bookings;
create trigger bookings_notify
  after insert or update of status on public.bookings
  for each row execute function public.notify_booking_change();

-- =============================================================================
-- STORAGE
--   avatars             private; each user reads/writes only `<uid>/...`
--   destination-images  public read; managed from the dashboard only
-- =============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', false, 2097152, array['image/jpeg', 'image/png', 'image/webp']),
  ('destination-images', 'destination-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "avatars: owner can read" on storage.objects;
create policy "avatars: owner can read" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "avatars: owner can upload" on storage.objects;
create policy "avatars: owner can upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "avatars: owner can update" on storage.objects;
create policy "avatars: owner can update" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "avatars: owner can delete" on storage.objects;
create policy "avatars: owner can delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
