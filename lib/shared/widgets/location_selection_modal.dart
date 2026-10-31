import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/location_service.dart';
import '../providers/app_providers.dart';

class LocationSelectionModal extends ConsumerStatefulWidget {
  const LocationSelectionModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationSelectionModal(),
    );
  }

  @override
  ConsumerState<LocationSelectionModal> createState() => _LocationSelectionModalState();
}

class _LocationSelectionModalState extends ConsumerState<LocationSelectionModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cityController; 
  late TextEditingController _countryController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  bool _isDetectingGps = false;

  static const List<Map<String, String>> _popularCities = [
    {'city': 'New Delhi', 'country': 'India', 'lat': '28.6139', 'lng': '77.2090'},
    {'city': 'Mumbai', 'country': 'India', 'lat': '19.0760', 'lng': '72.8777'},
    {'city': 'Makkah', 'country': 'Saudi Arabia', 'lat': '21.4225', 'lng': '39.8262'},
    {'city': 'Madinah', 'country': 'Saudi Arabia', 'lat': '24.4672', 'lng': '39.6112'},
    {'city': 'London', 'country': 'UK', 'lat': '51.5074', 'lng': '-0.1278'},
    {'city': 'Dubai', 'country': 'UAE', 'lat': '25.2048', 'lng': '55.2708'},
    {'city': 'Karachi', 'country': 'Pakistan', 'lat': '24.8607', 'lng': '67.0011'},
    {'city': 'Dhaka', 'country': 'Bangladesh', 'lat': '23.8103', 'lng': '90.4125'},
    {'city': 'Istanbul', 'country': 'Turkey', 'lat': '41.0082', 'lng': '28.9784'},
  ];

  @override
  void initState() {
    super.initState();
    final currentLocation = ref.read(currentLocationProvider).value ?? LocationService.defaultLocation;
    _cityController = TextEditingController(text: currentLocation.city);
    _countryController = TextEditingController(text: currentLocation.country);
    _latController = TextEditingController(text: currentLocation.latitude.toStringAsFixed(4));
    _lngController = TextEditingController(text: currentLocation.longitude.toStringAsFixed(4));
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _detectGps() async {
    setState(() => _isDetectingGps = true);
    try {
      await ref.read(userLocationProvider.notifier).refreshFromGps();
      final updated = ref.read(currentLocationProvider).value;
      if (updated != null && mounted) {
        context.showSnackBar('Location updated from GPS!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Failed to get GPS location. Please enter manually.');
    } finally {
      if (mounted) setState(() => _isDetectingGps = false);
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final city = _cityController.text.trim();
      final country = _countryController.text.trim();
      final placeName = country.isNotEmpty ? '$city, $country' : city;

      double? lat = double.tryParse(_latController.text.trim());
      double? lng = double.tryParse(_lngController.text.trim());

      final locationService = ref.read(locationServiceProvider);

      // Fetch latitude & longitude of placeName using locationFromAddress
      final geocoded = await locationService.getCoordinatesFromPlace(placeName);
      double finalLat = LocationService.makkahLat;
      double finalLng = LocationService.makkahLng;

      if (geocoded != null) {
        finalLat = geocoded.latitude;
        finalLng = geocoded.longitude;
      } else if (lat != null && lng != null) {
        finalLat = lat;
        finalLng = lng; 
      }

      await ref.read(userLocationProvider.notifier).setCustomLocation(
            latitude: finalLat,
            longitude: finalLng,
            city: city,
            country: country,
          );

      if (mounted) {
        Navigator.of(context).pop();
        context.showSnackBar('Location updated to $city, $country!');
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Location updated!');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _selectPreset(Map<String, String> preset) {
    _cityController.text = preset['city']!;
    _countryController.text = preset['country']!;
    _latController.text = preset['lat']!;
    _lngController.text = preset['lng']!;
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    required bool isDark,
    required Color primaryColor,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(
        fontSize: 13.5,
        color: isDark ? Colors.white70 : const Color(0xFF64748B),
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white38 : Colors.grey.shade400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? primaryColor : const Color(0xFF2A531D),
        size: 20,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          color: primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Location & City Settings',
                    style: GoogleFonts.outfit(
                      fontSize: 18.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A3512),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // GPS Auto-detect Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isDetectingGps ? null : _detectGps,
                  icon: _isDetectingGps
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        )
                      : Icon(
                          Icons.my_location_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                  label: Text(
                    _isDetectingGps ? 'Detecting Location...' : 'Use Current Device GPS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : primaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF9FAFB),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'City & Country',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: isDark ? const Color(0xFF86EFAC) : primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'City',
                        hintText: 'e.g. Mysore',
                        prefixIcon: Icons.location_city_rounded,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter city' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'Country',
                        hintText: 'e.g. India',
                        prefixIcon: Icons.flag_rounded,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter country' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'Popular Preset Cities',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _popularCities.map((preset) {
                  final isSelected = _cityController.text.trim().toLowerCase() ==
                      preset['city']!.toLowerCase();
                  return ChoiceChip(
                    label: Text('${preset['city']!}, ${preset['country']!}'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? const Color(0xFF0F0F12) : Colors.white)
                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF1F5F9),
                    checkmarkColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
                    onSelected: (_) {
                      setState(() {
                        _selectPreset(preset);
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                      width: 1.0,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              Text(
                'Coordinates (Auto-resolved)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icons.explore_outlined,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icons.explore_outlined,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveLocation,
                  icon: _isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? const Color(0xFF0F0F12) : Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                          color: isDark ? const Color(0xFF0F0F12) : Colors.white,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Resolving Coordinates...'
                        : 'Save & Fetch Prayer Timings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF0F0F12) : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
