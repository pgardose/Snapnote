import '../models/entry.dart';
import 'database_helper.dart';

/// Thin repository around [DatabaseHelper] for [Entry] CRUD.
class EntryRepository {
  EntryRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  Future<Entry> create({
    required int subjectId,
    required String content,
    String? sourceImagePath,
  }) {
    final now = DateTime.now();
    return _db.createEntry(
      Entry(
        subjectId: subjectId,
        content: content,
        sourceImagePath: sourceImagePath,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<List<Entry>> getForSubject(int subjectId) {
    return _db.getEntriesForSubject(subjectId);
  }

  Future<Entry?> getById(int id) => _db.getEntry(id);

  Future<void> update(Entry entry, {required String newContent}) {
    return _db
        .updateEntry(entry.copyWith(content: newContent, updatedAt: DateTime.now()))
        .then((_) {});
  }

  Future<void> delete(int id) => _db.deleteEntry(id).then((_) {});
}
