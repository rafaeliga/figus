import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../db_paths.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final file = await sqliteDatabaseFile();
    return NativeDatabase.createInBackground(file);
  });
}
