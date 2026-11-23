import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionsController extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;

  TransactionsController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> createTransaction({
    required TransactionType type,
    required int amount,
    required DateTime occurredAt,
    required String walletId,
    String? destinationWalletId,
    String? categoryId,
    String? merchant,
    String? description,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final tx = Transaction(
        id: const Uuid().v4(),
        type: type,
        amount: amount,
        occurredAt: occurredAt.toUtc().toIso8601String(),
        walletId: walletId,
        destinationWalletId: destinationWalletId,
        categoryId: categoryId,
        merchant: merchant?.trim().isEmpty == true ? null : merchant?.trim(),
        description: description?.trim().isEmpty == true ? null : description?.trim(),
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        source: 'manual',
        status: TransactionStatus.confirmed,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.createTransaction(tx);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> voidTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.voidTransaction(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
