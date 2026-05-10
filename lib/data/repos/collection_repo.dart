import 'package:drift/drift.dart';

import '../db/database.dart';

/// Mutates ownership for a single sticker.
/// UX from refs:  tap → owned · tap again → duplicate (+1) · long press → missing.
class CollectionRepo {
  final AppDatabase db;
  CollectionRepo(this.db);

  Future<int> _activeProfileId() async {
    final p = await (db.select(db.profiles)..where((t) => t.isActive.equals(true))).getSingleOrNull();
    return p?.id ?? (await db.select(db.profiles).get()).first.id;
  }

  Future<Collection?> _entry(int profileId, int stickerId) async {
    return (db.select(db.collections)
          ..where((c) => c.profileId.equals(profileId) & c.stickerId.equals(stickerId)))
        .getSingleOrNull();
  }

  Future<void> _upsert(int profileId, int stickerId, String status, int dupCount) async {
    final existing = await _entry(profileId, stickerId);
    if (existing == null) {
      await db.into(db.collections).insert(CollectionsCompanion.insert(
            profileId: profileId,
            stickerId: stickerId,
            status: Value(status),
            duplicateCount: Value(dupCount),
          ));
    } else {
      await (db.update(db.collections)..where((c) => c.id.equals(existing.id))).write(
        CollectionsCompanion(
          status: Value(status),
          duplicateCount: Value(dupCount),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Cycles: missing → owned → duplicate(+1)
  Future<void> tapSticker(int stickerId) async {
    final pid = await _activeProfileId();
    final e = await _entry(pid, stickerId);
    if (e == null || e.status == 'missing') {
      await _upsert(pid, stickerId, 'owned', 0);
    } else if (e.status == 'owned') {
      await _upsert(pid, stickerId, 'duplicate', 1);
    } else {
      // already duplicate → +1
      await _upsert(pid, stickerId, 'duplicate', e.duplicateCount + 1);
    }
  }

  /// Long press: clears the sticker entirely.
  Future<void> removeSticker(int stickerId) async {
    final pid = await _activeProfileId();
    await _upsert(pid, stickerId, 'missing', 0);
  }
}
