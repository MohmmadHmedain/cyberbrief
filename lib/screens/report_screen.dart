import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'app_locale.dart';

// ---------- دوال Top-level لاستخدامها مع compute ----------
String sha256OfBytes(Uint8List data) => sha256.convert(data).toString();

Future<String> hashFilePath(String path) async {
  final file = File(path);
  if (!file.existsSync()) return '';
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

enum ScanStatus { idle, scanning, safe, threat }
enum ScanType { quick, full, custom }

class _ReportScreenState extends State<ReportScreen>
    with TickerProviderStateMixin {
  // ---------- URL Scan ----------
  bool isUrlScanning = false;
  int progress = 0;
  String result = "";
  ScanStatus scanStatus = ScanStatus.idle;

  final TextEditingController urlController = TextEditingController();
  List<EngineResult> engineResults = [];
  String urlScanSummary = "";
  int urlScanProgress = 0;
  String _lastScannedUrl = '';

  late AnimationController _meterController;
  late AnimationController _urlMeterController;

  final List<String> securityEngines = [
    'Google Safe Browsing',
    'Kaspersky',
    'Bitdefender',
    'Fortinet',
    'Sophos',
    'ESET',
    'Dr.Web',
    'Webroot',
    'Trend Micro Site Safety',
    'AlienVault OTX',
    'PhishTank',
    'OpenPhish',
    'Abusix',
    'Spam404',
    'StopForum404',
    'Sucuri SiteCheck',
    'Quttera',
    'URLhaus',
    'CINS Army',
    'MalwarePatrol'
  ];

  final Map<String, UrlTestResult> testUrls = {
    'https://www.google.com':
        UrlTestResult(safe: true, threats: 0),
    'https://www.facebook.com':
        UrlTestResult(safe: true, threats: 0),
    'https://malware.testing.google.test/testing/malware/':
        UrlTestResult(safe: false, threats: 18),
    'http://testsafebrowsing.appspot.com/s/phishing.html':
        UrlTestResult(safe: false, threats: 15),
    'https://www.wikipedia.org':
        UrlTestResult(safe: true, threats: 0),
    'http://malware.wicar.org/data/java_jre17_exec.html':
        UrlTestResult(safe: false, threats: 12),
  };

  // ---------- Palette ----------
  static const Color bg = Color(0xFF0F1722);
  static const Color card = Color(0xFF111C2B);
  static const Color mute = Color(0xFF8FA0B6);
  static const Color accent = Color(0xFF00CFFF);
  static const Color okGreen = Color(0xFF18E07F);

  // ---------- File Threat Scan ----------
  bool isFileScanning = false;
  double fileProgress = 0.0;

  ScanType fileScanType = ScanType.quick;
  int filesScannedCount = 0;
  int threatsFoundCount = 0;
  int totalFilesCount = 0;
  Timer? _fileTimer;
  List<PlatformFile> customFiles = [];

  // نتائج الفحص لتفاصيل View Details
  final List<FileScanItem> _fileScanItems = [];
  DateTime? _lastFileScanAt;

  // قاعدة توقيعات بسيطة (SHA-256)
  final Set<String> badHashes = {
    // مثال:
    // 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
  };

  final Set<String> _imgExt = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic'
  };

  final Set<String> _vidExt = {
    '.mp4',
    '.mkv',
    '.mov',
    '.avi',
    '.webm'
  };

  final Set<String> _audExt = {
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.flac',
    '.ogg'
  };

  bool get _isArabic =>
      localeNotifier.value.languageCode == 'ar';

  TextDirection get _textDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  String _t(String ar, String en) =>
      _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();

    _meterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0,
      upperBound: 1,
    );

    _urlMeterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _meterController.dispose();
    _urlMeterController.dispose();
    urlController.dispose();
    _fileTimer?.cancel();
    super.dispose();
  }

  // ================== Save Scan History ==================

  Future<bool> _isHistoryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('saveScanHistory') ?? true;
  }

  Future<void> _saveUrlScanRecord({
    required String url,
    required bool isSafe,
    required int threats,
    required int totalEngines,
  }) async {
    if (!await _isHistoryEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList =
        prefs.getStringList('scanHistory') ?? [];

    final record = {
      'type': 'url',
      'title': url,
      'isSafe': isSafe,
      'threats': threats,
      'total': totalEngines,
      'time': DateTime.now().toIso8601String(),
    };

    rawList.insert(0, jsonEncode(record));

    if (rawList.length > 100) {
      rawList.removeRange(100, rawList.length);
    }

    await prefs.setStringList('scanHistory', rawList);
  }

  Future<void> _saveFileScanRecord({
    required int totalFiles,
    required int threats,
  }) async {
    if (!await _isHistoryEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList =
        prefs.getStringList('scanHistory') ?? [];

    final record = {
      'type': 'files',
      'title': 'Files scan',
      'isSafe': threats == 0,
      'threats': threats,
      'total': totalFiles,
      'time': DateTime.now().toIso8601String(),
    };

    rawList.insert(0, jsonEncode(record));

    if (rawList.length > 100) {
      rawList.removeRange(100, rawList.length);
    }

    await prefs.setStringList('scanHistory', rawList);
  }

  // ---------------- URL Scan ----------------

  Future<void> scanURL() async {
    final url = urlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'الرجاء إدخال رابط صحيح',
              'Please enter a valid URL',
            ),
          ),
        ),
      );
      return;
    }

    final parsedUri = Uri.tryParse(url);

    if (parsedUri == null ||
        !parsedUri.hasAbsolutePath ||
        (!url.startsWith('http://') &&
            !url.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'الرجاء إدخال رابط يبدأ بـ http:// أو https://',
              'Please enter a valid URL starting with http:// or https://',
            ),
          ),
        ),
      );
      return;
    }

    _lastScannedUrl = url;

    setState(() {
      isUrlScanning = true;
      engineResults.clear();
      urlScanSummary = "";
      urlScanProgress = 0;
    });

    _urlMeterController.repeat();

    try {
      final scanId = await submitUrlToVirusTotal(url);

      if (scanId == null) {
        throw Exception('Failed to submit URL');
      }

      for (int i = 0; i < 100; i += 5) {
        if (!mounted) return;

        setState(() {
          urlScanProgress = i;
        });

        await Future.delayed(
          const Duration(milliseconds: 150),
        );
      }

      final results =
          await getVirusTotalResults(scanId);

      if (results == null) {
        throw Exception('No results');
      }

      await processVirusTotalResults(results);
    } catch (_) {
      await _useFallbackResults(url);
    } finally {
      if (mounted) {
        setState(() {
          isUrlScanning = false;
          urlScanProgress = 100;
          _urlMeterController.stop();
        });
      }
    }
  }

  // ==========================================================
  // URL SCAN BACKEND
  // Flutter -> FastAPI -> VirusTotal
  // ==========================================================

  Future<String?> submitUrlToVirusTotal(String url) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              'http://10.0.2.2:8000/scan-url',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'url': url,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['scan_id'];
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVirusTotalResults(
    String scanId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'http://10.0.2.2:8000/scan-url/$scanId',
            ),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================

  Future<void> processVirusTotalResults(
    Map<String, dynamic> results,
  ) async {
    final scans =
        results['scans'] as Map<String, dynamic>? ?? {};

    final positives =
        results['positives'] as int? ?? 0;

    final total =
        results['total'] as int? ??
            (scans.isEmpty ? 1 : scans.length);

    final List<EngineResult> list = [];

    scans.forEach((engine, val) {
      final isDetected =
          val['detected'] == true;

      list.add(
        EngineResult(
          name: engine,
          isThreat: isDetected,
        ),
      );
    });

    setState(() {
      engineResults = list;

      if (positives == 0) {
        urlScanSummary = _t(
          '✅ الرابط آمن - لم يتم اكتشاف تهديدات ($total محركات)',
          '✅ URL is safe - no threats detected ($total engines)',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                '✅ الرابط آمن',
                '✅ URL is safe',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        urlScanSummary = _t(
          '⚠️ تم اكتشاف تهديدات بواسطة $positives من $total محركات',
          '⚠️ Threats detected by $positives of $total engines',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                '⚠️ الرابط يحتوي على تهديدات',
                '⚠️ URL contains threats',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    await _saveUrlScanRecord(
      url: _lastScannedUrl,
      isSafe: positives == 0,
      threats: positives,
      totalEngines: total,
    );
  }

  Future<void> _useFallbackResults(String url) async {
    UrlTestResult scanResult;

    if (testUrls.containsKey(url)) {
      scanResult = testUrls[url]!;
    } else {
      final isSafe = Random().nextDouble() > 0.3;

      scanResult = UrlTestResult(
        safe: isSafe,
        threats: isSafe
            ? 0
            : Random().nextInt(15) + 1,
      );
    }

    final List<EngineResult> results = [];

    for (final engine in securityEngines) {
      final isThreat =
          !scanResult.safe &&
          Random().nextDouble() <
              (scanResult.threats / 20);

      results.add(
        EngineResult(
          name: engine,
          isThreat: isThreat,
        ),
      );
    }

    setState(() {
      engineResults = results;

      if (scanResult.safe) {
        urlScanSummary = _t(
          '✅ الرابط آمن (نتائج تجريبية)',
          '✅ URL is safe (simulated results)',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                '✅ الرابط آمن (نتائج تجريبية)',
                '✅ URL is safe (simulated results)',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        urlScanSummary = _t(
          '⚠️ تم اكتشاف تهديدات بواسطة ${scanResult.threats} محركات (نتائج تجريبية)',
          '⚠️ Threats detected by ${scanResult.threats} engines (simulated results)',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                '⚠️ الرابط يحتوي على تهديدات (نتائج تجريبية)',
                '⚠️ URL contains threats (simulated results)',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    await _saveUrlScanRecord(
      url: url,
      isSafe: scanResult.safe,
      threats: scanResult.threats,
      totalEngines: securityEngines.length,
    );
  }

  // ---------------- أذونات الوسائط ----------------

  Future<bool> _ensureMediaPerms() async {
    final req = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
      Permission.storage,
    ].request();

    final granted =
        req.values.any((s) => s.isGranted);

    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'يرجى منح صلاحية الوصول للملفات للمتابعة',
              'Please grant storage access permission to continue',
            ),
          ),
        ),
      );
    }

    return granted;
  }

  // ======= أدوات الوصول التلقائي للمجلدات العامة =======

  String? _externalBase() {
    final candidates = <String>[
      '/storage/emulated/0',
      '/sdcard',
      '/storage/self/primary',
    ];

    for (final p in candidates) {
      final d = Directory(p);

      if (d.existsSync()) {
        return d.path;
      }
    }

    return null;
  }

  Directory _dirIfExists(String path) =>
      Directory(path);

  List<File> _gatherFlatFiles(
    List<Directory> dirs, {
    int maxCount = 150,
    Set<String>? allowedExts,
  }) {
    final files = <File>[];

    for (final d in dirs) {
      try {
        if (!d.existsSync()) continue;

        for (final e in d.listSync(
          followLinks: false,
        )) {
          if (e is File) {
            if (allowedExts != null) {
              final ext =
                  e.path.toLowerCase();

              if (!allowedExts.any(
                (x) => ext.endsWith(x),
              )) {
                continue;
              }
            }

            files.add(e);

            if (files.length >= maxCount) {
              return files;
            }
          }
        }
      } catch (_) {}
    }

    return files;
  }

  List<File> _gatherRecursiveFiles(
    List<Directory> dirs, {
    int maxCount = 2000,
  }) {
    final files = <File>[];

    for (final d in dirs) {
      try {
        if (!d.existsSync()) continue;

        final it = d.listSync(
          recursive: true,
          followLinks: false,
        );

        for (final e in it) {
          if (e is File) {
            files.add(e);

            if (files.length >= maxCount) {
              return files;
            }
          }
        }
      } catch (_) {}
    }

    return files;
  }

  Future<List<Uri>> _autoQuickSample() async {
    final base = _externalBase();

    if (base == null) return [];

    final dirs = <Directory>[
      _dirIfExists('$base/DCIM'),
      _dirIfExists('$base/Pictures'),
      _dirIfExists('$base/Movies'),
      _dirIfExists('$base/Music'),
      _dirIfExists(
        '$base/WhatsApp/Media/WhatsApp Images',
      ),
    ];

    final files = _gatherFlatFiles(
      dirs,
      maxCount: 150,
      allowedExts: {
        ..._imgExt,
        ..._vidExt,
        ..._audExt,
      },
    );

    return files
        .map((f) => Uri.file(f.path))
        .toList();
  }

  Future<List<Uri>> _autoFullScan() async {
    final base = _externalBase();

    if (base == null) return [];

    final dirs = <Directory>[
      _dirIfExists('$base/Download'),
      _dirIfExists('$base/Documents'),
      _dirIfExists('$base/DCIM'),
      _dirIfExists('$base/Pictures'),
      _dirIfExists('$base/Movies'),
      _dirIfExists('$base/Music'),
      _dirIfExists('$base/WhatsApp/Media'),
    ];

    final files = _gatherRecursiveFiles(
      dirs,
      maxCount: 2000,
    );

    return files
        .map((f) => Uri.file(f.path))
        .toList();
  }

  Future<void> _pickAnyFiles() async {
    final result =
        await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        customFiles = result.files;
      });
    }
  }

  Future<void> _pickImages() async {
    final result =
        await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        customFiles = result.files;
      });
    }
  }

  Future<String?> _hashUri(Uri uri) async {
    try {
      final path = uri.toFilePath();

      if (!File(path).existsSync()) {
        return null;
      }

      final hash =
          await compute(hashFilePath, path);

      return hash.isEmpty ? null : hash;
    } catch (_) {
      return null;
    }
  }

  bool _isBad(String? hash) =>
      hash != null && badHashes.contains(hash);

  String _basename(String path) {
    final p = path.replaceAll('\\', '/');
    final idx = p.lastIndexOf('/');

    return idx >= 0
        ? p.substring(idx + 1)
        : p;
  }

  Future<void> _scanUris(List<Uri> uris) async {
    _fileScanItems.clear();
    _lastFileScanAt = DateTime.now();

    setState(() {
      isFileScanning = true;
      threatsFoundCount = 0;
      filesScannedCount = 0;
      totalFilesCount = uris.length;
      fileProgress = 0;
    });

    for (final u in uris) {
      if (!mounted) break;

      final path = u.toFilePath();
      final h = await _hashUri(u);
      final bad = _isBad(h);

      _fileScanItems.add(
        FileScanItem(
          name: _basename(path),
          path: path,
          hash: h ?? '',
          isThreat: bad,
        ),
      );

      if (bad) threatsFoundCount++;

      filesScannedCount++;

      fileProgress =
          filesScannedCount /
              (totalFilesCount == 0
                  ? 1
                  : totalFilesCount);

      if (filesScannedCount % 10 == 0) {
        setState(() {});
      }
    }

    setState(() {
      isFileScanning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          threatsFoundCount == 0
              ? _t(
                  '✅ لم يتم العثور على تهديدات معروفة',
                  '✅ No known threats',
                )
              : _t(
                  '⚠️ تم العثور على $threatsFoundCount ملف يطابق توقيعات تهديد معروفة',
                  '⚠️ Found $threatsFoundCount file(s) matching known signatures',
                ),
        ),
        backgroundColor: threatsFoundCount == 0
            ? Colors.green
            : Colors.red,
      ),
    );

    await _saveFileScanRecord(
      totalFiles: totalFilesCount,
      threats: threatsFoundCount,
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _resetFileScan() {
    _fileTimer?.cancel();

    setState(() {
      isFileScanning = false;
      fileProgress = 0.0;
      filesScannedCount = 0;
      threatsFoundCount = 0;
      totalFilesCount = 0;
      customFiles = [];
      _fileScanItems.clear();
      _lastFileScanAt = null;
    });
  }

  Future<void> startFileScan() async {
    final ok = await _ensureMediaPerms();

    if (!ok) return;

    List<Uri> targets = [];

    switch (fileScanType) {
      case ScanType.quick:
        targets = await _autoQuickSample();
        break;

      case ScanType.full:
        targets = await _autoFullScan();
        break;

      case ScanType.custom:
        if (customFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _t(
                  'اختر ملفات أو صور للفحص المخصص',
                  'Select files or images for custom scan',
                ),
              ),
            ),
          );

          return;
        }

        targets = customFiles
            .where((f) => f.path != null)
            .map(
              (f) => Uri.file(f.path!),
            )
            .toList();

        break;
    }

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'لا توجد ملفات للفحص، قد تكون قيود النظام تمنع الوصول.',
              'No files to scan (system restrictions may block access).',
            ),
          ),
        ),
      );

      return;
    }

    await _scanUris(targets);
  }

  // ==========================================================
  // View Details BottomSheet
  // ==========================================================

  void _showFileScanDetails() {
    final total = _fileScanItems.length;

    final threats =
        _fileScanItems
            .where((e) => e.isThreat)
            .length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Directionality(
          textDirection: _textDirection,
          child: DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, scroll) {
              return ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12,
                    sigmaY: 12,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: card.withOpacity(0.92),
                      borderRadius:
                          const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      border: Border.all(
                        color: Colors.white
                            .withOpacity(.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(.18),
                            borderRadius:
                                BorderRadius.circular(
                              999,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.list_alt_rounded,
                                color: accent,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  _t(
                                    'تفاصيل الفحص',
                                    'Scan Details',
                                  ),
                                  style:
                                      const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: (threats == 0
                                          ? okGreen
                                          : Colors.redAccent)
                                      .withOpacity(.15),
                                  borderRadius:
                                      BorderRadius.circular(
                                    999,
                                  ),
                                  border: Border.all(
                                    color: (threats == 0
                                            ? okGreen
                                            : Colors.redAccent)
                                        .withOpacity(.55),
                                  ),
                                ),
                                child: Text(
                                  threats == 0
                                      ? _t(
                                          'آمن',
                                          'SAFE',
                                        )
                                      : _t(
                                          'تهديدات: $threats',
                                          'THREATS: $threats',
                                        ),
                                  style: TextStyle(
                                    color: threats == 0
                                        ? okGreen
                                        : Colors.redAccent,
                                    fontWeight:
                                        FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            10,
                            16,
                            14,
                          ),
                          child: Row(
                            children: [
                              _miniStat(
                                _t(
                                  'الإجمالي',
                                  'Total',
                                ),
                                "$total",
                              ),

                              const SizedBox(width: 10),

                              _miniStat(
                                _t(
                                  'التهديدات',
                                  'Threats',
                                ),
                                "$threats",
                                color: threats == 0
                                    ? okGreen
                                    : Colors.redAccent,
                              ),

                              const SizedBox(width: 10),

                              _miniStat(
                                _t(
                                  'الوقت',
                                  'Time',
                                ),
                                _lastFileScanAt == null
                                    ? "-"
                                    : "${_lastFileScanAt!.hour.toString().padLeft(2, '0')}:${_lastFileScanAt!.minute.toString().padLeft(2, '0')}",
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: ListView.builder(
                            controller: scroll,
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              20,
                            ),
                            itemCount:
                                _fileScanItems.length,
                            itemBuilder:
                                (context, i) {
                              final item =
                                  _fileScanItems[i];

                              final color =
                                  item.isThreat
                                      ? Colors.redAccent
                                      : okGreen;

                              final hashShort =
                                  item.hash.isEmpty
                                      ? _t(
                                          'البصمة: -',
                                          'hash: -',
                                        )
                                      : _t(
                                          'البصمة: ${item.hash.substring(0, item.hash.length > 14 ? 14 : item.hash.length)}…',
                                          'hash: ${item.hash.substring(0, item.hash.length > 14 ? 14 : item.hash.length)}…',
                                        );

                              return Container(
                                margin:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 6,
                                ),
                                padding:
                                    const EdgeInsets.all(
                                  12,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(.04),
                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),
                                  border: Border.all(
                                    color: Colors.white
                                        .withOpacity(.06),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration:
                                          BoxDecoration(
                                        color: color
                                            .withOpacity(.14),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
                                        border:
                                            Border.all(
                                          color: color
                                              .withOpacity(
                                            .55,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        item.isThreat
                                            ? Icons
                                                .warning_amber_rounded
                                            : Icons
                                                .verified_rounded,
                                        color: color,
                                        size: 18,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            item.name,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.white,
                                              fontWeight:
                                                  FontWeight
                                                      .w800,
                                            ),
                                          ),

                                          const SizedBox(
                                              height: 4),

                                          Text(
                                            hashShort,
                                            style: TextStyle(
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                .70,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),

                                          const SizedBox(
                                              height: 4),

                                          Text(
                                            item.path,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style: TextStyle(
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                .45,
                                              ),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    IconButton(
                                      tooltip: _t(
                                        'نسخ البصمة',
                                        'Copy hash',
                                      ),
                                      onPressed:
                                          item.hash.isEmpty
                                              ? null
                                              : () async {
                                                  await Clipboard
                                                      .setData(
                                                    ClipboardData(
                                                      text: item
                                                          .hash,
                                                    ),
                                                  );

                                                  if (!mounted) {
                                                    return;
                                                  }

                                                  ScaffoldMessenger
                                                      .of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content:
                                                          Text(
                                                        _t(
                                                          'تم نسخ البصمة',
                                                          'Hash copied',
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                      icon: Icon(
                                        Icons.copy_rounded,
                                        color: Colors.white
                                            .withOpacity(
                                          .75,
                                        ),
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _miniStat(
    String label,
    String value, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.04),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(.06),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white
                    .withOpacity(.65),
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight:
                    FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final ringValue = isFileScanning
            ? fileProgress.clamp(0.0, 1.0)
            : (fileProgress == 1.0
                ? 1.0
                : 0.0);

        final ringLabel = isFileScanning
            ? _t(
                'جاري الفحص',
                'Scanning',
              )
            : (fileProgress == 1.0
                ? _t(
                    'تم',
                    'Done',
                  )
                : _t(
                    'جاهز',
                    'Ready',
                  ));

        final urlValue =
            (urlScanProgress / 100)
                .clamp(0.0, 1.0);

        final urlHasThreat =
            urlScanSummary
                .trim()
                .startsWith('⚠️');

        return Directionality(
          textDirection: _textDirection,
          child: Scaffold(
            backgroundColor: bg,
            body: SafeArea(
              child: Container(
                decoration:
                    const BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,
                    colors: [
                      Color(0xFF050B18),
                      Color(0xFF0F1722),
                      Color(0xFF050B18),
                    ],
                  ),
                ),
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .white
                                  .withOpacity(
                                .06,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                              border:
                                  Border.all(
                                color: Colors
                                    .white
                                    .withOpacity(
                                  .08,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons
                                  .security_rounded,
                              color: accent,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  _t(
                                    'مركز الفحص',
                                    'Scan Center',
                                  ),
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),

                                const SizedBox(
                                    height: 2),

                                Text(
                                  _t(
                                    'التهديدات وأمان الروابط',
                                    'Threats & URL Security',
                                  ),
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _pill(
                            text:
                                (isFileScanning ||
                                        isUrlScanning)
                                    ? _t(
                                        'نشط',
                                        'Active',
                                      )
                                    : _t(
                                        'خامل',
                                        'Idle',
                                      ),
                            color:
                                (isFileScanning ||
                                        isUrlScanning)
                                    ? okGreen
                                    : Colors.white
                                        .withOpacity(
                                      .16,
                                    ),
                            textColor:
                                (isFileScanning ||
                                        isUrlScanning)
                                    ? Colors.black
                                    : Colors.white,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ================= FILE SCAN =================

                      _glassCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .shield_moon_outlined,
                                  color: accent,
                                ),

                                const SizedBox(
                                    width: 8),

                                Text(
                                  _t(
                                    'فحص التهديدات',
                                    'Threat Scan',
                                  ),
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: _segChip(
                                    icon: Icons
                                        .flash_on_rounded,
                                    label: _t(
                                      'سريع',
                                      'Quick',
                                    ),
                                    active:
                                        fileScanType ==
                                            ScanType
                                                .quick,
                                    activeColor:
                                        const Color(
                                      0xFF1E90FF,
                                    ),
                                    onTap: isFileScanning
                                        ? null
                                        : () =>
                                            setState(
                                              () =>
                                                  fileScanType =
                                                      ScanType
                                                          .quick,
                                            ),
                                  ),
                                ),

                                const SizedBox(
                                    width: 8),

                                Expanded(
                                  child: _segChip(
                                    icon: Icons
                                        .shield_rounded,
                                    label: _t(
                                      'كامل',
                                      'Full',
                                    ),
                                    active:
                                        fileScanType ==
                                            ScanType
                                                .full,
                                    activeColor:
                                        accent,
                                    onTap: isFileScanning
                                        ? null
                                        : () =>
                                            setState(
                                              () =>
                                                  fileScanType =
                                                      ScanType
                                                          .full,
                                            ),
                                  ),
                                ),

                                const SizedBox(
                                    width: 8),

                                Expanded(
                                  child: _segChip(
                                    icon: Icons
                                        .tune_rounded,
                                    label: _t(
                                      'مخصص',
                                      'Custom',
                                    ),
                                    active:
                                        fileScanType ==
                                            ScanType
                                                .custom,
                                    activeColor:
                                        okGreen,
                                    textColorWhenActive:
                                        Colors.black,
                                    onTap: isFileScanning
                                        ? null
                                        : () =>
                                            setState(
                                              () =>
                                                  fileScanType =
                                                      ScanType
                                                          .custom,
                                            ),
                                  ),
                                ),
                              ],
                            ),

                            if (fileScanType ==
                                ScanType.custom) ...[
                              const SizedBox(
                                  height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        OutlinedButton
                                            .icon(
                                      onPressed:
                                          isFileScanning
                                              ? null
                                              : _pickAnyFiles,
                                      icon:
                                          const Icon(
                                        Icons
                                            .insert_drive_file,
                                        size: 18,
                                      ),
                                      label: Text(
                                        _t(
                                          'اختيار ملف',
                                          'Choose File',
                                        ),
                                      ),
                                      style:
                                          OutlinedButton
                                              .styleFrom(
                                        foregroundColor:
                                            Colors
                                                .white,
                                        side:
                                            BorderSide(
                                          color: Colors
                                              .white
                                              .withOpacity(
                                            .20,
                                          ),
                                        ),
                                        backgroundColor:
                                            Colors
                                                .white
                                                .withOpacity(
                                          .04,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            12,
                                          ),
                                        ),
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 10),

                                  Expanded(
                                    child:
                                        OutlinedButton
                                            .icon(
                                      onPressed:
                                          isFileScanning
                                              ? null
                                              : _pickImages,
                                      icon:
                                          const Icon(
                                        Icons
                                            .image_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        _t(
                                          'اختيار صورة',
                                          'Choose Image',
                                        ),
                                      ),
                                      style:
                                          OutlinedButton
                                              .styleFrom(
                                        foregroundColor:
                                            Colors
                                                .white,
                                        side:
                                            BorderSide(
                                          color: Colors
                                              .white
                                              .withOpacity(
                                            .20,
                                          ),
                                        ),
                                        backgroundColor:
                                            Colors
                                                .white
                                                .withOpacity(
                                          .04,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            12,
                                          ),
                                        ),
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                  height: 10),

                              _pill(
                                text: customFiles
                                        .isEmpty
                                    ? _t(
                                        'لم يتم اختيار ملفات',
                                        'No files selected',
                                      )
                                    : _t(
                                        'تم اختيار: ${customFiles.length}',
                                        'Selected: ${customFiles.length}',
                                      ),
                                color: Colors.white
                                    .withOpacity(
                                  .10,
                                ),
                                textColor:
                                    Colors.white70,
                              ),
                            ],

                            const SizedBox(
                                height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    icon: Icons
                                        .folder_open_rounded,
                                    label: _t(
                                      'تم فحصها',
                                      'Scanned',
                                    ),
                                    value:
                                        '$filesScannedCount',
                                  ),
                                ),

                                const SizedBox(
                                    width: 8),

                                Expanded(
                                  child: _statCard(
                                    icon: Icons
                                        .layers_rounded,
                                    label: _t(
                                      'الإجمالي',
                                      'Total',
                                    ),
                                    value:
                                        '$totalFilesCount',
                                  ),
                                ),

                                const SizedBox(
                                    width: 8),

                                Expanded(
                                  child: _statCard(
                                    icon: Icons
                                        .warning_amber_rounded,
                                    label: _t(
                                      'التهديدات',
                                      'Threats',
                                    ),
                                    value:
                                        '$threatsFoundCount',
                                    valueColor:
                                        threatsFoundCount ==
                                                0
                                            ? okGreen
                                            : Colors
                                                .redAccent,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 16),

                            Center(
                              child: Stack(
                                alignment:
                                    Alignment.center,
                                children: [
                                  _gradientRing(
                                    value:
                                        ringValue,
                                    size: 172,
                                    stroke: 10,
                                  ),

                                  Column(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,
                                    children: [
                                      Text(
                                        ringLabel,
                                        style:
                                            const TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize:
                                              18,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 4),

                                      Text(
                                        isFileScanning
                                            ? '${(ringValue * 100).toInt()}%'
                                            : (fileProgress ==
                                                    1.0
                                                ? _t(
                                                    'اكتمل',
                                                    'Completed',
                                                  )
                                                : _t(
                                                    'اضغط ابدأ',
                                                    'Tap start',
                                                  )),
                                        style:
                                            TextStyle(
                                          color: Colors
                                              .white
                                              .withOpacity(
                                            .70,
                                          ),
                                          fontSize:
                                              12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                                height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                      _primaryButton(
                                    label: isFileScanning
                                        ? _t(
                                            'جاري الفحص...',
                                            'Scanning...',
                                          )
                                        : _t(
                                            'ابدأ الفحص',
                                            'Start Scan',
                                          ),
                                    onTap:
                                        isFileScanning
                                            ? null
                                            : startFileScan,
                                  ),
                                ),

                                const SizedBox(
                                    width: 12),

                                Expanded(
                                  child:
                                      OutlinedButton(
                                    onPressed:
                                        _resetFileScan,
                                    style:
                                        OutlinedButton
                                            .styleFrom(
                                      side:
                                          BorderSide(
                                        color: Colors
                                            .white
                                            .withOpacity(
                                          .22,
                                        ),
                                        width: 1.2,
                                      ),
                                      backgroundColor:
                                          Colors.white
                                              .withOpacity(
                                        .04,
                                      ),
                                      minimumSize:
                                          const Size(
                                        double.infinity,
                                        50,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          12,
                                        ),
                                      ),
                                      foregroundColor:
                                          Colors.white,
                                    ),
                                    child: Text(
                                      _t(
                                        'إعادة ضبط',
                                        'Reset',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (!isFileScanning &&
                                _fileScanItems
                                    .isNotEmpty) ...[
                              const SizedBox(
                                  height: 10),

                              OutlinedButton
                                  .icon(
                                onPressed:
                                    _showFileScanDetails,
                                icon: const Icon(
                                  Icons
                                      .list_alt_rounded,
                                ),
                                label: Text(
                                  _t(
                                    'عرض التفاصيل',
                                    'View Details',
                                  ),
                                ),
                                style:
                                    OutlinedButton
                                        .styleFrom(
                                  foregroundColor:
                                      Colors.white,
                                  side: BorderSide(
                                    color: Colors.white
                                        .withOpacity(
                                      .22,
                                    ),
                                  ),
                                  backgroundColor:
                                      Colors.white
                                          .withOpacity(
                                    .04,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 18),

                      // ================= URL SCANNER =================

                      _glassCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  color: accent,
                                ),

                                const SizedBox(
                                    width: 8),

                                Text(
                                  _t(
                                    'فاحص أمان الروابط',
                                    'URL Security Scanner',
                                  ),
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 12),

                            TextField(
                              controller:
                                  urlController,
                              textDirection:
                                  _textDirection,
                              textAlign: _isArabic
                                  ? TextAlign.right
                                  : TextAlign.left,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                              ),
                              decoration:
                                  InputDecoration(
                                hintText: _t(
                                  'أدخل رابطًا للفحص (مثال: https://example.com)',
                                  'Enter URL to scan (e.g., https://example.com)',
                                ),
                                hintStyle:
                                    const TextStyle(
                                  color:
                                      Colors.white54,
                                ),
                                filled: true,
                                fillColor: Colors
                                    .white
                                    .withOpacity(
                                  0.06,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                  borderSide:
                                      BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted:
                                  (_) => scanURL(),
                            ),

                            const SizedBox(
                                height: 10),

                            SizedBox(
                              width:
                                  double.infinity,
                              child:
                                  ElevatedButton(
                                onPressed:
                                    isUrlScanning
                                        ? null
                                        : scanURL,
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      accent,
                                  foregroundColor:
                                      Colors.black,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child:
                                    isUrlScanning
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .center,
                                            children: [
                                              const SizedBox(
                                                width:
                                                    18,
                                                height:
                                                    18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth:
                                                      2,
                                                  color:
                                                      Colors.black,
                                                ),
                                              ),

                                              const SizedBox(
                                                  width:
                                                      10),

                                              Text(
                                                _t(
                                                  'جاري الفحص',
                                                  'Scanning',
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            _t(
                                              'ابدأ الفحص',
                                              'Start Scan',
                                            ),
                                          ),
                              ),
                            ),

                            const SizedBox(
                                height: 10),

                            ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                999,
                              ),
                              child:
                                  LinearProgressIndicator(
                                value:
                                    isUrlScanning
                                        ? urlValue
                                        : 1.0,
                                minHeight: 6,
                                backgroundColor:
                                    Colors.white12,
                                valueColor:
                                    const AlwaysStoppedAnimation<
                                        Color>(
                                  accent,
                                ),
                              ),
                            ),

                            if (urlScanSummary
                                .isNotEmpty) ...[
                              const SizedBox(
                                  height: 12),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .all(12),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      urlHasThreat
                                          ? Colors.red
                                              .withOpacity(
                                              .12,
                                            )
                                          : Colors.green
                                              .withOpacity(
                                              .12,
                                            ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                  border:
                                      Border.all(
                                    color:
                                        urlHasThreat
                                            ? Colors
                                                .redAccent
                                            : okGreen,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      urlHasThreat
                                          ? Icons
                                              .report_gmailerrorred_rounded
                                          : Icons
                                              .verified_rounded,
                                      color:
                                          urlHasThreat
                                              ? Colors
                                                  .redAccent
                                              : okGreen,
                                    ),

                                    const SizedBox(
                                        width: 8),

                                    Expanded(
                                      child: Text(
                                        urlScanSummary,
                                        style:
                                            const TextStyle(
                                          color: Colors
                                              .white,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= Helpers UI =================

  Widget _glassCard({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration:
              BoxDecoration(
            color: card.withOpacity(0.72),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white
                  .withOpacity(.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(.25),
                blurRadius: 18,
                spreadRadius: 2,
                offset:
                    const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _pill({
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Widget _segChip({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback? onTap,
    Color textColorWhenActive =
        Colors.white,
  }) {
    final chipColor =
        active
            ? textColorWhenActive
            : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 220,
        ),
        height: 44,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? activeColor
              : Colors.white
                  .withOpacity(0.06),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? activeColor
                : Colors.white
                    .withOpacity(.16),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: chipColor,
            ),

            const SizedBox(width: 4),

            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: chipColor,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF0E1622,
        ).withOpacity(0.9),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white
              .withOpacity(.06),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: Colors.white70,
              ),

              const SizedBox(width: 4),

              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  softWrap: false,
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              color:
                  valueColor ??
                      Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(
            0xFF00FF84,
          ),
          foregroundColor:
              Colors.black,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
        child: Text(
          label,
          style:
              const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _gradientRing({
    required double value,
    double size = 170,
    double stroke = 10,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: ShaderMask(
        blendMode:
            BlendMode.srcIn,
        shaderCallback: (rect) {
          return SweepGradient(
            startAngle: -pi / 2,
            endAngle:
                3 * pi / 2,
            colors: const [
              accent,
              okGreen,
              accent
            ],
            stops: const [
              0.0,
              0.65,
              1.0
            ],
          ).createShader(rect);
        },
        child:
            CircularProgressIndicator(
          value: value,
          strokeWidth: stroke,
          backgroundColor:
              Colors.white
                  .withOpacity(0.10),
          valueColor:
              const AlwaysStoppedAnimation<
                  Color>(
            Colors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------- Models ----------------

class UrlTestResult {
  final bool safe;
  final int threats;

  UrlTestResult({
    required this.safe,
    required this.threats,
  });
}

class EngineResult {
  final String name;
  final bool isThreat;

  EngineResult({
    required this.name,
    required this.isThreat,
  });
}

// عنصر تفاصيل فحص الملفات
class FileScanItem {
  final String name;
  final String path;
  final String hash;
  final bool isThreat;

  FileScanItem({
    required this.name,
    required this.path,
    required this.hash,
    required this.isThreat,
  });
}