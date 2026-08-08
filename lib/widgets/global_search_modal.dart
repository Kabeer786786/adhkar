import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/extensions/context_extensions.dart';

class SearchSuggestionItem {
  final String title;
  final String category;
  final IconData icon;
  final String route;

  const SearchSuggestionItem({
    required this.title,
    required this.category,
    required this.icon,
    required this.route,
  });
}

class GlobalSearchModal extends StatefulWidget {
  const GlobalSearchModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const GlobalSearchModal(),
    );
  }

  @override
  State<GlobalSearchModal> createState() => _GlobalSearchModalState();
}

class _GlobalSearchModalState extends State<GlobalSearchModal> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  static const List<SearchSuggestionItem> _allSuggestions = [
    SearchSuggestionItem(
      title: 'Prayer Times & Timetable',
      category: 'Prayer',
      icon: Icons.access_time_filled_rounded,
      route: '/prayer',
    ),
    SearchSuggestionItem(
      title: 'Salah Tracker & History',
      category: 'Prayer',
      icon: Icons.check_circle_rounded,
      route: '/prayer',
    ),
    SearchSuggestionItem(
      title: 'Qibla Finder Compass',
      category: 'Qibla',
      icon: Icons.explore_rounded,
      route: '/qibla',
    ),
    SearchSuggestionItem(
      title: 'Morning Adhkar',
      category: 'Adhkar',
      icon: Icons.wb_sunny_rounded,
      route: '/adhkar/detail?id=morning&title=Morning%20Adhkar',
    ),
    SearchSuggestionItem(
      title: 'Evening Adhkar',
      category: 'Adhkar',
      icon: Icons.nights_stay_rounded,
      route: '/adhkar/detail?id=evening&title=Evening%20Adhkar',
    ),
    SearchSuggestionItem(
      title: 'After Salah Duas & Adhkar',
      category: 'Adhkar',
      icon: Icons.mosque_rounded,
      route: '/adhkar/detail?id=salah&title=After%20Salah',
    ),
    SearchSuggestionItem(
      title: 'Before Sleep Adhkar',
      category: 'Adhkar',
      icon: Icons.bedtime_rounded,
      route: '/adhkar/detail?id=sleep&title=Before%20Sleep',
    ),
    SearchSuggestionItem(
      title: 'Digital Tasbeeh Counter',
      category: 'Tasbeeh',
      icon: Icons.touch_app_rounded,
      route: '/tasbeeh',
    ),
    SearchSuggestionItem(
      title: 'Surah Al-Fatiha',
      category: 'Quran',
      icon: Icons.menu_book_rounded,
      route: '/quran/surah?num=1&name=Al-Fatiha',
    ),
    SearchSuggestionItem(
      title: 'Surah Al-Baqarah',
      category: 'Quran',
      icon: Icons.menu_book_rounded,
      route: '/quran/surah?num=2&name=Al-Baqarah',
    ),
    SearchSuggestionItem(
      title: 'Surah Ya-Sin',
      category: 'Quran',
      icon: Icons.menu_book_rounded,
      route: '/quran/surah?num=36&name=Ya-Sin',
    ),
    SearchSuggestionItem(
      title: 'Surah Al-Kahf',
      category: 'Quran',
      icon: Icons.menu_book_rounded,
      route: '/quran/surah?num=18&name=Al-Kahf',
    ),
    SearchSuggestionItem(
      title: 'Settings & Calculation Methods',
      category: 'Settings',
      icon: Icons.settings_rounded,
      route: '/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allSuggestions.where((item) {
      return item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.category.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 16, right: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 480),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Text Field Bar
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (val) {
                setState(() {
                  _query = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Surahs, Adhkar, Qibla, Prayer...',
                prefixIcon: Icon(Icons.search_rounded, color: context.colorScheme.primary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // Suggestions List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No features found for "$_query"',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            context.push(item.route);
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: context.colorScheme.primary, size: 20),
                          ),
                          title: Text(
                            item.title,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            item.category,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
