import 'package:flutter/material.dart';
import 'package:get/get.dart'
    hide Rx, RxBool, RxInt, RxDouble, RxString, RxList, RxMap, Obx, Worker;
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:epub_viewer_pro/epub_viewer_pro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _darkMode = RxBool(false);
  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
          title: 'EPUB Viewer Pro Demo',
          theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
          darkTheme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true, brightness: Brightness.dark),
          themeMode: _darkMode.value ? ThemeMode.dark : ThemeMode.light,
          home: HomePage(appDarkMode: _darkMode),
        ));
  }
}

class HomePage extends StatefulWidget {
  final RxBool appDarkMode;
  const HomePage({super.key, required this.appDarkMode});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Theme
  Color _primaryColor = Colors.deepPurple;
  Color _lightBg = Colors.white;
  Color _darkBg = const Color(0xFF121212);
  Color _sepiaBg = const Color(0xFFF5E6C8);
  double _cardRadius = 12.0;
  // Features
  bool _enableBookmarks = true, _enableHighlights = true, _enableNotes = true;
  bool _enableAnnotations = true, _enableSearch = true, _enableTextSelection = true;
  bool _enableTOC = true, _enableAutoScroll = true, _enableDarkModeToggle = true;
  bool _enableFullscreen = true, _enableFontSize = true, _enableFontFamily = true;
  bool _enableLineHeight = true, _enableMargin = true, _enableScreenProtection = false;
  bool _enableKeepScreenOn = true, _enableSessionTracking = true;
  bool _enableSettings = true, _enableChapterNavigation = true;
  bool _isSamplePreview = false;
  String? _bookLanguage;
  // Service
  bool _enableCustomAuth = false;
  final _apiKeyController = TextEditingController(text: 'your-api-key');
  final _bookIdController = TextEditingController(text: '0');

  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); }

  @override
  void dispose() { _tabController.dispose(); _apiKeyController.dispose(); _bookIdController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Viewer Pro'),
        centerTitle: true,
        actions: [
          Obx(() => IconButton(
                icon: Icon(widget.appDarkMode.value ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => widget.appDarkMode.value = !widget.appDarkMode.value,
              )),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.tune), text: 'Features'),
          Tab(icon: Icon(Icons.palette), text: 'Theme'),
          Tab(icon: Icon(Icons.cloud_sync), text: 'Service'),
        ]),
      ),
      body: SafeArea(
        child: Column(children: [
          _buildOpenButtons(),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              _buildFeaturesTab(),
              _buildThemeTab(),
              _buildServiceTab(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildOpenButtons() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: FilledButton.icon(onPressed: _openFromFile, icon: const Icon(Icons.file_open, size: 18), label: const Text('Open EPUB File'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(onPressed: _openFromUrl, icon: const Icon(Icons.link, size: 18), label: const Text('Open from URL'))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _openMinimal, icon: const Icon(Icons.remove_red_eye, size: 18), label: const Text('Minimal Viewer'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: _openReadOnly, icon: const Icon(Icons.menu_book, size: 18), label: const Text('Read-Only Viewer'))),
      ]),
    ]),
  );

  Widget _buildFeaturesTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('Quick Presets'),
    Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: () => _applyPreset('all'), icon: const Icon(Icons.check_circle, size: 16, color: Colors.green), label: const Text('All', style: TextStyle(color: Colors.green, fontSize: 12)))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () => _applyPreset('minimal'), icon: const Icon(Icons.minimize, size: 16, color: Colors.orange), label: const Text('Minimal', style: TextStyle(color: Colors.orange, fontSize: 12)))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () => _applyPreset('readOnly'), icon: const Icon(Icons.chrome_reader_mode, size: 16, color: Colors.blue), label: const Text('Read-Only', style: TextStyle(color: Colors.blue, fontSize: 12)))),
    ]),
    const SizedBox(height: 16),
    _sectionHeader('Book Configuration'),
    TextFormField(controller: _bookIdController, decoration: const InputDecoration(labelText: 'Book ID (for bookmarks/notes storage)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.book)), keyboardType: TextInputType.number),
    const SizedBox(height: 12),
    DropdownButtonFormField<String?>(
      initialValue: _bookLanguage,
      decoration: const InputDecoration(labelText: 'Book Language (optional)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.language)),
      items: const [
        DropdownMenuItem(value: null, child: Text('Auto-detect')),
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'ta', child: Text('Tamil')),
        DropdownMenuItem(value: 'hi', child: Text('Hindi')),
        DropdownMenuItem(value: 'ar', child: Text('Arabic (RTL)')),
        DropdownMenuItem(value: 'zh', child: Text('Chinese')),
        DropdownMenuItem(value: 'ja', child: Text('Japanese')),
      ],
      onChanged: (v) => setState(() => _bookLanguage = v),
    ),
    SwitchListTile.adaptive(title: const Text('Sample Preview Mode'), subtitle: const Text('Limits reading to first few chapters'), value: _isSamplePreview, dense: true, contentPadding: EdgeInsets.zero, onChanged: (v) => setState(() => _isSamplePreview = v)),
    const SizedBox(height: 16),
    _sectionHeader('Reading & Annotations'),
    _featureSwitch('Bookmarks', 'Save and navigate to positions', Icons.bookmark, _enableBookmarks, (v) => setState(() => _enableBookmarks = v)),
    _featureSwitch('Highlights', 'Highlight text in multiple colors', Icons.highlight, _enableHighlights, (v) => setState(() => _enableHighlights = v)),
    _featureSwitch('Notes', 'Add text notes to passages', Icons.note, _enableNotes, (v) => setState(() => _enableNotes = v)),
    _featureSwitch('Annotations', 'Drawing and freeform annotations', Icons.edit, _enableAnnotations, (v) => setState(() => _enableAnnotations = v)),
    _featureSwitch('Text Selection', 'Select and copy text', Icons.text_fields, _enableTextSelection, (v) => setState(() => _enableTextSelection = v)),
    const SizedBox(height: 16),
    _sectionHeader('Navigation'),
    _featureSwitch('Table of Contents', 'Slide-in TOC drawer', Icons.list, _enableTOC, (v) => setState(() => _enableTOC = v)),
    _featureSwitch('Chapter Navigation', 'Prev/Next chapter buttons', Icons.arrow_forward, _enableChapterNavigation, (v) => setState(() => _enableChapterNavigation = v)),
    _featureSwitch('Search', 'Full-text search within book', Icons.search, _enableSearch, (v) => setState(() => _enableSearch = v)),
    _featureSwitch('Auto-scroll', 'Timed automatic chapter advance', Icons.play_arrow, _enableAutoScroll, (v) => setState(() => _enableAutoScroll = v)),
    const SizedBox(height: 16),
    _sectionHeader('Display Controls'),
    _featureSwitch('Dark Mode Toggle', 'Light/Dark/Sepia switch', Icons.dark_mode, _enableDarkModeToggle, (v) => setState(() => _enableDarkModeToggle = v)),
    _featureSwitch('Fullscreen', 'Hide system UI while reading', Icons.fullscreen, _enableFullscreen, (v) => setState(() => _enableFullscreen = v)),
    _featureSwitch('Font Size Control', 'Adjust text size slider', Icons.format_size, _enableFontSize, (v) => setState(() => _enableFontSize = v)),
    _featureSwitch('Font Family', '25+ language font selector', Icons.font_download, _enableFontFamily, (v) => setState(() => _enableFontFamily = v)),
    _featureSwitch('Line Height', 'Adjust line spacing', Icons.format_line_spacing, _enableLineHeight, (v) => setState(() => _enableLineHeight = v)),
    _featureSwitch('Margin Control', 'Adjust page margins', Icons.margin, _enableMargin, (v) => setState(() => _enableMargin = v)),
    _featureSwitch('Settings Panel', 'Bottom sheet with all display options', Icons.settings, _enableSettings, (v) => setState(() => _enableSettings = v)),
    const SizedBox(height: 16),
    _sectionHeader('Security & Tracking'),
    _featureSwitch('Screen Protection', 'Prevent screenshots/recording (DRM)', Icons.security, _enableScreenProtection, (v) => setState(() => _enableScreenProtection = v)),
    _featureSwitch('Keep Screen On', 'Prevent device from sleeping', Icons.brightness_high, _enableKeepScreenOn, (v) => setState(() => _enableKeepScreenOn = v)),
    _featureSwitch('Session Tracking', 'Track reading duration and progress', Icons.analytics, _enableSessionTracking, (v) => setState(() => _enableSessionTracking = v)),
    const SizedBox(height: 24),
  ]);

  Widget _buildThemeTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('Accent / Primary Color'),
    _colorRow([Colors.deepPurple, Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.teal, Colors.pink, Colors.indigo], _primaryColor, (c) => setState(() => _primaryColor = c)),
    const SizedBox(height: 16),
    _sectionHeader('Light Background'),
    _colorRow([Colors.white, const Color(0xFFF5F5F5), const Color(0xFFFFF8E1), const Color(0xFFE8F5E9), const Color(0xFFE3F2FD)], _lightBg, (c) => setState(() => _lightBg = c)),
    const SizedBox(height: 16),
    _sectionHeader('Sepia Background'),
    _colorRow([const Color(0xFFF5E6C8), const Color(0xFFF4E4BA), const Color(0xFFE8D5B7), const Color(0xFFFFF3E0), const Color(0xFFEDE0C8)], _sepiaBg, (c) => setState(() => _sepiaBg = c)),
    const SizedBox(height: 16),
    _sectionHeader('Dark Background'),
    _colorRow([const Color(0xFF121212), const Color(0xFF1a1a1a), const Color(0xFF212121), const Color(0xFF263238), const Color(0xFF1C1B1F)], _darkBg, (c) => setState(() => _darkBg = c)),
    const SizedBox(height: 16),
    _sectionHeader('Card Border Radius'),
    Row(children: [
      const Text('0'),
      Expanded(child: Slider.adaptive(value: _cardRadius, min: 0, max: 24, divisions: 12, label: _cardRadius.round().toString(), onChanged: (v) => setState(() => _cardRadius = v))),
      const Text('24'),
      const SizedBox(width: 8),
      Text('${_cardRadius.round()}px', style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
    const SizedBox(height: 24),
  ]);

  Widget _buildServiceTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('HTTP Headers (for authenticated file downloads)'),
    SwitchListTile.adaptive(title: const Text('Custom HTTP Headers'), subtitle: const Text('Attach Authorization / API key to file requests'), value: _enableCustomAuth, contentPadding: EdgeInsets.zero, onChanged: (v) => setState(() => _enableCustomAuth = v)),
    if (_enableCustomAuth) ...[
      const SizedBox(height: 8),
      TextFormField(controller: _apiKeyController, decoration: const InputDecoration(labelText: 'API Key / Bearer Token', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.key))),
    ],
    const SizedBox(height: 16),
    _sectionHeader('Available Server Sync Callbacks'),
    _callbackInfo('onBookmarksSync', 'Upload changed bookmarks to server'),
    _callbackInfo('onBookmarksLoad', 'Download bookmarks from server on init'),
    _callbackInfo('onHighlightsSync', 'Upload changed highlights'),
    _callbackInfo('onNotesSync', 'Upload changed notes'),
    _callbackInfo('onAnnotationsSync', 'Upload drawing annotations'),
    _callbackInfo('onAnnotationsLoad', 'Download annotations on init'),
    _callbackInfo('onSessionStart', 'Called when user opens book'),
    _callbackInfo('onSessionEnd', 'Called with duration + progress on close'),
    _callbackInfo('onProgressSync', 'Called periodically with reading progress %'),
    const SizedBox(height: 16),
    const Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Custom Storage', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Provide a PluginStorage implementation to use Hive, SharedPreferences, or any custom backend instead of the default GetStorage.', style: TextStyle(fontSize: 13)),
    ]))),
    const SizedBox(height: 24),
  ]);

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary, letterSpacing: 0.5)),
  );

  Widget _featureSwitch(String title, String subtitle, IconData icon, bool value, void Function(bool) onChanged) => SwitchListTile.adaptive(
    title: Row(children: [Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 14))]),
    subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
    value: value, dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    onChanged: onChanged,
  );

  Widget _colorRow(List<Color> colors, Color selected, void Function(Color) onSelected) => Wrap(spacing: 10, children: colors.map((c) {
    final isSelected = selected == c;
    return GestureDetector(
      onTap: () => onSelected(c),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: c,
          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400, width: isSelected ? 3 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isSelected ? Icon(Icons.check, color: ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : Colors.black, size: 18) : null,
      ),
    );
  }).toList());

  Widget _callbackInfo(String name, String description) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 4),
      Expanded(child: RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [
        TextSpan(text: '$name ', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 12)),
        TextSpan(text: '— $description', style: const TextStyle(fontSize: 12)),
      ]))),
    ]),
  );

  void _applyPreset(String preset) {
    setState(() {
      if (preset == 'all') {
        _enableBookmarks = _enableHighlights = _enableNotes = _enableAnnotations =
        _enableSearch = _enableTextSelection = _enableTOC = _enableAutoScroll =
        _enableDarkModeToggle = _enableFullscreen = _enableFontSize =
        _enableFontFamily = _enableLineHeight = _enableMargin =
        _enableKeepScreenOn = _enableSessionTracking = _enableSettings =
        _enableChapterNavigation = true;
        _enableScreenProtection = false;
      } else if (preset == 'minimal') {
        _enableBookmarks = _enableHighlights = _enableNotes = _enableAnnotations =
        _enableSearch = _enableTextSelection = _enableAutoScroll =
        _enableDarkModeToggle = _enableFullscreen = _enableFontSize =
        _enableFontFamily = _enableLineHeight = _enableMargin =
        _enableScreenProtection = _enableKeepScreenOn =
        _enableSessionTracking = _enableSettings = false;
        _enableTOC = _enableChapterNavigation = true;
      } else if (preset == 'readOnly') {
        _enableBookmarks = _enableHighlights = _enableNotes = _enableAnnotations =
        _enableScreenProtection = _enableSessionTracking = false;
        _enableSearch = _enableTextSelection = _enableTOC = _enableAutoScroll =
        _enableDarkModeToggle = _enableFullscreen = _enableFontSize =
        _enableFontFamily = _enableLineHeight = _enableMargin =
        _enableKeepScreenOn = _enableSettings = _enableChapterNavigation = true;
      }
    });
  }

  EpubViewerThemeConfig _buildThemeConfig() => EpubViewerThemeConfig(
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

  EpubViewerFeatureConfig _buildFeatureConfig() => EpubViewerFeatureConfig(
    enableBookmarks: _enableBookmarks,
    enableHighlights: _enableHighlights,
    enableNotes: _enableNotes,
    enableAnnotations: _enableAnnotations,
    enableSearch: _enableSearch,
    enableTextSelection: _enableTextSelection,
    enableTableOfContents: _enableTOC,
    enableAutoScroll: _enableAutoScroll,
    enableDarkModeToggle: _enableDarkModeToggle,
    enableFullscreen: _enableFullscreen,
    enableFontSizeControl: _enableFontSize,
    enableFontFamilyControl: _enableFontFamily,
    enableLineHeightControl: _enableLineHeight,
    enableMarginControl: _enableMargin,
    enableScreenProtection: _enableScreenProtection,
    enableKeepScreenOn: _enableKeepScreenOn,
    enableSessionTracking: _enableSessionTracking,
    enableSettings: _enableSettings,
    enableChapterNavigation: _enableChapterNavigation,
  );

  EpubViewerServiceConfig _buildServiceConfig() => EpubViewerServiceConfig(
    onMessage: (message, type) {
      final color = type == ViewerMessageType.error ? Colors.red : type == ViewerMessageType.warning ? Colors.orange : Colors.green;
      Get.snackbar(type.name.toUpperCase(), message, snackPosition: SnackPosition.BOTTOM, backgroundColor: color.withValues(alpha: 0.9), colorText: Colors.white, duration: const Duration(seconds: 3));
    },
    httpHeaders: _enableCustomAuth ? {'Authorization': 'Bearer ${_apiKeyController.text}'} : null,
  );

  void _openFromFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['epub']);
    if (result != null && result.files.single.path != null) {
      Get.to(() => EpubViewerScreen(
        filePath: result.files.single.path!, title: result.files.single.name.replaceAll('.epub', ''),
        bookId: int.tryParse(_bookIdController.text), bookLanguage: _bookLanguage, isSamplePreview: _isSamplePreview,
        serviceConfig: _buildServiceConfig(), themeConfig: _buildThemeConfig(), featureConfig: _buildFeatureConfig(), externalDarkMode: widget.appDarkMode,
      ));
    }
  }

  void _openFromUrl() {
    Get.to(() => EpubViewerScreen(
      fileUrl: 'https://www.gutenberg.org/ebooks/11.epub.images', title: "Alice's Adventures in Wonderland",
      bookId: int.tryParse(_bookIdController.text), serviceConfig: _buildServiceConfig(),
      themeConfig: _buildThemeConfig(), featureConfig: _buildFeatureConfig(), externalDarkMode: widget.appDarkMode,
    ));
  }

  void _openMinimal() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['epub']);
    if (result != null && result.files.single.path != null) {
      Get.to(() => EpubViewerScreen(
        filePath: result.files.single.path!, title: result.files.single.name.replaceAll('.epub', ''),
        featureConfig: EpubViewerFeatureConfig.minimal, externalDarkMode: widget.appDarkMode,
      ));
    }
  }

  void _openReadOnly() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['epub']);
    if (result != null && result.files.single.path != null) {
      Get.to(() => EpubViewerScreen(
        filePath: result.files.single.path!, title: result.files.single.name.replaceAll('.epub', ''),
        featureConfig: EpubViewerFeatureConfig.readOnly, themeConfig: _buildThemeConfig(), externalDarkMode: widget.appDarkMode,
      ));
    }
  }
}