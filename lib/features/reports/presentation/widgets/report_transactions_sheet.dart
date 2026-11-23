import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';

class ReportTransactionsSheet extends ConsumerWidget {
  final String monthKey;
  final String title;
  final String? categoryId;
  final String? walletId;

  const ReportTransactionsSheet({
    super.key,
    required this.monthKey,
    required this.title,
    this.categoryId,
    this.walletId,
  });

  static void show(
    BuildContext context, {
    required String monthKey,
    required String title,
    String? categoryId,
    String? walletId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportTransactionsSheet(
        monthKey: monthKey,
        title: title,
        categoryId: categoryId,
        walletId: walletId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportRepo = ref.watch(reportRepositoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.title2.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Daftar transaksi pembentuk laporan ($monthKey)',
                          style: AppTypography.caption1.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<TransactionWithDetails>>(
                  future: reportRepo.getTransactionsForReport(
                    monthKey: monthKey,
                    categoryId: categoryId,
                    walletId: walletId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LoadingIndicator(message: 'Memuat mutasi...'));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Gagal memuat mutasi: ${snapshot.error}',
                          style: AppTypography.subhead,
                        ),
                      );
                    }

                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Tidak Ada Transaksi',
                        message: 'Tidak ditemukan transaksi untuk filter ini.',
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final t = item.transaction;
                        final isExpense = t.type == TransactionType.expense;
                        final isIncome = t.type == TransactionType.income;
                        final prefix = isIncome ? '+' : (isExpense ? '-' : '');
                        final color = isIncome
                            ? (isDark ? AppColors.primaryLight : AppColors.primary)
                            : (isExpense ? (isDark ? AppColors.errorLight : AppColors.error) : null);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          title: Text(
                            item.displayTitle,
                            style: AppTypography.subhead.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${AppDateFormatter.formatDate(DateTime.parse(t.occurredAt))} • ${item.displaySubtitle}',
                            style: AppTypography.caption1.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          trailing: Text(
                            '$prefix${CurrencyFormatter.formatRupiah(t.amount)}',
                            style: AppTypography.subhead.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
