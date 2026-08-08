import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/models/sadqa_record.dart';
import '../../domain/models/zakat_calculator_model.dart';
import '../providers/sadqa_provider.dart';
import 'add_sadqa_record_modal.dart';

class ZakatCalculatorModal extends ConsumerStatefulWidget {
  const ZakatCalculatorModal({super.key});

  @override
  ConsumerState<ZakatCalculatorModal> createState() => _ZakatCalculatorModalState();
}

class _ZakatCalculatorModalState extends ConsumerState<ZakatCalculatorModal> {
  late TextEditingController _cashController;
  late TextEditingController _goldGramsController;
  late TextEditingController _goldPriceController;
  late TextEditingController _silverGramsController;
  late TextEditingController _silverPriceController;
  late TextEditingController _investmentsController;
  late TextEditingController _businessGoodsController;
  late TextEditingController _moneyOwedController;
  late TextEditingController _liabilitiesController;

  final currencyFormatter = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    final model = ref.read(zakatCalculatorProvider);
    _cashController = TextEditingController(
      text: model.cashAndBank > 0 ? model.cashAndBank.toStringAsFixed(0) : '',
    );
    _goldGramsController = TextEditingController(
      text: model.goldGrams > 0 ? model.goldGrams.toStringAsFixed(0) : '',
    );
    _goldPriceController = TextEditingController(
      text: model.goldPricePerGram.toStringAsFixed(0),
    );
    _silverGramsController = TextEditingController(
      text: model.silverGrams > 0 ? model.silverGrams.toStringAsFixed(0) : '',
    );
    _silverPriceController = TextEditingController(
      text: model.silverPricePerGram.toStringAsFixed(0),
    );
    _investmentsController = TextEditingController(
      text: model.investments > 0 ? model.investments.toStringAsFixed(0) : '',
    );
    _businessGoodsController = TextEditingController(
      text: model.businessGoods > 0 ? model.businessGoods.toStringAsFixed(0) : '',
    );
    _moneyOwedController = TextEditingController(
      text: model.moneyOwedToYou > 0 ? model.moneyOwedToYou.toStringAsFixed(0) : '',
    );
    _liabilitiesController = TextEditingController(
      text: model.liabilities > 0 ? model.liabilities.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _goldGramsController.dispose();
    _goldPriceController.dispose();
    _silverGramsController.dispose();
    _silverPriceController.dispose();
    _investmentsController.dispose();
    _businessGoodsController.dispose();
    _moneyOwedController.dispose();
    _liabilitiesController.dispose();
    super.dispose();
  }

  void _onValuesChanged() {
    final current = ref.read(zakatCalculatorProvider);
    final updated = current.copyWith(
      cashAndBank: double.tryParse(_cashController.text) ?? 0.0,
      goldGrams: double.tryParse(_goldGramsController.text) ?? 0.0,
      goldPricePerGram: double.tryParse(_goldPriceController.text) ?? 7500.0,
      silverGrams: double.tryParse(_silverGramsController.text) ?? 0.0,
      silverPricePerGram: double.tryParse(_silverPriceController.text) ?? 90.0,
      investments: double.tryParse(_investmentsController.text) ?? 0.0,
      businessGoods: double.tryParse(_businessGoodsController.text) ?? 0.0,
      moneyOwedToYou: double.tryParse(_moneyOwedController.text) ?? 0.0,
      liabilities: double.tryParse(_liabilitiesController.text) ?? 0.0,
    );
    ref.read(zakatCalculatorProvider.notifier).updateState(updated);
  }

  void _recordAsPaidZakat(double amount, String currency) {
    final nav = Navigator.of(context);
    nav.pop();
    Future.microtask(() {
      if (nav.context.mounted) {
        showModalBottomSheet(
          context: nav.context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (modalContext) {
            return Consumer(
              builder: (context, ref, child) {
                return AddSadqaRecordModal(
                  defaultType: CharityType.zakat,
                  defaultAmount: amount,
                  onSave: (record) {
                    ref.read(sadqaRecordsProvider.notifier).addRecord(record);
                  },
                );
              },
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final model = ref.watch(zakatCalculatorProvider);
    final symbol = model.currencySymbol;

    return Container(
      height: MediaQuery.of(context).size.height * 0.89,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192520) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calculate_rounded,
                    color: Color(0xFFD97724),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zakat Calculator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
                        ),
                      ),
                      Text(
                        'Calculate 2.5% Zakat on net eligible wealth',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Form Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                // Nisab Benchmark Selector Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF23322B) : const Color(0xFFF3FAF2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF2A531D).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nisab Standard',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select benchmark threshold (Silver Nisab is recommended as it benefits more poor people):',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Silver Nisab (612.36g)'),
                              selected: model.nisabStandard == NisabStandard.silver,
                              selectedColor: const Color(0xFF2A531D),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: model.nisabStandard == NisabStandard.silver
                                    ? Colors.white
                                    : const Color(0xFF2A531D),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  ref.read(zakatCalculatorProvider.notifier).updateState( 
                                        model.copyWith(nisabStandard: NisabStandard.silver),
                                      );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Gold Nisab (87.48g)'),
                              selected: model.nisabStandard == NisabStandard.gold,
                              selectedColor: const Color(0xFFEAB308),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: model.nisabStandard == NisabStandard.gold
                                    ? Colors.white
                                    : const Color(0xFFEAB308),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  ref.read(zakatCalculatorProvider.notifier).updateState(
                                        model.copyWith(nisabStandard: NisabStandard.gold),
                                      );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Cash & Savings
                _buildSectionHeader('1. Cash & Bank Balances', Icons.account_balance_rounded),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _cashController,
                  label: 'Cash in Hand, Bank Balances & Fixed Deposits',
                  symbol: symbol,
                  isDark: isDark,
                  onChanged: (_) => _onValuesChanged(),
                ),
                const SizedBox(height: 18),

                // Section 2: Gold & Silver
                _buildSectionHeader('2. Gold & Silver Assets', Icons.workspace_premium_rounded),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _goldGramsController,
                        label: 'Gold Owned (Grams)',
                        symbol: 'g',
                        isDark: isDark,
                        onChanged: (_) => _onValuesChanged(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInputField(
                        controller: _goldPriceController,
                        label: 'Gold Price / Gram',
                        symbol: symbol,
                        isDark: isDark,
                        onChanged: (_) => _onValuesChanged(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _silverGramsController,
                        label: 'Silver Owned (Grams)',
                        symbol: 'g',
                        isDark: isDark,
                        onChanged: (_) => _onValuesChanged(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInputField(
                        controller: _silverPriceController,
                        label: 'Silver Price / Gram',
                        symbol: symbol,
                        isDark: isDark,
                        onChanged: (_) => _onValuesChanged(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Section 3: Investments & Business
                _buildSectionHeader('3. Investments & Business Merchandise', Icons.show_chart_rounded),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _investmentsController,
                  label: 'Stocks, Mutual Funds, Crypto & Investments',
                  symbol: symbol,
                  isDark: isDark,
                  onChanged: (_) => _onValuesChanged(),
                ),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _businessGoodsController,
                  label: 'Business Inventory & Trade Goods Value',
                  symbol: symbol,
                  isDark: isDark,
                  onChanged: (_) => _onValuesChanged(),
                ),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _moneyOwedController,
                  label: 'Loans Given Out (Money Owed to You)',
                  symbol: symbol,
                  isDark: isDark,
                  onChanged: (_) => _onValuesChanged(),
                ),
                const SizedBox(height: 18),

                // Section 4: Liabilities & Deductions
                _buildSectionHeader('4. Liabilities & Debts Owed', Icons.money_off_rounded),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _liabilitiesController,
                  label: 'Short-term Debts, Bills & Liabilities Owed Now',
                  symbol: symbol,
                  isDark: isDark,
                  onChanged: (_) => _onValuesChanged(),
                ),
                const SizedBox(height: 24),

                // Summary & Result Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: model.isNisabReached
                          ? [const Color(0xFF15803D), const Color(0xFF2A531D)]
                          : [const Color(0xFF374151), const Color(0xFF1F2937)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (model.isNisabReached ? const Color(0xFF15803D) : Colors.black)
                            .withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Gross Zakatable Wealth:',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          Text(
                            '$symbol ${currencyFormatter.format(model.grossZakatableAssets)}',
                            style: GoogleFonts.oxanium(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Liabilities Deducted:',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          Text(
                            '- $symbol ${currencyFormatter.format(model.liabilities)}',
                            style: GoogleFonts.oxanium(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFCA5A5),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Net Zakatable Assets:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$symbol ${currencyFormatter.format(model.netZakatableAssets)}',
                            style: GoogleFonts.oxanium(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFACC15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nisab Threshold (${model.nisabStandard.name.toUpperCase()}):',
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                          Text(
                            '$symbol ${currencyFormatter.format(model.nisabThreshold)}',
                            style: GoogleFonts.oxanium(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              model.isNisabReached
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              color: model.isNisabReached
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFDE047),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                model.isNisabReached
                                    ? 'Nisab Reached! Zakat is mandatory.'
                                    : 'Below Nisab. Zakat is not mandatory.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: model.isNisabReached
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFFFDE047),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Zakat Payable Amount Display
                      const Text(
                        'Total Zakat Payable (2.5%):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$symbol ${currencyFormatter.format(model.zakatPayable)}',
                        style: GoogleFonts.oxanium(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Record Button
                      if (model.zakatPayable > 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFACC15),
                              foregroundColor: const Color(0xFF78350F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            label: const Text(
                              'Record as Paid Zakat',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              _recordAsPaidZakat(model.zakatPayable, symbol);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2A531D)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A531D),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String symbol,
    required bool isDark,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: '0',
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Text(
                symbol,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A531D),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: isDark ? const Color(0xFF23322B) : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
