import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GetWalletsUseCase {
  final WalletRepository _repository;

  GetWalletsUseCase(this._repository);

  Future<List<WalletWithBalance>> execute() {
    return _repository.getActiveWalletsWithBalance();
  }

  Stream<List<WalletWithBalance>> watch() {
    return _repository.watchActiveWalletsWithBalance();
  }
}
