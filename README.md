# Crypto Research

A small CoinGecko-style Flutter app that displays live market data, coin
details, a 7-day price chart, market statistics, search, sorting, and a
persistent watchlist.

## Run it

```bash
cd Crypto_Backend && npm start
flutter run
```

### Backend connectivity

The app tries backend URLs in this order:

1. **Custom URL** — set with `--dart-define=API_BASE_URL=...`
2. **Platform default** — Android emulator: `http://10.0.2.2:8000`; iOS simulator / desktop: `http://localhost:8000`
3. **Deployed fallback** — `https://crypto-backend-hemn.onrender.com` (first request may be slow on cold start)

**Physical device** (phone on same Wi‑Fi as your computer):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.9:8000
```

Replace `192.168.1.9` with your machine's LAN IP. Start the backend with
`cd Crypto_Backend && npm start`.

**Optional:** override the deployed fallback:

```bash
flutter run --dart-define=API_FALLBACK_URL=https://your-backend.example.com
```

If the backend is unavailable, the app falls back to public CoinGecko data
for the coin list and trending section only. Put `COINGECKO_API_KEY` in
`Crypto_Backend/.env` to use the CoinGecko demo key through the backend.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
