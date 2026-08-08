import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    {'city': 'Makkah', 'country': 'Saudi', 'lat': '21.4225', 'lng': '39.8262'},
    {'city': 'Madinah', 'country': 'Saudi', 'lat': '24.4672', 'lng': '39.6112'},
    {'city': 'Mysore', 'country': 'India', 'lat': '12.2958', 'lng': '76.6394'},
    {'city': 'London', 'country': 'UK', 'lat': '51.5074', 'lng': '-0.1278'},
    {'city': 'Dubai', 'country': 'UAE', 'lat': '25.2048', 'lng': '55.2708'},
    {'city': 'Karachi', 'country': 'Pakistan', 'lat': '24.8607', 'lng': '67.0011'},
    {'city': 'New York', 'country': 'US', 'lat': '40.7128', 'lng': '-74.0060'},
    {'city': 'Istanbul', 'country': 'Turkey', 'lat': '41.0082', 'lng': '28.9784'},
    {'city': 'Jakarta', 'country': 'Indonesia', 'lat': '-6.2088', 'lng': '106.8456'},
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                    style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
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
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(_isDetectingGps ? 'Detecting Location...' : 'Use Current Device GPS'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'City & Country',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City (e.g. Mysore)',
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter city' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'Country (e.g. India)',
                        prefixIcon: const Icon(Icons.flag_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter country' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'Popular Preset Cities',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: _popularCities.map((preset) {
                  final isSelected = _cityController.text.trim().toLowerCase() == preset['city']!.toLowerCase();
                  return ChoiceChip(
                    label: Text('${preset['city']!}, ${preset['country']!}'),
                    selected: isSelected,
                    onSelected: (_) => _selectPreset(preset),
                    side: BorderSide(
                      color: isSelected
                          ? context.colorScheme.primary
                          : context.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  );
                }).toList(), 
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveLocation,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_isSaving ? 'Resolving Coordinates...' : 'Save & Fetch AlAdhan Timings'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
