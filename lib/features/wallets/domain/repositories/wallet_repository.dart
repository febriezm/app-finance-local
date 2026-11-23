import '../entities/wallet.dart';

abstract class WalletRepository {
  /// Mengambil daftar semua wallet yang aktif
  Future<List<Wallet>> getActiveWallets();

  /// Watch stream daftar semua wallet yang aktif
  Stream<List<Wallet>> watchActiveWallets();

  /// Mengambil semua wallet aktif beserta saldo berjalan yang dihitung dari ledger
  Future<List<WalletWithBalance>> getActiveWalletsWithBalance();

  /// Watch stream wallet aktif beserta saldo berjalannya
  Stream<List<WalletWithBalance>> watchActiveWalletsWithBalance();

  /// Mengambil satu wallet berdasarkan ID
  Future<Wallet?> getWalletById(String id);

  /// Menghitung saldo berjalan untuk wallet tertentu berdasarkan ledger
  Future<int> calculateWalletBalance(String walletId);

  /// Menghitung total saldo seluruh aset aktif
  Future<int> calculateTotalAssetBalance();

  /// Membuat wallet baru
  Future<void> createWallet(Wallet wallet);

  /// Memperbarui informasi wallet
  Future<void> updateWallet(Wallet wallet);

  /// Mengarsipkan wallet (soft delete)
  Future<void> archiveWallet(String id);

  /// Mengaktifkan kembali wallet yang diarsipkan
  Future<void> unarchiveWallet(String id);

  /// Mengambil semua wallet yang diarsipkan beserta saldo berjalannya
  Future<List<WalletWithBalance>> getArchivedWalletsWithBalance();

  /// Watch stream wallet yang diarsipkan beserta saldo berjalannya
  Stream<List<WalletWithBalance>> watchArchivedWalletsWithBalance();
}
