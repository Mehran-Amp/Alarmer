import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/tokens.dart';
import '../bloc/alert_rules_bloc.dart';
import '../bloc/alert_rules_event.dart';
import '../bloc/alert_rules_state.dart';
import '../models/alert_rule.dart';
import '../repositories/json_alert_rule_repository.dart';
import '../widgets/alert_row.dart';

/// Alert Management Screen displaying active and cooling-down rules.
/// Supports 5-second undo swipe deletion, direct active toggle,
/// re-arm confirmation dialogs, and rule duplication.
class AlertListPage extends StatefulWidget {
  const AlertListPage({super.key});

  @override
  State<AlertListPage> createState() => _AlertListPageState();
}

class _AlertListPageState extends State<AlertListPage> {
  // Pending delete timers for 5-second Undo window
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Set<String> _pendingDeleteUuids = {};

  @override
  void dispose() {
    for (final timer in _pendingDeleteTimers.values) {
      timer.cancel();
    }
    _pendingDeleteTimers.clear();
    super.dispose();
  }

  void _handleSwipeDelete(AlertRule rule) {
    setState(() {
      _pendingDeleteUuids.add(rule.uuid);
    });

    // Schedule actual commit to Isar after 5 seconds
    _pendingDeleteTimers[rule.uuid] = Timer(const Duration(seconds: 5), () {
      if (mounted && _pendingDeleteUuids.contains(rule.uuid)) {
        context.read<AlertRulesBloc>().add(DeleteAlertRule(rule.uuid));
        _pendingDeleteUuids.remove(rule.uuid);
        _pendingDeleteTimers.remove(rule.uuid);
      }
    });

    // Present 5-second Undo Snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${S.alertDeleted}: ${rule.baseCurrency}/${rule.counterCurrency}'),
        backgroundColor: AppTokens.surfaceElevated,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: S.undo,
          textColor: AppTokens.primary,
          onPressed: () {
            // Cancel scheduled delete timer and restore row
            _pendingDeleteTimers[rule.uuid]?.cancel();
            _pendingDeleteTimers.remove(rule.uuid);
            setState(() {
              _pendingDeleteUuids.remove(rule.uuid);
            });
          },
        ),
      ),
    );
  }

  Future<void> _showRearmConfirmation(BuildContext context, AlertRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderLarge),
        title: const Text(S.rearmConfirmTitle, style: AppTokens.sectionHeader),
        content: const Text(S.rearmConfirmBody, style: AppTokens.bodySecondary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppTokens.textSecondary),
            child: const Text(S.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.warning,
              foregroundColor: AppTokens.background,
              shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderMedium),
            ),
            child: const Text(S.rearmNow),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AlertRulesBloc>().add(RearmAlertRule(rule.uuid));
    }
  }

  void _duplicateRule(AlertRule rule) async {
    final repo = context.read<JsonAlertRuleRepository>();
    final duplicated = await repo.duplicateRule(rule.uuid);
    if (duplicated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(S.alertDuplicated),
          backgroundColor: AppTokens.surfaceElevated,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _exportSingleRule(AlertRule rule) {
    final jsonStr = jsonEncode(rule.toJson());
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rule JSON copied to clipboard'),
        backgroundColor: AppTokens.surfaceElevated,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        backgroundColor: AppTokens.surface,
        elevation: 0,
        title: const Text(S.alertListTitle, style: AppTokens.displayTitle),
      ),
      body: BlocBuilder<AlertRulesBloc, AlertRulesState>(
        builder: (context, state) {
          final visibleRules = state.rules
              .where((r) => !_pendingDeleteUuids.contains(r.uuid))
              .toList();

          if (visibleRules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTokens.space24),
                      decoration: const BoxDecoration(
                        color: AppTokens.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: AppTokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space16),
                    const Text(S.noAlertsTitle, style: AppTokens.sectionHeader),
                    const SizedBox(height: AppTokens.space8),
                    Text(
                      S.noAlertsSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTokens.bodySecondary.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space12),
            itemCount: visibleRules.length,
            itemBuilder: (context, index) {
              final rule = visibleRules[index];

              return AlertRow(
                rule: rule,
                onToggle: (isActive) {
                  context.read<AlertRulesBloc>().add(ToggleAlertRule(
                    uuid: rule.uuid,
                    isActive: isActive,
                  ));
                },
                onSwipeDelete: () => _handleSwipeDelete(rule),
                onRearm: () => _showRearmConfirmation(context, rule),
                onDuplicate: () => _duplicateRule(rule),
                onEdit: () {
                  // Placeholder: editing will be integrated with the new CreateAlertFlow wizard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rule editing will be available in the upcoming wizard.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                onExport: () => _exportSingleRule(rule),
              );
            },
          );
        },
      ),
    );
  }
}
