import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crypto_market/crypto_api.dart';
import 'package:crypto_market/models/coin.dart';
import 'package:crypto_market/models/trending_coin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cryptobloc_event.dart';
import 'cryptobloc_state.dart';

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final CryptoApi api;

  // ─────────────────────────────────────────────
  // COIN DATA
  // ─────────────────────────────────────────────

  List<Coin> allCoins = [];
  List<Coin> filteredCoins = [];
  List<TrendingCoin> trendingCoins = [];

  // ─────────────────────────────────────────────
  // WATCHLIST
  // ─────────────────────────────────────────────

  final List<Coin> _watchlistCoins = [];
  final Set<String> _watchlistIds = {};

  // ─────────────────────────────────────────────
  // SEARCH / FILTER
  // ─────────────────────────────────────────────

  String searchQuery = '';
  CoinFilter selectedFilter = CoinFilter.all;

  // ─────────────────────────────────────────────
  // PAGINATION
  // ─────────────────────────────────────────────

  static const int pageLimit = 20;

  int _offset = 0;

  bool _isLoadingMore = false;

  bool _hasMoreCoins = true;

  // Public getters if your UI needs them
  bool get isLoadingMore => _isLoadingMore;

  bool get hasMoreCoins => _hasMoreCoins;

  int get currentOffset => _offset;

  // ─────────────────────────────────────────────
  // CONSTRUCTOR
  // ─────────────────────────────────────────────

  CryptoBloc(this.api) : super(CryptoInitial()) {
    on<LoadCoins>(_loadCoins);
    on<LoadMoreCoins>(_loadMoreCoins);

    on<SearchCoins>(_searchCoins);
    on<FilterCoins>(_filterCoins);
    on<SortCoins>(_sortCoins);

    on<SelectCoin>(_selectCoin);

    on<ToggleWatchlist>(_toggleWatchlist);
    on<LoadWatchlist>(_loadWatchlist);

    on<LoadTrending>(_loadTrending);
  }

  // ═════════════════════════════════════════════
  // WATCHLIST HELPERS
  // ═════════════════════════════════════════════

  List<Coin> watchlistCoins() {
    return List<Coin>.from(_watchlistCoins);
  }

  bool isWatchlisted(String coinId) {
    return _watchlistIds.contains(coinId);
  }

  // ═════════════════════════════════════════════
  // LOAD FIRST PAGE
  // ═════════════════════════════════════════════

  Future<void> _loadCoins(
    LoadCoins event,
    Emitter<CryptoState> emit,
  ) async {
    // Reset pagination
    _offset = 0;
    _hasMoreCoins = true;
    _isLoadingMore = false;

    emit(CryptoLoading());

    try {
      final coins = await api.getCoins(
        limit: pageLimit,
        offset: 0,
      );

      // Store first page
      allCoins = List<Coin>.from(coins);

      // Update offset
      _offset = coins.length;

      // If API returned less than requested,
      // there are probably no more coins.
      if (coins.length < pageLimit) {
        _hasMoreCoins = false;
      }

      _refreshWatchlistCoins();

      _applyFiltersAndSearch(emit);
    } catch (e) {
      emit(
        CryptoError(
          'Unable to load crypto data. Check your connection.',
        ),
      );
    }
  }

  // ═════════════════════════════════════════════
  // LOAD MORE COINS
  // ═════════════════════════════════════════════

  Future<void> _loadMoreCoins(
    LoadMoreCoins event,
    Emitter<CryptoState> emit,
  ) async {
    // Prevent duplicate API calls
    if (_isLoadingMore) return;

    // No more data available
    if (!_hasMoreCoins) return;

    _isLoadingMore = true;

    // Keep currently displayed coins
    final currentCoins = List<Coin>.from(allCoins);

    try {
      final newCoins = await api.getCoins(
        limit: pageLimit,
        offset: _offset,
      );

      // No new data
      if (newCoins.isEmpty) {
        _hasMoreCoins = false;
        _isLoadingMore = false;
        return;
      }

      // Prevent duplicate coins
      final existingIds = allCoins.map((coin) => coin.id).toSet();

      final uniqueNewCoins = newCoins.where(
        (coin) => !existingIds.contains(coin.id),
      ).toList();

      // Append new coins
      allCoins.addAll(uniqueNewCoins);

      // Move offset
      _offset += newCoins.length;

      // If fewer than pageLimit came back,
      // we've reached the end.
      if (newCoins.length < pageLimit) {
        _hasMoreCoins = false;
      }

      _refreshWatchlistCoins();

      // Apply existing search/filter
      _applyFiltersAndSearch(
        emit,
        preserveLoadingMore: true,
      );
    } catch (e) {
      // Do NOT replace the existing list with CryptoError.
      // The user can continue using the already loaded data.
      emit(
        CryptoLoaded(
          List<Coin>.from(
            filteredCoins.isNotEmpty ? filteredCoins : currentCoins,
          ),
        ),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  // ═════════════════════════════════════════════
  // LOAD TRENDING
  // ═════════════════════════════════════════════

  Future<void> _loadTrending(
    LoadTrending event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      final trending = await api.getTrending();

      trendingCoins = trending;

      // Re-emit current loaded state with trending data merged
      if (state is CryptoLoaded) {
        emit(
          TrendingLoaded(
            trending: trending,
            coins: filteredCoins,
          ),
        );
      }
    } catch (_) {
      // Non-fatal.
      // Trending section stays hidden.
    }
  }

  // ═════════════════════════════════════════════
  // SEARCH
  // ═════════════════════════════════════════════

  void _searchCoins(
    SearchCoins event,
    Emitter<CryptoState> emit,
  ) {
    searchQuery = event.query.toLowerCase().trim();

    _applyFiltersAndSearch(emit);
  }

  // ═════════════════════════════════════════════
  // FILTER
  // ═════════════════════════════════════════════

  void _filterCoins(
    FilterCoins event,
    Emitter<CryptoState> emit,
  ) {
    selectedFilter = event.filter;

    _applyFiltersAndSearch(emit);
  }

  // ═════════════════════════════════════════════
  // SORT
  // ═════════════════════════════════════════════

  void _sortCoins(
    SortCoins event,
    Emitter<CryptoState> emit,
  ) {
    final coins = List<Coin>.from(filteredCoins);

    switch (event.sort) {
      case CoinSort.marketCap:
        coins.sort(
          (a, b) => b.marketCap.compareTo(a.marketCap),
        );

      case CoinSort.price:
        coins.sort(
          (a, b) => b.currentPrice.compareTo(a.currentPrice),
        );

      case CoinSort.priceLowToHigh:
        coins.sort(
          (a, b) => a.currentPrice.compareTo(b.currentPrice),
        );

      case CoinSort.volume:
        coins.sort(
          (a, b) => b.totalVolume.compareTo(a.totalVolume),
        );

      case CoinSort.change:
        coins.sort(
          (a, b) => b.priceChangePercentage24h
              .compareTo(a.priceChangePercentage24h),
        );

      case CoinSort.alphabetical:
        coins.sort(
          (a, b) => a.name.compareTo(b.name),
        );

      case CoinSort.rank:
        coins.sort(
          (a, b) => a.marketCapRank.compareTo(b.marketCapRank),
        );
    }

    filteredCoins = coins;

    emit(
      CryptoLoaded(
        List<Coin>.from(filteredCoins),
      ),
    );
  }

  // ═════════════════════════════════════════════
  // SELECT COIN
  // ═════════════════════════════════════════════

  void _selectCoin(
    SelectCoin event,
    Emitter<CryptoState> emit,
  ) {
    emit(
      CoinSelected(event.coin),
    );
  }

  // ═════════════════════════════════════════════
  // TOGGLE WATCHLIST
  // ═════════════════════════════════════════════

  void _toggleWatchlist(
    ToggleWatchlist event,
    Emitter<CryptoState> emit,
  ) {
    final coin = event.coin;

    if (isWatchlisted(coin.id)) {
      _watchlistCoins.removeWhere(
        (item) => item.id == coin.id,
      );

      _watchlistIds.remove(coin.id);
    } else {
      _watchlistCoins.add(coin);
      _watchlistIds.add(coin.id);
    }

    unawaited(
      _saveWatchlist(),
    );

    emit(
      CryptoLoaded(
        List<Coin>.from(filteredCoins),
      ),
    );
  }

  // ═════════════════════════════════════════════
  // LOAD WATCHLIST
  // ═════════════════════════════════════════════

  Future<void> _loadWatchlist(
    LoadWatchlist event,
    Emitter<CryptoState> emit,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    _watchlistIds
      ..clear()
      ..addAll(
        preferences.getStringList(
              'watchlist_coin_ids',
            ) ??
            const [],
      );

    _refreshWatchlistCoins();

    if (state is CryptoLoaded) {
      emit(
        CryptoLoaded(
          List<Coin>.from(filteredCoins),
        ),
      );
    }
  }

  // ═════════════════════════════════════════════
  // SAVE WATCHLIST
  // ═════════════════════════════════════════════

  Future<void> _saveWatchlist() async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setStringList(
      'watchlist_coin_ids',
      _watchlistIds.toList(
        growable: false,
      ),
    );
  }

  // ═════════════════════════════════════════════
  // REFRESH WATCHLIST COINS
  // ═════════════════════════════════════════════

  void _refreshWatchlistCoins() {
    _watchlistCoins
      ..clear()
      ..addAll(
        allCoins.where(
          (coin) => _watchlistIds.contains(
            coin.id,
          ),
        ),
      );
  }

  // ═════════════════════════════════════════════
  // SEARCH + FILTER
  // ═════════════════════════════════════════════

  void _applyFiltersAndSearch(
    Emitter<CryptoState> emit, {
    bool preserveLoadingMore = false,
  }) {
    List<Coin> result =
        List<Coin>.from(allCoins);

    // ───────────────────────────────────────────
    // SEARCH
    // ───────────────────────────────────────────

    if (searchQuery.isNotEmpty) {
      result = result.where((coin) {
        return coin.name
                .toLowerCase()
                .contains(searchQuery) ||
            coin.symbol
                .toLowerCase()
                .contains(searchQuery);
      }).toList();
    }

    // ───────────────────────────────────────────
    // FILTER
    // ───────────────────────────────────────────

    switch (selectedFilter) {
      case CoinFilter.all:
        break;

      case CoinFilter.gainers:
        result = result
            .where(
              (c) =>
                  c.priceChangePercentage24h > 0,
            )
            .toList();

      case CoinFilter.losers:
        result = result
            .where(
              (c) =>
                  c.priceChangePercentage24h < 0,
            )
            .toList();

      case CoinFilter.stablecoins:
        const stables = {
          'tether',
          'usd-coin',
          'dai',
          'binance-usd',
          'true-usd',
          'first-digital-usd',
        };

        result = result
            .where(
              (c) => stables.contains(c.id),
            )
            .toList();

      case CoinFilter.memeCoins:
        const memes = {
          'dogecoin',
          'shiba-inu',
          'pepe',
          'bonk',
          'dogwifcoin',
          'floki',
        };

        result = result
            .where(
              (c) => memes.contains(c.id),
            )
            .toList();

      case CoinFilter.defi:
        const defi = {
          'uniswap',
          'aave',
          'maker',
          'lido-staked-ether',
          'chainlink',
          'curve-dao-token',
        };

        result = result
            .where(
              (c) => defi.contains(c.id),
            )
            .toList();

      case CoinFilter.layer1:
        const layer1 = {
          'bitcoin',
          'ethereum',
          'solana',
          'cardano',
          'avalanche-2',
          'polkadot',
          'cosmos',
        };

        result = result
            .where(
              (c) => layer1.contains(c.id),
            )
            .toList();
    }

    filteredCoins = result;

    // ───────────────────────────────────────────
    // EMPTY STATE
    // ───────────────────────────────────────────

    if (result.isEmpty &&
        (searchQuery.isNotEmpty ||
            selectedFilter != CoinFilter.all)) {
      emit(
        CryptoEmpty(
          searchQuery.isNotEmpty
              ? 'No coins match "$searchQuery"'
              : 'No coins in this category',
        ),
      );
    } else {
      emit(
        CryptoLoaded(
          List<Coin>.from(filteredCoins),
        ),
      );
    }
  }
}