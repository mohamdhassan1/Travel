-- =============================================================================
-- Phase 7: server-side push dispatch for booking notifications.
--
--   booking insert / cancel
--     -> notify_booking_change (existing)  -> row in public.notifications
--     -> dispatch_notification_push (new)   -> pg_net POST {notification_id}
--     -> Edge Function send-booking-notification -> FCM HTTP v1 -> devices
--
-- The client never calls the sender. The trigger sends only the id of a row
-- the database itself just created; the Edge Function re-reads everything
-- (owner, tokens, booking, type) with server privileges and builds the
-- message itself. pg_net queues the request and sends it only after the
-- transaction commits, so a rolled-back booking never pushes.
--
-- Safe to run more than once. Project-specific values (the function URL) are
-- not in this file; see supabase/README.md section 1d.
-- =============================================================================

create extension if not exists pg_net with schema extensions;

-- Set (once) by the sender when it claims a row: at most one push per
-- notification even if the function is invoked twice. No client grant changes
-- (clients can read it on their own rows; only read_at is client-updatable).
alter table public.notifications add column if not exists push_dispatched_at timestamptz;

-- Shared secret between this trigger and the Edge Function, generated here and
-- kept in Vault. It never leaves the server: the function checks a presented
-- value through verify_push_dispatch_secret() (service role only).
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'push_dispatch_secret') then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'push_dispatch_secret',
      'Authenticates notifications trigger -> send-booking-notification calls'
    );
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- Trigger: queue a push for booking notifications. Never blocks the insert.
-- Does nothing until the Vault secret `push_function_url` is set.
-- -----------------------------------------------------------------------------
create or replace function public.dispatch_notification_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  -- Trip reminders are local to the device; only booking events are pushed.
  if new.type not in ('booking_confirmed', 'booking_cancelled') then
    return new;
  end if;

  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'push_function_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'push_dispatch_secret';
  if v_url is null or v_secret is null then
    return new;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-dispatch-secret', v_secret),
    body := jsonb_build_object('notification_id', new.id),
    timeout_milliseconds := 10000
  );
  return new;
exception when others then
  -- A push problem must never fail a booking.
  raise warning 'push dispatch skipped (%)', sqlstate;
  return new;
end;
$$;

revoke execute on function public.dispatch_notification_push() from public, anon, authenticated;

drop trigger if exists notifications_dispatch_push on public.notifications;
create trigger notifications_dispatch_push
  after insert on public.notifications
  for each row execute function public.dispatch_notification_push();

-- -----------------------------------------------------------------------------
-- Used by the Edge Function (service role only).
-- -----------------------------------------------------------------------------

-- True only for the exact dispatch secret. Never returns the secret.
create or replace function public.verify_push_dispatch_secret(p_secret text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(length(p_secret) >= 32, false) and exists (
    select 1 from vault.decrypted_secrets
    where name = 'push_dispatch_secret' and decrypted_secret = p_secret
  );
$$;

-- Atomically claims a fresh, not-yet-pushed booking notification. Returns no
-- row if it was already claimed, is older than 15 minutes, or isn't a booking
-- event — so a replayed or forged id can never cause a second push.
create or replace function public.claim_notification_push(p_notification_id uuid)
returns setof public.notifications
language sql
security definer
set search_path = ''
as $$
  update public.notifications
     set push_dispatched_at = now()
   where id = p_notification_id
     and push_dispatched_at is null
     and type in ('booking_confirmed', 'booking_cancelled')
     and created_at > now() - interval '15 minutes'
  returning *;
$$;

revoke all on function public.verify_push_dispatch_secret(text) from public, anon, authenticated;
revoke all on function public.claim_notification_push(uuid) from public, anon, authenticated;
grant execute on function public.verify_push_dispatch_secret(text) to service_role;
grant execute on function public.claim_notification_push(uuid) to service_role;
