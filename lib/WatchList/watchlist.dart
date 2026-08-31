import 'package:crypto_market/Bloc/bloc/cryptobloc_bloc.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_event.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_state.dart';
import 'package:crypto_market/Coin%20Details/coindetails.dart';
import 'package:crypto_market/models/coin.dart';
import 'package:crypto_market/widgets/empty_state.dart';
import 'package:crypto_market/widgets/price_change_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Watchlist extends StatelessWidget {
  const Watchlist({super.key});

  Future<void> _refresh(BuildContext context) async {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Watchlist',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your favourite coins',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<CryptoBloc, CryptoState>(
                builder: (context, state) {
                  final bloc = context.read<CryptoBloc>();
                  final coins = bloc.watchlistCoins();

                  if (coins.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => _refresh(context),
                      color: const Color(0xff8B7CFF),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                          ),
                          EmptyStateWidget(
                            icon: Icons.star_outline_rounded,
                            title: 'No Coins Yet',
                            subtitle:
                                'Tap the ★ icon on any coin to add it to your watchlist.',
                            actionLabel: 'Browse Markets',
                            onAction: () {
                              Navigator.of(context).popUntil(
                                (route) => route.isFirst,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    color: const Color(0xff8B7CFF),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: coins.length,
                      itemBuilder: (context, index) {
                        return _WatchlistCard(
                          coin: coins[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CoinDetailsPage(coin: coins[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WATCHLIST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _WatchlistCard extends StatelessWidget {
  final Coin coin;
  final VoidCallback onTap;

  const _WatchlistCard({required this.coin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xff121925),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xff1E2535)),
        ),
        child: Row(
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: CachedNetworkImage(
                imageUrl: coin.image,
                width: 46,
                height: 46,
                errorWidget: (_, __, ___) => Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xff1A2030),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.currency_bitcoin, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // NAME + SYMBOL
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
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

            // PRICE + CHANGE
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(coin.currentPrice),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                PriceChangeBadge(percent: coin.priceChangePercentage24h),
              ],
            ),

            const SizedBox(width: 8),

            // REMOVE (amber star)
            BlocBuilder<CryptoBloc, CryptoState>(
              builder: (context, _) => GestureDetector(
                onTap: () =>
                    context.read<CryptoBloc>().add(ToggleWatchlist(coin)),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1.0) {
      return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(price);
    } else if (price >= 0.001) {
      return '\$${price.toStringAsFixed(5)}';
    }
    return '\$${price.toStringAsExponential(3)}';
  }
}
