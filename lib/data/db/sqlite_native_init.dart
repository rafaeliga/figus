import 'dart:io';

import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Ensures bundled native SQLite is loadable (Android/iOS/desktop via [sqlite3_flutter_libs]).
Future<void> ensureBundledSqlite3Ready() async {
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }
}
