import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/student_viewmodel.dart';
import '../../models/student.dart';

class ConfirmPaymentDialog extends StatefulWidget {
  final Student student;

  const ConfirmPaymentDialog({
    super.key,
    required this.student,
  });

  @override
  ConfirmPaymentDialogState createState() => ConfirmPaymentDialogState(); // FIXED: Removed underscore
}

class ConfirmPaymentDialogState extends State<ConfirmPaymentDialog> { // FIXED: Removed underscore from class name
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.student.fee.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mark payment as received for:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.student.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount Paid (₹)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? widget.student.fee;
            final viewModel = Provider.of<StudentViewModel>(context, listen: false);
            viewModel.updatePaymentStatus(widget.student.id, true, amount);
            Navigator.pop(context);
          },
          child: const Text('Confirm Payment'),
        ),
      ],
    );
  }
}
