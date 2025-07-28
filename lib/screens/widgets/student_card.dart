import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/payment.dart';
import '../../models/student.dart';
import '../../viewmodels/student_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class StudentCard extends StatelessWidget {
  final StudentWithPaymentStatus studentWithStatus;
  final bool isSelected;
  final int currentTabIndex;
  final Function(String, bool) onStatusChange;
  final Function(String) onDelete;
  final Function(Student) onEdit;
  final Function(String) onLongPress;
  final Function(String) onTap;

  const StudentCard({
    super.key,
    required this.studentWithStatus,
    required this.isSelected,
    required this.currentTabIndex,
    required this.onStatusChange,
    required this.onDelete,
    required this.onEdit,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final student = studentWithStatus.student;
    final isStudentsTab = currentTabIndex == 2;

    final batchColors = _getBatchColors(context, student.batch);

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected
          ? batchColors.selectedBackground
          : batchColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isSelected
            ? BorderSide(color: batchColors.selectedBorder, width: 2)
            : BorderSide(color: batchColors.cardBorder, width: 1),
      ),
      child: InkWell(
        onTap: () => onTap(student.id),
        onLongPress: () => onLongPress(student.id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                batchColors.gradientStart,
                batchColors.gradientEnd,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Show batch indicator only for non-Students tabs
                    if (!isStudentsTab)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: batchColors.batchIndicator,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.group,
                              size: 12,
                              color: batchColors.batchIndicatorText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Batch ${student.batch}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: batchColors.batchIndicatorText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    // Show status chip only for non-Students tabs
                    if (!isStudentsTab)
                      _StatusChip(
                        isPaid: studentWithStatus.isPaid,
                        isOverdue: studentWithStatus.isOverdue,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                isStudentsTab
                    ? _buildStudentsTabLayout(context, student, batchColors)
                    : _buildPaidUnpaidTabLayout(context, student, batchColors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BatchColors _getBatchColors(BuildContext context, int batch) {
    final colorScheme = Theme.of(context).colorScheme;

    if (batch == 1) {
      return BatchColors(
        cardBackground: colorScheme.surface,
        cardBorder: Colors.blue.withValues(alpha: 0.3),
        selectedBackground: Colors.blue.withValues(alpha: 0.1),
        selectedBorder: Colors.blue,
        gradientStart: Colors.blue.withValues(alpha: 0.05),
        gradientEnd: Colors.indigo.withValues(alpha: 0.02),
        batchIndicator: Colors.blue.withValues(alpha: 0.2),
        batchIndicatorText: Colors.blue.shade700,
        accentColor: Colors.blue,
      );
    } else {
      return BatchColors(
        cardBackground: colorScheme.surface,
        cardBorder: Colors.green.withValues(alpha: 0.3),
        selectedBackground: Colors.green.withValues(alpha: 0.1),
        selectedBorder: Colors.green,
        gradientStart: Colors.green.withValues(alpha: 0.05),
        gradientEnd: Colors.teal.withValues(alpha: 0.02),
        batchIndicator: Colors.green.withValues(alpha: 0.2),
        batchIndicatorText: Colors.green.shade700,
        accentColor: Colors.green,
      );
    }
  }

  Widget _buildStudentsTabLayout(BuildContext context, Student student, BatchColors batchColors) {
    return Consumer<StudentViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Student name and status chip on same line
            Row(
              children: [
                Expanded(
                  child: Text(
                    student.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Status chip on same line as name
                _StatusChip(
                  isPaid: studentWithStatus.isPaid,
                  isOverdue: studentWithStatus.isOverdue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Main row: Batch indicator, action buttons, and fee
            Row(
              children: [
                // Batch indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: batchColors.batchIndicator,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.group,
                        size: 12,
                        color: batchColors.batchIndicatorText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Batch ${student.batch}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: batchColors.batchIndicatorText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action buttons
                IconButton(
                  onPressed: () => onEdit(student),
                  icon: const Icon(Icons.edit),
                  iconSize: 18,
                  tooltip: 'Edit Student',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                if (student.contact != null && student.contact!.isNotEmpty)
                  IconButton(
                    onPressed: () => _makePhoneCall(student.contact!),
                    icon: const Icon(Icons.phone),
                    iconSize: 18,
                    color: batchColors.accentColor,
                    tooltip: 'Call ${student.contact}',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                IconButton(
                  onPressed: () => onDelete(student.id),
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  iconSize: 18,
                  tooltip: 'Delete Student',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const Spacer(),
                // Fee display
                _buildFeeDisplay(
                  context,
                  '₹${student.fee.toStringAsFixed(0)}',
                  viewModel.isFeesVisible,
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: batchColors.accentColor,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaidUnpaidTabLayout(BuildContext context, Student student, BatchColors batchColors) {
    return Consumer<StudentViewModel>(
      builder: (context, viewModel, child) {
        final overdueMonths = _getOverdueMonthsExcludingCurrent(viewModel, student.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    student.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (studentWithStatus.isOverdue && overdueMonths.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Overdue Payments (${overdueMonths.length})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    if (overdueMonths.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...overdueMonths.take(3).map((monthStr) => _buildOverduePaymentRow(
                          context, viewModel, student, monthStr, batchColors
                      )),
                      if (overdueMonths.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${overdueMonths.length - 3} more overdue months',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            _DetailItem(label: 'Joined', value: student.joiningDate),
            _DetailItemWithFee(
              label: 'Fee',
              fee: student.fee,
              isVisible: viewModel.isFeesVisible,
              accentColor: batchColors.accentColor,
            ),

            if (studentWithStatus.isPaid && studentWithStatus.paymentDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: batchColors.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Paid on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(studentWithStatus.paymentDate!))}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 16),

            Row(
              children: [
                IconButton(
                  onPressed: () => onEdit(student),
                  icon: const Icon(Icons.edit),
                  iconSize: 20,
                  tooltip: 'Edit Student',
                ),

                if (student.contact != null && student.contact!.isNotEmpty) ...[
                  IconButton(
                    onPressed: () => _makePhoneCall(student.contact!),
                    icon: const Icon(Icons.phone),
                    iconSize: 20,
                    color: batchColors.accentColor,
                    tooltip: 'Call ${student.contact}',
                  ),
                ],

                IconButton(
                  onPressed: () => onDelete(student.id),
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  iconSize: 20,
                  tooltip: 'Delete Student',
                ),

                const Spacer(),

                Text(
                  'Paid',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: studentWithStatus.isPaid
                        ? batchColors.accentColor
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Switch(
                  value: studentWithStatus.isPaid,
                  onChanged: (value) => onStatusChange(student.id, value),
                  activeColor: batchColors.accentColor,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<String> _getOverdueMonthsExcludingCurrent(StudentViewModel viewModel, String studentId) {
    final allOverdueMonths = viewModel.getOverdueMonths(studentId);
    final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());

    return allOverdueMonths.where((monthStr) => monthStr != currentMonthStr).toList();
  }

  Widget _buildOverduePaymentRow(BuildContext context, StudentViewModel viewModel, Student student, String monthStr, BatchColors batchColors) {
    final monthDate = DateFormat('yyyy-MM').parse(monthStr);
    final monthName = DateFormat('MMM yyyy').format(monthDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              monthName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildFeeDisplay(
            context,
            '₹${student.fee.toStringAsFixed(0)}',
            viewModel.isFeesVisible,
            Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: batchColors.accentColor,
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: false,
              onChanged: (value) {
                if (value) {
                  viewModel.updatePaymentForMonth(student.id, monthStr, true, student.fee);
                }
              },
              activeColor: batchColors.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeDisplay(BuildContext context, String feeText, bool isVisible, TextStyle? style) {
    if (isVisible) {
      return Text(feeText, style: style);
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '••••',
              style: style?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

class BatchColors {
  final Color cardBackground;
  final Color cardBorder;
  final Color selectedBackground;
  final Color selectedBorder;
  final Color gradientStart;
  final Color gradientEnd;
  final Color batchIndicator;
  final Color batchIndicatorText;
  final Color accentColor;

  BatchColors({
    required this.cardBackground,
    required this.cardBorder,
    required this.selectedBackground,
    required this.selectedBorder,
    required this.gradientStart,
    required this.gradientEnd,
    required this.batchIndicator,
    required this.batchIndicatorText,
    required this.accentColor,
  });
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItemWithFee extends StatelessWidget {
  final String label;
  final double fee;
  final bool isVisible;
  final Color accentColor;

  const _DetailItemWithFee({
    required this.label,
    required this.fee,
    required this.isVisible,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isVisible)
            Text(
              '₹$fee',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '••••',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isPaid;
  final bool isOverdue;

  const _StatusChip({
    required this.isPaid,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    if (isPaid) {
      bgColor = Theme.of(context).colorScheme.primaryContainer;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;
      text = 'Paid';
    } else if (isOverdue) {
      bgColor = Theme.of(context).colorScheme.errorContainer;
      textColor = Theme.of(context).colorScheme.onErrorContainer;
      text = 'Overdue';
    } else {
      bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      textColor = Theme.of(context).colorScheme.onSurfaceVariant;
      text = 'Unpaid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
