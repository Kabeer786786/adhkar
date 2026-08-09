import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../widgets/app_action_popup_menu.dart';
import '../../../widgets/app_header_bar.dart';
import '../domain/models/sadqa_record.dart';
import 'providers/sadqa_provider.dart';
import 'widgets/add_sadqa_record_modal.dart';
import 'widgets/islamic_charity_info_modal.dart';
import 'widgets/online_donation_modal.dart';
import 'widgets/zakat_calculator_modal.dart';

class SadqaScreen extends ConsumerStatefulWidget {
  const SadqaScreen({super.key});

  @override
  ConsumerState<SadqaScreen> createState() => _SadqaScreenState();
}

class _SadqaScreenState extends ConsumerState<SadqaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CharityType? _filterType;

  final currencyFormatter = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF173a24)
            : const Color(0xFFF3FAF2),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'Sadaqah & Zakat',
            showBackButton: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            backgroundColor: isDark
                ? const Color(0xFF192520)
                : const Color(0xFF173a24),
            iconColor: Colors.white,
            titleWidget: const Text(
              'Sadaqah & Zakat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                tooltip: 'Islamic Guidelines & Benefits',
                onPressed: () => _openInfoModal(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
        floatingActionButton: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFD1820E),
                Color(0xFFA16207),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _openCalculatorModal(context),
              customBorder: const CircleBorder(),
              child: const Center(
                child: Icon(
                  Icons.calculate_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
        child: Column(
          children: [
            // Top Summary Hero Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF192520)
                    : const Color(0xFF173a24),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Total Sadaqah Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF16A34A).withValues(alpha: 0.9),
                                const Color(0xFF15803D).withValues(alpha: 0.9),
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
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Total Sadaqah',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹ ${currencyFormatter.format(totalSadaqah)}',
                                style: GoogleFonts.oxanium(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Total Zakat Paid Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFEAB308).withValues(alpha: 0.9),
                                const Color(0xFFd1820e).withValues(alpha: 0.9),
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
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Zakat Paid',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹ ${currencyFormatter.format(totalZakat)}',
                                style: GoogleFonts.oxanium(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick Zakat Banner / Action Button
                  InkWell(
                    onTap: () => _openCalculatorModal(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
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
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Zakat Payable:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    zakatModel.isNisabReached
                                        ? '₹ ${currencyFormatter.format(zakatModel.zakatPayable)} (2.5%)'
                                        : 'Calculate Wealth Zakat',
                                    style: GoogleFonts.oxanium(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFACC15),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Row(
                            children: [
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Online Donation Banner Button (Razorpay Integration)
                  InkWell(
                    onTap: () => OnlineDonationModal.show(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2A531D),
                            const Color(0xFF458133),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.payment_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Online Donation',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Support App & Sadqa via Razorpay',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Navigation Tab Bar & Quick Add Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Sadaqah',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _openAddModal(
                        context,
                        defaultType: CharityType.sadaqah,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdfaa0a),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Zakat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _openAddModal(
                        context,
                        defaultType: CharityType.zakat,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Logs'),
                    selected: _filterType == null,
                    selectedColor: const Color(0xFF2A531D),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _filterType == null
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF2A531D)),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _filterType = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Sadaqah Only'),
                    selected: _filterType == CharityType.sadaqah,
                    selectedColor: const Color(0xFF16A34A),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _filterType == CharityType.sadaqah
                          ? Colors.white
                          : const Color(0xFF16A34A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) =>
                        setState(() => _filterType = CharityType.sadaqah),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Zakat Only'),
                    selected: _filterType == CharityType.zakat,
                    selectedColor: const Color(0xFFdfaa0a),
                    checkmarkColor: Colors.white, 
                    labelStyle: TextStyle(
                      color: _filterType == CharityType.zakat
                          ? Colors.white
                          : const Color(0xFFD1820E),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) =>
                        setState(() => _filterType = CharityType.zakat),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Transaction History Feed
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF192520) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: filteredRecords.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredRecords.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredRecords[index];
                          return _buildRecordCard(context, item, isDark);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.volunteer_activism_rounded,
            size: 64,
            color: const Color(0xFF2A531D).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
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
            padding: EdgeInsets.symmetric(horizontal: 40),
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
    );
  }

  Widget _buildRecordCard(BuildContext context, SadqaRecord item, bool isDark) {
    final isSadaqah = item.type == CharityType.sadaqah;
    final badgeColor = isSadaqah
        ? const Color(0xFF16A34A)
        : const Color(0xFFD1820E);

    return InkWell(
      onTap: () => _openAddModal(context, record: item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23322B) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSadaqah
                    ? Icons.volunteer_activism_rounded
                    : Icons.account_balance_wallet_rounded,
                color: badgeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSadaqah ? 'SADAQAH' : 'ZAKAT',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getCategoryTitle(item.category),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(item.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      if (item.recipient.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(color: Colors.grey)),
                        Expanded(
                          child: Text(
                            item.recipient,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2A531D),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.note.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.note,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Amount & Options
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.currency} ${currencyFormatter.format(item.amount)}',
                  style: GoogleFonts.oxanium(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
                AppActionPopupMenu<String>(
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
                      ref
                          .read(sadqaRecordsProvider.notifier)
                          .deleteRecord(item.id);
                    }
                  },
                ),
              ],
            ),
          ],
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
