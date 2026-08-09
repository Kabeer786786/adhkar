import 'package:supabase_flutter/supabase_flutter.dart';

/// Central helper utility to parse raw Supabase & system exceptions into 
/// clean, friendly human-readable error messages.
class ErrorFormatter {
  static String format(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final str = error.toString();
    final lowerStr = str.toLowerCase();

    // 1. Specific Supabase Auth Exception
    if (error is AuthException) {
      return _cleanMessage(error.message);
    }

    // 2. Specific Postgrest Exception
    if (error is PostgrestException) {
      return _cleanMessage(error.message);
    }

    // 3. Known error patterns in string / JSON message
    if (lowerStr.contains('database error saving new user') ||
        lowerStr.contains('unexpected_failure')) {
      return 'Database error saving new user. Please run schema setup or check SMTP settings.';
    }

    if (lowerStr.contains('sending confirmation email') ||
        lowerStr.contains('smtp') ||
        lowerStr.contains('email_provider_disabled') ||
        lowerStr.contains('error sending email')) {
      return 'Error sending confirmation email. Please check your Hostinger SMTP configuration.';
    }

    if (lowerStr.contains('rate limit') || lowerStr.contains('over_email_send_rate_limit')) {
      return 'Email rate limit exceeded. Please wait a few minutes before requesting again.';
    }

    if (lowerStr.contains('user already registered') ||
        lowerStr.contains('already exists') ||
        lowerStr.contains('user_already_exists')) {
      return 'An account with this email address already exists. Please log in.';
    }

    if (lowerStr.contains('invalid login credentials') ||
        lowerStr.contains('invalid_credentials') ||
        lowerStr.contains('wrong password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (lowerStr.contains('token has expired') ||
        lowerStr.contains('otp_expired') ||
        lowerStr.contains('expired')) {
      return 'The verification code has expired. Please request a new code.';
    }

    if (lowerStr.contains('invalid token') ||
        lowerStr.contains('token is invalid') ||
        lowerStr.contains('invalid otp') ||
        lowerStr.contains('bad_jwt')) {
      return 'Invalid verification code. Please check the 6-digit code and try again.';
    }

    if (lowerStr.contains('socketexception') ||
        lowerStr.contains('clientexception') ||
        lowerStr.contains('failed host lookup') ||
        lowerStr.contains('network_error') ||
        lowerStr.contains('connection refused')) {
      return 'Network connection error. Please check your internet connection.';
    }

    // 4. Try extracting message from JSON string e.g. {"code":"...","message":"..."}
    if (str.contains('"message":')) {
      final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(str);
      if (match != null && match.group(1) != null) {
        return _cleanMessage(match.group(1)!);
      }
    }

    // 5. Clean up exception prefix
    String cleaned = str
        .replaceAll(RegExp(r'^[A-Za-z0-9_]+Exception:\s*'), '')
        .replaceAll(RegExp(r'^AuthRetryableFetchException\(message:\s*'), '')
        .replaceAll(RegExp(r'\,\s*statusCode:\s*\d+\)$'), '')
        .trim();

    if (cleaned.length > 120) {
      return 'An error occurred during authentication. Please try again.';
    }

    return cleaned.isEmpty ? 'An unexpected error occurred. Please try again.' : cleaned;
  }

  static String _cleanMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('database error saving new user')) {
      return 'Error saving new user. Please check database schema & SMTP configuration.';
    }
    if (lower.contains('error sending confirmation email') || lower.contains('smtp')) {
      return 'Error sending confirmation email. Please check your Hostinger SMTP setup.';
    }
    if (lower.contains('rate limit')) {
      return 'Too many requests. Please wait a few minutes before trying again.';
    }
    if (lower.contains('invalid token') || lower.contains('token is invalid')) {
      return 'Invalid verification code. Please check and try again.';
    }
    return raw;
  }
}
