import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'epub_reader_controller.dart';

/// Settings bottom sheet for EPUB reader
class EpubSettingsSheet extends GetView<EpubReaderController> {
  const EpubSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;
      final subtitleColor = isDark ? Colors.white60 : Colors.black54;
      final dividerColor = isDark ? Colors.white12 : Colors.black12;
      final primaryColor = Theme.of(context).primaryColor;

      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reading Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: subtitleColor),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              Divider(color: dividerColor, height: 1),

              // Settings content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Font size section
                      _buildSectionHeader('Font Size', textColor),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: controller.decreaseFontSize,
                              icon: Icon(Icons.text_decrease, color: textColor),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Slider(
                                    value: controller.fontSize.value,
                                    min: 12,
                                    max: 32,
                                    divisions: 10,
                                    activeColor: primaryColor,
                                    onChanged: controller.setFontSize,
                                  ),
                                  Text(
                                    '${controller.fontSize.value.toInt()}pt',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: controller.increaseFontSize,
                              icon: Icon(Icons.text_increase, color: textColor),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Font family section with grid layout
                      _buildSectionHeader('Font Family', textColor),

                      // Language indicator
                      if (controller.epubLanguage.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Fonts for ${_getLanguageName(controller.epubLanguage.value)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Font grid (2 columns, 3 rows = 6 fonts + Default)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: controller.fontFamilies.length,
                          itemBuilder: (context, index) {
                            final font = controller.fontFamilies[index];
                            final isSelected =
                                controller.fontFamily.value == font;
                            return _buildFontTile(
                              font: font,
                              isSelected: isSelected,
                              isDark: isDark,
                              primaryColor: primaryColor,
                              textColor: textColor,
                              onTap: () => controller.setFontFamily(font),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Line height section
                      _buildSectionHeader('Line Spacing', textColor),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Slider(
                              value: controller.lineHeight.value,
                              min: 1.0,
                              max: 3.0,
                              divisions: 8,
                              activeColor: primaryColor,
                              onChanged: controller.setLineHeight,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tight',
                                    style: TextStyle(
                                        fontSize: 12, color: subtitleColor)),
                                Text(
                                  '${controller.lineHeight.value.toStringAsFixed(1)}x',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                                Text('Loose',
                                    style: TextStyle(
                                        fontSize: 12, color: subtitleColor)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Display options
                      _buildSectionHeader('Display', textColor),

                      _SettingsTile(
                        icon: Icons.fullscreen,
                        title: 'Fullscreen Mode',
                        subtitle: 'Hide system bars while reading',
                        trailing: Switch(
                          value: controller.isFullscreen.value,
                          onChanged: (_) => controller.toggleFullscreen(),
                          activeTrackColor: primaryColor,
                        ),
                        isDarkMode: isDark,
                      ),

                      _SettingsTile(
                        icon: Icons.screen_lock_portrait,
                        title: 'Keep Screen On',
                        subtitle: 'Prevent screen from sleeping',
                        trailing: Switch(
                          value: controller.keepScreenOn.value,
                          onChanged: (_) => controller.toggleKeepScreenOn(),
                          activeTrackColor: primaryColor,
                        ),
                        isDarkMode: isDark,
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isDarkMode;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;
    final iconColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Helper widget for font selection tile with preview
Widget _buildFontTile({
  required String font,
  required bool isSelected,
  required bool isDark,
  required Color primaryColor,
  required Color textColor,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: 0.15)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Font preview text
          Text(
            'Aa',
            style:
                _getFontPreviewStyle(font, isSelected, primaryColor, textColor),
          ),
          const SizedBox(height: 2),
          // Font name
          Text(
            font == 'Default' ? 'Default' : _shortenFontName(font),
            style: TextStyle(
              fontSize: 10,
              color:
                  isSelected ? primaryColor : textColor.withValues(alpha: 0.7),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

/// Get font preview style using Google Fonts
TextStyle _getFontPreviewStyle(
    String font, bool isSelected, Color primaryColor, Color textColor) {
  final color = isSelected ? primaryColor : textColor;
  const fontSize = 18.0;
  const fontWeight = FontWeight.w500;

  if (font == 'Default') {
    return TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }

  try {
    return GoogleFonts.getFont(
      font,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  } catch (e) {
    return TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }
}

/// Shorten long font names for display
String _shortenFontName(String fontName) {
  if (fontName.length <= 12) return fontName;
  // Handle common patterns
  if (fontName.contains(' ')) {
    final parts = fontName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1].substring(0, 1)}...';
    }
  }
  return '${fontName.substring(0, 10)}...';
}

/// Get human-readable language name from code
String _getLanguageName(String langCode) {
  const languageNames = {
    'en': 'English',
    'hi': 'Hindi',
    'bn': 'Bengali',
    'ta': 'Tamil',
    'te': 'Telugu',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'pa': 'Punjabi',
    'or': 'Odia',
    'sa': 'Sanskrit',
    'ar': 'Arabic',
    'ur': 'Urdu',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'ru': 'Russian',
    'de': 'German',
    'fr': 'French',
    'es': 'Spanish',
    'pt': 'Portuguese',
    'it': 'Italian',
  };
  return languageNames[langCode] ?? langCode.toUpperCase();
}
