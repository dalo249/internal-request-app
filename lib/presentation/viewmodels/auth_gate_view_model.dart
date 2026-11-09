import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/profile_load_failure_exception.dart';
import 'package:internal_request_app/domain/models/user_profile.dart';
import 'package:internal_request_app/domain/repositories/auth_repository.dart';

enum AuthGateStatus {
  checkingSession,
  signedOut,
  loadingProfile,
  waitingForProfile,
  profileFailure,
  sessionFailure,
  signingOut,
  authenticated,
}

final class AuthGateState {
  const AuthGateState({
    this.status = AuthGateStatus.checkingSession,
    this.profile,
    this.profileFailure,
  });

  final AuthGateStatus status;
  final UserProfile? profile;
  final ProfileLoadFailure? profileFailure;
}

final class AuthGateViewModel extends ChangeNotifier {
  AuthGateViewModel(this._authRepository) {
    _listenToSession();
  }

  final AuthRepository _authRepository;

  AuthGateState _state = const AuthGateState();
  StreamSubscription<Result<String?>>? _sessionSubscription;
  StreamSubscription<Result<UserProfile?>>? _profileSubscription;
  String? _authenticatedUserId;
  bool _isDisposed = false;

  AuthGateState get state => _state;

  void retry() {
    if (_authenticatedUserId != null) {
      _listenToProfile(_authenticatedUserId!);
    } else {
      _listenToSession();
    }
  }

  Future<void> signOut() async {
    _stopWatchingProfile();
    _emit(const AuthGateState(status: AuthGateStatus.signingOut));
    final result = await _authRepository.signOut();

    switch (result) {
      case Ok<void>():
        break;
      case Error<void>():
        _emit(const AuthGateState(status: AuthGateStatus.sessionFailure));
    }
  }

  void _listenToSession() {
    _sessionSubscription?.cancel();
    _stopWatchingProfile();
    _authenticatedUserId = null;
    _emit(const AuthGateState(status: AuthGateStatus.checkingSession));

    _sessionSubscription = _authRepository.watchAuthenticatedUserId().listen(
      _handleSessionResult,
    );
  }

  void _handleSessionResult(Result<String?> result) {
    switch (result) {
      case Error<String?>():
        _stopWatchingProfile();
        _authenticatedUserId = null;
        _emit(const AuthGateState(status: AuthGateStatus.sessionFailure));
      case Ok<String?>():
        final uid = result.value;
        if (uid == null) {
          _stopWatchingProfile();
          _authenticatedUserId = null;
          _emit(const AuthGateState(status: AuthGateStatus.signedOut));
          return;
        }

        if (_authenticatedUserId == uid && _profileSubscription != null) {
          return;
        }
        _listenToProfile(uid);
    }
  }

  void _listenToProfile(String uid) {
    _authenticatedUserId = uid;
    _stopWatchingProfile();
    _emit(const AuthGateState(status: AuthGateStatus.loadingProfile));

    _profileSubscription = _authRepository
        .watchUserProfile(uid)
        .listen((result) => _handleProfileResult(uid, result));
  }

  void _handleProfileResult(String uid, Result<UserProfile?> result) {
    if (_authenticatedUserId != uid) return;

    switch (result) {
      case Error<UserProfile?>():
        final error = result.error;
        _emit(
          AuthGateState(
            status: AuthGateStatus.profileFailure,
            profileFailure: error is ProfileLoadFailureException
                ? error.failure
                : ProfileLoadFailure.unknown,
          ),
        );
      case Ok<UserProfile?>():
        final profile = result.value;
        if (profile == null) {
          _emit(const AuthGateState(status: AuthGateStatus.waitingForProfile));
          return;
        }

        _emit(
          AuthGateState(status: AuthGateStatus.authenticated, profile: profile),
        );
    }
  }

  void _stopWatchingProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  void _emit(AuthGateState state) {
    _state = state;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sessionSubscription?.cancel();
    _stopWatchingProfile();
    super.dispose();
  }
}
