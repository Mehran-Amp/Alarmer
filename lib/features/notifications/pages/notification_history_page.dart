import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/tokens.dart';
import '../models/notification_log.dart';
import '../repositories/notification_repository.dart';
import '../widgets/history_group_header.dart';

enum HistoryFilter { all, triggered, suppressed }

/// Chronological Notification History Page.
/// Groups logged events by date (Today, Yesterday, MMM d, yyyy),
/// supports pull-to-refresh from local storage, and filter chips.
class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  HistoryFilter _currentFilter = HistoryFilter.all;
  List<NotificationLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final repo = context.read<NotificationRepository>();
    final logs = await repo.getAllLogs();

    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _logs.where((log) {
      if (_currentFilter == HistoryFilter.all) return true;
      if (_currentFilter == HistoryFilter.triggered) {
        return !log.message.contains('Suppressed');
      }
      if (_currentFilter == HistoryFilter.suppressed) {
        return log.message.contains('Suppressed') || log.message.contains('cooldown');
      }
      return true;
    }).toList();

    // Group logs by day
    final groupedLogs = _groupLogsByDay(filteredLogs);

    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        backgroundColor: AppTokens.surface,
        elevation: 0,
        title: const Text(S.notificationHistoryTitle, style: AppTokens.displayTitle),
      ),
      body: Column(
        children: [
          // Filter Chips at Top
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space16,
              vertical: AppTokens.space12,
            ),
            child: Row(
              children: [
                _buildFilterChip(HistoryFilter.all, S.filterAll),
                const SizedBox(width: AppTokens.space8),
                _buildFilterChip(HistoryFilter.triggered, S.filterTriggered),
                const SizedBox(width: AppTokens.space8),
                _buildFilterChip(HistoryFilter.suppressed, S.filterSuppressed),
              ],
            ),
          ),

          // Log Entries List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTokens.primary))
                : filteredLogs.isEmpty
                    ? Center(
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
                                  Icons.history_toggle_off_rounded,
                                  size: 48,
                                  color: AppTokens.textMuted,
                                ),
                              ),
                              const SizedBox(height: AppTokens.space16),
                              const Text(S.noHistoryTitle, style: AppTokens.sectionHeader),
                              const SizedBox(height: AppTokens.space8),
                              Text(
                                S.noHistorySubtitle,
                                textAlign: TextAlign.center,
                                style: AppTokens.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        color: AppTokens.primary,
                        backgroundColor: AppTokens.surface,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: groupedLogs.length,
                          itemBuilder: (context, index) {
                            final group = groupedLogs[index];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HistoryGroupHeader(date: group.date),
                                ...group.logs.map((log) => _buildLogCard(log)),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(HistoryFilter filter, String label) {
    final isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _currentFilter = filter),
      selectedColor: AppTokens.primarySubtle,
      backgroundColor: AppTokens.surfaceElevated,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? AppTokens.primary : AppTokens.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppTokens.primary : AppTokens.borderSubtle,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderFull),
    );
  }

  Widget _buildLogCard(NotificationLog log) {
    final isWarning = log.message.contains('cooldown') || log.message.contains('Suppressed');

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space4,
      ),
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: AppTokens.borderMedium,
        border: Border.all(
          color: isWarning
              ? AppTokens.warning.withValues(alpha: 0.3)
              : AppTokens.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Pair & Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(log.marketSymbol, style: AppTokens.sectionHeader.copyWith(fontSize: 14)),
                  const SizedBox(width: AppTokens.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: 1.5),
                    decoration: const BoxDecoration(
                      color: AppTokens.surfaceElevated,
                      borderRadius: AppTokens.borderSmall,
                    ),
                    child: Text(
                      log.exchangeId.toUpperCase(),
                      style: AppTokens.caption.copyWith(color: AppTokens.secondary, fontSize: 10),
                    ),
                  ),
                ],
              ),
              Text(
                _formatTimestamp(log.timestamp),
                style: AppTokens.caption.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space6),

          // Message & Triggered Price
          Text(log.message, style: AppTokens.bodySecondary),
          const SizedBox(height: AppTokens.space6),

          // Price Tag
          Row(
            children: [
              const Text('Trigger Price: ', style: AppTokens.caption),
              Text(
                '\$${log.triggeredPrice.toStringAsFixed(2)}',
                style: AppTokens.monoNumbersSmall.copyWith(
                  color: AppTokens.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_GroupedLogItem> _groupLogsByDay(List<NotificationLog> logs) {
    final Map<String, List<NotificationLog>> map = {};

    for (final log in logs) {
      final key = '${log.timestamp.year}-${log.timestamp.month}-${log.timestamp.day}';
      map.putIfAbsent(key, () => []).add(log);
    }

    final groups = <_GroupedLogItem>[];
    for (final entry in map.entries) {
      final firstLog = entry.value.first;
      groups.add(_GroupedLogItem(
        date: DateTime(firstLog.timestamp.year, firstLog.timestamp.month, firstLog.timestamp.day),
        logs: entry.value,
      ));
    }

    return groups;
  }

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _GroupedLogItem {
  final DateTime date;
  final List<NotificationLog> logs;

  _GroupedLogItem({required this.date, required this.logs});
}
