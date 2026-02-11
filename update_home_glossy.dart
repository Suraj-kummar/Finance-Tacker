import 'dart:io';

void main() {
  final file = File('lib/screens/home.dart');
  if (!file.existsSync()) {
    print('File not found');
    exit(1);
  }
  
  String content = file.readAsStringSync();
  
  // 1. INJECT HELPER METHOD
  // We need to verify if helper is already there (if script ran partially)
  if (!content.contains('_buildIOSAppIcon')) {
    const helperCode = r'''
  Widget _buildIOSAppIcon(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16), // IOS squircle-like
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gloss effect (Top shine)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                ),
                // Icon
                Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

''';
    // Insert before _buildTransactionTile
    final insertionPoint = content.indexOf('Widget _buildTransactionTile');
    if (insertionPoint != -1) {
       content = content.substring(0, insertionPoint) + helperCode + content.substring(insertionPoint);
    } else {
       print('Could not find injection point for helper method');
       exit(1);
    }
  }

  // 2. REPLACE BOTTOM SHEET LOGIC
  // We look for the start of showModalBottomSheet and the end of its block
  // This is tricky with simple string matching, but we know the structure from previous view_file
  
  // Pivot: Find 'showModalBottomSheet' inside 'GestureDetector'
  int startIdx = content.indexOf('showModalBottomSheet');
  if (startIdx == -1) {
     print('Could not find showModalBottomSheet');
     exit(1);
  }
  
  // We need to find the specific one for "More" menu. 
  // Let's search for the comment "// Show More Menu" which we saw in the file content
  int commentIdx = content.indexOf('// Show More Menu');
  if (commentIdx == -1) {
    // Fallback: search for "more_horiz_rounded" and go back
    int iconIdx = content.indexOf('Icons.more_horiz_rounded');
    if (iconIdx == -1) {
        print('Could not find More menu anchor');
        exit(1);
    }
    // Search backwards for showModalBottomSheet
    startIdx = content.lastIndexOf('showModalBottomSheet', iconIdx);
  } else {
    startIdx = content.indexOf('showModalBottomSheet', commentIdx);
  }
  
  if (startIdx == -1) {
      print('Could not locate BottomSheet start');
      exit(1);
  }

  // Find the end of this statement. It ends with ");" usually, but let's be safer.
  // The structure is showModalBottomSheet(...); relative to the GestureDetector onTap closure.
  // It's inside onTap: () { ... }
  // We can search for the closing `};` of the onTap
  int onTapEnd = content.indexOf('},', startIdx); // It's followed by `child:` usually
  if (onTapEnd == -1) {
      print('Could not locate onTap end');
      exit(1);
  }
  
  // Extract existing block to verify
  // String existing = content.substring(startIdx, onTapEnd);
  // print("Replacing:\n$existing"); 

  const newBottomSheetCode = r'''showModalBottomSheet(
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
                              ''';
  
  // Replace
  // We replace from startIdx up to the character before onTapEnd (which is usually whitespace/newline)
  // We need to keep the closing brace of onTap, so we replace everything inside the block if possible
  // Actually, startIdx is 'showModalBottomSheet'. 
  // We want to replace `showModalBottomSheet(....);`
  // The semicolon is important.
  
  int statementEnd = content.indexOf(';', startIdx);
  if (statementEnd == -1 || statementEnd > onTapEnd) {
      // Maybe it doesn't have semicolon if it's single expression? Block usually has semicolon.
      // Let's assume it touches onTapEnd.
      statementEnd = onTapEnd;
      // Backtrack to find last non-whitespace
      while (statementEnd > startIdx && content[statementEnd-1].trim().isEmpty) {
          statementEnd--;
      }
  } else {
      statementEnd += 1; // Include semicolon
  }

  content = content.substring(0, startIdx) + newBottomSheetCode + content.substring(statementEnd);
  
  file.writeAsStringSync(content);
  print('Successfully updated home.dart with glossy menu');
}
