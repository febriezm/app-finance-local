import '../entities/transaction.dart';
import '../entities/transaction_with_details.dart';

abstract class TransactionRepository {
  /// Mengambil transaksi berdasarkan ID
  Future<Transaction?> getTransactionById(String id);

  /// Mengambil transaksi beserta detail wallet dan kategori
  Future<TransactionWithDetails?> getTransactionWithDetailsById(String id);

  /// Mengambil daftar transaksi terbaru
  Future<List<TransactionWithDetails>> getRecentTransactions({int limit = 20});

  /// Stream daftar transaksi terbaru (reactive)
  Stream<List<TransactionWithDetails>> watchRecentTransactions({int limit = 20});

  /// Mengambil mutasi untuk satu wallet
  Future<List<TransactionWithDetails>> getTransactionsForWallet(String walletId);

  /// Stream mutasi untuk satu wallet
  Stream<List<TransactionWithDetails>> watchTransactionsForWallet(String walletId);

  /// Mengambil transaksi dalam rentang tanggal
  Future<List<TransactionWithDetails>> getTransactionsInDateRange(
    DateTime start,
    DateTime end, {
    TransactionType? filterType,
  });

  /// Mencatat transaksi baru (income, expense, transfer)
  Future<void> createTransaction(Transaction transaction);

  /// Membatalkan (void) transaksi sehingga tidak memengaruhi saldo
  Future<void> voidTransaction(String id);

  /// Menghitung total pemasukan terkonfirmasi bulan tertentu
  Future<int> getMonthlyIncome(int year, int month);

  /// Stream total pemasukan terkonfirmasi bulan tertentu (reactive)
  Stream<int> watchMonthlyIncome(int year, int month);

  /// Menghitung total pengeluaran terkonfirmasi bulan tertentu
  Future<int> getMonthlyExpense(int year, int month);

  /// Stream total pengeluaran terkonfirmasi bulan tertentu (reactive)
  Stream<int> watchMonthlyExpense(int year, int month);
}
