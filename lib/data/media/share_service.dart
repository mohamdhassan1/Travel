import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';

import '../../core/utils/app_logger.dart';

/// Opens the platform share sheet. Faked in tests.
abstract interface class ShareService {
  /// Returns `false` if sharing isn't possible here.
  Future<bool> shareText(String text, {String? subject, Rect? origin});
}

class SharePlusShareService implements ShareService {
  @override
  Future<bool> shareText(String text, {String? subject, Rect? origin}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (error) {
      AppLogger.error('Share sheet unavailable', error: error);
      return false;
    }
  }
}
