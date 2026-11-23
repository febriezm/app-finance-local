import '../../../wallets/domain/entities/wallet.dart';

class WalletReportItem {
  final Wallet wallet;
  final int incomeAmount;
  final int expenseAmount;
  final int transferInAmount;
  final int transferOutAmount;
  final int transactionCount;

  const WalletReportItem({
    required this.wallet,
    required this.incomeAmount,
    required this.expenseAmount,
    this.transferInAmount = 0,
    this.transferOutAmount = 0,
    this.transactionCount = 0,
  });

  /// Arus kas bersih pada wallet ini (uang masuk - uang keluar)
  int get netFlow => (incomeAmount + transferInAmount) - (expenseAmount + transferOutAmount);
}
