import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'member.dart';
import 'fee.dart';

// Simple singleton database service using sqflite.
// Stores two tables: members & fees. Fees reference members via memberId.

class DBService {
  static final DBService _i = DBService._();
  DBService._();
  factory DBService() => _i;
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final file = p.join(await getDatabasesPath(), 'gym_flat.db');
    _db = await openDatabase(
      file,
      version: 3,
      onCreate: (d, v) async {
        await d.execute('''CREATE TABLE members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        contact TEXT,
        plan TEXT,
        attendance INTEGER,
        join_date TEXT,
        expiry_date TEXT
      )''');
        await d.execute('''CREATE TABLE fees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memberId INTEGER,
        amount REAL,
        dueDate TEXT,
        status TEXT,
        paymentDate TEXT,
        FOREIGN KEY(memberId) REFERENCES members(id) ON DELETE CASCADE
      )''');
        await d.execute('''CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )''');
      },
      onUpgrade: (d, oldV, newV) async {
        if (oldV < 2) {
          // Add new columns if upgrading existing installs
          await d.execute('ALTER TABLE members ADD COLUMN join_date TEXT');
          await d.execute('ALTER TABLE members ADD COLUMN expiry_date TEXT');
        }
        if (oldV < 3) {
          await d.execute('''CREATE TABLE IF NOT EXISTS settings(
            key TEXT PRIMARY KEY,
            value TEXT
          )''');
        }
      },
    );
    return _db!;
  }

  // ---------------- Member CRUD ----------------
  Future<int> insertMember(Member m) async =>
      (await db).insert('members', m.toMap());
  Future<List<Member>> fetchMembers() async =>
      (await (await db).query('members')).map(Member.fromMap).toList();
  Future<int> updateMember(Member m) async =>
      (await db).update('members', m.toMap(), where: 'id=?', whereArgs: [m.id]);
  Future<int> deleteMember(int id) async =>
      (await db).delete('members', where: 'id=?', whereArgs: [id]);

  // ---------------- Fee CRUD -------------------
  Future<int> insertFee(Fee f) async => (await db).insert('fees', f.toMap());
  Future<List<Fee>> feesFor(int memberId) async => (await (await db).query(
    'fees',
    where: 'memberId=?',
    whereArgs: [memberId],
  )).map(Fee.fromMap).toList();
  Future<int> markPaid(Fee f) async {
    f.status = 'Paid';
    f.paymentDate = DateTime.now().toIso8601String();
    return (await db).update(
      'fees',
      f.toMap(),
      where: 'id=?',
      whereArgs: [f.id],
    );
  }

  Future<int> deleteFee(int id) async =>
      (await db).delete('fees', where: 'id=?', whereArgs: [id]);

  // ---------------- Settings ------------------
  Future<void> setSetting(String key, String value) async {
    final database = await db;
    await database.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final database = await db;
    final rows = await database.query(
      'settings',
      where: 'key=?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }
}
