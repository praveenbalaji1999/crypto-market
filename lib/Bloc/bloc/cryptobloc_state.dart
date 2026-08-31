import 'package:crypto_market/models/coin.dart';
import 'package:crypto_market/models/trending_coin.dart';

abstract class CryptoState {}

class CryptoInitial extends CryptoState {}

class CryptoLoading extends CryptoState {}

class CryptoLoaded extends CryptoState {
  final List<Coin> coins;
  CryptoLoaded(this.coins);
}

class CryptoEmpty extends CryptoState {
  final String reason;
  CryptoEmpty(this.reason);
}

class CoinSelected extends CryptoState {
  final Coin coin;
  CoinSelected(this.coin);
}

class CryptoError extends CryptoState {
  final String message;
  CryptoError(this.message);
}

class TrendingLoaded extends CryptoState {
  final List<TrendingCoin> trending;
  final List<Coin> coins;
  TrendingLoaded({required this.trending, required this.coins});
}
