import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../alert_engine/models/alert_rule.dart';
import '../alert_engine/models/trigger_mode.dart';
import '../alert_engine/repositories/json_alert_rule_repository.dart';
import '../../core/utils/format_utils.dart';

/// Interactive Home Screen Widget representation for Alarmer.
/// Displays active market alerts, live ticker prices, target proximity, and quick actions.
/// Always rendered in English with exact app alert order, no percentage change, and no notes.
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
    // Keep exact order from the app
    final allRules = repository.allRules;
    final activeRules = allRules.where((r) => r.isActive).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Widget Header (Always English)
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Live Pulse Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
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

          const SizedBox(height: 10),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
          const SizedBox(height: 8),

          // Alerts List in Widget (Exact order, no percentage change, no notes)
          if (allRules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No alerts configured yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                return _buildWidgetAlertRow(context, rule, theme);
              },
            ),

          if (allRules.length > (isCompact ? 3 : 5)) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '+ ${allRules.length - (isCompact ? 3 : 5)} more alerts in background',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
      badgeBgColor = const Color(0xFF2B2410);
      badgeTextColor = const Color(0xFFE3B341); // Gold
    } else {
      switch (rule.conditionType) {
        case AlertConditionType.priceThreshold:
          final target = rule.targetPrice ?? 0.0;
          final isUp = rule.direction == AlertDirection.above;
          badgeText = '${isUp ? '≥' : '≤'} ${FormatUtils.formatPrice(target, currencySymbol: rule.pair.counterCurrency)}';
          badgeBgColor = isUp ? const Color(0xFF1A2E20) : const Color(0xFF2E1A1D);
          badgeTextColor = isUp ? const Color(0xFF3FB950) : const Color(0xFFF85149);
          break;

        case AlertConditionType.percentChange:
          final isUp = rule.direction == AlertDirection.above;
          badgeText = '${isUp ? '▲' : '▼'} Step';
          badgeBgColor = const Color(0xFF21262D);
          badgeTextColor = theme.colorScheme.primary;
          break;

        case AlertConditionType.absolutePriceChange:
          final isUp = rule.direction == AlertDirection.above;
          badgeText = '${isUp ? '▲' : '▼'} Move';
          badgeBgColor = const Color(0xFF21262D);
          badgeTextColor = theme.colorScheme.primary;
          break;

        case AlertConditionType.volumeChange:
          badgeText = 'Vol';
          badgeBgColor = const Color(0xFF21262D);
          badgeTextColor = theme.colorScheme.primary;
          break;
      }
    }

    // Clean single-line row: Symbol, Price, Condition Badge (No notes line)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: Color(0xFFF59E0B),
              ),
            ),
          ),

          // Condition / Done Badge (No percentage change)
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
