import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

double? convertCurrencyAmount({
  required double amount,
  required double fromRate,
  required double toRate,
}) {
  if (!amount.isFinite ||
      amount < 0 ||
      !fromRate.isFinite ||
      fromRate <= 0 ||
      !toRate.isFinite ||
      toRate <= 0) {
    return null;
  }

  return (amount / fromRate) * toRate;
}

class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  static const Color background = Color(0xFF071426);
  static const Color card = Color(0xFF10243D);
  static const Color cyan = Color(0xFF00D9FF);
  static const Color gold = Color(0xFFFFC857);
  static const String ratesUrl = 'https://open.er-api.com/v6/latest/USD';

  static const Map<String, String> currencies = {
    'USD': 'US Dollar',
    'INR': 'Indian Rupee',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal',
    'SGD': 'Singapore Dollar',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'CHF': 'Swiss Franc',
    'NZD': 'New Zealand Dollar',
    'ZAR': 'South African Rand',
    'BDT': 'Bangladeshi Taka',
  };

  final TextEditingController amountController =
      TextEditingController(text: '1');

  Map<String, double> rates = {};
  String fromCurrency = 'USD';
  String toCurrency = 'INR';
  String? errorMessage;
  DateTime? lastUpdated;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    amountController.addListener(_refreshConversion);
    _loadRates();
  }

  @override
  void dispose() {
    amountController.removeListener(_refreshConversion);
    amountController.dispose();
    super.dispose();
  }

  void _refreshConversion() {
    if (mounted) setState(() {});
  }

  double? get convertedAmount {
    final amount = double.tryParse(amountController.text.trim());
    final fromRate = rates[fromCurrency];
    final toRate = rates[toCurrency];

    if (amount == null || fromRate == null || toRate == null) {
      return null;
    }

    return convertCurrencyAmount(
      amount: amount,
      fromRate: fromRate,
      toRate: toRate,
    );
  }

  Future<void> _loadRates() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client
          .getUrl(Uri.parse(ratesUrl))
          .timeout(const Duration(seconds: 20));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server returned HTTP ${response.statusCode}.');
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic> || decoded['result'] != 'success') {
        throw Exception('Exchange-rate service returned an invalid response.');
      }

      final rawRates = decoded['rates'];
      if (rawRates is! Map<String, dynamic>) {
        throw Exception('Exchange rates are missing from the response.');
      }

      final parsedRates = <String, double>{};
      for (final entry in rawRates.entries) {
        final value = entry.value;
        if (value is num && value > 0 && value.isFinite) {
          parsedRates[entry.key] = value.toDouble();
        }
      }

      if (!parsedRates.containsKey('USD') ||
          !parsedRates.containsKey('INR')) {
        throw Exception('Required exchange rates are unavailable.');
      }

      final timestamp = decoded['time_last_update_unix'];
      final updated = timestamp is num
          ? DateTime.fromMillisecondsSinceEpoch(
              timestamp.toInt() * 1000,
              isUtc: true,
            ).toLocal()
          : null;

      if (!mounted) return;
      setState(() {
        rates = parsedRates;
        lastUpdated = updated;
        errorMessage = null;
      });
    } on TimeoutException {
      if (mounted) {
        setState(() {
          errorMessage = 'Connection timed out. Please try again.';
        });
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          errorMessage = 'No internet connection. Connect and try again.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Unable to update exchange rates. Please try again.';
        });
      }
      debugPrint('Currency rates error: $error');
    } finally {
      client.close(force: true);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _swapCurrencies() {
    setState(() {
      final previousFrom = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = previousFrom;
    });
  }

  String _formatAmount(double value) {
    return value.toStringAsFixed(2);
  }

  String _updatedLabel() {
    final updated = lastUpdated;
    if (updated == null) return 'Update time unavailable';
    final date = updated.toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return 'Rates updated: ${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '$hour:$minute $period';
  }

  Widget _currencyDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: card,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0A1B30),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cyan.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cyan),
        ),
      ),
      items: currencies.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text('${entry.key} - ${entry.value}'),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = convertedAmount;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: const Text(
          'Currency Converter',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Convert currencies with updated exchange rates.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 22),
              _buildInputCard(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _currencyDropdown(
                      value: fromCurrency,
                      onChanged: (value) =>
                          setState(() => fromCurrency = value!),
                    ),
                  ),
                  IconButton(
                    onPressed: _swapCurrencies,
                    tooltip: 'Swap currencies',
                    icon: const Icon(Icons.swap_horiz_rounded,
                        color: gold, size: 30),
                  ),
                  Expanded(
                    child: _currencyDropdown(
                      value: toCurrency,
                      onChanged: (value) =>
                          setState(() => toCurrency = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cyan.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Converted Amount',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    if (result != null)
                      Text(
                        '${_formatAmount(result)} $toCurrency',
                        style: const TextStyle(
                          color: cyan,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      const Text(
                        'Enter a valid amount',
                        style: TextStyle(color: gold, fontSize: 16),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(color: cyan),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _loadRates,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh Exchange Rates'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cyan,
                    side: BorderSide(color: cyan.withOpacity(0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              const SizedBox(height: 12),
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A2028),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              Text(
                _updatedLabel(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 10),
              const Text(
                'Rates are provided by an online exchange-rate service and are '
                'typically updated daily. They may differ from bank or card rates.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cyan.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
