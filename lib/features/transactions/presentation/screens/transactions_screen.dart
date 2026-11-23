import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../app/router.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_with_details.dart';
import '../widgets/add_transaction_sheet.dart';

/// Halaman Riwayat Transaksi — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Fitur:
/// - Tipografi hening dengan tabular figures pada nominal uang.
/// - Pemilih bulan terintegrasi (MinimalMonthSelector).
/// - Ringkasan pemasukan & pengeluaran bulanan flat.
/// - Pencarian teks instan (merchant, catatan, kategori, dompet).
/// - Filter jenis transaksi (Semua, Pengeluaran, Pemasukan, Transfer).
/// - Pengelompokan mutasi berdasarkan tanggal (Grouping by Date).
/// - Detail transaksi lengkap dengan pembatalan (Void).
class TransactionsScreen extends ConsumerStatefulWidget {
  final DateTime? initialMonth;

  const TransactionsScreen({super.key, this.initialMonth});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Pengeluaran, 2: Pemasukan, 3: Transfer
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialMonth != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedTransactionMonthProvider.notifier).state =
              DateTime(widget.initialMonth!.year, widget.initialMonth!.month, 1);
        }
      });
    }
  }

  @override
  void didUpdateWidget(TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != null && widget.initialMonth != oldWidget.initialMonth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedTransactionMonthProvider.notifier).state =
              DateTime(widget.initialMonth!.year, widget.initialMonth!.month, 1);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTransaction(BuildContext context) {
    AppHaptics.light();
    AddTransactionSheet.show(context);
  }

  String _getDateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'Hari ini • ${AppDateFormatter.formatDate(date)}';
    if (diffDays == 1) return 'Kemarin • ${AppDateFormatter.formatDate(date)}';
    return AppDateFormatter.formatDate(date);
  }

  void _showDetailSheet(BuildContext context, TransactionWithDetails item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = item.transaction;
    final isVoided = tx.status == TransactionStatus.voided;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    AmountDisplayType amountType;
    if (tx.type == TransactionType.income) {
      amountType = AmountDisplayType.income;
    } else if (tx.type == TransactionType.expense) {
      amountType = AmountDisplayType.expense;
    } else {
      amountType = AmountDisplayType.neutral;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Judul & Nominal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayTitle,
                            style: AppTypography.pageTitle.copyWith(fontSize: 20),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormatter.formatDateAndTime(tx.occurredAt),
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FinanceAmountText(
                      amount: tx.amount,
                      type: amountType,
                      isVoided: isVoided,
                      style: AppTypography.balanceMedium.copyWith(fontSize: 20),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Detail Data Baris Kunci-Nilai Flat
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF191919) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Jenis Transaksi', tx.type.displayName, isDark),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        'Status Transaksi',
                        tx.status.displayName,
                        isDark,
                        valueColor: isVoided
                            ? (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight)
                            : (isDark ? AppColors.incomeDark : AppColors.incomeLight),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow('Dompet Sumber', item.wallet?.name ?? '-', isDark),
                      if (tx.type == TransactionType.transfer) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          'Tujuan Transfer',
                          item.destinationWallet?.name ?? (tx.merchant ?? 'Pihak Luar'),
                          isDark,
                        ),
                      ],
                      if (item.category != null) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow('Kategori', item.category!.name, isDark),
                      ],
                      if (tx.merchant != null && tx.merchant!.isNotEmpty && tx.type != TransactionType.transfer) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow('Merchant / Penerima', tx.merchant!, isDark),
                      ],
                      if (tx.description != null && tx.description!.isNotEmpty && tx.description != tx.merchant) ...[
                        const SizedBox(height: 12),
                        _buildTextBlock('Keterangan', tx.description!, isDark, borderColor),
                      ],
                      if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildTextBlock('Rincian Item / Catatan', tx.notes!, isDark, borderColor),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol Aksi Transaksi (Edit & Batalkan)
                if (tx.status == TransactionStatus.confirmed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      label: Text(
                        'Edit Transaksi',
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor, width: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        unawaited(AppHaptics.selection());
                        Navigator.of(context).pop();
                        await AddTransactionSheet.show(context, initialTransaction: item);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                      ),
                      label: Text(
                        'Batalkan Transaksi (Void)',
                        style: TextStyle(
                          color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: (isDark ? AppColors.expenseDark : AppColors.expenseLight).withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        unawaited(AppHaptics.selection());
                        final confirm = await MinimalDialog.showConfirm(
                          context,
                          title: 'Batalkan Transaksi?',
                          message: 'Transaksi ini akan ditandai "Voided" dan tidak akan lagi memengaruhi saldo dompet maupun laporan anggaran.',
                          confirmText: 'Ya, Batalkan',
                          isDestructive: true,
                        );

                        if (confirm == true) {
                          await ref.read(transactionsControllerProvider.notifier).voidTransaction(tx.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Transaksi berhasil dibatalkan.')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextBlock(String label, String value, bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.6),
          ),
          child: Text(
            value,
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactionsAsync = ref.watch(recentTransactionsStreamProvider);
    final selectedMonth = ref.watch(selectedTransactionMonthProvider);
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgScaffold = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: AppBar(
        title: const Text('Transaksi'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgScaffold,
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined, size: 21),
            tooltip: 'Scan Struk (OCR)',
            onPressed: () {
              AppHaptics.selection();
              context.push(AppRouter.receiptScanner);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: 'Catat Transaksi',
            onPressed: () => _showAddTransaction(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Month Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MinimalMonthSelector(
              currentMonth: selectedMonth,
              onMonthChanged: (newMonth) {
                ref.read(selectedTransactionMonthProvider.notifier).state = newMonth;
              },
            ),
          ),

          // 2. Transaksi Data Provider & Filter/Summary
          Expanded(
            child: transactionsAsync.when(
              data: (allTransactions) {
                final selectedMonthKey = AppDateFormatter.toMonthKey(selectedMonth);

                // Hitung total pemasukan & pengeluaran terkonfirmasi di bulan yang dipilih
                final monthConfirmedTransactions = allTransactions.where((item) {
                  final localDt = AppDateFormatter.parseUtcToLocal(item.transaction.occurredAt);
                  return AppDateFormatter.toMonthKey(localDt) == selectedMonthKey &&
                      item.transaction.status == TransactionStatus.confirmed;
                }).toList();

                final monthIncome = monthConfirmedTransactions
                    .where((t) => t.transaction.type == TransactionType.income)
                    .fold<int>(0, (sum, t) => sum + t.transaction.amount);

                final monthExpense = monthConfirmedTransactions
                    .where((t) => t.transaction.type == TransactionType.expense)
                    .fold<int>(0, (sum, t) => sum + t.transaction.amount);

                // Filter berdasarkan bulan, filter kategori jenis, dan query pencarian
                final filtered = allTransactions.where((item) {
                  final tx = item.transaction;
                  final localDt = AppDateFormatter.parseUtcToLocal(tx.occurredAt);

                  // Filter bulan: jika ada pencarian teks aktif, cari lintas bulan; jika tidak, filter per bulan terpilih
                  if (_searchQuery.trim().isEmpty && AppDateFormatter.toMonthKey(localDt) != selectedMonthKey) {
                    return false;
                  }

                  // Filter tipe
                  if (_selectedFilterIndex == 1 && tx.type != TransactionType.expense) return false;
                  if (_selectedFilterIndex == 2 && tx.type != TransactionType.income) return false;
                  if (_selectedFilterIndex == 3 && tx.type != TransactionType.transfer) return false;

                  // Filter pencarian
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final title = item.displayTitle.toLowerCase();
                    final merchant = tx.merchant?.toLowerCase() ?? '';
                    final desc = tx.description?.toLowerCase() ?? '';
                    final notes = tx.notes?.toLowerCase() ?? '';
                    final category = item.category?.name.toLowerCase() ?? '';
                    final wallet = item.wallet?.name.toLowerCase() ?? '';
                    final dest = item.destinationWallet?.name.toLowerCase() ?? '';

                    final match = title.contains(query) ||
                        merchant.contains(query) ||
                        desc.contains(query) ||
                        notes.contains(query) ||
                        category.contains(query) ||
                        wallet.contains(query) ||
                        dest.contains(query);

                    if (!match) return false;
                  }

                  return true;
                }).toList();

                // Urutkan transaksi terbaru ke terlama
                filtered.sort((a, b) => b.transaction.occurredAt.compareTo(a.transaction.occurredAt));

                // Kelompokkan transaksi berdasarkan tanggal (Grouping by Date)
                final groupedTransactions = <String, List<TransactionWithDetails>>{};
                for (final item in filtered) {
                  final localDt = AppDateFormatter.parseUtcToLocal(item.transaction.occurredAt);
                  final dateKey = '${localDt.year}-${localDt.month.toString().padLeft(2, '0')}-${localDt.day.toString().padLeft(2, '0')}';
                  groupedTransactions.putIfAbsent(dateKey, () => []).add(item);
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // 2a. Ringkasan Pemasukan & Pengeluaran Bulan Berjalan
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pemasukan',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                FinanceAmountText(
                                  amount: monthIncome,
                                  type: AmountDisplayType.neutral,
                                  color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                                  style: AppTypography.bodyBold.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 0.8,
                            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pengeluaran',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                FinanceAmountText(
                                  amount: monthExpense,
                                  type: AmountDisplayType.neutral,
                                  color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                                  style: AppTypography.bodyBold.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2b. Kotak Pencarian Transaksi
                    Container(
                      height: 42,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari transaksi, merchant, catatan...',
                          hintStyle: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),

                    // 2c. Filter Jenis Transaksi Segment
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          _buildFilterChip(0, 'Semua', isDark, surfaceColor, borderColor),
                          const SizedBox(width: 8),
                          _buildFilterChip(1, 'Pengeluaran', isDark, surfaceColor, borderColor),
                          const SizedBox(width: 8),
                          _buildFilterChip(2, 'Pemasukan', isDark, surfaceColor, borderColor),
                          const SizedBox(width: 8),
                          _buildFilterChip(3, 'Transfer', isDark, surfaceColor, borderColor),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 2d. Daftar Transaksi Terkelompok atau Empty State
                    if (filtered.isEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 36,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak Ada Hasil'
                                  : 'Belum Ada Transaksi',
                              style: AppTypography.sectionTitle.copyWith(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ditemukan transaksi yang cocok dengan "$_searchQuery".'
                                  : _selectedFilterIndex == 0
                                      ? 'Belum ada transaksi tercatat pada ${AppDateFormatter.formatMonthYear(selectedMonth)}.'
                                      : 'Tidak ada transaksi untuk filter ini pada ${AppDateFormatter.formatMonthYear(selectedMonth)}.',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 14),
                              OutlinedButton(
                                onPressed: () => _showAddTransaction(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: borderColor, width: 0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                  ),
                                ),
                                child: const Text('Catat Transaksi'),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      ...groupedTransactions.entries.map((entry) {
                        final itemsInDate = entry.value;
                        final firstTxDt = AppDateFormatter.parseUtcToLocal(itemsInDate.first.transaction.occurredAt);
                        final dateHeaderLabel = _getDateGroupLabel(firstTxDt);

                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Group Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateHeaderLabel,
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    Text(
                                      '${itemsInDate.length} transaksi',
                                      style: AppTypography.caption2.copyWith(
                                        color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                thickness: 0.6,
                                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                              ),

                              // Tiles
                              ...itemsInDate.asMap().entries.map((itemEntry) {
                                final index = itemEntry.key;
                                final item = itemEntry.value;
                                return TransactionListTile(
                                  item: item,
                                  showDivider: index < itemsInDate.length - 1,
                                  onTap: () {
                                    AppHaptics.selection();
                                    _showDetailSheet(context, item);
                                  },
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum dapat memuat daftar transaksi. Silakan muat ulang.',
                    style: AppTypography.body.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    int index,
    String title,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isSelected = _selectedFilterIndex == index;
    final activeBg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final activeFg = isDark ? AppColors.backgroundDark : Colors.white;
    final inactiveFg = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return InkWell(
      onTap: () {
        AppHaptics.selection();
        setState(() => _selectedFilterIndex = index);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isSelected ? activeBg : borderColor,
            width: 0.8,
          ),
        ),
        child: Text(
          title,
          style: AppTypography.caption.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}
