import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/payment.dart';

class SimpleExportService {

  Future<String> exportStudentsAsJson(List<Student> students, List<Payment> payments) async {
    try {
      if (students.isEmpty) {
        return 'No student data to export.';
      }

      final backupData = {
        'metadata': {
          'exportDate': DateTime.now().toIso8601String(),
          'exportDateFormatted': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
          'version': '1.0.0',
          'totalStudents': students.length,
          'totalPayments': payments.length,
          'appName': 'Track Smart',
        },
        'students': students.map((student) {
          final studentPayments = payments.where((p) => p.studentId == student.id).toList();

          return {
            'id': student.id,
            'name': student.name,
            'joiningDate': student.joiningDate,
            'fee': student.fee,
            'paymentType': student.paymentType,
            'batch': student.batch,
            'contact': student.contact ?? '',
            'notes': student.notes ?? '',
            'paymentHistory': studentPayments.map((payment) => {
              'month': payment.month,
              'paymentDate': payment.paymentDate,
              'amountPaid': payment.amountPaid,
              'paymentDateFormatted': DateFormat('dd MMM yyyy, hh:mm a')
                  .format(DateTime.fromMillisecondsSinceEpoch(payment.paymentDate)),
            }).toList(),
          };
        }).toList(),
        'summary': {
          'batchWiseCount': {
            'batch1': students.where((s) => s.batch == 1).length,
            'batch2': students.where((s) => s.batch == 2).length,
          },
          'totalFeeCollected': payments.fold<double>(0, (sum, p) => sum + p.amountPaid),
          'paymentMethods': students.map((s) => s.paymentType).toSet().toList(),
        }
      };

      String jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      Directory baseDirectory;

      if (Platform.isAndroid) {
        baseDirectory = Directory('/storage/emulated/0/Download');
        if (!await baseDirectory.exists()) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            baseDirectory = Directory('${externalDir.path}/Download');
          } else {
            baseDirectory = await getApplicationDocumentsDirectory();
          }
        }
      } else {
        baseDirectory = await getApplicationDocumentsDirectory();
      }

      final backupsDir = Directory('${baseDirectory.path}/backups');
      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }

      final trackSmartDir = Directory('${backupsDir.path}/TrackSmart');
      if (!await trackSmartDir.exists()) {
        await trackSmartDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'track_smart_backup_$timestamp.json';
      final filePath = '${trackSmartDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(jsonString);

      if (await file.exists()) {
        final fileSize = await file.length();
        final fileSizeKB = (fileSize / 1024).toStringAsFixed(1);

        return 'Backup created successfully!\n'
            'Location: Downloads/backups/TrackSmart/\n'
            'File: $fileName\n'
            'Size: ${fileSizeKB}KB\n'
            'Students: ${students.length}\n'
            'Payment Records: ${payments.length}';
      } else {
        throw Exception('File was not created successfully');
      }

    } catch (e) {
      return 'Export failed: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> importStudentsFromJsonWithMerge(
      List<Student> existingStudents,
      List<Payment> existingPayments
      ) async {
    try {
      String? initialDirectory;
      if (Platform.isAndroid) {
        initialDirectory = '/storage/emulated/0/Download/backups/TrackSmart';
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Track Smart Backup File',
        initialDirectory: initialDirectory,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath == null) {
          throw Exception('Invalid file path');
        }

        final file = File(filePath);

        if (!await file.exists()) {
          throw Exception('Selected file does not exist');
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('Selected file is empty');
        }

        final jsonString = await file.readAsString();
        final Map<String, dynamic> backupData = json.decode(jsonString);

        if (!_validateBackupFormat(backupData)) {
          throw Exception('Invalid backup file format. Please select a valid Track Smart backup file.');
        }

        final mergeResult = _mergeStudentData(
            backupData,
            existingStudents,
            existingPayments
        );

        return mergeResult;
      }

      throw Exception('No file selected');
    } catch (e) {
      throw Exception('Import failed: ${e.toString()}');
    }
  }

  Map<String, dynamic> _mergeStudentData(
      Map<String, dynamic> backupData,
      List<Student> existingStudents,
      List<Payment> existingPayments,
      ) {
    final List<Student> finalStudents = [];
    final List<Payment> finalPayments = [];

    int newStudents = 0;
    int updatedStudents = 0;
    int newPayments = 0;
    int skippedPayments = 0;

    final Map<String, Student> existingStudentsMap = {
      for (Student s in existingStudents) s.id: s
    };

    final Map<String, Student> existingStudentsByNameBatch = {
      for (Student s in existingStudents)
        '${s.name.toLowerCase().trim()}_${s.batch}': s
    };

    final Set<String> existingPaymentKeys = existingPayments
        .map((p) => '${p.studentId}_${p.month}')
        .toSet();

    finalStudents.addAll(existingStudents);
    finalPayments.addAll(existingPayments);

    final studentsData = backupData['students'] as List<dynamic>? ?? [];

    for (final studentData in studentsData) {
      try {
        if (studentData == null ||
            studentData['id'] == null ||
            studentData['name'] == null ||
            studentData['fee'] == null ||
            studentData['batch'] == null ||
            studentData['joiningDate'] == null ||
            studentData['paymentType'] == null) {
          continue;
        }

        final backupStudent = Student(
          id: studentData['id'].toString(),
          name: studentData['name'].toString().trim(),
          joiningDate: studentData['joiningDate'].toString(),
          fee: (studentData['fee'] as num).toDouble(),
          paymentType: studentData['paymentType'].toString(),
          batch: (studentData['batch'] as num).toInt(),
          contact: studentData['contact']?.toString().isEmpty == true
              ? null
              : studentData['contact']?.toString(),
          notes: studentData['notes']?.toString().isEmpty == true
              ? null
              : studentData['notes']?.toString(),
        );

        Student? existingStudent = existingStudentsMap[backupStudent.id];
        if (existingStudent == null) {
          final lookupKey = '${backupStudent.name.toLowerCase()}_${backupStudent.batch}';
          existingStudent = existingStudentsByNameBatch[lookupKey];
        }

        if (existingStudent != null) {
          bool needsUpdate = false;
          Student updatedStudent = existingStudent;

          if (existingStudent.name != backupStudent.name ||
              existingStudent.fee != backupStudent.fee ||
              existingStudent.paymentType != backupStudent.paymentType ||
              existingStudent.contact != backupStudent.contact ||
              existingStudent.notes != backupStudent.notes ||
              existingStudent.joiningDate != backupStudent.joiningDate) {

            updatedStudent = existingStudent.copyWith(
              name: backupStudent.name,
              fee: backupStudent.fee,
              paymentType: backupStudent.paymentType,
              contact: backupStudent.contact,
              notes: backupStudent.notes,
              joiningDate: backupStudent.joiningDate,
            );
            needsUpdate = true;
          }

          if (needsUpdate) {
            final index = finalStudents.indexWhere((s) => s.id == existingStudent!.id);
            if (index != -1) {
              finalStudents[index] = updatedStudent;
              updatedStudents++;
            }
          }

          final paymentHistory = studentData['paymentHistory'] as List<dynamic>? ?? [];
          for (final paymentData in paymentHistory) {
            try {
              if (paymentData == null ||
                  paymentData['month'] == null ||
                  paymentData['paymentDate'] == null ||
                  paymentData['amountPaid'] == null) {
                continue;
              }

              final paymentKey = '${existingStudent.id}_${paymentData['month']}';

              if (!existingPaymentKeys.contains(paymentKey)) {
                final payment = Payment(
                  studentId: existingStudent.id,
                  month: paymentData['month'].toString(),
                  paymentDate: (paymentData['paymentDate'] as num).toInt(),
                  amountPaid: (paymentData['amountPaid'] as num).toDouble(),
                );
                finalPayments.add(payment);
                existingPaymentKeys.add(paymentKey);
                newPayments++;
              } else {
                skippedPayments++;
              }
            } catch (e) {
              continue;
            }
          }

        } else {
          finalStudents.add(backupStudent);
          newStudents++;

          final paymentHistory = studentData['paymentHistory'] as List<dynamic>? ?? [];
          for (final paymentData in paymentHistory) {
            try {
              if (paymentData == null ||
                  paymentData['month'] == null ||
                  paymentData['paymentDate'] == null ||
                  paymentData['amountPaid'] == null) {
                continue;
              }

              final payment = Payment(
                studentId: backupStudent.id,
                month: paymentData['month'].toString(),
                paymentDate: (paymentData['paymentDate'] as num).toInt(),
                amountPaid: (paymentData['amountPaid'] as num).toDouble(),
              );
              finalPayments.add(payment);
              newPayments++;
            } catch (e) {
              continue;
            }
          }
        }

      } catch (e) {
        continue;
      }
    }

    return {
      'students': finalStudents,
      'payments': finalPayments,
      'metadata': backupData['metadata'] ?? {},
      'summary': backupData['summary'] ?? {},
      'mergeStats': {
        'newStudents': newStudents,
        'updatedStudents': updatedStudents,
        'newPayments': newPayments,
        'skippedPayments': skippedPayments,
        'totalStudents': finalStudents.length,
        'totalPayments': finalPayments.length,
      },
    };
  }

  Future<Map<String, dynamic>> importStudentsFromJson() async {
    try {
      String? initialDirectory;
      if (Platform.isAndroid) {
        initialDirectory = '/storage/emulated/0/Download/backups/TrackSmart';
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Track Smart Backup File',
        initialDirectory: initialDirectory,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath == null) {
          throw Exception('Invalid file path');
        }

        final file = File(filePath);

        if (!await file.exists()) {
          throw Exception('Selected file does not exist');
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('Selected file is empty');
        }

        final jsonString = await file.readAsString();
        final Map<String, dynamic> backupData = json.decode(jsonString);

        if (!_validateBackupFormat(backupData)) {
          throw Exception('Invalid backup file format.');
        }

        final List<Student> students = [];
        final List<Payment> payments = [];

        final studentsData = backupData['students'] as List<dynamic>? ?? [];

        for (final studentData in studentsData) {
          if (studentData == null) continue;

          try {
            final student = Student(
              id: studentData['id']?.toString() ?? '',
              name: studentData['name']?.toString() ?? '',
              joiningDate: studentData['joiningDate']?.toString() ?? '',
              fee: (studentData['fee'] as num?)?.toDouble() ?? 0.0,
              paymentType: studentData['paymentType']?.toString() ?? 'Cash',
              batch: (studentData['batch'] as num?)?.toInt() ?? 1,
              contact: studentData['contact']?.toString().isEmpty == true
                  ? null
                  : studentData['contact']?.toString(),
              notes: studentData['notes']?.toString().isEmpty == true
                  ? null
                  : studentData['notes']?.toString(),
            );
            students.add(student);

            final paymentHistory = studentData['paymentHistory'] as List<dynamic>? ?? [];
            for (final paymentData in paymentHistory) {
              if (paymentData == null) continue;

              try {
                final payment = Payment(
                  studentId: student.id,
                  month: paymentData['month']?.toString() ?? '',
                  paymentDate: (paymentData['paymentDate'] as num?)?.toInt() ?? 0,
                  amountPaid: (paymentData['amountPaid'] as num?)?.toDouble() ?? 0.0,
                );
                payments.add(payment);
              } catch (e) {
                continue;
              }
            }
          } catch (e) {
            continue;
          }
        }

        return {
          'students': students,
          'payments': payments,
          'metadata': backupData['metadata'] ?? {},
          'summary': backupData['summary'] ?? {},
        };
      }

      throw Exception('No file selected');
    } catch (e) {
      throw Exception('Import failed: ${e.toString()}');
    }
  }

  bool _validateBackupFormat(Map<String, dynamic> data) {
    return data.containsKey('metadata') &&
        data.containsKey('students') &&
        data.containsKey('summary') &&
        data['students'] is List &&
        data['metadata'] is Map &&
        data['metadata']['appName'] == 'Track Smart';
  }

  Future<List<String>> getAvailableBackupFiles() async {
    try {
      Directory baseDirectory;

      if (Platform.isAndroid) {
        baseDirectory = Directory('/storage/emulated/0/Download/backups/TrackSmart');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        baseDirectory = Directory('${appDir.path}/backups/TrackSmart');
      }

      if (!await baseDirectory.exists()) {
        return [];
      }

      final files = baseDirectory.listSync()
          .where((file) => file.path.endsWith('.json') && file.path.contains('track_smart_backup_'))
          .map((file) => file.path.split('/').last)
          .toList();

      files.sort((a, b) => b.compareTo(a));
      return files;
    } catch (e) {
      return [];
    }
  }

  String getBackupFolderPath() {
    if (Platform.isAndroid) {
      return 'Downloads/backups/TrackSmart/';
    } else {
      return 'App Documents/backups/TrackSmart/';
    }
  }
}
