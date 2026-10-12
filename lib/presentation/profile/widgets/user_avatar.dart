import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/models/app_user.dart';
import '../../../logic/auth/session_cubit.dart';
import '../../../logic/profile/profile_cubit.dart';

/// The signed-in user's photo (from Storage) or initials. Fades between
/// them, and falls back to initials if the image can't be loaded.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.radius = 20});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.user);
    final (name, url) = context.select((ProfileCubit c) => (c.state.profile?.fullName, c.state.avatarUrl));
    final displayName = (name != null && name.trim().isNotEmpty) ? name : user?.displayName ?? '';
    final initials = AppUser(id: '', email: user?.email ?? '', fullName: displayName).initials;
    final colors = context.colors;

    final fallback = ColoredBox(
      color: colors.primaryContainer,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.8,
          ),
        ),
      ),
    );

    return SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: url == null
              ? KeyedSubtree(key: const ValueKey('initials'), child: fallback)
              : KeyedSubtree(
                  key: ValueKey(url),
                  child: AppNetworkImage(url: url, cacheWidth: (radius * 2).round(), fallback: fallback),
                ),
        ),
      ),
    );
  }
}
