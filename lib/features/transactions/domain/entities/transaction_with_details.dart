import 'package:myfinance/features/wallets/domain/entities/wallet.dart';
import 'package:myfinance/features/categories/domain/entities/category.dart';
import 'transaction.dart';

class TransactionWithDetails {
  final Transaction transaction;
  final Wallet? wallet;
  final Wallet? destinationWallet;
  final Category? category;

  const TransactionWithDetails({
    required this.transaction,
    this.wallet,
    this.destinationWallet,
    this.category,
  });

  String get displayTitle {
    if (transaction.type == TransactionType.transfer) {
      if (destinationWallet != null) {
        return 'Transfer ke ${destinationWallet!.name}';
      }
      if (transaction.merchant != null && transaction.merchant!.trim().isNotEmpty) {
        return 'Transfer ke ${transaction.merchant!.trim()}';
      }
      if (transaction.description != null && transaction.description!.trim().isNotEmpty) {
        return transaction.description!.trim();
      }
      return 'Transfer Keluar';
    }
    if (transaction.merchant != null && transaction.merchant!.trim().isNotEmpty) {
      return transaction.merchant!.trim();
    }
    if (category != null) {
      return category!.name;
    }
    if (transaction.description != null && transaction.description!.trim().isNotEmpty) {
      return transaction.description!.trim();
    }
    return transaction.type.displayName;
  }

  String get displaySubtitle {
    final parts = <String>[];
    if (transaction.type == TransactionType.transfer) {
      final source = wallet?.name ?? 'Dompet Asal';
      final dest = destinationWallet?.name ?? (transaction.merchant ?? 'Penerima Luar');
      parts.add('$source → $dest');
    } else {
      if (wallet != null) parts.add(wallet!.name);
      if (category != null && transaction.merchant != null && transaction.merchant!.isNotEmpty) {
        parts.add(category!.name);
      }
    }
    if (transaction.notes != null && transaction.notes!.trim().isNotEmpty) {
      parts.add(transaction.notes!.trim());
    }
    return parts.join(' • ');
  }
}
