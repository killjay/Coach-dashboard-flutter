import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/constants/app_constants.dart';

/// Settings screen following Apple HIG principles:
/// - Clarity: Clear visual hierarchy and organized sections
/// - Deference: Content-first design with minimal chrome
/// - Depth: Subtle shadows and meaningful grouping
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.padding.left,
            vertical: responsive.padding.top,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // App Preferences Section
                  _SettingsSection(
                    title: 'App Preferences',
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.palette_rounded,
                        title: 'Theme',
                        subtitle: _getThemeModeText(themeMode),
                        trailing: _ThemeModeSelector(
                          currentMode: themeMode,
                          onChanged: (mode) {
                            ref.read(themeModeProvider.notifier).setTheme(mode);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Notifications Section
                  _SettingsSection(
                    title: 'Notifications',
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_rounded,
                        title: 'Push Notifications',
                        subtitle: 'Receive push notifications',
                        trailing: Switch(
                          value: true, // TODO: Connect to notification preferences
                          onChanged: (value) {
                            // TODO: Update notification preferences
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Push notifications enabled'
                                      : 'Push notifications disabled',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.email_rounded,
                        title: 'Email Notifications',
                        subtitle: 'Receive email updates',
                        trailing: Switch(
                          value: true, // TODO: Connect to email preferences
                          onChanged: (value) {
                            // TODO: Update email preferences
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Email notifications enabled'
                                      : 'Email notifications disabled',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Privacy & Security Section
                  _SettingsSection(
                    title: 'Privacy & Security',
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_rounded,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () {
                          // TODO: Navigate to change password screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Change password feature coming soon'),
                            ),
                          );
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Privacy Policy',
                        subtitle: 'View our privacy policy',
                        onTap: () async {
                          // TODO: Replace with actual privacy policy URL
                          final url = Uri.parse('https://example.com/privacy');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.description_rounded,
                        title: 'Terms of Service',
                        subtitle: 'View terms and conditions',
                        onTap: () async {
                          // TODO: Replace with actual terms URL
                          final url = Uri.parse('https://example.com/terms');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Data Management Section
                  _SettingsSection(
                    title: 'Data Management',
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.download_rounded,
                        title: 'Export Data',
                        subtitle: 'Download your data',
                        onTap: () {
                          // TODO: Implement data export
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data export feature coming soon'),
                            ),
                          );
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Clear Cache',
                        subtitle: 'Clear app cache and temporary files',
                        onTap: () async {
                          final shouldClear = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear Cache'),
                              content: const Text(
                                'This will clear all cached data. This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.errorColor,
                                  ),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );

                          if (shouldClear == true) {
                            // TODO: Implement cache clearing
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cache cleared successfully'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // About Section
                  _SettingsSection(
                    title: 'About',
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.info_rounded,
                        title: 'App Version',
                        subtitle: AppConstants.appVersion,
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: AppConstants.appName,
                            applicationVersion: AppConstants.appVersion,
                            applicationIcon: const Icon(
                              Icons.fitness_center_rounded,
                              size: 48,
                            ),
                          );
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.code_rounded,
                        title: 'Open Source Licenses',
                        subtitle: 'View third-party licenses',
                        onTap: () {
                          showLicensePage(
                            context: context,
                            applicationName: AppConstants.appName,
                            applicationVersion: AppConstants.appVersion,
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.padding.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }
}

/// Settings Section Container - Apple HIG: Clear grouping
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _SettingsSection({
    required this.title,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children
                .map((child) => [
                      child,
                      if (child != children.last)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: isDark
                              ? AppTheme.darkSurfaceVariant
                              : AppTheme.surfaceVariant,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ])
                .expand((element) => element)
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// Settings Tile - Apple HIG: Clear affordances
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                )
              : null),
      onTap: onTap,
    );
  }
}

/// Theme Mode Selector - Apple HIG: Clear selection
class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      initialValue: currentMode,
      onSelected: onChanged,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getThemeModeText(currentMode),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkTextSecondary
                : AppTheme.textSecondary,
          ),
        ],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ThemeMode.system,
          child: Text('System Default'),
        ),
        const PopupMenuItem(
          value: ThemeMode.light,
          child: Text('Light'),
        ),
        const PopupMenuItem(
          value: ThemeMode.dark,
          child: Text('Dark'),
        ),
      ],
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }
}







