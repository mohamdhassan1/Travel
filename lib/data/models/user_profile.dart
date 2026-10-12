import 'package:equatable/equatable.dart';

import 'json_read.dart';

/// A row of `public.profiles` (one per auth user, created by the
/// `on_auth_user_created` trigger).
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    this.avatarPath,
    this.preferredLocale = 'en',
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json.str('id'),
        // Empty when the user signed up without a name.
        fullName: (json['full_name'] as String?) ?? '',
        phone: json.strOrNull('phone'),
        avatarPath: json.strOrNull('avatar_path'),
        preferredLocale: json.strOrNull('preferred_locale') ?? 'en',
        createdAt: json.dateOrNull('created_at'),
        updatedAt: json.dateOrNull('updated_at'),
      );

  final String id;
  final String fullName;
  final String? phone;
  final String? avatarPath;
  final String preferredLocale;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        avatarPath,
        preferredLocale,
        createdAt,
        updatedAt,
      ];
}
