import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_with_details.dart';

/// Modal Sheet Catat & Edit Transaksi — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Karakter Desain:
/// - Type selector hening (Pengeluaran, Pemasukan, Transfer).
/// - Nominal uang besar dan terfokus (38px, tabular figures, hint 'Rp 0').
/// - Category selector minimalis dengan icon sederhana.
/// - Form detail (Dompet, Waktu, Merchant, Catatan) flat tanpa border tebal.
/// - Tombol simpan flat bebas gradien dan ramah sentuhan.
class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionType initialType;
  final String? initialWalletId;
  final TransactionWithDetails? initialTransaction;

  const AddTransactionSheet({
    super.key,
    this.initialType = TransactionType.expense,
    this.initialWalletId,
    this.initialTransaction,
  });

  static Future<bool?> show(
    BuildContext context, {
    TransactionType initialType = TransactionType.expense,
    String? initialWalletId,
    TransactionWithDetails? initialTransaction,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        initialType: initialType,
        initialWalletId: initialWalletId,
        initialTransaction: initialTransaction,
      ),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionType _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Transfer eksternal (ke bank / e-wallet / orang lain)
  bool _isExternalTransfer = false;
  String _selectedInstitution = 'Bank BCA';
  final TextEditingController _customInstitutionController = TextEditingController();
  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _recipientAccountController = TextEditingController();

  static const List<String> transferInstitutions = [
    'Bank BCA',
    'Bank Mandiri',
    'Bank BRI',
    'Bank BNI',
    'Bank Syariah Indonesia (BSI)',
    'Bank CIMB Niaga',
    'Bank Permata',
    'Bank Danamon',
    'Bank Jago',
    'SeaBank',
    'Jenius / BTPN',
    'Blu by BCA',
    'GoPay',
    'OVO',
    'DANA',
    'ShopeePay',
    'LinkAja',
    'AstraPay',
    'Bank / E-Wallet Lainnya',
  ];

  int _amount = 0;
  String? _selectedWalletId;
  String? _selectedDestWalletId;
  String? _selectedCategoryId;
  DateTime _occurredAt = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!.transaction;
      _type = tx.type;
      _amount = tx.amount;
      _amountController.text = CurrencyFormatter.formatRupiah(tx.amount);
      _selectedWalletId = tx.walletId;
      _selectedDestWalletId = tx.destinationWalletId;
      _selectedCategoryId = tx.categoryId;
      _occurredAt = AppDateFormatter.parseUtcToLocal(tx.occurredAt);
      _merchantController.text = tx.merchant ?? '';
      _notesController.text = tx.notes ?? '';
      if (tx.type == TransactionType.transfer && tx.destinationWalletId == null && tx.merchant != null) {
        _isExternalTransfer = true;
        _recipientNameController.text = tx.merchant!;
      }
    } else {
      _type = widget.initialType;
      _selectedWalletId = widget.initialWalletId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    _customInstitutionController.dispose();
    _recipientNameController.dispose();
    _recipientAccountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final num = int.tryParse(clean) ?? 0;
    _amount = num;
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_occurredAt),
      );
      setState(() {
        _occurredAt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime?.hour ?? _occurredAt.hour,
          pickedTime?.minute ?? _occurredAt.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal transaksi harus lebih dari 0.')),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet sumber terlebih dahulu.')),
      );
      return;
    }

    if (_type == TransactionType.transfer) {
      if (_isExternalTransfer) {
        final recipient = _recipientNameController.text.trim();
        if (recipient.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Masukkan nama orang atau penerima transfer.')),
          );
          return;
        }
      } else {
        if (_selectedDestWalletId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih dompet tujuan transfer.')),
          );
          return;
        }
        if (_selectedDestWalletId == _selectedWalletId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dompet tujuan tidak boleh sama dengan dompet asal.')),
          );
          return;
        }
      }
    } else {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori transaksi.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    String? destWalletId;
    String? merchant;
    String? description;
    String? notes;

    if (_type == TransactionType.transfer) {
      if (_isExternalTransfer) {
        final recipient = _recipientNameController.text.trim();
        final institution = _selectedInstitution == 'Bank / E-Wallet Lainnya' &&
                _customInstitutionController.text.trim().isNotEmpty
            ? _customInstitutionController.text.trim()
            : _selectedInstitution;
        destWalletId = null;
        merchant = '$institution - $recipient';
        description = 'Transfer ke $institution ($recipient)';
        final accNo = _recipientAccountController.text.trim();
        final userNotes = _notesController.text.trim();
        if (accNo.isNotEmpty && userNotes.isNotEmpty) {
          notes = 'No. Rek: $accNo • $userNotes';
        } else if (accNo.isNotEmpty) {
          notes = 'No. Rek: $accNo';
        } else {
          notes = userNotes.isNotEmpty ? userNotes : null;
        }
      } else {
        destWalletId = _selectedDestWalletId;
        merchant = null;
        description = _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : null;
        notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;
      }
    } else {
      destWalletId = null;
      merchant = _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : null;
      description = _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : null;
      notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;
    }

    // Jika mengedit transaksi yang sudah ada, batalkan versi lama terlebih dahulu
    if (widget.initialTransaction != null) {
      await ref.read(transactionsControllerProvider.notifier).voidTransaction(widget.initialTransaction!.transaction.id);
    }

    final success = await ref.read(transactionsControllerProvider.notifier).createTransaction(
          type: _type,
          amount: _amount,
          occurredAt: _occurredAt,
          walletId: _selectedWalletId!,
          destinationWalletId: destWalletId,
          categoryId: _type != TransactionType.transfer ? _selectedCategoryId : null,
          merchant: merchant,
          description: description,
          notes: notes,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        unawaited(AppHaptics.light());
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan transaksi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletsWithBalanceStreamProvider);
    final categoryType = _type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider(categoryType));

    // Default select first wallet if not yet selected
    walletsAsync.whenData((wallets) {
      if (_selectedWalletId == null && wallets.isNotEmpty) {
        _selectedWalletId = wallets.first.wallet.id;
      }
      if (_type == TransactionType.transfer && _selectedDestWalletId == null && wallets.length > 1) {
        _selectedDestWalletId = wallets.firstWhere((w) => w.wallet.id != _selectedWalletId).wallet.id;
      }
    });

    // Default select first category if not yet selected
    categoriesAsync.whenData((cats) {
      if (_selectedCategoryId == null && cats.isNotEmpty) {
        _selectedCategoryId = cats.first.id;
      }
    });

    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = isDark ? const Color(0xFF191919) : const Color(0xFFF9FAFB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          // iOS Drag Handle
          const SizedBox(height: 10),
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
          const SizedBox(height: 8),

          // Modal Navigation Header (Batal - Judul - Simpan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    AppHaptics.selection();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                Text(
                  widget.initialTransaction != null ? 'Edit Transaksi' : 'Catat Transaksi',
                  style: AppTypography.pageTitle.copyWith(fontSize: 17),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.6, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),

          // Scrollable Form Content
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // 1. Transaction Type Selector (Segmented Flat)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 0.6),
                  ),
                  child: Row(
                    children: [
                      _buildTypeSegment(TransactionType.expense, 'Pengeluaran', isDark),
                      _buildTypeSegment(TransactionType.income, 'Pemasukan', isDark),
                      _buildTypeSegment(TransactionType.transfer, 'Transfer', isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Large Amount Input Display (Fokus Utama)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Nominal',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTypography.balanceLarge.copyWith(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rp 0',
                          hintStyle: AppTypography.balanceLarge.copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                            color: (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight)
                                .withValues(alpha: 0.35),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: _onAmountChanged,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Category Selector (Only for Income & Expense)
                if (_type != TransactionType.transfer) ...[
                  Text(
                    'Kategori',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) {
                        return Text(
                          'Tidak ada kategori tersedia.',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        );
                      }
                      return CategorySelector(
                        categories: categories,
                        selectedCategoryId: _selectedCategoryId,
                        isHorizontal: true,
                        onSelected: (cat) {
                          setState(() => _selectedCategoryId = cat.id);
                        },
                      );
                    },
                    loading: () => const SizedBox(height: 38, child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const Text('Gagal memuat kategori', style: TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                  const SizedBox(height: 18),
                ],

                // 4. Dompet / Wallets Selection
                Text(
                  _type == TransactionType.transfer ? 'Pengaturan Transfer' : 'Dompet Sumber',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                walletsAsync.when(
                  data: (wallets) {
                    if (wallets.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: const Text(
                          'Belum ada dompet. Tambahkan dompet terlebih dahulu.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (_type == TransactionType.transfer) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 4a. Dari Dompet Asal
                            Row(
                              children: [
                                Icon(Icons.arrow_upward_rounded, size: 18, color: isDark ? AppColors.expenseDark : AppColors.expenseLight),
                                const SizedBox(width: 8),
                                Text(
                                  'Dari',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: DropdownButton<String>(
                                      value: _selectedWalletId,
                                      isDense: true,
                                      underline: const SizedBox(),
                                      items: wallets.map((w) {
                                        return DropdownMenuItem<String>(
                                          value: w.wallet.id,
                                          child: Text(
                                            '${w.wallet.name} (${CurrencyFormatter.formatRupiah(w.currentBalance)})',
                                            style: AppTypography.bodyMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedWalletId = val;
                                          if (_selectedDestWalletId == val) {
                                            final rem = wallets.where((w) => w.wallet.id != val);
                                            _selectedDestWalletId = rem.isNotEmpty ? rem.first.wallet.id : null;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Divider(height: 20, thickness: 0.6, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),

                            // 4b. Tujuan Transfer: Segmented Toggle
                            Text(
                              'Tujuan Transfer',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : Colors.white,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: borderColor, width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        AppHaptics.selection();
                                        setState(() => _isExternalTransfer = false);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 7),
                                        decoration: BoxDecoration(
                                          color: !_isExternalTransfer
                                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Dompet Sendiri',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: !_isExternalTransfer ? FontWeight.w600 : FontWeight.normal,
                                            color: !_isExternalTransfer
                                                ? (isDark ? AppColors.backgroundDark : Colors.white)
                                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        AppHaptics.selection();
                                        setState(() => _isExternalTransfer = true);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 7),
                                        decoration: BoxDecoration(
                                          color: _isExternalTransfer
                                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Bank / Orang Lain',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: _isExternalTransfer ? FontWeight.w600 : FontWeight.normal,
                                            color: _isExternalTransfer
                                                ? (isDark ? AppColors.backgroundDark : Colors.white)
                                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 4c. Konten Tujuan
                            if (!_isExternalTransfer) ...[
                              if (wallets.length <= 1)
                                Text(
                                  'Hanya ada 1 dompet. Pilih "Bank / Orang Lain" untuk transfer ke luar.',
                                  style: AppTypography.caption.copyWith(color: Colors.amber),
                                )
                              else
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward_rounded, size: 18, color: isDark ? AppColors.incomeDark : AppColors.incomeLight),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ke',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: DropdownButton<String>(
                                          value: _selectedDestWalletId,
                                          isDense: true,
                                          underline: const SizedBox(),
                                          items: wallets
                                              .where((w) => w.wallet.id != _selectedWalletId)
                                              .map((w) {
                                            return DropdownMenuItem<String>(
                                              value: w.wallet.id,
                                              child: Text(
                                                '${w.wallet.name} (${CurrencyFormatter.formatRupiah(w.currentBalance)})',
                                                style: AppTypography.bodyMedium,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() => _selectedDestWalletId = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ] else ...[
                              // Dropdown Bank / E-Wallet Luar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor, width: 0.8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedInstitution,
                                    isExpanded: true,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                    dropdownColor: surfaceColor,
                                    items: transferInstitutions.map((inst) {
                                      return DropdownMenuItem<String>(
                                        value: inst,
                                        child: Text(inst, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedInstitution = val);
                                      }
                                    },
                                  ),
                                ),
                              ),

                              if (_selectedInstitution == 'Bank / E-Wallet Lainnya') ...[
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _customInstitutionController,
                                  decoration: InputDecoration(
                                    hintText: 'Tulis nama bank atau e-wallet...',
                                    hintStyle: AppTypography.caption.copyWith(
                                      color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: surfaceColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor, width: 0.8),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),

                              // Nama Penerima
                              TextField(
                                controller: _recipientNameController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                                  hintText: 'Nama penerima transfer',
                                  hintStyle: AppTypography.caption.copyWith(
                                    color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  filled: true,
                                  fillColor: surfaceColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: borderColor, width: 0.8),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Nomor Rekening
                              TextField(
                                controller: _recipientAccountController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                                  hintText: 'Nomor rekening / No. HP (opsional)',
                                  hintStyle: AppTypography.caption.copyWith(
                                    color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  filled: true,
                                  fillColor: surfaceColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: borderColor, width: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    // Single Wallet Picker untuk Income & Expense
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 19,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Dompet',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: DropdownButton<String>(
                                value: _selectedWalletId,
                                isDense: true,
                                underline: const SizedBox(),
                                items: wallets.map((w) {
                                  return DropdownMenuItem<String>(
                                    value: w.wallet.id,
                                    child: Text(
                                      '${w.wallet.name} (${CurrencyFormatter.formatRupiah(w.currentBalance)})',
                                      style: AppTypography.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedWalletId = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Gagal memuat dompet', style: TextStyle(color: Colors.red, fontSize: 13)),
                ),

                const SizedBox(height: 16),

                // 5. Merchant / Toko / Sumber (hanya jika bukan transfer eksternal)
                if (_type != TransactionType.transfer || !_isExternalTransfer) ...[
                  Text(
                    _type == TransactionType.transfer ? 'Keterangan Transfer' : 'Merchant / Toko',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
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
                        hintText: _type == TransactionType.transfer
                            ? 'Keterangan transfer (opsional)'
                            : 'Merchant, toko, atau sumber (opsional)',
                        border: InputBorder.none,
                        hintStyle: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 6. Tanggal & Waktu Transaksi
                Text(
                  'Waktu Transaksi',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
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
                            DateFormatter.formatDateAndTime(_occurredAt.toIso8601String()),
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                ),

                const SizedBox(height: 16),

                // 7. Catatan Tambahan (Notes)
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
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: AppTypography.bodyMedium,
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

                const SizedBox(height: 24),

                // 8. Tombol Simpan Utama
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                          )
                        : Text(
                            widget.initialTransaction != null ? 'Simpan Perubahan' : 'Simpan Transaksi',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment(TransactionType type, String title, bool isDark) {
    final isSelected = _type == type;
    final activeBg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final activeFg = isDark ? AppColors.backgroundDark : Colors.white;
    final inactiveFg = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          setState(() {
            _type = type;
            _selectedCategoryId = null; // Reset category when switching type
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? activeFg : inactiveFg,
            ),
          ),
        ),
      ),
    );
  }
}
