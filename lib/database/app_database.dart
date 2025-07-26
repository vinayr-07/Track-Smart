import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/payment.dart';

class AppDatabase {
  static Database? _database;
  static const String _databaseName = 'student_tracker.db';
  static const int _databaseVersion = 1;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        fee REAL NOT NULL,
        paymentType TEXT NOT NULL,
        notes TEXT,
        contact TEXT,
        joiningDate TEXT NOT NULL,
        batch INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId TEXT NOT NULL,
        month TEXT NOT NULL,
        paymentDate INTEGER NOT NULL,
        amountPaid REAL NOT NULL,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');
  }

  // Student operations
  static Future<List<Student>> getAllStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('students');
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  static Future<Student?> getStudentById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> insertStudent(Student student) async {
    final db = await database;
    await db.insert('students', student.toMap());
  }

  static Future<void> insertStudents(List<Student> students) async {
    final db = await database;
    final batch = db.batch();
    for (final student in students) {
      batch.insert('students', student.toMap());
    }
    await batch.commit();
  }

  static Future<void> updateStudent(Student student) async {
    final db = await database;
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  static Future<void> deleteStudent(String id) async {
    final db = await database;
    await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteStudentAndPayments(String studentId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments', where: 'studentId = ?', whereArgs: [studentId]);
      await txn.delete('students', where: 'id = ?', whereArgs: [studentId]);
    });
  }

  // Payment operations
  static Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('payments');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  static Future<List<Payment>> getPaymentsForStudent(String studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  static Future<void> insertPayment(Payment payment) async {
    final db = await database;
    await db.insert('payments', payment.toMap());
  }

  static Future<void> insertPayments(List<Payment> payments) async {
    final db = await database;
    final batch = db.batch();
    for (final payment in payments) {
      batch.insert('payments', payment.toMap());
    }
    await batch.commit();
  }

  static Future<void> deletePaymentForMonth(String studentId, String month) async {
    final db = await database;
    await db.delete(
      'payments',
      where: 'studentId = ? AND month = ?',
      whereArgs: [studentId, month],
    );
  }

  // ADDED: Clear all data
  static Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('students');
    });
  }
}
