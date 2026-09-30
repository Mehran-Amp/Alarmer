import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/standard_rest_exchange.dart';
import '../binance/binance_exchange.dart';
import '../coinbase/coinbase_exchange.dart';
import '../coingecko/coingecko_exchange.dart';
import '../kucoin/kucoin_exchange.dart';
import '../nobitex/nobitex_exchange.dart';
import '../stocks/global_stocks_exchange.dart';

/// Complete Catalog of 40+ cryptocurrency exchanges and global stock & commodity markets
class ExchangeCatalog {
  static List<Exchange> buildAllExchanges() {
    return [
      // --- GLOBAL STOCKS & COMMODITIES (NASDAQ, NYSE, Gold, Oil, S&P500) ---
      GlobalStocksExchange(),

      // --- TIER 1 GLOBAL EXCHANGES ---
      BinanceExchange(),
      CoinbaseExchange(),
      KuCoinExchange(),
      StandardRestExchange(
        id: 'kraken',
        name: 'Kraken',
        category: ExchangeCategory.tier1,
        countryBadge: '🇺🇸 USA / EU',
        defaultCounterCurrency: 'USD',
        fallbackPairs: _majorPairs(['USD', 'EUR', 'USDT']),
      ),
      StandardRestExchange(
        id: 'okx',
        name: 'OKX (OKCoin)',
        category: ExchangeCategory.tier1,
        countryBadge: '🌐 Global',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT', 'BTC']),
      ),
      StandardRestExchange(
        id: 'bybit',
        name: 'Bybit',
        category: ExchangeCategory.tier1,
        countryBadge: '🇦🇪 UAE / Global',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT', 'USDC']),
      ),
      StandardRestExchange(
        id: 'bitfinex',
        name: 'Bitfinex',
        category: ExchangeCategory.tier1,
        countryBadge: '🇭🇰 Hong Kong',
        defaultCounterCurrency: 'USD',
        fallbackPairs: _majorPairs(['USD', 'USDT']),
      ),
      StandardRestExchange(
        id: 'bitstamp',
        name: 'Bitstamp',
        category: ExchangeCategory.tier1,
        countryBadge: '🇱🇺 Luxembourg / EU',
        defaultCounterCurrency: 'USD',
        fallbackPairs: _majorPairs(['USD', 'EUR']),
      ),
      StandardRestExchange(
        id: 'gateio',
        name: 'Gate.io',
        category: ExchangeCategory.tier1,
        countryBadge: '🌐 Global',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT']),
      ),
      StandardRestExchange(
        id: 'mexc',
        name: 'MEXC Global',
        category: ExchangeCategory.tier1,
        countryBadge: '🌐 Global',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT']),
      ),
      StandardRestExchange(
        id: 'huobi',
        name: 'HTX (Huobi)',
        category: ExchangeCategory.tier1,
        countryBadge: '🌐 Global',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT']),
      ),
      StandardRestExchange(
        id: 'bitget',
        name: 'Bitget',
        category: ExchangeCategory.tier1,
        countryBadge: '🇸🇬 Singapore / Global',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT']),
      ),
      StandardRestExchange(
        id: 'gemini',
        name: 'Gemini',
        category: ExchangeCategory.tier1,
        countryBadge: '🇺🇸 USA',
        defaultCounterCurrency: 'USD',
        fallbackPairs: _majorPairs(['USD']),
      ),
      StandardRestExchange(
        id: 'poloniex',
        name: 'Poloniex',
        category: ExchangeCategory.tier1,
        countryBadge: '🌐 Global',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT', 'BTC']),
      ),
      StandardRestExchange(
        id: 'bingx',
        name: 'BingX',
        category: ExchangeCategory.tier1,
        countryBadge: '🌐 Global',
        defaultCounterCurrency: 'USDT',
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
      StandardRestExchange(
        id: 'cryptocompare',
        name: 'CryptoCompare',
        category: ExchangeCategory.aggregator,
        countryBadge: '📊 Aggregator',
        defaultCounterCurrency: 'USD',
        fallbackPairs: _majorPairs(['USD', 'EUR']),
      ),

      // --- IRAN & MIDDLE EAST ---
      NobitexExchange(),
      StandardRestExchange(
        id: 'wallex',
        name: 'Wallex (والکس)',
        category: ExchangeCategory.middleEast,
        countryBadge: '🇮🇷 Iran',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT', 'TMN']),
      ),
      StandardRestExchange(
        id: 'tabdeal',
        name: 'Tabdeal (تبدیل)',
        category: ExchangeCategory.middleEast,
        countryBadge: '🇮🇷 Iran',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT', 'TMN']),
      ),
      StandardRestExchange(
        id: 'coinex',
        name: 'CoinEx',
        category: ExchangeCategory.middleEast,
        countryBadge: '🌐 Middle East Friendly',
        defaultCounterCurrency: 'USDT',
        fallbackPairs: _majorPairs(['USDT', 'USDC']),
      ),

      // --- ASIA & PACIFIC ---
      StandardRestExchange(
        id: 'upbit',
        name: 'Upbit',
        category: ExchangeCategory.asia,
        countryBadge: '🇰🇷 South Korea',
        defaultCounterCurrency: 'KRW',
        fallbackPairs: _majorPairs(['KRW', 'USDT']),
      ),
      StandardRestExchange(
        id: 'bithumb',
        name: 'Bithumb',
        category: ExchangeCategory.asia,
        countryBadge: '🇰🇷 South Korea',
        defaultCounterCurrency: 'KRW',
        fallbackPairs: _majorPairs(['KRW']),
      ),
      StandardRestExchange(
        id: 'bitflyer',
        name: 'bitFlyer',
        category: ExchangeCategory.asia,
        countryBadge: '🇯🇵 Japan',
        defaultCounterCurrency: 'JPY',
        fallbackPairs: _majorPairs(['JPY', 'USD']),
      ),
      StandardRestExchange(
        id: 'zaif',
        name: 'Zaif',
        category: ExchangeCategory.asia,
        countryBadge: '🇯🇵 Japan',
        defaultCounterCurrency: 'JPY',
        fallbackPairs: _majorPairs(['JPY']),
      ),
      StandardRestExchange(
        id: 'wazirx',
        name: 'WazirX',
        category: ExchangeCategory.asia,
        countryBadge: '🇮🇳 India',
        defaultCounterCurrency: 'INR',
        fallbackPairs: _majorPairs(['INR', 'USDT']),
      ),
      StandardRestExchange(
        id: 'indodax',
        name: 'Indodax',
        category: ExchangeCategory.asia,
        countryBadge: '🇮🇩 Indonesia',
        defaultCounterCurrency: 'IDR',
        fallbackPairs: _majorPairs(['IDR', 'USDT']),
      ),
      StandardRestExchange(
        id: 'bitkub',
        name: 'Bitkub',
        category: ExchangeCategory.asia,
        countryBadge: '🇹🇭 Thailand',
        defaultCounterCurrency: 'THB',
        fallbackPairs: _majorPairs(['THB', 'USDT']),
      ),

      // --- EUROPE ---
      StandardRestExchange(
        id: 'bitvavo',
        name: 'Bitvavo',
        category: ExchangeCategory.europe,
        countryBadge: '🇳🇱 Netherlands',
        defaultCounterCurrency: 'EUR',
        fallbackPairs: _majorPairs(['EUR']),
      ),
      StandardRestExchange(
        id: 'bitpanda',
        name: 'Bitpanda',
        category: ExchangeCategory.europe,
        countryBadge: '🇦🇹 Austria',
        defaultCounterCurrency: 'EUR',
        fallbackPairs: _majorPairs(['EUR']),
      ),
      StandardRestExchange(
        id: 'bitcoinde',
        name: 'Bitcoin.de',
        category: ExchangeCategory.europe,
        countryBadge: '🇩🇪 Germany',
        defaultCounterCurrency: 'EUR',
        fallbackPairs: _majorPairs(['EUR']),
      ),
      StandardRestExchange(
        id: 'paymium',
        name: 'Paymium',
        category: ExchangeCategory.europe,
        countryBadge: '🇫🇷 France',
        defaultCounterCurrency: 'EUR',
        fallbackPairs: _majorPairs(['EUR']),
      ),
      StandardRestExchange(
        id: 'exmo',
        name: 'EXMO',
        category: ExchangeCategory.europe,
        countryBadge: '🇬🇧 United Kingdom',
        defaultCounterCurrency: 'USD',
        fallbackPairs: _majorPairs(['USD', 'EUR', 'USDT']),
      ),

      // --- AMERICAS & OTHERS ---
      StandardRestExchange(
        id: 'mercadobitcoin',
        name: 'Mercado Bitcoin',
        category: ExchangeCategory.americas,
        countryBadge: '🇧🇷 Brazil',
        defaultCounterCurrency: 'BRL',
        fallbackPairs: _majorPairs(['BRL']),
      ),
      StandardRestExchange(
        id: 'foxbit',
        name: 'Foxbit',
        category: ExchangeCategory.americas,
        countryBadge: '🇧🇷 Brazil',
        defaultCounterCurrency: 'BRL',
        fallbackPairs: _majorPairs(['BRL']),
      ),
      StandardRestExchange(
        id: 'bitso',
        name: 'Bitso',
        category: ExchangeCategory.americas,
        countryBadge: '🇲🇽 Mexico / LatAm',
        defaultCounterCurrency: 'MXN',
        fallbackPairs: _majorPairs(['MXN', 'USD']),
      ),
      StandardRestExchange(
        id: 'ndax',
        name: 'NDAX',
        category: ExchangeCategory.americas,
        countryBadge: '🇨🇦 Canada',
        defaultCounterCurrency: 'CAD',
        fallbackPairs: _majorPairs(['CAD']),
      ),
      StandardRestExchange(
        id: 'luno',
        name: 'Luno',
        category: ExchangeCategory.americas,
        countryBadge: '🇿🇦 South Africa / Global',
        defaultCounterCurrency: 'ZAR',
        fallbackPairs: _majorPairs(['ZAR', 'USD', 'EUR']),
      ),
      StandardRestExchange(
        id: 'valr',
        name: 'VALR',
        category: ExchangeCategory.americas,
        countryBadge: '🇿🇦 South Africa',
        defaultCounterCurrency: 'ZAR',
        fallbackPairs: _majorPairs(['ZAR', 'USDT']),
      ),
    ];
  }

  static List<CurrencyPair> _majorPairs(List<String> counters) {
    final bases = ['BTC', 'ETH', 'SOL', 'BNB', 'XRP', 'DOGE', 'ADA', 'AVAX', 'DOT', 'LINK', 'TON', 'SUI', 'PEPE', 'SHIB', 'TRX', 'NEAR', 'LTC', 'BCH', 'UNI', 'ATOM'];
    final pairs = <CurrencyPair>[];
    for (final counter in counters) {
      for (final base in bases) {
        pairs.add(CurrencyPair(
          baseCurrency: base,
          counterCurrency: counter,
          marketSymbol: '$base/$counter',
        ));
      }
    }
    return pairs;
  }
}
