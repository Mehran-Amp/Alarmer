import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/tokens.dart';

/// Group header for separating notification logs by day (Today, Yesterday, or MMM d, yyyy).
class HistoryGroupHeader extends StatelessWidget {
  final DateTime date;

  const HistoryGroupHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final title = _formatHeader(date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space8,
      ),
      color: AppTokens.background,
      child: Text(
        title.toUpperCase(),
        style: AppTokens.caption.copyWith(
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(dt.year, dt.month, dt.day);

    if (checkDate == today) {
      return S.dateToday;
    } else if (checkDate == yesterday) {
      return S.dateYesterday;
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    }
  }
}
