import 'package:sqflite/sqflite.dart';
import '../database/db.dart';
import '../model/sound_button_model.dart';

// Insert
Future<int> insertSoundButton(SoundButtonModel button) async {
  Database db = await getDatabase();
  return await db.insert(
    'sound_buttons',
    button.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

// Find all
Future<List<Map>> findAllSoundButtons() async {
  final db = await getDatabase();
  return db.query('sound_buttons');
}

// Remove
Future<int> removeSoundButton(int id) async {
  final db = await getDatabase();
  return db.delete('sound_buttons', where: 'id = ?', whereArgs: [id]);
}
