import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  static const _endpoint = 'https://open.er-api.com/v6/latest/USD';
  static const _cacheKey = 'bujji_currency_rates_v1';
  static const _timeKey = 'bujji_currency_rates_time_v1';
  static const _bg = Color(0xFF06101E);
  static const _card = Color(0xFF0B1B2D);
  static const _cyan = Color(0xFF25B8FF);
  static const _gold = Color(0xFFFFC857);

  static const Map<String, String> currencies = {
    'INR': 'Indian Rupee', 'USD': 'US Dollar', 'EUR': 'Euro',
    'GBP': 'British Pound', 'AED': 'UAE Dirham', 'SAR': 'Saudi Riyal',
    'KWD': 'Kuwaiti Dinar', 'QAR': 'Qatari Riyal', 'OMR': 'Omani Rial',
    'BHD': 'Bahraini Dinar', 'JPY': 'Japanese Yen', 'CNY': 'Chinese Yuan',
    'SGD': 'Singapore Dollar', 'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar', 'CHF': 'Swiss Franc', 'NZD': 'New Zealand Dollar',
    'HKD': 'Hong Kong Dollar', 'MYR': 'Malaysian Ringgit',
    'THB': 'Thai Baht', 'IDR': 'Indonesian Rupiah', 'PKR': 'Pakistani Rupee',
    'BDT': 'Bangladeshi Taka', 'LKR': 'Sri Lankan Rupee',
    'NPR': 'Nepalese Rupee', 'KRW': 'South Korean Won',
    'TRY': 'Turkish Lira', 'ZAR': 'South African Rand',
    'RUB': 'Russian Ruble', 'BRL': 'Brazilian Real',
    'MXN': 'Mexican Peso', 'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone', 'DKK': 'Danish Krone',
    'PLN': 'Polish Zloty', 'CZK': 'Czech Koruna',
    'HUF': 'Hungarian Forint', 'ILS': 'Israeli New Shekel',
    'EGP': 'Egyptian Pound', 'KES': 'Kenyan Shilling',
    'NGN': 'Nigerian Naira', 'GHS': 'Ghanaian Cedi',
    'PHP': 'Philippine Peso', 'VND': 'Vietnamese Dong',
    'ARS': 'Argentine Peso', 'CLP': 'Chilean Peso',
    'COP': 'Colombian Peso', 'UAH': 'Ukrainian Hryvnia',
  };

  final amountController = TextEditingController(text: '1');
  String fromCode = 'USD';
  String toCode = 'INR';
  Map<String, double> rates = {};
  DateTime? updatedAt;
  bool loading = true;
  bool refreshing = false;
  String? error;
  bool usingCache = false;

  @override
  void initState() {
    super.initState();
    amountController.addListener(_refreshUi);
    _loadRates();
  }

  @override
  void dispose() {
    amountController.removeListener(_refreshUi);
    amountController.dispose();
    super.dispose();
  }

  void _refreshUi() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRates() async {
    await _readCache();
    await _fetchRates();
  }

  Future<void> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      final savedTime = prefs.getInt(_timeKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final parsed = <String, double>{};
      decoded.forEach((key, value) {
        if (value is num && value > 0) parsed[key] = value.toDouble();
      });
      if (parsed.isEmpty) return;
      if (!mounted) return;
      setState(() {
        rates = parsed;
        updatedAt = savedTime == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(savedTime);
        usingCache = true;
        loading = false;
      });
    } catch (e) {
      debugPrint('Currency cache read error: $e');
    }
  }

  Future<void> _fetchRates() async {
    if (!mounted) return;
    setState(() {
      refreshing = true;
      error = null;
    });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 15));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(const Duration(seconds: 15));
      final body = await utf8.decoder.bind(response).join()
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw HttpException('Rate service returned HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic> || decoded['result'] != 'success'
          || decoded['rates'] is! Map) {
        throw const FormatException('Invalid exchange-rate response');
      }
      final parsed = <String, double>{};
      (decoded['rates'] as Map).forEach((key, value) {
        if (value is num && value > 0) parsed[key.toString()] = value.toDouble();
      });
      if (parsed.isEmpty || !parsed.containsKey('USD')) {
        throw const FormatException('No usable exchange rates received');
      }
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(parsed));
      await prefs.setInt(_timeKey, now.millisecondsSinceEpoch);
      if (!mounted) return;
      setState(() {
        rates = parsed;
        updatedAt = now;
        usingCache = false;
        loading = false;
        refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        refreshing = false;
        error = rates.isEmpty ? 'Internet unavailable. Connect and try again.' : null;
        usingCache = rates.isNotEmpty;
      });
    } finally {
      client.close(force: true);
    }
  }

  double? get converted {
    final amount = double.tryParse(amountController.text.trim());
    final fromRate = rates[fromCode];
    final toRate = rates[toCode];
    if (amount == null || amount < 0 || fromRate == null || toRate == null) {
      return null;
    }
    return amount / fromRate * toRate;
  }

  String _format(double value) {
    return value.toStringAsFixed(value.abs() >= 1000 ? 2 : 4);
  }

  Future<void> _chooseCurrency(bool isFrom) async {
    final selected = isFrom ? fromCode : toCode;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _CurrencyPicker(selected: selected),
    );
    if (choice == null || !mounted) return;
    setState(() {
      if (isFrom) {
        fromCode = choice;
      } else {
        toCode = choice;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = converted;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Currency Converter',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Refresh rates',
            onPressed: refreshing ? null : _fetchRates,
            icon: refreshing
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _cyan))
                : const Icon(Icons.refresh_rounded, color: _cyan),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF153B58), Color(0xFF0B1B2D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cyan.withOpacity(.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CONVERT CURRENCIES',
                      style: TextStyle(color: _cyan, letterSpacing: 1.5,
                          fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Fast. Simple. Reliable.',
                      style: TextStyle(color: Colors.white,
                          fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Convert using the latest available exchange rates.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _currencyCard(
              label: 'YOU SEND',
              code: fromCode,
              onTap: () => _chooseCurrency(true),
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 25,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter amount',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 18),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Material(
                  color: _cyan.withOpacity(.13),
                  shape: const CircleBorder(
                      side: BorderSide(color: _cyan, width: 1)),
                  child: IconButton(
                    tooltip: 'Swap currencies',
                    onPressed: () => setState(() {
                      final old = fromCode;
                      fromCode = toCode;
                      toCode = old;
                    }),
                    icon: const Icon(Icons.swap_vert_rounded,
                        color: _cyan, size: 28),
                  ),
                ),
              ),
            ),
            _currencyCard(
              label: 'YOU RECEIVE',
              code: toCode,
              onTap: () => _chooseCurrency(false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  result == null ? '—' : _format(result),
                  style: const TextStyle(color: _gold, fontSize: 27,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: _cyan),
              )),
            if (error != null)
              _statusMessage(error!, Icons.wifi_off_rounded, Colors.orangeAccent),
            if (!loading && rates.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(usingCache ? Icons.offline_bolt_rounded
                          : Icons.check_circle_rounded,
                          color: usingCache ? _gold : Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(usingCache
                          ? 'Offline mode · Saved rates'
                          : 'Rates loaded successfully',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 8),
                    Text(updatedAt == null ? 'Saved rate date unavailable'
                        : 'Last saved: ${updatedAt!.toLocal()}'.split('.').first,
                        style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    if (rates[fromCode] != null && rates[toCode] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('1 $fromCode = ${_format(rates[toCode]! / rates[fromCode]!)} $toCode',
                            style: const TextStyle(color: _cyan, fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Rates are provided by ExchangeRate-API and may update once per day. '
              'Offline conversions use the last successfully saved rates. '
              'Rates are indicative and may differ from bank or card provider fees.',
              style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyCard({
    required String label,
    required String code,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 12, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _cyan.withOpacity(.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54,
            fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: child),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cyan.withOpacity(.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(code, style: const TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: _cyan, size: 20),
              ]),
            ),
          ),
        ]),
        Text(currencies[code] ?? code,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }

  Widget _statusMessage(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 9),
        Expanded(child: Text(message,
            style: TextStyle(color: color, fontSize: 12))),
      ]),
    );
  }
}

class _CurrencyPicker extends StatefulWidget {
  final String selected;
  const _CurrencyPicker({required this.selected});

  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase();
    final entries = _CurrencyConverterState.currencies.entries.where((entry) =>
        entry.key.toLowerCase().contains(query) ||
        entry.value.toLowerCase().contains(query)).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18, right: 18, top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .65,
          child: Column(children: [
            const Text('Select currency', style: TextStyle(color: Colors.white,
                fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search code or currency name',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: _CurrencyConverterState._cyan),
                filled: true,
                fillColor: _CurrencyConverterState._bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final selected = entry.key == widget.selected;
                  return ListTile(
                    dense: true,
                    title: Text(entry.key, style: TextStyle(
                        color: selected ? _CurrencyConverterState._cyan : Colors.white,
                        fontWeight: FontWeight.bold)),
                    subtitle: Text(entry.value,
                        style: const TextStyle(color: Colors.white60)),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: _CurrencyConverterState._gold)
                        : null,
                    onTap: () => Navigator.pop(context, entry.key),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
