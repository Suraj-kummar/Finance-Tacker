import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _isIncome = false;
  final TextEditingController _customCategoryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _addTransaction() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);
    if (name.isEmpty || amount == null || amount <= 0) {
      _showErrorDialog("Please enter valid transaction details.");
      return;
    }

    final category = _selectedCategory == 'Others'
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    if (_selectedCategory == 'Others' && category.isEmpty) {
      _showErrorDialog("Please enter a custom category name.");
      return;
    }

    final transaction = Transaction(
      name: name,
      amount: amount,
      isIncome: _isIncome,
      category: category,
      date: DateTime.now(),
    );

    Provider.of<TransactionProvider>(context, listen: false)
        .addTransaction(transaction);
    Navigator.pop(context);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Invalid Input"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Add Transaction",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Name Field
            TextField(
              controller: _nameController,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Transaction Name",
                prefixIcon: Icon(Icons.edit_note_rounded, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: isDark 
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainer,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Amount Field with Rupay Symbol
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                labelText: "Amount",
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: isDark 
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainer,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark 
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                dropdownColor: isDark 
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainer,
                icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
                decoration: InputDecoration(
                  labelText: "Category",
                  prefixIcon: Icon(Icons.category_rounded, color: colorScheme.primary),
                  border: InputBorder.none,
                ),
                items: ['Food', 'Transport', 'Shopping', 'Entertainment', 'Bills', 'Health', 'Education', 'Others']
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
            ),
            
            if (_selectedCategory == 'Others')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextField(
                  controller: _customCategoryController,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: "Custom Category Name",
                    prefixIcon: Icon(Icons.edit_rounded, color: colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: isDark 
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.surfaceContainer,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Income/Expense Toggle
            Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isIncome ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                          color: _isIncome ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isIncome ? "Income" : "Expense",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isIncome,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: (value) => setState(() => _isIncome = value),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Add Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _addTransaction,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Add Transaction",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}