import 'package:drift/drift.dart';
import 'tables/wallets_table.dart';
import 'tables/categories_table.dart';
import 'tables/transactions_table.dart';
import 'tables/transaction_attachments_table.dart';
import 'tables/budgets_table.dart';
import 'tables/budget_category_limits_table.dart';
import 'tables/app_settings_table.dart';
import 'daos/wallets_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/transactions_dao.dart';
import 'daos/budgets_dao.dart';
import 'daos/app_settings_dao.dart';
import 'connection/connection.dart' if (dart.library.html) 'connection/connection_web.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    WalletsTable,
    CategoriesTable,
    TransactionsTable,
    TransactionAttachmentsTable,
    BudgetsTable,
    BudgetCategoryLimitsTable,
    AppSettingsTable,
  ],
  daos: [
    WalletsDao,
    CategoriesDao,
    TransactionsDao,
    BudgetsDao,
    AppSettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        // Memastikan Foreign Key constraints aktif di SQLite
        await customStatement('PRAGMA foreign_keys = ON;');

        // Pastikan tabel app_settings selalu dibuat jika belum ada (kompatibilitas database versi awal)
        await customStatement('''
          CREATE TABLE IF NOT EXISTS app_settings (
            "key" TEXT NOT NULL PRIMARY KEY,
            "value" TEXT NOT NULL,
            "updated_at" TEXT NOT NULL
          );
        ''');

        // Pastikan tabel budget_category_limits selalu dibuat jika belum ada
        await customStatement('''
          CREATE TABLE IF NOT EXISTS budget_category_limits (
            "id" TEXT NOT NULL PRIMARY KEY,
            "budget_id" TEXT NOT NULL,
            "category_id" TEXT NOT NULL,
            "limit_amount" INTEGER NOT NULL,
            "created_at" TEXT NOT NULL,
            FOREIGN KEY ("budget_id") REFERENCES budgets ("id") ON DELETE CASCADE,
            FOREIGN KEY ("category_id") REFERENCES categories ("id") ON DELETE CASCADE
          );
        ''');
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          try {
            await m.createTable(budgetCategoryLimitsTable);
          } catch (_) {}
          try {
            await m.createTable(appSettingsTable);
          } catch (_) {}
        }
      },
      onCreate: (m) async {
        await m.createAll();

        // Seed default system categories
        final now = DateTime.now().toUtc().toIso8601String();
        final defaultCategories = [
          // Income
          CategoriesTableCompanion.insert(
            id: 'cat-inc-salary',
            name: 'Gaji',
            type: 'income',
            iconKey: const Value('briefcase'),
            colorHex: const Value('0xFF0E7A4A'),
            isSystem: const Value(true),
            sortOrder: const Value(1),
          ),
          CategoriesTableCompanion.insert(
            id: 'cat-inc-bonus',
            name: 'Bonus & THR',
            type: 'income',
            iconKey: const Value('gift'),
            colorHex: const Value('0xFF2ED573'),
            isSystem: const Value(true),
            sortOrder: const Value(2),
          ),
          CategoriesTableCompanion.insert(
            id: 'cat-inc-investment',
            name: 'Investasi',
            type: 'income',
            iconKey: const Value('trending-up'),
            colorHex: const Value('0xFF10AC84'),
            isSystem: const Value(true),
            sortOrder: const Value(3),
          ),
          CategoriesTableCompanion.insert(
            id: 'cat-inc-other',
            name: 'Pemasukan Lainnya',
            type: 'income',
            iconKey: const Value('plus-circle'),
            colorHex: const Value('0xFF0984E3'),
            isSystem: const Value(true),
            sortOrder: const Value(4),
          ),

          // Expense
          CategoriesTableCompanion.insert(
            id: 'cat-exp-food',
            name: 'Makanan & Minuman',
            type: 'expense',
            iconKey: const Value('utensils'),
            colorHex: const Value('0xFFD63031'),
            isSystem: const Value(true),
            sortOrder: const Value(1),
          ),
          CategoriesTableCompanion.insert(
            id: 'cat-exp-transport',
            name: 'Transportasi',
            type: 'expense',
            iconKey: const Value('car'),
            colorHex: const Value('0xFFE17055'),
            isSystem: const Value(true),
            sortOrder: const Value(2),
          ),
          CategoriesTableCompanion.insert(
            id: 'cat-exp-bills',
            name: 'Tagihan & Utilitas',
            type: 'expense',
            iconKey: const Value('file-text'),
            colorHex: const Value('0xFFE67E22'),
            isSystem: const Value(true),
            sortOrder: const Value(3),
          ),
          CategoriesTableCompanion.insert(
            id: 'cat-exp-shopping',
            name: 'Belanja & Kebutuhan',
            type: 'expense',
            iconKey: const Value('shopping-bag'),
            colorHex: const Value('0xFF9B59B6'),
            isSystem: const Value(true),
            sortOrder: const Value(4),
          ),
          CategoriesTableCompanion.insert(
            id: 'cat-exp-entertainment',
            name: 'Hiburan & Liburan',
            type: 'expense',
            iconKey: const Value('film'),
            colorHex: const Value('0xFFF368E0'),
            isSystem: const Value(true),
            sortOrder: const Value(5),
          ),
          CategoriesTableCompanion.insert(
            id: 'cat-exp-health',
            name: 'Kesehatan',
            type: 'expense',
            iconKey: const Value('heart'),
            colorHex: const Value('0xFFFF6B6B'),
            isSystem: const Value(true),
            sortOrder: const Value(6),
          ),
          CategoriesTableCompanion.insert(
            id: 'cat-exp-other',
            name: 'Pengeluaran Lainnya',
            type: 'expense',
            iconKey: const Value('more-horizontal'),
            colorHex: const Value('0xFF636E72'),
            isSystem: const Value(true),
            sortOrder: const Value(7),
          ),
        ];

        for (final cat in defaultCategories) {
          await into(categoriesTable).insert(cat);
        }

        // Seed initial app settings
        await into(appSettingsTable).insert(
          AppSettingsTableCompanion.insert(
            key: 'currency_code',
            value: 'IDR',
            updatedAt: now,
          ),
        );
        await into(appSettingsTable).insert(
          AppSettingsTableCompanion.insert(
            key: 'theme_mode',
            value: 'system',
            updatedAt: now,
          ),
        );
      },
    );
  }
}
