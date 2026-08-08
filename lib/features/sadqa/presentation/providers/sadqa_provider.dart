import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../domain/models/sadqa_record.dart';
import '../../domain/models/zakat_calculator_model.dart';

const String _sadqaRecordsStorageKey = 'sadqa_zakat_records';
const String _zakatCalculatorStorageKey = 'zakat_calculator_state';

class SadqaRecordsNotifier extends StateNotifier<List<SadqaRecord>> {
  final StorageService _storage;

  SadqaRecordsNotifier(this._storage) : super([]) {
    _loadRecords();
  }

  void _loadRecords() {
    try {
      final savedData = _storage.getSavedSadqaRecords();
      if (savedData != null) {
        final records = savedData.map((e) => SadqaRecord.fromJson(e)).toList();
        records.sort((a, b) => b.date.compareTo(a.date));
        state = records;
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addRecord(SadqaRecord record) async {
    final updated = [record, ...state];
    updated.sort((a, b) => b.date.compareTo(a.date));
    state = updated;
    await _saveToStorage();
  }

  Future<void> updateRecord(SadqaRecord record) async {
    state = state.map((r) => r.id == record.id ? record : r).toList();
    await _saveToStorage();
  }

  Future<void> deleteRecord(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    final jsonList = state.map((r) => r.toJson()).toList();
    await _storage.saveSadqaRecords(jsonList);
  }
}

class ZakatCalculatorNotifier extends StateNotifier<ZakatCalculatorModel> {
  final StorageService _storage;

  ZakatCalculatorNotifier(this._storage) : super(const ZakatCalculatorModel()) {
    _loadSavedState();
  }

  void _loadSavedState() {
    try {
      final savedData = _storage.getSavedZakatCalcState();
      if (savedData != null) {
        state = ZakatCalculatorModel.fromJson(savedData);
      }
    } catch (_) {}
  }

  void updateState(ZakatCalculatorModel updated) {
    state = updated;
    _saveState();
  }

  void reset() {
    state = const ZakatCalculatorModel();
    _saveState();
  }

  Future<void> _saveState() async {
    await _storage.saveZakatCalcState(state.toJson());
  }
}

final sadqaRecordsProvider =
    StateNotifierProvider<SadqaRecordsNotifier, List<SadqaRecord>>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return SadqaRecordsNotifier(storage);
    });

final zakatCalculatorProvider =
    StateNotifierProvider<ZakatCalculatorNotifier, ZakatCalculatorModel>((
      ref,
    ) {
      final storage = ref.watch(storageServiceProvider);
      return ZakatCalculatorNotifier(storage);
    });

/// Extension on StorageService to support Sadqa & Zakat persistence
extension SadqaStorageExtensions on StorageService {
  List<Map<String, dynamic>>? getSavedSadqaRecords() {
    final data = getGenericData(_sadqaRecordsStorageKey);
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<void> saveSadqaRecords(List<Map<String, dynamic>> records) async {
    await saveGenericData(_sadqaRecordsStorageKey, records);
  }

  Map<String, dynamic>? getSavedZakatCalcState() {
    final data = getGenericData(_zakatCalculatorStorageKey);
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> saveZakatCalcState(Map<String, dynamic> stateMap) async {
    await saveGenericData(_zakatCalculatorStorageKey, stateMap);
  }
}
