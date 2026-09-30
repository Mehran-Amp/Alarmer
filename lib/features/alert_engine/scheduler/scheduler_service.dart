import 'dart:async';
import '../../exchanges/registry/exchange_registry.dart';
import '../../notifications/models/notification_log.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/services/notification_service.dart';
import '../models/alert_rule.dart';
import '../repositories/json_alert_rule_repository.dart';
import 'condition_evaluator.dart';

/// Personal Price-Alert Polling Scheduler Service.
/// Wakes up on a 1-second fine tick, checks which individual alert rules are due
/// based on each rule's specific `checkIntervalSeconds`, fetches prices via REST on demand,
/// evaluates conditions, triggers notifications, and updates baseline prices for recurring rules.
class SchedulerService {
  final JsonAlertRuleRepository _alertRuleRepository;
  final ExchangeRegistry _exchangeRegistry;
  final NotificationService _notificationService;
  final NotificationRepository? _notificationRepository;

  Timer? _tickTimer;
  final Set<String> _evaluatingRuleUuids = {};

  final _triggeredController = StreamController<AlertRule>.broadcast();
  Stream<AlertRule> get onRuleTriggered => _triggeredController.stream;

  SchedulerService({
    required JsonAlertRuleRepository alertRuleRepository,
    required ExchangeRegistry exchangeRegistry,
    required NotificationService notificationService,
    NotificationRepository? notificationRepository,
  })  : _alertRuleRepository = alertRuleRepository,
        _exchangeRegistry = exchangeRegistry,
        _notificationService = notificationService,
        _notificationRepository = notificationRepository;

  /// Starts the fine-grained tick scheduler
  void start() {
    _tickTimer?.cancel();
    // Run an initial tick immediately
    _runTick();
    // 1-second tick loop to support sub-minute intervals (5s, 10s, 30s, etc.)
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _runTick();
    });
  }

  /// Evaluates all due alert rules against REST market prices
  Future<void> _runTick() async {
    final now = DateTime.now();

    // Query active rules from repository
    final allRules = _alertRuleRepository.allRules.where((r) => r.isActive).toList();
    final dueRules = allRules.where((rule) => rule.isDue(now) && !_evaluatingRuleUuids.contains(rule.uuid)).toList();

    for (final rule in dueRules) {
      _evaluatingRuleUuids.add(rule.uuid);
      _evaluateSingleRule(rule, now).whenComplete(() {
        _evaluatingRuleUuids.remove(rule.uuid);
      });
    }
  }

  Future<void> _evaluateSingleRule(AlertRule rule, DateTime now) async {
    final exchange = _exchangeRegistry.get(rule.exchangeId);
    if (exchange == null) return;

    try {
      // 1. Fetch current price & volume via pure REST
      final ticker = await exchange.fetchTicker(rule.pair);

      // 2. Evaluate condition synchronously (pure functions, zero I/O)
      final result = ConditionEvaluator.evaluate(
        rule: rule,
        currentPrice: ticker.lastPrice,
        currentVolume: ticker.volume24h,
      );

      // 3. Prepare updated rule state
      var updatedRule = rule.copyWith(
        lastCheckedAt: now,
        lastCheckedPrice: ticker.lastPrice,
      );

      if (result.isTriggered) {
        // Dispatch Notification
        await _notificationService.showCriticalAlert(
          id: rule.uuid.hashCode,
          title: result.title,
          body: result.message,
          payload: rule.uuid,
        );

        // Save notification log
        if (_notificationRepository != null) {
          final log = NotificationLog(
            uuid: DateTime.now().microsecondsSinceEpoch.toString(),
            ruleUuid: rule.uuid,
            exchangeId: rule.exchangeId,
            marketSymbol: rule.marketSymbol,
            title: result.title,
            message: result.message,
            triggeredPrice: ticker.lastPrice,
            timestamp: now,
          );
          await _notificationRepository.saveLog(log);
        }

        // Update rule state per trigger mode
        updatedRule = updatedRule.copyWith(
          isActive: result.newIsActive,
          isTriggered: result.newIsTriggered,
          basePrice: result.newBasePrice, // New base price for subsequent % move calculations
          baseVolume: result.newBaseVolume,
          lastTriggeredAt: now,
          triggerCount: rule.triggerCount + 1,
        );

        _triggeredController.add(updatedRule);
      }

      // 4. Save updated rule to repository
      await _alertRuleRepository.saveRule(updatedRule);
    } catch (_) {
      // Skip on temporary network failure, will re-check on next interval
    }
  }

  /// Trigger an immediate manual check for a specific rule
  Future<void> checkRuleNow(AlertRule rule) async {
    await _evaluateSingleRule(rule, DateTime.now());
  }

  /// Stops the scheduler
  void stop() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void dispose() {
    stop();
    _triggeredController.close();
  }
}
