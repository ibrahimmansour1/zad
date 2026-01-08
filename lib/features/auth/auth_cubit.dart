import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/services/admin_auth_service.dart';
import 'package:zad_aldaia/services/admin_mode_service.dart';
import 'package:zad_aldaia/services/admin_permission_service.dart';

/// Authentication state classes
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

/// Keys for SharedPreferences
class AuthKeys {
  static const String hasOnboarded = 'has_onboarded';
  static const String selectedLanguage = 'selected_language';
}

class AuthCubit extends Cubit<AuthState> {
  final SupabaseClient supabase;
  final SharedPreferences sp;

  AuthCubit({required this.supabase, required this.sp}) : super(AuthInitial());

  /// Check if user has completed onboarding
  bool get hasOnboarded => sp.getBool(AuthKeys.hasOnboarded) ?? false;

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    await sp.setBool(AuthKeys.hasOnboarded, true);
  }

  /// Get the current user
  User? get currentUser => supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Initialize auth state - call this on app start
  Future<void> initializeAuth() async {
    emit(AuthLoading());
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Failed to initialize auth: $e'));
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
        return true;
      } else {
        emit(AuthError('Sign in failed'));
        return false;
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
      return false;
    } catch (e) {
      emit(AuthError('Error signing in: $e'));
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUp(String email, String password,
      {String? displayName}) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
        return true;
      } else {
        emit(AuthError('Sign up failed'));
        return false;
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
      return false;
    } catch (e) {
      emit(AuthError('Error signing up: $e'));
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await supabase.auth.signOut();
      if (getIt.isRegistered<AdminAuthService>()) {
        await getIt<AdminAuthService>().logout();
        getIt<AdminPermissionService>().clearCache();
        await getIt<AdminModeService>().enableUserMode();
      }
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Error signing out: $e'));
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      emit(AuthError('Error resetting password: $e'));
      return false;
    }
  }

  /// Listen to auth state changes
  void listenToAuthChanges() {
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (user != null) emit(AuthAuthenticated(user));
          break;
        case AuthChangeEvent.signedOut:
          emit(AuthUnauthenticated());
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (user != null) emit(AuthAuthenticated(user));
          break;
        default:
          break;
      }
    });
  }
}
