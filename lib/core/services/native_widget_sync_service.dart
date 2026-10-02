import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/alert_engine/models/alert_rule.dart';
import '../../features/alert_engine/models/trigger_mode.dart';
import '../utils/format_utils.dart';

/// Service that serializes active and recent alerts to the Native Android Home Screen Widget.
class NativeWidgetSyncService {
  static const _channel = MethodChannel('com.example.bitcoin_checker/app_lifecycle');

  /// Sync list of rules to native Android AppWidget
  static Future<void> syncAlerts(List<AlertRule> rules, {String lang = 'fa'}) async {
    try {
      final isFa = lang == 'fa' || lang == 'ar' || lang == 'ckb';
      
      // Sort rules: Active first, then most recently updated
      final sorted = List<AlertRule>.from(rules)
        ..sort((a, b) {
          if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
          final aTime = a.lastCheckedAt ?? a.createdAt;
          final bTime = b.lastCheckedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });

      final items = sorted.take(6).map((rule) {
        final symbol = rule.pair.displayName;
        final currentPrice = rule.lastCheckedPrice ?? rule.basePrice ?? 0.0;
        final formattedPrice = currentPrice > 0
            ? FormatUtils.formatPrice(currentPrice, currencySymbol: rule.pair.counterCurrency)
            : '—';

        // Check if one-shot condition is fulfilled / done (non-percentage)
        final isOneShot = rule.conditionType == AlertConditionType.priceThreshold;
        final isDone = isOneShot && (!rule.isActive || rule.isTriggered);

        String badgeText;
        bool? isPositive;

        if (isDone) {
          badgeText = isFa ? '✔️ انجام شد' : '✔️ Done';
          isPositive = true;
        } else {
          switch (rule.conditionType) {
            case AlertConditionType.percentChange:
              final base = rule.basePrice ?? currentPrice;
              if (base > 0 && currentPrice > 0) {
                final diffPct = ((currentPrice - base) / base) * 100.0;
                final isUp = diffPct >= 0;
                isPositive = isUp;
                final sign = isUp ? '+' : '';
                final arrow = isUp ? '▲' : '▼';
                badgeText = '$sign${diffPct.toStringAsFixed(2)}% $arrow';
              } else {
                final isUp = rule.direction == AlertDirection.above;
                isPositive = isUp;
                final arrow = isUp ? '▲' : '▼';
                badgeText = '±${rule.percent?.toStringAsFixed(1)}% $arrow';
              }
              break;

            case AlertConditionType.priceThreshold:
              final target = rule.targetPrice ?? 0.0;
              if (target > 0 && currentPrice > 0) {
                final diffPct = ((currentPrice - target) / target) * 100.0;
                final isUp = currentPrice >= target;
                isPositive = isUp;
                final sign = diffPct >= 0 ? '+' : '';
                final arrow = isUp ? '▲' : '▼';
                badgeText = '$sign${diffPct.toStringAsFixed(2)}% $arrow';
              } else {
                final isUp = rule.direction == AlertDirection.above;
                isPositive = isUp;
                final arrow = isUp ? '▲' : '▼';
                badgeText = 'Target ${FormatUtils.formatPrice(target, currencySymbol: rule.pair.counterCurrency)} $arrow';
              }
              break;

            case AlertConditionType.absolutePriceChange:
              final base = rule.basePrice ?? currentPrice;
              final diff = currentPrice - base;
              final isUp = diff >= 0;
              isPositive = isUp;
              final sign = isUp ? '+' : '-';
              final arrow = isUp ? '▲' : '▼';
              badgeText = '$sign${FormatUtils.formatPrice(diff.abs(), currencySymbol: rule.pair.counterCurrency)} $arrow';
              break;

            case AlertConditionType.volumeChange:
              final isUp = rule.direction == AlertDirection.above;
              isPositive = isUp;
              badgeText = 'Vol ${rule.volumePercent}%';
              break;
          }
        }

        // Target / Note information (no exchange name)
        String infoText = '';
        if (rule.customNote != null && rule.customNote!.trim().isNotEmpty) {
          infoText = rule.customNote!.trim();
        } else if (rule.targetPrice != null && rule.targetPrice! > 0) {
          infoText = '${isFa ? 'هدف' : 'Target'}: ${FormatUtils.formatPrice(rule.targetPrice!, currencySymbol: rule.pair.counterCurrency)}';
        } else if (rule.percent != null) {
          infoText = '${isFa ? 'تغییر' : 'Step'}: ±${rule.percent}%';
        } else {
          infoText = isFa ? 'هشدار فعال' : 'Active Alert';
        }

        return {
          'symbol': symbol,
          'price': formattedPrice,
          'badge': badgeText,
          'isPositive': isPositive == true,
          'isNegative': isPositive == false,
          'isDone': isDone,
          'info': infoText,
          'isActive': rule.isActive,
        };
      }).toList();

      final activeCount = rules.where((r) => r.isActive).length;
      final payload = {
        'activeCount': activeCount,
        'title': isFa ? 'هشدارهای زنده' : 'Live Alerts',
        'items': items,
      };

      await _channel.invokeMethod('updateWidgetList', {
        'json': jsonEncode(payload),
      });
    } catch (_) {
      // Ignore background or platform channel exceptions gracefully
    }
  }
}
