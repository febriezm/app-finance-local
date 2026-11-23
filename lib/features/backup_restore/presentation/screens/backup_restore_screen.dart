import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/file_picker_helper.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Halaman Cadangkan & Pulihkan (Backup & Restore)
/// Desain: MyFinance Minimal — Quiet, Clean, Premium.
///
/// Fitur:
/// - Informasi privasi & penyimpanan lokal 100% offline.
/// - Cadangkan seluruh data menjadi arsip JSON terstruktur & bagikan/unduh.
/// - Opsi salin teks JSON cadangan ke clipboard.
/// - Pulihkan data via berkas JSON dengan validasi schema & integritas.
/// - Dukungan tempel teks cadangan (paste) dari clipboard atau manual.
/// - Zona Berbahaya terpisah untuk reset seluruh data aplikasi dengan konfirmasi ketik "RESET".
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  final TextEditingController _jsonInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pastikan state selalu bersih saat membuka layar Cadangkan & Pulihkan
    Future.microtask(() {
      if (mounted) {
        ref.read(backupRestoreControllerProvider.notifier).resetState();
      }
    });
  }

  @override
  void dispose() {
    _jsonInputController.dispose();
    super.dispose();
  }

  Future<void> _pickJsonFile() async {
    unawaited(AppHaptics.selection());
    final messenger = ScaffoldMessenger.of(context);
    try {
      final content = await FilePickerHelper.pickJsonFile();
      if (content != null && content.isNotEmpty) {
        _jsonInputController.text = content;
        ref.read(backupRestoreControllerProvider.notifier).validateJson(content);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal membaca berkas cadangan: $e')),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    unawaited(AppHaptics.selection());
    String? text;
    try {
      final data = await Clipboard.getData('text/plain');
      text = data?.text?.trim();
    } catch (_) {
      text = null;
    }

    if (text != null && text.isNotEmpty) {
      _jsonInputController.text = text;
      final res = ref.read(backupRestoreControllerProvider.notifier).validateJson(text);
      if (res.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teks cadangan berhasil dimuat dan divalidasi dari papan klip.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    // Jika clipboard dibatasi oleh browser atau belum valid,
    // buka lembar input teks langsung agar pengguna dapat menempelkan secara manual.
    if (mounted) {
      _showManualPasteModal(context);
    }
  }

  void _showManualPasteModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgField = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: SafeArea(
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tempel Teks Cadangan',
                          style: AppTypography.title2.copyWith(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ketuk kolom teks di bawah lalu pilih opsi "Tempel" (Paste) untuk memuat data cadangan JSON:',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _jsonInputController,
                      maxLines: 7,
                      autofocus: true,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Ketuk di sini, lalu pilih "Tempel" / "Paste"...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                        ),
                        filled: true,
                        fillColor: bgField,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            width: 1.2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor, width: 0.8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.paste_rounded, size: 18),
                            label: const Text('Tempel Otomatis'),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                final data = await Clipboard.getData('text/plain');
                                final t = data?.text?.trim();
                                if (t != null && t.isNotEmpty) {
                                  setModalState(() {
                                    _jsonInputController.text = t;
                                  });
                                } else {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Papan klip dibatasi browser. Silakan ketuk kolom teks dan pilih "Tempel".'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } catch (_) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Akses otomatis dibatasi browser. Ketuk kolom teks dan pilih "Tempel".'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: const Text('Periksa & Muat'),
                            onPressed: () {
                              final raw = _jsonInputController.text.trim();
                              if (raw.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kolom teks masih kosong. Silakan tempel teks cadangan.')),
                                );
                                return;
                              }
                              Navigator.pop(sheetCtx);
                              final res = ref.read(backupRestoreControllerProvider.notifier).validateJson(raw);
                              if (mounted) {
                                if (res.isValid) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Arsip cadangan valid dan siap dipulihkan.'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res.errorMessage ?? 'Format cadangan tidak valid.'),
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmRestore(BuildContext context, int recordsCount) async {
    unawaited(AppHaptics.selection());
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await MinimalDialog.showConfirm(
      context,
      title: 'Pulihkan Data Cadangan?',
      message:
          'Aplikasi akan mengganti seluruh data yang ada saat ini dengan data dari cadangan ($recordsCount data).\n\nPastikan Anda telah mencadangkan data saat ini bila diperlukan.',
      confirmText: 'Pulihkan Data',
    );

    if (confirm == true && mounted) {
      final jsonStr = _jsonInputController.text;
      final success = await ref
          .read(backupRestoreControllerProvider.notifier)
          .restoreBackup(jsonStr);

      if (success && mounted) {
        _jsonInputController.clear();
        ref.read(backupRestoreControllerProvider.notifier).clearValidation();
        messenger.showSnackBar(
          const SnackBar(content: Text('Data berhasil dipulihkan dengan sempurna!')),
        );
      }
    }
  }

  void _confirmReset(BuildContext context) {
    unawaited(AppHaptics.selection());
    final resetConfirmController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final expenseColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isConfirmed = resetConfirmController.text.trim().toUpperCase() == 'RESET';

          return AlertDialog(
            backgroundColor: surfaceColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 0.8),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: expenseColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Hapus Seluruh Data?',
                  style: AppTypography.title2.copyWith(fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tindakan ini akan menghapus permanen seluruh transaksi, riwayat mutasi, dompet, dan anggaran di perangkat ini.\n\nKetik kata "RESET" di bawah ini untuk mengonfirmasi:',
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: resetConfirmController,
                  style: AppTypography.bodyBold.copyWith(letterSpacing: 1.2),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ketik RESET',
                    hintStyle: TextStyle(
                      letterSpacing: 0,
                      color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor, width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor, width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: expenseColor, width: 1.2),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConfirmed ? expenseColor : (isDark ? Colors.white10 : Colors.black12),
                  foregroundColor: isConfirmed ? Colors.white : (isDark ? Colors.white30 : Colors.black26),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isConfirmed
                    ? () async {
                        Navigator.pop(dialogCtx);
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await ref
                            .read(backupRestoreControllerProvider.notifier)
                            .resetAllData();
                        if (success && mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Seluruh basis data berhasil direset.')),
                          );
                        }
                      }
                    : null,
                child: const Text(
                  'Hapus Semua Data',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(backupRestoreControllerProvider);
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgScaffold = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final incomeColor = isDark ? AppColors.incomeDark : AppColors.incomeLight;
    final expenseColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: AppBar(
        title: const Text('Cadangkan & Pulihkan'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgScaffold,
      ),
      body: state.isLoading
          ? Center(
              child: LoadingIndicator(
                message: state.loadingMessage ?? 'Memproses...',
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
              children: [
                // 1. Informasi Penyimpanan Lokal & Privasi (Flat Minimalis)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Penyimpanan Lokal & Privat',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Data transaksi dan dompet tersimpan 100% offline di perangkat Anda. Berkas cadangan berupa arsip JSON terstruktur yang aman dan dapat dipindahkan antar perangkat.',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Feedback Banner: Error Message (Hening)
                if (state.errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: expenseColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: expenseColor.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: expenseColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: AppTypography.caption.copyWith(color: expenseColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Feedback Banner: Success Message (Hening)
                if (state.successMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: incomeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: incomeColor.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: incomeColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.successMessage!,
                            style: AppTypography.caption.copyWith(color: incomeColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 2. Section: Cadangkan Data (Backup)
                const MinimalSectionHeader(
                  title: 'Cadangkan Data',
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simpan seluruh basis data MyFinance ke dalam berkas cadangan JSON yang valid.',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 19),
                          label: const Text(
                            'Buat & Bagikan Cadangan (JSON)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            unawaited(AppHaptics.selection());
                            ref
                                .read(backupRestoreControllerProvider.notifier)
                                .createAndShareBackup();
                          },
                        ),
                      ),
                      if (state.latestBackupJson != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor, width: 0.8),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 17,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            label: Text(
                              'Salin Teks JSON Cadangan',
                              style: TextStyle(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () {
                              unawaited(AppHaptics.light());
                              Clipboard.setData(ClipboardData(text: state.latestBackupJson!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Teks JSON cadangan berhasil disalin ke papan klip!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Section: Pulihkan Data (Restore)
                const MinimalSectionHeader(
                  title: 'Pulihkan Data',
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pulihkan data dari berkas cadangan JSON yang valid untuk mengembalikan seluruh mutasi dan dompet Anda.',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor, width: 0.8),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(
                            Icons.file_open_outlined,
                            size: 19,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                          label: Text(
                            'Pilih Berkas Cadangan (.json)',
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _pickJsonFile,
                        ),
                      ),

                      // Status Hasil Validasi Arsip Cadangan
                      if (state.validationResult != null) ...[
                        const SizedBox(height: 14),
                        if (state.validationResult!.isValid) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: incomeColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: incomeColor.withValues(alpha: 0.3), width: 0.8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, color: incomeColor, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Arsip Valid (v${state.validationResult!.schemaVersion}) • ${state.validationResult!.totalRecordsCount} data',
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: incomeColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      tooltip: 'Batalkan / Hapus',
                                      splashRadius: 18,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      onPressed: () {
                                        setState(() {
                                          _jsonInputController.clear();
                                        });
                                        ref.read(backupRestoreControllerProvider.notifier).clearValidation();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${state.validationResult!.walletsCount} Dompet • ${state.validationResult!.categoriesCount} Kategori • ${state.validationResult!.transactionsCount} Transaksi • ${state.validationResult!.budgetsCount} Anggaran',
                                  style: AppTypography.caption2.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: incomeColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.restore_rounded, size: 19),
                              label: const Text(
                                'Terapkan Pemulihan Data',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              onPressed: () => _confirmRestore(
                                context,
                                state.validationResult!.totalRecordsCount,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: expenseColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: expenseColor.withValues(alpha: 0.3), width: 0.8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, color: expenseColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.validationResult!.errorMessage ?? 'Arsip tidak valid.',
                                    style: AppTypography.caption.copyWith(color: expenseColor),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  color: expenseColor,
                                  tooltip: 'Batalkan / Hapus',
                                  splashRadius: 18,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: () {
                                    setState(() {
                                      _jsonInputController.clear();
                                    });
                                    ref.read(backupRestoreControllerProvider.notifier).clearValidation();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              Icons.paste_rounded,
                              size: 14,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            label: Text(
                              'atau Tempel / Masukkan Teks Cadangan',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            onPressed: _pasteFromClipboard,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 4. Section: Zona Bahaya (Danger Zone — Hening Tanpa Card Merah Berlebihan)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'ZONA BERBAHAYA',
                    style: AppTypography.caption2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDisabledDark : AppColors.textSecondaryLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Seluruh Data Aplikasi',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: expenseColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Menghapus seluruh mutasi transaksi, dompet, dan anggaran di perangkat ini secara permanen. Tindakan ini tidak dapat dibatalkan.',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: expenseColor,
                            side: BorderSide(
                              color: expenseColor.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, size: 19),
                          label: const Text(
                            'Reset Seluruh Data Aplikasi',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _confirmReset(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
