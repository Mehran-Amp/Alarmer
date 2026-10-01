import '../base/crypto_catalog_data.dart';
import '../base/currency_pair.dart';
import '../base/exchange.dart';
import '../base/exchange_category.dart';
import '../base/standard_rest_exchange.dart';
import '../binance/binance_exchange.dart';
import '../bingx/bingx_exchange.dart';
import '../bitbarg/bitbarg_exchange.dart';
import '../bitget/bitget_exchange.dart';
import '../bybit/bybit_exchange.dart';
import '../coinbase/coinbase_exchange.dart';
import '../coinex/coinex_exchange.dart';
import '../coingecko/coingecko_exchange.dart';
import '../coinmarketcap/coinmarketcap_exchange.dart';
import '../gateio/gateio_exchange.dart';
import '../kraken/kraken_exchange.dart';
import '../kucoin/kucoin_exchange.dart';
import '../mexc/mexc_exchange.dart';
import '../nobitex/nobitex_exchange.dart';
import '../okx/okx_exchange.dart';
import '../stocks/global_stocks_exchange.dart';
import '../tabdeal/tabdeal_exchange.dart';
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
      KuCoinExchange(),
      OKXExchange(),
      BybitExchange(),
      MEXCExchange(),
      GateioExchange(),
      BingXExchange(),
      BitgetExchange(),
      CoinbaseExchange(),
      KrakenExchange(),

      // --- GLOBAL AGGREGATORS & BENCHMARKS ---
      CoinMarketCapExchange(),
      CoinGeckoExchange(),

      // --- IRAN & MIDDLE EAST (Full Catalog & Live API) ---
      NobitexExchange(),
      WallexExchange(),
      TabdealExchange(),
      BitbargExchange(),
      CoinExExchange(),
    ];
  }
}
