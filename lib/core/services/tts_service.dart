import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/crypto_icons.dart';

/// Text-to-Speech (TTS) Voice Announcer Service.
/// Generates and vocalizes natural spoken market voice announcements for critical trade alerts.
/// Structure: [Symbol] + [Current Price text] + [Price + Currency] (+ Optional Custom Note)
class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  static const MethodChannel _channel = MethodChannel('com.example.bitcoin_checker/app_lifecycle');

  /// Formats natural language voice sentence for an alert across all supported app languages
  static String buildAlertSpeech({
    required String symbol,
    required double price,
    required String lang,
    String? baseCurrency,
    String? counterCurrency,
    String? customNote,
  }) {
    // Determine clean asset symbol/name
    final base = (baseCurrency != null && baseCurrency.isNotEmpty)
        ? baseCurrency.toUpperCase()
        : (symbol.contains('/') ? symbol.split('/')[0].trim().toUpperCase() : symbol.trim().toUpperCase());

    final counter = (counterCurrency != null && counterCurrency.isNotEmpty)
        ? counterCurrency.toUpperCase()
        : (symbol.contains('/') ? symbol.split('/')[1].trim().toUpperCase() : 'USDT');

    final assetName = _getLocalizedAssetName(base, lang);
    final currencyName = _getLocalizedCurrencyName(counter, lang);

    // Format price without trailing decimals for whole numbers or 2 decimals for small fractions
    final String priceStr;
    if (price >= 1000) {
      priceStr = price.toInt().toString();
    } else if (price >= 1) {
      priceStr = price.toStringAsFixed(2);
    } else {
      priceStr = price.toStringAsFixed(4);
    }

    // Exact structured template across all 10 languages:
    // [Symbol] + [Current Price text] + [Price + Currency]
    String text;
    String notePart = '';

    final hasNote = customNote != null && customNote.trim().isNotEmpty;

    switch (lang) {
      case 'fa':
        if (hasNote) notePart = '. یادداشت: ${customNote.trim()}';
        text = '$assetName، قیمت فعلی $priceStr $currencyName$notePart';
        break;

      case 'ar':
        if (hasNote) notePart = '. ملاحظة: ${customNote.trim()}';
        text = '$assetName، السعر الحالي $priceStr $currencyName$notePart';
        break;

      case 'ckb':
        if (hasNote) notePart = '. تێبینی: ${customNote.trim()}';
        text = '$assetName، نرخی ئێستا $priceStr $currencyName$notePart';
        break;

      case 'tr':
        if (hasNote) notePart = '. Not: ${customNote.trim()}';
        text = '$assetName, güncel fiyat $priceStr $currencyName$notePart';
        break;

      case 'es':
        if (hasNote) notePart = '. Nota: ${customNote.trim()}';
        text = '$assetName, precio actual $priceStr $currencyName$notePart';
        break;

      case 'de':
        if (hasNote) notePart = '. Notiz: ${customNote.trim()}';
        text = '$assetName, aktueller Preis $priceStr $currencyName$notePart';
        break;

      case 'fr':
        if (hasNote) notePart = '. Note: ${customNote.trim()}';
        text = '$assetName, prix actuel $priceStr $currencyName$notePart';
        break;

      case 'ru':
        if (hasNote) notePart = '. Заметка: ${customNote.trim()}';
        text = '$assetName, текущая цена $priceStr $currencyName$notePart';
        break;

      case 'zh':
        if (hasNote) notePart = '。备注: ${customNote.trim()}';
        text = '$assetName，当前价格 $priceStr $currencyName$notePart';
        break;

      case 'en':
      default:
        if (hasNote) notePart = '. Note: ${customNote.trim()}';
        text = '$assetName, current price $priceStr $currencyName$notePart';
        break;
    }

    return text;
  }

  static String _getLocalizedAssetName(String base, String lang) {
    if (lang == 'fa') {
      switch (base) {
        case 'BTC':
        case 'XBT':
          return 'بیت کوین';
        case 'ETH':
          return 'اتریوم';
        case 'SOL':
          return 'سولانا';
        case 'BNB':
          return 'بی ان بی';
        case 'XRP':
          return 'ریپل';
        case 'DOGE':
          return 'دوج کوین';
        case 'ADA':
          return 'کاردانو';
        case 'TON':
          return 'تون کوین';
        case 'TRX':
          return 'ترون';
        case 'SHIB':
          return 'شیبا اینو';
        case 'PEPE':
          return 'پپه';
        case 'AVAX':
          return 'آوالانچ';
        case 'DOT':
          return 'پولکادات';
        case 'NEAR':
          return 'نیر';
        case 'LINK':
          return 'چین لینک';
        case 'LTC':
          return 'لایت کوین';
        case 'BCH':
          return 'بیت کوین کش';
        case 'SUI':
          return 'سویی';
        case 'APT':
          return 'آپتوس';
        case 'ATOM':
          return 'کازموس';
        default:
          return CryptoIcons.getName(base);
      }
    } else if (lang == 'ar') {
      switch (base) {
        case 'BTC':
          return 'بتكوين';
        case 'ETH':
          return 'إيثريوم';
        case 'SOL':
          return 'سولانا';
        case 'BNB':
          return 'بي إن بي';
        case 'XRP':
          return 'ريبل';
        case 'DOGE':
          return 'دوجكوين';
        default:
          return CryptoIcons.getName(base);
      }
    } else if (lang == 'ckb') {
      switch (base) {
        case 'BTC':
          return 'بیتکۆین';
        case 'ETH':
          return 'ئیسریۆم';
        case 'SOL':
          return 'سۆلانا';
        case 'DOGE':
          return 'دۆجکۆین';
        default:
          return CryptoIcons.getName(base);
      }
    } else if (lang == 'zh') {
      switch (base) {
        case 'BTC':
          return '比特币';
        case 'ETH':
          return '以太坊';
        case 'SOL':
          return '索拉纳';
        case 'DOGE':
          return '狗狗币';
        case 'BNB':
          return '币安币';
        case 'XRP':
          return '瑞波币';
        default:
          return CryptoIcons.getName(base);
      }
    } else if (lang == 'ru') {
      switch (base) {
        case 'BTC':
          return 'Биткоин';
        case 'ETH':
          return 'Эфириум';
        case 'SOL':
          return 'Солана';
        case 'DOGE':
          return 'Догикоин';
        default:
          return CryptoIcons.getName(base);
      }
    }
    return CryptoIcons.getName(base);
  }

  static String _getLocalizedCurrencyName(String counter, String lang) {
    final c = counter.toUpperCase();
    if (c == 'USDT' || c == 'USD' || c == 'USDC' || c == 'BUSD' || c == 'DAI') {
      switch (lang) {
        case 'fa':
          return 'دلار';
        case 'ar':
          return 'دولار';
        case 'ckb':
          return 'دۆلار';
        case 'tr':
          return 'dolar';
        case 'es':
          return 'dólares';
        case 'de':
          return 'Dollar';
        case 'fr':
          return 'dollars';
        case 'ru':
          return 'долларов';
        case 'zh':
          return '美元';
        case 'en':
        default:
          return 'dollars';
      }
    } else if (c == 'TMN' || c == 'IRT' || c == 'TOMAN') {
      switch (lang) {
        case 'fa':
        case 'ar':
          return 'تومان';
        case 'ckb':
          return 'تمەن';
        case 'tr':
          return 'Tümen';
        case 'ru':
          return 'туманов';
        case 'zh':
          return '图曼';
        case 'en':
        default:
          return 'Toman';
      }
    } else if (c == 'EUR') {
      switch (lang) {
        case 'fa':
        case 'ar':
        case 'ckb':
          return 'یورو';
        case 'de':
        case 'tr':
          return 'Euro';
        case 'es':
        case 'fr':
        case 'en':
          return 'Euros';
        case 'ru':
          return 'евро';
        case 'zh':
          return '欧元';
        default:
          return 'Euro';
      }
    }
    return c;
  }

  /// Speaks the given text using the platform TTS engine
  Future<void> speak({
    required String text,
    required String lang,
    double rate = 1.0,
    double pitch = 1.0,
  }) async {
    try {
      debugPrint('[TTS] Speaking: "$text" (Lang: $lang)');
      await _channel.invokeMethod('speak', {
        'text': text,
        'lang': lang,
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

  /// Plays a quick voice test utterance in the selected language
  Future<void> testVoice(String lang) async {
    final sample = buildAlertSpeech(
      symbol: 'BTC/USDT',
      baseCurrency: 'BTC',
      counterCurrency: 'USDT',
      price: 87420.0,
      lang: lang,
      customNote: lang == 'fa' ? 'رسیدن به هدف' : 'Target reached',
    );
    await speak(text: sample, lang: lang);
  }
}
