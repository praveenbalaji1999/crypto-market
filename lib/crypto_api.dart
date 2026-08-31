import 'dart:convert';

import 'package:crypto_market/models/coin.dart';
import 'package:crypto_market/models/trending_coin.dart';
import 'package:crypto_market/network/network.dart';
import 'package:http/http.dart' as http;

class CryptoApi {
  CryptoApi({ApiClient? apiClient, http.Client? httpClient})
    : _apiClient = apiClient ?? ApiClient(),
      _httpClient = httpClient ?? http.Client();

  final ApiClient _apiClient;
  final http.Client _httpClient;

  // ─────────────────────────────────────────────
  // GET COINS (top 100 by market cap)
  // ─────────────────────────────────────────────

  Future<List<Coin>> getCoins({required int limit, required int offset}) async {
    try {
      return _parseCoins(await _apiClient.getData('/api/coins'));
    } catch (_) {
      final response = await _httpClient
          .get(
            Uri.https('api.coingecko.com', '/api/v3/coins/markets', {
              'vs_currency': 'usd',
              'order': 'market_cap_desc',
              'per_page': '100',
              'page': '1',
              'sparkline': 'true',
              'price_change_percentage': '7d,30d',
            }),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception('CoinGecko returned ${response.statusCode}');
      }
      return _parseCoins(jsonDecode(response.body));
    }
  }

  // ─────────────────────────────────────────────
  // GET COIN DETAILS
  // ─────────────────────────────────────────────

  Future<Coin> getCoinDetails(String coinId) async {
    final data = await _apiClient.getData('/api/coin/$coinId');
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid coin details');
    }

    final marketData = data['market_data'];
    if (marketData is! Map<String, dynamic>) {
      throw const FormatException('Coin details did not include market data');
    }

    Map<String, dynamic> usdValue(String key) {
      final value = marketData[key];
      return value is Map<String, dynamic> ? value : const {};
    }

    final image = data['image'];
    final sparkline = marketData['sparkline_7d'];
    return Coin.fromJson({
      'id': data['id'],
      'symbol': data['symbol'],
      'name': data['name'],
      'image': image is Map<String, dynamic> ? image['large'] : '',
      'current_price': usdValue('current_price')['usd'],
      'market_cap': usdValue('market_cap')['usd'],
      'market_cap_rank': data['market_cap_rank'],
      'total_volume': usdValue('total_volume')['usd'],
      'high_24h': usdValue('high_24h')['usd'],
      'low_24h': usdValue('low_24h')['usd'],
      'price_change_24h': marketData['price_change_24h'],
      'price_change_percentage_24h': marketData['price_change_percentage_24h'],
      'circulating_supply': marketData['circulating_supply'],
      'total_supply': marketData['total_supply'],
      'max_supply': marketData['max_supply'],
      'sparkline_in_7d': sparkline,
      'ath': usdValue('ath')['usd'],
      'atl': usdValue('atl')['usd'],
      'price_change_percentage_7d_in_currency':
          marketData['price_change_percentage_7d'],
      'price_change_percentage_30d_in_currency':
          marketData['price_change_percentage_30d'],
    });
  }

  // ─────────────────────────────────────────────
  // GET CHART PRICES
  // ─────────────────────────────────────────────

  Future<List<double>> getChartPrices(String coinId, {int days = 7}) async {
    final data = await _apiClient.getData('/api/chart/$coinId?days=$days');
    if (data is! Map<String, dynamic> || data['prices'] is! List) {
      throw const FormatException('Invalid chart data');
    }

    return (data['prices'] as List)
        .whereType<List>()
        .where((point) => point.length > 1 && point[1] is num)
        .map((point) => (point[1] as num).toDouble())
        .toList(growable: false);
  }

  // ─────────────────────────────────────────────
  // GET GLOBAL MARKET DATA
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getGlobalMarketData() async {
    final data = await _apiClient.getData('/api/global');
    if (data is! Map<String, dynamic> ||
        data['data'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid global market data');
    }
    return data['data'] as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────
  // GET TRENDING COINS
  // ─────────────────────────────────────────────

  Future<List<TrendingCoin>> getTrending() async {
    try {
      final data = await _apiClient.getData('/api/trending');
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid trending data');
      }
      final coins = data['coins'] as List? ?? [];
      return coins
          .whereType<Map<String, dynamic>>()
          .map(TrendingCoin.fromJson)
          .toList(growable: false);
    } catch (_) {
      // Fallback: direct CoinGecko call
      final response = await _httpClient
          .get(
            Uri.https('api.coingecko.com', '/api/v3/search/trending'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final coins = data['coins'] as List? ?? [];
      return coins
          .whereType<Map<String, dynamic>>()
          .map(TrendingCoin.fromJson)
          .toList(growable: false);
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  List<Coin> _parseCoins(dynamic data) {
    if (data is! List) throw const FormatException('Invalid crypto data');
    return data
        .whereType<Map<String, dynamic>>()
        .map(Coin.fromJson)
        .toList(growable: false);
  }
}
