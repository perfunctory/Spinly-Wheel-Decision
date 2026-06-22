以下是一套完整的、推荐在生产环境中使用的 Flutter 加密工具类
1. 添加依赖（pubspec.yaml）
YAMLdependencies:
  encrypt: ^5.0.3
  flutter_secure_storage: ^9.2.2
  crypto: ^3.0.3        # 用于生成随机密钥
运行 flutter pub get

2. 完整的加密工具类 encryption_service.dart
Dartimport 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const String _storageKey = 'aes_encryption_key';
  static const String _storageIV = 'aes_encryption_iv';

  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  bool _isInitialized = false;

  /// 初始化加密服务（必须在 main.dart 中 await 调用）
  Future<void> init() async {
    if (_isInitialized) return;

    final storage = const FlutterSecureStorage();

    // 尝试读取已保存的密钥
    String? keyBase64 = await storage.read(key: _storageKey);
    String? ivBase64 = await storage.read(key: _storageIV);

    if (keyBase64 == null || ivBase64 == null) {
      // 首次使用，生成随机密钥和IV
      keyBase64 = _generateRandomBase64(32); // 256位密钥
      ivBase64 = _generateRandomBase64(16);  // 128位IV

      await storage.write(key: _storageKey, value: keyBase64);
      await storage.write(key: _storageIV, value: ivBase64);
    }

    _key = encrypt.Key.fromBase64(keyBase64);
    _iv = encrypt.IV.fromBase64(ivBase64);

    _encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc, padding: 'PKCS7')
    );

    _isInitialized = true;
  }

  String _generateRandomBase64(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// 加密字符串
  String encrypt(String plainText) {
    if (!_isInitialized) throw Exception("EncryptionService 未初始化，请先调用 init()");
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// 解密字符串
  String decrypt(String encryptedBase64) {
    if (!_isInitialized) throw Exception("EncryptionService 未初始化，请先调用 init()");
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      return "【解密失败】";
    }
  }

  // ====================== 自动解密的敏感字符串常量 ======================

  String get apiBaseUrl => decrypt(
      "在这里粘贴你加密后的baseUrl字符串"
    );

  String get apiKey => decrypt(
      "在这里粘贴你加密后的apiKey字符串"
    );

  String get secretToken => decrypt(
      "在这里粘贴你加密后的token字符串"
    );

  String get websocketUrl => decrypt(
      "在这里粘贴你加密后的websocketUrl字符串"
    );

  // 可继续添加更多...
}

// ====================== 使用示例 ======================

3. 在 main.dart 中初始化
DartFuture<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化加密服务
  await EncryptionService().init();

  runApp(const MyApp());
}

4. 使用方式（非常简洁）
Dart// 任何地方直接使用，自动解密
final String baseUrl = EncryptionService().apiBaseUrl;
final String key = EncryptionService().apiKey;

// 临时加密某个字符串（开发时使用）
String encrypted = EncryptionService().encrypt("sk_live_xxxxxxxx");
print(encrypted);   // 把这个输出复制到上面的常量中

5. 如何生成加密字符串（开发工具）
在开发阶段，你可以临时这样生成加密字符串：
DartFuture<void> generateEncryptedStrings() async {
  await EncryptionService().init();

  print("加密后 BaseUrl: ${EncryptionService().encrypt("https://api.example.com")}");
  print("加密后 ApiKey: ${EncryptionService().encrypt("sk_live_1234567890abcdef")}");
}

安全特性总结：

密钥使用 flutter_secure_storage 安全存储（Android Keystore + iOS Keychain）
首次启动自动生成随机强密钥
AES-256-CBC + PKCS7 填充
单例模式 + 初始化检查
代码混淆后更难被逆向