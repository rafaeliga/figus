import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Same basename as [native.dart] — single source of truth for the path.
const String kFigusSqliteFileName = 'figus.sqlite';

Future<File> sqliteDatabaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, kFigusSqliteFileName));
}
