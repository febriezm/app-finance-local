import '../repositories/backup_repository.dart';

class ResetDatabaseUseCase {
  final BackupRepository repository;

  const ResetDatabaseUseCase(this.repository);

  Future<void> execute() {
    return repository.resetAllData();
  }
}
