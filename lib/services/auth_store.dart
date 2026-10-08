import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// صندوقان:
/// - users: يحتفظ بكل المستخدمين
///   المفتاح = email.toLowerCase()
///   القيمة = {salt, pwdHash, createdAt, updatedAt}
/// - session: معلومات الجلسة الحالية {currentEmail}
class AuthStore {
  static const _usersBox = 'auth_users';
  static const _sessionBox = 'auth_session';
  static const _hiveKeyName = 'hive_key_32';
  final _sec = const FlutterSecureStorage();

  // ====== Bootstrap ======
  Future<void> init() async {
    await Hive.initFlutter();
    // مفتاح تشفير للصناديق
    final keyBytes = await _loadOrCreateHiveKey();
    final cipher = HiveAesCipher(keyBytes);
    await Hive.openBox(_usersBox, encryptionCipher: cipher);
    await Hive.openBox(_sessionBox, encryptionCipher: cipher);
  }

  // ====== إنشاء/إدارة مستخدمين ======
  Future<bool> createUser({
    required String email,
    required String password,
    bool overwriteIfExists = false,
  }) async {
    final users = Hive.box(_usersBox);
    final k = email.trim().toLowerCase();
    if (users.containsKey(k) && !overwriteIfExists) return false;

    final salt = _randomBytes(16);
    final hash = await _pbkdf2(password, salt);
    final now = DateTime.now().toIso8601String();
    await users.put(k, {
      'salt': base64Encode(salt),
      'pwdHash': base64Encode(hash),
      'createdAt': users.containsKey(k)
          ? (users.get(k)['createdAt'] as String? ?? now)
          : now,
      'updatedAt': now,
    });
    return true;
  }

  Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final ok = await verifyLogin(email, oldPassword);
    if (!ok) return false;
    final users = Hive.box(_usersBox);
    final k = email.trim().toLowerCase();
    final salt = _randomBytes(16);
    final hash = await _pbkdf2(newPassword, salt);
    final data = Map<String, dynamic>.from(users.get(k));
    data['salt'] = base64Encode(salt);
    data['pwdHash'] = base64Encode(hash);
    data['updatedAt'] = DateTime.now().toIso8601String();
    await users.put(k, data);
    return true;
  }

  Future<bool> deleteUser(String email) async {
    final users = Hive.box(_usersBox);
    final k = email.trim().toLowerCase();
    if (!users.containsKey(k)) return false;
    await users.delete(k);
    final session = Hive.box(_sessionBox);
    if ((session.get('currentEmail') as String?) == k) {
      await session.delete('currentEmail');
    }
    return true;
  }

  List<String> listUsersEmails() {
    final users = Hive.box(_usersBox);
    return users.keys.cast<String>().toList();
  }

  // ====== تسجيل الدخول والخروج ======
  Future<bool> verifyLogin(String email, String password) async {
    final users = Hive.box(_usersBox);
    final k = email.trim().toLowerCase();
    final data = users.get(k);
    if (data == null) return false;
    final salt = base64Decode(data['salt'] as String);
    final savedHash = base64Decode(data['pwdHash'] as String);
    final hash = await _pbkdf2(password, salt);
    return _constTimeEqual(hash, savedHash);
  }

  Future<bool> signIn(String email, String password) async {
    final ok = await verifyLogin(email, password);
    if (!ok) return false;
    final session = Hive.box(_sessionBox);
    await session.put('currentEmail', email.trim().toLowerCase());
    return true;
    }

  Future<void> signOut() async {
    final session = Hive.box(_sessionBox);
    await session.delete('currentEmail');
  }

  String? get currentUserEmail {
    final session = Hive.box(_sessionBox);
    return session.get('currentEmail') as String?;
  }

  // ====== أدوات داخلية ======
  Future<List<int>> _loadOrCreateHiveKey() async {
    var key = await _sec.read(key: _hiveKeyName);
    if (key != null) return base64Decode(key);
    final bytes =
        List<int>.generate(32, (_) => Random.secure().nextInt(256));
    await _sec.write(key: _hiveKeyName, value: base64Encode(bytes));
    return bytes;
  }

  List<int> _randomBytes(int n) =>
      List<int>.generate(n, (_) => Random.secure().nextInt(256));

  Future<List<int>> _pbkdf2(String password, List<int> salt) async {
    final algo = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000, // زدها إن كان الأداء جيداً
      bits: 256,
    );
    final key = await algo.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  bool _constTimeEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a[i] ^ b[i];
    }
    return r == 0;
  }
}
