import 'package:drift/drift.dart';

import '../db/database.dart';

class ProfileRepo {
  final AppDatabase db;
  ProfileRepo(this.db);

  Future<List<Profile>> all() => db.select(db.profiles).get();

  Future<Profile> active() async {
    final p = await (db.select(db.profiles)..where((t) => t.isActive.equals(true))).getSingleOrNull();
    if (p != null) return p;
    final any = await db.select(db.profiles).get();
    if (any.isEmpty) throw StateError('No profiles');
    await setActive(any.first.id);
    return any.first;
  }

  Future<int> create(String name, {int avatarColor = 0xFF1F66FF}) async {
    return db.into(db.profiles).insert(ProfilesCompanion.insert(
          name: name,
          avatarColor: Value(avatarColor),
        ));
  }

  Future<void> setActive(int id) async {
    await db.transaction(() async {
      await db.update(db.profiles).write(const ProfilesCompanion(isActive: Value(false)));
      await (db.update(db.profiles)..where((p) => p.id.equals(id)))
          .write(const ProfilesCompanion(isActive: Value(true)));
    });
  }

  Future<void> rename(int id, String name) async {
    await (db.update(db.profiles)..where((p) => p.id.equals(id)))
        .write(ProfilesCompanion(name: Value(name)));
  }

  Future<void> delete(int id) async {
    final all = await db.select(db.profiles).get();
    if (all.length <= 1) return; // never delete the last profile
    await db.transaction(() async {
      await (db.delete(db.collections)..where((c) => c.profileId.equals(id))).go();
      await (db.delete(db.profiles)..where((p) => p.id.equals(id))).go();
      final remaining = await db.select(db.profiles).get();
      await setActive(remaining.first.id);
    });
  }
}
