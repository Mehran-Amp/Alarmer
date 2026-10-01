import 'currency_pair.dart';

/// Exhaustive list of top cryptocurrencies across major global & Iranian exchanges
class CryptoCatalogData {
  static const List<String> topCoins = [
    // Layer 1 & Bluechips
    'BTC', 'ETH', 'SOL', 'BNB', 'XRP', 'DOGE', 'TON', 'TRX', 'ADA', 'AVAX',
    'SUI', 'LINK', 'BCH', 'DOT', 'NEAR', 'LTC', 'UNI', 'APT', 'FET', 'ICP',
    'POL', 'XLM', 'KAS', 'TAO', 'RENDER', 'ETC', 'ATOM', 'XMR', 'HBAR', 'FIL',
    
    // Layer 2 & Scaling
    'ARB', 'OP', 'TIA', 'INJ', 'FTM', 'ALGO', 'SEI', 'STRK', 'STX', 'BLUR',
    'IMX', 'LDO', 'MANTA', 'METIS', 'ZRO', 'BLAST', 'EVMOS',

    // Top Memecoins
    'SHIB', 'PEPE', 'WIF', 'BONK', 'FLOKI', 'NOT', 'POPCAT', 'MEW', 'NEIRO',
    'DOGS', 'HMSTR', 'CATI', 'TURBO', 'BABYDOGE', 'BRETT', 'GOAT', 'ACT', 'PNUT', 'BOME', 'ORDI', '1000SATS', 'MEME',

    // DeFi & Yield
    'AAVE', 'MKR', 'PENDLE', 'ENA', 'JUP', 'PYTH', 'RUNE', 'CRV', 'SNX', 'CAKE',
    '1INCH', 'ENS', 'COMP', 'YFI', 'DYDX', 'GNO', 'CVX', 'FXS', 'SUSHI', 'BAL',

    // AI & Compute
    'WLD', 'ARKM', 'AGIX', 'OCEAN', 'AKT', 'IO', 'NOS', 'SPEC', 'GLM',

    // Metaverse, Gaming & Web3 Infra
    'GRT', 'SAND', 'MANA', 'AXS', 'THETA', 'GALA', 'BEAM', 'RON', 'PIXEL', 'PORTAL',
    'AEVO', 'ETHFI', 'CHZ', 'FLOW', 'ENJ', 'SUPER', 'MASK', 'API3', 'ILV',

    // Privacy & Classical Alts
    'ZEC', 'DASH', 'KSM', 'ROSE', 'WOO', 'CFX', 'GMT', 'JASMY', 'LRC', 'BAT',
    'QTUM', 'BTT', 'HOT', 'ANKR', 'SC', 'GLMR', 'MINA', 'OSMO', 'KAVA', 'LPT', 'CELO', 'ZIL',
  ];

  /// Generates pairs for a given list of base coins and quote currencies
  static List<CurrencyPair> buildPairs({
    required List<String> quoteCurrencies,
    String Function(String base, String quote)? symbolFormatter,
  }) {
    final pairs = <CurrencyPair>[];
    for (final base in topCoins) {
      for (final quote in quoteCurrencies) {
        if (base.toUpperCase() != quote.toUpperCase()) {
          final sym = symbolFormatter != null
              ? symbolFormatter(base, quote)
              : '$base$quote';
          pairs.add(CurrencyPair(
            baseCurrency: base,
            counterCurrency: quote,
            marketSymbol: sym,
          ));
        }
      }
    }
    return pairs;
  }
}
