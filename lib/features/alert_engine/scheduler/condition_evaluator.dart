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

/// Pure evaluation functions per condition type. Zero I/O, 100% deterministic.
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

  /// 1. Price Threshold (One-shot):
  /// Trigger when current price crosses the target in the chosen direction.
  /// After trigger: isActive = false, isTriggered = true.
  static EvaluationResult _evaluatePriceThreshold(
    AlertRule rule,
    double currentPrice,
  ) {
    final target = rule.targetPrice ?? 0.0;
    if (target <= 0.0) return EvaluationResult.notTriggered;

    bool triggered = false;
    if (rule.direction == AlertDirection.above) {
      triggered = currentPrice >= target;
    } else if (rule.direction == AlertDirection.below) {
      triggered = currentPrice <= target;
    } else {
      // Both sides threshold
      triggered = currentPrice >= target || currentPrice <= target;
    }

    if (!triggered) return EvaluationResult.notTriggered;

    final dirText = rule.direction == AlertDirection.above
        ? 'crossed above'
        : (rule.direction == AlertDirection.below ? 'crossed below' : 'hit target');

    return EvaluationResult(
      isTriggered: true,
      title: '${rule.pair.displayName} Target Hit',
      message: '${rule.pair.displayName} $dirText target \$${target.toStringAsFixed(2)} at \$${currentPrice.toStringAsFixed(2)} on ${rule.exchangeId.toUpperCase()}.',
      newIsActive: false,     // One-shot: deactivates
      newIsTriggered: true,   // Marked as triggered in UI
      newBasePrice: currentPrice,
    );
  }

  /// 2. Percent Change (Recurring):
  /// Trigger when percentage change from basePrice >= percent in chosen direction (Up, Down, or Both ±%).
  /// After trigger: updates basePrice = currentPrice so next check calculates from the latest price.
  /// Remains active continuously until paused or deleted.
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
      // Both directions (±%)
      triggered = actualPercent.abs() >= targetPercent;
    }

    if (!triggered) return EvaluationResult.notTriggered;

    final sign = actualPercent >= 0 ? '+' : '';
    final dirText = actualPercent >= 0 ? 'Surged ▲' : 'Dropped ▼';

    return EvaluationResult(
      isTriggered: true,
      title: '${rule.pair.displayName} $dirText $sign${actualPercent.toStringAsFixed(2)}%',
      message: '${rule.pair.displayName} moved $sign${actualPercent.toStringAsFixed(2)}% (target: ±$targetPercent%) from base \$${base.toStringAsFixed(2)} to \$${currentPrice.toStringAsFixed(2)}.',
      newBasePrice: currentPrice, // Update baseline for next cycle to latest price!
      newIsActive: true,          // Stays active forever until paused
      newIsTriggered: false,
    );
  }

  /// 3. Absolute Price Change (Recurring):
  /// Trigger when abs(currentPrice - basePrice) >= deltaAbsolute in chosen direction.
  /// After trigger: basePrice = currentPrice, stays active.
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
      // Both directions
      triggered = diff.abs() >= delta;
    }

    if (!triggered) return EvaluationResult.notTriggered;

    final dirText = diff >= 0 ? 'gained' : 'lost';
    return EvaluationResult(
      isTriggered: true,
      title: '${rule.pair.displayName} Price Delta',
      message: '${rule.pair.displayName} $dirText \$${diff.abs().toStringAsFixed(2)} (delta: \$${delta.toStringAsFixed(2)}) reaching \$${currentPrice.toStringAsFixed(2)}.',
      newBasePrice: currentPrice, // Update baseline
      newIsActive: true,          // Stays active forever
      newIsTriggered: false,
    );
  }

  /// 4. Volume Change (Recurring):
  /// Trigger when volume percentage change from baseVolume >= volumePercent in chosen direction.
  /// After trigger: baseVolume = currentVolume, stays active.
  static EvaluationResult _evaluateVolumeChange(
    AlertRule rule,
    double currentVolume,
  ) {
    final base = rule.baseVolume ?? currentVolume;
    final targetPercent = rule.volumePercent ?? 0.0;
    if (base <= 0.0 || targetPercent <= 0.0) return EvaluationResult.notTriggered;

    final diff = currentVolume - base;
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

    final dirText = actualPercent >= 0 ? 'surged' : 'dropped';
    return EvaluationResult(
      isTriggered: true,
      title: '${rule.pair.displayName} Volume Alert',
      message: '${rule.pair.displayName} 24h volume $dirText ${actualPercent.abs().toStringAsFixed(1)}% to \$${currentVolume.toStringAsFixed(0)}.',
      newBaseVolume: currentVolume, // Update baseline volume
      newIsActive: true,            // Stays active forever
      newIsTriggered: false,
    );
  }
}
