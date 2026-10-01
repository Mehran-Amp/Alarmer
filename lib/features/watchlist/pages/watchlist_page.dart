import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/crypto_icons.dart';
import '../../alert_engine/models/alert_rule.dart';
import '../../alert_engine/models/trigger_mode.dart';
import '../../alert_engine/repositories/json_alert_rule_repository.dart';
import '../../alert_engine/scheduler/scheduler_service.dart';
import '../../exchanges/registry/exchange_registry.dart';
import '../../settings/services/settings_service.dart';
import 'create_alert_flow.dart';

/// The Main Screen of Alarmer: Personal Price Alerts.
/// Highlights the latest checked price prominently (large and bold).
class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final Set<String> _checkingRuleUuids = {};

  void _openCreateFlow() {
    final registry = context.read<ExchangeRegistry>();
    final repository = context.read<JsonAlertRuleRepository>();

    CreateAlertFlow.open(
      context,
      registry: registry,
      repository: repository,
    );
  }

  Future<void> _manualCheck(AlertRule rule, SchedulerService scheduler, String lang) async {
    setState(() => _checkingRuleUuids.add(rule.uuid));
    try {
      await scheduler.checkRuleNow(rule);
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.get('check_price_done', lang)}${rule.pair.displayName}'),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checkingRuleUuids.remove(rule.uuid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<JsonAlertRuleRepository>();
    final scheduler = context.read<SchedulerService>();
    final settingsService = context.watch<SettingsService>();
    final lang = settingsService.settings.language;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.space6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: AppTokens.borderSmall,
              ),
              child: Icon(Icons.alarm_on_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.get('my_alerts', lang),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.get('smart_alerts_desc', lang),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: _openCreateFlow,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                AppStrings.get('new_alert', lang),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AlertRule>>(
        stream: repository.watchAllRules(),
        builder: (context, snapshot) {
          final rules = snapshot.data ?? repository.allRules;

          if (rules.isEmpty) {
            return _buildEmptyState(lang, theme);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space16,
              vertical: AppTokens.space12,
            ),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space12),
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _buildAlertCard(rule, repository, scheduler, lang);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(
    AlertRule rule,
    JsonAlertRuleRepository repository,
    SchedulerService scheduler,
    String lang,
  ) {
    final theme = Theme.of(context);
    final isTriggeredOneShot = rule.isTriggered && rule.triggerMode == TriggerMode.oneShot;
    final isChecking = _checkingRuleUuids.contains(rule.uuid);
    final textMuted = theme.colorScheme.onSurface.withValues(alpha: 0.45);
    final textSecondary = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    final displayPrice = rule.currentDisplayPrice;
    final basePrice = rule.basePrice;

    double? changePercent;
    if (displayPrice != null && basePrice != null && basePrice > 0) {
      changePercent = ((displayPrice - basePrice) / basePrice) * 100.0;
    }

    return Dismissible(
      key: Key(rule.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTokens.space20),
        decoration: BoxDecoration(
          color: AppTokens.negative,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        repository.deleteRule(rule.uuid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.get('alert_deleted_msg', lang)}${rule.pair.displayName}'),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            action: SnackBarAction(
              label: AppStrings.get('undo_action', lang),
              textColor: theme.colorScheme.primary,
              onPressed: () => repository.saveRule(rule),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isTriggeredOneShot
                ? AppTokens.warning.withValues(alpha: 0.7)
                : theme.dividerColor,
            width: isTriggeredOneShot ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Row 1: Logo + Coin info & Exchange Name + Live Price + Switch
            Row(
              children: [
                CryptoIcons.buildLogo(rule.baseCurrency, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.pair.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: rule.isActive ? theme.colorScheme.onSurface : textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.storefront_rounded, size: 12, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _getExchangeDisplayName(rule.exchangeId, lang),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: rule.isActive ? textSecondary : textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayPrice != null ? _formatPrice(displayPrice) : '---',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: rule.isActive
                            ? (changePercent != null && changePercent >= 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface)
                            : textMuted,
                      ),
                    ),
                    if (changePercent != null)
                      Text(
                        '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: changePercent >= 0 ? AppTokens.positive : AppTokens.negative,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.8,
                  child: isTriggeredOneShot
                      ? IconButton(
                          icon: const Icon(Icons.replay_rounded, color: AppTokens.warning),
                          onPressed: () => repository.rearmRule(rule.uuid),
                        )
                      : Switch(
                          value: rule.isActive,
                          activeThumbColor: Colors.white,
                          activeTrackColor: theme.colorScheme.primary,
                          onChanged: (val) => repository.saveRule(rule.copyWith(isActive: val)),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Row 2: Condition Summary Tag
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    rule.conditionType == AlertConditionType.priceThreshold
                        ? Icons.flag_rounded
                        : Icons.show_chart_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _buildConditionSummary(rule, lang),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: rule.isActive ? theme.colorScheme.onSurface : textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Row 3: Interval Tag + Baseline + Last Checked + Quick Check Now Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 11, color: theme.colorScheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        _formatInterval(rule.checkIntervalSeconds, lang),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                if (rule.basePrice != null && rule.basePrice! > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${AppStrings.get('baseline', lang)}: ${_formatPrice(rule.basePrice!)}',
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
                const Spacer(),
                if (rule.lastCheckedAt != null)
                  Text(
                    _formatTimeAgo(rule.lastCheckedAt!, lang),
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: isChecking ? null : () => _manualCheck(rule, scheduler, lang),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isChecking)
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.colorScheme.primary),
                          )
                        else
                          Icon(Icons.refresh_rounded, size: 12, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.get('check_now', lang),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String lang, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.space24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor),
              ),
              child: Icon(
                Icons.add_alert_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTokens.space20),
            Text(
              AppStrings.get('empty_alerts_title', lang),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              AppStrings.get('empty_alerts_desc', lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppTokens.space24),
            ElevatedButton.icon(
              onPressed: _openCreateFlow,
              icon: const Icon(Icons.add_rounded),
              label: Text(AppStrings.get('create_first_alert', lang)),
            ),
          ],
        ),
      ),
    );
  }

  String _buildConditionSummary(AlertRule rule, [String lang = 'fa']) {
    switch (rule.conditionType) {
      case AlertConditionType.percentChange:
        if (rule.direction == AlertDirection.bothSides) {
          return '${AppStrings.get('price_fluctuation', lang)} ±${rule.percent?.toStringAsFixed(1) ?? '0'}%';
        } else if (rule.direction == AlertDirection.above) {
          return '${AppStrings.get('price_surge', lang)} +${rule.percent?.toStringAsFixed(1) ?? '0'}%';
        } else {
          return '${AppStrings.get('price_drop', lang)} -${rule.percent?.toStringAsFixed(1) ?? '0'}%';
        }
      case AlertConditionType.priceThreshold:
        final targetStr = rule.targetPrice != null ? _formatPrice(rule.targetPrice!) : '---';
        final dir = rule.direction == AlertDirection.above
            ? AppStrings.get('price_cross_above', lang)
            : AppStrings.get('price_cross_below', lang);
        return '${AppStrings.get('target_price_summary', lang)} $dir $targetStr';
      case AlertConditionType.absolutePriceChange:
        final dir = rule.direction == AlertDirection.bothSides
            ? '±'
            : (rule.direction == AlertDirection.above ? '+' : '-');
        return '${AppStrings.get('price_delta_summary', lang)} $dir\$${rule.deltaAbsolute?.toStringAsFixed(2) ?? '0'}';
      case AlertConditionType.volumeChange:
        final dir = rule.direction == AlertDirection.above ? '+' : '-';
        return '${AppStrings.get('volume_surge_summary', lang)} $dir${rule.volumePercent?.toStringAsFixed(1) ?? '0'}%';
    }
  }

  String _getExchangeDisplayName(String exchangeId, [String lang = 'fa']) {
    switch (exchangeId.toLowerCase()) {
      case 'binance':
        return 'Binance';
      case 'nobitex':
        return 'Nobitex';
      case 'wallex':
        return 'Wallex';
      case 'kucoin':
        return 'KuCoin';
      case 'okx':
        return 'OKX';
      case 'bybit':
        return 'Bybit';
      case 'coingecko':
        return 'CoinGecko';
      case 'coinmarketcap':
        return 'CoinMarketCap';
      case 'global_stocks':
        return AppStrings.get('wallstreet_stocks', lang);
      default:
        return exchangeId.toUpperCase();
    }
  }

  String _formatPrice(double price) {
    if (price < 0.0001) return '\$${price.toStringAsFixed(7)}';
    if (price < 1.0) return '\$${price.toStringAsFixed(4)}';
    if (price >= 1000) {
      final intPart = price.round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '\$$intPart';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  String _formatInterval(int seconds, [String lang = 'fa']) {
    if (seconds >= 3600) return '${seconds ~/ 3600} ${AppStrings.get('hours', lang)}';
    if (seconds >= 60) return '${seconds ~/ 60} ${AppStrings.get('minutes', lang)}';
    return '$seconds ${AppStrings.get('seconds', lang)}';
  }

  String _formatTimeAgo(DateTime dt, [String lang = 'fa']) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return AppStrings.get('just_now', lang);
    if (diff.inSeconds < 60) return '${diff.inSeconds} ${AppStrings.get('seconds_ago', lang)}';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${AppStrings.get('minutes_ago', lang)}';
    if (diff.inHours < 24) return '${diff.inHours} ${AppStrings.get('hours_ago', lang)}';
    return '${diff.inDays} ${AppStrings.get('days_ago', lang)}';
  }
}
