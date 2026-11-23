import '../../../../core/database/app_database.dart';
import '../../domain/entities/wallet.dart';

class WalletModel {
  WalletModel._();

  static Wallet fromEntry(WalletEntry entry) {
    return Wallet(
      id: entry.id,
      name: entry.name,
      type: WalletType.fromString(entry.type),
      openingBalance: entry.openingBalance,
      openingDate: entry.openingDate,
      currencyCode: entry.currencyCode,
      iconKey: entry.iconKey,
      colorHex: entry.colorHex,
      isArchived: entry.isArchived,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  static WalletsTableCompanion toCompanion(Wallet wallet) {
    return WalletsTableCompanion.insert(
      id: wallet.id,
      name: wallet.name,
      type: wallet.type.toDbString(),
      openingBalance: wallet.openingBalance,
      openingDate: wallet.openingDate,
      createdAt: wallet.createdAt,
      updatedAt: wallet.updatedAt,
    );
  }
}
