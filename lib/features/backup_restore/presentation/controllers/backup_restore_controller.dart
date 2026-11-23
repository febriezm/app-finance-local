import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/utils/file_export_helper.dart';
import '../../domain/entities/backup_archive.dart';
import '../../domain/entities/restore_validation_result.dart';
import '../../domain/usecases/create_backup_usecase.dart';
import '../../domain/usecases/reset_database_usecase.dart';
import '../../domain/usecases/restore_backup_usecase.dart';
import '../../domain/usecases/validate_backup_usecase.dart';

class BackupRestoreState {
  final bool isLoading;
  final String? loadingMessage;
  final String? errorMessage;
  final String? successMessage;
  final BackupArchive? latestBackup;
  final String? latestBackupJson;
  final RestoreValidationResult? validationResult;

  const BackupRestoreState({
    this.isLoading = false,
    this.loadingMessage,
    this.errorMessage,
    this.successMessage,
    this.latestBackup,
    this.latestBackupJson,
    this.validationResult,
  });

  BackupRestoreState copyWith({
    bool? isLoading,
    String? loadingMessage,
    String? errorMessage,
    String? successMessage,
    BackupArchive? latestBackup,
    String? latestBackupJson,
    RestoreValidationResult? validationResult,
    bool clearValidationResult = false,
    bool clearLatestBackup = false,
    bool clearMessages = false,
  }) {
    return BackupRestoreState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: clearMessages ? null : (loadingMessage ?? this.loadingMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      latestBackup: clearLatestBackup ? null : (latestBackup ?? this.latestBackup),
      latestBackupJson: clearLatestBackup ? null : (latestBackupJson ?? this.latestBackupJson),
      validationResult: clearValidationResult ? null : (validationResult ?? this.validationResult),
    );
  }
}

class BackupRestoreController extends StateNotifier<BackupRestoreState> {
  final CreateBackupUseCase _createBackupUseCase;
  final ValidateBackupUseCase _validateBackupUseCase;
  final RestoreBackupUseCase _restoreBackupUseCase;
  final ResetDatabaseUseCase _resetDatabaseUseCase;
  final Ref _ref;

  BackupRestoreController({
    required CreateBackupUseCase createBackupUseCase,
    required ValidateBackupUseCase validateBackupUseCase,
    required RestoreBackupUseCase restoreBackupUseCase,
    required ResetDatabaseUseCase resetDatabaseUseCase,
    required Ref ref,
  })  : _createBackupUseCase = createBackupUseCase,
        _validateBackupUseCase = validateBackupUseCase,
        _restoreBackupUseCase = restoreBackupUseCase,
        _resetDatabaseUseCase = resetDatabaseUseCase,
        _ref = ref,
        super(const BackupRestoreState());

  void resetState() {
    state = const BackupRestoreState();
  }

  void clearValidation() {
    state = state.copyWith(
      clearValidationResult: true,
      clearMessages: true,
    );
  }

  Future<void> createAndShareBackup() async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Membuat arsip cadangan...',
      errorMessage: null,
      successMessage: null,
    );

    try {
      final jsonString = await _createBackupUseCase.exportJson();
      final archive = await _createBackupUseCase.execute();

      final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = 'MyFinance_Backup_$nowStr.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      // Simpan backup di state lebih awal agar tombol Salin JSON langsung aktif
      state = state.copyWith(
        latestBackup: archive,
        latestBackupJson: jsonString,
      );

      // Gunakan FileExportHelper: Download otomatis di Web, Share Sheet di iOS/Android
      await FileExportHelper.saveOrShare(
        bytes: bytes,
        filename: filename,
        mimeType: 'application/json',
        subject: 'Cadangan Data MyFinance ($nowStr)',
      );

      state = state.copyWith(
        isLoading: false,
        latestBackup: archive,
        latestBackupJson: jsonString,
        successMessage: kIsWeb
            ? 'Cadangan berhasil dibuat & diunduh (${archive.totalRecordsCount} data).'
            : 'Cadangan berhasil dibuat (${archive.totalRecordsCount} data).',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membuat cadangan: $e',
      );
    }
  }

  RestoreValidationResult validateJson(String jsonString) {
    final result = _validateBackupUseCase.execute(jsonString);
    state = state.copyWith(validationResult: result);
    return result;
  }

  Future<bool> restoreBackup(String jsonString) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Memulihkan data secara atomik...',
      errorMessage: null,
      successMessage: null,
    );

    try {
      await _restoreBackupUseCase.execute(jsonString);

      // Invalidate providers to force refresh across the entire app
      _ref.invalidate(walletsWithBalanceStreamProvider);
      _ref.invalidate(archivedWalletsWithBalanceStreamProvider);
      _ref.invalidate(recentTransactionsStreamProvider);
      _ref.invalidate(totalAssetBalanceProvider);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Data berhasil dipulihkan dengan sempurna!',
        clearValidationResult: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memulihkan cadangan: $e',
      );
      return false;
    }
  }

  Future<bool> resetAllData() async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Mengosongkan seluruh data...',
      errorMessage: null,
      successMessage: null,
    );

    try {
      await _resetDatabaseUseCase.execute();

      // Invalidate providers
      _ref.invalidate(walletsWithBalanceStreamProvider);
      _ref.invalidate(archivedWalletsWithBalanceStreamProvider);
      _ref.invalidate(recentTransactionsStreamProvider);
      _ref.invalidate(totalAssetBalanceProvider);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Seluruh data transaksi dan dompet berhasil direset.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mereset data: $e',
      );
      return false;
    }
  }
}
