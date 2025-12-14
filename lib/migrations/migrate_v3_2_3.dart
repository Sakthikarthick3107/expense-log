import 'package:hive/hive.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/models/account.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Migration v3.2.3
/// Force-set lastSmsSyncedAt = 2025-11-01 for all accounts (even if non-null),
/// but only run when installed app version equals targetVersion.
Future<void> runMigrationV323() async {
  const targetVersion = '3.2.3';
  const migrationTag = 'migrate_v3_2_3_checked';

  try {
    final pkg = await PackageInfo.fromPlatform();
    if (pkg.version != targetVersion) {
      // don't run migration if app version doesn't match
      return;
    }
  } catch (_) {
    // if we can't read package info, skip running to be safe
    return;
  }

  final targetDate = DateTime(2025, 11, 1);
  final boxName = AccountsService.boxName;

  if (!Hive.isBoxOpen(boxName)) {
    try {
      await Hive.openBox<Account>(boxName);
    } catch (_) {
      // can't open box -> abort
      return;
    }
  }

  final box = Hive.box<Account>(boxName);

  // run once only: check a settings flag stored in the same box to avoid repeating
  try {
    final already = box.get(migrationTag);
    if (already == true) return;
  } catch (_) {
    // ignore and proceed
  }

  final accounts = box.values.toList();
  for (final acc in accounts) {
    if (acc == null) continue;
    try {
      final dyn = acc as dynamic;

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