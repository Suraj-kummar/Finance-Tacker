import 'dart:io';

void main() {
  final file = File('lib/screens/home.dart');
  if (!file.existsSync()) {
    print('File not found');
    exit(1);
  }
  
  List<String> lines = file.readAsLinesSync();
  
  // We are looking for the block around line 420
  // 421: child: _buildQuickAction(context, Icons.more_horiz_rounded, "More"),
  // 422: ),
  // 423: ),
  // 424: ),
  
  int anchorLine = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('child: _buildQuickAction(context, Icons.more_horiz_rounded, "More"),')) {
      anchorLine = i;
      break;
    }
  }
  
  if (anchorLine == -1) {
    print('Anchor line not found');
    exit(1);
  }
  
  print('Anchor found at line ${anchorLine + 1}');
  
  // We expect the next line to be `),` or `  ),` closing the GestureDetector
  // The lines after that are suspicious if they are also `),`
  
  // Let's inspect next few lines
  for (int i = 1; i <= 4; i++) {
      if (anchorLine + i < lines.length) {
          print('Line ${anchorLine + 1 + i}: ${lines[anchorLine + i]}');
      }
  }

  // Logic: Remove lines that are just `),` or `),` with whitespace, IMMEDIATELY following the valid closing of GestureDetector.
  // We assume the first `),` is valid.
  
  List<int> linesToRemove = [];
  
  // Check anchorLine + 1 (should be valid close)
  // Check anchorLine + 2 (suspect)
  // Check anchorLine + 3 (suspect)
  
  // Strict check: if line matches `^\s*\),\s*$`
  RegExp closingPattern = RegExp(r'^\s*\),\s*$');
  
  if (closingPattern.hasMatch(lines[anchorLine + 2])) {
      linesToRemove.add(anchorLine + 2);
  }
  if (closingPattern.hasMatch(lines[anchorLine + 3])) {
      linesToRemove.add(anchorLine + 3);
  }
  
  if (linesToRemove.isEmpty) {
      print('No obvious duplicate closing lines found.');
      // Force check if they are `                             ),`
      if (lines[anchorLine + 2].trim() == '),') linesToRemove.add(anchorLine + 2);
      if (lines[anchorLine + 3].trim() == '),') linesToRemove.add(anchorLine + 3);
  }
  
  if (linesToRemove.isNotEmpty) {
      print('Removing lines: ${linesToRemove.map((i) => i + 1).toList()}');
      // Remove in reverse order to keep indices valid
      linesToRemove.sort((a, b) => b.compareTo(a));
      for (int idx in linesToRemove) {
          lines.removeAt(idx);
      }
      file.writeAsStringSync(lines.join('\n'));
      print('Successfully removed extra lines.');
  } else {
      print('Nothing removed.');
  }
}
