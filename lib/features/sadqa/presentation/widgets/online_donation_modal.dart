import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/razorpay_donation_service.dart';
import '../../../../shared/providers/user_profile_provider.dart';
import '../../domain/models/sadqa_record.dart';
import '../providers/sadqa_provider.dart';

class OnlineDonationModal extends ConsumerStatefulWidget {
  const OnlineDonationModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OnlineDonationModal(),
    );
  }

  @override
  ConsumerState<OnlineDonationModal> createState() =>
      _OnlineDonationModalState();
}

class _OnlineDonationModalState extends ConsumerState<OnlineDonationModal> {
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late RazorpayDonationService _razorpayService;
  bool _isLoading = false;

  // Post-payment celebration state
  bool _isSuccess = false;
  String _successPaymentId = '';
  String _successOrderId = '';
  double _successAmount = 0.0;
  String _successCurrency = 'INR';
  DateTime? _successDate;

  // Currency state: 'INR' or 'USD'
  String _selectedCurrency = 'INR';
  double _selectedAmount = 100.0;

  static const double _maxDonationAmount = 100000.0;

  // Preset amounts: INR starts 50, USD starts 5
  List<double> get _presetAmounts {
    return _selectedCurrency == 'INR'
        ? [50.0, 100.0, 500.0, 1000.0]
        : [5.0, 10.0, 25.0, 50.0];
  }

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayDonationService();

    final user = ref.read(userProfileProvider);
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone;

    // Detect currency based on user location (Default = INR for India/Indian cities, USD for foreign)
    _detectCurrencyFromLocation(user.location);
  }

  void _detectCurrencyFromLocation(String location) {
    final isExplicitUsd = _isExplicitUsdLocation(location);
    if (isExplicitUsd) {
      _selectedCurrency = 'USD';
      _selectedAmount = 5.0;
      _amountController.text = '5';
    } else {
      _selectedCurrency = 'INR'; // Default INR for India & Indian users
      _selectedAmount = 100.0;
      _amountController.text = '100';
    }
  }

  bool _isExplicitUsdLocation(String location) {
    final loc = location.trim().toLowerCase();
    if (loc.isEmpty) return false;

    final usdKeywords = ['usa', 'united states', 'america', 'usd'];
    return usdKeywords.any((keyword) => loc.contains(keyword));
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startRazorpayPayment() {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid donation amount.')),
      );
      return;
    }

    if (amount > _maxDonationAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum allowed donation amount is ${_selectedCurrency == 'INR' ? '₹' : '\$'}${_maxDonationAmount.toStringAsFixed(0)}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and email address.'),
        ),
      );
      return;
    }

    // Save/update donor profile details in local app state & Supabase database
    ref
        .read(userProfileProvider.notifier)
        .saveProfile(
          name: name,
          email: email,
          phone: phone,
          location: ref.read(userProfileProvider).location,
        );

    setState(() {
      _isLoading = true;
    });

    final user = ref.read(userProfileProvider);
    final profileId = user.profileId;

    // Calls RazorpayDonationService via Supabase Edge Functions
    _razorpayService.processDonation(
      amount: amount,
      currency: _selectedCurrency,
      name: name,
      email: email,
      phone: phone,
      profileId: profileId,
      onSuccess: (paymentId, orderId, signature) {
        if (!mounted) return;

        // Play subtle celebratory haptic feedback
        HapticFeedback.mediumImpact();

        // Auto-log online donation payment directly into Sadaqah records
        final currencySymbol = _selectedCurrency == 'INR' ? '₹' : '\$';
        ref
            .read(sadqaRecordsProvider.notifier)
            .addRecord(
              SadqaRecord(
                id: 'online_${DateTime.now().millisecondsSinceEpoch}',
                type: CharityType.sadaqah,
                category: SadaqahCategory.general,
                amount: amount,
                currency: currencySymbol,
                date: DateTime.now(),
                recipient: 'Online App Donation',
                note: 'Razorpay Txn: $paymentId',
              ),
            );

        // Instantly transition to the celebration view without popping the modal!
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _successPaymentId = paymentId;
          _successOrderId = orderId;
          _successAmount = amount;
          _successCurrency = _selectedCurrency;
          _successDate = DateTime.now();
        });
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Donation Error: $errorMessage'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildCelebrationView(context);
    }
    return _buildDonationFormView(context);
  }

  // ===========================================================================
  // JAZAKALLAH KHAIR CELEBRATION VIEW WITH SPREADING FLOWERS & STARS
  // ===========================================================================

  Widget _buildCelebrationView(BuildContext context) {
    final currencySymbol = _successCurrency == 'INR' ? '₹' : '\$';
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(
      _successDate ?? DateTime.now(),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // SPREADING FLOWERS & STARS PARTICLES WITH CENTRAL VICTORY BADGE
            const _SpreadingCelebrationBadge(),

            const SizedBox(height: 12),

            // Arabic Blessing Calligraphy
            Text(
              'جَزَاكَ ٱللَّٰهُ خَيْرًا',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B3D14),
                height: 1.3,
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 2),

            // English Title
            Text(
              'JazakAllah Khair!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A531D),
                letterSpacing: -0.3,
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 450.ms),

            const SizedBox(height: 6),

            // Heartfelt Blessing Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'May Allah accept your generous Sadqa, purify and multiply your wealth, and bless you and your family with boundless barakah.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: const Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 450.ms),

            const SizedBox(height: 20),

            // DONATION RECEIPT CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4E7D2),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Receipt Header Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2A531D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Donation Receipt',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2A531D),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFA5D6A7),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Amount Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount Donated',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'Online Sadqa Support',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$currencySymbol${_successAmount.toStringAsFixed(0)} $_successCurrency',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A531D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Transaction ID Row with One-Tap Copy
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _successOrderId.isNotEmpty
                                  ? 'Transaction & Order Reference'
                                  : 'Transaction ID',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _successPaymentId.isNotEmpty
                                  ? _successPaymentId
                                  : 'Verified via Razorpay',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            if (_successOrderId.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Order: $_successOrderId',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (_successPaymentId.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: Color(0xFF2A531D),
                            ),
                            tooltip: 'Copy Txn ID',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _successPaymentId),
                              );
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction ID copied!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Date & Sadqa Tracker Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.bookmark_added_rounded,
                            size: 14,
                            color: Color(0xFF2A531D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Saved in Sadqa Tracker',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2A531D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms, duration: 500.ms).slideY(
                  begin: 0.12,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 22),

            // PRIMARY DONE ACTION BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor:
                      const Color(0xFF2A531D).withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.done_all_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Alhamdulillah • Done',
                      style: GoogleFonts.outfit(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 450.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // NORMAL DONATION FORM VIEW (BEFORE PAYMENT)
  // ===========================================================================

  Widget _buildDonationFormView(BuildContext context) {
    final currencySymbol = _selectedCurrency == 'INR' ? '₹' : '\$';

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Banner Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B3D14), Color(0xFF2A531D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support App & Sadqa',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: Color(0xFFA3E635),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Secure Payments with Razorpay',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Preset Amount Chips Header
              Text(
                'Select Predefined Amount ($_selectedCurrency)',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 8),

              // Preset Amount Chips Row
              Row(
                children: _presetAmounts.map((amt) {
                  final isSelected = _selectedAmount == amt;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAmount = amt;
                          _amountController.text = amt.toStringAsFixed(0);
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2A531D)
                              : const Color(0xFFF4FAF3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2A531D)
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Text(
                          '$currencySymbol${amt.toStringAsFixed(0)}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF2A531D),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Custom Amount Input Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                decoration: InputDecoration(
                  labelText: 'Custom Donation Amount ($currencySymbol)',
                  hintText: 'Enter amount (Max: ${currencySymbol}100,000)',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      currencySymbol,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2A531D),
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF2A531D),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (val) {
                  final amt = double.tryParse(val);
                  if (amt != null) {
                    setState(() {
                      _selectedAmount = amt;
                    });
                  }
                },
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a donation amount';
                  }
                  final amt = double.tryParse(val.trim());
                  if (amt == null || amt <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  if (amt > _maxDonationAmount) {
                    return 'Maximum donation amount is $currencySymbol${_maxDonationAmount.toStringAsFixed(0)}';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Donor Details Section
              Text(
                'Donor Information',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),

              // Donor Name Input Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your name',
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF2A531D),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Donor Email Input Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email address',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF2A531D),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty || !val.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Donor Phone Input Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  hintText: 'Enter your phone number',
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF2A531D),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // SINGLE ACTION BUTTON: "Proceed to Pay"
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startRazorpayPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A531D),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color(
                      0xFF2A531D,
                    ).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Securing Payment...',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Proceed to Pay',
                              style: GoogleFonts.outfit(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SPREADING CELEBRATION BADGE (FLOWERS, STARS & GLOWING EMERALD CIRCLE)
// =============================================================================

class _CelebrationParticle {
  final String char;
  final double angle;
  final double distance;
  final double scale;
  final double size;
  final double spinDelta;
  final double floatPhase;
  final double floatSpeed;

  const _CelebrationParticle({
    required this.char,
    required this.angle,
    required this.distance,
    required this.scale,
    required this.size,
    required this.spinDelta,
    required this.floatPhase,
    required this.floatSpeed,
  });
}

class _SpreadingCelebrationBadge extends StatefulWidget {
  const _SpreadingCelebrationBadge();

  @override
  State<_SpreadingCelebrationBadge> createState() =>
      _SpreadingCelebrationBadgeState();
}

class _SpreadingCelebrationBadgeState extends State<_SpreadingCelebrationBadge>
    with TickerProviderStateMixin {
  late final AnimationController _burstController;
  late final AnimationController _ambientController;
  late final CurvedAnimation _burstCurve;

  // 44 Deterministic spreading flowers and sparkling stars
  static final List<_CelebrationParticle> _particles = List.generate(44, (i) {
    final baseAngle = (i / 44.0) * 2 * math.pi;
    final rng = math.Random(i * 1237 + 42);
    final angleJitter = (rng.nextDouble() - 0.5) * 0.35;
    final angle = baseAngle + angleJitter;
    final distance = 78.0 + rng.nextDouble() * 115.0; // 78 to 193 px spread
    final scale = 0.85 + rng.nextDouble() * 0.45;
    final size = 18.0 + rng.nextDouble() * 12.0;
    final spinDelta =
        (rng.nextBool() ? 1.0 : -1.0) * (math.pi * 0.6 + rng.nextDouble() * math.pi);
    final floatPhase = rng.nextDouble() * 2 * math.pi;
    final floatSpeed = 0.8 + rng.nextDouble() * 1.3;

    // Harmonious mix of flowers and glowing stars
    const chars = [
      '🌸', '✨', '🌺', '⭐', '🌼', '🌟', '🌷', '💫',
      '🌹', '✦', '🌿', '✨', '🌸', '🌟', '🌺', '⭐',
      '🌼', '💫', '🌷', '✦', '🏵️', '✨', '🌹', '🌟',
      '🌿', '⭐', '🌸', '💫', '🌺', '✦', '🌼', '✨',
      '🌷', '🌟', '🌹', '⭐', '🌿', '💫', '🌸', '✨',
      '🌺', '🌟', '🌼', '💫',
    ];
    final char = chars[i % chars.length];

    return _CelebrationParticle(
      char: char,
      angle: angle,
      distance: distance,
      scale: scale,
      size: size,
      spinDelta: spinDelta,
      floatPhase: floatPhase,
      floatSpeed: floatSpeed,
    );
  });

  @override
  void initState() {
    super.initState();
    // Burst animation: spreads flowers and stars outward rapidly
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _burstCurve = CurvedAnimation(
      parent: _burstController,
      curve: Curves.easeOutCubic,
    );

    // Ambient floating/twinkling loop: keeps the particles lively
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _burstController.forward();
    _ambientController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _burstController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background soft radial glow aura
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFA3E635).withValues(alpha: 0.30),
                  const Color(0xFF2A531D).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Custom canvas for radiating starlight beams
          CustomPaint(
            size: const Size(220, 220),
            painter: _RadiantStarlightPainter(
              animation: _burstCurve,
              ambient: _ambientController,
            ),
          ),

          // SPREADING FLOWERS & STARS PARTICLES (🌸 🌺 🌼 🌷 🌹 🌿 ✨ ⭐ 🌟 💫)
          AnimatedBuilder(
            animation: Listenable.merge([_burstController, _ambientController]),
            builder: (context, _) {
              final burstProgress = _burstCurve.value;
              final ambientVal = _ambientController.value;

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: _particles.map((p) {
                  final dist = p.distance * burstProgress;
                  final flutter = math.sin(
                        (ambientVal * 2 * math.pi) * p.floatSpeed + p.floatPhase,
                      ) *
                      6.0;

                  final dx = dist * math.cos(p.angle);
                  final dy = dist * math.sin(p.angle) + flutter;

                  // Pop up scale quickly at start, then gently pulse
                  final scaleProgress = (burstProgress < 0.25
                          ? (burstProgress / 0.25)
                          : 1.0) *
                      p.scale *
                      (0.92 + 0.08 * math.sin(ambientVal * math.pi));

                  final rotation =
                      (p.spinDelta * burstProgress) + (ambientVal * 0.2);

                  final opacity = (burstProgress < 0.15
                          ? (burstProgress / 0.15)
                          : 1.0)
                      .clamp(0.0, 1.0);

                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scaleProgress,
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            p.char,
                            style: TextStyle(
                              fontSize: p.size,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  blurRadius: 4,
                                ),
                                Shadow(
                                  color: const Color(0xFF2A531D)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Glowing Outer Concentric Ring
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFA3E635).withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA3E635).withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          ).animate().scale(
                duration: 650.ms,
                curve: Curves.elasticOut,
              ),

          // Central Victory Emerald Checkmark Circle
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B3D14), Color(0xFF2A531D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFA3E635),
                width: 3.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A531D).withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
          ).animate().scale(
                duration: 700.ms,
                curve: Curves.elasticOut,
              ),
        ],
      ),
    );
  }
}

/// Custom painter for glowing starburst beams and sparkling diamond bursts
class _RadiantStarlightPainter extends CustomPainter {
  final Animation<double> animation;
  final Animation<double> ambient;

  _RadiantStarlightPainter({
    required this.animation,
    required this.ambient,
  }) : super(repaint: Listenable.merge([animation, ambient]));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final progress = animation.value;
    if (progress <= 0.05) return;

    final paintBeam = Paint()
      ..color = const Color(0xFFFBBF24).withValues(
        alpha: 0.45 * (1.0 - progress * 0.3),
      )
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final paintSpark = Paint()
      ..color = const Color(0xFFA3E635).withValues(
        alpha: 0.70 * (0.8 + 0.2 * math.sin(ambient.value * math.pi)),
      )
      ..style = PaintingStyle.fill;

    // Draw 12 radial starlight rays expanding outward
    const rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi + (ambient.value * 0.15);
      final startR = 52.0 * progress;
      final endR = (75.0 + (i % 2 == 0 ? 30.0 : 15.0)) * progress;

      final startP = Offset(
        center.dx + startR * math.cos(angle),
        center.dy + startR * math.sin(angle),
      );
      final endP = Offset(
        center.dx + endR * math.cos(angle),
        center.dy + endR * math.sin(angle),
      );

      canvas.drawLine(startP, endP, paintBeam);

      // Draw sparkling diamond/circle tip
      if (progress > 0.4) {
        canvas.drawCircle(endP, 2.2 * progress, paintSpark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadiantStarlightPainter oldDelegate) => true;
}
