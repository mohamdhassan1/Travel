import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards over the Phase 5 migration (idempotency, read receipts,
/// function hardening). The behaviour itself was verified against the live
/// database; these catch regressions in the file.
void main() {
  final sql =
      File('supabase/migrations/20261002000000_booking_idempotency_and_hardening.sql').readAsStringSync().toLowerCase();
  // Without comment lines, so explanations don't satisfy the checks.
  final code = sql.split('\n').where((l) => !l.trimLeft().startsWith('--')).join('\n');

  test('request ids are unique per owner, enforced by the database', () {
    expect(code, contains('add column if not exists client_request_id uuid'));
    expect(code, contains('bookings_user_client_request_key unique (user_id, client_request_id)'));
  });

  test('the client may only add client_request_id; no price/status/owner/update grants', () {
    final grants = RegExp(r'grant [^;]*on table public\.bookings[^;]*;').allMatches(code).map((m) => m[0]!).toList();
    expect(grants, hasLength(2));
    for (final g in grants) {
      expect(g, contains('(client_request_id)'));
      expect(g, isNot(contains('update')));
      expect(g, isNot(contains('anon')));
    }
  });

  test('mark_notifications_read runs as the caller, only touches the caller\'s rows, only read_at', () {
    final fn = RegExp(r'create or replace function public\.mark_notifications_read[\s\S]*?\$\$;').firstMatch(code)![0]!;
    expect(fn, contains('security invoker'));
    expect(fn, isNot(contains('security definer')));
    expect(fn, contains("set search_path = ''"));
    expect(fn, contains('user_id = auth.uid()'));
    expect(RegExp(r'set\s+([a-z_]+)\s*=').allMatches(fn.split('as \$\$')[1]).map((m) => m[1]), ['read_at']);
    expect(code, contains('revoke all on function public.mark_notifications_read(uuid[]) from public, anon'));
    expect(code, contains('grant execute on function public.mark_notifications_read(uuid[]) to authenticated'));
  });

  test('trigger functions are not executable by API roles', () {
    for (final fn in ['handle_new_user', 'notify_booking_change', 'prepare_booking', 'set_updated_at']) {
      expect(code, contains('revoke execute on function public.$fn() from public, anon, authenticated'), reason: fn);
    }
  });

  test('never disables RLS or touches the platform rls_auto_enable function', () {
    expect(code, isNot(contains('disable row level security')));
    expect(code, isNot(contains('rls_auto_enable')));
    expect(code, isNot(contains('service_role')));
  });
}
