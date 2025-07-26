import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/student_viewmodel.dart';
import '../../models/student.dart';

class StudentDetailsSheet extends StatefulWidget {
  final Student? student;

  const StudentDetailsSheet({super.key, this.student});

  @override
  State<StudentDetailsSheet> createState() => _StudentDetailsSheetState();
}

class _StudentDetailsSheetState extends State<StudentDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _feeController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentType = 'Cash';
  int _selectedBatch = 1;
  DateTime _joiningDate = DateTime.now();

  // FIXED: Made fields final
  final List<String> _previousMonths = [];
  final Map<String, bool> _monthPaymentStatus = {};

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _feeController.text = widget.student!.fee.toString();
      _contactController.text = widget.student!.contact ?? '';
      _notesController.text = widget.student!.notes ?? '';
      _paymentType = widget.student!.paymentType;
      _selectedBatch = widget.student!.batch;

      try {
        _joiningDate = DateFormat('MMM d, yyyy', 'en_US').parse(widget.student!.joiningDate);
      } catch (e) {
        _joiningDate = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    widget.student == null ? 'Add New Student' : 'Edit Student',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Student Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _feeController,
                          decoration: const InputDecoration(
                            labelText: 'Fee Amount (₹)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Fee is required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid fee amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Info (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batch',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _selectedBatch == 1
                                      ? ElevatedButton.icon(
                                    onPressed: () => setState(() => _selectedBatch = 1),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Batch 1'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  )
                                      : OutlinedButton(
                                    onPressed: () => setState(() => _selectedBatch = 1),
                                    child: const Text('Batch 1'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _selectedBatch == 2
                                      ? ElevatedButton.icon(
                                    onPressed: () => setState(() => _selectedBatch = 2),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Batch 2'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  )
                                      : OutlinedButton(
                                    onPressed: () => setState(() => _selectedBatch = 2),
                                    child: const Text('Batch 2'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                'Selected: Batch $_selectedBatch',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Joining Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(DateFormat('MMM d, yyyy').format(_joiningDate)),
                          ),
                        ),

                        if (_previousMonths.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Card(
                            // FIXED: Replace withOpacity with withValues
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payment,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Previous Month Payments',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Mark which months this student has already paid:',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),

                                  ...(_previousMonths.map((monthStr) {
                                    final monthDate = DateFormat('yyyy-MM').parse(monthStr);
                                    final monthName = DateFormat('MMMM yyyy').format(monthDate);
                                    final isPaid = _monthPaymentStatus[monthStr] ?? false;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isPaid
                                          // FIXED: Replace withOpacity with withValues
                                              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                                              : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isPaid
                                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                                                : Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isPaid ? Icons.check_circle : Icons.schedule,
                                              size: 18,
                                              color: isPaid
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.error,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    monthName,
                                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₹${_feeController.text.isNotEmpty ? _feeController.text : "0"}',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              isPaid ? 'Paid' : 'Unpaid',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: isPaid
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).colorScheme.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Switch(
                                              value: isPaid,
                                              onChanged: (value) {
                                                setState(() {
                                                  _monthPaymentStatus[monthStr] = value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList()),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _paymentType,
                          decoration: const InputDecoration(
                            labelText: 'Payment Type',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Cash', 'Online', 'Cheque']
                              .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                              .toList(),
                          onChanged: (value) => setState(() => _paymentType = value!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveStudent,
                          child: Text(widget.student == null ? 'Add Student' : 'Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year, now.month + 1, 0);

    final date = await showDatePicker(
      context: context,
      initialDate: _joiningDate.isAfter(maxDate) ? maxDate : _joiningDate,
      firstDate: DateTime(2000),
      lastDate: maxDate,
      helpText: 'Select joining date',
      errorFormatText: 'Invalid date format',
      errorInvalidText: 'Date cannot be in the future',
    );

    if (date != null) {
      setState(() {
        _joiningDate = date;
        _calculatePreviousMonths();
      });
    }
  }

  void _calculatePreviousMonths() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final joiningMonth = DateTime(_joiningDate.year, _joiningDate.month);

    _previousMonths.clear();
    _monthPaymentStatus.clear();

    final viewModel = Provider.of<StudentViewModel>(context, listen: false);
    final selectedMonth = DateTime(viewModel.selectedDate.year, viewModel.selectedDate.month);

    if (widget.student == null && selectedMonth.isAtSameMomentAs(currentMonth)) {
      var checkMonth = joiningMonth;

      while (checkMonth.isBefore(currentMonth)) {
        final monthStr = DateFormat('yyyy-MM').format(checkMonth);
        _previousMonths.add(monthStr);
        _monthPaymentStatus[monthStr] = false;
        checkMonth = DateTime(checkMonth.year, checkMonth.month + 1);
      }
    }
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<StudentViewModel>(context, listen: false);
      final formattedDate = DateFormat('MMM d, yyyy', 'en_US').format(_joiningDate);
      final fee = double.parse(_feeController.text);

      if (widget.student == null) {
        viewModel.addStudent(
          name: _nameController.text.trim(),
          fee: fee,
          paymentType: _paymentType,
          notes: _notesController.text.trim(),
          contact: _contactController.text.trim(),
          joiningDate: formattedDate,
          batch: _selectedBatch,
          previousMonthPayments: _monthPaymentStatus,
        );
      } else {
        viewModel.updateStudent(
          id: widget.student!.id,
          name: _nameController.text.trim(),
          fee: fee,
          paymentType: _paymentType,
          notes: _notesController.text.trim(),
          contact: _contactController.text.trim(),
          joiningDate: formattedDate,
          batch: _selectedBatch,
        );
      }

      Navigator.pop(context);
    }
  }
}
