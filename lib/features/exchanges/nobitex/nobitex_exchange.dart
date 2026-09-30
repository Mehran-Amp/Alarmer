import 'package:dio/dio.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// Nobitex Exchange Adapter (Popular Iranian Crypto Exchange)
class NobitexExchange implements Exchange {
  final Dio _dio;

  NobitexExchange({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.nobitex.ir',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
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
    return [
      const CurrencyPair(baseCurrency: 'BTC', counterCurrency: 'USDT', marketSymbol: 'btc-usdt'),
      const CurrencyPair(baseCurrency: 'ETH', counterCurrency: 'USDT', marketSymbol: 'eth-usdt'),
      const CurrencyPair(baseCurrency: 'SOL', counterCurrency: 'USDT', marketSymbol: 'sol-usdt'),
      const CurrencyPair(baseCurrency: 'XRP', counterCurrency: 'USDT', marketSymbol: 'xrp-usdt'),
      const CurrencyPair(baseCurrency: 'DOGE', counterCurrency: 'USDT', marketSymbol: 'doge-usdt'),
      const CurrencyPair(baseCurrency: 'TON', counterCurrency: 'USDT', marketSymbol: 'ton-usdt'),
      const CurrencyPair(baseCurrency: 'TRX', counterCurrency: 'USDT', marketSymbol: 'trx-usdt'),
      const CurrencyPair(baseCurrency: 'SHIB', counterCurrency: 'USDT', marketSymbol: 'shib-usdt'),
      const CurrencyPair(baseCurrency: 'PEPE', counterCurrency: 'USDT', marketSymbol: 'pepe-usdt'),
    ];
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
      final src = '${pair.baseCurrency}-${pair.counterCurrency}'.toLowerCase();
      final response = await _dio.post('/market/stats', data: {'srcCurrency': pair.baseCurrency.toLowerCase(), 'dstCurrency': pair.counterCurrency.toLowerCase()});
      final data = response.data['stats']?[src] as Map<String, dynamic>?;
      final price = double.tryParse(data?['latest']?.toString() ?? '0') ?? 0.0;
      final vol = double.tryParse(data?['volumeSrc']?.toString() ?? '0') ?? 0.0;
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
}
