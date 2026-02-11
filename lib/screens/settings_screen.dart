import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _pinCode = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pinCode = prefs.getString('pinCode') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _setPin() async {
    final pin = await _showPinEntryDialog('Set 4-Digit PIN', 4);
    
    if (pin != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pinCode', pin);
      setState(() => _pinCode = pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN set successfully')),
        );
      }
    }
  }

  Future<String?> _showPinEntryDialog(String title, int length, {String? currentPin}) async {
    String enteredPin = '';
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < enteredPin.length
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: index < enteredPin.length
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Dial Pad
                ...List.generate(3, (row) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (col) {
                        final number = (row * 3 + col + 1).toString();
                        return _buildDialPadButton(
                          number,
                          () {
                            if (enteredPin.length < length) {
                              setState(() => enteredPin += number);
                            }
                          },
                        );
                      }),
                    ),
                  );
                }),
                
                // Bottom row with 0 and delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 50),
                    _buildDialPadButton('0', () {
                      if (enteredPin.length < length) {
                        setState(() => enteredPin += '0');
                      }
                    }),
                    _buildDialPadButton('⌫', () {
                      if (enteredPin.isNotEmpty) {
                        setState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                      }
                    }, isDelete: true),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: enteredPin.length == length
                    ? () {
                        if (currentPin != null && enteredPin != currentPin) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Incorrect current PIN')),
                          );
                        } else {
                          Navigator.pop(context, enteredPin);
                        }
                      }
                    : null,
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialPadButton(String label, VoidCallback onTap, {bool isDelete = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isDelete ? 20 : 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updatePin() async {
    // Verify current PIN first
    final currentPinVerified = await _showPinEntryDialog(
      'Enter Current PIN',
      4,
      currentPin: _pinCode,
    );
    
    if (currentPinVerified == null) return;

    // Enter new PIN
    if (mounted) {
      final newPin = await _showPinEntryDialog('Set New 4-Digit PIN', 4);
      
      if (newPin != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pinCode', newPin);
        setState(() => _pinCode = newPin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN updated successfully')),
          );
        }
      }
    }
  }

  Future<void> _removePin() async {
    final controller = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Enter Current Password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text == _pinCode) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect password')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pinCode');
      setState(() => _pinCode = '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password removed successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Section
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              themeProvider.currentThemeIcon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: const Text('Theme'),
                          subtitle: Text(themeProvider.currentThemeName),
                          trailing: const Icon(Icons.arrow_drop_down),
                          onTap: () => _showThemeDialog(context, themeProvider),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Security Section
                  Text(
                    'Security',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_pinCode.isEmpty) ...[
                    // Set Password Button
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: const Text('Set Password'),
                        subtitle: const Text('Secure your app with a password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _setPin,
                      ),
                    ),
                  ] else ...[
                    // Update Password Button
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: const Text('Update Password'),
                        subtitle: const Text('Change your current password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _updatePin,
                      ),
                    ),
                    
                    // Remove Password Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_open,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Remove Password',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text('Disable app password protection'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.red),
                        onTap: _removePin,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(context, ThemeOption.system, 'System', 'Follow device theme', Icons.brightness_auto, themeProvider),
              _buildThemeOption(context, ThemeOption.light, 'Light', 'Bright and clean', Icons.brightness_7, themeProvider),
              _buildThemeOption(context, ThemeOption.dark, 'Dark', 'Easy on the eyes', Icons.brightness_4, themeProvider),
              _buildThemeOption(context, ThemeOption.midnight, 'Midnight', 'Deep blue with purple', Icons.nightlight_round, themeProvider),
              _buildThemeOption(context, ThemeOption.cozy, 'Cozy', 'Warm and comfortable', Icons.local_fire_department, themeProvider),
              _buildThemeOption(context, ThemeOption.bright, 'Bright', 'High contrast vibrant', Icons.wb_sunny, themeProvider),
              _buildThemeOption(context, ThemeOption.ocean, 'Ocean', 'Cool blue tones', Icons.water, themeProvider),
              _buildThemeOption(context, ThemeOption.forest, 'Forest', 'Natural green tones', Icons.forest, themeProvider),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeOption option,
    String title,
    String subtitle,
    IconData icon,
    ThemeProvider themeProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = themeProvider.selectedTheme == option;
    
    return ListTile(
      leading: Icon(icon, color: isSelected ? colorScheme.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.primary) : null,
      onTap: () {
        themeProvider.setTheme(option);
        Navigator.pop(context);
      },
    );
  }
}