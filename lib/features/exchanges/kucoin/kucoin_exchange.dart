import 'package:dio/dio.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// KuCoin REST Exchange Adapter
class KuCoinExchange implements Exchange {
  final Dio _dio;

  KuCoinExchange({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.kucoin.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  String get id => 'kucoin';

  @override
  String get name => 'KuCoin';

  @override
  ExchangeCategory get category => ExchangeCategory.tier1;

  @override
  String get countryBadge => '🌐 Global';

  @override
  String get defaultCounterCurrency => 'USDT';

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    try {
      final response = await _dio.get('/api/v1/symbols');
      final data = response.data['data'] as List;
      return data
          .map((item) => CurrencyPair(
                baseCurrency: (item['baseCurrency'] as String).toUpperCase(),
                counterCurrency: (item['quoteCurrency'] as String).toUpperCase(),
                marketSymbol: (item['symbol'] as String).toUpperCase(),
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
      final symbol = '${pair.baseCurrency}-${pair.counterCurrency}'.toUpperCase();
      final response = await _dio.get('/api/v1/market/orderbook/level1', queryParameters: {'symbol': symbol});
      final data = response.data['data'] as Map<String, dynamic>;
      final price = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
      final vol = double.tryParse(data['size']?.toString() ?? '0') ?? 0.0;
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
        const CurrencyPair(baseCurrency: 'BTC', counterCurrency: 'USDT', marketSymbol: 'BTC-USDT'),
        const CurrencyPair(baseCurrency: 'ETH', counterCurrency: 'USDT', marketSymbol: 'ETH-USDT'),
        const CurrencyPair(baseCurrency: 'SOL', counterCurrency: 'USDT', marketSymbol: 'SOL-USDT'),
        const CurrencyPair(baseCurrency: 'XRP', counterCurrency: 'USDT', marketSymbol: 'XRP-USDT'),
        const CurrencyPair(baseCurrency: 'PEPE', counterCurrency: 'USDT', marketSymbol: 'PEPE-USDT'),
        const CurrencyPair(baseCurrency: 'DOGE', counterCurrency: 'USDT', marketSymbol: 'DOGE-USDT'),
      ];
}
