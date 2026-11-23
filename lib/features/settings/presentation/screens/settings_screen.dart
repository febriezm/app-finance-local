import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../app/router.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../backup_restore/presentation/screens/backup_restore_screen.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../reports/presentation/widgets/export_sheet.dart';
import '../../../security/presentation/widgets/pin_setup_sheet.dart';
import '../../../security/presentation/widgets/pin_verify_sheet.dart';

/// Halaman Pengaturan (Settings) — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Karakter Desain:
/// - Daftar terkelompok sederhana (Grouped List) bergaya modern minimalis.
/// - Outline icons dengan palet aksen hening.
/// - Tipografi sederhana dan keterbacaan tinggi.
/// - Divider tipis hairline tanpa card bertumpuk berlebihan.
/// - Mempertahankan seluruh fitur pengaturan: Umum, Tampilan, Mata Uang, Kategori,
///   Manajemen Dompet, Manajemen Data, Keamanan/Privasi, dan Tentang Aplikasi.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showCategoriesSheet(BuildContext context, WidgetRef ref) {
    unawaited(AppHaptics.selection());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseCategoriesAsync = ref.watch(activeCategoriesStreamProvider(CategoryType.expense));
    final incomeCategoriesAsync = ref.watch(activeCategoriesStreamProvider(CategoryType.income));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceModalDark : AppColors.surfaceModalLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
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
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kategori Transaksi',
                style: AppTypography.title2.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Daftar kategori bawaan untuk mencatat pengeluaran dan pemasukan',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                thickness: 0.6,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const MinimalSectionHeader(title: 'Kategori Pengeluaran'),
                    expenseCategoriesAsync.when(
                      data: (categories) => _buildCategoryItemList(categories, isDark),
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                      error: (e, _) => const Text('Gagal memuat kategori pengeluaran'),
                    ),
                    const SizedBox(height: 20),
                    const MinimalSectionHeader(title: 'Kategori Pemasukan'),
                    incomeCategoriesAsync.when(
                      data: (categories) => _buildCategoryItemList(categories, isDark),
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                      error: (e, _) => const Text('Gagal memuat kategori pemasukan'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItemList(List<Category> categories, bool isDark) {
    return Column(
      children: categories.asMap().entries.map((entry) {
        final idx = entry.key;
        final cat = entry.value;
        final color = AppIcons.parseColor(cat.colorHex);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: color.withValues(alpha: isDark ? 0.4 : 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      AppIcons.getIcon(cat.iconKey),
                      size: 18,
                      color: isDark ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevatedDark : AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cat.type == CategoryType.expense ? 'Pengeluaran' : 'Pemasukan',
                      style: AppTypography.caption2.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (idx < categories.length - 1)
              Divider(
                height: 1,
                thickness: 0.6,
                indent: 48,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonthKey = AppDateFormatter.toMonthKey(DateTime.now());
    final themeMode = ref.watch(themeModeProvider);
    final lockState = ref.watch(appLockControllerProvider);
    final walletsAsync = ref.watch(walletsWithBalanceStreamProvider);
    final activeWalletsCount = walletsAsync.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        children: [
          // 1. App Info Header (Minimalist & Quiet)
          _buildAppHeader(isDark),

          const SizedBox(height: 28),

          // 2. Group: General (Umum)
          _buildGroupHeader('UMUM', isDark),
          _buildGroupCard(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.language_rounded,
                iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                title: 'Format Wilayah & Bahasa',
                subtitle: 'Indonesia (id_ID) • DD/MM/YYYY',
                trailingBadge: 'WIB',
                isDark: isDark,
                onTap: () {
                  unawaited(AppHaptics.light());
                  _showInfoDialog(
                    context,
                    title: 'Wilayah & Bahasa',
                    content: 'Aplikasi menggunakan standar lokalisasi Bahasa Indonesia (id_ID) dengan format tanggal tanggal/bulan/tahun dan zona waktu lokal perangkat Anda.',
                  );
                },
              ),
              _buildDivider(isDark),
              _buildSettingTile(
                icon: Icons.calendar_today_outlined,
                iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                title: 'Awal Periode Laporan',
                subtitle: 'Siklus bulanan dimulai tanggal 1',
                trailingBadge: 'Tgl 1',
                isDark: isDark,
                onTap: () {
                  unawaited(AppHaptics.light());
                  _showInfoDialog(
                    context,
                    title: 'Periode Finansial',
                    content: 'Perhitungan anggaran bulanan dan laporan arus kas dihitung otomatis mulai dari tanggal 1 hingga akhir bulan kalender berjalan.',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. Group: Appearance (Tampilan & Tema)
          _buildGroupHeader('TAMPILAN & TEMA', isDark),
          _buildGroupCard(
            isDark: isDark,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: isDark ? 0.4 : 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(Icons.palette_outlined, color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tema Aplikasi',
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Pilih tema terang, gelap, atau ikuti sistem OS',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.brightness_auto_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Terang'),
                        icon: Icon(Icons.light_mode_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Gelap'),
                        icon: Icon(Icons.dark_mode_rounded, size: 16),
                      ),
                    ],
                    selected: {themeMode},
                    style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                    onSelectionChanged: (newSelection) {
                      unawaited(AppHaptics.selection());
                      ref.read(themeModeProvider.notifier).state = newSelection.first;
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Group: Currency (Mata Uang)
          _buildGroupHeader('MATA UANG', isDark),
          _buildGroupCard(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.payments_outlined,
                iconColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                title: 'Mata Uang Utama',
                subtitle: 'Format Rupiah Indonesia (IDR) • Tabular Figures',
                trailingBadge: 'IDR (Rp)',
                isDark: isDark,
                onTap: () {
                  unawaited(AppHaptics.light());
                  _showInfoDialog(
                    context,
                    title: 'Mata Uang & Presisi Angka',
                    content: 'MyFinance menggunakan integer arithmetic untuk seluruh nominal Rupiah tanpa pembulatan desimal (Zero Rounding Error), dengan tipografi Tabular Figures agar digit tersusun rapi.',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 5. Group: Categories (Kategori)
          _buildGroupHeader('KATEGORI TRANSAKSI', isDark),
          _buildGroupCard(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.category_outlined,
                iconColor: Colors.teal,
                title: 'Daftar Kategori',
                subtitle: 'Kelola kategori pengeluaran & pemasukan',
                showChevron: true,
                isDark: isDark,
                onTap: () => _showCategoriesSheet(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 6. Group: Wallet Management (Manajemen Dompet)
          _buildGroupHeader('MANAJEMEN DOMPET', isDark),
          _buildGroupCard(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                title: 'Dompet & Rekening',
                subtitle: '$activeWalletsCount dompet aktif tercatat',
                showChevron: true,
                isDark: isDark,
                onTap: () {
                  unawaited(AppHaptics.light());
                  context.go(AppRouter.wallets);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 7. Group: Data Management (Manajemen Data)
          _buildGroupHeader('MANAJEMEN DATA', isDark),
          _buildGroupCard(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.ios_share_rounded,
                iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                title: 'Ekspor Laporan (PDF / CSV)',
                subtitle: 'Simpan berkas PDF cetak atau tabular CSV',
                showChevron: true,
                isDark: isDark,
                onTap: () {
                  unawaited(AppHaptics.light());
                  ExportSheet.show(context, currentMonthKey);
                },
              ),
              _buildDivider(isDark),
              _buildSettingTile(
                icon: Icons.cloud_sync_outlined,
                iconColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                title: 'Cadangkan & Pulihkan (Backup & Restore)',
                subtitle: 'Ekspor arsip JSON terstruktur atau pulihkan data',
                showChevron: true,
                isDark: isDark,
                onTap: () {
                  unawaited(AppHaptics.light());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupRestoreScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 8. Group: Privacy & Security (Privasi & Keamanan)
          _buildGroupHeader('KEAMANAN & PRIVASI', isDark),
          _buildGroupCard(
            isDark: isDark,
            children: [
              // Switch Kunci Aplikasi
              SwitchListTile.adaptive(
                value: lockState.isAppLockEnabled,
                activeColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.incomeDark : AppColors.incomeLight).withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isDark ? AppColors.incomeDark : AppColors.incomeLight).withValues(alpha: isDark ? 0.4 : 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Kunci Aplikasi',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  lockState.isAppLockEnabled
                      ? (lockState.isBiometricsAvailable && lockState.isBiometricsEnabled
                          ? 'Aktif • Dilindungi ${lockState.biometricLabel} & PIN'
                          : 'Aktif • Dilindungi PIN 6-digit')
                      : 'Minta PIN atau Biometrik saat membuka aplikasi',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                onChanged: (enabled) async {
                  unawaited(AppHaptics.light());
                  if (!context.mounted) return;
                  if (enabled) {
                    final result = await PinSetupSheet.show(context);
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kunci aplikasi berhasil diaktifkan.')),
                      );
                    }
                  } else {
                    final verified = await PinVerifySheet.show(
                      context,
                      title: 'Matikan Kunci Aplikasi',
                      subtitle: 'Masukkan kode sandi PIN untuk menonaktifkan keamanan',
                      onPinEntered: (pin) =>
                          ref.read(appLockControllerProvider.notifier).disableAppLock(pin),
                    );
                    if (verified == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kunci aplikasi telah dinonaktifkan.')),
                      );
                    }
                  }
                },
              ),

              if (lockState.isAppLockEnabled) ...[
                _buildDivider(isDark),
                _buildSettingTile(
                  icon: Icons.pin_outlined,
                  iconColor: Colors.blue,
                  title: 'Ubah Kode Sandi PIN',
                  subtitle: 'Ganti 6-digit PIN kode sandi aplikasi Anda',
                  showChevron: true,
                  isDark: isDark,
                  onTap: () async {
                    unawaited(AppHaptics.light());
                    if (!context.mounted) return;
                    final verified = await PinVerifySheet.show(
                      context,
                      title: 'Verifikasi PIN Saat Ini',
                      subtitle: 'Masukkan kode sandi lama Anda terlebih dahulu',
                      onPinEntered: (pin) =>
                          ref.read(appLockControllerProvider.notifier).unlockWithPin(pin),
                    );

                    if (verified == true && context.mounted) {
                      final changed = await PinSetupSheet.show(context, isChangingPin: true);
                      if (changed == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kode sandi PIN berhasil diubah.')),
                        );
                      }
                    }
                  },
                ),

                if (lockState.isBiometricsAvailable) ...[
                  _buildDivider(isDark),
                  SwitchListTile.adaptive(
                    value: lockState.isBiometricsEnabled,
                    activeColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.incomeDark : AppColors.incomeLight).withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isDark ? AppColors.incomeDark : AppColors.incomeLight).withValues(alpha: isDark ? 0.4 : 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(Icons.fingerprint_rounded, color: isDark ? AppColors.incomeDark : AppColors.incomeLight, size: 20),
                    ),
                    title: Text(
                      'Buka dengan ${lockState.biometricLabel}',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Gunakan biometrik untuk membuka cepat tanpa mengetik PIN',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    onChanged: (val) {
                      unawaited(AppHaptics.light());
                      ref.read(appLockControllerProvider.notifier).setBiometricsEnabled(val);
                    },
                  ),
                ],

                _buildDivider(isDark),
                _buildSettingTile(
                  icon: Icons.screen_lock_portrait_rounded,
                  iconColor: Colors.orange,
                  title: 'Kunci Aplikasi Sekarang',
                  subtitle: 'Uji coba langsung layar kunci tanpa menutup aplikasi',
                  showChevron: true,
                  isDark: isDark,
                  onTap: () {
                    unawaited(AppHaptics.medium());
                    ref.read(appLockControllerProvider.notifier).lock();
                  },
                ),
              ],

              _buildDivider(isDark),
              _buildSettingTile(
                icon: Icons.shield_outlined,
                iconColor: Colors.blue,
                title: 'Jaminan Privasi Offline-First',
                subtitle: 'Tanpa pelacak, analitik, atau server eksternal',
                showChevron: true,
                isDark: isDark,
                onTap: () {
                  unawaited(AppHaptics.light());
                  _showInfoDialog(
                    context,
                    title: 'Privasi 100% Offline',
                    content: 'MyFinance beroperasi sepenuhnya di dalam sandbox perangkat iPhone/ponsel Anda.\n\n'
                        '• Basis data SQLite lokal (Drift Engine)\n'
                        '• OCR struk diproses di perangkat tanpa unggah foto\n'
                        '• Tidak ada server backend, analitik pihak ketiga, atau pelacakan data keuangan.',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 9. Group: About (Tentang Aplikasi)
          _buildGroupHeader('TENTANG APLIKASI', isDark),
          _buildGroupCard(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                title: 'Versi Aplikasi',
                subtitle: 'MyFinance v1.0.0 (Release Build)',
                trailingBadge: 'v1.0.0',
                isDark: isDark,
                onTap: () {
                  unawaited(AppHaptics.light());
                  _showInfoDialog(
                    context,
                    title: 'MyFinance v1.0.0',
                    content: 'Aplikasi manajemen keuangan pribadi modern, minimalis, dan privat yang mematuhi standar akuntansi integer Rupiah dan arsitektur offline-first.',
                  );
                },
              ),
              _buildDivider(isDark),
              _buildSettingTile(
                icon: Icons.description_outlined,
                iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                title: 'Arsitektur & Lisensi',
                subtitle: 'Flutter • Drift SQLite • On-Device OCR',
                showChevron: true,
                isDark: isDark,
                onTap: () {
                  unawaited(AppHaptics.light());
                  _showInfoDialog(
                    context,
                    title: 'Arsitektur & Lisensi',
                    content: 'Dikembangkan dengan arsitektur Clean Architecture, Riverpod, dan Drift SQLite engine.\n\nHak Cipta © 2026 MyFinance. Seluruh data keuangan milik Anda sepenuhnya di perangkat lokal.',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  /// App Info Header Minimalis
  Widget _buildAppHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.incomeDark : AppColors.incomeLight).withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark ? AppColors.incomeDark : AppColors.incomeLight).withValues(alpha: isDark ? 0.4 : 0.25),
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MyFinance',
                      style: AppTypography.title3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.incomeContainerDark : AppColors.incomeContainerLight),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '100% Offline • Penyimpanan Lokal Privat',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header Kategori Group
  Widget _buildGroupHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Container Pembungkus Grup Pengaturan
  Widget _buildGroupCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// Baris Item Pengaturan
  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    String? trailingBadge,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: iconColor.withValues(alpha: isDark ? 0.4 : 0.25),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceModalDark : AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trailingBadge,
                  style: AppTypography.caption2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 56,
      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
    );
  }

  void _showInfoDialog(BuildContext context, {required String title, required String content}) {
    MinimalDialog.showInfo(
      context,
      title: title,
      message: content,
    );
  }
}
