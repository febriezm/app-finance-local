import '../../../../core/errors/failures.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class CreateWalletUseCase {
  final WalletRepository _repository;

  CreateWalletUseCase(this._repository);

  Future<Wallet> execute({
    required String name,
    required WalletType type,
    required int openingBalance,
    String? iconKey,
    String? colorHex,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationFailure('Nama wallet tidak boleh kosong.');
    }
    if (openingBalance < 0) {
      throw const ValidationFailure('Saldo awal tidak boleh negatif.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final wallet = Wallet(
      id: UuidGenerator.generate(),
      name: trimmedName,
      type: type,
      openingBalance: openingBalance,
      openingDate: now,
      iconKey: iconKey,
      colorHex: colorHex,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.createWallet(wallet);
    return wallet;
  }
}
