import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/transactions_model.dart';
import '../../../../data/models/user_models.dart';
import '../../../../state/auth_provider.dart';
import '../../../../state/expense_provider.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  static const routeName = 'add_edit_transaction';
  final TransactionModel? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;
  String _selectedCurrency = 'PKR'; // Default currency

  final List<String> _incomeCategories = [
    'Salary', 'Freelance', 'Investment', 'Business', 'Gift', 'Other Income'
  ];

  final List<String> _expenseCategories = [
    'Food', 'Transport', 'Entertainment', 'Shopping',
    'Healthcare', 'Education', 'Utilities', 'Rent', 'Bills', 'Other Expenses'
  ];

  // List of supported currencies
  final List<String> _currencies = [
    'PKR', 'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CNY', 'INR', 'AED'
  ];

  @override
  void initState() {
    super.initState();

    // Load user data to get currency preference
    final user = ref.read(authControllerProvider).value;
    if (user != null && user.currency != null) {
      _selectedCurrency = user.currency!;
    }

    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _categoryController.text = widget.transaction!.category;
      _notesController.text = widget.transaction!.notes ?? '';
      _selectedDate = widget.transaction!.date;
      _selectedType = widget.transaction!.type;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getFinancialImpactMessage(double amount) {
    if (_selectedType == TransactionType.income) {
      return "💵 Adding $_selectedCurrency ${amount.toStringAsFixed(2)} to your monthly income";
    } else {
      return "💸 Adding $_selectedCurrency ${amount.toStringAsFixed(2)} to your expenses";
    }
  }

  List<String> _getAvailableCategories() {
    return _selectedType == TransactionType.income ? _incomeCategories : _expenseCategories;
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final userAsync = ref.read(authControllerProvider);
      final user = userAsync.value;
      if (user == null) return;

      final amount = double.parse(_amountController.text);
      final transaction = TransactionModel(
        id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        amount: amount,
        category: _categoryController.text,
        date: _selectedDate,
        type: _selectedType,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      try {
        if (widget.transaction == null) {
          // Add new transaction
          await ref.read(transactionProvider.notifier).addTransaction(transaction);

          // If it's an income transaction, update user's monthly income
          if (_selectedType == TransactionType.income) {
            final newMonthlyIncome = (user.monthlyIncome ?? 0) + amount;

            // Update user's monthly income and adjust budget if needed
            await ref.read(authControllerProvider.notifier).updateUser(
              user.copyWith(
                monthlyIncome: newMonthlyIncome,
                // If no budget is set, automatically set it to 70% of the new income
                monthlyBudget: user.monthlyBudget ?? newMonthlyIncome * 0.7,
              ),
            );
          }

          // Show financial impact message
          final impactMessage = _getFinancialImpactMessage(amount);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(impactMessage),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          // Update existing transaction
          await ref.read(transactionProvider.notifier).updateTransaction(transaction);
        }

        if (mounted) {
          Navigator.pop(context);
          if (widget.transaction != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaction updated successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final financialImpact = _getFinancialImpactMessage(amount);
    final availableCategories = _getAvailableCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Add Transaction' : 'Edit Transaction'),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: const Text('Are you sure you want to delete this transaction?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await ref.read(transactionProvider.notifier).deleteTransaction(widget.transaction!.id);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Transaction Type
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Expense'),
                      selected: _selectedType == TransactionType.expense,
                      selectedColor: Colors.red,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = TransactionType.expense;
                          _categoryController.text = '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Income'),
                      selected: _selectedType == TransactionType.income,
                      selectedColor: Colors.green,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = TransactionType.income;
                          _categoryController.text = '';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Currency Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: _currencies.map((currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '$_selectedCurrency ',
                  border: const OutlineInputBorder(),
                  suffixIcon: _amountController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.calculate),
                    onPressed: () {
                      setState(() {}); // Recalculate impact
                    },
                  )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {}); // Update financial impact in real-time
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _categoryController.text.isEmpty ? null : _categoryController.text,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: availableCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryController.text = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat.yMMMd().format(_selectedDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Financial Impact Preview
              if (_amountController.text.isNotEmpty && amount > 0)
                Card(
                  color: _selectedType == TransactionType.income
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Financial Impact:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          financialImpact,
                          style: TextStyle(
                            color: _selectedType == TransactionType.income
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                        if (_selectedType == TransactionType.income)
                          const SizedBox(height: 8),
                        if (_selectedType == TransactionType.income)
                          const Text(
                            "Your monthly income will be updated automatically",
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _selectedType == TransactionType.income
                      ? Colors.green
                      : Colors.blue,
                ),
                child: Text(
                  widget.transaction == null ? 'Add Transaction' : 'Update Transaction',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}