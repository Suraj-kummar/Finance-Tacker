// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Finance Tracker PRO';

  @override
  String get home => 'Home';

  @override
  String get stats => 'Stats';

  @override
  String get wallet => 'Wallet';

  @override
  String get settings => 'Settings';

  @override
  String get transactions => 'Transactions';

  @override
  String get financialOverview => 'Financial Overview';

  @override
  String get balance => 'Balance';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get updateTransaction => 'Update Transaction';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get cancel => 'Cancel';

  @override
  String get filter => 'Filter';

  @override
  String get noTransactions => 'No transactions found';

  @override
  String get groups => 'Groups';

  @override
  String get newGroup => 'New Group';

  @override
  String get createGroup => 'Create Group';

  @override
  String get noGroups => 'No groups yet';

  @override
  String get createGroupPrompt => 'Create a group to split expenses';

  @override
  String get groupName => 'Group Name';

  @override
  String get members => 'Members';

  @override
  String get addMember => 'Add Member';

  @override
  String get memberAlreadyAdded => 'Member already added';

  @override
  String get validationGroup =>
      'Please enter a group name and at least one member';

  @override
  String get groupDetails => 'Group Details';

  @override
  String get groupBalance => 'Group Balance';

  @override
  String get allSettled => 'All settled up!';

  @override
  String get addFirstExpense => 'Add First Expense';

  @override
  String get startSplitting =>
      'Start splitting expenses with your group by adding your first transaction. Track who pays what and settle up easily.';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get enterAmount => 'Enter Amount';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get splitWith => 'Split with';

  @override
  String get save => 'Save';

  @override
  String get paidBy => 'Paid by';

  @override
  String get you => 'You';

  @override
  String owes(String amount) {
    return 'owes $amount';
  }

  @override
  String isOwed(String amount) {
    return 'is owed $amount';
  }

  @override
  String get deleteTransactionTitle => 'Delete Transaction?';

  @override
  String deleteTransactionMessage(String name) {
    return 'Are you sure you want to delete \'$name\'? This action cannot be undone.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get failedToLoadGroupData =>
      'Failed to load group data. Please try again.';

  @override
  String get transactionDeletedSuccessfully =>
      'Transaction deleted successfully';
}
