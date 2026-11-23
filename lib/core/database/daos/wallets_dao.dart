import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/wallets_table.dart';

part 'wallets_dao.g.dart';

@DriftAccessor(tables: [WalletsTable])
class WalletsDao extends DatabaseAccessor<AppDatabase> with _$WalletsDaoMixin {
  WalletsDao(super.db);

  /// Mengambil semua wallet yang aktif (tidak diarsip)
  Future<List<WalletEntry>> getActiveWallets() {
    return (select(walletsTable)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Watch stream semua wallet aktif
  Stream<List<WalletEntry>> watchActiveWallets() {
    return (select(walletsTable)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Mengambil wallet berdasarkan ID
  Future<WalletEntry?> getWalletById(String id) {
    return (select(walletsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert wallet baru
  Future<int> insertWallet(WalletsTableCompanion wallet) {
    return into(walletsTable).insert(wallet);
  }

  /// Update wallet
  Future<bool> updateWallet(WalletsTableCompanion wallet) {
    return update(walletsTable).replace(wallet);
  }

  /// Arsipkan wallet (soft delete / cadangan)
  Future<int> archiveWallet(String id) {
    return (update(walletsTable)..where((t) => t.id.equals(id))).write(
      const WalletsTableCompanion(isArchived: Value(true)),
    );
  }

  /// Aktifkan kembali wallet yang diarsipkan
  Future<int> unarchiveWallet(String id) {
    return (update(walletsTable)..where((t) => t.id.equals(id))).write(
      const WalletsTableCompanion(isArchived: Value(false)),
    );
  }

  /// Mengambil semua wallet yang diarsipkan
  Future<List<WalletEntry>> getArchivedWallets() {
    return (select(walletsTable)
          ..where((t) => t.isArchived.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Watch stream semua wallet yang diarsipkan
  Stream<List<WalletEntry>> watchArchivedWallets() {
    return (select(walletsTable)
          ..where((t) => t.isArchived.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Hapus wallet permanen (hanya untuk data uji tanpa relasi)
  Future<int> deleteWallet(String id) {
    return (delete(walletsTable)..where((t) => t.id.equals(id))).go();
  }
}
