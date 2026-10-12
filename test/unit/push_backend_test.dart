import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/data/notifications/local_reminder_notifier.dart';
import 'package:rahala/data/notifications/push_messaging.dart';

/// Static guards over the Phase 7 push backend: the migration's security
/// model, and that the Edge Function, Android resources and Dart code agree
/// on keys, channel and icon (a mismatch would silently break pushes).
void main() {
  final migration = File('supabase/migrations/20261003000000_push_dispatch.sql').readAsStringSync().toLowerCase();
  final code = migration.split('\n').where((l) => !l.trimLeft().startsWith('--')).join('\n');
  final fcm = File('supabase/functions/send-booking-notification/fcm.ts').readAsStringSync();
  final index = File('supabase/functions/send-booking-notification/index.ts').readAsStringSync();
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  group('migration', () {
    test('the trigger sends only the notification id, only for booking events, never failing the insert', () {
      final fn =
          RegExp(r'create or replace function public\.dispatch_notification_push[\s\S]*?\$\$;').firstMatch(code)![0]!;
      expect(fn, contains('security definer'));
      expect(fn, contains("set search_path = ''"));
      expect(fn, contains("new.type not in ('booking_confirmed', 'booking_cancelled')"));
      expect(fn, contains("jsonb_build_object('notification_id', new.id)"));
      expect(fn, contains('exception when others'));
      expect(code, contains('after insert on public.notifications'));
    });

    test('server-only functions are not callable by clients', () {
      for (final f in [
        'dispatch_notification_push()',
        'verify_push_dispatch_secret(text)',
        'claim_notification_push(uuid)',
      ]) {
        expect(code, contains('on function public.$f from public, anon, authenticated'), reason: f);
      }
      expect(code, contains('grant execute on function public.verify_push_dispatch_secret(text) to service_role'));
      expect(code, contains('grant execute on function public.claim_notification_push(uuid) to service_role'));
      expect(code, isNot(contains('to authenticated')));
      expect(code, isNot(contains('to anon')));
    });

    test('claim is single-use and time-boxed; the secret is generated, never written in the file', () {
      final claim =
          RegExp(r'create or replace function public\.claim_notification_push[\s\S]*?\$\$;').firstMatch(code)![0]!;
      expect(claim, contains('push_dispatched_at is null'));
      expect(claim, contains("interval '15 minutes'"));
      expect(code, contains("vault.create_secret(\n      encode(extensions.gen_random_bytes(32), 'hex')"));
      expect(code, isNot(contains('https://')), reason: 'project URLs are configured per environment, not migrated');
    });
  });

  group('edge function', () {
    test('accepts only the dispatch secret and an id; uses HTTP v1 and the secret name', () {
      expect(index, contains("req.headers.get('x-push-dispatch-secret')"));
      expect(index, contains("admin.rpc('verify_push_dispatch_secret'"));
      expect(index, contains("admin.rpc('claim_notification_push'"));
      expect(index, contains("Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')"));
      expect(index, contains('https://fcm.googleapis.com/v1/projects/'));
      expect(index, isNot(contains('fcm.googleapis.com/fcm/send')), reason: 'no legacy API');
      // Tokens are looked up for the notification owner only, and never logged whole.
      expect(index, contains(".from('device_tokens')"));
      expect(index, contains(".eq('user_id', row.user_id)"));
      for (final line in index.split('\n').where((l) => l.contains('console.'))) {
        // A raw `token` / `tokens` / `presented` argument would leak it.
        final unmasked = line.replaceAll('maskToken(token)', 'masked');
        expect(RegExp(r'[(,]\s*(token|tokens|presented|bearer)\s*[,)]').hasMatch(unmasked), isFalse, reason: line);
      }
      expect(index, contains('maskToken(token)'));
    });
  });

  group('Android ↔ function ↔ app agree', () {
    test('channel id', () {
      expect(fcm, contains("ANDROID_CHANNEL_ID = '${FlutterLocalReminderNotifier.bookingUpdatesChannelId}'"));
      expect(manifest, contains('default_notification_channel_id"\n            android:value="booking_updates"'));
    });

    test('monochrome status-bar icon exists and is the default for FCM and reminders', () {
      final icon = File('android/app/src/main/res/drawable/ic_stat_rahala.xml');
      expect(icon.existsSync(), isTrue);
      final xml = icon.readAsStringSync();
      expect(xml, contains('<vector'));
      expect(RegExp(r'android:fillColor="#FFFFFFFF"').allMatches(xml), isNotEmpty, reason: 'single colour');
      expect(fcm, contains("ANDROID_ICON = 'ic_stat_rahala'"));
      expect(manifest, contains('android:resource="@drawable/ic_stat_rahala"'));
      expect(File('lib/data/notifications/local_reminder_notifier.dart').readAsStringSync(),
          contains("AndroidInitializationSettings('@drawable/ic_stat_rahala')"));
    });

    test('every localization key the function sends exists in English and Arabic', () {
      final keys = RegExp(r"key: '(push_[a-z_]+)'").allMatches(fcm).map((m) => m[1]!).toList();
      expect(keys, ['push_booking_confirmed', 'push_booking_cancelled']);
      for (final dir in ['values', 'values-ar']) {
        final strings = File('android/app/src/main/res/$dir/strings.xml').readAsStringSync();
        for (final key in keys) {
          expect(strings, contains('name="${key}_title"'), reason: '$dir $key');
          expect(RegExp('name="${key}_body">[^<]*%1\\\$s').hasMatch(strings), isTrue, reason: '$dir $key body arg');
        }
      }
    });

    test('POST_NOTIFICATIONS and reboot handling stay declared', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('ScheduledNotificationBootReceiver'));
    });
  });

  group('PushMessage', () {
    test('reads the function data; rejects malformed references', () {
      final m = PushMessage.fromData({
        'type': 'booking_cancelled',
        'booking_id': '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90',
        'notification_id': '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d',
        'reference': 'RH-3F9A1C2B',
      });
      expect(m.isBookingCancelled, isTrue);
      expect(m.reference, 'RH-3F9A1C2B');
      expect(m.notificationId, '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d');
      expect(PushMessage.fromData({'reference': '<b>hi</b>'}).reference, isNull);
      expect(PushMessage.fromData({'type': 42, 'booking_id': ''}).bookingId, isNull);
    });
  });
}
