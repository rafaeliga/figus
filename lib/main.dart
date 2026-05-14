import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db/database.dart';
import 'data/db/sqlite_native_init.dart'
    if (dart.library.html) 'data/db/sqlite_native_init_stub.dart' as sqlite_native;
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await sqlite_native.ensureBundledSqlite3Ready();

  final db = AppDatabase();
  await db.ensureSeeded();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const FigusApp(),
    ),
  );
}
