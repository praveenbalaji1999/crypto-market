class Coin {
  final String id;
  final String symbol;
  final String name;
  final String image;

  final double currentPrice;
  final double marketCap;
  final int marketCapRank;
  final double totalVolume;

  final double high24h;
  final double low24h;

  final double priceChange24h;
  final double priceChangePercentage24h;

  final double circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;

  final List<double> sparkline;
  final double? allTimeHigh;
  final double? allTimeLow;
  final double? priceChangePercentage7d;
  final double? priceChangePercentage30d;

  Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.marketCap,
    required this.marketCapRank,
    required this.totalVolume,
    required this.high24h,
    required this.low24h,
    required this.priceChange24h,
    required this.priceChangePercentage24h,
    required this.circulatingSupply,
    required this.totalSupply,
    required this.maxSupply,
    required this.sparkline,
    this.allTimeHigh,
    this.allTimeLow,
    this.priceChangePercentage7d,
    this.priceChangePercentage30d,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',

      currentPrice: (json['current_price'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),

      marketCapRank: json['market_cap_rank'] ?? 0,

      totalVolume: (json['total_volume'] ?? 0).toDouble(),

      high24h: (json['high_24h'] ?? 0).toDouble(),
      low24h: (json['low_24h'] ?? 0).toDouble(),

      priceChange24h: (json['price_change_24h'] ?? 0).toDouble(),

      priceChangePercentage24h: (json['price_change_percentage_24h'] ?? 0)
          .toDouble(),

      circulatingSupply: (json['circulating_supply'] ?? 0).toDouble(),

      totalSupply: json['total_supply']?.toDouble(),

      maxSupply: json['max_supply']?.toDouble(),

      sparkline: List<double>.from(
        (json['sparkline_in_7d']?['price'] ?? []).map(
          (e) => (e as num).toDouble(),
        ),
      ),
      allTimeHigh: json['ath']?.toDouble(),
      allTimeLow: json['atl']?.toDouble(),
      priceChangePercentage7d: json['price_change_percentage_7d_in_currency']
          ?.toDouble(),
      priceChangePercentage30d: json['price_change_percentage_30d_in_currency']
          ?.toDouble(),
    );
  }
}
