import '../base/crypto_catalog_data.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/standard_rest_exchange.dart';
import '../binance/binance_exchange.dart';
import '../bybit/bybit_exchange.dart';
import '../coinbase/coinbase_exchange.dart';
import '../coinex/coinex_exchange.dart';
import '../coingecko/coingecko_exchange.dart';
import '../gateio/gateio_exchange.dart';
import '../kraken/kraken_exchange.dart';
import '../kucoin/kucoin_exchange.dart';
import '../mexc/mexc_exchange.dart';
import '../nobitex/nobitex_exchange.dart';
import '../okx/okx_exchange.dart';
import '../stocks/global_stocks_exchange.dart';
import '../wallex/wallex_exchange.dart';

/// Complete Catalog of verified cryptocurrency exchanges and global stock & commodity markets.
/// Provides unrestricted access to all spot assets on each exchange without artificial limits.
class ExchangeCatalog {
  static List<Exchange> buildAllExchanges() {
    return [
      // --- GLOBAL STOCKS, METALS, FOREX & COMMODITIES ---
      GlobalStocksExchange(),

      // --- TIER 1 GLOBAL CRYPTO EXCHANGES (Full Catalog & Live API) ---
      BinanceExchange(),
      MEXCExchange(),
      GateioExchange(),
      KuCoinExchange(),
      OKXExchange(),
      BybitExchange(),
      CoinbaseExchange(),
      KrakenExchange(),

      // --- GLOBAL AGGREGATORS ---
      CoinGeckoExchange(),
      StandardRestExchange(
        id: 'coinmarketcap',
        name: 'CoinMarketCap',
        category: ExchangeCategory.aggregator,
        countryBadge: '📊 Global Index',
        defaultCounterCurrency: 'USD',
        fallbackPairs: CryptoCatalogData.buildPairs(quoteCurrencies: ['USD', 'USDT']),
      ),

      // --- IRAN & MIDDLE EAST (Full Catalog & Live API) ---
      NobitexExchange(),
      WallexExchange(),
      CoinExExchange(),
    ];
  }
}
