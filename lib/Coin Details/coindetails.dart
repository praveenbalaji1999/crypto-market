import 'package:crypto_market/Bloc/bloc/cryptobloc_bloc.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_event.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_state.dart';
import 'package:crypto_market/crypto_api.dart';
import 'package:crypto_market/models/coin.dart';
import 'package:crypto_market/widgets/price_change_badge.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COIN DETAILS PAGE
// ─────────────────────────────────────────────────────────────────────────────

class CoinDetailsPage extends StatefulWidget {
  final Coin coin;
  const CoinDetailsPage({super.key, required this.coin});

  @override
  State<CoinDetailsPage> createState() => _CoinDetailsPageState();
}

class _CoinDetailsPageState extends State<CoinDetailsPage> {
  final CryptoApi _api = CryptoApi();

  late Coin _displayCoin;
  late List<double> _chartPrices;

  int _selectedChartDays = 7;
  bool _isChartLoading = false;
  bool _isLiveLoading = true;
  int? _selectedChartPoint;

  // Price formatters
  final _currency = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  final _compact = NumberFormat.compact(locale: 'en_US');

  @override
  void initState() {
    super.initState();
    _displayCoin = widget.coin;
    _chartPrices = widget.coin.sparkline;
    _loadLiveCoinData();
  }

  Future<void> _loadLiveCoinData() async {
    final detailsReq = _api.getCoinDetails(widget.coin.id);
    final chartReq = _api.getChartPrices(widget.coin.id, days: 7);

    Coin? details;
    List<double>? chart;

    try {
      details = await detailsReq;
    } catch (_) {}
    try {
      chart = await chartReq;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      if (details != null) _displayCoin = details;
      if (chart != null && chart.isNotEmpty) _chartPrices = chart;
      _selectedChartPoint = null;
      _isLiveLoading = false;
    });
  }

  Future<void> _changeChartRange(int days) async {
    if (_selectedChartDays == days || _isChartLoading) return;
    setState(() {
      _selectedChartDays = days;
      _selectedChartPoint = null;
      _isChartLoading = true;
    });
    try {
      final prices = await _api.getChartPrices(widget.coin.id, days: days);
      if (!mounted) return;
      setState(() => _chartPrices = prices);
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isChartLoading = false);
    }
  }

  Coin get coin => _displayCoin;

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final positive = coin.priceChangePercentage24h >= 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              coin.image,
              width: 26,
              height: 26,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.currency_bitcoin, size: 26),
            ),
            const SizedBox(width: 8),
            Text(
              coin.symbol.toUpperCase(),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (context, state) {
              final saved = context.read<CryptoBloc>().isWatchlisted(coin.id);
              return IconButton(
                tooltip: saved ? 'Remove from watchlist' : 'Add to watchlist',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    saved ? Icons.star_rounded : Icons.star_outline_rounded,
                    key: ValueKey(saved),
                    color: saved ? Colors.amber : Colors.grey,
                  ),
                ),
                onPressed: () =>
                    context.read<CryptoBloc>().add(ToggleWatchlist(coin)),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COIN HEADER
            _buildCoinHeader(positive),

            const SizedBox(height: 32),

            // ATH / ATL PROGRESS
            if (coin.allTimeHigh != null && coin.allTimeLow != null)
              _buildAthAtlSection(),

            // CHART SECTION
            _buildChartSection(),

            // PRICE INFORMATION
            const SizedBox(height: 28),
            _sectionTitle('Price Information'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _infoCard('24h High', _fmtPrice(coin.high24h))),
                const SizedBox(width: 10),
                Expanded(child: _infoCard('24h Low', _fmtPrice(coin.low24h))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    '24h Change',
                    '${positive ? '+' : ''}\$${coin.priceChange24h.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _infoCard('Rank', '#${coin.marketCapRank}')),
              ],
            ),

            // MARKET DATA
            const SizedBox(height: 28),
            _sectionTitle('Market Data'),
            const SizedBox(height: 14),
            _dataRow('Market Cap', '\$${_compact.format(coin.marketCap)}'),
            _dataRow('24h Volume', '\$${_compact.format(coin.totalVolume)}'),
            _dataRow(
              'Circulating Supply',
              '${_compact.format(coin.circulatingSupply)} ${coin.symbol.toUpperCase()}',
            ),
            _dataRow(
              'Total Supply',
              coin.totalSupply == null
                  ? 'N/A'
                  : '${_compact.format(coin.totalSupply!)} ${coin.symbol.toUpperCase()}',
            ),
            _dataRow(
              'Max Supply',
              coin.maxSupply == null
                  ? 'N/A'
                  : '${_compact.format(coin.maxSupply!)} ${coin.symbol.toUpperCase()}',
            ),

            // ADDITIONAL STATS
            const SizedBox(height: 28),
            _sectionTitle('Additional Statistics'),
            const SizedBox(height: 14),
            _dataRow(
              'All Time High',
              coin.allTimeHigh == null
                  ? 'N/A'
                  : _fmtPrice(coin.allTimeHigh!),
            ),
            _dataRow(
              'All Time Low',
              coin.allTimeLow == null
                  ? 'N/A'
                  : _fmtPrice(coin.allTimeLow!),
            ),
            _dataRow(
              'Price Change 7D',
              _fmtPercent(coin.priceChangePercentage7d),
            ),
            _dataRow(
              'Price Change 30D',
              _fmtPercent(coin.priceChangePercentage30d),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // COIN HEADER
  // ─────────────────────────────────────────────

  Widget _buildCoinHeader(bool positive) {
    return Center(
      child: Column(
        children: [
          // Loading indicator or image
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  coin.image,
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.currency_bitcoin, size: 80),
                ),
              ),
              if (_isLiveLoading)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff8B7CFF),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            coin.name,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            coin.symbol.toUpperCase(),
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
          ),

          const SizedBox(height: 18),

          Text(
            _fmtPrice(coin.currentPrice),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 10),

          PriceChangeBadge(
            percent: coin.priceChangePercentage24h,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ATH / ATL PROGRESS BAR
  // ─────────────────────────────────────────────

  Widget _buildAthAtlSection() {
    final ath = coin.allTimeHigh!;
    final atl = coin.allTimeLow ?? 0.0;
    final cur = coin.currentPrice;
    final range = ath - atl;
    final progress = range > 0 ? ((cur - atl) / range).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff171D2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff252C3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '52-Week Range',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _fmtPrice(atl),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xff252C3A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.redAccent, Color(0xff8B7CFF)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _fmtPrice(ath),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${(progress * 100).toStringAsFixed(1)}% from ATL • ${((1 - progress) * 100).toStringAsFixed(1)}% below ATH',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CHART SECTION
  // ─────────────────────────────────────────────

  Widget _buildChartSection() {
    final positive = coin.priceChangePercentage24h >= 0;
    final chartColor = positive ? Colors.greenAccent.shade400 : Colors.redAccent.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Price Chart'),
        const SizedBox(height: 14),

        // Range selector
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              (label: '24H', days: 1),
              (label: '7D', days: 7),
              (label: '1M', days: 30),
              (label: '3M', days: 90),
              (label: '1Y', days: 365),
            ].map((range) {
              final selected = range.days == _selectedChartDays;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _changeChartRange(range.days),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xff6C5CE7)
                          : const Color(0xff171D2B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xff8B7CFF)
                            : const Color(0xff252C3A),
                      ),
                    ),
                    child: Text(
                      range.label,
                      style: GoogleFonts.inter(
                        color: selected ? Colors.white : Colors.grey,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Price readout
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _selectedChartPoint != null &&
                    _selectedChartPoint! < _chartPrices.length
                ? _fmtPrice(_chartPrices[_selectedChartPoint!])
                : _fmtPrice(coin.currentPrice),
            key: ValueKey(_selectedChartPoint),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: chartColor,
            ),
          ),
        ),

        const SizedBox(height: 4),
        Text(
          _selectedChartPoint != null
              ? 'Selected price'
              : 'Touch chart to inspect',
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
        ),

        const SizedBox(height: 12),

        // Chart container
        Container(
          height: 220,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 12, 8, 0),
          decoration: BoxDecoration(
            color: const Color(0xff171D2B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xff252C3A)),
          ),
          child: _isChartLoading
              ? const Center(child: CircularProgressIndicator())
              : _chartPrices.isEmpty
                  ? Center(
                      child: Text(
                        'Chart data unavailable',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    )
                  : _buildLineChart(chartColor),
        ),
      ],
    );
  }

  Widget _buildLineChart(Color color) {
    final spots = List<FlSpot>.generate(
      _chartPrices.length,
      (i) => FlSpot(i.toDouble(), _chartPrices[i]),
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_chartPrices.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (_chartPrices.reduce((a, b) => a > b ? a : b) -
                  _chartPrices.reduce((a, b) => a < b ? a : b)) /
              4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            final spot = response?.lineBarSpots?.firstOrNull;
            if (spot != null && mounted) {
              setState(() => _selectedChartPoint = spot.x.round());
            }
          },
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((i) {
              return TouchedSpotIndicatorData(
                FlLine(color: color.withValues(alpha: 0.5), strokeWidth: 1),
                FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 5,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xff1A2030),
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    _fmtPrice(s.y),
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff171D2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xff252C3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xff1E2535)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FORMATTERS
  // ─────────────────────────────────────────────

  String _fmtPrice(double price) {
    if (price >= 1.0) return _currency.format(price);
    if (price >= 0.001) return '\$${price.toStringAsFixed(5)}';
    return '\$${price.toStringAsExponential(3)}';
  }

  String _fmtPercent(double? v) {
    if (v == null) return 'N/A';
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
  }
}
