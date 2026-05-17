/// Native SQLite initialization for mobile/desktop.
///
/// [sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs) reached EOL (`0.6.0+eol`)
/// — the workaround API was removed while `sqlite3`/Drift bundles libraries as needed on current
/// toolchains.
Future<void> ensureBundledSqlite3Ready() async {}
