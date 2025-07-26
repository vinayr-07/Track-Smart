import 'student.dart';

class Payment {
  final int? id;
  final String studentId;
  final String month;
  final int paymentDate;
  final double amountPaid;

  Payment({
    this.id,
    required this.studentId,
    required this.month,
    required this.paymentDate,
    required this.amountPaid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'month': month,
      'paymentDate': paymentDate,
      'amountPaid': amountPaid,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      studentId: map['studentId'],
      month: map['month'],
      paymentDate: map['paymentDate'],
      amountPaid: map['amountPaid'].toDouble(),
    );
  }
}

class StudentWithPaymentStatus {
  final Student student;
  final bool isPaid;
  final bool isOverdue;
  final int? paymentDate;

  StudentWithPaymentStatus({
    required this.student,
    required this.isPaid,
    required this.isOverdue,
    this.paymentDate,
  });
}

class MonthlyStatus {
  final DateTime month;
  final bool isPaid;
  final DateTime? overdueFrom;

  MonthlyStatus({
    required this.month,
    required this.isPaid,
    this.overdueFrom,
  });
}

class StudentHistory {
  final Student student;
  final List<MonthlyStatus> monthlyStatuses;

  StudentHistory({
    required this.student,
    required this.monthlyStatuses,
  });
}

// REMOVED: enum SortType { nameAsc, nameDesc, feeAsc, feeDesc }
