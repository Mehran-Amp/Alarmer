import 'package:dio/dio.dart';
import '../base/crypto_catalog_data.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// Production-grade CoinGecko Exchange Adapter.
/// Covers top altcoins and long-tail tokens.
class CoinGeckoExchange implements Exchange {
  final Dio _dio;
  final Map<String, _CachedTicker> _tickerCache = {};
  List<CurrencyPair>? _cachedPairs;
  DateTime? _pairsCacheTimestamp;

  CoinGeckoExchange({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.coingecko.com/api/v3',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'Alarmer/1.0',
              },
            ));

  @override
  String get id => 'coingecko';

  @override
  String get name => 'CoinGecko (250+ Coins)';

  @override
  ExchangeCategory get category => ExchangeCategory.aggregator;

  @override
  String get countryBadge => '📊 Global Index';

  @override
  String get defaultCounterCurrency => 'USD';

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    if (_cachedPairs != null && _pairsCacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_pairsCacheTimestamp!);
      if (cacheAge < const Duration(hours: 1)) {
        return _cachedPairs!;
      }
    }

    try {
      final response = await _dio.get(
        '/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': 250,
          'page': 1,
          'sparkline': false,
        },
      );

      final list = response.data as List<dynamic>;
      final pairs = <CurrencyPair>[];

      for (final item in list) {
        final coin = item as Map<String, dynamic>;
        final symbol = (coin['symbol'] as String).toUpperCase();
        final coinId = coin['id'] as String;

        pairs.add(CurrencyPair(
          baseCurrency: symbol,
          counterCurrency: 'USD',
          marketSymbol: '$coinId:usd',
        ));
      }

      if (pairs.isNotEmpty) {
        _cachedPairs = pairs;
        _pairsCacheTimestamp = DateTime.now();
        return pairs;
      }
    } catch (_) {}

    final fallback = CryptoCatalogData.buildPairs(
      quoteCurrencies: ['USD'],
      symbolFormatter: (b, q) => '${b.toLowerCase()}:usd',
    );
    _cachedPairs = fallback;
    return fallback;
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
    final coinId = _extractCoinId(pair);
    final counter = pair.counterCurrency.toLowerCase();

    final cached = _tickerCache[pair.marketSymbol];
    if (cached != null && DateTime.now().difference(cached.timestamp) < const Duration(seconds: 15)) {
      return cached.ticker;
    }

    try {
      final response = await _dio.get(
        '/simple/price',
        queryParameters: {
          'ids': coinId,
          'vs_currencies': counter,
          'include_24hr_vol': true,
          'include_24hr_change': true,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final coinData = data[coinId] as Map<String, dynamic>?;

      if (coinData == null || coinData[counter] == null) {
        throw Exception('Price data not found on CoinGecko for $coinId in $counter');
      }

      final price = (coinData[counter] as num).toDouble();
      final volume = (coinData['${counter}_24h_vol'] as num?)?.toDouble() ?? 0.0;
      final change24h = (coinData['${counter}_24h_change'] as num?)?.toDouble() ?? 0.0;

      final high24h = change24h >= 0 ? price * (1 + (change24h / 100)) : price;
      final low24h = change24h < 0 ? price * (1 + (change24h / 100)) : price * 0.95;

      final ticker = MarketTicker(
        exchangeId: id,
        pair: pair,
        lastPrice: price,
        volume24h: volume,
        high24h: high24h,
        low24h: low24h,
        timestamp: DateTime.now(),
      );

      _tickerCache[pair.marketSymbol] = _CachedTicker(ticker: ticker, timestamp: DateTime.now());
      return ticker;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429 && cached != null) {
        return cached.ticker;
      }
      throw Exception('CoinGecko REST Error: ${e.message}');
    }
  }

  String _extractCoinId(CurrencyPair pair) {
    if (pair.marketSymbol.contains(':')) {
      return pair.marketSymbol.split(':').first.toLowerCase();
    }
    return pair.baseCurrency.toLowerCase();
  }
}

class _CachedTicker {
  final MarketTicker ticker;
  final DateTime timestamp;

  _CachedTicker({required this.ticker, required this.timestamp});
}
