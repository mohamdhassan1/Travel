-- =============================================================================
-- Phase 9: in-app account deletion, booking abuse cap, index/grant hygiene.
--
-- Safe to run more than once. Applies on top of the earlier migrations.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Account deletion (store policies require it for apps with sign-up)
--
-- Deletes the caller's auth user. Every user-owned row goes with it through
-- the existing ON DELETE CASCADE foreign keys: profiles, favorites, bookings
-- (and their notifications), device_tokens. Catalog rows are untouched.
--
-- Storage objects are not rows the database may delete directly (Supabase
-- blocks it), so the app first removes the user's own files from the private
-- `avatars` bucket through the Storage API (allowed by the owner-delete
-- policy). If any file is still there, nothing is deleted and the call fails
-- with `avatar_cleanup_required`, so a photo is never orphaned silently.
-- -----------------------------------------------------------------------------
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  if exists (
    select 1 from storage.objects
    where bucket_id = 'avatars' and (storage.foldername(name))[1] = v_uid::text
  ) then
    raise exception 'avatar_cleanup_required' using errcode = 'P0001';
  end if;

  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Booking abuse cap
--
-- There is no payment step, so nothing stops a script from creating bookings
-- (and with them notifications and pushes) in a loop. At most 10 new bookings
-- per user per rolling hour — far above real use. A retry of a request that
-- already succeeded (same client_request_id) is not counted, so idempotent
-- retries still reach the unique constraint and return the existing booking.
-- This is abuse protection only; it says nothing about availability.
-- -----------------------------------------------------------------------------
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

  if not (
    new.client_request_id is not null
    and exists (
      select 1 from public.bookings b
      where b.user_id = auth.uid() and b.client_request_id = new.client_request_id
    )
  ) and (
    select count(*) from public.bookings b
    where b.user_id = auth.uid() and b.created_at > now() - interval '1 hour'
  ) >= 10 then
    raise exception 'booking_rate_limited' using errcode = 'P0001';
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

revoke execute on function public.prepare_booking() from public, anon, authenticated;

-- Supports the per-user "recent bookings" count above.
create index if not exists bookings_user_created_idx on public.bookings (user_id, created_at desc);

-- -----------------------------------------------------------------------------
-- 3. Hygiene (Supabase advisors)
-- -----------------------------------------------------------------------------
-- Covers the notifications -> bookings foreign key (cascade deletes).
create index if not exists notifications_booking_idx on public.notifications (booking_id);

-- `rls_auto_enable()` is an event-trigger function created by the project's
-- "automatic RLS" setting. Event triggers don't check EXECUTE when they fire,
-- so API roles never need it.
do $$
begin
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'rls_auto_enable'
  ) then
    revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
  end if;
end $$;
