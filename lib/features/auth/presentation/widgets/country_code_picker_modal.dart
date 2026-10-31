import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/country_code.dart';

class CountryCodePickerModal extends StatefulWidget {
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode> onSelect;

  const CountryCodePickerModal({
    super.key,
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<CountryCodePickerModal> createState() => _CountryCodePickerModalState();
}

class _CountryCodePickerModalState extends State<CountryCodePickerModal> {
  final _searchController = TextEditingController();
  List<CountryCode> _filteredCountries = CountryCode.allCountries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = CountryCode.allCountries;
      } else {
        _filteredCountries = CountryCode.allCountries.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.dialCode.contains(query) ||
              c.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Country Code',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              cursorColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
              decoration: InputDecoration(
                hintText: 'Search country or code (e.g. India, +91)...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF4FAF3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF27272A) : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Country List
          Expanded(
            child: _filteredCountries.isEmpty
                ? Center(
                    child: Text(
                      'No countries found',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _filteredCountries.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark ? const Color(0xFF27272A) : Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      final isSelected = country.code == widget.selectedCountry.code;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isSelected
                            ? (isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFF2A531D).withValues(alpha: 0.08))
                            : null,
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 26),
                        ),
                        title: Text(
                          country.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D))
                                : (isDark ? Colors.white : const Color(0xFF1F2937)),
                          ),
                        ),
                        trailing: Text(
                          '${country.code} (${country.dialCode})',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D))
                                : (isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                        ),
                        onTap: () {
                          widget.onSelect(country);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
