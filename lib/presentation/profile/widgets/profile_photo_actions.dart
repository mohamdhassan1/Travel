import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../data/media/photo_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/profile/profile_cubit.dart';
import '../../common/l10n_extensions.dart';

/// Bottom sheet: choose / take / remove the profile photo. Picking happens
/// through [PhotoPicker]; the upload through [ProfileCubit].
Future<void> showProfilePhotoActions(BuildContext context) async {
  final l10n = context.l10n;
  final picker = context.read<PhotoPicker>();
  final cubit = context.read<ProfileCubit>();
  final hasPhoto = cubit.state.profile?.avatarPath != null;

  final choice = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true, // above the tab bar
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.profilePhotoGallery),
            onTap: () => Navigator.pop(sheetContext, 'gallery'),
          ),
          if (picker.canUseCamera)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.profilePhotoCamera),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
          if (hasPhoto)
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(sheetContext).colorScheme.error),
              title: Text(l10n.profilePhotoRemove),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'remove') {
    await cubit.removePhoto();
    return;
  }
  try {
    final photo = await picker.pick(choice == 'camera' ? PhotoSource.camera : PhotoSource.gallery);
    if (photo != null) await cubit.changePhoto(photo.bytes, photo.contentType);
  } catch (_) {
    // The OS picker itself failed (no permission / no camera).
    if (context.mounted) context.showSnack(l10n.profilePhotoPickFailed);
  }
}

/// App-wide: shows the outcome of profile saves and photo changes once each
/// (mounted once in the app builder, so stacked screens never duplicate it).
class ProfileEventListener extends StatelessWidget {
  const ProfileEventListener({super.key, required this.messengerKey, required this.child});
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (a, b) => b.lastEvent != null && a.lastEvent != b.lastEvent,
      listener: (context, state) {
        final messenger = messengerKey.currentState;
        if (messenger == null) return;
        final l10n = AppLocalizations.of(context);
        final event = state.lastEvent!;
        final failure = event.failure == null ? '' : ' ${event.failure!.message(l10n)}';
        final text = switch (event.change) {
          ProfileChange.saved => l10n.profileSaved,
          ProfileChange.saveFailed => '${l10n.profileSaveFailed}$failure',
          ProfileChange.photoUpdated => l10n.profilePhotoUpdated,
          ProfileChange.photoRemoved => l10n.profilePhotoRemoved,
          ProfileChange.photoFailed => '${l10n.profilePhotoFailed}$failure',
          ProfileChange.photoTooLarge => l10n.profilePhotoTooLarge,
        };
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text)));
      },
      child: child,
    );
  }
}
