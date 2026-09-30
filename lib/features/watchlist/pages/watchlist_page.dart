import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// The Main Screen of BitcoinChecker: Personal Price Alerts.
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

  Future<void> _manualCheck(AlertRule rule, SchedulerService scheduler) async {
    setState(() => _checkingRuleUuids.add(rule.uuid));
    try {
      await scheduler.checkRuleNow(rule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('بررسی قیمت انجام شد: ${rule.pair.displayName}'),
            backgroundColor: AppTokens.surfaceElevated,
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
                    style: AppTokens.displayTitle.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.get('smart_alerts_desc', lang),
                    style: const TextStyle(fontSize: 10, color: AppTokens.textMuted),
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
                elevation: 2,
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
            content: Text('هشدار ${rule.pair.displayName} حذف شد'),
            backgroundColor: AppTokens.surfaceElevated,
            action: SnackBarAction(
              label: 'بازگردانی',
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
                ? AppTokens.warning.withValues(alpha: 0.6)
                : (rule.isActive ? AppTokens.borderSubtle : AppTokens.borderSubtle.withValues(alpha: 0.3)),
            width: isTriggeredOneShot ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                          color: rule.isActive ? null : AppTokens.textMuted,
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
                                color: rule.isActive ? AppTokens.textSecondary : AppTokens.textMuted,
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
                            ? (changePercent != null && changePercent >= 0 ? AppTokens.primary : Colors.white)
                            : AppTokens.textMuted,
                      ),
                    ),
                    if (changePercent != null)
                      Text(
                        '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: changePercent >= 0 ? AppTokens.primary : AppTokens.negative,
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
                          activeThumbColor: theme.colorScheme.primary,
                          activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                          onChanged: (val) => repository.saveRule(rule.copyWith(isActive: val)),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Row 2 (NEW dedicated line for alert condition):
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
                        color: rule.isActive ? AppTokens.textPrimary : AppTokens.textMuted,
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
                    color: AppTokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTokens.borderSubtle),
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
                    style: const TextStyle(fontSize: 10, color: AppTokens.textMuted),
                  ),
                ],
                const Spacer(),
                if (rule.lastCheckedAt != null)
                  Text(
                    _formatTimeAgo(rule.lastCheckedAt!, lang),
                    style: const TextStyle(fontSize: 10, color: AppTokens.textMuted),
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: isChecking ? null : () => _manualCheck(rule, scheduler),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTokens.borderSubtle),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space24,
                  vertical: AppTokens.space12,
                ),
                shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildConditionSummary(AlertRule rule, [String lang = 'fa']) {
    final isFa = lang == 'fa';
    switch (rule.conditionType) {
      case AlertConditionType.percentChange:
        if (rule.direction == AlertDirection.bothSides) {
          return isFa
              ? 'نوسان قیمت: ±${rule.percent?.toStringAsFixed(1) ?? '0'}% (افزایش یا کاهش)'
              : 'Price change: ±${rule.percent?.toStringAsFixed(1) ?? '0'}% (Both ways)';
        } else if (rule.direction == AlertDirection.above) {
          return isFa
              ? 'افزایش قیمت: +${rule.percent?.toStringAsFixed(1) ?? '0'}% (صعودی)'
              : 'Price increase: +${rule.percent?.toStringAsFixed(1) ?? '0'}% (Upwards)';
        } else {
          return isFa
              ? 'کاهش قیمت: -${rule.percent?.toStringAsFixed(1) ?? '0'}% (نزولی)'
              : 'Price drop: -${rule.percent?.toStringAsFixed(1) ?? '0'}% (Downwards)';
        }
      case AlertConditionType.priceThreshold:
        final targetStr = rule.targetPrice != null ? _formatPrice(rule.targetPrice!) : '---';
        if (isFa) {
          final dir = rule.direction == AlertDirection.above ? 'عبور به بالاتر از (▲)' : 'سقوط به پایین‌تر از (▼)';
          return 'قیمت هدف: $dir $targetStr';
        } else {
          final dir = rule.direction == AlertDirection.above ? 'Cross above (▲)' : 'Drop below (▼)';
          return 'Target price: $dir $targetStr';
        }
      case AlertConditionType.absolutePriceChange:
        final dir = rule.direction == AlertDirection.bothSides
            ? '±'
            : (rule.direction == AlertDirection.above ? '+' : '-');
        return isFa
            ? 'تغییر دلاری: $dir\$${rule.deltaAbsolute?.toStringAsFixed(2) ?? '0'}'
            : 'Price delta: $dir\$${rule.deltaAbsolute?.toStringAsFixed(2) ?? '0'}';
      case AlertConditionType.volumeChange:
        final dir = rule.direction == AlertDirection.above ? '+' : '-';
        return isFa
            ? 'جهش حجم معاملات: $dir${rule.volumePercent?.toStringAsFixed(1) ?? '0'}%'
            : 'Volume surge: $dir${rule.volumePercent?.toStringAsFixed(1) ?? '0'}%';
    }
  }

  String _getExchangeDisplayName(String exchangeId, [String lang = 'fa']) {
    final isFa = lang == 'fa';
    switch (exchangeId.toLowerCase()) {
      case 'binance':
        return isFa ? 'صرافی بایننس (Binance)' : 'Binance Exchange';
      case 'nobitex':
        return isFa ? 'صرافی نوبیتکس (Nobitex)' : 'Nobitex Exchange';
      case 'wallex':
        return isFa ? 'صرافی والکس (Wallex)' : 'Wallex Exchange';
      case 'kucoin':
        return isFa ? 'صرافی کوکوین (KuCoin)' : 'KuCoin Exchange';
      case 'okx':
        return isFa ? 'صرافی اوکی‌اکس (OKX)' : 'OKX Exchange';
      case 'bybit':
        return isFa ? 'صرافی بای‌بیت (Bybit)' : 'Bybit Exchange';
      case 'coingecko':
        return isFa ? 'کوین‌گکو (CoinGecko)' : 'CoinGecko Aggregator';
      case 'coinmarketcap':
        return isFa ? 'کوین‌مارکت‌کپ (CMC)' : 'CoinMarketCap';
      case 'global_stocks':
        return isFa ? 'بازارهای جهانی (وال‌استریت)' : 'Global Markets (Wall Street)';
      default:
        return isFa ? 'صرافی ${exchangeId.toUpperCase()}' : '${exchangeId.toUpperCase()} Exchange';
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
    final isFa = lang == 'fa';
    if (seconds >= 3600) return isFa ? '${seconds ~/ 3600} ساعت' : '${seconds ~/ 3600} hours';
    if (seconds >= 60) return isFa ? '${seconds ~/ 60} دقیقه' : '${seconds ~/ 60} min';
    return isFa ? '$seconds ثانیه' : '$seconds sec';
  }

  String _formatTimeAgo(DateTime dt, [String lang = 'fa']) {
    final diff = DateTime.now().difference(dt);
    final isFa = lang == 'fa';
    if (diff.inSeconds < 10) return isFa ? 'همین الان' : 'Just now';
    if (diff.inSeconds < 60) return isFa ? '${diff.inSeconds} ثانیه قبل' : '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return isFa ? '${diff.inMinutes} دقیقه قبل' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isFa ? '${diff.inHours} ساعت قبل' : '${diff.inHours}h ago';
    return isFa ? '${diff.inDays} روز قبل' : '${diff.inDays}d ago';
  }
}
