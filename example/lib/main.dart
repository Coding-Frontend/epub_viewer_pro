import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:epub_viewer_pro/epub_viewer_pro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EPUB Viewer Pro Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Theme configuration
  Color _primaryColor = Colors.deepPurple;
  bool _useDarkMode = false;
  final _darkMode = false.obs;

  // Feature toggles
  bool _enableBookmarks = true;
  bool _enableHighlights = true;
  bool _enableNotes = true;
  bool _enableSearch = true;
  bool _enableTableOfContents = true;
  bool _enableFontSizeControl = true;
  bool _enableFontFamilyControl = true;
  bool _enableScreenProtection = false;
  bool _enableSettings = true;
  bool _enableFullscreen = true;
  bool _enableChapterNavigation = true;

  // Theme customization
  Color _lightBg = Colors.white;
  Color _darkBg = const Color(0xFF121212);
  Color _sepiaBg = const Color(0xFFF5E6C8);
  double _cardRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Viewer Pro Example'),
        actions: [
          IconButton(
            icon: Icon(_useDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _useDarkMode = !_useDarkMode;
                _darkMode.value = _useDarkMode;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === Open EPUB Buttons ===
            FilledButton.icon(
              onPressed: _openEpubFromFile,
              icon: const Icon(Icons.file_open),
              label: const Text('Open EPUB from Device'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openMinimalViewer,
              icon: const Icon(Icons.remove_red_eye),
              label: const Text('Open Minimal Viewer (No Extras)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openReadOnlyViewer,
              icon: const Icon(Icons.menu_book),
              label: const Text('Open Read-Only Viewer'),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // === Theme Configuration ===
            const Text(
              'Theme Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Primary color picker
            const Text('Primary Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Colors.deepPurple,
                Colors.blue,
                Colors.red,
                Colors.green,
                Colors.orange,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
              ]
                  .map((color) => GestureDetector(
                        onTap: () => setState(() => _primaryColor = color),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: color,
                          child: _primaryColor == color
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Card border radius
            Row(
              children: [
                const Text('Card Border Radius: '),
                Expanded(
                  child: Slider(
                    value: _cardRadius,
                    min: 0,
                    max: 24,
                    divisions: 12,
                    label: _cardRadius.round().toString(),
                    onChanged: (v) => setState(() => _cardRadius = v),
                  ),
                ),
              ],
            ),

            // Light background color
            const Text('Light Background'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Colors.white,
                const Color(0xFFF5F5F5),
                const Color(0xFFFFF8E1),
                const Color(0xFFE8F5E9),
              ]
                  .map((color) => GestureDetector(
                        onTap: () => setState(() => _lightBg = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: _lightBg == color
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: _lightBg == color ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            // Sepia background color
            const SizedBox(height: 8),
            const Text('Sepia Background'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                const Color(0xFFF5E6C8),
                const Color(0xFFF4E4BA),
                const Color(0xFFE8D5B7),
                const Color(0xFFFFF3E0),
              ]
                  .map((color) => GestureDetector(
                        onTap: () => setState(() => _sepiaBg = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: _sepiaBg == color
                                  ? Colors.brown
                                  : Colors.grey.shade300,
                              width: _sepiaBg == color ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            // Dark background color
            const SizedBox(height: 8),
            const Text('Dark Background'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                const Color(0xFF121212),
                const Color(0xFF1a1a1a),
                const Color(0xFF212121),
                const Color(0xFF263238),
              ]
                  .map((color) => GestureDetector(
                        onTap: () => setState(() => _darkBg = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: _darkBg == color
                                  ? Colors.blue
                                  : Colors.grey.shade600,
                              width: _darkBg == color ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // === Feature Toggles ===
            const Text(
              'Feature Toggles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _featureSwitch('Bookmarks', _enableBookmarks,
                (v) => setState(() => _enableBookmarks = v)),
            _featureSwitch('Highlights', _enableHighlights,
                (v) => setState(() => _enableHighlights = v)),
            _featureSwitch(
                'Notes', _enableNotes, (v) => setState(() => _enableNotes = v)),
            _featureSwitch('Search', _enableSearch,
                (v) => setState(() => _enableSearch = v)),
            _featureSwitch('Table of Contents', _enableTableOfContents,
                (v) => setState(() => _enableTableOfContents = v)),
            _featureSwitch('Font Size Control', _enableFontSizeControl,
                (v) => setState(() => _enableFontSizeControl = v)),
            _featureSwitch('Font Family Control', _enableFontFamilyControl,
                (v) => setState(() => _enableFontFamilyControl = v)),
            _featureSwitch('Screen Protection', _enableScreenProtection,
                (v) => setState(() => _enableScreenProtection = v)),
            _featureSwitch('Settings Panel', _enableSettings,
                (v) => setState(() => _enableSettings = v)),
            _featureSwitch('Fullscreen', _enableFullscreen,
                (v) => setState(() => _enableFullscreen = v)),
            _featureSwitch('Chapter Navigation', _enableChapterNavigation,
                (v) => setState(() => _enableChapterNavigation = v)),
          ],
        ),
      ),
      ),
    );
  }

  Widget _featureSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  EpubViewerThemeConfig _buildThemeConfig() {
    return EpubViewerThemeConfig(
      primaryColor: _primaryColor,
      lightBackgroundColor: _lightBg,
      darkBackgroundColor: _darkBg,
      sepiaBackgroundColor: _sepiaBg,
      cardBorderRadius: _cardRadius,
      bookmarkColor: _primaryColor,
      highlightColor: _primaryColor.withValues(alpha: 0.3),
      progressColor: _primaryColor,
      loadingIndicatorColor: _primaryColor,
    );
  }

  EpubViewerFeatureConfig _buildFeatureConfig() {
    return EpubViewerFeatureConfig(
      enableBookmarks: _enableBookmarks,
      enableHighlights: _enableHighlights,
      enableNotes: _enableNotes,
      enableSearch: _enableSearch,
      enableTableOfContents: _enableTableOfContents,
      enableFontSizeControl: _enableFontSizeControl,
      enableFontFamilyControl: _enableFontFamilyControl,
      enableScreenProtection: _enableScreenProtection,
      enableSettings: _enableSettings,
      enableFullscreen: _enableFullscreen,
      enableChapterNavigation: _enableChapterNavigation,
    );
  }

  EpubViewerServiceConfig _buildServiceConfig() {
    return EpubViewerServiceConfig(
      onMessage: (message, type) {
        final color = type == ViewerMessageType.error
            ? Colors.red
            : type == ViewerMessageType.warning
                ? Colors.orange
                : Colors.green;
        Get.snackbar(
          type.name.toUpperCase(),
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: color.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
    );
  }

  Future<void> _openEpubFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result != null && result.files.single.path != null) {
      Get.to(() => EpubViewerScreen(
            filePath: result.files.single.path!,
            title: result.files.single.name,
            serviceConfig: _buildServiceConfig(),
            themeConfig: _buildThemeConfig(),
            featureConfig: _buildFeatureConfig(),
            externalDarkMode: _darkMode,
          ));
    }
  }

  Future<void> _openMinimalViewer() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result != null && result.files.single.path != null) {
      Get.to(() => EpubViewerScreen(
            filePath: result.files.single.path!,
            title: result.files.single.name,
            featureConfig: EpubViewerFeatureConfig.minimal,
            themeConfig: EpubViewerThemeConfig(
              primaryColor: Colors.grey,
              lightBackgroundColor: const Color(0xFFFAFAFA),
              darkBackgroundColor: const Color(0xFF1E1E1E),
            ),
          ));
    }
  }

  Future<void> _openReadOnlyViewer() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result != null && result.files.single.path != null) {
      Get.to(() => EpubViewerScreen(
            filePath: result.files.single.path!,
            title: result.files.single.name,
            featureConfig: EpubViewerFeatureConfig.readOnly,
            themeConfig: _buildThemeConfig(),
          ));
    }
  }
}
