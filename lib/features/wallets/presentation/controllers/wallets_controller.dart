import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletsController extends StateNotifier<AsyncValue<void>> {
  final WalletRepository _repository;

  WalletsController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> createWallet({
    required String name,
    required WalletType type,
    required int openingBalance,
    String? iconKey,
    String? colorHex,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final wallet = Wallet(
        id: const Uuid().v4(),
        name: name.trim(),
        type: type,
        openingBalance: openingBalance,
        openingDate: now,
        currencyCode: 'IDR',
        iconKey: iconKey ?? 'wallet',
        colorHex: colorHex ?? '0xFF0E7A4A',
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.createWallet(wallet);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('Error creating wallet: $e\n$st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> archiveWallet(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.archiveWallet(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('Error archiving wallet: $e\n$st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> unarchiveWallet(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.unarchiveWallet(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('Error unarchiving wallet: $e\n$st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateWallet({
    required String id,
    required String name,
    required WalletType type,
    required int openingBalance,
    String? iconKey,
    String? colorHex,
    required bool isArchived,
    required String openingDate,
    required String currencyCode,
    required String createdAt,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final updated = Wallet(
        id: id,
        name: name.trim(),
        type: type,
        openingBalance: openingBalance,
        openingDate: openingDate,
        currencyCode: currencyCode,
        iconKey: iconKey ?? 'wallet',
        colorHex: colorHex ?? '0xFF0E7A4A',
        isArchived: isArchived,
        createdAt: createdAt,
        updatedAt: now,
      );
      await _repository.updateWallet(updated);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('Error updating wallet: $e\n$st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
