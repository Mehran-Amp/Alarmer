import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/standard_rest_exchange.dart';
import '../binance/binance_exchange.dart';
import '../bybit/bybit_exchange.dart';
import '../coinbase/coinbase_exchange.dart';
import '../coingecko/coingecko_exchange.dart';
import '../kucoin/kucoin_exchange.dart';
import '../nobitex/nobitex_exchange.dart';
import '../okx/okx_exchange.dart';
import '../stocks/global_stocks_exchange.dart';
import '../wallex/wallex_exchange.dart';

/// Complete Catalog of verified cryptocurrency exchanges and global stock & commodity markets
class ExchangeCatalog {
  static List<Exchange> buildAllExchanges() {
    return [
      // --- GLOBAL STOCKS, METALS, FOREX & COMMODITIES ---
      GlobalStocksExchange(),

      // --- TIER 1 GLOBAL EXCHANGES ---
      BinanceExchange(),
      CoinbaseExchange(),
      KuCoinExchange(),
      OKXExchange(),
      BybitExchange(),
      StandardRestExchange(
        id: 'kraken',
        name: 'Kraken',
        category: ExchangeCategory.tier1,
        countryBadge: '🇺🇸 USA / EU',
        defaultCounterCurrency: 'USD',
        pairsUrl: 'https://api.kraken.com/0/public/AssetPairs',
        fallbackPairs: _majorPairs(['USD', 'EUR', 'USDT']),
      ),
      StandardRestExchange(
        id: 'gateio',
        name: 'Gate.io',
        category: ExchangeCategory.tier1,
        countryBadge: '🌐 Global',
        defaultCounterCurrency: 'USDT',
        tickerUrlTemplate: 'https://api.gateio.ws/api/v4/spot/tickers?currency_pair={BASE_UPPER}_{QUOTE_UPPER}',
        pairsUrl: 'https://api.gateio.ws/api/v4/spot/currency_pairs',
        fallbackPairs: _majorPairs(['USDT']),
      ),
      StandardRestExchange(
        id: 'mexc',
        name: 'MEXC Global',
        category: ExchangeCategory.tier1,
        countryBadge: '🌐 Global',
        defaultCounterCurrency: 'USDT',
        tickerUrlTemplate: 'https://api.mexc.com/api/v3/ticker/24hr?symbol={BASE_UPPER}{QUOTE_UPPER}',
        pairsUrl: 'https://api.mexc.com/api/v3/defaultSymbols',
        fallbackPairs: _majorPairs(['USDT']),
      ),

      // --- GLOBAL AGGREGATORS ---
      CoinGeckoExchange(),
      StandardRestExchange(
        id: 'coinmarketcap',
        name: 'CoinMarketCap',
        category: ExchangeCategory.aggregator,
        countryBadge: '📊 Global Index',
        defaultCounterCurrency: 'USD',
        fallbackPairs: _majorPairs(['USD', 'USDT']),
      ),

      // --- IRAN & MIDDLE EAST ---
      NobitexExchange(),
      WallexExchange(),
      StandardRestExchange(
        id: 'coinex',
        name: 'CoinEx',
        category: ExchangeCategory.middleEast,
        countryBadge: '🌐 Middle East Friendly',
        defaultCounterCurrency: 'USDT',
        tickerUrlTemplate: 'https://api.coinex.com/v1/market/ticker?market={BASE_UPPER}{QUOTE_UPPER}',
        fallbackPairs: _majorPairs(['USDT', 'USDC']),
      ),
    ];
  }

  static List<CurrencyPair> _majorPairs(List<String> counters) {
    const bases = [
      'BTC', 'ETH', 'SOL', 'TON', 'XRP', 'DOGE', 'TRX', 'SHIB', 'PEPE',
      'ADA', 'BNB', 'NOT', 'SUI', 'AVAX', 'NEAR', 'LINK', 'DOT', 'BCH',
      'LTC', 'UNI', 'ATOM', 'FET', 'APT', 'ARB', 'OP', 'TIA', 'INJ',
      'FTM', 'ALGO', 'ICP', 'ETC', 'XLM', 'FIL', 'FLOKI', 'BONK', 'WIF',
    ];

    final list = <CurrencyPair>[];
    for (final b in bases) {
      for (final c in counters) {
        list.add(CurrencyPair(
          baseCurrency: b,
          counterCurrency: c,
          marketSymbol: '$b$c',
        ));
      }
    }
    return list;
  }
}
