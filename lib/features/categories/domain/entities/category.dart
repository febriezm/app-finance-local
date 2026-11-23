enum CategoryType {
  income,
  expense;

  String get displayName => this == CategoryType.income ? 'Pemasukan' : 'Pengeluaran';

  static CategoryType fromString(String value) {
    return value == 'income' ? CategoryType.income : CategoryType.expense;
  }

  String toDbString() => this == CategoryType.income ? 'income' : 'expense';
}

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final String? iconKey;
  final String? colorHex;
  final bool isSystem;
  final bool isArchived;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.iconKey,
    this.colorHex,
    this.isSystem = false,
    this.isArchived = false,
    this.sortOrder = 0,
  });

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? iconKey,
    String? colorHex,
    bool? isSystem,
    bool? isArchived,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
