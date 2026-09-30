import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/tokens.dart';
import '../models/alert_rule.dart';
import '../models/alert_type.dart';
import 'cooldown_timer.dart';

/// Single alert rule row widget with swipe-to-delete, direct toggle,
/// long-press contextual actions, and independent cooldown timer.
class AlertRow extends StatelessWidget {
  final AlertRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSwipeDelete;
  final VoidCallback onRearm;
  final VoidCallback onDuplicate;
  final VoidCallback onEdit;
  final VoidCallback onExport;

  const AlertRow({
    super.key,
    required this.rule,
    required this.onToggle,
    required this.onSwipeDelete,
    required this.onRearm,
    required this.onDuplicate,
    required this.onEdit,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final conditionDescription = _buildConditionDescription(rule);

    return Dismissible(
      key: Key(rule.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTokens.space24),
        decoration: const BoxDecoration(
          color: AppTokens.negative,
          borderRadius: AppTokens.borderMedium,
        ),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: AppTokens.textPrimary,
          size: 26,
        ),
      ),
      onDismissed: (_) => onSwipeDelete(),
      child: GestureDetector(
        onLongPressStart: (details) => _showContextMenu(context, details.globalPosition),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTokens.space16,
            vertical: AppTokens.space6,
          ),
          padding: const EdgeInsets.all(AppTokens.space16),
          decoration: BoxDecoration(
            color: rule.isActive ? AppTokens.surface : AppTokens.surface.withValues(alpha: 0.5),
            borderRadius: AppTokens.borderMedium,
            border: Border.all(
              color: rule.isInCooldown
                  ? AppTokens.warning.withValues(alpha: 0.4)
                  : (rule.isActive ? AppTokens.borderSubtle : AppTokens.borderSubtle.withValues(alpha: 0.3)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Pair, Exchange & Active Switch
              Row(
                children: [
                  Text(
                    '${rule.baseCurrency} / ${rule.counterCurrency}',
                    style: AppTokens.sectionHeader.copyWith(
                      color: rule.isActive ? AppTokens.textPrimary : AppTokens.textMuted,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space6,
                      vertical: 1.5,
                    ),
                    decoration: const BoxDecoration(
                      color: AppTokens.surfaceElevated,
                      borderRadius: AppTokens.borderSmall,
                    ),
                    child: Text(
                      rule.exchangeId.toUpperCase(),
                      style: AppTokens.caption.copyWith(
                        color: AppTokens.secondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (rule.logicOperator != null) ...[
                    const SizedBox(width: AppTokens.space6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space6,
                        vertical: 1.5,
                      ),
                      decoration: const BoxDecoration(
                        color: AppTokens.accentSubtle,
                        borderRadius: AppTokens.borderSmall,
                      ),
                      child: Text(
                        rule.logicOperator!.name.toUpperCase(),
                        style: AppTokens.caption.copyWith(
                          color: AppTokens.accent,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),

                  // Direct Active / Pause Toggle (No confirmation dialog needed)
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: rule.isActive,
                      activeThumbColor: AppTokens.primary,
                      activeTrackColor: AppTokens.primarySubtle,
                      inactiveThumbColor: AppTokens.textMuted,
                      inactiveTrackColor: AppTokens.surfaceElevated,
                      onChanged: onToggle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTokens.space6),

              // Condition description
              Text(
                conditionDescription,
                style: AppTokens.monoNumbers.copyWith(
                  fontSize: 13,
                  color: rule.isActive ? AppTokens.textSecondary : AppTokens.textMuted,
                ),
              ),

              const SizedBox(height: AppTokens.space8),

              // Metadata Row: Trigger count & last triggered
              Row(
                children: [
                  Text(
                    'Triggers: ${rule.triggerCount}',
                    style: AppTokens.caption,
                  ),
                  if (rule.lastTriggeredAt != null) ...[
                    const SizedBox(width: AppTokens.space8),
                    const Text('·', style: AppTokens.caption),
                    const SizedBox(width: AppTokens.space8),
                    Text(
                      'Last: ${_formatTime(rule.lastTriggeredAt!)}',
                      style: AppTokens.caption,
                    ),
                  ],
                ],
              ),

              // Independent Cooldown Timer (rendered ONLY when currently cooling down)
              if (rule.isInCooldown && rule.cooldownUntil != null)
                CooldownTimer(
                  cooldownUntil: rule.cooldownUntil!,
                  onRearmPressed: onRearm,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: AppTokens.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderMedium),
      items: const [
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 18, color: AppTokens.textSecondary),
              SizedBox(width: AppTokens.space12),
              Text(S.duplicateAlert, style: AppTokens.body),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: AppTokens.textSecondary),
              SizedBox(width: AppTokens.space12),
              Text(S.editAlert, style: AppTokens.body),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.ios_share_rounded, size: 18, color: AppTokens.textSecondary),
              SizedBox(width: AppTokens.space12),
              Text(S.exportAlert, style: AppTokens.body),
            ],
          ),
        ),
      ],
    ).then((selection) {
      if (selection == 'duplicate') onDuplicate();
      if (selection == 'edit') onEdit();
      if (selection == 'export') onExport();
    });
  }

  String _buildConditionDescription(AlertRule rule) {
    final target = (rule.targetValue ?? 0.0).toStringAsFixed(2);
    switch (rule.alertType) {
      case AlertType.price:
      case AlertType.priceCross:
        final dir = rule.condition == ConditionType.above ? 'ABOVE' : 'BELOW';
        return 'Price crosses $dir \$$target';
      case AlertType.percent:
      case AlertType.percentChange:
        final dir = rule.condition == ConditionType.percentUp ? '+' : '-';
        final secs = rule.timeWindowSeconds;
        final windowLabel = secs >= 3600
            ? '${secs ~/ 3600}h'
            : (secs >= 60 ? '${secs ~/ 60}m' : '${secs}s');
        return 'Price moves $dir${rule.targetValue ?? 0}% in $windowLabel';
      case AlertType.absolute:
        return 'Price delta >= \$$target';
      case AlertType.volume:
      case AlertType.volumeSurge:
        final volTarget = (rule.targetValue ?? 0.0).toStringAsFixed(0);
        return 'Volume surge >= \$$volTarget';
      case AlertType.compound:
        return 'Compound Rule ($dirOperator)';
    }
  }

  String get dirOperator => rule.logicOperator?.name.toUpperCase() ?? 'AND';

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
