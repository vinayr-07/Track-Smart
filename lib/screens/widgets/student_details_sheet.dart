import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/student_viewmodel.dart';
import '../../models/student.dart';

class StudentDetailsSheet extends StatefulWidget {
  final Student? student;
  final int? initialBatch;

  const StudentDetailsSheet({super.key, this.student, this.initialBatch});

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
  late int _selectedBatch;
  DateTime _joiningDate = DateTime.now();

  // For previous months payment tracking
  final List<String> _previousMonths = [];
  final Map<String, bool> _monthPaymentStatus = {};

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      // Editing existing student - use student's data
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
    } else {
      // Adding new student - use initialBatch or default to 1
      _selectedBatch = widget.initialBatch ?? 1;
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
                          decoration: InputDecoration(
                            labelText: 'Student Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                                width: 2,
                              ),
                            ),
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
                          decoration: InputDecoration(
                            labelText: 'Fee Amount (₹)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                                width: 2,
                              ),
                            ),
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
                          decoration: InputDecoration(
                            labelText: 'Contact Info (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  )
                                      : OutlinedButton(
                                    onPressed: () => setState(() => _selectedBatch = 1),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  )
                                      : OutlinedButton(
                                    onPressed: () => setState(() => _selectedBatch = 2),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
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
                          borderRadius: BorderRadius.circular(16),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Joining Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(DateFormat('MMM d, yyyy').format(_joiningDate)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _paymentType,
                          decoration: InputDecoration(
                            labelText: 'Payment Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
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
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveStudent,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
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
      });

      // NEW: Check if selected date is previous month and show popup
      final selectedMonth = DateTime(date.year, date.month);
      final currentMonth = DateTime(now.year, now.month);

      if (widget.student == null && selectedMonth.isBefore(currentMonth)) {
        await _showPreviousMonthsPaymentDialog();
      }
    }
  }

  // NEW: Show prominent centered popup for previous months payment
  Future<void> _showPreviousMonthsPaymentDialog() async {
    // Calculate previous months
    final currentMonth = DateTime.now();
    final joiningMonth = DateTime(_joiningDate.year, _joiningDate.month);

    final tempPreviousMonths = <String>[];
    final tempMonthPaymentStatus = <String, bool>{};

    var checkMonth = joiningMonth;
    while (checkMonth.isBefore(currentMonth)) {
      final monthStr = DateFormat('yyyy-MM').format(checkMonth);
      tempPreviousMonths.add(monthStr);
      tempMonthPaymentStatus[monthStr] = false;
      checkMonth = DateTime(checkMonth.year, checkMonth.month + 1);
    }

    if (tempPreviousMonths.isEmpty) return;

    // Create scroll controller for auto-scroll
    final scrollController = ScrollController();

    // Show the prominent centered dialog
    final result = await showDialog<Map<String, bool>>(
      context: context,
      barrierDismissible: false, // Make it prominent - user must interact
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Auto-scroll to toggles after dialog is built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  150, // Scroll down to show toggles prominently
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            });

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.payment,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Previous Months Payment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5, // Make it prominent
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Student joined in a previous month',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please mark which previous months this student has already paid:',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Previous Months (${tempPreviousMonths.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // THE MAIN ATTRACTION - Payment Toggles
                      ...tempPreviousMonths.map((monthStr) {
                        final monthDate = DateFormat('yyyy-MM').parse(monthStr);
                        final monthName = DateFormat('MMMM yyyy').format(monthDate);
                        final isPaid = tempMonthPaymentStatus[monthStr] ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPaid
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                                  : Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPaid ? Icons.check_circle : Icons.schedule,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              monthName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '₹${_feeController.text.isNotEmpty ? _feeController.text : "0"}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Transform.scale(
                              scale: 1.2, // Make toggle more prominent
                              child: Switch(
                                value: isPaid,
                                onChanged: (value) {
                                  setDialogState(() {
                                    tempMonthPaymentStatus[monthStr] = value;
                                  });
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(tempMonthPaymentStatus),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Save Payment Status'),
                ),
              ],
            );
          },
        );
      },
    );

    // If user saved the payment status, update the local state
    if (result != null) {
      setState(() {
        _previousMonths.clear();
        _monthPaymentStatus.clear();
        _previousMonths.addAll(result.keys);
        _monthPaymentStatus.addAll(result);
      });
    }
  }

  // Existing methods for change summary and confirmation dialogs...
  String? _getChangesSummary() {
    if (widget.student == null) return null;

    final changes = <String>[];
    final formattedDate = DateFormat('MMM d, yyyy', 'en_US').format(_joiningDate);
    final newFee = double.tryParse(_feeController.text) ?? 0.0;
    final newContact = _contactController.text.trim().isEmpty ? null : _contactController.text.trim();
    final newNotes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    if (widget.student!.name != _nameController.text.trim()) {
      changes.add("Name: '${widget.student!.name}' → '${_nameController.text.trim()}'");
    }

    if (widget.student!.fee != newFee) {
      changes.add("Fee: '₹${widget.student!.fee.toStringAsFixed(0)}' → '₹${newFee.toStringAsFixed(0)}'");
    }

    if (widget.student!.contact != newContact) {
      final oldContact = widget.student!.contact ?? 'Not set';
      final newContactDisplay = newContact ?? 'Not set';
      changes.add("Contact: '$oldContact' → '$newContactDisplay'");
    }

    if (widget.student!.notes != newNotes) {
      final oldNotes = widget.student!.notes ?? 'Not set';
      final newNotesDisplay = newNotes ?? 'Not set';
      changes.add("Notes: '$oldNotes' → '$newNotesDisplay'");
    }

    if (widget.student!.paymentType != _paymentType) {
      changes.add("Payment Type: '${widget.student!.paymentType}' → '$_paymentType'");
    }

    if (widget.student!.batch != _selectedBatch) {
      changes.add("Batch: '${widget.student!.batch}' → '$_selectedBatch'");
    }

    if (widget.student!.joiningDate != formattedDate) {
      changes.add("Joining Date: '${widget.student!.joiningDate}' → '$formattedDate'");
    }

    if (changes.isEmpty) return null;

    return "You are changing the following information:\n\n${changes.join('\n')}\n\nDo you want to proceed?";
  }

  Future<bool> _showEditConfirmationDialog() async {
    final changesSummary = _getChangesSummary();

    if (changesSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No changes detected'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Confirm Changes'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                changesSummary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  void _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      if (widget.student != null) {
        final confirmed = await _showEditConfirmationDialog();
        if (!confirmed) return;
      }

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
