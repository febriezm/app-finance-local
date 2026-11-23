import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';
import '../tables/transaction_attachments_table.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable, TransactionAttachmentsTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase> with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// Mengambil transaksi berdasarkan ID
  Future<TransactionEntry?> getTransactionById(String id) {
    return (select(transactionsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Watch transaksi terbaru berstatus confirmed
  Stream<List<TransactionEntry>> watchRecentTransactions({int limit = 100}) {
    return (select(transactionsTable)
          ..where((t) => t.status.equals('confirmed'))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
          ..limit(limit))
        .watch();
  }

  /// Mengambil seluruh mutasi confirmed untuk wallet tertentu (income, expense, transfer)
  Future<List<TransactionEntry>> getConfirmedLedgerForWallet(String walletId) {
    return (select(transactionsTable)
          ..where((t) =>
              t.status.equals('confirmed') &
              (t.walletId.equals(walletId) | t.destinationWalletId.equals(walletId)))
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
        .get();
  }

  /// Watch mutasi confirmed untuk wallet tertentu
  Stream<List<TransactionEntry>> watchConfirmedLedgerForWallet(String walletId) {
    return (select(transactionsTable)
          ..where((t) =>
              t.status.equals('confirmed') &
              (t.walletId.equals(walletId) | t.destinationWalletId.equals(walletId)))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch();
  }

  /// Mengambil seluruh pengeluaran confirmed dalam rentang waktu tertentu
  Future<List<TransactionEntry>> getConfirmedExpensesInDateRange(
    String startIsoUtc,
    String endIsoUtc,
  ) {
    return (select(transactionsTable)
          ..where((t) =>
              t.status.equals('confirmed') &
              t.type.equals('expense') &
              t.occurredAt.isBiggerOrEqualValue(startIsoUtc) &
              t.occurredAt.isSmallerOrEqualValue(endIsoUtc))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .get();
  }

  /// Watch seluruh pengeluaran confirmed dalam rentang waktu tertentu (Real-time Stream)
  Stream<List<TransactionEntry>> watchConfirmedExpensesInDateRange(
    String startIsoUtc,
    String endIsoUtc,
  ) {
    return (select(transactionsTable)
          ..where((t) =>
              t.status.equals('confirmed') &
              t.type.equals('expense') &
              t.occurredAt.isBiggerOrEqualValue(startIsoUtc) &
              t.occurredAt.isSmallerOrEqualValue(endIsoUtc))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch();
  }

  /// Mengambil seluruh pemasukan confirmed dalam rentang waktu tertentu
  Future<List<TransactionEntry>> getConfirmedIncomesInDateRange(
    String startIsoUtc,
    String endIsoUtc,
  ) {
    return (select(transactionsTable)
          ..where((t) =>
              t.status.equals('confirmed') &
              t.type.equals('income') &
              t.occurredAt.isBiggerOrEqualValue(startIsoUtc) &
              t.occurredAt.isSmallerOrEqualValue(endIsoUtc))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .get();
  }

  /// Watch seluruh pemasukan confirmed dalam rentang waktu tertentu (Real-time Stream)
  Stream<List<TransactionEntry>> watchConfirmedIncomesInDateRange(
    String startIsoUtc,
    String endIsoUtc,
  ) {
    return (select(transactionsTable)
          ..where((t) =>
              t.status.equals('confirmed') &
              t.type.equals('income') &
              t.occurredAt.isBiggerOrEqualValue(startIsoUtc) &
              t.occurredAt.isSmallerOrEqualValue(endIsoUtc))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch();
  }

  /// Insert transaksi
  Future<int> insertTransaction(TransactionsTableCompanion transaction) {
    return into(transactionsTable).insert(transaction);
  }

  /// Update transaksi
  Future<bool> updateTransaction(TransactionsTableCompanion transaction) {
    return update(transactionsTable).replace(transaction);
  }

  /// Void transaksi (status = 'voided') agar tidak memengaruhi saldo & laporan
  Future<int> voidTransaction(String id, String updatedAtUtcIso) {
    return (update(transactionsTable)..where((t) => t.id.equals(id))).write(
      TransactionsTableCompanion(
        status: const Value('voided'),
        updatedAt: Value(updatedAtUtcIso),
      ),
    );
  }

  /// Attachment: Tambah attachment struk
  Future<int> insertAttachment(TransactionAttachmentsTableCompanion attachment) {
    return into(transactionAttachmentsTable).insert(attachment);
  }

  /// Attachment: Ambil attachment berdasarkan ID transaksi
  Future<List<TransactionAttachmentEntry>> getAttachmentsForTransaction(String transactionId) {
    return (select(transactionAttachmentsTable)
          ..where((t) => t.transactionId.equals(transactionId)))
        .get();
  }
}
