import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Text-to-Speech (TTS) Voice Announcer Service.
/// Generates and vocalizes natural spoken market voice announcements for critical trade alerts.
class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  static const MethodChannel _channel = MethodChannel('com.example.bitcoin_checker/app_lifecycle');

  /// Formats natural language voice sentence for an alert
  static String buildAlertSpeech({
    required String symbol,
    required double price,
    required String lang,
    String? conditionText,
    String? customNote,
  }) {
    final cleanSym = symbol.replaceAll('_', ' ').replaceAll('-', ' ');
    final priceStr = price >= 1000 ? price.toStringAsFixed(0) : price.toStringAsFixed(2);

    if (lang == 'fa') {
      if (customNote != null && customNote.trim().isNotEmpty) {
        return 'هشدار $cleanSym: $customNote. قیمت فعلی: $priceStr';
      }
      return 'توجه، هشدار برای نماد $cleanSym فعال شد. قیمت فعلی: $priceStr دلار.';
    } else if (lang == 'ar') {
      return 'تنبيه، تم تفعيل الإنذار للرمز $cleanSym. السعر الحالي: $priceStr دولار.';
    } else if (lang == 'ckb') {
      return 'ئاگاداربە، ئاگادارکەرەوە بۆ $cleanSym چالاک بوو. نرخی ئێستا: $priceStr.';
    } else if (lang == 'de') {
      return 'Achtung, Alarm ausgelöst für $cleanSym. Aktueller Preis: $priceStr Dollar.';
    } else if (lang == 'tr') {
      return 'Dikkat, $cleanSym için alarm tetiklendi. Güncel fiyat: $priceStr dolar.';
    } else if (lang == 'es') {
      return 'Atención, alerta activada para $cleanSym. Precio actual: $priceStr dólares.';
    } else if (lang == 'fr') {
      return 'Attention, alerte déclenchée pour $cleanSym. Prix actuel: $priceStr dollars.';
    } else if (lang == 'zh') {
      return '请注意，$cleanSym 警报已触发。当前价格：$priceStr 美元。';
    } else if (lang == 'ru') {
      return 'Внимание, сработал сигнал для $cleanSym. Текущая цена: $priceStr долларов.';
    } else {
      if (customNote != null && customNote.trim().isNotEmpty) {
        return 'Alert for $cleanSym: $customNote. Current price: $priceStr dollars.';
      }
      return 'Attention, price alert triggered for $cleanSym. Current price is $priceStr dollars.';
    }
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
      price: 87420.0,
      lang: lang,
      customNote: lang == 'fa' ? 'رسیدن به تارگت سود' : 'Take Profit',
    );
    await speak(text: sample, lang: lang);
  }
}
