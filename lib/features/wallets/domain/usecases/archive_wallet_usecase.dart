import '../repositories/wallet_repository.dart';

class ArchiveWalletUseCase {
  final WalletRepository _repository;

  ArchiveWalletUseCase(this._repository);

  Future<void> execute(String walletId) {
    return _repository.archiveWallet(walletId);
  }
}
