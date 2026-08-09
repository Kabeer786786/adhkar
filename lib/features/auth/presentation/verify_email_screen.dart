import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/error_formatter.dart';
import '../../../../shared/providers/user_profile_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String? email;

  const VerifyEmailScreen({super.key, this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _otpScrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus OTP field after screen transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _otpScrollController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(String val) {
    setState(() {});
    // Auto scroll horizontal list to focused digit
    if (val.length > 3 && _otpScrollController.hasClients) {
      final targetOffset = (val.length * 52.0) - 160;
      _otpScrollController.animateTo(
        targetOffset.clamp(0.0, _otpScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _otpController.text.trim();
    final targetEmail = widget.email ?? ref.read(userProfileProvider).email;

    if (targetEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email address is missing.')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await ref.read(userProfileProvider.notifier).verifyEmailOTP(
            email: targetEmail,
            token: code,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! Welcome to Adhkar.'),
            backgroundColor: Color(0xFF2A531D),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorFormatter.format(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    final targetEmail = widget.email ?? ref.read(userProfileProvider).email;
    if (targetEmail.isEmpty) return;

    setState(() {
      _isResending = true;
    });

    try {
      await ref.read(userProfileProvider.notifier).resendVerificationOTP(targetEmail);
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code resent to $targetEmail'),
            backgroundColor: const Color(0xFF2A531D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorFormatter.format(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetEmail = widget.email ?? ref.watch(userProfileProvider).email;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937), size: 18),
          onPressed: () => context.go('/auth'),
        ),
        title: Text(
          'Email Verification',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: [
              const SizedBox(height: 4),

              // 1. Hero Decorative Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B3D14), Color(0xFF2A531D), Color(0xFF3F772E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A531D).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Glowing Animated Mail Badge Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Check Your Inbox',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      'We sent an 8-digit verification code to:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Target Email Badge Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.email_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              targetEmail.isNotEmpty ? targetEmail : 'your email address',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. White Card with 8-Digit OTP Input Form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pin_rounded, color: Color(0xFF2A531D), size: 17),
                          const SizedBox(width: 6),
                          Text(
                            'Enter 8-Digit Verification Code',
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap boxes to enter code (scrollable)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 8-Digit Pin Custom Horizontal Scrollable Box Input Widget
                      _buildEightDigitPinInput(),

                      const SizedBox(height: 22),

                      // Verify Code Primary Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A531D),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0xFF2A531D).withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Verify Code & Continue',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Resend Code Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: _resendCountdown > 0 ? const Color(0xFF2A531D) : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Didn't get the code?",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF4B5563),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: (_resendCountdown == 0 && !_isResending) ? _resendCode : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend in ${_resendCountdown}s'
                            : (_isResending ? 'Sending...' : 'Resend Code'),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _resendCountdown == 0 ? const Color(0xFF2A531D) : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Interactive 8-Digit Pin Input displaying 8 distinct digit boxes in a smooth horizontally scrollable row
  Widget _buildEightDigitPinInput() {
    final currentText = _otpController.text;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_otpFocusNode);
      },
      child: Column(
        children: [
          // Hidden input field capturing 8 digits
          SizedBox(
            height: 0,
            width: 0,
            child: Opacity(
              opacity: 0,
              child: TextFormField(
                focusNode: _otpFocusNode,
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                onChanged: _onOtpChanged,
                validator: (val) {
                  if (val == null || val.trim().length < 8) {
                    return 'Please enter all 8 digits';
                  }
                  return null;
                },
              ),
            ),
          ),

          // Horizontally Scrollable 8-Digit Row
          SizedBox(
            height: 56,
            child: SingleChildScrollView(
              controller: _otpScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                children: List.generate(
                  8,
                  (index) => _buildSingleDigitBox(index, currentText),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                'Swipe horizontally to view all 8 digits',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleDigitBox(int index, String text) {
    final hasValue = index < text.length;
    final isFocused = _otpFocusNode.hasFocus &&
        (index == text.length || (index == 7 && text.length == 8));
    final digit = hasValue ? text[index] : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 44,
      height: 50,
      decoration: BoxDecoration(
        color: hasValue ? const Color(0xFFEBF5EA) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused 
              ? const Color(0xFF2A531D)
              : (hasValue ? const Color(0xFF458133) : const Color(0xFFD1D5DB)),
          width: isFocused ? 2.2 : 1.2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF2A531D).withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          digit,
          style: GoogleFonts.outfit(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2A531D),
          ),
        ),
      ),
    );
  }
}
