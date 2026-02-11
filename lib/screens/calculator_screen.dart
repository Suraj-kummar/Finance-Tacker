import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '0';
  String _result = '0';
  String _expression = '';

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _input = '0';
        _result = '0';
        _expression = '';
      } else if (buttonText == '⌫') {
        if (_input.isNotEmpty && _input != '0') {
          _input = _input.substring(0, _input.length - 1);
          if (_input.isEmpty) _input = '0';
        }
      } else if (buttonText == '=') {
        _calculateResult();
      } else if (_isOperator(buttonText)) {
        if (_input != '0' && _input != 'Error') {
           _expression += _input + buttonText;
           _input = '0';
        } else if (_expression.isNotEmpty && _isOperator(_expression[_expression.length - 1])) {
           // Replace last operator
           _expression = _expression.substring(0, _expression.length - 1) + buttonText;
        }
      } else {
        if (_input == '0' || _input == 'Error') {
          _input = buttonText;
        } else {
          _input += buttonText;
        }
      }
    });
  }
  
  bool _isOperator(String text) {
    return text == '+' || text == '-' || text == '*' || text == '/' || text == '%';
  }

  void _calculateResult() {
    try {
      String finalExpression = _expression + _input;
      // Handle simple evaluation using a helper
      double eval = _evaluateMathExpression(finalExpression);
      
      // Format result (remove .0 if integer)
      String evalResult = eval.toString();
      if (evalResult.endsWith(".0")) {
        evalResult = evalResult.substring(0, evalResult.length - 2);
      }
      
      setState(() {
        _result = evalResult;
        _input = evalResult;
        _expression = '';
      });
    } catch (e) {
      setState(() {
        _input = "Error";
      });
    }
  }

  // Simple evaluator supporting +, -, *, /, % with correct precedence
  double _evaluateMathExpression(String expression) {
    expression = expression.replaceAll('x', '*');
    List<String> rpn = _shuntingYard(expression);
    return _evaluateRPN(rpn);
  }

  List<String> _shuntingYard(String expression) {
    List<String> outputQueue = [];
    List<String> operatorStack = [];
    
    // Tokenize
    RegExp regex = RegExp(r'(\d+(\.\d+)?|[\+\-\*\/%])');
    Iterable<Match> matches = regex.allMatches(expression);
    
    for (Match match in matches) {
      String token = match.group(0)!;
      if (double.tryParse(token) != null) {
        outputQueue.add(token);
      } else if (_isOperator(token)) {
        while (operatorStack.isNotEmpty && _getPrecedence(operatorStack.last) >= _getPrecedence(token)) {
          outputQueue.add(operatorStack.removeLast());
        }
        operatorStack.add(token);
      }
    }
    
    while (operatorStack.isNotEmpty) {
      outputQueue.add(operatorStack.removeLast());
    }
    
    return outputQueue;
  }
  
  double _evaluateRPN(List<String> rpn) {
    List<double> stack = [];
    
    for (String token in rpn) {
      if (double.tryParse(token) != null) {
        stack.add(double.parse(token));
      } else {
        if (stack.length < 2) throw Exception("Invalid expression");
        double b = stack.removeLast();
        double a = stack.removeLast();
        switch (token) {
          case '+': stack.add(a + b); break;
          case '-': stack.add(a - b); break;
          case '*': stack.add(a * b); break;
          case '/': stack.add(a / b); break;
          case '%': stack.add(a % b); break;
        }
      }
    }
    
    return stack.isNotEmpty ? stack.last : 0.0;
  }
  
  int _getPrecedence(String op) {
    if (op == '*' || op == '/' || op == '%') return 2;
    if (op == '+' || op == '-') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text("Calculator", style: TextStyle(color: colorScheme.onSurface)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Display Area
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                   mainAxisAlignment: MainAxisAlignment.end,
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                      if (_expression.isNotEmpty)
                        Text(
                          _expression, 
                          style: TextStyle(
                            fontSize: 24, 
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _result == '0' && _input != '0' && !_isOperator(_input) ? _input : _result,
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w300,
                            color: colorScheme.onSurface,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                   ],
                ),
              ),
            ),
            
            // Buttons Area
            Column(
              children: [
                _buildButtonRow(['C', '%', '⌫', '/'], colorScheme),
                _buildButtonRow(['7', '8', '9', '*'], colorScheme),
                _buildButtonRow(['4', '5', '6', '-'], colorScheme),
                _buildButtonRow(['1', '2', '3', '+'], colorScheme),
                _buildButtonRow(['0', '.', '=']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons, [ColorScheme? colorScheme]) {
    // We can access theme in _buildButton via context or pass it down. 
    // Since _buildButton doesn't have context easily without passing, let's assume we pass colorScheme or access it inside via context if we changed signature.
    // For simplicity, let's keep it simple. But wait, _buildButtonRow calls _buildButton.
    // I need to update _buildButton signature or use Builder. Use context from build method? No, separated widgets.
    // I will pass colorScheme to _buildButton through _buildButtonRow.
    
    // Rereading: I can't easily change _buildButtonRow signature in existing call sites without changing ALL of them in the replacement content.
    // I am replacing the whole build method AND helper methods.
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: buttons.map((text) {
          return _buildButton(text, context);
        }).toList(),
      ),
    );
  }

  Widget _buildButton(String text, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    bool isOperator = _isOperator(text) || text == '=';
    bool isFunction = text == 'C' || text == '⌫' || text == '%';
    bool isZero = text == '0';
    
    Color bgColor;
    Color textColor;

    if (isOperator) {
      bgColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (isFunction) {
      bgColor = colorScheme.secondaryContainer;
      textColor = colorScheme.onSecondaryContainer;
    } else {
      // Numbers
      bgColor = colorScheme.surfaceContainerHighest; 
      textColor = colorScheme.onSurface;
    }

    if (isZero) {
       // "0" button spans 2 columns
       return Expanded(
         flex: 2,
         child: Container(
           margin: const EdgeInsets.only(right: 16), // space to the next button
           height: 80, 
           decoration: BoxDecoration(
             color: bgColor,
             borderRadius: BorderRadius.circular(40),
           ),
           child: Material(
             color: Colors.transparent,
             child: InkWell(
               borderRadius: BorderRadius.circular(40),
               onTap: () => _onButtonPressed(text),
               child: Container(
                 alignment: Alignment.centerLeft,
                 padding: const EdgeInsets.only(left: 32),
                 child: Text(
                   text,
                   style: TextStyle(
                     fontSize: 34,
                     fontWeight: FontWeight.w500,
                     color: textColor,
                   ),
                 ),
               ),
             ),
           ),
         ),
       );
    }
    
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: text == '=' || text == '+' || text == '-' || text == '*' || text == '/' ? 0 : 16),
        height: 80,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
         child: Material(
           color: Colors.transparent,
           child: InkWell(
             customBorder: const CircleBorder(),
             onTap: () => _onButtonPressed(text),
             child: Center(
               child: Text(
                 text,
                 style: TextStyle(
                   fontSize: 34,
                   fontWeight: FontWeight.w500,
                   color: textColor,
                 ),
               ),
             ),
           ),
         ),
      ),
    );
  }
}
