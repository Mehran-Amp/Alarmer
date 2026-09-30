import 'package:dio/dio.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// Coinbase REST Exchange Adapter
class CoinbaseExchange implements Exchange {
  final Dio _dio;

  CoinbaseExchange({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.exchange.coinbase.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  String get id => 'coinbase';

  @override
  String get name => 'Coinbase';

  @override
  ExchangeCategory get category => ExchangeCategory.tier1;

  @override
  String get countryBadge => '🇺🇸 USA';

  @override
  String get defaultCounterCurrency => 'USD';

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    try {
      final response = await _dio.get('/products');
      final data = response.data as List;
      return data
          .where((item) => item['status'] == 'online')
          .map((item) => CurrencyPair(
                baseCurrency: (item['base_currency'] as String).toUpperCase(),
                counterCurrency: (item['quote_currency'] as String).toUpperCase(),
                marketSymbol: (item['id'] as String).toUpperCase(),
              ))
          .toList();
    } catch (_) {
      return _defaultPairs();
    }
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
      final productId = '${pair.baseCurrency}-${pair.counterCurrency}'.toUpperCase();
      final response = await _dio.get('/products/$productId/ticker');
      final data = response.data as Map<String, dynamic>;
      final price = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
      final vol = double.tryParse(data['volume']?.toString() ?? '0') ?? 0.0;
      return MarketTicker(
        exchangeId: id,
        pair: pair,
        lastPrice: price,
        volume24h: vol,
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

  List<CurrencyPair> _defaultPairs() => [
        const CurrencyPair(baseCurrency: 'BTC', counterCurrency: 'USD', marketSymbol: 'BTC-USD'),
        const CurrencyPair(baseCurrency: 'ETH', counterCurrency: 'USD', marketSymbol: 'ETH-USD'),
        const CurrencyPair(baseCurrency: 'SOL', counterCurrency: 'USD', marketSymbol: 'SOL-USD'),
        const CurrencyPair(baseCurrency: 'ADA', counterCurrency: 'USD', marketSymbol: 'ADA-USD'),
        const CurrencyPair(baseCurrency: 'DOGE', counterCurrency: 'USD', marketSymbol: 'DOGE-USD'),
      ];
}
