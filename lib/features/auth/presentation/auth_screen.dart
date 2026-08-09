import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/country_code.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/providers/user_profile_provider.dart';
import '../../../../core/utils/error_formatter.dart';
import 'widgets/country_code_picker_modal.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  CountryCode _selectedCountry = CountryCode.defaultCountry; // Default IN +91

  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState(); 
    _autoFetchLocation();
  } 

  @override
  void dispose() { 
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _autoFetchLocation() async {
    if (_isFetchingLocation) return;
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final locationData = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _locationController.text = locationData.fullAddress;
        });

        await ref.read(userLocationProvider.notifier).setCustomLocation(
              latitude: locationData.latitude,
              longitude: locationData.longitude,
              city: locationData.city,
              country: locationData.country,
            );
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountryCodePickerModal(
        selectedCountry: _selectedCountry,
        onSelect: (country) {
          setState(() {
            _selectedCountry = country;
          });
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phoneNum = _phoneController.text.trim();
    final fullPhone = '${_selectedCountry.dialCode} $phoneNum';
    final location = _locationController.text.trim().isNotEmpty
        ? _locationController.text.trim()
        : 'Unknown Location';

    try {
      await ref.read(userProfileProvider.notifier).signUpWithEmail(
            name: name,
            email: email,
            phone: fullPhone,
            location: location,
          );

      if (mounted) {
        context.go('/verify-email?email=${Uri.encodeComponent(email)}');
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Complete Registration',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Header Title
                Text(
                  'User Information',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please fill in your details to validate your email and continue.',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Full Name
                _buildLabel('Full Name *'),
                SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      hint: 'e.g. Ahmad Khan',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Email Address
                _buildLabel('Email Address *'),
                SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hint: 'e.g. ahmad@example.com',
                      icon: Icons.email_outlined,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Phone Number with Country Code Selector
                _buildLabel('Phone Number *'),
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      // Country Code Selector
                      InkWell(
                        onTap: _showCountryPicker,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedCountry.flag,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedCountry.dialCode,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Phone Input
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration(
                            hint: '9876543210',
                            icon: Icons.phone_outlined,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter phone number';
                            }
                            if (val.trim().length < 6) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Current Location with Auto Detect Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Current Location *'),
                    InkWell(
                      onTap: _isFetchingLocation ? null : _autoFetchLocation,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Row(
                          children: [
                            _isFetchingLocation
                                ? const SizedBox(
                                    width: 13,
                                    height: 13,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2A531D)),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 14, color: Color(0xFF2A531D)),
                            const SizedBox(width: 4),
                            Text(
                              _isFetchingLocation ? 'Detecting...' : 'Auto Detect',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2A531D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _locationController,
                    decoration: _inputDecoration(
                      hint: 'e.g. Mumbai, Maharashtra, India',
                      icon: Icons.location_on_outlined,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your location';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: profileState.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A531D),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF2A531D).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: profileState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Save & Validate Email',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(
        fontSize: 13.5,
        color: Colors.grey.shade400,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF2A531D), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2A531D), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }
}
