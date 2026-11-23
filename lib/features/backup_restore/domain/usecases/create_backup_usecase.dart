import '../entities/backup_archive.dart';
import '../repositories/backup_repository.dart';

class CreateBackupUseCase {
  final BackupRepository repository;

  const CreateBackupUseCase(this.repository);

  Future<BackupArchive> execute() {
    return repository.createBackup();
  }

  Future<String> exportJson() {
    return repository.exportBackupJson();
  }
}
