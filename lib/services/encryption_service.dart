import 'dart:convert';
import 'package:encrypt/encrypt.dart' as e;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const String _storageKey = 'aes_encryption_key';
  static const String _storageIV = 'aes_encryption_iv';

  // Deterministic seeds — same key across all installs so the
  // hardcoded encrypted constants always decrypt correctly.
  static const String _keySeed = 'SpinlyWheel2024!AES256Key';
  static const String _ivSeed = 'SpinlyWheel2024!IV16';

  late final e.Key _key;
  late final e.IV _iv;
  late final e.Encrypter _encrypter;

  bool _isInitialized = false;

  /// Initialize the encryption service. Must be awaited in main().
  Future<void> init() async {
    if (_isInitialized) return;

    final storage = const FlutterSecureStorage();

    // Try to read previously saved key
    String? keyBase64 = await storage.read(key: _storageKey);
    String? ivBase64 = await storage.read(key: _storageIV);

    if (keyBase64 == null || ivBase64 == null) {
      // First launch — derive deterministic key from seeds
      final keyBytes = sha256.convert(utf8.encode(_keySeed)).bytes;
      final ivBytes = _md5Bytes(_ivSeed);

      keyBase64 = base64Url.encode(keyBytes);
      ivBase64 = base64Url.encode(ivBytes);

      await storage.write(key: _storageKey, value: keyBase64);
      await storage.write(key: _storageIV, value: ivBase64);
    }

    _key = e.Key.fromBase64(keyBase64);
    _iv = e.IV.fromBase64(ivBase64);

    _encrypter = e.Encrypter(
      e.AES(_key, mode: e.AESMode.cbc, padding: 'PKCS7'),
    );

    _isInitialized = true;
  }

  List<int> _md5Bytes(String input) {
    final digest = md5.convert(utf8.encode(input));
    return digest.bytes; // 16 bytes
  }

  /// Decrypt a base64-encoded ciphertext.
  String decrypt(String encryptedBase64) {
    if (!_isInitialized) {
      throw Exception('EncryptionService not initialized — call init() first');
    }
    try {
      final encrypted = e.Encrypted.fromBase64(encryptedBase64);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      return ''; // graceful fallback — won't crash the app
    }
  }

  /// Encrypt a plaintext string (for dev-time generation only).
  String encrypt(String plainText) {
    if (!_isInitialized) {
      throw Exception('EncryptionService not initialized — call init() first');
    }
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  // ── WebView / sensitive constants ────────────────────────────────

  // Adjust event-token map (JSON)
  static const String _encryptedTokens =
      '+mqgH/KBMsxRmCb4p8OBPdjaDjLZMHC8C9L8km/0w9h21PGojYYR7pHAiPSyOpcS'
      '6lJETMcPG/bZZiMCmorpI7v4wgdZPEGPhUULaC3XT0iGF7OZxjy01ymOX8X0vXAz'
      '6Me/8rkXPHW+BHCoWDOvL6x91jD8jpMzeioVnvUM3eWrdkcli3O9SF5ER+ay/J1F';

  String get actionMapping => decrypt(_encryptedTokens);

  // Bridge method/field names (JSON map)
  static const String _encryptedBridgeStrings =
      'bu1N+C0JtOEZNxIUfLJlF5xWqpWGGdAs0lLWbZg5u4IRm1gwTozvvEVLLMsoeAtY'
      'xMJ/67WgC9ooSIxk70+y9ogZLOsIh3+1WEqwR4oqR9taA/C3fWtxBCw4xkWm9v2w'
      'Oh60EDUIYEbGBGmTkYbfrP/UPSqzYBhSHd9QcqG1YEYw/728CRep3BGHiPAa8V81'
      'Y7tvt+Fhs1r+V6JgnxPZNE/sMjsQ1ZzTNXJWn31W5YRQH5Q6j/MZJnHu+C2WsIxG'
      'lKheCnqSuIWPuVyIzcLrN6RTfj8WhlLBqy7hDYPB/5ds6OqZ4+AIbQDqQ/3mI5ms'
      '8ciS1io/yl2a9I9ZXEB1pVPGYj0tC1VuY0UhWshTArDfUcq4k2Xym4XVmg/z6L2p'
      '+KPcMn/gj6DOiQ9GxyqQuo7mwFpZtIwZISWYBiCadsj9XwgHbxuXj87uayJBS3nN'
      '1F7rXLW0wsxDTCLeHsGBHLAEKDT4Pmwmsicr8Rgowd44MBPq/aDa5YUXcwfj1Lds'
      '3UU+RYa4mCMNxWo3/9tieWOuYsa93ynx1hM1O9Vf/X8PlOVFaQ8iDFjDuFxLd0xD'
      'pm2u048COo3cw3TsNyvZBymribZKn6qLJ3D0ZrfHFS/DhJ9bNes/jKlZffRh/SqW'
      'A0D6gAJfQgczEQqX795kjUYsTwTbcu1tyLd0iC0Lcg5eYQGYJQlXRBYibE6h7Jh9'
      'dY4P4PFjMWU4nr2X5z2OLELYiLWRiAFQPv4aJ0wmUGxzG4R4W3nz0ZtT4YJUsOFC'
      'x0jaDxO17fiZG+w3SNG1+n5JrMv1oaii5uTMnZ4+zm8=';

  Map<String, dynamic>? _cachedStrings;

  /// Returns {fields: {...}, methods: {...}, defaultCurrency: "USD"}
  Map<String, dynamic> get bridgeStrings {
    if (_cachedStrings != null) return _cachedStrings!;
    _cachedStrings = jsonDecode(decrypt(_encryptedBridgeStrings)) as Map<String, dynamic>;
    return _cachedStrings!;
  }

  // JavaScript bridge injected into WebView
  static const String _encryptedBridgeJs =
      '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';

  String get injectionPayload => decrypt(_encryptedBridgeJs);

  // Remote config API URL
  static const String _encryptedApiUrl =
      'IFViQMOus2o5rxlUaigEaN2GxneulclltyVACR/ZG2jXhQ5mHd1eZHjsXU47yM6J';

  String get remoteConfigApiUrl => decrypt(_encryptedApiUrl);

  // MD5 signing key for remote config
  static const String _encryptedSignKey =
      'WToRuhBOiInBnaGhX1nkmvZpKDeHs7ceefvGmeD4yJU=';

  String get remoteConfigSignKey => decrypt(_encryptedSignKey);

  // App package / bundle ID
  static const String _encryptedAppId =
      'xuuS/8a8HE/nxIG77P1DFxCTRBzqioZdgru7JKfP2Dg=';

  String get appId => decrypt(_encryptedAppId);

  // About page URL
  static const String _encryptedAboutUrl =
      'sHyDbaC4IDL+3aI7MgyFvNUF40gZywMTiKeKWEBPIBxw+0z0twvsMdvnWm0aq8AZ'
      'JtXxaR1PDlpqgp6qJJGj3w==';

  String get aboutUrl => decrypt(_encryptedAboutUrl);

  // WebView User-Agent
  static const String _encryptedUserAgent =
      'nHtC/GOjVKJDik8ZmLIzUUDQxy1cn72HD9+JS1LRrRFfTGOcXUBsXEK/Np+DdXVo'
      'HjVNDG09q//yO9w5HjNdQ5bBvK6MI9IpKEgTNOYK5xbn84pT1o9GNGs1HD69Utek'
      'SNEZLQ7/lZYiEpddxD39me02XwJAV9mFnei1uq239WUVL6xboqydim1F0sl9e4so';

  String get userAgent => decrypt(_encryptedUserAgent);

  // GCash deep-link strings
  static const String _encryptedGcashScheme = '3DZdnudlUmV8263N3MHtyA==';

  String get gcashScheme => decrypt(_encryptedGcashScheme);

  static const String _encryptedGcashFallback = 'dHBU4mhCoHIcSAqjzVXUbvLJrKBykHqQvBAnuYXgh8Y=';

  String get gcashFallback => decrypt(_encryptedGcashFallback);
}
