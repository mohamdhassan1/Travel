import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';

/// Values of the `public.device_platform` enum.
enum DevicePlatform { android, ios, web }

/// The app-relevant part of a push message's `data` (never trusted as
/// authoritative — any booking it names is re-read from Supabase).
class PushMessage {
  const PushMessage({this.type, this.bookingId, this.reference, this.notificationId});

  /// Reads the `data` the send-booking-notification Edge Function sets:
  /// `type`, `booking_id`, `notification_id`, `reference`.
  factory PushMessage.fromData(Map<String, dynamic> data) {
    String? text(String key) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    final reference = text('reference');
    return PushMessage(
      type: text('type'),
      bookingId: text('booking_id'),
      notificationId: text('notification_id'),
      // Shown in the UI, so only the database's own format is accepted.
      reference: reference != null && RegExp(r'^RH-[0-9A-F]{8}$').hasMatch(reference) ? reference : null,
    );
  }

  final String? type;
  final String? bookingId;
  final String? reference;
  final String? notificationId;

  bool get isBookingConfirmed => type == 'booking_confirmed';
  bool get isBookingCancelled => type == 'booking_cancelled';
}

/// Firebase Cloud Messaging as the app uses it: a device token to register
/// with Supabase, and incoming/opened messages. Faked in tests.
abstract interface class PushMessaging {
  /// Whether FCM initialised on this device (platform supported and Firebase
  /// configured).
  bool get isAvailable;
  DevicePlatform? get platform;

  /// Initialises Firebase. Returns `false` (never throws) when unavailable.
  Future<bool> initialize();

  /// The current FCM registration token, or `null` if unavailable.
  Future<String?> token();
  Stream<String> get tokenRefresh;

  /// Messages received while the app is in the foreground.
  Stream<PushMessage> get foregroundMessages;

  /// Notifications tapped while the app was in the background.
  Stream<PushMessage> get openedMessages;

  /// The notification that launched the app from terminated, if any.
  Future<PushMessage?> initialMessage();
}

/// FCM via FlutterFire on Android (configured by `google-services.json`) and
/// iOS (needs `GoogleService-Info.plist` + APNs, not configured in this repo
/// yet — initialisation then fails and push stays off). Disabled on web: no
/// Firebase web app, VAPID key or messaging service worker is configured.
class FirebasePushMessaging implements PushMessaging {
  bool _available = false;

  @override
  bool get isAvailable => _available;

  @override
  DevicePlatform? get platform {
    if (kIsWeb) return DevicePlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => DevicePlatform.android,
      TargetPlatform.iOS => DevicePlatform.ios,
      _ => null,
    };
  }

  @override
  Future<bool> initialize() async {
    if (kIsWeb || platform == null) return false;
    if (_available) return true;
    try {
      // Options come from the native config files (no firebase_options.dart).
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _available = await FirebaseMessaging.instance.isSupported();
    } catch (error) {
      // Missing / invalid native configuration: push stays unavailable.
      AppLogger.error('Firebase unavailable; push notifications disabled', error: error);
      _available = false;
    }
    return _available;
  }

  @override
  Future<String?> token() async {
    if (!_available) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      AppLogger.error('Could not get an FCM token', error: error);
      return null;
    }
  }

  @override
  Stream<String> get tokenRefresh => _available ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  @override
  Stream<PushMessage> get foregroundMessages =>
      _available ? FirebaseMessaging.onMessage.map((m) => PushMessage.fromData(m.data)) : const Stream.empty();

  @override
  Stream<PushMessage> get openedMessages =>
      _available ? FirebaseMessaging.onMessageOpenedApp.map((m) => PushMessage.fromData(m.data)) : const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async {
    if (!_available) return null;
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      return message == null ? null : PushMessage.fromData(message.data);
    } catch (error) {
      AppLogger.error('Could not read the initial push message', error: error);
      return null;
    }
  }
}
