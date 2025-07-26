import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';

class StudentHistoryDialog extends StatelessWidget {
  final StudentHistory history;

  const StudentHistoryDialog({
    super.key, // Changed from {super.key} to super.key
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${history.student.name} - Payment History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: history.monthlyStatuses.length,
                itemBuilder: (context, index) {
                  final status = history.monthlyStatuses[index];
                  return _HistoryItem(
                    monthlyStatus: status,
                    fee: history.student.fee,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final MonthlyStatus monthlyStatus;
  final double fee;

  const _HistoryItem({
    required this.monthlyStatus,
    required this.fee,
  });

  @override
  Widget build(BuildContext context) {
    final monthFormatter = DateFormat('MMMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: monthlyStatus.isPaid
              ? Theme.of(context).colorScheme.primaryContainer
              : monthlyStatus.overdueFrom != null
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest, // Fixed: Changed from surfaceVariant
          child: Icon(
            monthlyStatus.isPaid
                ? Icons.check
                : monthlyStatus.overdueFrom != null
                ? Icons.warning
                : Icons.pending,
            color: monthlyStatus.isPaid
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : monthlyStatus.overdueFrom != null
                ? Theme.of(context).colorScheme.onErrorContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(monthFormatter.format(monthlyStatus.month)),
        subtitle: monthlyStatus.overdueFrom != null
            ? Text(
          'Overdue since ${monthFormatter.format(monthlyStatus.overdueFrom!)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
          ),
        )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              monthlyStatus.isPaid ? 'Paid' : 'Unpaid',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: monthlyStatus.isPaid
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (monthlyStatus.isPaid)
              Text(
                '₹${fee.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
