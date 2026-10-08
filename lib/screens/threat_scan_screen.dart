import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

enum ScanType { quick, full, custom }

class ThreatScanScreen extends StatefulWidget {
  const ThreatScanScreen({super.key});

  @override
  State<ThreatScanScreen> createState() => _ThreatScanScreenState();
}

class _ThreatScanScreenState extends State<ThreatScanScreen> {
  bool isScanning = false;
  double progress = 0.0;

  // الإضافات الجديدة
  ScanType scanType = ScanType.quick;
  int filesScanned = 0;
  int threatsFound = 0;
  int totalFiles = 0;
  Timer? _timer;
  List<PlatformFile> customFiles = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      isScanning = false;
      progress = 0.0;
      filesScanned = 0;
      threatsFound = 0;
      totalFiles = 0;
      customFiles = [];
    });
  }

  // تحديد عدد الملفات بحسب نوع الفحص
  int _estimateTotalFiles(ScanType type) {
    switch (type) {
      case ScanType.quick:
        return 50; // عينة سريعة
      case ScanType.full:
        return 500; // النظام كاملاً
      case ScanType.custom:
        return customFiles.isEmpty ? 0 : customFiles.length;
    }
  }

  // اختيار ملفات للفحص المخصوص
  Future<void> pickCustomFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        customFiles = result.files;
      });
    }
  }

  void startScan() {
    // في حالة custom يجب أن تكون هناك ملفات
    if (scanType == ScanType.custom && customFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر ملفات للفحص المخصوص')),
      );
      return;
    }

    _timer?.cancel();

    setState(() {
      isScanning = true;
      progress = 0.0;
      filesScanned = 0;
      threatsFound = 0;
      totalFiles = _estimateTotalFiles(scanType);
    });

    if (totalFiles == 0) {
      setState(() => isScanning = false);
      return;
    }

    final rnd = Random();

    // سرعة الفحص لكل نوع
    final perTick = switch (scanType) {
      ScanType.quick => 5, // 5 ملفات كل نبضة
      ScanType.full => 15, // 15 ملف كل نبضة
      ScanType.custom => 10, // 10 ملفات كل نبضة
    };

    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        final remaining = totalFiles - filesScanned;
        final step = remaining >= perTick ? perTick : remaining;
        filesScanned += step;

        // محاكاة اكتشافات: احتمال 2% لكل ملف
        for (int i = 0; i < step; i++) {
          if (rnd.nextDouble() < 0.02) threatsFound++;
        }

        progress = filesScanned / totalFiles;

        if (filesScanned >= totalFiles) {
          isScanning = false;
          timer.cancel();
          progress = 1.0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Threat Scan',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // اختيار نوع الفحص
              Row(
                children: [
                  const Text('نوع الفحص:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<ScanType>(
                      value: scanType,
                      dropdownColor: Colors.grey.shade900,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: ScanType.quick, child: Text('فحص سريع')),
                        DropdownMenuItem(value: ScanType.full, child: Text('فحص كامل')),
                        DropdownMenuItem(value: ScanType.custom, child: Text('فحص مخصوص')),
                      ],
                      onChanged: isScanning
                          ? null
                          : (v) => setState(() {
                                scanType = v ?? ScanType.quick;
                              }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (scanType == ScanType.custom)
                    TextButton(
                      onPressed: isScanning ? null : pickCustomFiles,
                      child: const Text('اختيار ملفات'),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // موجز الملفات والتهديدات
              Row(
                children: const [
                  _StatTile(label: 'المفحوص', value: ''),
                  SizedBox(width: 8),
                  _StatTile(label: 'الإجمالي', value: ''),
                  SizedBox(width: 8),
                  _StatTile(label: 'التهديدات', value: ''),
                ],
              ),

              // القيم داخل صف منفصل لتجنب تمدد مزدوج
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MetricValue(text: filesScanned.toString()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricValue(text: totalFiles.toString()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricValue(text: threatsFound.toString()),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // دائرة الفحص
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: isScanning ? progress : 0,
                          strokeWidth: 10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00CFFF)),
                          backgroundColor: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        isScanning
                            ? '${(progress * 100).toInt()}%'
                            : (progress == 1.0 ? 'Done' : 'Ready'),
                        style: const TextStyle(fontSize: 22, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // أزرار التحكم
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isScanning ? null : startScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF84),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isScanning ? 'Scanning...' : 'Start Scan',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade700, width: 1.5),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('إعادة ضبط'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                scanType == ScanType.custom && customFiles.isNotEmpty
                    ? 'ملفات مختارة: ${customFiles.length}'
                    : 'جهازك محمي بواسطة CyberGuard',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _MetricValue extends StatelessWidget {
  final String text;
  const _MetricValue({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade900),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
