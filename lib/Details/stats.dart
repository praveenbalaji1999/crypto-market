import 'package:crypto_market/Bloc/bloc/cryptobloc_bloc.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_event.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_state.dart';
import 'package:crypto_market/Coin%20Details/coindetails.dart';
import 'package:crypto_market/crypto_api.dart';
import 'package:crypto_market/models/coin.dart';
import 'package:crypto_market/widgets/error_state.dart';
import 'package:crypto_market/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MarketStatsPage extends StatefulWidget {
  const MarketStatsPage({super.key});

  @override
  State<MarketStatsPage> createState() => _MarketStatsPageState();
}

class _MarketStatsPageState extends State<MarketStatsPage> {
  late final CryptoApi _api;
  Future<Map<String, dynamic>>? _globalFuture;

  @override
  void initState() {
    super.initState();
    _api = CryptoApi();
    _globalFuture = _api.getGlobalMarketData();
  }

  Future<void> _reload() async {
    setState(() {
      _globalFuture = _api.getGlobalMarketData();
    });
    final bloc = context.read<CryptoBloc>();
    final done = bloc.stream.firstWhere(
      (s) => s is CryptoLoaded || s is CryptoError || s is CryptoEmpty,
    );
    bloc.add(LoadCoins());
    await done;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CryptoBloc, CryptoState>(
          builder: (context, state) {
            if (state is CryptoLoading) {
              return _buildLoadingShimmer();
            }

            if (state is CryptoError) {
              return ErrorStateWidget(
                message: state.message,
                onRetry: () => context.read<CryptoBloc>().add(LoadCoins()),
              );
            }

            if (state is CryptoLoaded || state is TrendingLoaded) {
              final coins = state is CryptoLoaded
                  ? state.coins
                  : (state as TrendingLoaded).coins;

              return FutureBuilder<Map<String, dynamic>>(
                future: _globalFuture,
                builder: (context, snap) {
                  return RefreshIndicator(
                    onRefresh: _reload,
                    color: const Color(0xff8B7CFF),
                    child: _buildContent(coins, snap.data),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
      child: Column(
        children: List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
              width: double.infinity,
              height: 70,
              borderRadius: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    List<Coin> coins,
    Map<String, dynamic>? globalData,
  ) {
    double totalMCap = 0, totalVol = 0;
    Coin? topMCap, topVol, topPrice;

    for (final coin in coins) {
      totalMCap += coin.marketCap;
      totalVol += coin.totalVolume;
      if (topMCap == null || coin.marketCap > topMCap.marketCap) {
        topMCap = coin;
      }
      if (topVol == null || coin.totalVolume > topVol.totalVolume) {
        topVol = coin;
      }
      if (topPrice == null || coin.currentPrice > topPrice.currentPrice) {
        topPrice = coin;
      }
    }

    final gMCap = _usdValue(globalData, 'total_market_cap');
    final gVol = _usdValue(globalData, 'total_volume');
    final activeCryptos = globalData?['active_cryptocurrencies'];
    final markets = globalData?['markets'];
    final mcapChange = globalData?['market_cap_change_percentage_24h_usd'];
    final dominance = globalData?['market_cap_percentage']
        as Map<String, dynamic>?;
    final btcDom = (dominance?['btc'] as num?)?.toDouble();
    final ethDom = (dominance?['eth'] as num?)?.toDouble();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // HEADER
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Stats',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Live crypto market data',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // GLOBAL STATS GRID
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Overview',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _statRow(
                  'Total Market Cap',
                  _fmtLarge(gMCap ?? totalMCap),
                  Icons.bar_chart_rounded,
                  const Color(0xff6C5CE7),
                ),
                const SizedBox(height: 10),
                _statRow(
                  '24h Trading Volume',
                  _fmtLarge(gVol ?? totalVol),
                  Icons.swap_vert_rounded,
                  const Color(0xff00B894),
                ),
                const SizedBox(height: 10),
                _statRow(
                  'Active Cryptocurrencies',
                  '${activeCryptos ?? coins.length}',
                  Icons.currency_bitcoin,
                  Colors.amber,
                ),
                if (markets is num) ...[
                  const SizedBox(height: 10),
                  _statRow(
                    'Active Markets',
                    markets.toString(),
                    Icons.storefront_outlined,
                    Colors.blueAccent,
                  ),
                ],
                if (mcapChange is num) ...[
                  const SizedBox(height: 10),
                  _statRow(
                    'Market Cap Change (24h)',
                    '${mcapChange >= 0 ? '+' : ''}${mcapChange.toStringAsFixed(2)}%',
                    mcapChange >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    mcapChange >= 0 ? Colors.greenAccent : Colors.redAccent,
                  ),
                ],

                // DOMINANCE BARS
                if (btcDom != null || ethDom != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Market Dominance',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (btcDom != null)
                    _dominanceBar('Bitcoin (BTC)', btcDom, const Color(0xffF7931A)),
                  if (ethDom != null)
                    _dominanceBar('Ethereum (ETH)', ethDom, const Color(0xff627EEA)),
                  if (btcDom != null && ethDom != null) ...[
                    const SizedBox(height: 8),
                    _dominanceBar(
                      'Others',
                      100.0 - btcDom - ethDom,
                      Colors.grey.shade600,
                    ),
                  ],
                ],

                // LEADERS
                const SizedBox(height: 24),
                Text(
                  'Market Leaders',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                if (topMCap != null)
                  _leaderCard('Highest Market Cap', topMCap,
                      _fmtLarge(topMCap.marketCap)),
                const SizedBox(height: 10),
                if (topVol != null)
                  _leaderCard('Highest 24h Volume', topVol,
                      _fmtLarge(topVol.totalVolume)),
                const SizedBox(height: 10),
                if (topPrice != null)
                  _leaderCard('Highest Price', topPrice,
                      _fmtPrice(topPrice.currentPrice)),
              ],
            ),
          ),
        ),

        // TOP 10 TABLE
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top 10 by Market Cap',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ...coins.take(10).map(_topCoinRow),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────

  Widget _statRow(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff171D2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff252C3A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dominanceBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 13),
              ),
              Text(
                '${percent.toStringAsFixed(2)}%',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xff252C3A),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderCard(String title, Coin coin, String value) {
    final positive = coin.priceChangePercentage24h >= 0;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CoinDetailsPage(coin: coin)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xff121925),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xff1E2535)),
        ),
        child: Row(
          children: [
            Image.network(
              coin.image,
              width: 42,
              height: 42,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.currency_bitcoin, size: 42),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    coin.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${positive ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                  style: GoogleFonts.inter(
                    color: positive ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCoinRow(Coin coin) {
    final positive = coin.priceChangePercentage24h >= 0;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CoinDetailsPage(coin: coin)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xff121925),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xff1E2535)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${coin.marketCapRank}',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            Image.network(
              coin.image,
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.currency_bitcoin, size: 32),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                coin.name,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _fmtPrice(coin.currentPrice),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 70,
              child: Text(
                '${positive ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  color: positive ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  static String _fmtLarge(double n) =>
      '\$${NumberFormat.compact(locale: 'en_US').format(n)}';

  static String _fmtPrice(double price) {
    if (price >= 1.0) {
      return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(price);
    } else if (price >= 0.001) {
      return '\$${price.toStringAsFixed(5)}';
    }
    return '\$${price.toStringAsExponential(3)}';
  }

  static double? _usdValue(Map<String, dynamic>? data, String key) {
    final v = data?[key];
    if (v is Map<String, dynamic> && v['usd'] is num) {
      return (v['usd'] as num).toDouble();
    }
    return null;
  }
}

