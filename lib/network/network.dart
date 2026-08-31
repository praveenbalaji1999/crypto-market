import 'dart:convert';

import 'package:crypto_market/network/api_config.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final List<String> _baseUrls;
  final http.Client _client;

  ApiClient({
    http.Client? client,
    List<String>? baseUrls,
  })  : _client = client ?? http.Client(),
        _baseUrls = baseUrls ?? ApiConfig.backendBaseUrls;

  Future<dynamic> getData(String endpoint) async {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    Object? lastError;

    for (final base in _baseUrls) {
      try {
        final response = await _client
            .get(
              Uri.parse('${ApiConfig.normalizeBaseUrl(base)}$path'),
              headers: const {'Accept': 'application/json'},
            )
            .timeout(ApiConfig.timeoutForBaseUrl(base));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body);
        }

        lastError = Exception(
          'Backend $base returned ${response.statusCode} for $path',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception(
      'All backend endpoints failed for $path'
      '${lastError == null ? '' : ' ($lastError)'}',
    );
  }
}
