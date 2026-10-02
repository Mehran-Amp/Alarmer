import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../alert_engine/models/alert_rule.dart';
import '../alert_engine/models/trigger_mode.dart';
import '../alert_engine/repositories/json_alert_rule_repository.dart';
import '../../core/localization/app_strings.dart';

/// Interactive Home Screen Widget representation for Alarmer.
/// Displays active market alerts, live ticker prices, target proximity, and quick actions.
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
    final isFa = lang == 'fa' || lang == 'ar' || lang == 'ckb';
    final allRules = repository.allRules;
    final activeRules = allRules.where((r) => r.isActive).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Widget Header
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
                      isFa ? 'ویجت زنده صفحه اصلی' : 'Live Home Screen Widget',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${activeRules.length} ${isFa ? 'هشدار فعال' : 'active alerts'} • ${DateFormat('HH:mm').format(DateTime.now())}',
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
                      isFa ? 'زنده' : 'LIVE',
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
                  tooltip: isFa ? 'بروزرسانی زنده' : 'Refresh All',
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Alerts List in Widget
          if (allRules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  isFa ? 'هنوز هشداری تنظیم نشده است' : 'No alerts configured yet',
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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final rule = allRules[index];
                return _buildWidgetAlertRow(context, rule, theme, isFa);
              },
            ),

          if (allRules.length > (isCompact ? 3 : 5)) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                isFa
                    ? '+ ${allRules.length - (isCompact ? 3 : 5)} هشدار دیگر در پس‌زمینه فعال است'
                    : '+ ${allRules.length - (isCompact ? 3 : 5)} more alerts running in background',
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
    bool isFa,
  ) {
    final currentPrice = rule.lastCheckedPrice ?? rule.basePrice ?? 0.0;
    final targetPrice = rule.targetPrice ?? 0.0;
    
    // Proximity to target calculation
    double progress = 0.5;
    if (targetPrice > 0 && currentPrice > 0) {
      if (rule.direction == AlertDirection.above) {
        progress = (currentPrice / targetPrice).clamp(0.0, 1.0);
      } else {
        progress = (targetPrice / currentPrice).clamp(0.0, 1.0);
      }
    }

    final isTriggered = rule.isTriggered;
    final statusColor = !rule.isActive
        ? Colors.grey
        : (isTriggered
            ? Colors.redAccent
            : (progress >= 0.95 ? Colors.amber : theme.colorScheme.primary));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Symbol & Market
              Expanded(
                child: Row(
                  children: [
                    Text(
                      rule.pair.baseCurrency,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '/${rule.pair.counterCurrency}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rule.exchangeId.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    if (rule.ttsEnabled) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.record_voice_over_rounded, size: 12, color: theme.colorScheme.primary),
                    ],
                  ],
                ),
              ),

              // Live Current Price
              Text(
                currentPrice >= 1000
                    ? NumberFormat('#,##0').format(currentPrice)
                    : currentPrice.toStringAsFixed(currentPrice < 1 ? 4 : 2),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Condition Target & Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rule.targetPrice != null
                    ? '${rule.direction == AlertDirection.above ? '≥' : '≤'} \$${rule.targetPrice}'
                    : '${rule.percent != null ? '${rule.percent}%' : ''}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
