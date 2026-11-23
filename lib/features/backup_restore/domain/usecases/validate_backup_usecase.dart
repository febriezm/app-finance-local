import '../entities/restore_validation_result.dart';
import '../repositories/backup_repository.dart';

class ValidateBackupUseCase {
  final BackupRepository repository;

  const ValidateBackupUseCase(this.repository);

  RestoreValidationResult execute(String jsonString) {
    return repository.validateBackupJson(jsonString);
  }
}
