import 'package:dio/dio.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// OKX REST Exchange Adapter
/// Direct integration with OKX v5 Public Spot REST endpoints.
class OKXExchange implements Exchange {
  final Dio _dio;

  OKXExchange({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://www.okx.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  String get id => 'okx';

  @override
  String get name => 'OKX';

  @override
  ExchangeCategory get category => ExchangeCategory.tier1;

  @override
  String get countryBadge => '🌐 Global';

  @override
  String get defaultCounterCurrency => 'USDT';

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    try {
      final response = await _dio.get('/api/v5/public/instruments', queryParameters: {'instType': 'SPOT'});
      final data = response.data?['data'] as List?;
      if (data != null && data.isNotEmpty) {
        final pairs = <CurrencyPair>[];
        for (final item in data) {
          final base = item['baseCcy']?.toString().toUpperCase() ?? '';
          final quote = item['quoteCcy']?.toString().toUpperCase() ?? '';
          final instId = item['instId']?.toString() ?? '$base-$quote';
          final state = item['state']?.toString() ?? 'live';

          if (state == 'live' && (quote == 'USDT' || quote == 'USDC' || quote == 'BTC')) {
            pairs.add(CurrencyPair(
              baseCurrency: base,
              counterCurrency: quote,
              marketSymbol: instId,
            ));
          }
        }
        if (pairs.isNotEmpty) return pairs;
      }
    } catch (_) {}

    return _fallbackPairs();
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
      final instId = '${pair.baseCurrency}-${pair.counterCurrency}'.toUpperCase();
      final response = await _dio.get(
        '/api/v5/market/ticker',
        queryParameters: {'instId': instId},
      );

      final data = (response.data?['data'] as List?)?.firstOrNull as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Market data not found on OKX for $instId');
      }

      final price = double.tryParse(data['last']?.toString() ?? '0') ?? 0.0;
      final vol = double.tryParse(data['vol24h']?.toString() ?? '0') ?? 0.0;
      final high = double.tryParse(data['high24h']?.toString() ?? '0') ?? price;
      final low = double.tryParse(data['low24h']?.toString() ?? '0') ?? price;

      if (price <= 0) {
        throw Exception('Invalid price from OKX ($price)');
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
      throw Exception('OKX Live Connection Error for ${pair.displayName}: $e');
    }
  }

  List<CurrencyPair> _fallbackPairs() => const [
        CurrencyPair(baseCurrency: 'BTC', counterCurrency: 'USDT', marketSymbol: 'BTC-USDT'),
        CurrencyPair(baseCurrency: 'ETH', counterCurrency: 'USDT', marketSymbol: 'ETH-USDT'),
        CurrencyPair(baseCurrency: 'SOL', counterCurrency: 'USDT', marketSymbol: 'SOL-USDT'),
        CurrencyPair(baseCurrency: 'TON', counterCurrency: 'USDT', marketSymbol: 'TON-USDT'),
        CurrencyPair(baseCurrency: 'XRP', counterCurrency: 'USDT', marketSymbol: 'XRP-USDT'),
        CurrencyPair(baseCurrency: 'DOGE', counterCurrency: 'USDT', marketSymbol: 'DOGE-USDT'),
        CurrencyPair(baseCurrency: 'PEPE', counterCurrency: 'USDT', marketSymbol: 'PEPE-USDT'),
        CurrencyPair(baseCurrency: 'SUI', counterCurrency: 'USDT', marketSymbol: 'SUI-USDT'),
      ];
}
