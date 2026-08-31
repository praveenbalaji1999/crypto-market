import 'package:flutter/foundation.dart';

/// Resolves backend base URLs for the Flutter app.
///
/// Priority:
/// 1. `API_BASE_URL` dart-define (physical device / custom host)
/// 2. Platform default local dev URL (emulator / desktop)
/// 3. Deployed fallback backend (`API_FALLBACK_URL` or Render default)
class ApiConfig {
  ApiConfig._();

  static const String remoteFallbackUrl = String.fromEnvironment(
    'API_FALLBACK_URL',
    defaultValue: 'https://crypto-backend-hemn.onrender.com',
  );

  static const String _explicitBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Ordered, de-duplicated backend base URLs to try.
  static List<String> get backendBaseUrls {
    final urls = <String>[];

    void add(String? raw) {
      if (raw == null || raw.isEmpty) return;
      final normalized = normalizeBaseUrl(raw);
      if (!urls.contains(normalized)) {
        urls.add(normalized);
      }
    }

    if (_explicitBaseUrl.isNotEmpty) {
      add(_explicitBaseUrl);
    } else {
      add(_platformLocalUrl());
    }

    add(remoteFallbackUrl);

    return urls;
  }

  static String normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String _platformLocalUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator maps host loopback to 10.0.2.2
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 'http://localhost:8000';
      case TargetPlatform.fuchsia:
        return 'http://localhost:8000';
    }
  }

  /// Shorter timeout for local dev; longer for deployed fallback (cold starts).
  static Duration timeoutForBaseUrl(String baseUrl) {
    final normalized = normalizeBaseUrl(baseUrl);
    if (normalized == normalizeBaseUrl(remoteFallbackUrl)) {
      return const Duration(seconds: 20);
    }
    return const Duration(seconds: 8);
  }
}
