import 'package:drift/native.dart';
import 'package:figus/app.dart';
import 'package:figus/data/db/database.dart';
import 'package:figus/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FigusApp builds', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureSeeded();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const FigusApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
