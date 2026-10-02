import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../alert_engine/models/alert_rule.dart';
import '../alert_engine/models/trigger_mode.dart';
import '../alert_engine/repositories/json_alert_rule_repository.dart';
import '../../core/utils/format_utils.dart';

/// Interactive Home Screen Widget representation for Alarmer.
/// Displays active market alerts, live ticker prices, percentage change, and quick actions.
/// Always rendered in English with exact app alert order, real percentage + arrow, and dynamic theme contrast.
class AlertHomeWidgetView extends StatelessWidget {
  final JsonAlertRuleRepository repository;
  final String lang;
  final VoidCallback? onRefresh;
  final VoidCallback? onAddNew;
  final ValueChanged<AlertRule>? onToggleRule;
  final bool isCompact;

  const AlertHomeWidgetView({
    super.key,
    required this.repository,
    required this.lang,
    this.onRefresh,
    this.onAddNew,
    this.onToggleRule,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allRules = repository.allRules;
    final activeRules = allRules.where((r) => r.isActive).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Widget Header (Always English, High Contrast)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alarmer Live Widget',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${activeRules.length} active alerts • ${DateFormat('HH:mm').format(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Live Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onRefresh,
                  tooltip: 'Refresh All',
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 8),

          // Alerts List in Widget
          if (allRules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No active alerts configured',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: isCompact ? allRules.take(3).length : allRules.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final rule = allRules[index];
                return _buildWidgetAlertRow(context, rule, theme, isDark);
              },
            ),

          if (allRules.length > (isCompact ? 3 : 5)) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                '+ ${allRules.length - (isCompact ? 3 : 5)} more alerts in background',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWidgetAlertRow(
    BuildContext context,
    AlertRule rule,
    ThemeData theme,
    bool isDark,
  ) {
    final currentPrice = rule.lastCheckedPrice ?? rule.basePrice ?? 0.0;
    final formattedPrice = currentPrice > 0
        ? FormatUtils.formatPrice(currentPrice, currencySymbol: rule.pair.counterCurrency)
        : '—';

    // One-shot condition done check
    final isOneShot = rule.conditionType == AlertConditionType.priceThreshold;
    final isDone = isOneShot && (!rule.isActive || rule.isTriggered);

    String badgeText;
    Color badgeBgColor;
    Color badgeTextColor;

    if (isDone) {
      badgeText = '✔️ Done';
      badgeBgColor = isDark ? const Color(0xFF2B2410) : const Color(0xFFFEF3C7);
      badgeTextColor = isDark ? const Color(0xFFE3B341) : const Color(0xFFD97706);
    } else {
      // Calculate real percentage change from base / last checked price
      final base = rule.basePrice ?? currentPrice;
      double diffPct = 0.0;
      if (base > 0 && currentPrice > 0) {
        diffPct = ((currentPrice - base) / base) * 100.0;
      } else if (rule.percent != null) {
        diffPct = rule.percent!;
      }

      final isUp = diffPct >= 0;
      final sign = isUp ? '+' : '';
      final arrow = isUp ? '▲' : '▼';
      badgeText = '$sign${diffPct.toStringAsFixed(2)}% $arrow';

      if (isUp) {
        badgeBgColor = isDark ? const Color(0xFF1A2E20) : const Color(0xFFDCFCE7);
        badgeTextColor = isDark ? const Color(0xFF3FB950) : const Color(0xFF15803D);
      } else {
        badgeBgColor = isDark ? const Color(0xFF2E1A1D) : const Color(0xFFFEE2E2);
        badgeTextColor = isDark ? const Color(0xFFF85149) : const Color(0xFFB91C1C);
      }
    }

    final priceColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.scaffoldBackgroundColor.withValues(alpha: 0.7)
            : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Symbol
          Text(
            rule.pair.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),

          // Live Current Price
          Expanded(
            child: Text(
              formattedPrice,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: priceColor,
              ),
            ),
          ),

          // Percentage + Arrow Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
