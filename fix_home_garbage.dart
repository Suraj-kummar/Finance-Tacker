import 'dart:io';

void main() {
  final file = File('lib/screens/home.dart');
  if (!file.existsSync()) {
    print('File not found');
    exit(1);
  }
  
  String content = file.readAsStringSync();
  
  // Anchor: The Settings button closure
  const anchor = 'child: _buildQuickAction(context, Icons.settings_rounded, "Settings"),';
  int anchorIdx = content.indexOf(anchor);
  if (anchorIdx == -1) {
    print('Anchor not found');
    exit(1);
  }
  
  // Find where the Settings button definition ends (after anchor)
  // anchor is line 351 (approx). line 352 is `),`.
  // We want to start replacing at line 353 `GestureDetector`.
  
  // Find `GestureDetector` after anchor
  int startIdx = content.indexOf('GestureDetector', anchorIdx);
  if (startIdx == -1) {
    print('Start GestureDetector not found');
    exit(1);
  }
  
  // Anchor End: The More button child line
  const endAnchor = 'child: _buildQuickAction(context, Icons.more_horiz_rounded, "More"),';
  int endAnchorInfoIdx = content.indexOf(endAnchor);
  if (endAnchorInfoIdx == -1) {
    print('End anchor not found');
    exit(1);
  }
  
  // We need to include the closing `),` of the GestureDetector.
  // It's usually the line after `child: ...`.
  // Find `),` after endAnchorInfoIdx
  int endIdx = content.indexOf('),', endAnchorInfoIdx);
  if (endIdx == -1) {
     print('End bracket not found');
     exit(1);
  }
  endIdx += 2; // Include `),`
  
  // The clean code to insert
  const cleanCode = r'''GestureDetector(
                              onTap: () {
                                // Show More Menu
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Handle bar
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 24),
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        // App Grid
                                        Wrap(
                                          spacing: 24,
                                          runSpacing: 24,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            _buildIOSAppIcon(
                                              context,
                                              title: "Calculator",
                                              icon: Icons.calculate_rounded,
                                              gradientColors: [const Color(0xFFFF9F0A), const Color(0xFFFFB340)],
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => const CalculatorScreen()));
                                              },
                                            ),
                                            _buildIOSAppIcon(
                                              context,
                                              title: "Help",
                                              icon: Icons.help_outline_rounded,
                                              gradientColors: [const Color(0xFF0A84FF), const Color(0xFF409CFF)],
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                                              },
                                            ),
                                            _buildIOSAppIcon(
                                              context,
                                              title: "About",
                                              icon: Icons.info_outline_rounded,
                                              gradientColors: [const Color(0xFF8E8E93), const Color(0xFFAEB0B6)],
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: _buildQuickAction(context, Icons.more_horiz_rounded, "More"),
                            ),''';

  String newContent = content.substring(0, startIdx) + cleanCode + content.substring(endIdx);
  
  file.writeAsStringSync(newContent);
  print('Successfully cleaned up home.dart');
}
