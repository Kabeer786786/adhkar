import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../widgets/app_action_popup_menu.dart';
import '../../../widgets/app_header_bar.dart';
import '../domain/models/sadqa_record.dart';
import 'providers/sadqa_provider.dart';
import 'widgets/add_sadqa_record_modal.dart';
import 'widgets/islamic_charity_info_modal.dart';
import 'widgets/online_donation_modal.dart';
import 'widgets/zakat_calculator_modal.dart';

import '../../../shared/widgets/feature_intro_modal.dart';

class SadqaScreen extends ConsumerStatefulWidget {
  const SadqaScreen({super.key});

  @override
  ConsumerState<SadqaScreen> createState() => _SadqaScreenState();
}

class _SadqaScreenState extends ConsumerState<SadqaScreen> {
  CharityType? _filterType;
  bool _isDonationBannerDismissed = false;
  final Set<String> _expandedRecordIds = <String>{};

  final currencyFormatter = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    _checkDonationBannerStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureIntroModal.show(context, FeatureIntroType.sadqa);
    });
  }

  Future<void> _checkDonationBannerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDonationBannerDismissed =
            prefs.getBool('online_donation_banner_dismissed') ?? false;
      });
    }
  }

  Future<void> _dismissDonationBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('online_donation_banner_dismissed', true);
    if (mounted) {
      setState(() {
        _isDonationBannerDismissed = true;
      });
    }
  }

  String _formatMoney(double amount, {String symbol = '₹'}) {
    final cleanSymbol = symbol.trim().isEmpty ? '' : '$symbol ';
    if (amount >= 10000000) {
      final v = amount / 10000000;
      final formatted = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
      return '$cleanSymbol${formatted}Cr';
    } else if (amount >= 100000) {
      final v = amount / 100000;
      final formatted = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
      return '$cleanSymbol${formatted}L';
    } else if (amount >= 10000) {
      final v = amount / 1000;
      final formatted = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
      return '$cleanSymbol${formatted}k';
    } else {
      return '$cleanSymbol${currencyFormatter.format(amount)}';
    }
  }

  void _openInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IslamicCharityInfoModal(),
    );
  }

  void _openCalculatorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ZakatCalculatorModal(),
    );
  }

  void _openAddModal(
    BuildContext context, {
    CharityType? defaultType,
    SadqaRecord? record,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddSadqaRecordModal(
          initialRecord: record,
          defaultType: defaultType,
          onSave: (newRecord) {
            if (record != null) {
              ref.read(sadqaRecordsProvider.notifier).updateRecord(newRecord);
            } else {
              ref.read(sadqaRecordsProvider.notifier).addRecord(newRecord);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final records = ref.watch(sadqaRecordsProvider);
    final zakatModel = ref.watch(zakatCalculatorProvider);

    // Compute Totals
    final totalSadaqah = records
        .where((r) => r.type == CharityType.sadaqah)
        .fold(0.0, (sum, r) => sum + r.amount);

    final totalZakat = records
        .where((r) => r.type == CharityType.zakat)
        .fold(0.0, (sum, r) => sum + r.amount);

    final filteredRecords = _filterType == null
        ? records
        : records.where((r) => r.type == _filterType).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF173a24), // Deep forest green matching Roza
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'Zakat & Sadaqah',
            showBackButton: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconColor: Colors.white,
            titleWidget: const Text(
              'Zakat & Sadaqah',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calculate_rounded, color: Colors.white),
                tooltip: 'Zakat Calculator',
                onPressed: () => _openCalculatorModal(context),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                tooltip: 'Islamic Guidelines & Benefits',
                onPressed: () => _openInfoModal(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
        floatingActionButton: filteredRecords.isEmpty
            ? null
            : FloatingActionButton(
                onPressed: () => _openAddModal(context),
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add_rounded,
                  size: 32,
                ),
              ),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Upper Half Container (Forest Green Summary Metrics & Banners)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Total Sadaqah Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF16A34A).withValues(alpha: 0.92),
                                  const Color(0xFF15803D).withValues(alpha: 0.92),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.volunteer_activism_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Total Sadaqah',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatMoney(totalSadaqah),
                                  style: GoogleFonts.oxanium(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Total Zakat Paid Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFEAB308).withValues(alpha: 0.92),
                                  const Color(0xFFD1820E).withValues(alpha: 0.92),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Zakat Paid',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatMoney(totalZakat),
                                  style: GoogleFonts.oxanium(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick Zakat Banner / Action Button
                    InkWell(
                      onTap: () => _openCalculatorModal(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calculate_rounded,
                                  color: Color(0xFFFACC15),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Zakat Payable:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      zakatModel.isNisabReached
                                          ? '${_formatMoney(zakatModel.zakatPayable)} (2.5%)'
                                          : 'Calculate Wealth Zakat',
                                      style: GoogleFonts.oxanium(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFACC15),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.white30,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (!_isDonationBannerDismissed) ...[
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          InkWell(
                            onTap: () => OnlineDonationModal.show(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2A531D),
                                    Color(0xFF458133),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.payment_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Online Donation',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Support App & Sadqa via Razorpay',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white.withValues(alpha: 0.85),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _dismissDonationBanner,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 2. Lower Half Sheet Container (Curved out with top Radius 32)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF192520) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 3 Centered Filter Buttons: All Logs, Sadaqah Only, Zakat Only
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 8, left: 16, right: 16),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131D18) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildFilterPill(
                                  label: 'All Logs',
                                  isSelected: _filterType == null,
                                  activeColor: const Color(0xFF173a24),
                                  onTap: () => setState(() => _filterType = null),
                                  isDark: isDark,
                                ),
                                _buildFilterPill(
                                  label: 'Sadaqah Only',
                                  isSelected: _filterType == CharityType.sadaqah,
                                  activeColor: const Color(0xFF16A34A),
                                  onTap: () => setState(() => _filterType = CharityType.sadaqah),
                                  isDark: isDark,
                                ),
                                _buildFilterPill(
                                  label: 'Zakat Only',
                                  isSelected: _filterType == CharityType.zakat,
                                  activeColor: const Color(0xFFD1820E),
                                  onTap: () => setState(() => _filterType = CharityType.zakat),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Transaction History Feed
                      Expanded(
                        child: filteredRecords.isEmpty
                            ? _buildEmptyState(context, isDark)
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 6,
                                  bottom: 90,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredRecords.length,
                                itemBuilder: (context, index) {
                                  final item = filteredRecords[index];
                                  return _buildRecordCard(context, item, isDark);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_rounded,
              size: 56,
              color: const Color(0xFF2A531D).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No Charity Payments Logged Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Track your voluntary Sadaqah & mandatory Zakat payments to stay organized and achieve spiritual blessings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A531D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Log First Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _openAddModal(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, SadqaRecord item, bool isDark) {
    final isExpanded = _expandedRecordIds.contains(item.id);
    final isSadaqah = item.type == CharityType.sadaqah;
    final badgeColor = isSadaqah ? const Color(0xFF16A34A) : const Color(0xFFD1820E);
    final iconData = isSadaqah
        ? Icons.volunteer_activism_rounded
        : Icons.account_balance_wallet_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23322B) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E4237) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedRecordIds.remove(item.id);
              } else {
                _expandedRecordIds.add(item.id);
              }
            });
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Circular Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconData,
                            color: badgeColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 2 Centered Rows: Category & (Recipient + Date)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Row 1: Category title without Sadaqah/Zakat badge
                              Text(
                                _getCategoryTitle(item.category),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Row 2: Recipient and Date
                              Row(
                                children: [
                                  if (item.recipient.isNotEmpty) ...[
                                    Flexible(
                                      child: Text(
                                        item.recipient,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: badgeColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Text(' • ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 11,
                                    color: isDark ? Colors.white54 : Colors.grey,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(item.date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Amount: Rightmost, sitting below the 3 dots at top-right
                        Padding(
                          padding: const EdgeInsets.only(top: 18, right: 2),
                          child: Text(
                            _formatMoney(item.amount, symbol: item.currency.isNotEmpty ? item.currency : '₹'),
                            style: GoogleFonts.oxanium(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Description/Note row shown when card is clicked
                    AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.note.isNotEmpty ? item.note : 'No description provided.',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                fontStyle: item.note.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),

          // 3 Dots at top right corner absolute (comes over the amount)
          Positioned(
            top: 2,
            right: 2,
            child: AppActionPopupMenu<String>(
              items: const [
                AppActionMenuItem(
                  value: 'edit',
                  title: 'Edit Record',
                  icon: Icons.edit_outlined,
                ),
                AppActionMenuItem(
                  value: 'delete',
                  title: 'Delete Record',
                  icon: Icons.delete_outline_rounded,
                  isDestructive: true,
                ),
              ],
              onSelected: (action) {
                if (action == 'edit') {
                  _openAddModal(context, record: item);
                } else if (action == 'delete') {
                  ref.read(sadqaRecordsProvider.notifier).deleteRecord(item.id);
                }
              },
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  String _getCategoryTitle(SadaqahCategory category) {
    switch (category) {
      case SadaqahCategory.general:
        return 'General Sadaqah';
      case SadaqahCategory.sadaqahJariyah:
        return 'Sadaqah Jariyah';
      case SadaqahCategory.foodClothing:
        return 'Food & Clothing';
      case SadaqahCategory.orphanSupport:
        return 'Orphan Support';
      case SadaqahCategory.medicalHelp:
        return 'Medical Support';
      case SadaqahCategory.education:
        return 'Education';
      case SadaqahCategory.mosqueCommunity:
        return 'Mosque & Community';
      case SadaqahCategory.zakatAlFitr:
        return 'Zakat al-Fitr';
      case SadaqahCategory.zakatAlMal:
        return 'Zakat al-Mal';
      case SadaqahCategory.other:
        return 'Other Charity';
    }
  }
}
