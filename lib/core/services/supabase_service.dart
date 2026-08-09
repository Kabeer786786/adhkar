import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;

  /// Replace with your actual Supabase Project URL & Anon Key
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rcexsmabfkwaxnfnydjz.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjZXhzbWFiZmt3YXhuZm55ZGp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYyMDIzNzgsImV4cCI6MjEwMTc3ODM3OH0.lzfTyE10o8ZubclTufzP6xzGDwXEJWcFf1N48UPoClo',
  );

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  bool get isEmailVerified {
    final user = currentUser;
    if (user == null) return false;
    // Check if email confirmed timestamp exists
    return user.emailConfirmedAt != null && user.emailConfirmedAt!.isNotEmpty;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization warning/error: $e');
    }
  }

  /// Send Email OTP for passwordless registration
  Future<void> sendEmailOTP({
    required String name,
    required String email,
    required String phone,
    required String location,
  }) async {
    try {
      await client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        data: {
          'full_name': name,
          'phone': phone,
          'location': location,
        },
      );
    } catch (e) {
      debugPrint('Error sending Supabase email OTP: $e');
      rethrow;
    }
  }

  /// Sign Up with Email (collects name, email, phone, location)
  Future<AuthResponse> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String location,
    String? password,
  }) async {
    try {
      final pass = password ?? 'adhkar_pass_${email.hashCode}';
      final response = await client.auth.signUp(
        email: email,
        password: pass,
        data: {
          'name': name,
          'full_name': name,
          'phone': phone,
          'phone_number': phone,
          'location': location,
        },
      );

      if (response.user != null) {
        await saveUserProfile(
          name: name,
          email: email,
          phone: phone,
          location: location,
          userId: response.user!.id,
          emailVerified: false,
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error during Supabase sign up: $e');
      rethrow;
    }
  }

  /// Verify Email OTP token
  Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      return response;
    } catch (_) {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      return response;
    }
  }

  /// Resend Verification OTP
  Future<void> resendVerificationOTP({required String email}) async {
    try {
      await client.auth.resend(
        email: email,
        type: OtpType.signup,
      );
    } catch (e) {
      debugPrint('Error resending OTP: $e');
      rethrow;
    }
  }

  /// Fetch user profile from `public.profiles`
  Future<Map<String, dynamic>?> fetchUserProfile([String? uid]) async {
    final targetId = uid ?? currentUser?.id;
    if (targetId == null) return null;
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', targetId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Create or update user profile in Supabase `profiles` table
  Future<Map<String, dynamic>?> saveUserProfile({
    required String name,
    required String email,
    required String phone,
    required String location,
    String? userId,
    bool emailVerified = true,
  }) async {
    final uid = userId ?? currentUser?.id;
    if (uid == null) {
      debugPrint('Cannot save profile: no user ID available');
      return null;
    }

    try {
      final nowIso = DateTime.now().toIso8601String();
      final profileData = {
        'id': uid,
        'user_id': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'email_verified': emailVerified,
        'updated_at': nowIso,
      };

      final response = await client
          .from('profiles')
          .upsert(profileData, onConflict: 'id')
          .select()
          .single();

      debugPrint('Saved profile to Supabase: $response');
      return response;
    } catch (e) {
      debugPrint('Error saving user profile to Supabase: $e');
      return null;
    }
  }

  /// Call `create-order` Edge Function
  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    required String currency,
    required String name,
    required String email,
    required String phone,
    String? userId,
  }) async {
    try {
      final response = await client.functions.invoke(
        'create-order',
        body: {
          'amount': amount,
          'currency': currency,
          'user_id': userId ?? currentUser?.id,
          'user_details': {
            'name': name,
            'email': email,
            'phone': phone,
          },
        },
      );

      if (response.status != 200) {
        throw Exception(
            'Failed to create Razorpay order: ${response.data}');
      }

      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      debugPrint('Error calling create-order Edge Function: $e');
      rethrow;
    }
  }

  /// Call `verify-payment` Edge Function
  Future<bool> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await client.functions.invoke(
        'verify-payment',
        body: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error calling verify-payment Edge Function: $e');
      return false;
    }
  }
}
