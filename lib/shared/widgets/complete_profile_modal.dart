import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/country_code.dart';
import '../../core/services/location_service.dart';
import '../../features/auth/presentation/widgets/country_code_picker_modal.dart';
import '../providers/app_providers.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/app_floating_toast.dart';

class CompleteProfileModal extends ConsumerStatefulWidget {
  const CompleteProfileModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CompleteProfileModal(),
    );
  }

  @override
  ConsumerState<CompleteProfileModal> createState() =>
      _CompleteProfileModalState();
}

class _CompleteProfileModalState extends ConsumerState<CompleteProfileModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  CountryCode _selectedCountry = CountryCode.defaultCountry;
  bool _isFetchingLocation = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Record that the modal was shown so it will not popup again within the 3-day cooldown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(storageServiceProvider).recordRegistrationPromptDate();
      } catch (_) {}
    });

    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);

    // Extract raw phone number if country code exists
    String rawPhone = profile.phone;
    if (rawPhone.contains(' ')) {
      final parts = rawPhone.split(' ');
      if (parts.length > 1) {
        rawPhone = parts.sublist(1).join(' ');
      }
    }
    _phoneController = TextEditingController(text: rawPhone);
    _locationController = TextEditingController(text: profile.location);

    if (_locationController.text.isEmpty) {
      _autoFetchLocation();
    }
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
    setState(() => _isFetchingLocation = true);

    try {
      final locationData = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _locationController.text = locationData.fullAddress;
        });

        await ref
            .read(userLocationProvider.notifier)
            .setCustomLocation(
              latitude: locationData.latitude,
              longitude: locationData.longitude,
              city: locationData.city,
              country: locationData.country,
            );
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phoneNum = _phoneController.text.trim();
    final fullPhone = '${_selectedCountry.dialCode} $phoneNum';
    final location = _locationController.text.trim().isNotEmpty
        ? _locationController.text.trim()
        : 'Unknown Location';

    setState(() => _isSaving = true);

    try {
      await ref
          .read(userProfileProvider.notifier)
          .registerUser(
            name: name,
            email: email,
            phone: fullPhone,
            location: location,
          );

      if (mounted) {
        Navigator.pop(context);
        AppFloatingToast.showSuccess(
          context,
          message: 'Profile saved successfully',
        );
      }
    } catch (e) {
      // Even if remote sync fails, persist locally so user is never asked again once filled
      await ref
          .read(userProfileProvider.notifier)
          .saveProfile(
            name: name,
            email: email,
            phone: fullPhone,
            location: location,
            registrationCompleted: true,
          );
      if (mounted) {
        Navigator.pop(context);
        AppFloatingToast.showSuccess(
          context,
          message: 'Profile saved successfully',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    InputDecoration inputDecoration({
      required String labelText,
      required String hintText,
      required IconData prefixIcon,
    }) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
            width: 1.8,
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),

                // Icon Badge & Title
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFF3FAF2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3F3F46)
                          : const Color(0xFF2A531D).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF2A531D),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'Complete Your Profile',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  'Quick one-time registration to personalize your Islamic experience. No password or login required!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 20),

                // Full Name Input
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  cursorColor: isDark
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFF2A531D),
                  decoration: inputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Shaik Kabeer',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Email Address Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  cursorColor: isDark
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFF2A531D),
                  decoration: inputDecoration(
                    labelText: 'Email Address',
                    hintText: 'name@example.com',
                    prefixIcon: Icons.email_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    final trimmed = val.trim();
                    if (!RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    ).hasMatch(trimmed)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Phone Number Input
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _showCountryPicker,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F0F12)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCountry.flag,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCountry.dialCode,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: isDark ? Colors.white70 : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        cursorColor: isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF2A531D),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF4B5563),
                          ),
                          hintText: '9876543210',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F0F12)
                              : const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF27272A)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF27272A)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF2A531D),
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          final digitsOnly = val.replaceAll(RegExp(r'\s+'), '');
                          if (!RegExp(r'^[0-9]{7,15}$').hasMatch(digitsOnly)) {
                            return 'Enter a valid 7-15 digit phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Save Primary Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF18A74C)
                          : const Color(0xFF2A531D),
                      foregroundColor: isDark
                          ? const Color(0xFF0F0F12)
                          : Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: isDark
                                  ? const Color(0xFF0F0F12)
                                  : Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Save Profile',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.check_rounded, size: 17),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                // Skip / Dismiss Text Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Skip for Now',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
