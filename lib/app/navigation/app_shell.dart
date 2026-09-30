import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/tokens.dart';
import '../../features/notifications/pages/notification_history_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/settings/services/settings_service.dart';
import '../../features/watchlist/pages/watchlist_page.dart';

/// App-wide Navigation Shell with custom floating center tab.
/// Tab 0: History (تاریخچه)
/// Tab 1: Alerts (هشدارهای من - وسط، شناور و پیش‌فرض)
/// Tab 2: Settings (تنظیمات)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Alerts tab in the middle (index 1) is default
  int _currentIndex = 1;

  final List<Widget> _pages = const [
    NotificationHistoryPage(),
    WatchlistPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final lang = settingsService.settings.language;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: AppTokens.borderSubtle, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. History Tab
            _buildNavItem(
              index: 0,
              icon: Icons.notifications_none_rounded,
              activeIcon: Icons.notifications_active_rounded,
              label: AppStrings.get('history', lang),
              activeColor: theme.colorScheme.primary,
            ),

            // 2. Middle Floating Alerts Tab (Default & Prominent)
            _buildCenterAlertsButton(
              label: AppStrings.get('my_alerts', lang),
              primaryColor: theme.colorScheme.primary,
            ),

            // 3. Settings Tab
            _buildNavItem(
              index: 2,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: AppStrings.get('settings', lang),
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? activeColor : AppTokens.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : AppTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAlertsButton({
    required String label,
    required Color primaryColor,
  }) {
    final isSelected = _currentIndex == 1;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -10),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : AppTokens.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : AppTokens.border,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isSelected ? Icons.alarm_on_rounded : Icons.alarm_outlined,
                color: isSelected ? Colors.white : AppTokens.textSecondary,
                size: 26,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : AppTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
