//Arquivo responsável por criar o banco de dados SQLite para o app.

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

Future<Database> getDatabase() async {
  // Inicializa o databaseFactory para sqflite_common_ffi
  sqfliteFfiInit();

  String caminhoDatabase = join(await getDatabasesPath(), 'dogs.db');

  return await openDatabase(
    caminhoDatabase,
    version: 1,
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
          cor TEXT
        )
      ''');
    },
  );
}
