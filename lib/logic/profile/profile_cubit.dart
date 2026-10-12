import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../auth/session_cubit.dart';
import '../common/load_state.dart';

enum ProfileChange { saved, saveFailed, photoUpdated, photoRemoved, photoFailed, photoTooLarge }

/// One-off outcome for a snack bar; [serial] makes repeats distinct.
class ProfileEvent extends Equatable {
  const ProfileEvent(this.change, this.serial, {this.failure});
  final ProfileChange change;
  final int serial;
  final AppFailure? failure;

  @override
  List<Object?> get props => [change, serial, failure];
}

class ProfileState extends Equatable {
  const ProfileState({
    this.status = LoadStatus.loading,
    this.profile,
    this.failure,
    this.avatarUrl,
    this.saving = false,
    this.photoBusy = false,
    this.lastEvent,
  });

  final LoadStatus status;
  final UserProfile? profile;
  final AppFailure? failure;

  /// Signed URL for [UserProfile.avatarPath]; `null` while resolving or if
  /// there's no photo.
  final String? avatarUrl;
  final bool saving;
  final bool photoBusy;
  final ProfileEvent? lastEvent;

  bool get isReady => status == LoadStatus.success && profile != null;

  ProfileState copyWith({
    LoadStatus? status,
    UserProfile? profile,
    AppFailure? Function()? failure,
    String? Function()? avatarUrl,
    bool? saving,
    bool? photoBusy,
    ProfileEvent? lastEvent,
  }) =>
      ProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        failure: failure != null ? failure() : this.failure,
        avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
        saving: saving ?? this.saving,
        photoBusy: photoBusy ?? this.photoBusy,
        lastEvent: lastEvent ?? this.lastEvent,
      );

  @override
  List<Object?> get props => [status, profile, failure, avatarUrl, saving, photoBusy, lastEvent];
}

/// The signed-in user's `profiles` row and photo, shared by Home (greeting,
/// avatar), Profile and Edit profile.
///
/// Follows the session: loads on sign-in, clears on sign-out and when a
/// different user signs in — a previous account's name or photo is never
/// shown. Changes are applied from the rows the server returns.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._profiles, SessionCubit session) : super(const ProfileState()) {
    _subscription = session.stream.listen(_onSession);
    _onSession(session.state);
  }

  final ProfileRepository _profiles;
  late final StreamSubscription<SessionState> _subscription;
  String? _userId;
  int _serial = 0;
  int _generation = 0;
  DateTime? _avatarUrlAt;

  void _onSession(SessionState session) {
    final userId = session.isAuthenticated ? session.user?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    _generation++;
    _avatarUrlAt = null;
    emit(const ProfileState());
    if (userId != null) load();
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    final generation = ++_generation;
    if (!state.isReady) emit(state.copyWith(status: LoadStatus.loading, failure: () => null));
    try {
      final profile = await _profiles.fetchMyProfile();
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(status: LoadStatus.success, profile: profile, failure: () => null));
      await _resolveAvatar(profile, generation);
    } on AppFailure catch (failure) {
      if (isClosed || generation != _generation) return;
      emit(state.isReady
          ? state.copyWith(failure: () => failure)
          : ProfileState(status: LoadStatus.failure, failure: failure));
    }
  }

  /// Signed URLs expire after an hour; refresh when older than 45 minutes.
  Future<void> refreshAvatarUrlIfStale() async {
    final profile = state.profile;
    final at = _avatarUrlAt;
    if (profile?.avatarPath == null) return;
    if (at != null && DateTime.now().difference(at) < const Duration(minutes: 45)) return;
    await _resolveAvatar(profile!, _generation);
  }

  Future<void> _resolveAvatar(UserProfile profile, int generation) async {
    final path = profile.avatarPath;
    if (path == null) {
      if (!isClosed) emit(state.copyWith(avatarUrl: () => null));
      return;
    }
    try {
      final url = await _profiles.avatarUrl(path);
      if (isClosed || generation != _generation || state.profile?.avatarPath != path) return;
      _avatarUrlAt = DateTime.now();
      emit(state.copyWith(avatarUrl: () => url));
    } on AppFailure {
      // Missing / deleted object: fall back to initials.
      if (!isClosed && generation == _generation) emit(state.copyWith(avatarUrl: () => null));
    }
  }

  /// Saves name and phone. Returns whether the server accepted it.
  Future<bool> save({required String fullName, String? phone}) async {
    if (_userId == null || state.saving) return false;
    final generation = _generation;
    emit(state.copyWith(saving: true));
    try {
      final updated = await _profiles.updateProfile(fullName: fullName, phone: phone);
      if (isClosed || generation != _generation) return false;
      emit(state.copyWith(profile: updated, saving: false, lastEvent: ProfileEvent(ProfileChange.saved, ++_serial)));
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed && generation == _generation) {
        emit(state.copyWith(
          saving: false,
          lastEvent: ProfileEvent(ProfileChange.saveFailed, ++_serial, failure: failure),
        ));
      }
      return false;
    }
  }

  Future<void> changePhoto(Uint8List bytes, String contentType) async {
    if (_userId == null || state.photoBusy) return;
    if (bytes.length > SupabaseProfileRepository.maxAvatarBytes) {
      emit(state.copyWith(lastEvent: ProfileEvent(ProfileChange.photoTooLarge, ++_serial)));
      return;
    }
    await _photoOp(() => _profiles.uploadAvatar(bytes, contentType), ProfileChange.photoUpdated);
  }

  Future<void> removePhoto() async {
    if (_userId == null || state.photoBusy || state.profile?.avatarPath == null) return;
    await _photoOp(_profiles.removeAvatar, ProfileChange.photoRemoved);
  }

  Future<void> _photoOp(Future<UserProfile> Function() op, ProfileChange success) async {
    final generation = _generation;
    emit(state.copyWith(photoBusy: true));
    try {
      final updated = await op();
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(
        profile: updated,
        avatarUrl: () => null,
        photoBusy: false,
        lastEvent: ProfileEvent(success, ++_serial),
      ));
      await _resolveAvatar(updated, generation);
    } on AppFailure catch (failure) {
      if (!isClosed && generation == _generation) {
        emit(state.copyWith(
          photoBusy: false,
          lastEvent: ProfileEvent(ProfileChange.photoFailed, ++_serial, failure: failure),
        ));
      }
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
