import 'package:flutter/material.dart';

/// Responsive utility class for adapting UI to different screen sizes
class Responsive {
  final BuildContext context;
  final Size size;

  Responsive(this.context) : size = MediaQuery.of(context).size;

  /// Check if device is mobile (phone)
  bool get isMobile => size.width < 600;

  /// Check if device is tablet
  bool get isTablet => size.width >= 600 && size.width < 1024;

  /// Check if device is desktop/web
  bool get isDesktop => size.width >= 1024;

  /// Get responsive padding
  EdgeInsets get padding => EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : isTablet ? 24 : 32,
        vertical: isMobile ? 16 : 24,
      );

  /// Get responsive grid columns
  int get gridColumns {
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4; // Desktop
  }

  /// Get responsive font scale
  double get fontScale => isMobile ? 1.0 : isTablet ? 1.1 : 1.2;

  /// Get responsive card padding
  EdgeInsets get cardPadding => EdgeInsets.all(
        isMobile ? 16 : isTablet ? 20 : 24,
      );

  /// Get responsive icon size
  double iconSize(double baseSize) {
    if (isMobile) return baseSize;
    if (isTablet) return baseSize * 1.2;
    return baseSize * 1.5;
  }

  /// Get responsive spacing
  double spacing(double baseSpacing) {
    if (isMobile) return baseSpacing;
    if (isTablet) return baseSpacing * 1.2;
    return baseSpacing * 1.5;
  }

  /// Get max content width (for centering on large screens)
  double get maxContentWidth {
    if (isMobile) return double.infinity;
    if (isTablet) return 800;
    return 1200; // Desktop max width
  }
}

/// Extension to easily access Responsive from BuildContext
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}

