import 'package:dio/dio.dart';
import '../base/crypto_catalog_data.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// Nobitex Exchange Adapter (Leading Iranian Crypto Exchange)
/// Direct REST API integration with real-time live price endpoints.
class NobitexExchange implements Exchange {
  final Dio _dio;

  NobitexExchange({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.nobitex.ir',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ));

  @override
  String get id => 'nobitex';

  @override
  String get name => 'Nobitex (نوبیتکس)';

  @override
  ExchangeCategory get category => ExchangeCategory.middleEast;

  @override
  String get countryBadge => '🇮🇷 Iran';

  @override
  String get defaultCounterCurrency => 'USDT';

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    try {
      final response = await _dio.post('/market/stats');
      if (response.data is Map && response.data['stats'] is Map) {
        final stats = response.data['stats'] as Map<String, dynamic>;
        final pairs = <CurrencyPair>[];

        for (final key in stats.keys) {
          final parts = key.split('-');
          if (parts.length == 2) {
            final base = parts[0].toUpperCase();
            final counter = parts[1].toUpperCase() == 'RLS' ? 'TMN' : parts[1].toUpperCase();
            pairs.add(CurrencyPair(
              baseCurrency: base,
              counterCurrency: counter,
              marketSymbol: key,
            ));
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

    // Complete Nobitex cryptos in both USDT and TMN
    return CryptoCatalogData.buildPairs(
      quoteCurrencies: ['USDT', 'TMN'],
      symbolFormatter: (b, q) => '${b.toLowerCase()}-${q == "TMN" ? "rls" : q.toLowerCase()}',
    );
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
    final dst = pair.counterCurrency.toUpperCase() == 'TMN' ? 'rls' : pair.counterCurrency.toLowerCase();
    final src = pair.baseCurrency.toLowerCase();
    final pairKey = '$src-$dst';

    try {
      final response = await _dio.post(
        '/market/stats',
        data: {'srcCurrency': src, 'dstCurrency': dst},
      );

      final stats = response.data?['stats'] as Map<String, dynamic>?;
      final data = stats?[pairKey] as Map<String, dynamic>? ?? stats?['$src-${pair.counterCurrency.toLowerCase()}'] as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Market data not found on Nobitex for $pairKey');
      }

      var price = double.tryParse(data['latest']?.toString() ?? '0') ?? 0.0;
      if (dst == 'rls' && price > 0) {
        price = price / 10.0;
      }

      final vol = double.tryParse(data['volumeSrc']?.toString() ?? '0') ?? 0.0;
      final high = double.tryParse(data['dayHigh']?.toString() ?? '0') ?? price;
      final low = double.tryParse(data['dayLow']?.toString() ?? '0') ?? price;

      if (price <= 0) {
        throw Exception('Invalid price received from Nobitex ($price)');
      }

      return MarketTicker(
        exchangeId: id,
        pair: pair,
        lastPrice: price,
        volume24h: vol,
        high24h: dst == 'rls' ? high / 10.0 : high,
        low24h: dst == 'rls' ? low / 10.0 : low,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Nobitex Live Connection Error for ${pair.displayName}: $e');
    }
  }
}
