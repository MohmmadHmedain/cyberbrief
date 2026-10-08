// lib/screens/scan_history_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<ScanHistoryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('scanHistory') ?? [];
    final parsed = rawList
        .map((s) => ScanHistoryItem.fromJson(jsonDecode(s)))
        .toList();
    setState(() {
      _items = parsed;
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scanHistory');
    setState(() {
      _items = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan history cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0F1722);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text('Scan History'),
        centerTitle: true,
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'Clear history',
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No scan history yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final safe = item.isSafe;
                    final color = safe ? Colors.greenAccent : Colors.redAccent;
                    final icon =
                        safe ? Icons.verified_user : Icons.warning_amber_rounded;

                    final subtitle = item.type == 'url'
                        ? (safe
                            ? 'URL is safe • checked by ${item.total} engines'
                            : 'Threats: ${item.threats} / ${item.total} engines')
                        : (safe
                            ? 'Files scan • no known threats'
                            : 'Files scan • threats in ${item.threats} file(s)');

                    final timeStr =
                        '${item.time.year}-${item.time.month.toString().padLeft(2, '0')}-${item.time.day.toString().padLeft(2, '0')} '
                        '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}';

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111C2B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.18),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ScanHistoryItem {
  final String type; // 'url' أو 'files'
  final String title; // الرابط أو وصف فحص الملفات
  final bool isSafe;
  final int threats;
  final int total;
  final DateTime time;

  ScanHistoryItem({
    required this.type,
    required this.title,
    required this.isSafe,
    required this.threats,
    required this.total,
    required this.time,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      type: json['type'] as String? ?? 'url',
      title: json['title'] as String? ?? '',
      isSafe: json['isSafe'] as bool? ?? true,
      threats: json['threats'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      time: DateTime.tryParse(json['time'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
