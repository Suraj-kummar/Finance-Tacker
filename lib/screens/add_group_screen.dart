import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/group.dart';
import '../l10n/app_localizations.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _groupNameController = TextEditingController();
  final _memberNameController = TextEditingController();
  final List<String> _members = ['You']; // Default 'You' as member
  String _selectedType = 'trip';
  bool _isSaving = false;

  final List<Map<String, dynamic>> _groupTypes = [
    {'id': 'trip', 'label': 'Trip', 'icon': Icons.flight},
    {'id': 'home', 'label': 'Home', 'icon': Icons.home},
    {'id': 'couple', 'label': 'Couple', 'icon': Icons.favorite},
    {'id': 'other', 'label': 'Other', 'icon': Icons.group},
  ];

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  void _addMember() {
    final memberName = _memberNameController.text.trim();
    if (memberName.isNotEmpty && !_members.contains(memberName)) {
      setState(() {
        _members.add(memberName);
        _memberNameController.clear();
      });
    } else if (memberName.isNotEmpty && _members.contains(memberName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member already added')),
      );
    }
  }

  void _removeMember(String member) {
    if (member == 'You') {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot remove yourself')),
      );
      return;
    }
    setState(() {
      _members.remove(member);
    });
  }

  Future<void> _saveGroup() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty || _members.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name and add at least one other member')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newGroup = Group(
      name: groupName,
      members: _members,
      paidBy: "You",
      createdAt: DateTime.now(),
      type: _selectedType,
    );

    try {
      await context.read<GroupProvider>().addGroup(newGroup);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save group')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.newGroup),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveGroup,
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
            Text(
              "Group Type",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _groupTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final type = _groupTypes[index];
                  final isSelected = _selectedType == type['id'];
                  return InkWell(
                    onTap: () => setState(() => _selectedType = type['id']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            type['icon'],
                            color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type['label'],
                            style: TextStyle(
                              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.groupDetails,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.groupName,
                hintText: 'e.g., Apartment 302',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.group),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.members,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberNameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.addMember,
                      hintText: 'Name',
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addMember,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _members.map((member) {
                final isYou = member == 'You';
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(member[0].toUpperCase()),
                  ),
                  label: Text(member),
                  onDeleted: isYou ? null : () => _removeMember(member),
                  deleteIcon: isYou ? null : const Icon(Icons.close, size: 18),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
