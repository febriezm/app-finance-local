enum WalletType {
  cash,
  bank,
  eWallet,
  other;

  String get displayName {
    switch (this) {
      case WalletType.cash:
        return 'Uang Tunai (Cash)';
      case WalletType.bank:
        return 'Rekening Bank';
      case WalletType.eWallet:
        return 'E-Wallet';
      case WalletType.other:
        return 'Lainnya';
    }
  }

  static WalletType fromString(String value) {
    switch (value) {
      case 'cash':
        return WalletType.cash;
      case 'bank':
        return WalletType.bank;
      case 'e_wallet':
        return WalletType.eWallet;
      default:
        return WalletType.other;
    }
  }

  String toDbString() {
    switch (this) {
      case WalletType.cash:
        return 'cash';
      case WalletType.bank:
        return 'bank';
      case WalletType.eWallet:
        return 'e_wallet';
      case WalletType.other:
        return 'other';
    }
  }
}

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final int openingBalance; // Integer Rupiah
  final String openingDate; // ISO-8601 UTC
  final String currencyCode;
  final String? iconKey;
  final String? colorHex;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.openingDate,
    this.currencyCode = 'IDR',
    this.iconKey,
    this.colorHex,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    int? openingBalance,
    String? openingDate,
    String? currencyCode,
    String? iconKey,
    String? colorHex,
    bool? isArchived,
    String? createdAt,
    String? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      openingDate: openingDate ?? this.openingDate,
      currencyCode: currencyCode ?? this.currencyCode,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WalletWithBalance {
  final Wallet wallet;
  final int currentBalance; // Dihitung dari ledger (opening + income + transfer_in - expense - transfer_out)

  const WalletWithBalance({
    required this.wallet,
    required this.currentBalance,
  });
}
