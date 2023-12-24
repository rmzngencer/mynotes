import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mynotes/services/crud/crud_exception.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'
    show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;


class NotesService {
  Database? _db;

  List<DatabeseNote> _notes = [];

  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance();
  factory NotesService() => _shared;


  final _notesStreamController =
      StreamController<List<DatabeseNote>>.broadcast();
  
  Stream<List<DatabeseNote>> get allNotes => _notesStreamController.stream;

  Future<DatabaseUser> getOrCreateUSer({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabeseNote> updateNote({
    required DatabeseNote note,
    required String text,
  }) async {
    await _ensureDbOpen();
    final db = _getDatabaseOrThrow();
    //make sure note exists
    await getNote(id: note.id);

    final updatesCount = await db.update(noteTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });
    if (updatesCount == 0) {
      throw CloudNotUpdateNotes();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<Iterable<DatabeseNote>> getAllNotes() async {
    await _ensureDbOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);

    return notes.map((noteRow) => DatabeseNote.fromRow(noteRow));
  
  }

  Future<DatabeseNote> getNote({required int id}) async {
    await _ensureDbOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      final note = DatabeseNote.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbOpen();
    final db = _getDatabaseOrThrow();
    final numberofDeletions = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberofDeletions;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbOpen();
    final db = _getDatabaseOrThrow();
    final deletedCound = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCound == 0) {
      throw CloudNotDeleteNotes();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabeseNote> createNote({required DatabaseUser owner}) async {
    await _ensureDbOpen();
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);
    //make sure if user is  in database in coorect id
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    //create notes
    final noteID = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: '',
      isSyncedWithCloudColumn: 1,
    });

    final note = DatabeseNote(
      id: noteID,
      userId: owner.id,
      text: '',
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      useTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      useTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final id = await db.insert(
      useTable,
      {
        emailColumn: email.toLowerCase(),
      },
    );
    return DatabaseUser(
      id: id,
      email: email,
    );
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbOpen();
    final db = _getDatabaseOrThrow();
    final deletedCound = await db.delete(
      useTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCound != 1) {
      throw CloudNotDeleteUSer();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabeseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabeseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbOpen() async {
    try{
      await open();
    }on DatabaseAlreadyOpenException{
      //ignore
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final dochPath = await getApplicationDocumentsDirectory();
      final dbPath = join(dochPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      //create user Table
      await db.execute(createUserTable);
      //create notes Table
      await db.execute(createNotesTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, dynamic> map)
      : id = map['idColum'] as int,
        email = map['emailColum'] as String;

  @override
  String toString() {
    return 'person, ID = $id, email = $email';
  }

  @override
  bool operator ==(covariant DatabaseUser other) {
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

class DatabeseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;
  const DatabeseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabeseNote.fromRow(Map<String, dynamic> map)
      : id = map['idColum'] as int,
        userId = map['userIdColum'] as int,
        text = map['textColum'] as String,
        isSyncedWithCloud =
            (map['isSyncedWithCloudColum'] as int) == 1 ? true : false;

  @override
  String toString() {
    return 'Notes, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';
  }

  @override
  bool operator ==(covariant DatabeseNote other) {
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const useTable = 'user';
const noteTable = 'notes';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';

const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';

const createNotesTable = '''CREATE TABLE IF NOT EXISTS "notes" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT ,
        "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("user_id") REFERENCES "user"("id")
      );''';
