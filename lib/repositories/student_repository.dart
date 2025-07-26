import '../models/student.dart';
import '../models/payment.dart';
import '../database/app_database.dart';

class StudentRepository {
  Future<List<Student>> getAllStudents() async {
    return await AppDatabase.getAllStudents();
  }

  Future<Student?> getStudentById(String id) async {
    return await AppDatabase.getStudentById(id);
  }

  Future<void> insertStudent(Student student) async {
    await AppDatabase.insertStudent(student);
  }

  Future<void> insertStudents(List<Student> students) async {
    await AppDatabase.insertStudents(students);
  }

  Future<void> updateStudent(Student student) async {
    await AppDatabase.updateStudent(student);
  }

  Future<void> deleteStudent(String id) async {
    await AppDatabase.deleteStudent(id);
  }

  Future<void> deleteStudentAndPayments(String studentId) async {
    await AppDatabase.deleteStudentAndPayments(studentId);
  }

  Future<List<Payment>> getAllPayments() async {
    return await AppDatabase.getAllPayments();
  }

  Future<List<Payment>> getPaymentsForStudent(String studentId) async {
    return await AppDatabase.getPaymentsForStudent(studentId);
  }

  Future<void> insertPayment(Payment payment) async {
    await AppDatabase.insertPayment(payment);
  }

  Future<void> insertPayments(List<Payment> payments) async {
    await AppDatabase.insertPayments(payments);
  }

  Future<void> deletePaymentForMonth(String studentId, String month) async {
    await AppDatabase.deletePaymentForMonth(studentId, month);
  }

  // Clear all data method for imports
  Future<void> clearAllData() async {
    await AppDatabase.clearAllData();
  }
}
