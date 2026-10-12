-- =============================================================================
-- Phase 5: booking idempotency, server-side read receipts, function hardening.
--
-- Safe to run more than once. Applies on top of
-- 20260929000000_initial_schema.sql and 20261001000000_package_natural_key.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Booking idempotency
--
-- The app generates a random UUID per booking attempt and reuses it for every
-- retry of that attempt (also after an app restart). The database refuses a
-- second row with the same (owner, request id), so a retry after a lost
-- response can never create a duplicate booking; the app then reads back the
-- booking that already exists.
--
-- `user_id` is always set by `prepare_booking` from auth.uid(), so request ids
-- are scoped per account and one user can't collide with (or probe) another
-- user's ids. Nullable so rows created before this migration stay valid.
-- -----------------------------------------------------------------------------
alter table public.bookings add column if not exists client_request_id uuid;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'bookings_user_client_request_key'
      and conrelid = 'public.bookings'::regclass
  ) then
    alter table public.bookings
      add constraint bookings_user_client_request_key unique (user_id, client_request_id);
  end if;
end $$;

-- The client may send and read its own request id — nothing else changes.
grant insert (client_request_id) on table public.bookings to authenticated;
grant select (client_request_id) on table public.bookings to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Read receipts with the server's clock
--
-- `read_at` is already owner-updatable; this function stamps it with now() on
-- the server and returns the updated rows. SECURITY INVOKER: it runs as the
-- caller, so the existing RLS policy and column grant still apply.
-- p_ids = null marks all of the caller's unread notifications as read.
-- -----------------------------------------------------------------------------
create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns setof public.notifications
language sql
security invoker
set search_path = ''
as $$
  update public.notifications
     set read_at = now()
   where user_id = auth.uid()
     and read_at is null
     and (p_ids is null or id = any (p_ids))
  returning *;
$$;

revoke all on function public.mark_notifications_read(uuid[]) from public, anon;
grant execute on function public.mark_notifications_read(uuid[]) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Function hardening (Supabase Security Advisor 0028 / 0029)
--
-- These are trigger functions: PostgreSQL only checks EXECUTE when a trigger
-- is *created*, never when it fires, so nobody needs to be able to call them.
-- (They also can't be invoked as RPCs — Postgres rejects direct calls to
-- trigger functions — so this removes noise rather than a live hole.)
-- -----------------------------------------------------------------------------
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.notify_booking_change() from public, anon, authenticated;
revoke execute on function public.prepare_booking() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;

-- Belt and braces: keep the Supabase Auth service role able to run the
-- sign-up trigger function even if a future platform change checks EXECUTE.
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
    grant execute on function public.handle_new_user() to supabase_auth_admin;
  end if;
end $$;

-- Intentionally unchanged:
--   * cancel_booking / register_device_token / unregister_device_token:
--     RPCs meant for signed-in users; each checks auth.uid() itself.
--   * public.rls_auto_enable(): an event-trigger function created by the
--     project's "automatic RLS" setting (event trigger `ensure_rls`), not by
--     this app's migrations. It can't be called as an RPC.
