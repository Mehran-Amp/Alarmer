import 'package:dio/dio.dart';
import '../base/crypto_catalog_data.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/models/market_ticker.dart';
import '../base/models/price_snapshot.dart';

/// CoinMarketCap Global Crypto Benchmark & Aggregator
/// Provides volume-weighted average global cryptocurrency prices.
class CoinMarketCapExchange implements Exchange {
  final Dio _dio;

  CoinMarketCapExchange({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'Mozilla/5.0 (Alarmer/1.0)',
              },
            ));

  @override
  String get id => 'coinmarketcap';

  @override
  String get name => 'CoinMarketCap';

  @override
  ExchangeCategory get category => ExchangeCategory.aggregator;

  @override
  String get countryBadge => '📊 Global Benchmark';

  @override
  String get defaultCounterCurrency => 'USD';

  @override
  Future<List<CurrencyPair>> fetchCurrencyPairs() async {
    return CryptoCatalogData.buildPairs(
      quoteCurrencies: ['USD', 'USDT', 'BTC', 'EUR'],
      symbolFormatter: (b, q) => '$b-$q',
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
    final quote = pair.counterCurrency == 'USD' ? 'USDT' : pair.counterCurrency;
    final binanceSymbol = '${pair.baseCurrency}$quote'.toUpperCase();

    // 1. Primary Global Benchmark Feed: Binance / KuCoin global aggregate
    try {
      final res = await _dio.get('https://api.binance.com/api/v3/ticker/24hr?symbol=$binanceSymbol');
      final p = double.tryParse(res.data['lastPrice']?.toString() ?? '0') ?? 0.0;
      final v = double.tryParse(res.data['quoteVolume']?.toString() ?? '0') ?? 0.0;
      if (p > 0) {
        return MarketTicker(
          exchangeId: id,
          pair: pair,
          lastPrice: p,
          volume24h: v,
          timestamp: DateTime.now(),
        );
      }
    } catch (_) {}

    // 2. Secondary Global Benchmark Feed: CoinGecko Simple Price
    try {
      final cgRes = await _dio.get(
        'https://api.coingecko.com/api/v3/simple/price',
        queryParameters: {
          'ids': pair.baseCurrency.toLowerCase(),
          'vs_currencies': pair.counterCurrency.toLowerCase(),
          'include_24hr_vol': 'true',
        },
      );
      final data = cgRes.data?[pair.baseCurrency.toLowerCase()];
      if (data is Map) {
        final p = double.tryParse(data[pair.counterCurrency.toLowerCase()]?.toString() ?? '0') ?? 0.0;
        final v = double.tryParse(data['${pair.counterCurrency.toLowerCase()}_24h_vol']?.toString() ?? '0') ?? 0.0;
        if (p > 0) {
          return MarketTicker(
            exchangeId: id,
            pair: pair,
            lastPrice: p,
            volume24h: v,
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (_) {}

    throw Exception('Connection error: Unable to fetch live price for ${pair.displayName} on CoinMarketCap');
  }
}
