import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinLockScreen extends StatefulWidget {
  final Widget child;
  const PinLockScreen({super.key, required this.child});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _savedPin = '';
  String _enteredPin = '';
  bool _unlocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPin();
  }

  Future<void> _loadSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('pinCode') ?? '';
      _isLoading = false;
    });
  }

  void _onNumberTap(String number) {
    if (_enteredPin.length < _savedPin.length) {
      setState(() {
        _enteredPin += number;
      });

      // Auto-verify when PIN is complete
      if (_enteredPin.length == _savedPin.length) {
        Future.delayed(const Duration(milliseconds: 200), _verifyPin);
      }
    }
  }

  void _onDeleteTap() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == _savedPin) {
      setState(() => _unlocked = true);
    } else {
      // Wrong PIN - shake animation and clear
      setState(() => _enteredPin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_savedPin.isEmpty || _unlocked) return widget.child;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // App Icon/Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Enter PIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _savedPin.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _enteredPin.length
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: index < _enteredPin.length
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Custom Dial Pad
              _buildDialPad(colorScheme, isDark),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialPad(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        _buildDialRow(['1', '2', '3'], colorScheme, isDark),
        const SizedBox(height: 16),
        _buildDialRow(['4', '5', '6'], colorScheme, isDark),
        const SizedBox(height: 16),
        _buildDialRow(['7', '8', '9'], colorScheme, isDark),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 70, height: 70), // Empty space
            _buildDialButton('0', colorScheme, isDark),
            _buildDeleteButton(colorScheme, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildDialRow(List<String> numbers, ColorScheme colorScheme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildDialButton(number, colorScheme, isDark)).toList(),
    );
  }

  Widget _buildDialButton(String number, ColorScheme colorScheme, bool isDark) {
    return InkWell(
      onTap: () => _onNumberTap(number),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainer,
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ColorScheme colorScheme, bool isDark) {
    return InkWell(
      onTap: _onDeleteTap,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainer,
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }
}
