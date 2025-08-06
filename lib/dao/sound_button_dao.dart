import 'package:sqflite/sqflite.dart';
import '../database/db.dart';
import '../model/sound_button_model.dart';

Future<int> insertSoundButton(SoundButtonModel button) async {
  Database db = await getDatabase();
  return await db.insert(
    'sound_buttons',
    button.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Map>> findAllSoundButtons() async {
  final db = await getDatabase();
  return db.query('sound_buttons');
}

Future<List<Map>> findSoundButtonsByCategory(String categoria) async {
  final db = await getDatabase();
  return db.query(
    'sound_buttons',
    where: 'categoria = ?',
    whereArgs: [categoria],
  );
}

Future<List<String>> findAllCategories() async {
  final db = await getDatabase();
  final result = await db.query(
    'sound_buttons',
    distinct: true,
    columns: ['categoria'],
    where: 'categoria IS NOT NULL AND categoria != ""',
  );
  return result.map((map) => map['categoria'] as String).toList();
}

Future<int> removeSoundButton(int id) async {
  final db = await getDatabase();
  return db.delete('sound_buttons', where: 'id = ?', whereArgs: [id]);
}
