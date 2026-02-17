import 'package:flutter/material.dart';

/// Theme configuration for the EPUB viewer.
///
/// Allows customizing all colors and styles used throughout the viewer.
/// When not specified, sensible defaults are used based on dark/light mode.
class EpubViewerThemeConfig {
  /// Primary accent color (used for buttons, links, active items).
  final Color? primaryColor;

  /// Background color in light mode.
  final Color lightBackgroundColor;

  /// Background color in dark mode.
  final Color darkBackgroundColor;

  /// Background color for sepia reading mode (optional).
  final Color? sepiaBackgroundColor;

  /// Text color in light mode.
  final Color lightTextColor;

  /// Text color in dark mode.
  final Color darkTextColor;

  /// Subtitle/secondary text color in light mode.
  final Color lightSubtitleColor;

  /// Subtitle/secondary text color in dark mode.
  final Color darkSubtitleColor;

  /// App bar background color in light mode.
  final Color lightAppBarColor;

  /// App bar background color in dark mode.
  final Color darkAppBarColor;

  /// App bar icon/text color in light mode.
  final Color lightAppBarForegroundColor;

  /// App bar icon/text color in dark mode.
  final Color darkAppBarForegroundColor;

  /// Surface/card color in light mode.
  final Color lightSurfaceColor;

  /// Surface/card color in dark mode.
  final Color darkSurfaceColor;

  /// Divider color in light mode.
  final Color lightDividerColor;

  /// Divider color in dark mode.
  final Color darkDividerColor;

  /// Icon color in light mode.
  final Color lightIconColor;

  /// Icon color in dark mode.
  final Color darkIconColor;

  /// Chapter navigation button color.
  final Color? chapterNavColor;

  /// Progress indicator color.
  final Color? progressColor;

  /// Loading indicator color.
  final Color? loadingIndicatorColor;

  /// Error text color.
  final Color errorColor;

  /// Bookmark icon color.
  final Color? bookmarkColor;

  /// Highlight default color.
  final Color? highlightColor;

  /// Search highlight color.
  final Color? searchHighlightColor;

  /// Link color in content.
  final Color? linkColor;

  /// TOC (Table of Contents) active item color.
  final Color? tocActiveColor;

  /// Border radius for cards and panels.
  final double cardBorderRadius;

  /// Border radius for buttons.
  final double buttonBorderRadius;

  /// Default padding.
  final double defaultPadding;

  const EpubViewerThemeConfig({
    this.primaryColor,
    this.lightBackgroundColor = Colors.white,
    this.darkBackgroundColor = const Color(0xFF121212),
    this.sepiaBackgroundColor,
    this.lightTextColor = const Color(0xFF212121),
    this.darkTextColor = Colors.white,
    this.lightSubtitleColor = const Color(0xFF757575),
    this.darkSubtitleColor = const Color(0xFF9E9E9E),
    this.lightAppBarColor = Colors.white,
    this.darkAppBarColor = const Color(0xFF1a1a1a),
    this.lightAppBarForegroundColor = const Color(0xFF212121),
    this.darkAppBarForegroundColor = Colors.white,
    this.lightSurfaceColor = Colors.white,
    this.darkSurfaceColor = const Color(0xFF1a1a1a),
    this.lightDividerColor = const Color(0xFFE0E0E0),
    this.darkDividerColor = const Color(0xFF424242),
    this.lightIconColor = const Color(0xFF757575),
    this.darkIconColor = const Color(0xFFBDBDBD),
    this.chapterNavColor,
    this.progressColor,
    this.loadingIndicatorColor,
    this.errorColor = Colors.red,
    this.bookmarkColor,
    this.highlightColor,
    this.searchHighlightColor,
    this.linkColor,
    this.tocActiveColor,
    this.cardBorderRadius = 12.0,
    this.buttonBorderRadius = 8.0,
    this.defaultPadding = 16.0,
  });

  /// Get background color based on dark mode.
  Color backgroundColor(bool isDark) =>
      isDark ? darkBackgroundColor : lightBackgroundColor;

  /// Get text color based on dark mode.
  Color textColor(bool isDark) => isDark ? darkTextColor : lightTextColor;

  /// Get subtitle color based on dark mode.
  Color subtitleColor(bool isDark) =>
      isDark ? darkSubtitleColor : lightSubtitleColor;

  /// Get app bar color based on dark mode.
  Color appBarColor(bool isDark) => isDark ? darkAppBarColor : lightAppBarColor;

  /// Get app bar foreground color based on dark mode.
  Color appBarForegroundColor(bool isDark) =>
      isDark ? darkAppBarForegroundColor : lightAppBarForegroundColor;

  /// Get surface color based on dark mode.
  Color surfaceColor(bool isDark) =>
      isDark ? darkSurfaceColor : lightSurfaceColor;

  /// Get divider color based on dark mode.
  Color dividerColor(bool isDark) =>
      isDark ? darkDividerColor : lightDividerColor;

  /// Get icon color based on dark mode.
  Color iconColor(bool isDark) => isDark ? darkIconColor : lightIconColor;

  /// Resolve primary color from theme or config.
  Color resolvePrimaryColor(BuildContext context) =>
      primaryColor ?? Theme.of(context).primaryColor;

  /// A default theme config.
  static const EpubViewerThemeConfig defaultTheme = EpubViewerThemeConfig();
}
