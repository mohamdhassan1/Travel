import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/app_notification.dart';
import 'package:rahala/data/models/app_user.dart';
import 'package:rahala/data/repositories/notifications_repository.dart';
import 'package:rahala/logic/auth/session_cubit.dart';
import 'package:rahala/logic/notifications/notifications_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_notifications_repository.dart';

Map<String, dynamic> notificationRow({
  String id = '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d',
  String type = 'booking_confirmed',
  Object? bookingId = '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90',
  Object? data = const {
    'reference': 'RH-3F9A1C2B',
    'travel_date': '2026-11-15',
    'destination_name_en': 'Cairo',
    'destination_name_ar': 'القاهرة',
  },
  Object? readAt,
}) =>
    {
      'id': id,
      'user_id': 'u1',
      'type': type,
      'booking_id': bookingId,
      'data': data,
      'read_at': readAt,
      'created_at': '2026-10-02T09:30:00+00:00',
    };

void main() {
  group('AppNotification.fromJson', () {
    test('reads the trigger payload', () {
      final n = AppNotification.fromJson(notificationRow());
      expect(n.type, NotificationType.bookingConfirmed);
      expect(n.bookingId, '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90');
      expect(n.reference, 'RH-3F9A1C2B');
      expect(n.travelDate, DateTime(2026, 11, 15));
      expect(n.destinationName('ar'), 'القاهرة');
      expect(n.destinationName('en'), 'Cairo');
      expect(n.isRead, isFalse);
      expect(
          AppNotification.fromJson(notificationRow(type: 'booking_cancelled')).type, NotificationType.bookingCancelled);
      expect(AppNotification.fromJson(notificationRow(readAt: '2026-10-02T10:00:00Z')).isRead, isTrue);
    });

    test('tolerates a missing or partial data payload and a deleted booking', () {
      final n = AppNotification.fromJson(notificationRow(
        bookingId: null,
        data: {'travel_date': 'not-a-date', 'destination_name_en': 'Cairo', 'reference': 42},
      ));
      expect(n.bookingId, isNull);
      expect(n.travelDate, isNull);
      expect(n.reference, isNull);
      expect(n.destinationName('ar'), 'Cairo', reason: 'falls back to the stored language');
      expect(AppNotification.fromJson(notificationRow(data: null)).reference, isNull);
    });

    test('rejects rows it cannot identify', () {
      expect(() => AppNotification.fromJson(notificationRow(type: 'promo')), throwsFormatException);
      expect(() => AppNotification.fromJson({...notificationRow(), 'id': null}), throwsFormatException);
    });

    test('parseNotificationRows skips unreadable rows instead of failing the list', () {
      final rows = parseNotificationRows([notificationRow(), notificationRow(type: 'promo'), 'junk']);
      expect(rows, hasLength(1));
    });
  });

  group('SupabaseNotificationsRepository', () {
    late List<http.Request> requests;
    late http.Response Function(http.Request) respond;
    late SupabaseClient client;
    late String? signedInUser;
    late SupabaseNotificationsRepository repo;

    http.Response json(Object body, {int status = 200}) =>
        http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

    setUp(() {
      requests = [];
      respond = (_) => json([]);
      signedInUser = 'u1';
      client = SupabaseClient(
        'https://test-project.supabase.co',
        'sb_publishable_test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          requests.add(r);
          final res = respond(r);
          return http.Response.bytes(res.bodyBytes, res.statusCode, headers: res.headers, request: r);
        }),
      );
      repo = SupabaseNotificationsRepository(client, currentUserId: () => signedInUser);
    });
    tearDown(() => client.dispose());

    test('fetchMine: newest first (explicit order), limited, own rows via RLS', () async {
      respond = (_) => json([notificationRow()]);
      final items = await repo.fetchMine(limit: 50);
      expect(items.single.reference, 'RH-3F9A1C2B');
      final url = requests.single.url;
      expect(url.path, '/rest/v1/notifications');
      expect(url.queryParameters['order'], startsWith('created_at.desc'));
      expect(url.queryParameters['order'], contains('id.desc'));
      expect(url.queryParameters['limit'], '50');
      expect(url.queryParameters.containsKey('user_id'), isFalse, reason: 'ownership is RLS, not a client filter');
    });

    test('markRead calls mark_notifications_read and returns the server rows', () async {
      const id = '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d';
      respond = (_) => json([notificationRow(readAt: '2026-10-02T10:00:00+00:00')]);
      final updated = await repo.markRead([id, 'not-a-uuid']);
      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/rest/v1/rpc/mark_notifications_read');
      expect(jsonDecode(r.body), {
        'p_ids': [id]
      });
      expect(updated.single.readAt, DateTime.parse('2026-10-02T10:00:00+00:00'));
    });

    test('markRead with only malformed ids sends nothing; markAllRead sends null', () async {
      expect(await repo.markRead(['x']), isEmpty);
      expect(requests, isEmpty);
      await repo.markAllRead();
      expect(jsonDecode(requests.single.body), {'p_ids': null});
    });

    test('failures are mapped; nothing is sent without a session', () async {
      respond = (_) => json({'code': '42501', 'message': 'permission denied'}, status: 403);
      await expectLater(
          repo.fetchMine(), throwsA(isA<AppFailure>().having((f) => f.type, 'type', FailureType.permissionDenied)));
      requests.clear();
      signedInUser = null;
      await expectLater(
          repo.markAllRead(), throwsA(isA<AppFailure>().having((f) => f.type, 'type', FailureType.sessionExpired)));
      expect(requests, isEmpty);
    });
  });

  group('NotificationsCubit', () {
    const otherUser = AppUser(id: 'user-2', email: 'other@example.com', emailConfirmed: true);
    late FakeAuthRepository auth;
    late SessionCubit session;
    late FakeNotificationsRepository repo;

    setUp(() {
      auth = FakeAuthRepository(signedInAs: testUser);
      session = SessionCubit(auth);
      repo = FakeNotificationsRepository(currentUserId: () => auth.currentUser?.id);
      repo
        ..add(userId: testUser.id)
        ..add(userId: testUser.id, type: NotificationType.bookingCancelled, read: true)
        ..add(userId: 'user-2', reference: 'RH-OTHER000');
    });

    tearDown(() async {
      await session.close();
      await auth.dispose();
    });

    Future<NotificationsCubit> ready() async {
      final cubit = NotificationsCubit(repo, session);
      await pumpEventQueue();
      expect(cubit.state.status, NotificationsStatus.ready);
      return cubit;
    }

    test('loads only the signed-in user\'s notifications, newest first', () async {
      final cubit = await ready();
      expect(
          cubit.state.items.map((n) => n.type), [NotificationType.bookingCancelled, NotificationType.bookingConfirmed]);
      expect(cubit.state.unreadCount, 1);
      expect(cubit.state.items.any((n) => n.reference == 'RH-OTHER000'), isFalse);
    });

    test('loading, then empty', () async {
      final empty = FakeNotificationsRepository(currentUserId: () => auth.currentUser?.id)..loadGate = Completer();
      final cubit = NotificationsCubit(empty, session);
      await pumpEventQueue();
      expect(cubit.state.status, NotificationsStatus.loading);
      empty.loadGate!.complete();
      await pumpEventQueue();
      expect(cubit.state.isEmpty, isTrue);
    });

    test('error, then retry', () async {
      repo.nextLoadFailure = const AppFailure(FailureType.network);
      final cubit = NotificationsCubit(repo, session);
      await pumpEventQueue();
      expect(cubit.state.status, NotificationsStatus.failure);
      expect(cubit.state.failure?.type, FailureType.network);
      await cubit.load();
      expect(cubit.state.status, NotificationsStatus.ready);
    });

    test('markRead uses the server\'s read state', () async {
      final cubit = await ready();
      final unread = cubit.state.items.firstWhere((n) => !n.isRead);
      await cubit.markRead(unread.id);
      expect(repo.calls, contains('mark:${unread.id}'));
      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.items.firstWhere((n) => n.id == unread.id).readAt, repo.stored(unread.id).readAt);
    });

    test('a failed markRead changes nothing locally and is reported', () async {
      final cubit = await ready();
      repo.nextMarkFailure = const AppFailure(FailureType.network);
      await cubit.markRead(cubit.state.items.firstWhere((n) => !n.isRead).id);
      expect(cubit.state.unreadCount, 1, reason: 'never shown as read unless the server confirmed it');
      expect(cubit.state.lastActionFailure?.failure.type, FailureType.network);
    });

    test('markAllRead', () async {
      final cubit = await ready();
      await cubit.markAllRead();
      expect(repo.calls, contains('markAll'));
      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.markingAll, isFalse);
    });

    test('a failed refresh keeps the list and reports the failure', () async {
      final cubit = await ready();
      repo.nextLoadFailure = const AppFailure(FailureType.timeout);
      await cubit.refresh();
      expect(cubit.state.status, NotificationsStatus.ready);
      expect(cubit.state.items, hasLength(2));
      expect(cubit.state.lastActionFailure?.failure.type, FailureType.timeout);
    });

    test('clears on sign-out and reloads for a different account', () async {
      final cubit = await ready();
      await auth.signOut();
      await pumpEventQueue();
      expect(cubit.state.status, NotificationsStatus.signedOut);
      expect(cubit.state.items, isEmpty);

      auth.switchTo(otherUser);
      await pumpEventQueue();
      expect(cubit.state.items.single.reference, 'RH-OTHER000');
      expect(repo.calls.last, 'list:user-2');
    });

    test('a response for the previous account is discarded after a switch', () async {
      final cubit = await ready();
      repo.loadGate = Completer();
      final pending = cubit.refresh();
      auth.switchTo(otherUser);
      repo.loadGate!.complete();
      await pending;
      await pumpEventQueue();
      expect(cubit.state.items.every((n) => n.reference == 'RH-OTHER000'), isTrue);
    });
  });
}
