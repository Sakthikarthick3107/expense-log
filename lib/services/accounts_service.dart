import 'package:expense_log/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/account.dart';

class AccountsService extends ChangeNotifier {
  static const String boxName = 'accountsBox';
  Box<Account>? _box;

  bool get isInitialized => _box != null && _box!.isOpen;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(AccountAdapter().typeId)) {
      Hive.registerAdapter(AccountAdapter());
    }
    _box = await Hive.openBox<Account>(boxName);
    notifyListeners();
  }

  // safe getter returns empty list when not initialized
  List<Account> get all => isInitialized ? _box!.values.toList() : [];

  // get account by id (works if stored id is int or String)
  Account? getById(dynamic id) {
    if (!isInitialized) return null;
    final sid = id?.toString();
    try {
      return _box!.values.cast<Account?>().firstWhere((a) => a?.id.toString() == sid);
    } catch (e) {
      return null;
    }
  }

  /// Create account with uniqueness checks on name and code.
  /// Returns created Account id, or throws Exception on duplicate.
  Future<String> create(String name, String code, {String? description,String? smsSyncKeyword}) async {
    if (!isInitialized) await init();

    final existsName = _box!.values.any((a) => a.name.toLowerCase() == name.toLowerCase());
    if (existsName) throw Exception('Account name already exists');

    final existsCode = _box!.values.any((a) => a.code.toLowerCase() == code.toLowerCase());
    if (existsCode) throw Exception('Account code already exists');

    final settingsSvc = SettingsService();
    final keyRaw = await settingsSvc.getBoxKey(boxName); // await the Future
    int id;
    if (keyRaw is int) {
      id = keyRaw;
    } else {
      id = int.tryParse(keyRaw.toString()) ?? DateTime.now().millisecondsSinceEpoch;
    }

    final now = DateTime.now();
    final account = Account(
      id: id,
      name: name,
      code: code,
      description: description,
      createdAt: now,
      smsKeyword: smsSyncKeyword,
      updatedAt: null,
    );
    await _box!.put(account.id, account);
    notifyListeners();
    return account.id.toString();
  }

  // persist updated account object and notify listeners
  Future<void> update(Account account) async {
    if (!isInitialized) await init();
    await _box!.put(account.id, account);
    notifyListeners();
  }

  Future<void> delete(int id) async {
    if (!isInitialized) await init();
    await _box!.delete(id);
    notifyListeners();
  }
}