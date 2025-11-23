import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modern button styles following Apple HIG principles
class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ModernButtonStyle style;
  final double? width;
  final double? height;

  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.style = ModernButtonStyle.primary,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget button;
    switch (style) {
      case ModernButtonStyle.primary:
        button = _buildPrimaryButton(context, isDark);
        break;
      case ModernButtonStyle.secondary:
        button = _buildSecondaryButton(context, isDark);
        break;
      case ModernButtonStyle.outline:
        button = _buildOutlineButton(context, isDark);
        break;
      case ModernButtonStyle.text:
        button = _buildTextButton(context, isDark);
        break;
    }

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height ?? 50,
        child: button,
      );
    }

    return button;
  }

  Widget _buildPrimaryButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXL,
            vertical: AppTheme.spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ),
        child: _buildButtonContent(context),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, bool isDark) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? AppTheme.darkSurfaceVariant
            : AppTheme.surfaceVariant,
        foregroundColor: isDark
            ? AppTheme.darkTextPrimary
            : AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXL,
          vertical: AppTheme.spacingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        elevation: 0,
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildOutlineButton(BuildContext context, bool isDark) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        side: BorderSide(
          color: AppTheme.primaryColor,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXL,
          vertical: AppTheme.spacingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildTextButton(BuildContext context, bool isDark) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLG,
          vertical: AppTheme.spacingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppTheme.spacingSM),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

enum ModernButtonStyle {
  primary,
  secondary,
  outline,
  text,
}


