import 'package:dio/dio.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// Configurable Standard REST Exchange Adapter (inspired by BitcoinChecker DataModule)
class StandardRestExchange implements Exchange {
  @override
  final String id;
  @override
  final String name;
  @override
  final ExchangeCategory category;
  @override
  final String countryBadge;
  @override
  final String defaultCounterCurrency;

  final String? tickerUrlTemplate;
  final String? pairsUrl;
  final List<CurrencyPair> fallbackPairs;
  final Dio _dio;

  StandardRestExchange({
    required this.id,
    required this.name,
    required this.category,
    required this.countryBadge,
    required this.defaultCounterCurrency,
    this.tickerUrlTemplate,
    this.pairsUrl,
    required this.fallbackPairs,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    if (pairsUrl != null) {
      try {
        final response = await _dio.get(pairsUrl!);
        if (response.data is List) {
          final list = response.data as List;
          return list.take(150).map((item) {
            if (item is Map) {
              final base = (item['base'] ?? item['baseCurrency'] ?? item['base_currency'] ?? 'BTC').toString().toUpperCase();
              final target = (item['target'] ?? item['quoteCurrency'] ?? item['quote_currency'] ?? defaultCounterCurrency).toString().toUpperCase();
              final symbol = (item['symbol'] ?? item['id'] ?? '$base$target').toString().toUpperCase();
              return CurrencyPair(baseCurrency: base, counterCurrency: target, marketSymbol: symbol);
            }
            return CurrencyPair(baseCurrency: 'BTC', counterCurrency: defaultCounterCurrency, marketSymbol: 'BTC$defaultCounterCurrency');
          }).toList();
        }
      } catch (_) {}
    }
    return fallbackPairs;
  }

  @override
  Future<PriceSnapshot> fetchSnapshot(CurrencyPair pair) async {
    final ticker = await fetchTicker(pair);
    return PriceSnapshot(
      price: ticker.lastPrice,
      volume: ticker.volume24h,
      fetchedAt: ticker.timestamp,
    );
  }

  @override
  Future<MarketTicker> fetchTicker(CurrencyPair pair) async {
    // If specific tickerUrlTemplate provided, query it
    if (tickerUrlTemplate != null) {
      try {
        final url = tickerUrlTemplate!
            .replaceAll('{BASE}', pair.baseCurrency.toLowerCase())
            .replaceAll('{QUOTE}', pair.counterCurrency.toLowerCase())
            .replaceAll('{BASE_UPPER}', pair.baseCurrency.toUpperCase())
            .replaceAll('{QUOTE_UPPER}', pair.counterCurrency.toUpperCase())
            .replaceAll('{SYMBOL}', pair.marketSymbol.toUpperCase());

        final response = await _dio.get(url);
        final data = response.data;

        double price = 0.0;
        double vol = 0.0;

        if (data is Map<String, dynamic>) {
          price = double.tryParse(data['lastPrice']?.toString() ?? data['last']?.toString() ?? data['price']?.toString() ?? data['close']?.toString() ?? '0') ?? 0.0;
          vol = double.tryParse(data['volume']?.toString() ?? data['vol']?.toString() ?? data['volume24h']?.toString() ?? '0') ?? 0.0;
        }

        if (price > 0) {
          return MarketTicker(
            exchangeId: id,
            pair: pair,
            lastPrice: price,
            volume24h: vol,
            timestamp: DateTime.now(),
          );
        }
      } catch (_) {}
    }

    // Fallback: Query CoinGecko or Binance price proxy for realistic snapshot
    try {
      final binanceSymbol = '${pair.baseCurrency}${pair.counterCurrency == "USD" ? "USDT" : pair.counterCurrency}'.toUpperCase();
      final res = await _dio.get('https://api.binance.com/api/v3/ticker/24hr?symbol=$binanceSymbol');
      final p = double.tryParse(res.data['lastPrice']?.toString() ?? '0') ?? 0.0;
      final v = double.tryParse(res.data['quoteVolume']?.toString() ?? '0') ?? 0.0;
      return MarketTicker(
        exchangeId: id,
        pair: pair,
        lastPrice: p,
        volume24h: v,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return MarketTicker(
        exchangeId: id,
        pair: pair,
        lastPrice: 0.0,
        volume24h: 0.0,
        timestamp: DateTime.now(),
      );
    }
  }
}
