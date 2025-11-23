import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/screens/login_screen.dart';
import '../../../../../core/utils/router.dart';
import '../../../../../core/providers/repository_providers.dart';

/// Profile screen following Apple HIG principles:
/// - Clarity: Clear visual hierarchy and information grouping
/// - Deference: Content-first design with minimal chrome
/// - Depth: Subtle shadows and meaningful animations
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.signOut();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      try {
        final authRepository = ref.read(authRepositoryProvider);
        await authRepository.deleteAccount();
        if (mounted) {
          context.go(AppRoutes.login);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateProfile(name: _nameController.text.trim());
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isEditing) {
      _nameController.text = user.name;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Edit'),
            ),
        ],
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Profile Avatar - Apple HIG: Clear visual hierarchy
                  _ProfileAvatar(
                    avatarUrl: user.avatarUrl,
                    name: user.name,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  // Profile Form - Apple HIG: Content-first design
                  Form(
                    key: _formKey,
                    child: _ProfileSection(
                      isDark: isDark,
                      children: [
                        _ProfileField(
                          label: 'Name',
                          value: user.name,
                          controller: _nameController,
                          isEditing: _isEditing,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name cannot be empty';
                            }
                            return null;
                          },
                        ),
                        _ProfileField(
                          label: 'Email',
                          value: user.email,
                          isEditing: false,
                        ),
                        _ProfileField(
                          label: 'Role',
                          value: user.role.toUpperCase(),
                          isEditing: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Actions Section - Apple HIG: Clear grouping
                  _ProfileSection(
                    isDark: isDark,
                    children: [
                      if (_isEditing) ...[
                        _ProfileActionTile(
                          icon: Icons.save_rounded,
                          title: 'Save Changes',
                          onTap: _handleSaveProfile,
                          isPrimary: true,
                        ),
                        _ProfileActionTile(
                          icon: Icons.close_rounded,
                          title: 'Cancel',
                          onTap: () => setState(() => _isEditing = false),
                        ),
                      ] else ...[
                        _ProfileActionTile(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          onTap: () {
                            context.push(AppRoutes.settings);
                          },
                        ),
                        _ProfileActionTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          onTap: () {
                            context.push(AppRoutes.helpSupport);
                          },
                        ),
                        _ProfileActionTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Coach-Client App',
                              applicationVersion: '1.0.0',
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Danger Zone - Apple HIG: Clear visual distinction
                  _ProfileSection(
                    isDark: isDark,
                    children: [
                      _ProfileActionTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        onTap: _handleSignOut,
                        isDestructive: true,
                      ),
                      _ProfileActionTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Delete Account',
                        onTap: _handleDeleteAccount,
                        isDestructive: true,
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
}

/// Profile Avatar with Apple HIG depth principles
class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final bool isDark;

  const _ProfileAvatar({
    required this.avatarUrl,
    required this.name,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              )
            : null,
      ),
    );
  }
}

/// Profile Section Container - Apple HIG: Clear grouping with subtle depth
class _ProfileSection extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _ProfileSection({
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    ),
                ])
            .expand((element) => element)
            .toList(),
      ),
    );
  }
}

/// Profile Field - Apple HIG: Clear information hierarchy
class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final TextEditingController? controller;
  final bool isEditing;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.label,
    required this.value,
    this.controller,
    this.isEditing = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: isEditing && controller != null
          ? TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: validator,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
    );
  }
}

/// Profile Action Tile - Apple HIG: Clear affordances
class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive
        ? AppTheme.errorColor
        : isPrimary
            ? AppTheme.primaryColor
            : null;

    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

