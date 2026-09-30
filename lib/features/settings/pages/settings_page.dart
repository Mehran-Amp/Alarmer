import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../alert_engine/repositories/json_alert_rule_repository.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/services/notification_service.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isBatteryExempt = false;

  final List<Map<String, String>> _supportedLanguages = const [
    {'code': 'fa', 'name': 'فارسی', 'native': 'فارسی', 'flag': '🇮🇷'},
    {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'French', 'native': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español', 'flag': '🇪🇸'},
    {'code': 'zh', 'name': 'Chinese', 'native': '中文', 'flag': '🇨🇳'},
    {'code': 'ko', 'name': 'Korean', 'native': '한국어', 'flag': '🇰🇷'},
    {'code': 'ckb', 'name': 'Kurdish Sorani', 'native': 'کوردی سۆرانی', 'flag': '☀️'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية', 'flag': '🇸🇦'},
    {'code': 'tr', 'name': 'Turkish', 'native': 'Türkçe', 'flag': '🇹🇷'},
  ];

  @override
  void initState() {
    super.initState();
    _checkBatteryStatus();
  }

  Future<void> _checkBatteryStatus() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (mounted) {
        setState(() {
          _isBatteryExempt = status.isGranted;
        });
      }
    }
  }

  Future<void> _requestBatteryExemption() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (mounted) {
      setState(() {
        _isBatteryExempt = status.isGranted;
      });
      if (status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('معافیت از بهینه‌سازی باتری با موفقیت ثبت شد.'),
            backgroundColor: AppTokens.surfaceElevated,
          ),
        );
      }
    }
  }

  void _showLanguagePicker(BuildContext context, SettingsService settingsService, String currentLang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.get('select_language', currentLang),
                      style: AppTokens.sectionHeader,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTokens.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: _supportedLanguages.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTokens.borderSubtle),
                    itemBuilder: (context, index) {
                      final lang = _supportedLanguages[index];
                      final isSelected = currentLang == lang['code'];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                          title: Text(lang['native']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(lang['name']!, style: AppTokens.caption),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: AppTokens.primary)
                              : null,
                          selected: isSelected,
                          selectedTileColor: AppTokens.primarySubtle,
                          onTap: () async {
                            await settingsService.setLanguage(lang['code']!);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _testAlarm(BuildContext context, String lang) async {
    final notifService = context.read<NotificationService>();
    final settingsService = context.read<SettingsService>();

    // 1. Haptic feedback
    if (settingsService.settings.vibrationEnabled) {
      await HapticFeedback.heavyImpact();
    }

    // 2. Sound
    if (settingsService.settings.soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }

    // 3. System Notification
    await notifService.showCriticalAlert(
      id: 99999,
      title: AppStrings.get('test_alert_title', lang),
      body: AppStrings.get('test_alert_body', lang),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('test_alert_body', lang)),
          backgroundColor: AppTokens.surfaceElevated,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _exportBackup(BuildContext context, String lang) async {
    final repo = context.read<JsonAlertRuleRepository>();
    final jsonString = await repo.exportAlertsToJson();
    await Clipboard.setData(ClipboardData(text: jsonString));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('backup_copied', lang)),
          backgroundColor: AppTokens.surfaceElevated,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _importBackup(BuildContext context, String lang) async {
    final controller = TextEditingController();

    final jsonString = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderLarge),
        title: Text(AppStrings.get('restore_backup', lang), style: AppTokens.sectionHeader),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'متن فایل JSON پشتیبان‌گیری شده را در کادر زیر جای‌گذاری (Paste) کنید:',
              style: AppTokens.bodySecondary,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              style: AppTokens.monoNumbersSmall,
              decoration: const InputDecoration(
                hintText: '[{"uuid": "...", "marketSymbol": "BTCUSDT", ...}]',
                filled: true,
                fillColor: AppTokens.surfaceElevated,
                border: OutlineInputBorder(borderRadius: AppTokens.borderMedium),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف', style: TextStyle(color: AppTokens.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.primary,
              foregroundColor: AppTokens.background,
            ),
            child: const Text('تأیید و بازیابی'),
          ),
        ],
      ),
    );

    if (jsonString != null && jsonString.isNotEmpty && context.mounted) {
      try {
        final repo = context.read<JsonAlertRuleRepository>();
        final count = await repo.importAlertsFromJson(jsonString);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 $count ${AppStrings.get('restore_success', lang)}'),
              backgroundColor: AppTokens.surfaceElevated,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطا در خواندن فایل JSON. لطفاً از صحت فرمت اطمینان حاصل کنید.'),
              backgroundColor: AppTokens.negative,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearHistory(BuildContext context, String lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderLarge),
        title: Text(AppStrings.get('clear_history', lang), style: AppTokens.sectionHeader),
        content: const Text('آیا از پاک کردن تمامی اعلان‌ها و رکوردهای ثبت‌شده اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('انصراف', style: TextStyle(color: AppTokens.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.negative,
              foregroundColor: Colors.white,
            ),
            child: const Text('پاک‌سازی'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = context.read<NotificationRepository>();
      await repo.clearAllLogs();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمامی لاگ‌های تاریخچه اعلان‌ها پاک شدند.'),
            backgroundColor: AppTokens.surfaceElevated,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final settings = settingsService.settings;
    final lang = settings.language;

    final currentLangObj = _supportedLanguages.firstWhere(
      (l) => l['code'] == lang,
      orElse: () => _supportedLanguages[0],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(AppStrings.get('settings', lang), style: AppTokens.displayTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space20),
        children: [
          // Section 1: Themes & Colors (4 Modes) - Real & Reactive
          _buildSectionHeader(AppStrings.get('theme_and_colors', lang)),
          const SizedBox(height: AppTokens.space8),

          Container(
            padding: const EdgeInsets.all(AppTokens.space16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppTokens.borderMedium,
              border: Border.all(color: AppTokens.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.3,
                  children: [
                    _buildThemeCard(
                      palette: AppThemePalette.darkGreen,
                      currentPalette: settings.themePalette,
                      title: AppStrings.get('theme_dark_green', lang),
                      bgPreview: const Color(0xFF020617),
                      accent: const Color(0xFF10B981),
                      onSelect: () => settingsService.setPalette(AppThemePalette.darkGreen),
                    ),
                    _buildThemeCard(
                      palette: AppThemePalette.lightGreen,
                      currentPalette: settings.themePalette,
                      title: AppStrings.get('theme_light_green', lang),
                      bgPreview: const Color(0xFFF8FAFC),
                      accent: const Color(0xFF059669),
                      onSelect: () => settingsService.setPalette(AppThemePalette.lightGreen),
                    ),
                    _buildThemeCard(
                      palette: AppThemePalette.darkOrange,
                      currentPalette: settings.themePalette,
                      title: AppStrings.get('theme_dark_orange', lang),
                      bgPreview: const Color(0xFF0C0A09),
                      accent: const Color(0xFFF97316),
                      onSelect: () => settingsService.setPalette(AppThemePalette.darkOrange),
                    ),
                    _buildThemeCard(
                      palette: AppThemePalette.lightOrange,
                      currentPalette: settings.themePalette,
                      title: AppStrings.get('theme_light_orange', lang),
                      bgPreview: const Color(0xFFFAFAF9),
                      accent: const Color(0xFFEA580C),
                      onSelect: () => settingsService.setPalette(AppThemePalette.lightOrange),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space20),

          // Section 2: Languages (10 Languages) - Real & Reactive
          _buildSectionHeader(AppStrings.get('select_language', lang)),
          const SizedBox(height: AppTokens.space8),

          InkWell(
            onTap: () => _showLanguagePicker(context, settingsService, lang),
            borderRadius: AppTokens.borderMedium,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: AppTokens.borderMedium,
                border: Border.all(color: AppTokens.borderSubtle),
              ),
              child: Row(
                children: [
                  Text(currentLangObj['flag']!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: AppTokens.space12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentLangObj['native']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${currentLangObj['name']} (۱۰ زبان)', style: AppTokens.caption),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down_rounded, color: AppTokens.textSecondary, size: 28),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space20),

          // Section 3: Sound & Vibration Toggles + Real Test Alarm Button
          _buildSectionHeader(AppStrings.get('sound_and_vibrate', lang)),
          const SizedBox(height: AppTokens.space8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppTokens.borderMedium,
              border: Border.all(color: AppTokens.borderSubtle),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.volume_up_rounded, color: AppTokens.primary),
                  title: Text(AppStrings.get('sound_alert', lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  value: settings.soundEnabled,
                  activeColor: AppTokens.primary,
                  onChanged: (val) => settingsService.toggleSound(val),
                ),
                const Divider(height: 1, color: AppTokens.borderSubtle),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.vibration_rounded, color: AppTokens.primary),
                  title: Text(AppStrings.get('vibrate_alert', lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  value: settings.vibrationEnabled,
                  activeColor: AppTokens.primary,
                  onChanged: (val) => settingsService.toggleVibration(val),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _testAlarm(context, lang),
                    icon: const Icon(Icons.notifications_active_rounded),
                    label: Text(
                      AppStrings.get('test_sound_button', lang),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.primary,
                      foregroundColor: AppTokens.background,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space20),

          // Section 4: Backup & Restore (Real JSON export & import)
          _buildSectionHeader(AppStrings.get('backup_and_restore', lang)),
          const SizedBox(height: AppTokens.space8),

          _buildActionTile(
            title: AppStrings.get('export_backup', lang),
            subtitle: 'خروجی گرفتن از تمام هشدارهای فعال در قالب فایل JSON',
            icon: Icons.cloud_upload_rounded,
            color: AppTokens.primary,
            onTap: () => _exportBackup(context, lang),
          ),
          const SizedBox(height: AppTokens.space8),

          _buildActionTile(
            title: AppStrings.get('restore_backup', lang),
            subtitle: 'وارد کردن و بازگردانی هشدارها از فایل یا متن JSON',
            icon: Icons.cloud_download_rounded,
            color: AppTokens.secondary,
            onTap: () => _importBackup(context, lang),
          ),
          const SizedBox(height: AppTokens.space8),

          _buildActionTile(
            title: AppStrings.get('clear_history', lang),
            subtitle: 'حذف تمامی گزارش‌ها و لاگ‌های ثبت‌شده',
            icon: Icons.delete_outline_rounded,
            color: AppTokens.negative,
            onTap: () => _clearHistory(context, lang),
          ),
          const SizedBox(height: AppTokens.space20),

          // Section 5: Battery Optimization Exemption
          if (defaultTargetPlatform == TargetPlatform.android) ...[
            _buildSectionHeader(AppStrings.get('battery_settings', lang)),
            const SizedBox(height: AppTokens.space8),

            Container(
              padding: const EdgeInsets.all(AppTokens.space16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: AppTokens.borderMedium,
                border: Border.all(
                  color: _isBatteryExempt
                      ? AppTokens.primary.withValues(alpha: 0.3)
                      : AppTokens.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isBatteryExempt ? Icons.battery_charging_full_rounded : Icons.battery_alert_rounded,
                        color: _isBatteryExempt ? AppTokens.primary : AppTokens.warning,
                        size: 24,
                      ),
                      const SizedBox(width: AppTokens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('معافیت از محدودیت باتری', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              _isBatteryExempt ? 'فعال (هشدارها سر وقت اجرا می‌شوند)' : 'غیرفعال (ممکن است سیستم هشدار را متوقف کند)',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isBatteryExempt ? AppTokens.primary : AppTokens.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!_isBatteryExempt) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestBatteryExemption,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.primary,
                          foregroundColor: AppTokens.background,
                        ),
                        child: Text(AppStrings.get('battery_request', lang)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppTokens.textSecondary,
      ),
    );
  }

  Widget _buildThemeCard({
    required AppThemePalette palette,
    required AppThemePalette currentPalette,
    required String title,
    required Color bgPreview,
    required Color accent,
    required VoidCallback onSelect,
  }) {
    final isSelected = currentPalette == palette;
    return InkWell(
      onTap: onSelect,
      borderRadius: AppTokens.borderSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgPreview,
          borderRadius: AppTokens.borderSmall,
          border: Border.all(
            color: isSelected ? accent : AppTokens.borderSubtle,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: bgPreview.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.borderMedium,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppTokens.borderMedium,
            border: Border.all(color: AppTokens.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppTokens.borderSmall,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTokens.caption),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
