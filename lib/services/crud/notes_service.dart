import 'package:flutter/foundation.dart';
import 'package:mynotes/services/crud/crud_exception.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'
    show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;


class NotesService {
  Database? _db;

  Future<DatabeseNote> updateNote({required DatabeseNote note, required String text}) async {
  final db = _getDatabaseOrThrow();
  await getNote(id: note.id);
  
  final updatesCount = await db.update(noteTable, {
    textColumn: text,
    isSyncedWithCloudColumn: 0,
  });
  if (updatesCount == 0) {
    throw CloudNotUpdateNotes();
    } else {
      return await getNote(id: note.id);
    }
  }

  Future<Iterable<DatabeseNote>> getAllNotes() async{
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);
    
    return notes.map((noteRow) => DatabeseNote.fromRow(noteRow));
   
  }

  Future<DatabeseNote> getNote({required int id}) async {
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
      return DatabeseNote.fromRow(notes.first);
    }
  }

  Future<void> deleteAllNotes() async {
    final db = _getDatabaseOrThrow();
    await db.delete(noteTable);
  }

  Future<void> deleteNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final deletedCound = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCound == 0) {
      throw CloudNotDeleteNotes();
    }
  }

  Future<DatabeseNote> createNote({required DatabaseUser owner}) async {
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

    return note;
  }

  Future<DatabaseUser?> getUser({required String email}) async {
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
