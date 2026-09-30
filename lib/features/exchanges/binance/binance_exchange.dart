import 'package:dio/dio.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// Production-grade Binance Exchange Adapter.
/// Pure REST endpoints for pair discovery, lightweight snapshots, and 24h ticker metrics.
class BinanceExchange implements Exchange {
  final Dio _dio;

  BinanceExchange({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.binance.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  String get id => 'binance';

  @override
  String get name => 'Binance';

  @override
  ExchangeCategory get category => ExchangeCategory.tier1;

  @override
  String get countryBadge => '🌐 Global #1';

  @override
  String get defaultCounterCurrency => 'USDT';

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    try {
      final response = await _dio.get('/api/v3/exchangeInfo');
      final data = response.data as Map<String, dynamic>;
      final symbols = data['symbols'] as List<dynamic>;

      final pairs = <CurrencyPair>[];
      for (final item in symbols) {
        final symbolMap = item as Map<String, dynamic>;
        final status = symbolMap['status'] as String?;
        final isSpot = (symbolMap['isSpotTradingAllowed'] as bool?) ?? true;

        if (status == 'TRADING' && isSpot) {
          pairs.add(CurrencyPair(
            baseCurrency: symbolMap['baseAsset'] as String,
            counterCurrency: symbolMap['quoteAsset'] as String,
            marketSymbol: symbolMap['symbol'] as String,
          ));
        }
      }
      return pairs;
    } catch (e) {
      throw Exception('Failed to fetch Binance currency pairs: $e');
    }
  }

  @override
  Future<PriceSnapshot> fetchSnapshot(CurrencyPair pair) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.binance.com/api/v3/ticker/24hr',
        queryParameters: {'symbol': pair.marketSymbol.toUpperCase()},
      );

      final json = response.data!;
      return PriceSnapshot(
        price: double.parse(json['lastPrice'] as String),
        volume: double.parse(json['quoteVolume'] as String),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(
          json['closeTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      throw Exception('Failed to fetch Binance price snapshot for ${pair.marketSymbol}: $e');
    }
  }

  @override
  Future<MarketTicker> fetchTicker(CurrencyPair pair) async {
    try {
      final response = await _dio.get(
        '/api/v3/ticker/24hr',
        queryParameters: {'symbol': pair.marketSymbol.toUpperCase()},
      );
      final json = response.data as Map<String, dynamic>;

      return MarketTicker(
        lastPrice: double.parse(json['lastPrice'] as String),
        volume24h: double.parse(json['quoteVolume'] as String),
        high24h: double.parse(json['highPrice'] as String),
        low24h: double.parse(json['lowPrice'] as String),
        bid: json['bidPrice'] != null ? double.parse(json['bidPrice'] as String) : null,
        ask: json['askPrice'] != null ? double.parse(json['askPrice'] as String) : null,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['closeTime'] as int),
      );
    } catch (e) {
      throw Exception('Failed to fetch Binance REST ticker for ${pair.marketSymbol}: $e');
    }
  }
}
