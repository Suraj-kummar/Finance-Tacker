import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import '../l10n/app_localizations.dart';

class AddGroupTransactionScreen extends StatefulWidget {
  final Group group;
  final Transaction? transactionToEdit;

  const AddGroupTransactionScreen({
    super.key, 
    required this.group,
    this.transactionToEdit,
  });

  @override
  State<AddGroupTransactionScreen> createState() =>
      _AddGroupTransactionScreenState();
}

class _AddGroupTransactionScreenState extends State<AddGroupTransactionScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();

  String _paidBy = '';
  String _selectedCategory = 'Food';
  final Map<String, bool> _splitMembers = {};
  bool _isSaving = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.purple},
    {'name': 'Utilities', 'icon': Icons.lightbulb, 'color': Colors.yellow},
    {'name': 'Rent', 'icon': Icons.home, 'color': Colors.green},
    {'name': 'Travel', 'icon': Icons.flight, 'color': Colors.teal},
    {'name': 'Health', 'icon': Icons.local_hospital, 'color': Colors.red},
    {'name': 'Others', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize split map with all true by default
    for (var member in widget.group.members) {
      _splitMembers[member] = true;
    }

    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _nameController.text = t.name;
      _amountController.text = t.amount.toString(); // consider removal of .00 if needed
      _selectedCategory = t.category;
      
      if (t.paidBy != null && widget.group.members.contains(t.paidBy)) {
        _paidBy = t.paidBy!;
      } else {
        _paidBy = widget.group.members.contains('You') ? 'You' : widget.group.members.first;
      }

      // Update split selection based on existing transaction
      if (t.split != null) {
        for (var member in widget.group.members) {
          _splitMembers[member] = t.split!.containsKey(member);
        }
      }
    } else {
      // New Transaction Default
      if (widget.group.members.contains('You')) {
        _paidBy = 'You';
      } else {
        _paidBy = widget.group.members.first;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _nameFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (name.isEmpty) {
      _showErrorSnackBar('Please enter an expense name');
      _nameFocusNode.requestFocus();
      return;
    }

    if (amountText.isEmpty || amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      _amountFocusNode.requestFocus();
      return;
    }

    final membersToSplit = _splitMembers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (membersToSplit.isEmpty) {
      _showErrorSnackBar('Please select at least one person to split with');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final perPersonAmount = amount / membersToSplit.length;
      final splitMap = {for (var member in membersToSplit) member: perPersonAmount};

      if (widget.transactionToEdit != null) {
        // Update existing
        final updatedTransaction = Transaction(
          id: widget.transactionToEdit!.id,
          name: name,
          amount: amount,
          isIncome: widget.transactionToEdit!.isIncome,
          category: _selectedCategory,
          date: widget.transactionToEdit!.date, // Keep original date
          groupId: widget.group.id,
          paidBy: _paidBy,
          split: splitMap,
          receiptPath: widget.transactionToEdit!.receiptPath,
          isSettlement: widget.transactionToEdit!.isSettlement,
        );
        await context.read<TransactionProvider>().updateTransaction(updatedTransaction);
      } else {
        // Create new
        final newTransaction = Transaction(
          name: name,
          amount: amount,
          isIncome: false,
          category: _selectedCategory,
          date: DateTime.now(),
          groupId: widget.group.id,
          paidBy: _paidBy,
          split: splitMap,
          receiptPath: null,
        );
        await context.read<TransactionProvider>().addTransaction(newTransaction);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to save expense: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transactionToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Expense" : AppLocalizations.of(context)!.addExpense),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveTransaction,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountCard(),
            const SizedBox(height: 16),
            _buildPayerSection(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildSplitSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.enterAmount),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                prefixText: '₹',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayerSection() {
     return DropdownButtonFormField<String>(
        value: _paidBy,
        decoration: InputDecoration(
             labelText: "Paid By",
             prefixIcon: Icon(Icons.person),
             border: OutlineInputBorder(),
        ),
        items: widget.group.members.map((member) {
             return DropdownMenuItem(
                 value: member,
                 child: Text(member == 'You' ? 'You' : member),
             );
        }).toList(),
        onChanged: (val) {
             if (val != null) setState(() => _paidBy = val);
        },
     );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.description,
                prefixIcon: const Icon(Icons.description_outlined),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.category,
                prefixIcon: const Icon(Icons.category_outlined),
                border: const OutlineInputBorder(),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['name'],
                  child: Row(
                    children: [
                      Icon(cat['icon'], size: 20, color: cat['color']),
                      const SizedBox(width: 12),
                      Text(cat['name']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.splitWith,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.group.members.map((member) {
            final isSelected = _splitMembers[member] ?? false;
            return FilterChip(
              label: Text(member == 'You' ? 'You' : member),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _splitMembers[member] = selected;
                });
              },
              avatar: CircleAvatar(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  member.isNotEmpty ? member[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}