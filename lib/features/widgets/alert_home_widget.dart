import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../alert_engine/models/alert_rule.dart';
import '../alert_engine/models/trigger_mode.dart';
import '../alert_engine/repositories/json_alert_rule_repository.dart';
import '../../core/utils/format_utils.dart';

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
              physics: const NeverScrollableScrollPhysics),
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
    final formattedPrice = currentPrice > 0
        ? FormatUtils.formatPrice(currentPrice, currencySymbol: rule.pair.counterCurrency)
        : '—';

    // One-shot condition done check (only non-percentage one-shot rules)
    final isOneShot = rule.conditionType == AlertConditionType.priceThreshold;
    final isDone = isOneShot && (!rule.isActive || rule.isTriggered);

    String badgeText;
    Color badgeBgColor;
    Color badgeTextColor;

    if (isDone) {
      badgeText = isFa ? '✔️ انجام شد' : '✔️ Done';
      badgeBgColor = const Color(0xFF2B2410);
      badgeTextColor = const Color(0xFFE3B341); // Gold
    } else {
      switch (rule.conditionType) {
        case AlertConditionType.percentChange:
          final base = rule.basePrice ?? currentPrice;
          if (base > 0 && currentPrice > 0) {
            final diff = ((currentPrice - base) / base) * 100.0;
            final isUp = diff >= 0;
            final sign = isUp ? '+' : '';
            final arrow = isUp ? '▲' : '▼';
            badgeText = '$sign${diff.toStringAsFixed(2)}% $arrow';
            badgeBgColor = isUp ? const Color(0xFF1A2E20) : const Color(0xFF2E1A1D);
            badgeTextColor = isUp ? const Color(0xFF3FB950) : const Color(0xFFF85149);
          } else {
            badgeText = '±${rule.percent?.toStringAsFixed(1)}%';
            badgeBgColor = const Color(0xFF21262D);
            badgeTextColor = const Color(0xFF58A6FF);
          }
          break;

        case AlertConditionType.priceThreshold:
          final target = rule.targetPrice ?? 0.0;
          if (target > 0 && currentPrice > 0) {
            final diff = ((currentPrice - target) / target) * 100.0;
            final isUp = currentPrice >= target;
            final sign = diff >= 0 ? '+' : '';
            final arrow = isUp ? '▲' : '▼';
            badgeText = '$sign${diff.toStringAsFixed(2)}% $arrow';
            badgeBgColor = isUp ? const Color(0xFF1A2E20) : const Color(0xFF2E1A1D);
            badgeTextColor = isUp ? const Color(0xFF3FB950) : const Color(0xFFF85149);
          } else {
            final isUp = rule.direction == AlertDirection.above;
            badgeText = '${rule.direction == AlertDirection.above ? '≥' : '≤'} $target';
            badgeBgColor = isUp ? const Color(0xFF1A2E20) : const Color(0xFF2E1A1D);
            badgeTextColor = isUp ? const Color(0xFF3FB950) : const Color(0xFFF85149);
          }
          break;

        case AlertConditionType.absolutePriceChange:
          final base = rule.basePrice ?? currentPrice;
          final diff = currentPrice - base;
          final isUp = diff >= 0;
          final sign = isUp ? '+' : '-';
          final arrow = isUp ? '▲' : '▼';
          badgeText = '$sign${FormatUtils.formatPrice(diff.abs(), currencySymbol: rule.pair.counterCurrency)} $arrow';
          badgeBgColor = isUp ? const Color(0xFF1A2E20) : const Color(0xFF2E1A1D);
          badgeTextColor = isUp ? const Color(0xFF3FB950) : const Color(0xFFF85149);
          break;

        case AlertConditionType.volumeChange:
          badgeText = 'Vol ${rule.volumePercent}%';
          badgeBgColor = const Color(0xFF21262D);
          badgeTextColor = const Color(0xFF58A6FF);
          break;
      }
    }

    String infoText = '';
    if (rule.customNote != null && rule.customNote!.trim().isNotEmpty) {
      infoText = rule.customNote!.trim();
    } else if (rule.targetPrice != null && rule.targetPrice! > 0) {
      infoText = '${isFa ? 'هدف' : 'Target'}: ${FormatUtils.formatPrice(rule.targetPrice!, currencySymbol: rule.pair.counterCurrency)}';
    } else if (rule.percent != null) {
      infoText = '${isFa ? 'تغییر مرحله‌ای' : 'Step'}: ±${rule.percent}%';
    } else {
      infoText = isFa ? 'هشدار فعال' : 'Active Alert';
    }

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
              // Symbol
              Text(
                rule.pair.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),

              // Live Current Price next to symbol
              Expanded(
                child: Text(
                  formattedPrice,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),

              // Status / % / Done Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
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

          const SizedBox(height: 3),

          // Target note / info text (No exchange name)
          Text(
            infoText,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
