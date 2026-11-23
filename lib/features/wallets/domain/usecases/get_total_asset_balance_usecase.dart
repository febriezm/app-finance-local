import '../repositories/wallet_repository.dart';

class GetTotalAssetBalanceUseCase {
  final WalletRepository _repository;

  GetTotalAssetBalanceUseCase(this._repository);

  Future<int> execute() {
    return _repository.calculateTotalAssetBalance();
  }
}
