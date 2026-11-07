import 'package:flutter/material.dart';

class SmartCalculator extends StatefulWidget {
  const SmartCalculator({super.key});

  @override
  State<SmartCalculator> createState() => _SmartCalculatorState();
}

class _SmartCalculatorState extends State<SmartCalculator> {
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _monthsController = TextEditingController();

  String _result = '0';
  String _expression = '';
  String _mode = 'Basic';
  final List<String> _history = [];

  final Color _background = const Color(0xFF071426);
  final Color _card = const Color(0xFF10243D);
  final Color _cyan = const Color(0xFF00D9FF);
  final Color _gold = const Color(0xFFFFC857);

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    _rateController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  double _number(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  String _format(double value) {
    if (!value.isFinite) return 'Invalid result';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  void _calculate(String operation) {
    final a = _number(_firstController.text);
    final b = _number(_secondController.text);

    double answer;

    switch (operation) {
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

    _showResult('$a $operation $b', answer);
  }

  void _calculateGst(bool add) {
    final amount = _number(_firstController.text);
    final rate = _number(_rateController.text);

    final gst = amount * rate / 100;
    final total = add ? amount + gst : amount - gst;

    _showResult(
      add ? 'Amount + GST ($rate%)' : 'Amount excluding GST ($rate%)',
      total,
    );
  }

  void _calculateEmi() {
    final principal = _number(_firstController.text);
    final annualRate = _number(_rateController.text);
    final months = _number(_monthsController.text).round();

    if (principal <= 0 || months <= 0 || annualRate < 0) {
      setState(() => _result = 'Enter valid EMI details');
      return;
    }

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

  void _showResult(String expression, double answer) {
    final formatted = _format(answer);

    setState(() {
      _expression = expression;
      _result = formatted;
      _history.insert(0, '$expression = $formatted');
    });
  }

  void _clear() {
    setState(() {
      _firstController.clear();
      _secondController.clear();
      _rateController.clear();
      _monthsController.clear();
      _expression = '';
      _result = '0';
    });
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    String hint = 'Enter value',
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
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _background,
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _card,
            foregroundColor: _cyan,
            padding: const EdgeInsets.symmetric(vertical: 16),
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
      ),
    );
  }

  Widget _buildBasic() {
    return Column(
      children: [
        _input('First Number', _firstController),
        const SizedBox(height: 16),
        _input('Second Number', _secondController),
        const SizedBox(height: 18),
        Row(
          children: [
            _actionButton('+', () => _calculate('+')),
            _actionButton('-', () => _calculate('-')),
          ],
        ),
        Row(
          children: [
            _actionButton('×', () => _calculate('×')),
            _actionButton('÷', () => _calculate('÷')),
          ],
        ),
        Row(
          children: [
            _actionButton('%', () => _calculate('%')),
            _actionButton('Clear', _clear),
          ],
        ),
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
        _actionButton('Clear', _clear),
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
        _actionButton('Calculate EMI', _calculateEmi),
        _actionButton('Clear', _clear),
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
          setState(() {
            _mode = mode;
            _clear();
          });
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
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
                      _expression.isEmpty ? 'BUJJI AI Calculator' : _expression,
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
