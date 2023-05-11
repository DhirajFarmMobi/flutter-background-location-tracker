import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = 'Tracking.db';
  static const _databaseVersion = 1;

  static const table = 'track';

  static const columnId = 'id';
  static const columnLatitude = 'latitude';
  static const columnLongitude = 'longitude';
  static const columnTime = 'time';
  static const status = 'status';

  dynamic db;

  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnLatitude TEXT NOT NULL,
            $columnLongitude TEXT NOT NULL,
            $columnTime TEXT NOT NULL,
            $status INT NOT NULL
          )
          ''');
  }

  void insert(Map<String, dynamic> row) {
    if (db != null) {
      db.insert(table, row);
    }
  }

  Future<int> getCount() async {
    var count = 0;
    if (db != null) {
      dynamic list = await db.rawQuery('SELECT * FROM $table where status=0');
      if (list is List<dynamic>) {
        count = list.length;
      }
    }
    return count;
  }

  Future<List<Map>> getData() async {
    final data = <Map>[];
    if (db != null) {
      dynamic list = await db.rawQuery('SELECT * FROM $table where status=0');
      if (list is List<Map>) {
        data.addAll(list);
      }
    }
    return data;
  }

  Future<void> updateData(dynamic row) async {
    dynamic id = row['id'] ?? '';
    if(db!=null){
      await db.update('$table', {'status':1}, where: 'id = ?', whereArgs: [id.toString()]);
    }

  }

  void delete(int id) {
    db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
