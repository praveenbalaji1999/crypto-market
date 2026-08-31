import 'package:crypto_market/models/coin.dart';

abstract class CryptoEvent {}

class LoadCoins extends CryptoEvent {}

class SearchCoins extends CryptoEvent {
  final String query;
  SearchCoins(this.query);
}

class FilterCoins extends CryptoEvent {
  final CoinFilter filter;
  FilterCoins(this.filter);
}

class SortCoins extends CryptoEvent {
  final CoinSort sort;
  SortCoins(this.sort);
}

class SelectCoin extends CryptoEvent {
  final Coin coin;
  SelectCoin(this.coin);
}

class ToggleWatchlist extends CryptoEvent {
  final Coin coin;
  ToggleWatchlist(this.coin);
}

class LoadMoreCoins extends CryptoEvent {
   LoadMoreCoins();
}


class LoadWatchlist extends CryptoEvent {}

class LoadTrending extends CryptoEvent {}

enum CoinFilter { all, gainers, losers, stablecoins, memeCoins, defi, layer1 }

enum CoinSort {
  marketCap,
  price,
  priceLowToHigh,
  volume,
  change,
  alphabetical,
  rank,
}
