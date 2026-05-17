import 'package:file_picker/file_picker.dart';

import 'database.dart';

bool get isNativeSqliteFileBackupSupported => false;

Future<void> exportSqliteDatabase(AppDatabase db) async {
  throw UnsupportedError('Backup do arquivo SQLite não está disponível nesta plataforma.');
}

Future<bool> fileLooksLikeSqliteDatabase(String path) async => false;

Future<String?> resolveBackupPickPath(PlatformFile file) async => null;

Future<void> replaceSqliteDatabaseFromBackup(AppDatabase db, String backupSourcePath) async {
  throw UnsupportedError('Restauração do SQLite não está disponível nesta plataforma.');
}
