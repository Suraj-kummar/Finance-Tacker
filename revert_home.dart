import 'dart:io';

void main() {
  final file = File('lib/screens/home.dart');
  if (!file.existsSync()) {
    print('File not found');
    exit(1);
  }
  
  String content = file.readAsStringSync();
  
  // 1. Remove _buildIOSAppIcon method
  // We search for the start and end of this method.
  // Method signature: Widget _buildIOSAppIcon(...)
  
  int methodStart = content.indexOf('Widget _buildIOSAppIcon(');
  if (methodStart != -1) {
    // Find the matching closing brace. 
    // It is safer to assume the next method starts with 'Widget _buildTransactionTile'
    // or search for brace balance. 
    // Given the previous view_file, we know it's followed by _buildTransactionTile.
    
    int methodEnd = content.indexOf('Widget _buildTransactionTile', methodStart);
    if (methodEnd != -1) {
       // Remove content from methodStart to methodEnd
       content = content.replaceRange(methodStart, methodEnd, '');
    } else {
       print('Warning: Could not find end of _buildIOSAppIcon method. Removing safely using brace couting.');
       // Fallback: This is risky without strict parser, but let's try finding the closing brace of the method.
       // It ends with line 742 in previous view `    );`.
       // Let's just strip manually if we know the signature.
       // Actually, if we can't find the next method, we might be at the end of class? No.
    }
  }

  // 2. Revert showModalBottomSheet
  // We look for 'showModalBottomSheet' inside 'onTap' of 'More' button.
  // Anchor: 'showModalBottomSheet(' inside the More button block.
  // We can search for the glossy implementation code snippet to replace.
  
  const glossyAnchor = 'backgroundColor: Colors.transparent,'; // Specific to glossy version
  int glossyStart = content.indexOf(glossyAnchor);
  
  if (glossyStart != -1) {
      // Find the start of the showModalBottomSheet call containing this.
      int sheetStart = content.lastIndexOf('showModalBottomSheet(', glossyStart);
      if (sheetStart != -1) {
           // Find the end of this statement.
           // It ends with `);` typically.
           // We can look for the closing parenthesis of builder or the function itself.
           
           // The structure of glossy was:
           // showModalBottomSheet( ... builder: (context) => Container(...) );
           
           // We can find the matching closing paren for showModalBottomSheet
           int openParens = 1;
           int currentIndex = sheetStart + 'showModalBottomSheet('.length;
           while (openParens > 0 && currentIndex < content.length) {
               if (content[currentIndex] == '(') openParens++;
               if (content[currentIndex] == ')') openParens--;
               currentIndex++;
           }
           
           int sheetEnd = currentIndex;
           // Check for semicolon
           if (currentIndex < content.length && content[currentIndex] == ';') {
               sheetEnd++;
           }
           
           // Code to restore
           const originalCode = r'''showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (context) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.calculate_outlined),
                                          title: const Text("Calculator"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CalculatorScreen()));
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.help_outline),
                                          title: const Text("Help & Support"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.info_outline),
                                          title: const Text("About"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );''';
                                
           content = content.replaceRange(sheetStart, sheetEnd, originalCode);
      }
  } else {
      print('Glossy menu code not found. Already reverted?');
  }
  
  file.writeAsStringSync(content);
  print('Successfully reverted home.dart');
}
