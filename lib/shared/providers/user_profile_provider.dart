import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class UserProfileState {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String location;
  final bool isEmailVerified;
  final bool isLoading;
  final bool registrationCompleted; 

  UserProfileState({
    this.userId = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.isEmailVerified = false,
    this.isLoading = false,
    this.registrationCompleted = false,
  });

  UserProfileState copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? location,
    bool? isEmailVerified,
    bool? isLoading,
    bool? registrationCompleted,
  }) {
    return UserProfileState(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isLoading: isLoading ?? this.isLoading,
      registrationCompleted: registrationCompleted ?? this.registrationCompleted,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier() : super(UserProfileState()) {
    _loadFromLocalStorage();
  }

  static const String _keyUserId = 'user_id';
  static const String _keyName = 'user_name';
  static const String _keyEmail = 'user_email';
  static const String _keyPhone = 'user_phone';
  static const String _keyLocation = 'user_location';
  static const String _keyRegistrationCompleted = 'registration_completed';
  static const String _keyEmailVerified = 'email_verified';

  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final localUserId = prefs.getString(_keyUserId) ?? '';
    final localName = prefs.getString(_keyName) ?? '';
    final localEmail = prefs.getString(_keyEmail) ?? '';
    final localPhone = prefs.getString(_keyPhone) ?? '';
    final localLocation = prefs.getString(_keyLocation) ?? '';
    final isRegCompleted = prefs.getBool(_keyRegistrationCompleted) ?? false;
    final isVerified = prefs.getBool(_keyEmailVerified) ?? false;

    state = UserProfileState(
      userId: localUserId,
      name: localName,
      email: localEmail,
      phone: localPhone,
      location: localLocation,
      isEmailVerified: isVerified,
      registrationCompleted: isRegCompleted,
    );
  }

  Future<void> _saveLocalStorage({
    String? userId,
    required String name,
    required String email,
    required String phone,
    required String location,
    bool? registrationCompleted,
    bool? emailVerified,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_keyUserId, userId);
    }
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyLocation, location);
    if (registrationCompleted != null) {
      await prefs.setBool(_keyRegistrationCompleted, registrationCompleted);
    }
    if (emailVerified != null) {
      await prefs.setBool(_keyEmailVerified, emailVerified);
    }
  }

  /// Register User with Supabase (Collects name, email, phone, location)
  Future<AuthResponse> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String location,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await SupabaseService().signUpWithEmail(
        name: name,
        email: email,
        password: password,
        phone: phone,
        location: location,
      );

      final uid = response.user?.id ?? '';
      await _saveLocalStorage(
        userId: uid,
        name: name,
        email: email,
        phone: phone,
        location: location,
        registrationCompleted: false,
        emailVerified: false,
      );

      state = state.copyWith(
        userId: uid,
        name: name,
        email: email,
        phone: phone,
        location: location,
        isEmailVerified: false,
        registrationCompleted: false,
        isLoading: false,
      );

      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Verify Email OTP & Complete Registration Profile in Supabase
  Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await SupabaseService().verifyEmailOTP(
        email: email,
        token: token,
      );

      final uid = response.user?.id ?? state.userId;

      final prefs = await SharedPreferences.getInstance();
      final name = state.name.isNotEmpty ? state.name : (prefs.getString(_keyName) ?? '');
      final phone = state.phone.isNotEmpty ? state.phone : (prefs.getString(_keyPhone) ?? '');
      final location = state.location.isNotEmpty ? state.location : (prefs.getString(_keyLocation) ?? '');

      // Save/update profile in Supabase profiles table after confirmation
      await SupabaseService().saveUserProfile(
        name: name,
        email: email,
        phone: phone,
        location: location,
        userId: uid,
        emailVerified: true,
      );

      await _saveLocalStorage(
        userId: uid,
        name: name,
        email: email,
        phone: phone,
        location: location,
        registrationCompleted: true,
        emailVerified: true,
      );

      state = state.copyWith(
        userId: uid,
        name: name,
        email: email,
        phone: phone,
        location: location,
        isEmailVerified: true,
        registrationCompleted: true,
        isLoading: false,
      );

      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Resend Verification OTP Code
  Future<void> resendVerificationOTP(String email) async {
    await SupabaseService().resendVerificationOTP(email: email);
  }

  /// Save/Update profile locally and to Supabase
  Future<bool> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String location,
  }) async {
    await _saveLocalStorage(
      name: name,
      email: email,
      phone: phone,
      location: location,
    );

    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      location: location,
    );

    if (state.userId.isNotEmpty) {
      await SupabaseService().saveUserProfile(
        name: name,
        email: email,
        phone: phone,
        location: location,
        userId: state.userId,
        emailVerified: state.isEmailVerified,
      );
    }

    return true;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier();
});
