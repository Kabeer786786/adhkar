import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/providers/user_profile_provider.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../domain/models/sadqa_record.dart';

class AddSadqaRecordModal extends ConsumerStatefulWidget {
  final SadqaRecord? initialRecord;
  final CharityType? defaultType;
  final double? defaultAmount;
  final Function(SadqaRecord record) onSave;

  const AddSadqaRecordModal({
    super.key,
    this.initialRecord,
    this.defaultType,
    this.defaultAmount,
    required this.onSave,
  });

  @override
  ConsumerState<AddSadqaRecordModal> createState() => _AddSadqaRecordModalState();
}

class _AddSadqaRecordModalState extends ConsumerState<AddSadqaRecordModal> {
  final _formKey = GlobalKey<FormState>();
  late CharityType _type;
  late SadaqahCategory _category;
  late TextEditingController _amountController;
  late TextEditingController _recipientController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final rec = widget.initialRecord;
    _type = rec?.type ?? widget.defaultType ?? CharityType.sadaqah;
    _category = rec?.category ??
        (_type == CharityType.zakat
            ? SadaqahCategory.zakatAlMal
            : SadaqahCategory.general);
    _amountController = TextEditingController(
      text: rec != null
          ? rec.amount.toStringAsFixed(0)
          : (widget.defaultAmount != null
                ? widget.defaultAmount!.toStringAsFixed(0)
                : ''),
    );
    _recipientController = TextEditingController(text: rec?.recipient ?? '');
    _noteController = TextEditingController(text: rec?.note ?? '');
    _selectedDate = rec?.date ?? DateTime.now();

    final userLoc = ref.read(userProfileProvider).location.toLowerCase();
    final gpsLoc = ref.read(currentLocationProvider).value;
    final combinedLoc = '$userLoc ${gpsLoc?.country ?? ''} ${gpsLoc?.city ?? ''}'.toLowerCase();

    if (rec != null) {
      _currency = rec.currency;
    } else if (combinedLoc.contains('usa') || combinedLoc.contains('united states') || combinedLoc.contains('america') || combinedLoc.contains('usd')) {
      _currency = '\$';
    } else {
      _currency = '₹';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final record = SadqaRecord(
        id: widget.initialRecord?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        type: _type,
        category: _category,
        amount: amount,
        currency: _currency,
        date: _selectedDate,
        recipient: _recipientController.text.trim(),
        note: _noteController.text.trim(),
      );
      widget.onSave(record);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_type == CharityType.zakat ? 'Zakat added' : 'Sadaqah added'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A531D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192520) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialRecord != null
                        ? 'Edit Record'
                        : 'Record Payment',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A531D),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Charity Type Segmented Switch (Sadaqah vs Zakat)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23322B) : const Color(0xFFF3FAF2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = CharityType.sadaqah;
                            _category = SadaqahCategory.general;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == CharityType.sadaqah
                                ? const Color(0xFF16A34A)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.volunteer_activism_rounded,
                                  size: 16,
                                  color: _type == CharityType.sadaqah
                                      ? Colors.white
                                      : const Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sadaqah (Sadqa)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _type == CharityType.sadaqah
                                        ? Colors.white
                                        : const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = CharityType.zakat;
                            _category = SadaqahCategory.zakatAlMal;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == CharityType.zakat
                                ? const Color(0xFFEAB308)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 16,
                                  color: _type == CharityType.zakat
                                      ? Colors.white
                                      : const Color(0xFFEAB308),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Zakat (Obligatory)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _type == CharityType.zakat
                                        ? Colors.white
                                        : const Color(0xFFEAB308),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Selector
              AppDropdown<SadaqahCategory>(
                label: 'Category',
                value: _category,
                onAddCustomCategory: () async {
                  final newCatName = await AppDropdown.showAddCustomCategoryDialog(
                    context,
                    title: 'Add Custom Category',
                    hintText: 'e.g. Water Well Project',
                    icon: Icons.favorite_border_rounded,
                  );
                  if (newCatName != null && newCatName.isNotEmpty) {
                    ref.read(storageServiceProvider).saveCustomCategory('sadqa', newCatName);
                    setState(() {
                      _category = SadaqahCategory.other;
                      if (_noteController.text.isEmpty) {
                        _noteController.text = newCatName;
                      }
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added custom category: $newCatName')),
                      );
                    }
                  }
                  return newCatName;
                },
                items: _type == CharityType.sadaqah
                    ? const [
                        AppDropdownItem(value: SadaqahCategory.general, label: 'General Sadaqah', icon: Icons.volunteer_activism_rounded),
                        AppDropdownItem(value: SadaqahCategory.sadaqahJariyah, label: 'Sadaqah Jariyah (Continuous)', icon: Icons.all_inclusive_rounded),
                        AppDropdownItem(value: SadaqahCategory.foodClothing, label: 'Food & Clothing', icon: Icons.shopping_bag_outlined),
                        AppDropdownItem(value: SadaqahCategory.orphanSupport, label: 'Orphan Support', icon: Icons.child_care_rounded),
                        AppDropdownItem(value: SadaqahCategory.medicalHelp, label: 'Medical Help', icon: Icons.local_hospital_outlined),
                        AppDropdownItem(value: SadaqahCategory.education, label: 'Education & Books', icon: Icons.school_outlined),
                        AppDropdownItem(value: SadaqahCategory.mosqueCommunity, label: 'Mosque & Community', icon: Icons.mosque_rounded),
                        AppDropdownItem(value: SadaqahCategory.other, label: 'Other', icon: Icons.more_horiz_rounded),
                      ]
                    : const [
                        AppDropdownItem(value: SadaqahCategory.zakatAlMal, label: 'Zakat al-Mal (Annual Wealth)', icon: Icons.account_balance_wallet_outlined),
                        AppDropdownItem(value: SadaqahCategory.zakatAlFitr, label: 'Zakat al-Fitr (Fitrana)', icon: Icons.rice_bowl_outlined),
                        AppDropdownItem(value: SadaqahCategory.other, label: 'Other Zakat', icon: Icons.more_horiz_rounded),
                      ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _category = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              // Amount Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8C6D53),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 1000',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Text(
                          _currency,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                        ),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF23322B)
                          : const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter amount';
                            }
                            if (double.tryParse(val.trim()) == null) {
                              return 'Valid number required';
                            }
                            return null;
                          },
                        ),
                ],
              ),
              const SizedBox(height: 14),

              // Date Picker Field
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8C6D53),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF23322B)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: Color(0xFF2A531D),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Recipient / Cause
              const Text(
                'Recipient / Cause (Optional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8C6D53),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  hintText: 'e.g. Local Mosque, Needy Neighbor, Orphanage',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF23322B)
                      : const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Notes / Comments
              const Text(
                'Note / Intention (Optional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8C6D53),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add notes or intention details...',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF23322B)
                      : const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A531D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _submit,
                  child: Text(
                    widget.initialRecord != null
                        ? 'Update Record'
                        : 'Save Charity Record',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
