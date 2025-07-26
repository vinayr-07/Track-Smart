import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/payment.dart';
import 'app_database.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static const String _databaseName = 'student_database.db';

  DatabaseHelper._internal();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  // Database utility methods
  Future<bool> isDatabaseEmpty() async {
    final students = await AppDatabase.getAllStudents();
    return students.isEmpty;
  }

  Future<int> getStudentCount() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM students');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPaymentCount() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM payments');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Student-specific helper methods
  Future<List<Student>> getStudentsByBatch(int batch) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'batch = ?',
      whereArgs: [batch],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<List<Student>> searchStudents(String query) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'name LIKE ? OR contact LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<bool> isStudentNameExists(String name, {String? excludeId}) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: excludeId != null ? 'name = ? AND id != ?' : 'name = ?',
      whereArgs: excludeId != null ? [name, excludeId] : [name],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // Payment-specific helper methods
  Future<List<Payment>> getPaymentsByMonth(String month) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'month = ?',
      whereArgs: [month],
      orderBy: 'paymentDate DESC',
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<double> getTotalRevenueForMonth(String month) async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery(
      'SELECT SUM(amountPaid) as total FROM payments WHERE month = ?',
      [month],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalRevenueForStudent(String studentId) async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery(
      'SELECT SUM(amountPaid) as total FROM payments WHERE studentId = ?',
      [studentId],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<Payment?> getPaymentForStudentInMonth(String studentId, String month) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'studentId = ? AND month = ?',
      whereArgs: [studentId, month],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  Future<List<String>> getUnpaidMonthsForStudent(String studentId) async {
    final student = await AppDatabase.getStudentById(studentId);
    if (student == null) return [];

    final formatter = DateFormat('MMM d, yyyy', 'en_US');
    DateTime joiningDate;
    try {
      joiningDate = formatter.parse(student.joiningDate);
    } catch (e) {
      return [];
    }

    final currentDate = DateTime.now();
    final unpaidMonths = <String>[];

    var checkDate = DateTime(joiningDate.year, joiningDate.month);
    while (checkDate.isBefore(DateTime(currentDate.year, currentDate.month + 1))) {
      final monthStr = DateFormat('yyyy-MM').format(checkDate);
      final payment = await getPaymentForStudentInMonth(studentId, monthStr);

      if (payment == null) {
        unpaidMonths.add(monthStr);
      }

      checkDate = DateTime(checkDate.year, checkDate.month + 1);
    }

    return unpaidMonths;
  }

  // Statistics and analytics methods
  Future<Map<String, dynamic>> getMonthlyStatistics(String month) async {
    final db = await AppDatabase.database;

    // Get total students active in this month
    final totalStudentsResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM students 
      WHERE date(substr(joiningDate, 8, 4) || '-' || 
                 CASE substr(joiningDate, 1, 3)
                   WHEN 'Jan' THEN '01'
                   WHEN 'Feb' THEN '02'
                   WHEN 'Mar' THEN '03'
                   WHEN 'Apr' THEN '04'
                   WHEN 'May' THEN '05'
                   WHEN 'Jun' THEN '06'
                   WHEN 'Jul' THEN '07'
                   WHEN 'Aug' THEN '08'
                   WHEN 'Sep' THEN '09'
                   WHEN 'Oct' THEN '10'
                   WHEN 'Nov' THEN '11'
                   WHEN 'Dec' THEN '12'
                 END || '-' || 
                 CASE LENGTH(substr(joiningDate, 5, 2))
                   WHEN 1 THEN '0' || substr(joiningDate, 5, 1)
                   ELSE substr(joiningDate, 5, 2)
                 END) <= ?
    ''', ['$month-01']);

    // Get paid students count
    final paidStudentsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payments WHERE month = ?',
      [month],
    );

    // Get total revenue
    final revenueResult = await db.rawQuery(
      'SELECT SUM(amountPaid) as total FROM payments WHERE month = ?',
      [month],
    );

    final totalStudents = Sqflite.firstIntValue(totalStudentsResult) ?? 0;
    final paidStudents = Sqflite.firstIntValue(paidStudentsResult) ?? 0;
    final totalRevenue = (revenueResult.first['total'] as double?) ?? 0.0;

    return {
      'totalStudents': totalStudents,
      'paidStudents': paidStudents,
      'unpaidStudents': totalStudents - paidStudents,
      'totalRevenue': totalRevenue,
      'collectionRate': totalStudents > 0 ? (paidStudents / totalStudents) * 100 : 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getBatchWiseStatistics(String month) async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery('''
      SELECT 
        s.batch,
        COUNT(s.id) as totalStudents,
        COUNT(p.id) as paidStudents,
        COALESCE(SUM(p.amountPaid), 0) as totalRevenue
      FROM students s
      LEFT JOIN payments p ON s.id = p.studentId AND p.month = ?
      GROUP BY s.batch
      ORDER BY s.batch
    ''', [month]);

    return result.map((row) {
      final totalStudents = row['totalStudents'] as int;
      final paidStudents = row['paidStudents'] as int;
      return {
        'batch': row['batch'],
        'totalStudents': totalStudents,
        'paidStudents': paidStudents,
        'unpaidStudents': totalStudents - paidStudents,
        'totalRevenue': row['totalRevenue'],
        'collectionRate': totalStudents > 0 ? (paidStudents / totalStudents) * 100 : 0.0,
      };
    }).toList();
  }

  // Data validation methods
  Future<List<String>> validateStudentData(Student student) async {
    final errors = <String>[];

    if (student.name.trim().isEmpty) {
      errors.add('Student name cannot be empty');
    }

    if (student.fee <= 0) {
      errors.add('Fee must be greater than zero');
    }

    if (student.batch < 1 || student.batch > 2) {
      errors.add('Invalid batch number');
    }

    if (await isStudentNameExists(student.name, excludeId: student.id)) {
      errors.add('A student with this name already exists');
    }

    return errors;
  }

  Future<bool> validatePaymentData(Payment payment) async {
    if (payment.studentId.isEmpty) return false;
    if (payment.month.isEmpty) return false;
    if (payment.amountPaid <= 0) return false;

    final student = await AppDatabase.getStudentById(payment.studentId);
    return student != null;
  }

  // Backup and restore methods
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, _databaseName);
  }

  Future<bool> backupDatabase(String backupPath) async {
    try {
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restoreDatabase(String backupPath) async {
    try {
      final dbPath = await getDatabasePath();
      final backupFile = File(backupPath);

      if (await backupFile.exists()) {
        // Close current database
        final db = await AppDatabase.database;
        await db.close();

        // Copy backup to database location
        await backupFile.copy(dbPath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Cleanup and maintenance methods
  Future<void> cleanupOldData() async {
    final db = await AppDatabase.database;

    // Remove payments for students that no longer exist
    await db.execute('''
      DELETE FROM payments 
      WHERE studentId NOT IN (SELECT id FROM students)
    ''');
  }

  Future<void> vacuumDatabase() async {
    final db = await AppDatabase.database;
    await db.execute('VACUUM');
  }

  Future<Map<String, int>> getDatabaseInfo() async {
    final db = await AppDatabase.database;

    final studentCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM students')
    ) ?? 0;

    final paymentCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM payments')
    ) ?? 0;

    final dbFile = File(await getDatabasePath());
    final dbSize = await dbFile.exists() ? await dbFile.length() : 0;

    return {
      'studentCount': studentCount,
      'paymentCount': paymentCount,
      'databaseSize': dbSize,
    };
  }

  // Export/Import helper methods
  Future<List<Map<String, dynamic>>> getStudentsWithPayments() async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery('''
      SELECT 
        s.*,
        COUNT(p.id) as totalPayments,
        COALESCE(SUM(p.amountPaid), 0) as totalPaid
      FROM students s
      LEFT JOIN payments p ON s.id = p.studentId
      GROUP BY s.id
      ORDER BY s.name
    ''');

    return result;
  }

  Future<void> clearAllData() async {
    final db = await AppDatabase.database;
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('students');
    });
  }
}
