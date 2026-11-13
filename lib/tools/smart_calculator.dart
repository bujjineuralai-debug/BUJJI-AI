
import 'package:flutter/material.dart';

class SmartCalculator extends StatefulWidget {
  const SmartCalculator({super.key});

  @override
  State<SmartCalculator> createState() => _SmartCalculatorState();
}

class _SmartCalculatorState extends State<SmartCalculator> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();
  final _rateController = TextEditingController();
  final _monthsController = TextEditingController();

  final _secondFocus = FocusNode();
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();

  String _result = '0';
  String _expression = '';
  String _mode = 'Basic';
  String _operation = '+';

  final List<String> _history = [];

  final Color _background = const Color(0xFF06101E);
  final Color _card = const Color(0xFF0B1B2D);
  final Color _cyan = const Color(0xFF25B8FF);
  final Color _gold = const Color(0xFFFFC857);

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    _rateController.dispose();
    _monthsController.dispose();
    _secondFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double? _number(String value) {
    return double.tryParse(value.trim());
  }

  String _format(double value) {
    if (!value.isFinite) return 'Invalid result';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final resultContext = _resultKey.currentContext;

      if (resultContext != null) {
        Scrollable.ensureVisible(
          resultContext,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }
    });
  }

  void _showResult(String expression, double answer) {
    FocusScope.of(context).unfocus();

    final formatted = _format(answer);

    setState(() {
      _expression = expression;
      _result = formatted;
      _history.insert(0, '$expression = $formatted');
    });

    _scrollToResult();
  }

  void _calculateBasic() {
    final a = _number(_firstController.text);
    final b = _number(_secondController.text);

    if (a == null || b == null) {
      setState(() => _result = 'Enter both numbers');
      return;
    }

    double answer;

    switch (_operation) {
      case '+':
        answer = a + b;
        break;
      case '-':
        answer = a - b;
        break;
      case '×':
        answer = a * b;
        break;
      case '÷':
        if (b == 0) {
          setState(() => _result = 'Cannot divide by zero');
          return;
        }
        answer = a / b;
        break;
      case '%':
        answer = a * b / 100;
        break;
      default:
        return;
    }

    _showResult('$a $_operation $b', answer);
  }

  void _calculateGst(bool add) {
    final amount = _number(_firstController.text);
    final rate = _number(_rateController.text);

    if (amount == null || rate == null || amount < 0 || rate < 0) {
      setState(() => _result = 'Enter valid GST details');
      return;
    }

    final gst = add
        ? amount * rate / 100
        : amount * rate / (100 + rate);

    final total = add ? amount + gst : amount - gst;

    _showResult(
      add ? 'Amount + GST ($rate%)' : 'Amount excluding GST ($rate%)',
      total,
    );
  }

  void _calculateEmi() {
    final principal = _number(_firstController.text);
    final annualRate = _number(_rateController.text);
    final monthsValue = _number(_monthsController.text);

    if (principal == null ||
        annualRate == null ||
        monthsValue == null ||
        principal <= 0 ||
        annualRate < 0 ||
        monthsValue <= 0) {
      setState(() => _result = 'Enter valid EMI details');
      return;
    }

    final months = monthsValue.round();
    final monthlyRate = annualRate / 12 / 100;

    final emi = monthlyRate == 0
        ? principal / months
        : principal *
            monthlyRate *
            _power(1 + monthlyRate, months) /
            (_power(1 + monthlyRate, months) - 1);

    _showResult('Monthly EMI', emi);
  }

  double _power(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  void _clear() {
    _firstController.clear();
    _secondController.clear();
    _rateController.clear();
    _monthsController.clear();

    setState(() {
      _expression = '';
      _result = '0';
    });
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    String hint = 'Enter value',
    FocusNode? focusNode,
    bool nextField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: _cyan, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction:
              nextField ? TextInputAction.next : TextInputAction.done,
          onSubmitted: (_) {
            if (nextField) {
              FocusScope.of(context).nextFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _card,
          foregroundColor: _cyan,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _cyan.withOpacity(0.35)),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _operationButton(String operation) {
    final selected = _operation == operation;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () {
            setState(() => _operation = operation);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: selected ? _cyan : _card,
            foregroundColor: selected ? _background : _cyan,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            operation,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _input(
          'First Number',
          _firstController,
          nextField: true,
        ),
        const SizedBox(height: 16),
        _input(
          'Second Number',
          _secondController,
          focusNode: _secondFocus,
        ),
        const SizedBox(height: 20),
        Text(
          'Select Operation',
          style: TextStyle(color: _cyan, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _operationButton('+'),
            _operationButton('-'),
            _operationButton('×'),
            _operationButton('÷'),
            _operationButton('%'),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              _calculateBasic();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              foregroundColor: _background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'CALCULATE  =',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: _actionButton('Clear', _clear)),
      ],
    );
  }

  Widget _buildGst() {
    return Column(
      children: [
        _input('Amount (₹)', _firstController),
        const SizedBox(height: 16),
        _input('GST Rate (%)', _rateController, hint: 'Example: 18'),
        const SizedBox(height: 18),
        Row(
          children: [
            _actionButton('Add GST', () => _calculateGst(true)),
            _actionButton('Remove GST', () => _calculateGst(false)),
          ],
        ),
        SizedBox(width: double.infinity, child: _actionButton('Clear', _clear)),
      ],
    );
  }

  Widget _buildEmi() {
    return Column(
      children: [
        _input('Loan Amount (₹)', _firstController),
        const SizedBox(height: 16),
        _input('Annual Interest Rate (%)', _rateController),
        const SizedBox(height: 16),
        _input('Loan Duration (Months)', _monthsController),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: _actionButton('Calculate EMI', _calculateEmi)),
        SizedBox(width: double.infinity, child: _actionButton('Clear', _clear)),
      ],
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No calculation history yet',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _history.clear()),
            child: Text('Clear History', style: TextStyle(color: _gold)),
          ),
        ),
        ..._history.map(
          (item) => ListTile(
            leading: Icon(Icons.history, color: _cyan),
            title: Text(
              item,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMode(String mode) {
    final selected = _mode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _clear();
          setState(() => _mode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? _cyan.withOpacity(0.18) : _card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _cyan : Colors.white12,
            ),
          ),
          child: Center(
            child: Text(
              mode,
              style: TextStyle(
                color: selected ? _cyan : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Smart Calculator',
          style: TextStyle(
            color: _cyan,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: _resultKey,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _cyan.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression.isEmpty
                          ? 'BUJJI AI Calculator'
                          : _expression,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      child: Text(
                        _result,
                        style: TextStyle(
                          color: _gold,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _buildMode('Basic'),
                  _buildMode('GST'),
                  _buildMode('EMI'),
                  _buildMode('History'),
                ],
              ),
              const SizedBox(height: 22),
              if (_mode == 'Basic') _buildBasic(),
              if (_mode == 'GST') _buildGst(),
              if (_mode == 'EMI') _buildEmi(),
              if (_mode == 'History') _buildHistory(),
            ],
          ),
        ),
      ),
    );
  }
}
