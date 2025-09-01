import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/transactions_model.dart';
import '../../../state/transaction_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  static const String routePath = "/add-expense";
  static const String routeName = "add-expense";

  final String userId;
  const AddExpenseScreen({super.key, required this.userId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(transactionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter amount" : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Category"),
                validator: (value) => value!.isEmpty ? "Enter category" : null,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Notes"),
              ),
              DropdownButton<TransactionType>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: TransactionType.expense, child: Text("Expense")),
                  DropdownMenuItem(value: TransactionType.income, child: Text("Income")),
                ],
                onChanged: (val) => setState(() => _type = val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final transaction = TransactionModel(
                      id: const Uuid().v4(),
                      userId: widget.userId,
                      amount: double.parse(_amountController.text),
                      category: _categoryController.text,
                      date: DateTime.now(),
                      type: _type,
                      notes: _notesController.text,
                    );
                    await repo.addTransaction(transaction);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save Transaction"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
