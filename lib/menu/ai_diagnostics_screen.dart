import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/bujji_api_service.dart';

enum _DiagnosticFilter { all, success, failure }

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
  static const Color _green = Color(0xFF54D6A0);
  static const Color _orange = Color(0xFFFFB45C);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _entries = <Map<String, dynamic>>[];
  _DiagnosticFilter _filter = _DiagnosticFilter.all;
  bool _loading = true;
  bool _clearing = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final entries = await BujjiApiService.getRecentDiagnostics();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Clear local diagnostics?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This removes the diagnostic history stored on this device. It does not delete chat history or server logs.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    await BujjiApiService.clearDiagnostics();
    if (!mounted) return;
    setState(() {
      _entries = <Map<String, dynamic>>[];
      _clearing = false;
    });
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
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}  ${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  bool _isSuccess(Map<String, dynamic> entry) => entry['outcome'] == 'success';

  List<Map<String, dynamic>> get _visibleEntries {
    final query = _query.trim().toLowerCase();
    return _entries.where((entry) {
      final success = _isSuccess(entry);
      if (_filter == _DiagnosticFilter.success && !success) return false;
      if (_filter == _DiagnosticFilter.failure && success) return false;
      if (query.isEmpty) return true;
      final searchable = [
        entry['requestId'],
        entry['endpoint'],
        entry['statusCode'],
        entry['errorType'],
        entry['timestamp'],
      ].where((value) => value != null).join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  int get _successCount => _entries.where(_isSuccess).length;
  int get _failureCount => _entries.length - _successCount;

  int get _averageDuration {
    final values = _entries
        .map((entry) => entry['durationMs'])
        .whereType<num>()
        .map((value) => value.toInt())
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) ~/ values.length;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleEntries;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF06101E),
        foregroundColor: Colors.white,
        title: const Text('AI Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Refresh diagnostics',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Clear local diagnostics',
            onPressed: _entries.isEmpty || _clearing ? null : _clear,
            icon: _clearing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _introCard(),
            const SizedBox(height: 14),
            if (!_loading) _summary(),
            const SizedBox(height: 14),
            _searchField(),
            const SizedBox(height: 10),
            _filterBar(),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_entries.isEmpty)
              _emptyState(
                'No diagnostics yet',
                'Chat లేదా Vision request చేసిన తర్వాత API attempts ఇక్కడ కనిపిస్తాయి.',
                Icons.monitor_heart_outlined,
              )
            else if (visible.isEmpty)
              _emptyState(
                'No matching diagnostics',
                'Search text లేదా selected filter మార్చి మళ్లీ ప్రయత్నించండి.',
                Icons.search_off_rounded,
              )
            else ...[
              Row(
                children: [
                  Text(
                    '${visible.length} of ${_entries.length} attempts',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const Spacer(),
                  const Text('Newest first', style: TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 9),
              ...visible.map(_entryCard),
            ],
            const SizedBox(height: 12),
            const Text(
              'Privacy: ఈ dashboard‌లో device-local API metadata మాత్రమే చూపిస్తాం. Prompts, chat content, passwords, Firebase tokens, images లేదా personal data చూపించము. ఇది server-side distributed trace viewer కాదు.',
              style: TextStyle(color: _muted, fontSize: 11, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _cyan.withOpacity(.28)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_rounded, color: _cyan, size: 20),
              SizedBox(width: 8),
              Text(
                'Request health & trace history',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 7),
          Text(
            'చివరి 50 API attempts‌ను Trace ID, endpoint, HTTP status, duration మరియు error category ఆధారంగా పరిశీలించండి.',
            style: TextStyle(color: _muted, height: 1.45, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    return Row(
      children: [
        Expanded(child: _metricCard('Total', '${_entries.length}', Icons.receipt_long_rounded, _cyan)),
        const SizedBox(width: 8),
        Expanded(child: _metricCard('Success', '$_successCount', Icons.check_circle_outline, _green)),
        const SizedBox(width: 8),
        Expanded(child: _metricCard('Failed', '$_failureCount', Icons.error_outline, _orange)),
        const SizedBox(width: 8),
        Expanded(child: _metricCard('Avg ms', _entries.isEmpty ? '—' : '$_averageDuration', Icons.speed_rounded, Colors.white70)),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search Trace ID, endpoint, error…',
        hintStyle: const TextStyle(color: _muted, fontSize: 12),
        prefixIcon: const Icon(Icons.search_rounded, color: _cyan),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded, color: _muted),
              ),
        filled: true,
        fillColor: _panel,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _filterBar() {
    return Wrap(
      spacing: 8,
      children: [
        _filterChip('All', _DiagnosticFilter.all),
        _filterChip('Success', _DiagnosticFilter.success),
        _filterChip('Failed', _DiagnosticFilter.failure),
      ],
    );
  }

  Widget _filterChip(String label, _DiagnosticFilter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: _cyan.withOpacity(.2),
      backgroundColor: _panel,
      labelStyle: TextStyle(color: selected ? _cyan : _muted, fontSize: 12, fontWeight: FontWeight.w600),
      side: BorderSide(color: selected ? _cyan.withOpacity(.6) : Colors.white12),
    );
  }

  Widget _emptyState(String title, String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
      child: Column(
        children: [
          Icon(icon, color: _muted, size: 34),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, height: 1.45, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _entryCard(Map<String, dynamic> entry) {
    final success = _isSuccess(entry);
    final traceId = entry['requestId']?.toString();
    final status = entry['statusCode']?.toString() ?? '—';
    final duration = entry['durationMs']?.toString() ?? '—';
    final endpoint = entry['endpoint']?.toString() ?? 'API';
    final errorType = entry['errorType']?.toString();
    final color = success ? _green : _orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.32)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
          leading: Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 20,
          ),
          title: Text(
            endpoint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              'HTTP $status  •  $duration ms  •  ${_formatTime(entry['timestamp'])}',
              maxLines: 2,
              style: const TextStyle(color: _muted, fontSize: 10, height: 1.35),
            ),
          ),
          trailing: Text(
            success ? 'SUCCESS' : 'FAILED',
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          children: [
            const Divider(color: Colors.white12, height: 12),
            _detailRow('Outcome', success ? 'Successful response' : 'Failed attempt'),
            _detailRow('HTTP status', status),
            _detailRow('Duration', '$duration ms'),
            _detailRow('Timestamp', _formatTime(entry['timestamp'])),
            if (errorType != null && errorType.isNotEmpty)
              _detailRow('Error category', errorType, valueColor: _orange),
            if (traceId != null && traceId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, color: _cyan, size: 17),
                  const SizedBox(width: 7),
                  const Text('Trace ID', style: TextStyle(color: _muted, fontSize: 11)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Copy Trace ID',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copyTrace(traceId),
                    icon: const Icon(Icons.copy_rounded, color: _cyan, size: 18),
                  ),
                ],
              ),
              SelectableText(
                traceId,
                style: const TextStyle(color: _cyan, fontSize: 11, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color valueColor = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text(label, style: const TextStyle(color: _muted, fontSize: 11))),
          Expanded(child: Text(value, style: TextStyle(color: valueColor, fontSize: 11))),
        ],
      ),
    );
  }
}
