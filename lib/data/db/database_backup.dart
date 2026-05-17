import 'package:file_picker/file_picker.dart';

import 'database.dart';

import 'database_backup_stub.dart'
    if (dart.library.io) 'database_backup_io.dart' as impl;

bool get isNativeSqliteFileBackupSupported => impl.isNativeSqliteFileBackupSupported;

Future<void> exportSqliteDatabase(AppDatabase db) => impl.exportSqliteDatabase(db);

Future<bool> fileLooksLikeSqliteDatabase(String path) => impl.fileLooksLikeSqliteDatabase(path);

Future<String?> resolveBackupPickPath(PlatformFile file) => impl.resolveBackupPickPath(file);

Future<void> replaceSqliteDatabaseFromBackup(AppDatabase db, String backupSourcePath) =>
    impl.replaceSqliteDatabaseFromBackup(db, backupSourcePath);
