class TrendingCoin {
  final String id;
  final String name;
  final String symbol;
  final String image;
  final int marketCapRank;
  final double? priceChangePercentage24h;
  final double? currentPrice;

  const TrendingCoin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.image,
    required this.marketCapRank,
    this.priceChangePercentage24h,
    this.currentPrice,
  });

  factory TrendingCoin.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>? ?? json;
    final data = item['data'] as Map<String, dynamic>?;
    final priceChangeMap =
        data?['price_change_percentage_24h'] as Map<String, dynamic>?;

    // Price may be a string like "$0.00034" from trending endpoint
    double? parsePrice(dynamic raw) {
      if (raw == null) return null;
      if (raw is num) return raw.toDouble();
      final s = raw.toString().replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(s);
    }

    return TrendingCoin(
      id: (item['id'] as String?) ?? '',
      name: (item['name'] as String?) ?? '',
      symbol: (item['symbol'] as String?) ?? '',
      image: (item['small'] as String?) ??
          (item['thumb'] as String?) ??
          '',
      marketCapRank: (item['market_cap_rank'] as num?)?.toInt() ?? 0,
      priceChangePercentage24h: (priceChangeMap?['usd'] as num?)?.toDouble(),
      currentPrice: parsePrice(data?['price']),
    );
  }
}
