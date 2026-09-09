import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'supabase_service.dart';

typedef DonationSuccessCallback = void Function(
  String paymentId,
  String orderId,
  String signature,
);
typedef DonationErrorCallback = void Function(String errorMessage);

class RazorpayDonationService {
  late Razorpay _razorpay;
  DonationSuccessCallback? _onSuccess;
  DonationErrorCallback? _onError;
  String? _currentOrderId;

  RazorpayDonationService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  /// Initiate Razorpay donation flow by calling `create-order` Edge Function
  Future<void> processDonation({
    required double amount,
    required String currency,
    required String name,
    required String email,
    required String phone,
    String? profileId,
    required DonationSuccessCallback onSuccess,
    required DonationErrorCallback onError,
  }) async {
    _onSuccess = onSuccess;
    _onError = onError;

    try {
      // Step 1: Call Supabase create-order Edge Function
      final orderResult = await SupabaseService().createRazorpayOrder(
        amount: amount,
        currency: currency,
        name: name,
        email: email,
        phone: phone,
        profileId: profileId,
      );

      final String orderId = orderResult['order_id'] ?? '';
      final String razorpayKeyId = orderResult['key_id'] ?? 'rzp_test_dummykey';
      final int amountInSubunits = orderResult['amount'] ?? (amount * 100).toInt();

      _currentOrderId = orderId;

      // Step 2: Open Razorpay Checkout UI
      var options = {
        'key': razorpayKeyId,
        'amount': amountInSubunits,
        'currency': currency,
        'name': 'Adhkar Islamic App',
        'description': 'Sadqa & Islamic Support Donation',
        'order_id': orderId,
        'prefill': {
          'contact': phone,
          'email': email,
          'name': name,
        },
        'theme': {
          'color': '#2A531D',
        }
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error starting donation: $e');
      _onError?.call(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success: ${response.paymentId}');
    final paymentId = response.paymentId ?? '';
    final orderId = response.orderId ?? _currentOrderId ?? '';
    final signature = response.signature ?? '';

    // Step 1: Notify UI immediately so the celebration appears without any lag or delay
    _onSuccess?.call(paymentId, orderId, signature);

    // Step 2: Call Supabase verify-payment Edge Function server-side asynchronously
    try {
      final isVerified = await SupabaseService().verifyRazorpayPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (!isVerified) {
        debugPrint(
          'Warning: Payment signature verification returned false server-side for $paymentId',
        );
      }
    } catch (e) {
      debugPrint('Error verifying payment: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _onError?.call(response.message ?? 'Payment cancelled or failed.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }
}
