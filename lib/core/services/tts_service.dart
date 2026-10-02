import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Text-to-Speech (TTS) Voice Announcer Service.
/// Always vocalizes in English with clean, clear pronunciation.
///
/// Reading Pattern:
/// [Asset Name] [Price] [Currency] (+ [Optional Note])
///
/// Famous assets are spoken with their full authentic name (e.g. Bitcoin, Ethereum, Apple, Gold).
/// Unlisted tickers are pronounced letter-by-letter (e.g. "W I F", "O N D O").
class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  static const MethodChannel _channel = MethodChannel('com.example.bitcoin_checker/app_lifecycle');

  // Comprehensive Pronunciation Dictionary for Famous Assets
  static const Map<String, String> _famousAssetNames = {
    // 1. Top Cryptocurrencies
    'BTC': 'Bitcoin',
    'XBT': 'Bitcoin',
    'BITCOIN': 'Bitcoin',
    'ETH': 'Ethereum',
    'ETHEREUM': 'Ethereum',
    'SOL': 'Solana',
    'SOLANA': 'Solana',
    'BNB': 'BNB',
    'XRP': 'Ripple',
    'RIPPLE': 'Ripple',
    'DOGE': 'Dogecoin',
    'DOGECOIN': 'Dogecoin',
    'ADA': 'Cardano',
    'CARDANO': 'Cardano',
    'AVAX': 'Avalanche',
    'AVALANCHE': 'Avalanche',
    'DOT': 'Polkadot',
    'POLKADOT': 'Polkadot',
    'TON': 'Toncoin',
    'TONCOIN': 'Toncoin',
    'SUI': 'Sui',
    'APT': 'Aptos',
    'APTOS': 'Aptos',
    'NEAR': 'Near Protocol',
    'LINK': 'Chainlink',
    'CHAINLINK': 'Chainlink',
    'TRX': 'Tron',
    'TRON': 'Tron',
    'LTC': 'Litecoin',
    'LITECOIN': 'Litecoin',
    'BCH': 'Bitcoin Cash',
    'UNI': 'Uniswap',
    'UNISWAP': 'Uniswap',
    'ATOM': 'Cosmos',
    'COSMOS': 'Cosmos',
    'TIA': 'Celestia',
    'CELESTIA': 'Celestia',
    'SEI': 'Sei',
    'SHIB': 'Shiba Inu',
    'SHIBA': 'Shiba Inu',
    'PEPE': 'Pepe',
    'ICP': 'Internet Computer',
    'XLM': 'Stellar',
    'STELLAR': 'Stellar',
    'ETC': 'Ethereum Classic',
    'FIL': 'Filecoin',
    'HBAR': 'Hedera',
    'KAS': 'Kaspa',
    'POL': 'Polygon',
    'MATIC': 'Polygon',
    'POLYGON': 'Polygon',
    'RENDER': 'Render',
    'RNDR': 'Render',
    'FET': 'Artificial Superintelligence',
    'ASI': 'Artificial Superintelligence',
    'AGIX': 'Artificial Superintelligence',
    'OCEAN': 'Artificial Superintelligence',
    'INJ': 'Injective',
    'ALGO': 'Algorand',
    'XMR': 'Monero',
    'MONERO': 'Monero',
    'ARB': 'Arbitrum',
    'OP': 'Optimism',
    'AAVE': 'Aave',
    'MKR': 'Maker',
    'SKY': 'Maker',
    'FTM': 'Fantom',
    'S': 'Sonic',
    'SAND': 'Sandbox',
    'MANA': 'Decentraland',
    'VET': 'VeChain',
    'GRT': 'The Graph',
    'THETA': 'Theta',
    'FLOKI': 'Floki',
    'BONK': 'Bonk',
    'WIF': 'Dogwifhat',
    'JUP': 'Jupiter',
    'PENDLE': 'Pendle',
    'ONDO': 'Ondo',
    'CRV': 'Curve',
    'DYDX': 'dYdX',
    'STX': 'Stacks',
    'KAVA': 'Kava',
    'IMX': 'Immutable X',
    'AXS': 'Axie Infinity',
    'EGLD': 'MultiversX',
    'GALA': 'Gala',

    // 2. Global Stocks & Equities
    'AAPL': 'Apple',
    'TSLA': 'Tesla',
    'NVDA': 'Nvidia',
    'MSFT': 'Microsoft',
    'AMZN': 'Amazon',
    'GOOGL': 'Google',
    'GOOG': 'Google',
    'META': 'Meta',
    'NFLX': 'Netflix',
    'AMD': 'AMD',
    'INTC': 'Intel',
    'COIN': 'Coinbase',
    'MSTR': 'MicroStrategy',
    'BABA': 'Alibaba',
    'DIS': 'Disney',
    'PYPL': 'PayPal',
    'UBER': 'Uber',
    'ARM': 'Arm',
    'PLTR': 'Palantir',

    // 3. Commodities, Indices & Forex
    'GOLD': 'Gold',
    'XAU': 'Gold',
    'SILVER': 'Silver',
    'XAG': 'Silver',
    'OIL': 'Crude Oil',
    'WTI': 'Crude Oil',
    'BRENT': 'Brent Oil',
    'SPX': 'S and P 500',
    'SPY': 'S and P 500',
    'NDX': 'Nasdaq',
    'QQQ': 'Nasdaq',
    'DJI': 'Dow Jones',
    'DIA': 'Dow Jones',
    'DXY': 'Dollar Index',
    'EURUSD': 'Euro Dollar',
    'GBPUSD': 'Pound Dollar',
    'USDJPY': 'Dollar Yen',
  };

  /// Builds clean English voice speech sentence for an alert.
  /// Pattern: [Asset Name] [Price] [Currency] (+ Note)
  static String buildAlertSpeech({
    required String symbol,
    required double price,
    String lang = 'en',
    String? baseCurrency,
    String? counterCurrency,
    String? customNote,
  }) {
    // 1. Resolve base asset and quote currency
    String base;
    String counter;

    if (baseCurrency != null && baseCurrency.isNotEmpty) {
      base = baseCurrency.toUpperCase().trim();
    } else if (symbol.contains('/')) {
      base = symbol.split('/')[0].toUpperCase().trim();
    } else if (symbol.contains('-')) {
      base = symbol.split('-')[0].toUpperCase().trim();
    } else {
      base = symbol.toUpperCase().trim();
    }

    if (counterCurrency != null && counterCurrency.isNotEmpty) {
      counter = counterCurrency.toUpperCase().trim();
    } else if (symbol.contains('/')) {
      counter = symbol.split('/')[1].toUpperCase().trim();
    } else if (symbol.contains('-')) {
      counter = symbol.split('-')[1].toUpperCase().trim();
    } else {
      counter = 'USD';
    }

    // 2. Resolve Asset Pronunciation (Famous full name or letter-by-letter)
    final spokenAssetName = _getSpokenAssetName(base);

    // 3. Resolve Currency Pronunciation
    final spokenCurrency = _getSpokenCurrency(counter);

    // 4. Format Price
    final String priceStr;
    if (price >= 1000) {
      priceStr = price.toStringAsFixed(0);
    } else if (price >= 1) {
      priceStr = price.toStringAsFixed(2);
    } else if (price >= 0.0001) {
      priceStr = price.toStringAsFixed(4);
    } else {
      priceStr = price.toStringAsFixed(6);
    }

    // 5. Build Final Pattern: [Asset Name] [Price] [Currency]
    var sentence = '$spokenAssetName $priceStr $spokenCurrency';

    // Append custom note if available
    if (customNote != null && customNote.trim().isNotEmpty) {
      sentence += '. Note: ${customNote.trim()}';
    }

    return sentence;
  }

  /// Pronounces famous assets with full name, or spells unlisted tickers letter-by-letter
  static String _getSpokenAssetName(String baseSymbol) {
    final clean = baseSymbol.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (_famousAssetNames.containsKey(clean)) {
      return _famousAssetNames[clean]!;
    }
    // Spell out letter-by-letter with space separation (e.g. "W I F", "J U P")
    if (clean.length <= 5) {
      return clean.split('').join(' ');
    }
    return clean;
  }

  /// Returns natural spoken currency word
  static String _getSpokenCurrency(String counterSymbol) {
    final c = counterSymbol.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    switch (c) {
      case 'USDT':
      case 'USD':
      case 'USDC':
      case 'BUSD':
      case 'DAI':
      case 'FDUSD':
        return 'dollars';
      case 'EUR':
        return 'euros';
      case 'GBP':
        return 'pounds';
      case 'JPY':
        return 'yen';
      case 'TMN':
      case 'IRT':
      case 'TOMAN':
        return 'toman';
      case 'BTC':
      case 'XBT':
        return 'bitcoin';
      case 'ETH':
        return 'ethereum';
      case 'TRY':
        return 'lira';
      case 'AUD':
        return 'Australian dollars';
      case 'CAD':
        return 'Canadian dollars';
      case 'CHF':
        return 'Swiss francs';
      case 'CNY':
      case 'RMB':
        return 'yuan';
      default:
        if (c.length <= 4) {
          return c.split('').join(' ');
        }
        return c;
    }
  }

  /// Speaks the given text using the platform English TTS engine
  Future<void> speak({
    required String text,
    String lang = 'en',
    double rate = 1.0,
    double pitch = 1.0,
  }) async {
    try {
      debugPrint('[TTS] Speaking (English): "$text"');
      await _channel.invokeMethod('speak', {
        'text': text,
        'lang': 'en',
        'rate': rate,
        'pitch': pitch,
      });
    } catch (e) {
      debugPrint('[TTS] Error invoking speak: $e');
    }
  }

  /// Stops any currently playing speech
  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopSpeak');
    } catch (_) {}
  }

  /// Plays a quick voice test utterance in English
  Future<void> testVoice([String lang = 'en']) async {
    final sample = buildAlertSpeech(
      symbol: 'BTC/USDT',
      baseCurrency: 'BTC',
      counterCurrency: 'USDT',
      price: 87420.0,
      customNote: 'Take profit',
    );
    await speak(text: sample, lang: 'en');
  }
}
