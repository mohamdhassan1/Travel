import 'package:equatable/equatable.dart';

/// The signed-in account as the app needs it — independent of the auth SDK.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.emailConfirmed = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final bool emailConfirmed;
  final DateTime? createdAt;

  /// Best available display name: full name, otherwise the email's local part.
  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }

  /// Up to two initials; rune-based so non-Latin names work.
  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String first(String s) => String.fromCharCodes(s.runes.take(1));
    final value = parts.length > 1 ? first(parts.first) + first(parts.last) : first(parts.first);
    return value.toUpperCase();
  }

  @override
  List<Object?> get props => [id, email, fullName, emailConfirmed, createdAt];
}
