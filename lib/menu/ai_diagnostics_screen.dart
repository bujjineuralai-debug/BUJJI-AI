import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/bujji_api_service.dart';

class AiDiagnosticsScreen extends StatefulWidget {
  const AiDiagnosticsScreen({super.key});

  @override
  State<AiDiagnosticsScreen> createState() => _AiDiagnosticsScreenState();
}

class _AiDiagnosticsScreenState extends State<AiDiagnosticsScreen> {
  static const Color _background = Color(0xFF020A14);
  static const Color _panel = Color(0xFF0B1B2D);
  static const Color _cyan = Color(0xFF25B8FF);
  static const Color _muted = Color(0xFF9AACC1);

  List<Map<String, dynamic>> _entries = <Map<String, dynamic>>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await BujjiApiService.getRecentDiagnostics();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    await BujjiApiService.clearDiagnostics();
    await _load();
  }

  Future<void> _copyTrace(String traceId) async {
    await Clipboard.setData(ClipboardData(text: traceId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trace ID copied.')),
    );
  }

  String _formatTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Unknown time';
    return parsed.toLocal().toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF06101E),
        foregroundColor: Colors.white,
        title: const Text('AI Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Clear local diagnostics',
            onPressed: _entries.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _cyan.withOpacity(.28)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request health & trace history',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'ఈ పరికరంలో నిల్వ చేసిన చివరి 50 API attempts మాత్రమే ఇక్కడ కనిపిస్తాయి. Prompts, chat history, passwords, Firebase tokens, images లేదా వ్యక్తిగత వివరాలు ఈ dashboard‌లో నిల్వ చేయము.',
                    style: TextStyle(color: _muted, height: 1.45, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Text(
                    'ఇంకా API diagnostics లేవు. Chat లేదా Vision request చేసిన తర్వాత వివరాలు ఇక్కడ కనిపిస్తాయి.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, height: 1.5),
                  ),
                ),
              )
            else
              ..._entries.map(_entryCard),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(Map<String, dynamic> entry) {
    final success = entry['outcome'] == 'success';
    final traceId = entry['requestId']?.toString();
    final status = entry['statusCode']?.toString() ?? '—';
    final duration = entry['durationMs']?.toString() ?? '—';
    final endpoint = entry['endpoint']?.toString() ?? 'API';
    final errorType = entry['errorType']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: success ? Colors.green.withOpacity(.35) : Colors.orange.withOpacity(.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: success ? Colors.greenAccent : Colors.orangeAccent,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  endpoint,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                success ? 'Success' : 'Failed',
                style: TextStyle(
                  color: success ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'HTTP $status  •  $duration ms',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(entry['timestamp']),
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
          if (errorType != null) ...[
            const SizedBox(height: 5),
            Text(
              'Error category: $errorType',
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
          ],
          if (traceId != null && traceId.isNotEmpty) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    'Trace ID: $traceId',
                    style: const TextStyle(color: _cyan, fontSize: 11),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy Trace ID',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _copyTrace(traceId),
                  icon: const Icon(Icons.copy_rounded, color: _cyan, size: 18),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
