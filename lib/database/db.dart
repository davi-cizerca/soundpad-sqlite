import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

Future<Database> getDatabase() async {
  sqfliteFfiInit();

  String caminhoDatabase = join(await getDatabasesPath(), 'dogs.db');

  return await openDatabase(
    caminhoDatabase,
    version: 2,
    onCreate: (Database db, int version) async {
      await db.execute('''
        CREATE TABLE dogs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          idade INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE sound_buttons (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          audioPath TEXT NOT NULL,
          cor TEXT,
          categoria TEXT
        )
      ''');
    },
    onUpgrade: (Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE sound_buttons ADD COLUMN categoria TEXT');
      }
    },
  );
}
