import 'package:crypto_market/network/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfig', () {
    test('normalizeBaseUrl trims trailing slash', () {
      expect(
        ApiConfig.normalizeBaseUrl('http://192.168.1.9:8000/'),
        'http://192.168.1.9:8000',
      );
    });

    test('normalizeBaseUrl trims surrounding whitespace', () {
      expect(
        ApiConfig.normalizeBaseUrl('  http://localhost:8000  '),
        'http://localhost:8000',
      );
    });

    test('backendBaseUrls always includes remote fallback', () {
      expect(
        ApiConfig.backendBaseUrls,
        contains(ApiConfig.remoteFallbackUrl),
      );
    });

    test('timeoutForBaseUrl uses longer remote timeout', () {
      expect(
        ApiConfig.timeoutForBaseUrl(ApiConfig.remoteFallbackUrl),
        const Duration(seconds: 20),
      );
      expect(
        ApiConfig.timeoutForBaseUrl('http://localhost:8000'),
        const Duration(seconds: 8),
      );
    });
  });
}
