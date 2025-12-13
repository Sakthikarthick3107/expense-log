import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ParsedSmsTxn.dart';
import '../../models/account.dart';
import '../services/expense_service.dart';
import 'package:provider/provider.dart';

class SmsReviewPage extends StatefulWidget {
  final Account account;
  final List<ParsedSmsTxn> txns;

  const SmsReviewPage({
    super.key,
    required this.account,
    required this.txns,
  });

  @override
  State<SmsReviewPage> createState() => _SmsReviewPageState();
}

class _SmsReviewPageState extends State<SmsReviewPage> {
  final Set<int> _selectedIndexes = {};
  late ExpenseService expenseService;

  @override
  void initState() {
    super.initState();
    expenseService = Provider.of<ExpenseService>(context, listen: false);
    for (int i = 0; i < widget.txns.length; i++) {
      _selectedIndexes.add(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review SMS Transactions'),
      ),
      body: widget.txns.isEmpty
          ? const Center(child: Text('No transactions found'))
          : ListView.builder(
              itemCount: widget.txns.length,
              itemBuilder: (context, index) {
                final txn = widget.txns[index];
                final isSelected = _selectedIndexes.contains(index);

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIndexes.add(index);
                          } else {
                            _selectedIndexes.remove(index);
                          }
                        });
                      },
                    ),
                    title: Text(
                      '₹${txn.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color:
                            txn.isDebit ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.isDebit ? 'Debit' : 'Credit',
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(txn.date),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          txn.rawBody,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editAmount(context, index),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedIndexes.isEmpty
                    ? null
                    : _postSelected,
                child: const Text('Post Selected'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editAmount(BuildContext context, int index) {
    final controller = TextEditingController(
      text: widget.txns[index].amount.toString(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                setState(() {
                  widget.txns[index] =
                      widget.txns[index].copyWith(amount: value);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _postSelected() {
    // final expenseService = ExpenseService();
    // final incomeService = IncomeService();

    // for (final index in _selectedIndexes) {
    //   final txn = widget.txns[index];

    //   if (txn.isDebit) {
    //     expenseService.addExpense(
    //       amount: txn.amount,final expenseService = ExpenseService();
    // final incomeService = IncomeService();

    // for (final index in _selectedIndexes) {
    //   final txn = widget.txns[index];

    //   if (txn.isDebit) {
    //     expenseService.addExpense(
    //       amount: txn.amount,
    //       accountId: widget.account.id,
    //       note: txn.description,
    //       date: txn.date,
    //     );
    //     widget.account.balance -= txn.amount;
    //   } else {
    //     incomeService.addIncome(
    //       amount: txn.amount,
    //       accountId: widget.account.id,
    //       note: txn.description,
    //       date: txn.date,
    //     );
    //     widget.account.balance += txn.amount;
    //   }
    // }

    // widget.account.lastSmsSyncedAt = DateTime.now();
    // widget.account.save();
    //       accountId: widget.account.id,
    //       note: txn.description,
    //       date: txn.date,
    //     );
    //     widget.account.balance -= txn.amount;
    //   } else {
    //     incomeService.addIncome(
    //       amount: txn.amount,
    //       accountId: widget.account.id,
    //       note: txn.description,
    //       date: txn.date,
    //     );
    //     widget.account.balance += txn.amount;
    //   }
    // }

    // widget.account.lastSmsSyncedAt = DateTime.now();
    // widget.account.save();

    Navigator.pop(context);
  }
}
