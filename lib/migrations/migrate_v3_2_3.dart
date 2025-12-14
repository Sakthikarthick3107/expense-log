import 'package:hive/hive.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/models/account.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Migration v3.2.3
/// If installed app version is greater than 3.2.3, set lastSmsSyncedAt = 2025-11-01
/// only for accounts where lastSmsSyncedAt is null. No migration flag stored.
Future<void> runMigrationV323() async {
  const targetVersion = '3.2.3';
  final targetDate = DateTime(2025, 11, 1);
  final boxName = AccountsService.boxName;

  // helper: compare semantic versions "x.y.z"
  int compareVersion(String a, String b) {
    List<int> pa = a.split('.').map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    List<int> pb = b.split('.').map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    while (pa.length < len) pa.add(0);
    while (pb.length < len) pb.add(0);
    for (var i = 0; i < len; i++) {
      if (pa[i] > pb[i]) return 1;
      if (pa[i] < pb[i]) return -1;
    }
    return 0;
  }

  // read package version
  String installedVersion;
  try {
    final pkg = await PackageInfo.fromPlatform();
    installedVersion = pkg.version;
  } catch (_) {
    // unable to read package info -> skip migration
    return;
  }

  // proceed only if installedVersion > targetVersion
  if (compareVersion(installedVersion, targetVersion) <= 0) return;

  // open accounts box if needed
  if (!Hive.isBoxOpen(boxName)) {
    try {
      await Hive.openBox<Account>(boxName);
    } catch (_) {
      return;
    }
  }

  final box = Hive.box<Account>(boxName);
  final accounts = box.values.toList();

  for (final acc in accounts) {
    if (acc == null) continue;
    try {
      final dyn = acc;
      // only update when lastSmsSyncedAt is null
      final last = (() {
        try {
          return dyn.lastSmsSyncedAt;
        } catch (_) {
          return null;
        }
      })();
      if (last != null) continue;

      // Prefer copyWith if available
      try {
        final updated = dyn.copyWith(lastSmsSyncedAt: targetDate);
        await box.put(updated.id, updated);
        continue;
      } catch (_) {}

      // Try mutating the object then re-put
      try {
        dyn.lastSmsSyncedAt = targetDate;
        await box.put(dyn.id, dyn);
        continue;
      } catch (_) {}

      // Fallback: rebuild a minimal Account instance if model matches
      try {
        final id = dyn.id;
        final name = dyn.name ?? '';
        final code = dyn.code ?? '';
        final description = dyn.description;
        final createdAt = dyn.createdAt ?? DateTime.now();
        final updatedAt = DateTime.now();
        final newAcc = Account(
          id: id,
          name: name,
          code: code,
          description: description,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        try {
          (newAcc as dynamic).lastSmsSyncedAt = targetDate;
        } catch (_) {}
        await box.put(id, newAcc);
      } catch (_) {
        // ignore individual failures
      }
    } catch (_) {
      // ignore per-entry errors
    }
  }
}