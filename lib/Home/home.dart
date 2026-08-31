import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_bloc.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_event.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_state.dart';
import 'package:crypto_market/Coin%20Details/coindetails.dart';
import 'package:crypto_market/models/coin.dart';
import 'package:crypto_market/models/trending_coin.dart';
import 'package:crypto_market/widgets/empty_state.dart';
import 'package:crypto_market/widgets/error_state.dart';
import 'package:crypto_market/widgets/loading_shimmer.dart';
import 'package:crypto_market/widgets/price_change_badge.dart';
import 'package:crypto_market/widgets/sparkline_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

final _compactFormat = NumberFormat.compact(locale: 'en_US');

final _currencyFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: '\$',
);

String formatLargeNumber(double n) {
  return '\$${_compactFormat.format(n)}';
}

String formatPrice(double price) {
  if (price >= 1.0) {
    return _currencyFormat.format(price);
  } else if (price >= 0.001) {
    return '\$${price.toStringAsFixed(5)}';
  } else {
    return '\$${price.toStringAsExponential(3)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME PAGE
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showMarketOverview = true;

  Timer? _searchDebounce;

  final TextEditingController searchController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
  }

  // ─────────────────────────────────────────────
  // PAGINATION SCROLL
  // ─────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    // Load the next page 500px before reaching bottom.
    if (position.pixels >=
        position.maxScrollExtent - 500) {
      final bloc = context.read<CryptoBloc>();

      if (!bloc.isLoadingMore &&
          bloc.hasMoreCoins) {
        bloc.add(LoadMoreCoins());
      }
    }
  }

  // ─────────────────────────────────────────────
  // REFRESH
  // ─────────────────────────────────────────────

  Future<void> _refreshCoins() async {
    final bloc = context.read<CryptoBloc>();

    final completer = Completer<void>();

    late StreamSubscription subscription;

    subscription = bloc.stream.listen((state) {
      if (state is CryptoLoaded ||
          state is CryptoError ||
          state is CryptoEmpty) {
        if (!completer.isCompleted) {
          completer.complete();
        }

        subscription.cancel();
      }
    });

    bloc
      ..add(LoadCoins())
      ..add(LoadTrending());

    await completer.future;
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────

  @override
  void dispose() {
    _searchDebounce?.cancel();

    searchController.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshCoins,
          color: const Color(0xff8B7CFF),
          child: CustomScrollView(
            controller: _scrollController,
            physics:
                const AlwaysScrollableScrollPhysics(),
            slivers: [
              // HEADER
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              // SEARCH
              SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),

              // FILTERS
              SliverToBoxAdapter(
                child: _buildFilterChips(),
              ),

              // MARKET OVERVIEW
              SliverToBoxAdapter(
                child: _buildMarketOverviewSection(),
              ),

              // TRENDING / GAINERS / LOSERS
              SliverToBoxAdapter(
                child: _buildFeaturedSections(),
              ),

              // MARKET TITLE
              SliverToBoxAdapter(
                child: _buildMarketTitle(),
              ),

              // COIN LIST
              _buildCoinList(),

              const SliverToBoxAdapter(
                child: SizedBox(height: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════
  // HEADER
  // ═════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        0,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Crypto Research',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore the crypto market',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff171D2B),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xff252C3A),
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  // SEARCH BAR
  // ═════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        0,
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          _searchDebounce?.cancel();

          _searchDebounce = Timer(
            const Duration(milliseconds: 300),
            () {
              if (!mounted) return;

              context.read<CryptoBloc>().add(
                    SearchCoins(value),
                  );
            },
          );
        },
        style: GoogleFonts.inter(
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText:
              'Search Bitcoin, Ethereum...',
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade600,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.grey,
          ),
          suffixIcon:
              ValueListenableBuilder<
                  TextEditingValue>(
            valueListenable: searchController,
            builder: (
              context,
              value,
              child,
            ) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  size: 18,
                ),
                onPressed: () {
                  searchController.clear();

                  context.read<CryptoBloc>().add(
                        SearchCoins(''),
                      );
                },
              );
            },
          ),
          filled: true,
          fillColor: const Color(0xff171D2B),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xff252C3A),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xff6C5CE7),
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════
  // FILTER CHIPS
  // ═════════════════════════════════════════════

  Widget _buildFilterChips() {
    const filters = [
      ('All', CoinFilter.all),
      ('Gainers', CoinFilter.gainers),
      ('Losers', CoinFilter.losers),
      ('Stable', CoinFilter.stablecoins),
      ('Meme', CoinFilter.memeCoins),
      ('DeFi', CoinFilter.defi),
      ('Layer 1', CoinFilter.layer1),
    ];

    return BlocBuilder<CryptoBloc, CryptoState>(
      builder: (context, state) {
        final bloc = context.read<CryptoBloc>();

        final currentFilter =
            bloc.selectedFilter;

        return Padding(
          padding:
              const EdgeInsets.only(top: 16),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection:
                  Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              children:
                  filters.map((filter) {
                final isSelected =
                    currentFilter ==
                        filter.$2;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    right: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      filter.$1,
                      style:
                          GoogleFonts.inter(
                        color: isSelected
                            ? Colors.white
                            : Colors.grey,
                        fontWeight:
                            isSelected
                                ? FontWeight.w600
                                : FontWeight
                                    .normal,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      context
                          .read<CryptoBloc>()
                          .add(
                            FilterCoins(
                              filter.$2,
                            ),
                          );
                    },
                    selectedColor:
                        const Color(0xff6C5CE7),
                    backgroundColor:
                        const Color(0xff171D2B),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(
                              0xff8B7CFF,
                            )
                          : const Color(
                              0xff252C3A,
                            ),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════
  // MARKET OVERVIEW
  // ═════════════════════════════════════════════

  Widget _buildMarketOverviewSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        0,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Market Overview',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showMarketOverview =
                        !_showMarketOverview;
                  });
                },
                icon: Icon(
                  _showMarketOverview
                      ? Icons
                          .keyboard_arrow_up_rounded
                      : Icons
                          .keyboard_arrow_down_rounded,
                  size: 26,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration:
                const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showMarketOverview
                ? BlocBuilder<CryptoBloc,
                    CryptoState>(
                    builder:
                        (context, state) {
                      final coins =
                          state is CryptoLoaded
                              ? state.coins
                              : state
                                      is TrendingLoaded
                                  ? state.coins
                                  : null;

                      if (coins != null &&
                          coins.isNotEmpty) {
                        return _marketOverviewCards(
                          coins,
                        );
                      }

                      return const
                          _MarketOverviewShimmer();
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _marketOverviewCards(
    List<Coin> coins,
  ) {
    double marketCap = 0;
    double volume = 0;
    int gainers = 0;

    for (final coin in coins) {
      marketCap += coin.marketCap;
      volume += coin.totalVolume;

      if (coin.priceChangePercentage24h > 0) {
        gainers++;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
      ),
      child: SizedBox(
        height: 100,
        child: ListView(
          scrollDirection:
              Axis.horizontal,
          children: [
            _statCard(
              'Market Cap',
              formatLargeNumber(marketCap),
              Icons.bar_chart_rounded,
              const Color(0xff6C5CE7),
            ),
            _statCard(
              '24h Volume',
              formatLargeNumber(volume),
              Icons.swap_vert_rounded,
              const Color(0xff00B894),
            ),
            _statCard(
              'Gainers',
              '$gainers / ${coins.length}',
              Icons.trending_up_rounded,
              Colors.greenAccent.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 165,
      margin: const EdgeInsets.only(
        right: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff171D2B),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xff252C3A),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  // FEATURED SECTIONS
  // ═════════════════════════════════════════════

  Widget _buildFeaturedSections() {
    return BlocBuilder<CryptoBloc, CryptoState>(
      builder: (
        context,
        state,
      ) {
        List<Coin>? coins;
        List<TrendingCoin>? trending;

        if (state is CryptoLoaded) {
          coins = state.coins;
        }

        if (state is TrendingLoaded) {
          coins = state.coins;
          trending = state.trending;
        }

        if (coins == null || coins.isEmpty) {
          return const SizedBox.shrink();
        }

        final gainers =
            List<Coin>.from(coins)
              ..sort(
                (a, b) => b
                    .priceChangePercentage24h
                    .compareTo(
                      a.priceChangePercentage24h,
                    ),
              );

        final losers =
            List<Coin>.from(coins)
              ..sort(
                (a, b) => a
                    .priceChangePercentage24h
                    .compareTo(
                      b.priceChangePercentage24h,
                    ),
              );

        return Column(
          children: [
            if (trending != null &&
                trending.isNotEmpty)
              _trendingSection(
                trending.take(6).toList(),
              ),
            _coinFeaturedSection(
              '🚀 Top Gainers',
              gainers.take(5).toList(),
            ),
            _coinFeaturedSection(
              '📉 Top Losers',
              losers.take(5).toList(),
            ),
          ],
        );
      },
    );
  }

  // ═════════════════════════════════════════════
  // TRENDING
  // ═════════════════════════════════════════════

  Widget _trendingSection(
    List<TrendingCoin> coins,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 Trending',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount: coins.length,
              separatorBuilder:
                  (_, __) =>
                      const SizedBox(width: 10),
              itemBuilder:
                  (context, index) {
                return _trendingCard(
                  coins[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendingCard(
    TrendingCoin coin,
  ) {
    final change =
        coin.priceChangePercentage24h;

    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff171D2B),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xff252C3A),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: coin.image,
                  width: 28,
                  height: 28,
                  errorWidget:
                      (_, __, ___) =>
                          const Icon(
                    Icons.currency_bitcoin,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  coin.symbol.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            coin.name,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          if (change != null)
            PriceChangeBadge(
              percent: change,
              fontSize: 11,
            )
          else
            Text(
              '#${coin.marketCapRank}',
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  // GAINERS / LOSERS
  // ═════════════════════════════════════════════

  Widget _coinFeaturedSection(
    String title,
    List<Coin> coins,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 105,
            child: ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount: coins.length,
              separatorBuilder:
                  (_, __) =>
                      const SizedBox(width: 10),
              itemBuilder:
                  (context, index) {
                final coin = coins[index];

                return GestureDetector(
                  onTap: () => _openDetails(
                    context,
                    coin,
                  ),
                  child: Container(
                    width: 150,
                    padding:
                        const EdgeInsets.all(12),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xff171D2B,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color:
                            const Color(
                          0xff252C3A,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                              child:
                                  CachedNetworkImage(
                                imageUrl:
                                    coin.image,
                                width: 26,
                                height: 26,
                                errorWidget:
                                    (_, __, ___) =>
                                        const Icon(
                                  Icons
                                      .currency_bitcoin,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Expanded(
                              child: Text(
                                coin.symbol
                                    .toUpperCase(),
                                style:
                                    GoogleFonts
                                        .inter(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  fontSize: 13,
                                ),
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          formatPrice(
                            coin.currentPrice,
                          ),
                          style:
                              GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                          ),
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        PriceChangeBadge(
                          percent:
                              coin.priceChangePercentage24h,
                          fontSize: 11,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  // MARKET TITLE
  // ═════════════════════════════════════════════

  Widget _buildMarketTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        12,
        8,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Market',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          PopupMenuButton<CoinSort>(
            tooltip: 'Sort coins',
            icon: Container(
              padding:
                  const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xff171D2B),
                borderRadius:
                    BorderRadius.circular(10),
                border: Border.all(
                  color:
                      const Color(0xff252C3A),
                ),
              ),
              child: const Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Sort',
                    style:
                        TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            color: const Color(0xff1A2030),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
            onSelected: (sort) {
              context
                  .read<CryptoBloc>()
                  .add(
                    SortCoins(sort),
                  );
            },
            itemBuilder:
                (context) => const [
              PopupMenuItem(
                value: CoinSort.marketCap,
                child:
                    Text('Market Cap ↓'),
              ),
              PopupMenuItem(
                value: CoinSort.price,
                child: Text(
                  'Price: High → Low',
                ),
              ),
              PopupMenuItem(
                value:
                    CoinSort.priceLowToHigh,
                child: Text(
                  'Price: Low → High',
                ),
              ),
              PopupMenuItem(
                value: CoinSort.volume,
                child:
                    Text('24h Volume'),
              ),
              PopupMenuItem(
                value: CoinSort.change,
                child:
                    Text('24h Change'),
              ),
              PopupMenuItem(
                value: CoinSort.alphabetical,
                child:
                    Text('Alphabetical'),
              ),
              PopupMenuItem(
                value: CoinSort.rank,
                child: Text('Rank'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  // COIN LIST
  // ═════════════════════════════════════════════

  Widget _buildCoinList() {
    return BlocBuilder<CryptoBloc, CryptoState>(
      builder: (
        context,
        state,
      ) {
        // ───────────────────────────────────────
        // INITIAL LOADING
        // ───────────────────────────────────────

        if (state is CryptoLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: ShimmerCoinList(),
            ),
          );
        }

        // ───────────────────────────────────────
        // ERROR
        // ───────────────────────────────────────

        if (state is CryptoError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorStateWidget(
              message: state.message,
              onRetry: () {
                context
                    .read<CryptoBloc>()
                    .add(
                      LoadCoins(),
                    );
              },
            ),
          );
        }

        // ───────────────────────────────────────
        // EMPTY
        // ───────────────────────────────────────

        if (state is CryptoEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon:
                  Icons.search_off_rounded,
              title: 'No Results Found',
              subtitle: state.reason,
              actionLabel: 'Clear Filter',

              // FIXED:
              // Removed undefined selectedFilter.
              onAction: () {
                searchController.clear();

                context.read<CryptoBloc>()
                  ..add(SearchCoins(''))
                  ..add(
                    FilterCoins(
                      CoinFilter.all,
                    ),
                  );
              },
            ),
          );
        }

        // ───────────────────────────────────────
        // LOADED
        // ───────────────────────────────────────

        if (state is CryptoLoaded ||
            state is TrendingLoaded) {
          final List<Coin> coins =
              state is CryptoLoaded
                  ? state.coins
                  : (state as TrendingLoaded)
                      .coins;

          if (coins.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon:
                    Icons.currency_bitcoin,
                title: 'No Coins Found',
                subtitle:
                    'Pull down to refresh and load the latest market data.',
              ),
            );
          }

          final bloc =
              context.read<CryptoBloc>();

          final showLoadingMore =
              bloc.isLoadingMore;

          final showBottomSpace =
              bloc.hasMoreCoins;

          final extraItem =
              showLoadingMore ||
                      showBottomSpace
                  ? 1
                  : 0;

          return SliverPadding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            sliver:
                SliverList.builder(
              itemCount:
                  coins.length +
                      extraItem,
              itemBuilder:
                  (context, index) {
                // PAGINATION FOOTER
                if (index >= coins.length) {
                  if (showLoadingMore) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 24,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    );
                  }

                  return const SizedBox(
                    height: 40,
                  );
                }

                final coin =
                    coins[index];

                return GestureDetector(
                  onTap: () => _openDetails(
                    context,
                    coin,
                  ),
                  child: CoinCard(
                    coin: coin,
                  ),
                );
              },
            ),
          );
        }

        return const SliverToBoxAdapter(
          child: SizedBox.shrink(),
        );
      },
    );
  }

  // ═════════════════════════════════════════════
  // COIN DETAILS
  // ═════════════════════════════════════════════

  void _openDetails(
    BuildContext context,
    Coin coin,
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (
          _,
          animation,
          __,
        ) =>
            CoinDetailsPage(
          coin: coin,
        ),
        transitionsBuilder: (
          _,
          animation,
          __,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                begin:
                    const Offset(
                  0,
                  0.06,
                ),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve:
                      Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COIN CARD
// ─────────────────────────────────────────────────────────────────────────────

class CoinCard extends StatelessWidget {
  final Coin coin;

  const CoinCard({
    super.key,
    required this.coin,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final positive =
        coin.priceChangePercentage24h >=
            0;

    final sparkColor = positive
        ? Colors.greenAccent.shade400
        : Colors.redAccent.shade400;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff121925),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xff1E2535),
        ),
      ),
      child: Row(
        children: [
          // RANK
          SizedBox(
            width: 26,
            child: Text(
              '${coin.marketCapRank}',
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // IMAGE
          ClipRRect(
            borderRadius:
                BorderRadius.circular(50),
            child: CachedNetworkImage(
              imageUrl: coin.image,
              width: 42,
              height: 42,
              errorWidget:
                  (_, __, ___) =>
                      const Icon(
                Icons.currency_bitcoin,
                size: 42,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // NAME + SYMBOL
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  coin.name,
                  style: GoogleFonts.inter(
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow:
                      TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  coin.symbol.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // SPARKLINE
          if (coin.sparkline.isNotEmpty)
            SparklineChart(
              prices: coin.sparkline,
              color: sparkColor,
              width: 64,
              height: 34,
            ),

          const SizedBox(width: 12),

          // PRICE + CHANGE
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                formatPrice(
                  coin.currentPrice,
                ),
                style: GoogleFonts.inter(
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              PriceChangeBadge(
                percent:
                    coin.priceChangePercentage24h,
              ),
            ],
          ),

          const SizedBox(width: 4),

          // WATCHLIST
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (
              context,
              state,
            ) {
              final saved =
                  context
                      .read<CryptoBloc>()
                      .isWatchlisted(
                        coin.id,
                      );

              return GestureDetector(
                onTap: () {
                  context
                      .read<CryptoBloc>()
                      .add(
                        ToggleWatchlist(
                          coin,
                        ),
                      );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.all(6),
                  child: AnimatedSwitcher(
                    duration:
                        const Duration(
                      milliseconds: 200,
                    ),
                    child: Icon(
                      saved
                          ? Icons.star_rounded
                          : Icons
                              .star_outline_rounded,
                      key: ValueKey(saved),
                      color: saved
                          ? Colors.amber
                          : Colors
                              .grey
                              .shade600,
                      size: 22,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKET OVERVIEW SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _MarketOverviewShimmer
    extends StatelessWidget {
  const _MarketOverviewShimmer();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection:
              Axis.horizontal,
          itemCount: 3,
          separatorBuilder:
              (_, __) =>
                  const SizedBox(width: 12),
          itemBuilder:
              (_, __) =>
                  const ShimmerBox(
            width: 165,
            height: 100,
          ),
        ),
      ),
    );
  }
}