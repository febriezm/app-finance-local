import '../../../../core/database/app_database.dart';
import '../../domain/entities/category.dart';

class CategoryModel {
  CategoryModel._();

  static Category fromEntry(CategoryEntry entry) {
    return Category(
      id: entry.id,
      name: entry.name,
      type: CategoryType.fromString(entry.type),
      iconKey: entry.iconKey,
      colorHex: entry.colorHex,
      isSystem: entry.isSystem,
      isArchived: entry.isArchived,
      sortOrder: entry.sortOrder,
    );
  }
}
