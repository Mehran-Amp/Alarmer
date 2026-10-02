import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/alert_engine/models/alert_rule.dart';
import '../../features/alert_engine/models/trigger_mode.dart';
import '../../features/settings/models/app_settings.dart';
import '../utils/format_utils.dart';

/// Service that serializes active alerts and active app theme to the Native Android Home Screen Widget.
/// - Preserves exact alert order from app
/// - Always in English
/// - No notes/info lines
/// - No percentage change (displays condition target or status directly)
/// - Synchronizes widget colors with selected app theme palette dynamically
class NativeWidgetSyncService {
  static const _channel = MethodChannel('com.example.bitcoin_checker/app_lifecycle');

  static List<AlertRule> _cachedRules = [];
  static AppThemePalette _cachedPalette = AppThemePalette.darkGreen;

  /// Sync list of rules (with optional theme palette) to native Android AppWidget
  static Future<void> syncAlerts(
    List<AlertRule> rules, {
    AppThemePalette? themePalette,
  }) async {
    try {
      _cachedRules = rules;
      if (themePalette != null) {
        _cachedPalette = themePalette;
      }

      // Preserve exact order from app alerts list
      final items = rules.take(5).map((rule) {
        final symbol = rule.pair.displayName;
        final currentPrice = rule.lastCheckedPrice ?? rule.basePrice ?? 0.0;
        final formattedPrice = currentPrice > 0
            ? FormatUtils.formatPrice(currentPrice, currencySymbol: rule.pair.counterCurrency)
            : '—';

        // Check if one-shot condition is fulfilled / done
        final isOneShot = rule.conditionType == AlertConditionType.priceThreshold;
        final isDone = isOneShot && (!rule.isActive || rule.isTriggered);

        String badgeText;
        bool? isPositive;

        if (isDone) {
          badgeText = '✔️ Done';
          isPositive = true;
        } else {
          switch (rule.conditionType) {
            case AlertConditionType.priceThreshold:
              final target = rule.targetPrice ?? 0.0;
              final isUp = rule.direction == AlertDirection.above;
              isPositive = isUp;
              badgeText = '${isUp ? '≥' : '≤'} ${FormatUtils.formatPrice(target, currencySymbol: rule.pair.counterCurrency)}';
              break;

            case AlertConditionType.percentChange:
              final isUp = rule.direction == AlertDirection.above;
              isPositive = isUp;
              badgeText = '${isUp ? '▲' : '▼'} Step';
              break;

            case AlertConditionType.absolutePriceChange:
              final isUp = rule.direction == AlertDirection.above;
              isPositive = isUp;
              badgeText = '${isUp ? '▲' : '▼'} Move';
              break;

            case AlertConditionType.volumeChange:
              isPositive = rule.direction == AlertDirection.above;
              badgeText = 'Vol';
              break;
          }
        }

        return {
          'symbol': symbol,
          'price': formattedPrice,
          'badge': badgeText,
          'isPositive': isPositive == true,
          'isNegative': isPositive == false,
          'isDone': isDone,
          'isActive': rule.isActive,
        };
      }).toList();

      final activeCount = rules.where((r) => r.isActive).length;
      final themeColors = _getPaletteColors(_cachedPalette);

      final payload = {
        'activeCount': activeCount,
        'title': 'Alarmer Live Widget',
        'footerText': 'Tap to open Alarmer',
        'theme': themeColors,
        'items': items,
      };

      await _channel.invokeMethod('updateWidgetList', {
        'json': jsonEncode(payload),
      });
    } catch (_) {
      // Ignore platform channel exceptions gracefully
    }
  }

  /// Sync theme palette change directly to Android AppWidget
  static Future<void> syncTheme(AppThemePalette palette) async {
    _cachedPalette = palette;
    await syncAlerts(_cachedRules, themePalette: palette);
  }

  static Map<String, int> _getPaletteColors(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.darkGreen:
        return {
          'bg': 0xFF090D16,
          'surface': 0xFF111827,
          'primary': 0xFF10B981,
          'textPrimary': 0xFFF9FAFB,
          'textSecondary': 0xFF9CA3AF,
          'border': 0xFF374151,
          'isDark': 1,
        };
      case AppThemePalette.lightGreen:
        return {
          'bg': 0xFFF3F4F6,
          'surface': 0xFFFFFFFF,
          'primary': 0xFF059669,
          'textPrimary': 0xFF111827,
          'textSecondary': 0xFF4B5563,
          'border': 0xFFD1D5DB,
          'isDark': 0,
        };
      case AppThemePalette.darkOrange:
        return {
          'bg': 0xFF0C0A09,
          'surface': 0xFF1C1917,
          'primary': 0xFFF97316,
          'textPrimary': 0xFFFAFAF9,
          'textSecondary': 0xFFA8A29E,
          'border': 0xFF44403C,
          'isDark': 1,
        };
      case AppThemePalette.lightOrange:
        return {
          'bg': 0xFFFAF8F5,
          'surface': 0xFFFFFFFF,
          'primary': 0xFFEA580C,
          'textPrimary': 0xFF1C1917,
          'textSecondary': 0xFF78716C,
          'border': 0xFFE7E5E4,
          'isDark': 0,
        };
      case AppThemePalette.darkPurpleBlue:
        return {
          'bg': 0xFF0B0D1B,
          'surface': 0xFF13172E,
          'primary': 0xFF8B5CF6,
          'textPrimary': 0xFFF8FAFC,
          'textSecondary': 0xFF94A3B8,
          'border': 0xFF2E365E,
          'isDark': 1,
        };
      case AppThemePalette.lightPurpleBlue:
        return {
          'bg': 0xFFF5F6FF,
          'surface': 0xFFFFFFFF,
          'primary': 0xFF7C3AED,
          'textPrimary': 0xFF0F172A,
          'textSecondary': 0xFF475569,
          'border': 0xFFD6DBF5,
          'isDark': 0,
        };
    }
  }
}
