import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../repositories/student_repository.dart';
import '../services/simple_export_service.dart';

class StudentViewModel extends ChangeNotifier {
  final StudentRepository _repository;
  final SimpleExportService _exportService = SimpleExportService();
  final Uuid _uuid = const Uuid();

  List<Student> _allStudents = [];
  List<Payment> _allPayments = [];
  List<StudentWithPaymentStatus> _studentsWithStatus = [];
  DateTime _selectedDate = DateTime.now();
  StudentHistory? _studentHistory;
  final Set<String> _selectedStudentIds = {};
  String _themePreference = "Light";
  String _searchQuery = "";
  bool _isLoading = true;

  // FIXED: Privacy feature for hiding fee amounts
  bool _isFeesVisible = false;

  StudentViewModel(this._repository) {
    _initializeData();
  }

  // Getters
  List<Student> get allStudents => _allStudents;
  List<Payment> get allPayments => _allPayments;
  List<StudentWithPaymentStatus> get studentsWithStatus => _studentsWithStatus;
  DateTime get selectedDate => _selectedDate;
  StudentHistory? get studentHistory => _studentHistory;
  Set<String> get selectedStudentIds => _selectedStudentIds;
  String get themePreference => _themePreference;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  // FIXED: Privacy getter
  bool get isFeesVisible => _isFeesVisible;

  Future<void> _initializeData() async {
    await _loadThemePreference();
    await _loadPrivacyPreference();
    await _refreshData();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _themePreference = prefs.getString('theme_preference') ?? 'Light';
  }

  // FIXED: Privacy preference loading
  Future<void> _loadPrivacyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isFeesVisible = prefs.getBool('fees_visible') ?? false;
  }

  // FIXED: Toggle fee visibility
  Future<void> toggleFeesVisibility() async {
    _isFeesVisible = !_isFeesVisible;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fees_visible', _isFeesVisible);

    notifyListeners();
  }

  Future<void> _refreshData() async {
    _allStudents = await _repository.getAllStudents();
    _allPayments = await _repository.getAllPayments();
    _updateStudentsWithStatus();
  }

  void _updateStudentsWithStatus() {
    final monthStr = DateFormat('yyyy-MM').format(_selectedDate);
    final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());

    var processedStudents = _allStudents.map((student) {
      DateTime studentJoined;
      try {
        final formatter = DateFormat('MMM d, yyyy', 'en_US');
        studentJoined = formatter.parse(student.joiningDate);
      } catch (e) {
        studentJoined = DateTime.now();
      }

      final payment = _allPayments.firstWhere(
            (p) => p.studentId == student.id && p.month == monthStr,
        orElse: () => Payment(
          studentId: '',
          month: '',
          paymentDate: 0,
          amountPaid: 0,
        ),
      );

      bool isOverdue = false;
      if (monthStr == currentMonthStr) {
        final joiningMonth = DateTime(studentJoined.year, studentJoined.month);
        final currentMonth = DateTime.now().year == _selectedDate.year && DateTime.now().month == _selectedDate.month
            ? DateTime(DateTime.now().year, DateTime.now().month)
            : DateTime(_selectedDate.year, _selectedDate.month);

        var checkMonth = joiningMonth;
        while (checkMonth.isBefore(currentMonth)) {
          final checkMonthStr = DateFormat('yyyy-MM').format(checkMonth);
          final hasPayment = _allPayments.any((p) => p.studentId == student.id && p.month == checkMonthStr);

          if (!hasPayment) {
            isOverdue = true;
            break;
          }

          checkMonth = DateTime(checkMonth.year, checkMonth.month + 1);
        }
      } else if (monthStr != currentMonthStr) {
        final joiningMonth = DateTime(studentJoined.year, studentJoined.month);
        final selectedMonth = DateTime(_selectedDate.year, _selectedDate.month);

        var checkMonth = joiningMonth;
        while (checkMonth.isBefore(selectedMonth)) {
          final checkMonthStr = DateFormat('yyyy-MM').format(checkMonth);
          final hasPayment = _allPayments.any((p) => p.studentId == student.id && p.month == checkMonthStr);

          if (!hasPayment) {
            isOverdue = true;
            break;
          }

          checkMonth = DateTime(checkMonth.year, checkMonth.month + 1);
        }

        if (!isOverdue && payment.studentId.isEmpty) {
          isOverdue = true;
        }
      }

      return StudentWithPaymentStatus(
        student: student,
        isPaid: payment.studentId.isNotEmpty,
        paymentDate: payment.studentId.isNotEmpty ? payment.paymentDate : null,
        isOverdue: isOverdue,
      );
    }).where((studentWithStatus) {
      try {
        final formatter = DateFormat('MMM d, yyyy', 'en_US');
        final studentJoined = formatter.parse(studentWithStatus.student.joiningDate);
        return _selectedDate.isAfter(DateTime(studentJoined.year, studentJoined.month - 1));
      } catch (e) {
        return true;
      }
    }).where((studentWithStatus) {
      return studentWithStatus.student.name
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    processedStudents.sort((a, b) => a.student.name.compareTo(b.student.name));

    _studentsWithStatus = processedStudents;
    notifyListeners();
  }

  Future<void> addStudent({
    required String name,
    required double fee,
    required String paymentType,
    required String notes,
    required String contact,
    required String joiningDate,
    required int batch,
    Map<String, bool>? previousMonthPayments,
  }) async {
    final student = Student(
      id: _uuid.v4(),
      name: name,
      fee: fee,
      paymentType: paymentType,
      notes: notes,
      contact: contact,
      joiningDate: joiningDate,
      batch: batch,
    );

    await _repository.insertStudent(student);

    if (previousMonthPayments != null && previousMonthPayments.isNotEmpty) {
      final paymentsToInsert = <Payment>[];

      try {
        for (String monthStr in previousMonthPayments.keys) {
          final isPaid = previousMonthPayments[monthStr] ?? false;

          if (isPaid) {
            final monthDate = DateFormat('yyyy-MM').parse(monthStr);
            final payment = Payment(
              studentId: student.id,
              month: monthStr,
              paymentDate: monthDate.millisecondsSinceEpoch,
              amountPaid: fee,
            );
            paymentsToInsert.add(payment);
          }
        }

        if (paymentsToInsert.isNotEmpty) {
          await _repository.insertPayments(paymentsToInsert);
        }
      } catch (e) {
        debugPrint('Error adding previous month payments: $e');
      }
    }

    await _refreshData();
  }

  Future<void> updateStudent({
    required String id,
    required String name,
    required double fee,
    required String paymentType,
    required String notes,
    required String contact,
    required String joiningDate,
    required int batch,
  }) async {
    final existingStudent = await _repository.getStudentById(id);
    if (existingStudent != null) {
      final updatedStudent = existingStudent.copyWith(
        name: name,
        fee: fee,
        paymentType: paymentType,
        notes: notes,
        contact: contact,
        joiningDate: joiningDate,
        batch: batch,
      );

      await _repository.updateStudent(updatedStudent);
      await _refreshData();
    }
  }

  Future<void> deleteStudent(String studentId) async {
    await _repository.deleteStudentAndPayments(studentId);
    await _refreshData();
  }

  Future<void> updatePaymentStatus(String studentId, bool isPaid, double amount) async {
    final monthStr = DateFormat('yyyy-MM').format(_selectedDate);

    if (isPaid) {
      final payment = Payment(
        studentId: studentId,
        month: monthStr,
        paymentDate: DateTime.now().millisecondsSinceEpoch,
        amountPaid: amount,
      );
      await _repository.insertPayment(payment);
    } else {
      await _repository.deletePaymentForMonth(studentId, monthStr);
    }

    await _refreshData();
  }

  Future<void> updatePaymentForMonth(String studentId, String monthStr, bool isPaid, double amount) async {
    if (isPaid) {
      final payment = Payment(
        studentId: studentId,
        month: monthStr,
        paymentDate: DateTime.now().millisecondsSinceEpoch,
        amountPaid: amount,
      );
      await _repository.insertPayment(payment);
    } else {
      await _repository.deletePaymentForMonth(studentId, monthStr);
    }

    await _refreshData();
  }

  List<String> getOverdueMonths(String studentId) {
    final student = _allStudents.firstWhere((s) => s.id == studentId);
    final formatter = DateFormat('MMM d, yyyy', 'en_US');

    try {
      final joinedDate = formatter.parse(student.joiningDate);
      final joinedMonth = DateTime(joinedDate.year, joinedDate.month);
      final currentMonth = DateTime.now().year == _selectedDate.year && DateTime.now().month == _selectedDate.month
          ? DateTime.now()
          : DateTime(_selectedDate.year, _selectedDate.month);

      List<String> overdueMonths = [];

      var checkMonth = joinedMonth;
      while (checkMonth.isBefore(currentMonth)) {
        final checkMonthStr = DateFormat('yyyy-MM').format(checkMonth);
        final hasPayment = _allPayments.any((p) => p.studentId == studentId && p.month == checkMonthStr);

        if (!hasPayment) {
          overdueMonths.add(checkMonthStr);
        }

        checkMonth = DateTime(checkMonth.year, checkMonth.month + 1);
      }

      return overdueMonths;
    } catch (e) {
      return [];
    }
  }

  void toggleStudentSelection(String studentId) {
    if (_selectedStudentIds.contains(studentId)) {
      _selectedStudentIds.remove(studentId);
    } else {
      _selectedStudentIds.add(studentId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedStudentIds.clear();
    notifyListeners();
  }

  Future<void> markSelectedAsPaid() async {
    final monthStr = DateFormat('yyyy-MM').format(_selectedDate);
    final paymentsToInsert = <Payment>[];

    for (String studentId in _selectedStudentIds) {
      final student = _allStudents.firstWhere((s) => s.id == studentId);
      paymentsToInsert.add(Payment(
        studentId: studentId,
        month: monthStr,
        paymentDate: DateTime.now().millisecondsSinceEpoch,
        amountPaid: student.fee,
      ));
    }

    await _repository.insertPayments(paymentsToInsert);
    clearSelection();
    await _refreshData();
  }

  void goToPresentMonth() {
    _selectedDate = DateTime.now();
    _updateStudentsWithStatus();
  }

  void goToPreviousMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    _updateStudentsWithStatus();
  }

  void goToNextMonth() {
    final now = DateTime.now();
    if (_selectedDate.isBefore(DateTime(now.year, now.month))) {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      _updateStudentsWithStatus();
    }
  }

  Future<void> showHistory(Student student) async {
    final payments = await _repository.getPaymentsForStudent(student.id);
    final formatter = DateFormat('MMM d, yyyy', 'en_US');

    DateTime joiningMonth;
    try {
      joiningMonth = formatter.parse(student.joiningDate);
    } catch (e) {
      joiningMonth = DateTime.now();
    }

    final currentMonth = DateTime.now();
    final monthlyStatuses = <MonthlyStatus>[];
    DateTime? firstUnpaidInStreak;

    var month = DateTime(joiningMonth.year, joiningMonth.month);
    while (month.isBefore(currentMonth) || month.isAtSameMomentAs(DateTime(currentMonth.year, currentMonth.month))) {
      final monthStr = DateFormat('yyyy-MM').format(month);
      final isPaidThisMonth = payments.any((p) => p.month == monthStr);

      if (isPaidThisMonth) {
        monthlyStatuses.add(MonthlyStatus(
          month: month,
          isPaid: true,
          overdueFrom: null,
        ));
        firstUnpaidInStreak = null;
      } else {
        firstUnpaidInStreak ??= month;
        final overdueStatus = month.isAfter(firstUnpaidInStreak) ? firstUnpaidInStreak : null;
        monthlyStatuses.add(MonthlyStatus(
          month: month,
          isPaid: false,
          overdueFrom: overdueStatus,
        ));
      }

      month = DateTime(month.year, month.month + 1);
    }

    _studentHistory = StudentHistory(
      student: student,
      monthlyStatuses: monthlyStatuses.reversed.toList(),
    );
    notifyListeners();
  }

  Future<String> exportData() async {
    try {
      if (_allStudents.isEmpty) {
        return 'No student data to export.\nPlease add some students first.';
      }

      final result = await _exportService.exportStudentsAsJson(_allStudents, _allPayments);
      return result;
    } catch (e) {
      return 'Export Failed!\n${e.toString()}';
    }
  }

  Future<String> importDataWithMerge() async {
    try {
      final importData = await _exportService.importStudentsFromJsonWithMerge(
          _allStudents,
          _allPayments
      );

      final students = importData['students'] as List<Student>;
      final payments = importData['payments'] as List<Payment>;
      final metadata = importData['metadata'] as Map<String, dynamic>;
      final mergeStats = importData['mergeStats'] as Map<String, dynamic>;

      if (students.isEmpty) {
        return 'Import Failed!\nNo valid students found in the backup file.';
      }

      try {
        await _repository.clearAllData();
        await _repository.insertStudents(students);
        if (payments.isNotEmpty) {
          await _repository.insertPayments(payments);
        }
      } catch (e) {
        throw Exception('Failed to save merged data: ${e.toString()}');
      }

      await _refreshData();

      final exportDate = DateTime.parse(metadata['exportDate']).toLocal();
      final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(exportDate);

      return 'Smart Import Successful!\n'
          '📊 Merge Summary:\n'
          '• ${mergeStats['newStudents']} new students added\n'
          '• ${mergeStats['updatedStudents']} existing students updated\n'
          '• ${mergeStats['newPayments']} new payment records\n'
          '• ${mergeStats['skippedPayments']} duplicate payments skipped\n\n'
          '📈 Final Totals:\n'
          '• ${mergeStats['totalStudents']} total students\n'
          '• ${mergeStats['totalPayments']} total payment records\n\n'
          'Backup created: $formattedDate';
    } catch (e) {
      return 'Import Failed!\n${e.toString()}';
    }
  }

  Future<String> importData() async {
    try {
      final importData = await _exportService.importStudentsFromJson();

      final students = importData['students'] as List<Student>;
      final payments = importData['payments'] as List<Payment>;
      final metadata = importData['metadata'] as Map<String, dynamic>;

      if (students.isEmpty) {
        return 'Import Failed!\nNo valid students found in the backup file.';
      }

      try {
        await _repository.clearAllData();
        await _repository.insertStudents(students);
        if (payments.isNotEmpty) {
          await _repository.insertPayments(payments);
        }
      } catch (e) {
        throw Exception('Failed to import data: ${e.toString()}');
      }

      await _refreshData();

      final exportDate = DateTime.parse(metadata['exportDate']).toLocal();
      final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(exportDate);

      return 'Import Successful!\n'
          '${students.length} students restored\n'
          '${payments.length} payment records restored\n'
          'Backup created: $formattedDate';
    } catch (e) {
      return 'Import Failed!\n${e.toString()}';
    }
  }

  String getBackupFolderPath() {
    return _exportService.getBackupFolderPath();
  }

  Future<List<String>> getAvailableBackupFiles() async {
    return await _exportService.getAvailableBackupFiles();
  }

  Future<void> changeTheme(String preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_preference', preference);
    _themePreference = preference;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _updateStudentsWithStatus();
  }
}
