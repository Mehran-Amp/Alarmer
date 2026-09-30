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

class AlertListPage extends StatefulWidget {
  const AlertListPage({super.key});

  @override
  State<AlertListPage> createState() => _AlertListPageState();
}

class _AlertListPageState extends State<AlertListPage> {
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

    _pendingDeleteTimers[rule.uuid] = Timer(const Duration(seconds: 5), () {
      if (mounted && _pendingDeleteUuids.contains(rule.uuid)) {
        context.read<AlertRulesBloc>().add(DeleteAlertRule(rule.uuid));
        _pendingDeleteUuids.remove(rule.uuid);
        _pendingDeleteTimers.remove(rule.uuid);
      }
    });

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${S.alertDeleted}: ${rule.baseCurrency}/${rule.counterCurrency}'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: S.undo,
          textColor: theme.colorScheme.primary,
          onPressed: () {
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
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          S.rearmConfirmTitle,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
        ),
        content: Text(
          S.rearmConfirmBody,
          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.cancel, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.warning,
              foregroundColor: Colors.white,
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
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(S.alertDuplicated),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _exportSingleRule(AlertRule rule) {
    final jsonStr = jsonEncode(rule.toJson());
    Clipboard.setData(ClipboardData(text: jsonStr));
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rule JSON copied to clipboard'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          S.alertListTitle,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
        ),
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
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space16),
                    Text(
                      S.noAlertsTitle,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    Text(
                      S.noAlertsSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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
                onEdit: () {},
                onExport: () => _exportSingleRule(rule),
              );
            },
          );
        },
      ),
    );
  }
}
