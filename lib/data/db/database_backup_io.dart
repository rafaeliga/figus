import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:share_plus/share_plus.dart';

import 'database.dart';
import 'db_paths.dart';

bool get isNativeSqliteFileBackupSupported => true;

Future<void> exportSqliteDatabase(AppDatabase db) async {
  try {
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
  } catch (_) {
    // Memory DB / executor quirks — still attempt copy.
  }

  final src = await sqliteDatabaseFile();
  if (!await src.exists()) {
    throw StateError('Arquivo do banco não encontrado.');
  }

  final tmpDir = await getTemporaryDirectory();
  final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
  final copyPath = p.join(tmpDir.path, 'figus_backup_$stamp.sqlite');
  await src.copy(copyPath);

  await Share.shareXFiles(
    [XFile(copyPath, mimeType: 'application/x-sqlite3', name: p.basename(copyPath))],
    subject: 'Backup Figus',
  );
}

/// iCloud / Android SAF often omit [PlatformFile.path]; [PlatformFile.bytes]
/// is populated when picking with `withData: true`.
Future<String?> resolveBackupPickPath(PlatformFile file) async {
  final pth = file.path;
  if (pth != null && pth.isNotEmpty) {
    final f = File(pth);
    if (await f.exists()) return pth;
  }
  final bytes = file.bytes;
  if (bytes != null && bytes.isNotEmpty) {
    final tmpDir = await getTemporaryDirectory();
    final tmp = File(
      p.join(tmpDir.path, 'figus_restore_pick_${DateTime.now().millisecondsSinceEpoch}.sqlite'),
    );
    await tmp.writeAsBytes(bytes, flush: true);
    return tmp.path;
  }
  return null;
}

Future<bool> fileLooksLikeSqliteDatabase(String path) async {
  final f = File(path);
  if (!await f.exists()) return false;
  try {
    final raf = await f.open(mode: FileMode.read);
    try {
      final bytes = await raf.read(15);
      if (bytes.length < 15) return false;
      return String.fromCharCodes(bytes) == 'SQLite format 3';
    } finally {
      await raf.close();
    }
  } catch (_) {
    return false;
  }
}

Future<void> replaceSqliteDatabaseFromBackup(AppDatabase db, String backupSourcePath) async {
  final src = File(backupSourcePath);
  if (!await src.exists()) {
    throw StateError('Arquivo de backup não encontrado.');
  }
  if (!await fileLooksLikeSqliteDatabase(backupSourcePath)) {
    throw const FormatException('O arquivo não parece ser um banco SQLite válido.');
  }

  final dest = await sqliteDatabaseFile();
  final destWal = File('${dest.path}-wal');
  final destShm = File('${dest.path}-shm');

  await db.close();

  if (await destWal.exists()) await destWal.delete();
  if (await destShm.exists()) await destShm.delete();
  if (await dest.exists()) await dest.delete();

  await src.copy(dest.path);

  await Restart.restartApp();
}
