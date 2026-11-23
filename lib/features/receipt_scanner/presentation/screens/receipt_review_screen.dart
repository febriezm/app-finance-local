import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../app/router.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../../wallets/domain/entities/wallet.dart';
import '../../domain/entities/receipt_draft.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/receipt_items_list.dart';

/// Layar Review & Konfirmasi Hasil Scan Struk — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Karakteristik Desain:
/// - Header minimalis dengan judul 'Review Struk'.
/// - Pratinjau foto struk ringkas dalam bentuk capsule horizontal dengan akses zoom interaktif layar penuh.
/// - Display total nominal typography-first tanpa box berlebihan (34px tabular figures).
/// - Form detail dikelompokkan flat dalam satu list terpadu dengan divider tipis (0.6px), bukan kumpulan card.
/// - Selector modal yang hening dan ramah satu sentuhan untuk Dompet dan Kategori.
/// - Section rincian item struk & breakdown biaya yang dapat diperluas/dilipat (collapsible).
/// - Sticky bottom action bar dengan penanganan SafeArea dan perlindungan anti-duplikasi.
class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final ReceiptDraft draft;

  const ReceiptReviewScreen({
    super.key,
    required this.draft,
  });

  @override
  ConsumerState<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int _amount = 0;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  late DateTime _occurredAt;
  bool _isSaving = false;
  bool _isDetailsExpanded = false;
  bool _showRawOcr = false;
  late String _rawText;

  @override
  void initState() {
    super.initState();
    _amount = widget.draft.totalAmount ?? 0;
    if (_amount > 0) {
      _amountController.text = CurrencyFormatter.formatRupiah(_amount);
    }
    _merchantController.text = widget.draft.merchant ?? '';
    _occurredAt = widget.draft.occurredAt ?? DateTime.now();
    _selectedCategoryId = widget.draft.suggestedCategoryId;
    _rawText = widget.draft.rawText;

    // Prefill Keterangan / Catatan dengan rincian item belanja jika tersedia
    if (widget.draft.items.isNotEmpty) {
      final itemsSummary = widget.draft.items.map((i) {
        final qtyStr = i.quantity > 1 ? '${i.quantity}x ' : '';
        return '$qtyStr${i.name} (${CurrencyFormatter.formatRupiah(i.totalPrice)})';
      }).join(', ');
      _notesController.text = itemsSummary;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final num = int.tryParse(clean) ?? 0;
    setState(() {
      _amount = num;
    });
    final formatted = num > 0 ? CurrencyFormatter.formatRupiah(num) : '';
    if (_amountController.text != formatted) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _selectDate() async {
    unawaited(AppHaptics.selection());
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_occurredAt),
      );
      if (!mounted) return;
      setState(() {
        _occurredAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time?.hour ?? _occurredAt.hour,
          time?.minute ?? _occurredAt.minute,
        );
      });
    }
  }

  void _showZoomedReceipt() {
    if (widget.draft.imageBytes == null || widget.draft.imageBytes!.isEmpty) return;
    unawaited(AppHaptics.light());

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.90),
      builder: (ctx) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: const Text(
              'Pratinjau Struk',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.5,
              child: Image.memory(
                widget.draft.imageBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWalletPickerSheet(BuildContext context, List<WalletWithBalance> wallets) {
    unawaited(AppHaptics.selection());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Material(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SafeArea(
              top: false,
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
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Pilih Dompet Sumber Dana',
                    style: AppTypography.pageTitle.copyWith(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 0.6, color: borderColor),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: wallets.length,
                    separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.6, indent: 56, color: borderColor),
                    itemBuilder: (_, index) {
                      final item = wallets[index];
                      final isSelected = item.wallet.id == _selectedWalletId;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 18,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        title: Text(item.wallet.name, style: AppTypography.bodyBold),
                        subtitle: Text(
                          CurrencyFormatter.formatRupiah(item.currentBalance),
                          style: AppTypography.caption.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: isDark ? AppColors.incomeDark : AppColors.incomeLight, size: 20)
                            : null,
                        onTap: () {
                          unawaited(AppHaptics.selection());
                          setState(() => _selectedWalletId = item.wallet.id);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  void _showCategoryPickerSheet(BuildContext context, List<Category> categories) {
    unawaited(AppHaptics.selection());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Material(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SafeArea(
              top: false,
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
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Pilih Kategori Pengeluaran',
                    style: AppTypography.pageTitle.copyWith(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 0.6, color: borderColor),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.6, indent: 56, color: borderColor),
                    itemBuilder: (_, index) {
                      final item = categories[index];
                      final isSelected = item.id == _selectedCategoryId;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppIcons.parseColor(item.colorHex).withValues(alpha: 0.15),
                          child: Icon(
                            AppIcons.getIcon(item.iconKey),
                            size: 18,
                            color: AppIcons.parseColor(item.colorHex),
                          ),
                        ),
                        title: Text(item.name, style: AppTypography.bodyMedium),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: isDark ? AppColors.incomeDark : AppColors.incomeLight, size: 20)
                            : null,
                        onTap: () {
                          unawaited(AppHaptics.selection());
                          setState(() => _selectedCategoryId = item.id);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Future<void> _confirmAndSave() async {
    // Pencegahan double submission
    if (_isSaving) return;

    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal pengeluaran harus lebih dari Rp 0.')),
      );
      return;
    }
    if (_selectedWalletId == null || _selectedWalletId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih dompet sumber dana.')),
      );
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan tentukan kategori pengeluaran.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final merchant = _merchantController.text.trim();
    final notes = _notesController.text.trim();

    // Rangkum item ke deskripsi transaksi agar muncul jelas di riwayat
    String description;
    if (widget.draft.items.isNotEmpty) {
      final itemNames = widget.draft.items.map((i) => i.name).join(', ');
      description = merchant.isNotEmpty ? '$merchant: $itemNames' : itemNames;
    } else if (merchant.isNotEmpty) {
      description = 'Belanja di $merchant';
    } else {
      description = 'Scan Struk Pembelian';
    }

    final txId = await ref.read(receiptScannerControllerProvider.notifier).confirmTransaction(
          draft: widget.draft,
          walletId: _selectedWalletId!,
          categoryId: _selectedCategoryId!,
          amount: _amount,
          occurredAt: _occurredAt,
          merchant: merchant.isNotEmpty ? merchant : null,
          description: description,
          notes: notes.isNotEmpty ? notes : null,
          imageBytes: widget.draft.imageBytes,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      if (txId != null) {
        unawaited(AppHaptics.medium());
        // Sinkronisasi bulan tab Transaksi ke bulan transaksi struk yang disimpan
        ref.read(selectedTransactionMonthProvider.notifier).state =
            DateTime(_occurredAt.year, _occurredAt.month, 1);

        // Refresh providers agar Home dan Riwayat Transaksi sinkron seketika
        ref.invalidate(walletsWithBalanceStreamProvider);
        ref.invalidate(recentTransactionsStreamProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi struk berhasil dikonfirmasi dan dicatat!')),
        );
        // Kembali ke tab Transaksi dengan bulan transaksi terpilih
        context.go(AppRouter.transactions, extra: {'initialMonth': _occurredAt});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan transaksi. Silakan periksa kembali data.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletsWithBalanceStreamProvider);
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider(CategoryType.expense));
    final surfaceColor = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final expenseColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;
    final textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Default select first wallet if not yet selected
    walletsAsync.whenData((wallets) {
      if (_selectedWalletId == null && wallets.isNotEmpty) {
        _selectedWalletId = wallets.first.wallet.id;
      }
    });

    // Default select category
    categoriesAsync.whenData((cats) {
      if ((_selectedCategoryId == null || !cats.any((c) => c.id == _selectedCategoryId)) && cats.isNotEmpty) {
        _selectedCategoryId = cats.first.id;
      }
    });

    final hasDetailedItems = widget.draft.items.isNotEmpty ||
        widget.draft.subtotal != null ||
        widget.draft.taxAmount != null ||
        widget.draft.serviceCharge != null ||
        widget.draft.discountAmount != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Review Struk',
          style: AppTypography.pageTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.6),
          child: Divider(height: 0.6, thickness: 0.6, color: borderColor),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                children: [
                  // SECTION 2: Receipt Preview (Compact Media Capsule)
                  if (widget.draft.imageBytes != null && widget.draft.imageBytes!.isNotEmpty) ...[
                    InkWell(
                      onTap: _showZoomedReceipt,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Image.memory(
                                  widget.draft.imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.receipt_long_outlined, size: 14, color: textSecondary),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Lampiran Struk',
                                          style: AppTypography.bodyBold.copyWith(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Foto tersimpan • Ketuk untuk perbesar',
                                    style: AppTypography.caption.copyWith(color: textTertiary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceElevatedDark : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in_rounded, size: 14, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Perbesar',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // SECTION 3: Total Transaksi (Typography-First, Generous & Clean)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'TOTAL TRANSAKSI',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            if (!widget.draft.isTotalCertain) ...[
                              const SizedBox(width: 8),
                              ConfidenceBadge(isCertain: widget.draft.isTotalCertain),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: AppTypography.balanceLarge.copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                            color: _amount > 0
                                ? expenseColor
                                : (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Rp 0',
                            hintStyle: AppTypography.balanceLarge.copyWith(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              color: (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight)
                                  .withValues(alpha: 0.4),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          onChanged: _onAmountChanged,
                        ),
                        if (_amount == 0 || !widget.draft.isTotalCertain) ...[
                          const SizedBox(height: 8),
                          Text(
                            _amount == 0
                                ? 'Nominal belum terdeteksi otomatis. Ketuk untuk mengisi.'
                                : 'Nominal belum pasti. Harap periksa kebenaran angka.',
                            style: AppTypography.caption2.copyWith(
                              color: isDark ? AppColors.warningDark : AppColors.warningLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // SECTION 4: Detail Transaksi (Konsisten dengan AddTransactionSheet)
                  // 1. Toko / Merchant
                  Text(
                    'Merchant / Toko',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: TextField(
                      controller: _merchantController,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        icon: Icon(
                          Icons.storefront_outlined,
                          size: 19,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        hintText: 'Merchant, toko, atau sumber (opsional)',
                        border: InputBorder.none,
                        hintStyle: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Tanggal & Waktu Transaksi
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal & Waktu',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppDateFormatter.formatDateTime(_occurredAt),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Dompet Sumber Dana
                  InkWell(
                    onTap: walletsAsync.valueOrNull != null && walletsAsync.valueOrNull!.isNotEmpty
                        ? () => _showWalletPickerSheet(context, walletsAsync.valueOrNull!)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dompet Sumber',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: walletsAsync.when(
                                  data: (wallets) {
                                    final selectedWallet = wallets.cast<WalletWithBalance?>().firstWhere(
                                      (w) => w?.wallet.id == _selectedWalletId,
                                      orElse: () => wallets.isNotEmpty ? wallets.first : null,
                                    );
                                    return Text(
                                      selectedWallet != null
                                          ? '${selectedWallet.wallet.name} (${CurrencyFormatter.formatRupiah(selectedWallet.currentBalance)})'
                                          : 'Pilih Dompet',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                  loading: () => Text('Memuat dompet...', style: AppTypography.caption.copyWith(color: textSecondary)),
                                  error: (e, _) => const Text('Gagal memuat dompet', style: TextStyle(color: Colors.red, fontSize: 13)),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Kategori Pengeluaran
                  InkWell(
                    onTap: categoriesAsync.valueOrNull != null && categoriesAsync.valueOrNull!.isNotEmpty
                        ? () => _showCategoryPickerSheet(context, categoriesAsync.valueOrNull!)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              categoriesAsync.when(
                                data: (categories) {
                                  final selectedCat = categories.cast<Category?>().firstWhere(
                                    (c) => c?.id == _selectedCategoryId,
                                    orElse: () => categories.isNotEmpty ? categories.first : null,
                                  );
                                  if (selectedCat != null) {
                                    return Icon(
                                      AppIcons.getIcon(selectedCat.iconKey),
                                      size: 18,
                                      color: AppIcons.parseColor(selectedCat.colorHex),
                                    );
                                  }
                                  return Icon(Icons.category_outlined, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
                                },
                                loading: () => Icon(Icons.category_outlined, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                error: (_, __) => Icon(Icons.category_outlined, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: categoriesAsync.when(
                                  data: (categories) {
                                    final selectedCat = categories.cast<Category?>().firstWhere(
                                      (c) => c?.id == _selectedCategoryId,
                                      orElse: () => categories.isNotEmpty ? categories.first : null,
                                    );
                                    return Text(
                                      selectedCat?.name ?? 'Pilih Kategori',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                  loading: () => Text('Memuat kategori...', style: AppTypography.caption.copyWith(color: textSecondary)),
                                  error: (e, _) => const Text('Gagal memuat kategori', style: TextStyle(color: Colors.red, fontSize: 13)),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Catatan Tambahan
                  Text(
                    'Catatan',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _notesController,
                      style: AppTypography.bodyMedium,
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        icon: Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        hintText: 'Rincian item atau catatan tambahan (opsional)',
                        border: InputBorder.none,
                        hintStyle: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SECTION 5: Optional Receipt Details (Collapsible Section)
                  if (hasDetailedItems) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              unawaited(AppHaptics.selection());
                              setState(() => _isDetailsExpanded = !_isDetailsExpanded);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_outlined, size: 18, color: textSecondary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Rincian Struk & Item',
                                      style: AppTypography.bodyBold.copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.draft.items.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${widget.draft.items.length} item',
                                        style: AppTypography.caption2.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  AnimatedRotation(
                                    turns: _isDetailsExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isDetailsExpanded) ...[
                            Divider(height: 1, thickness: 0.6, color: borderColor),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.draft.subtotal != null ||
                                      widget.draft.taxAmount != null ||
                                      widget.draft.serviceCharge != null ||
                                      widget.draft.discountAmount != null) ...[
                                    Text(
                                      'Rincian Biaya Struk',
                                      style: AppTypography.caption.copyWith(
                                        color: textTertiary,
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (widget.draft.subtotal != null)
                                      FinanceSummaryRow(
                                        label: 'Subtotal',
                                        customValue: CurrencyFormatter.formatRupiah(widget.draft.subtotal!),
                                      ),
                                    if (widget.draft.taxAmount != null)
                                      FinanceSummaryRow(
                                        label: 'Pajak (PPN/PB1)',
                                        customValue: CurrencyFormatter.formatRupiah(widget.draft.taxAmount!),
                                      ),
                                    if (widget.draft.serviceCharge != null)
                                      FinanceSummaryRow(
                                        label: 'Biaya Layanan',
                                        customValue: CurrencyFormatter.formatRupiah(widget.draft.serviceCharge!),
                                      ),
                                    if (widget.draft.discountAmount != null)
                                      FinanceSummaryRow(
                                        label: 'Diskon / Potongan',
                                        customValue: '- ${CurrencyFormatter.formatRupiah(widget.draft.discountAmount!)}',
                                        valueColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                                      ),
                                    const SizedBox(height: 14),
                                  ],
                                  if (widget.draft.items.isNotEmpty) ...[
                                    Text(
                                      'Item Belanja',
                                      style: AppTypography.caption.copyWith(
                                        color: textTertiary,
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ReceiptItemsList(items: widget.draft.items),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Teks Mentah OCR (Audit Transparan)
                  InkWell(
                    onTap: () {
                      unawaited(AppHaptics.selection());
                      setState(() => _showRawOcr = !_showRawOcr);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _showRawOcr ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Teks OCR Mentah (Lokal)',
                                style: AppTypography.caption.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                          if (_rawText.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() => _rawText = '');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Teks mentah OCR telah dibersihkan.')),
                                );
                              },
                              child: Text(
                                'Hapus',
                                style: TextStyle(
                                  color: expenseColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_showRawOcr) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Text(
                        _rawText.isNotEmpty ? _rawText : '(Teks mentah telah dibersihkan)',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // SECTION 6: Sticky Bottom Action Bar
            _buildBottomActionBar(isDark, surfaceColor, borderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _confirmAndSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Konfirmasi & Simpan Transaksi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          if (widget.draft.totalAmount == null || widget.draft.totalAmount == 0) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: borderColor, width: 0.8),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  AddTransactionSheet.show(context, initialType: TransactionType.expense);
                },
                child: const Text('Beralih ke Input Manual'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
