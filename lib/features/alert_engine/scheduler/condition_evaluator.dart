import '../models/alert_rule.dart';
import '../models/trigger_mode.dart';

/// Result of evaluating an alert rule condition against current market data
class EvaluationResult {
  final bool isTriggered;
  final String title;
  final String message;
  final double? newBasePrice;
  final double? newBaseVolume;
  final bool newIsActive;
  final bool newIsTriggered;

  const EvaluationResult({
    required this.isTriggered,
    this.title = '',
    this.message = '',
    this.newBasePrice,
    this.newBaseVolume,
    this.newIsActive = true,
    this.newIsTriggered = false,
  });

  static const notTriggered = EvaluationResult(isTriggered: false);
}

/// Pure evaluation functions per condition type with color-coded emojis and arrow formatting.
abstract class ConditionEvaluator {
  /// Evaluates an [AlertRule] against current market price and volume
  static EvaluationResult evaluate({
    required AlertRule rule,
    required double currentPrice,
    double? currentVolume,
  }) {
    switch (rule.conditionType) {
      case AlertConditionType.priceThreshold:
        return _evaluatePriceThreshold(rule, currentPrice);
      case AlertConditionType.percentChange:
        return _evaluatePercentChange(rule, currentPrice);
      case AlertConditionType.absolutePriceChange:
        return _evaluateAbsolutePriceChange(rule, currentPrice);
      case AlertConditionType.volumeChange:
        return _evaluateVolumeChange(rule, currentVolume ?? 0.0);
    }
  }

  static String _formatVal(double val) {
    if (val.abs() >= 1000) {
      return val.toStringAsFixed(2);
    } else if (val.abs() >= 1) {
      return val.toStringAsFixed(val < 10 ? 3 : 2);
    } else {
      return val.toStringAsFixed(val < 0.01 ? 6 : 4);
    }
  }

  /// 1. Price Threshold (One-shot):
  static EvaluationResult _evaluatePriceThreshold(
    AlertRule rule,
    double currentPrice,
  ) {
    final target = rule.targetPrice ?? 0.0;
    if (target <= 0.0) return EvaluationResult.notTriggered;

    bool triggered = false;
    final isUpward = rule.direction == AlertDirection.above ||
        (rule.direction == AlertDirection.bothSides && currentPrice >= target);

    if (rule.direction == AlertDirection.above) {
      triggered = currentPrice >= target;
    } else if (rule.direction == AlertDirection.below) {
      triggered = currentPrice <= target;
    } else {
      triggered = currentPrice >= target || currentPrice <= target;
    }

    if (!triggered) return EvaluationResult.notTriggered;

    final emoji = isUpward ? '🟢' : '🔴';
    final arrow = isUpward ? '↗️' : '↘️';
    final actionText = isUpward ? 'عبور به بالای هدف' : 'افت به زیر هدف';

    return EvaluationResult(
      isTriggered: true,
      title: '$emoji 🎯 ${rule.pair.displayName} $actionText $arrow',
      message: '💰 قیمت زنده: \$${_formatVal(currentPrice)} $emoji\n🎯 تارگت تعیین‌شده: \$${_formatVal(target)} · صرافی ${rule.exchangeId.toUpperCase()}',
      newIsActive: false,     // One-shot: deactivates
      newIsTriggered: true,   // Marked as triggered in UI
      newBasePrice: currentPrice,
    );
  }

  /// 2. Percent Change (Recurring):
  static EvaluationResult _evaluatePercentChange(
    AlertRule rule,
    double currentPrice,
  ) {
    final base = rule.basePrice ?? currentPrice;
    final targetPercent = rule.percent ?? 0.0;
    if (base <= 0.0 || targetPercent <= 0.0) return EvaluationResult.notTriggered;

    final diff = currentPrice - base;
    final actualPercent = (diff / base) * 100.0;

    bool triggered = false;
    if (rule.direction == AlertDirection.above) {
      triggered = actualPercent >= targetPercent;
    } else if (rule.direction == AlertDirection.below) {
      triggered = actualPercent <= -targetPercent;
    } else {
      triggered = actualPercent.abs() >= targetPercent;
    }

    if (!triggered) return EvaluationResult.notTriggered;

    final isUpward = actualPercent >= 0;
    final emoji = isUpward ? '🟢' : '🔴';
    final arrow = isUpward ? '▲ ↗️' : '▼ ↘️';
    final sign = isUpward ? '+' : '';
    final actionText = isUpward ? 'صعود شارپ' : 'ریزش قیمت';

    return EvaluationResult(
      isTriggered: true,
      title: '$emoji 📈 ${rule.pair.displayName} $actionText $sign${actualPercent.toStringAsFixed(2)}% $arrow',
      message: '📊 نوسان ثبت‌شده: $emoji $sign${actualPercent.toStringAsFixed(2)}% (هدف: ±$targetPercent%)\n💰 قیمت فعلی: \$${_formatVal(currentPrice)} (مبنا: \$${_formatVal(base)})',
      newBasePrice: currentPrice, // Update baseline for next cycle to latest price!
      newIsActive: true,          // Stays active forever until paused
      newIsTriggered: false,
    );
  }

  /// 3. Absolute Price Change (Recurring):
  static EvaluationResult _evaluateAbsolutePriceChange(
    AlertRule rule,
    double currentPrice,
  ) {
    final base = rule.basePrice ?? currentPrice;
    final delta = rule.deltaAbsolute ?? 0.0;
    if (delta <= 0.0) return EvaluationResult.notTriggered;

    final diff = currentPrice - base;

    bool triggered = false;
    if (rule.direction == AlertDirection.above) {
      triggered = diff >= delta;
    } else if (rule.direction == AlertDirection.below) {
      triggered = diff <= -delta;
    } else {
      triggered = diff.abs() >= delta;
    }

    if (!triggered) return EvaluationResult.notTriggered;

    final isUpward = diff >= 0;
    final emoji = isUpward ? '🟢' : '🔴';
    final arrow = isUpward ? '▲ ↗️' : '▼ ↘️';
    final sign = isUpward ? '+' : '-';

    return EvaluationResult(
      isTriggered: true,
      title: '$emoji ${rule.pair.displayName} تغییر دلاری $sign\$${_formatVal(diff.abs())} $arrow',
      message: '💵 تغییرات دلاری: $emoji $sign\$${_formatVal(diff.abs())}\n💰 قیمت لحظه‌ای: \$${_formatVal(currentPrice)}',
      newBasePrice: currentPrice,
      newIsActive: true,
      newIsTriggered: false,
    );
  }

  /// 4. Volume Change (Recurring):
  static EvaluationResult _evaluateVolumeChange(
    AlertRule rule,
    double currentVolume,
  ) {
    final baseVolume = rule.baseVolume ?? currentVolume;
    final volumePercent = rule.volumePercent ?? 0.0;
    if (baseVolume <= 0.0 || volumePercent <= 0.0) {
      return EvaluationResult.notTriggered;
    }

    final diff = currentVolume - baseVolume;
    final actualPercent = (diff / baseVolume) * 100.0;

    if (actualPercent >= volumePercent) {
      return EvaluationResult(
        isTriggered: true,
        title: '📊 ⚡ ${rule.pair.displayName} جهش حجم معاملات +${actualPercent.toStringAsFixed(1)}%',
        message: '🚀 حجم ۲۴ ساعته بازار با رشد +${actualPercent.toStringAsFixed(1)}% به \$${_formatVal(currentVolume)} رسید.',
        newBaseVolume: currentVolume,
        newIsActive: true,
        newIsTriggered: false,
      );
    }

    return EvaluationResult.notTriggered;
  }
}
