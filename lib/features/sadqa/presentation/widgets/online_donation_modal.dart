import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

    // Calls RazorpayDonationService via Supabase Edge Functions
    _razorpayService.processDonation(
      amount: amount,
      currency: _selectedCurrency,
      name: name,
      email: email,
      phone: phone,
      onSuccess: (paymentId, orderId, signature) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

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

        Navigator.pop(context);

        // Show JazakAllah Khair Blessing & Receipt Modal
        _showSuccessDialog(
          amount: amount,
          currency: _selectedCurrency,
          paymentId: paymentId,
          orderId: orderId,
        );
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

  void _showSuccessDialog({
    required double amount,
    required String currency,
    required String paymentId,
    required String orderId,
  }) {
    final symbol = currency == 'INR' ? '₹' : '\$';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4FAF3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 54,
                color: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'JazakAllah Khair!',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'May Allah reward your generous Sadqa abundantly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount Paid:',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '$symbol${amount.toStringAsFixed(0)} $currency',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A531D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color:  Colors.grey.shade300,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Txn ID:',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            paymentId,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

              // Donor Details Section (Allows user to provide name, email, phone if missing or edit them)
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
