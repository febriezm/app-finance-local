import '../repositories/backup_repository.dart';

class RestoreBackupUseCase {
  final BackupRepository repository;

  const RestoreBackupUseCase(this.repository);

  Future<void> execute(String jsonString) {
    return repository.restoreFromJson(jsonString);
  }
}
