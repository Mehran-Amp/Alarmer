import 'package:dio/dio.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// Wallex Exchange Adapter (Popular Iranian Crypto Exchange)
/// Direct REST integration with Wallex public market stats.
class WallexExchange implements Exchange {
  final Dio _dio;

  WallexExchange({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.wallex.ir/v1',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  String get id => 'wallex';

  @override
  String get name => 'Wallex (والکس)';

  @override
  ExchangeCategory get category => ExchangeCategory.middleEast;

  @override
  String get countryBadge => '🇮🇷 Iran';

  @override
  String get defaultCounterCurrency => 'USDT';

  static const List<String> _popularCoins = [
    'BTC', 'ETH', 'SOL', 'TON', 'USDT', 'XRP', 'DOGE', 'TRX', 'SHIB', 'PEPE',
    'ADA', 'BNB', 'NOT', 'SUI', 'AVAX', 'NEAR', 'LINK', 'DOT', 'BCH', 'LTC',
    'UNI', 'ATOM', 'FET', 'APT', 'ARB', 'OP', 'TIA', 'INJ', 'FTM', 'ALGO',
    'ICP', 'ETC', 'XLM', 'FIL', 'FLOKI', 'BONK', 'WIF', 'ENA', 'KAS',
  ];

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    try {
      final response = await _dio.get('/markets');
      final symbols = response.data?['result']?['symbols'] as Map<String, dynamic>?;

      if (symbols != null && symbols.isNotEmpty) {
        final pairs = <CurrencyPair>[];
        for (final item in symbols.values) {
          if (item is Map) {
            final base = item['baseAsset']?.toString().toUpperCase() ?? '';
            final quote = item['quoteAsset']?.toString().toUpperCase() ?? '';
            final symbol = item['symbol']?.toString().toUpperCase() ?? '$base$quote';

            if (base.isNotEmpty && quote.isNotEmpty) {
              pairs.add(CurrencyPair(
                baseCurrency: base,
                counterCurrency: quote == 'TMN' ? 'TMN' : quote,
                marketSymbol: symbol,
              ));
            }
          }
        }

        if (pairs.isNotEmpty) {
          pairs.sort((a, b) {
            if (a.counterCurrency == 'USDT' && b.counterCurrency != 'USDT') return -1;
            if (a.counterCurrency != 'USDT' && b.counterCurrency == 'USDT') return 1;
            return a.baseCurrency.compareTo(b.baseCurrency);
          });
          return pairs;
        }
      }
    } catch (_) {}

    final list = <CurrencyPair>[];
    for (final sym in _popularCoins) {
      if (sym != 'USDT') {
        list.add(CurrencyPair(
          baseCurrency: sym,
          counterCurrency: 'USDT',
          marketSymbol: '${sym}USDT',
        ));
        list.add(CurrencyPair(
          baseCurrency: sym,
          counterCurrency: 'TMN',
          marketSymbol: '${sym}TMN',
        ));
      }
    }
    return list;
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
    try {
      final response = await _dio.get('/markets');
      final symbols = response.data?['result']?['symbols'] as Map<String, dynamic>?;

      if (symbols == null) {
        throw Exception('Wallex markets data not available');
      }

      final symbolKey = '${pair.baseCurrency}${pair.counterCurrency}'.toUpperCase();
      final data = symbols[symbolKey] as Map<String, dynamic>? ??
          symbols['${pair.baseCurrency}TMN'] as Map<String, dynamic>? ??
          symbols['${pair.baseCurrency}USDT'] as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Market symbol $symbolKey not found on Wallex');
      }

      final stats = data['stats'] as Map<String, dynamic>?;
      final price = double.tryParse(stats?['lastPrice']?.toString() ?? '0') ?? 0.0;
      final vol = double.tryParse(stats?['24h_volume']?.toString() ?? '0') ?? 0.0;
      final high = double.tryParse(stats?['24h_highPrice']?.toString() ?? '0') ?? price;
      final low = double.tryParse(stats?['24h_lowPrice']?.toString() ?? '0') ?? price;

      if (price <= 0) {
        throw Exception('Invalid price received from Wallex ($price)');
      }

      return MarketTicker(
        exchangeId: id,
        pair: pair,
        lastPrice: price,
        volume24h: vol,
        high24h: high,
        low24h: low,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Wallex Live Connection Error for ${pair.displayName}: $e');
    }
  }
}
