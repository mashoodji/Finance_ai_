// transaction_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/transactions_model.dart';

class TransactionEditDialog extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const TransactionEditDialog({super.key, required this.transaction});

  @override
  ConsumerState<TransactionEditDialog> createState() => _TransactionEditDialogState();
}

class _TransactionEditDialogState extends ConsumerState<TransactionEditDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.transaction.amount.toString());
    _categoryController =
        TextEditingController(text: widget.transaction.category);
    _selectedDate = widget.transaction.date;
    _dateController =
        TextEditingController(text: DateFormat.yMMMd().format(_selectedDate));
    _notesController =
        TextEditingController(text: widget.transaction.notes ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMMMd().format(picked);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.transaction.type == TransactionType.income
          ? 'INCOME'
          : 'EXPENSE'}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date'),
              onTap: () => _selectDate(context),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedTransaction = TransactionModel(
              id: widget.transaction.id,
              userId: widget.transaction.userId,
              category: _categoryController.text,
              amount: double.tryParse(_amountController.text) ??
                  widget.transaction.amount,
              date: _selectedDate,
              type: widget.transaction.type,
              notes: _notesController.text.isNotEmpty
                  ? _notesController.text
                  : null,
            );
            Navigator.of(context).pop(updatedTransaction);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
