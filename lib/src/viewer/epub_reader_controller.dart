import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:epubx/epubx.dart' as epub;
import 'package:screen_protector/screen_protector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../service_config.dart';
import '../viewer_theme_config.dart';
import '../feature_config.dart';
import '../annotations/annotation_models.dart';
import '../annotations/annotation_toolbar.dart';

/// Controller for EPUB Reader using GetX state management
/// Uses epubx for parsing, flutter_widget_from_html for rendering
class EpubReaderController extends GetxController {
  final String? filePath;
  final String? fileUrl;
  final String title;
  final int? bookId;
  final bool isSamplePreview;
  final String? bookLanguage;
  final EpubViewerServiceConfig serviceConfig;
  final EpubViewerThemeConfig themeConfig;
  final EpubViewerFeatureConfig featureConfig;
  final RxBool? externalDarkMode;

  EpubReaderController({
    this.filePath,
    this.fileUrl,
    required this.title,
    this.bookId,
    this.isSamplePreview = false,
    this.bookLanguage,
    this.serviceConfig = const EpubViewerServiceConfig(),
    this.themeConfig = const EpubViewerThemeConfig(),
    this.featureConfig = const EpubViewerFeatureConfig(),
    this.externalDarkMode,
  });

  final GetStorage _storage = GetStorage();

  // EPUB Document
  epub.EpubBook? epubBook;
  String? _resolvedFilePath;

  // Loading State
  final isLoading = true.obs;
  final error = ''.obs;
  final loadingProgress = 0.0.obs;

  // UI State
  final showControls = true.obs;
  final showToc = false.obs;
  final isFullscreen = false.obs;
  final keepScreenOn = false.obs;

  // Reading State
  final currentChapterIndex = 0.obs;
  final totalChapters = 0.obs;
  final progress = 0.0.obs;
  final currentChapterTitle = ''.obs;
  final currentChapterHtml = ''.obs;
  final scrollOffset = 0.0.obs;

  // Chapters
  final chapters = <ChapterInfo>[].obs;
  final chapterContents = <int, String>{}.obs;

  // Settings
  final isDarkMode = false.obs;
  final fontSize = 16.0.obs;
  final fontFamily = 'Default'.obs;
  final lineHeight = 1.5.obs;
  final marginSize = 16.0.obs;

  // Auto-scroll
  final isAutoScrolling = false.obs;
  final autoScrollIntervalSeconds = 30.obs;
  final autoScrollProgress = 0.0.obs;
  Timer? _autoScrollTimer;
  Timer? _autoScrollProgressTimer;

  // Bookmarks
  final bookmarks = <BookmarkInfo>[].obs;
  final highlights = <HighlightInfo>[].obs;
  final notes = <NoteInfo>[].obs;

  // Search
  final isSearchMode = false.obs;
  final searchQuery = ''.obs;
  final searchResults = <SearchResult>[].obs;
  final currentSearchIndex = 0.obs;

  // Annotations
  late final AnnotationToolbarController annotationController;
  final pageAnnotations = <int, PageAnnotations>{}.obs;
  final showAnnotationToolbar = false.obs;
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];

  // Undo/Redo state getters
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // Session tracking
  DateTime? _sessionStartTime;
  Timer? _autoSaveTimer;
  Timer? _controlsHideTimer;
  Worker? _themeListener;

  // Font families - reactive based on epub language
  final fontFamilies =
      <String>['Default', 'Serif', 'Sans-serif', 'Monospace'].obs;
  final epubLanguage = ''.obs;

  // Language to Google Fonts mapping (top 6 fonts per language)
  static const Map<String, List<String>> languageFonts = {
    'en': [
      'Roboto',
      'Open Sans',
      'Lora',
      'Merriweather',
      'Playfair Display',
      'Poppins'
    ],
    'hi': [
      'Noto Sans Devanagari',
      'Poppins',
      'Hind',
      'Mukta',
      'Tiro Devanagari Hindi',
      'Laila'
    ],
    'bn': [
      'Noto Sans Bengali',
      'Hind Siliguri',
      'Atma',
      'Galada',
      'Mina',
      'Baloo Da 2'
    ],
    'ta': [
      'Noto Sans Tamil',
      'Mukta Malar',
      'Catamaran',
      'Meera Inimai',
      'Anek Tamil',
      'Arima'
    ],
    'te': [
      'Noto Sans Telugu',
      'Ramabhadra',
      'Mandali',
      'Mallanna',
      'Timmana',
      'Tenali Ramakrishna'
    ],
    'mr': [
      'Noto Sans Devanagari',
      'Mukta',
      'Hind',
      'Tiro Devanagari Marathi',
      'Poppins',
      'Laila'
    ],
    'gu': [
      'Noto Sans Gujarati',
      'Mukta Vaani',
      'Hind Vadodara',
      'Rasa',
      'Ek Mukta',
      'Shrikhand'
    ],
    'kn': [
      'Noto Sans Kannada',
      'Teko',
      'Baloo Tamma 2',
      'Akaya Kanadaka',
      'Benne',
      'Kavoon'
    ],
    'ml': [
      'Noto Sans Malayalam',
      'Manjari',
      'Chilanka',
      'Gayathri',
      'Baloo Chettan 2',
      'Meera'
    ],
    'pa': [
      'Noto Sans Gurmukhi',
      'Mukta Mahee',
      'Baloo Paaji 2',
      'Gotu',
      'Poppins',
      'Tiro Gurmukhi'
    ],
    'or': [
      'Noto Sans Oriya',
      'Baloo Bhaina 2',
      'Gotu',
      'Poppins',
      'Roboto',
      'Open Sans'
    ],
    'sa': [
      'Noto Sans Devanagari',
      'Tiro Devanagari Sanskrit',
      'Poppins',
      'Hind',
      'Mukta',
      'Laila'
    ],
    'ar': [
      'Noto Sans Arabic',
      'Amiri',
      'Cairo',
      'Tajawal',
      'Lateef',
      'Scheherazade New'
    ],
    'ur': [
      'Noto Nastaliq Urdu',
      'Noto Sans Arabic',
      'Amiri',
      'Scheherazade New',
      'Lateef',
      'Nafees'
    ],
    'zh': [
      'Noto Sans SC',
      'Noto Serif SC',
      'ZCOOL XiaoWei',
      'Ma Shan Zheng',
      'Liu Jian Mao Cao',
      'ZCOOL QingKe HuangYou'
    ],
    'ja': [
      'Noto Sans JP',
      'Noto Serif JP',
      'Kosugi Maru',
      'Sawarabi Gothic',
      'M PLUS Rounded 1c',
      'Zen Maru Gothic'
    ],
    'ko': [
      'Noto Sans KR',
      'Noto Serif KR',
      'Gothic A1',
      'Jua',
      'Sunflower',
      'Do Hyeon'
    ],
    'th': [
      'Noto Sans Thai',
      'Kanit',
      'Sarabun',
      'Prompt',
      'Mitr',
      'Chakra Petch'
    ],
    'vi': [
      'Noto Sans',
      'Roboto',
      'Open Sans',
      'Be Vietnam Pro',
      'Quicksand',
      'Nunito'
    ],
    'ru': [
      'Roboto',
      'Open Sans',
      'PT Sans',
      'PT Serif',
      'Fira Sans',
      'Montserrat'
    ],
    'de': ['Roboto', 'Open Sans', 'Lato', 'Fira Sans', 'Nunito', 'Work Sans'],
    'fr': [
      'Roboto',
      'Open Sans',
      'Lato',
      'Playfair Display',
      'Nunito',
      'Poppins'
    ],
    'es': ['Roboto', 'Open Sans', 'Lato', 'Nunito', 'Poppins', 'Montserrat'],
    'pt': ['Roboto', 'Open Sans', 'Lato', 'Nunito', 'Poppins', 'Montserrat'],
    'it': [
      'Roboto',
      'Open Sans',
      'Lato',
      'Playfair Display',
      'Nunito',
      'Poppins'
    ],
  };

  // Get TextStyle for a Google Font
  TextStyle getGoogleFontStyle(String fontName,
      {double? fontSize, FontWeight? fontWeight, Color? color}) {
    try {
      return GoogleFonts.getFont(
        fontName,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } catch (e) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }

  /// Helper to show a message via serviceConfig or fallback to snackbar
  void _showMessage(String message, ViewerMessageType type) {
    if (serviceConfig.onMessage != null) {
      serviceConfig.onMessage!(message, type);
    } else {
      Get.snackbar(
        type == ViewerMessageType.error ? 'Error' : 'Info',
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    annotationController = AnnotationToolbarController();
    _enableScreenProtector();
    _loadPreferences();
    _initializeReader();

    // Listen for external theme changes if provided
    if (externalDarkMode != null) {
      _themeListener = ever(externalDarkMode!, (value) {
        isDarkMode.value = value;
      });
    }
  }

  @override
  void onClose() {
    _endReadingSession();
    _syncAnnotationsToServer();
    annotationController.dispose();
    _themeListener?.dispose();
    _autoSaveTimer?.cancel();
    _controlsHideTimer?.cancel();
    _autoScrollTimer?.cancel();
    _autoScrollProgressTimer?.cancel();
    _disableScreenProtector();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }

  int get _bookIdForStorage => bookId ?? 0;

  // ============= Security =============

  Future<void> _enableScreenProtector() async {
    try {
      if (Platform.isAndroid) {
        await ScreenProtector.protectDataLeakageOn();
      } else if (Platform.isIOS) {
        await ScreenProtector.preventScreenshotOn();
        await ScreenProtector.protectDataLeakageWithBlur();
      }
    } catch (e) {
      debugPrint('screen_protector enable failed: $e');
    }
  }

  Future<void> _disableScreenProtector() async {
    try {
      if (Platform.isAndroid) {
        await ScreenProtector.protectDataLeakageOff();
      } else if (Platform.isIOS) {
        await ScreenProtector.preventScreenshotOff();
        await ScreenProtector.protectDataLeakageWithBlurOff();
      }
    } catch (e) {
      debugPrint('screen_protector disable failed: $e');
    }
  }

  // ============= Initialization =============

  Future<void> _initializeReader() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Determine file path
      if (filePath != null && filePath!.isNotEmpty) {
        _resolvedFilePath = filePath;
      } else if (fileUrl != null && fileUrl!.isNotEmpty) {
        // Check if URL needs authentication
        if (fileUrl!.contains('/api/') && serviceConfig.authToken != null) {
          _resolvedFilePath = await _downloadAuthenticatedFile(fileUrl!);
          if (_resolvedFilePath == null) {
            error.value = 'Failed to download EPUB file';
            isLoading.value = false;
            return;
          }
        } else {
          _resolvedFilePath = await _downloadPublicFile(fileUrl!);
          if (_resolvedFilePath == null) {
            error.value = 'Failed to download EPUB file';
            isLoading.value = false;
            return;
          }
        }
      }

      if (_resolvedFilePath == null || _resolvedFilePath!.isEmpty) {
        error.value = 'No file path provided';
        isLoading.value = false;
        return;
      }

      // Parse EPUB using epubx
      await _parseEpub();

      // Load saved position
      await _loadSavedPosition();

      // Load bookmarks
      await _loadBookmarks();

      // Load annotations
      await _loadAnnotations();

      _startReadingSession();

      _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        saveProgress();
      });

      isLoading.value = false;
    } catch (e) {
      error.value = 'Error initializing reader: $e';
      isLoading.value = false;
    }
  }

  /// Download file from authenticated API endpoint with caching
  Future<String?> _downloadAuthenticatedFile(String url) async {
    try {
      loadingProgress.value = 0.0;

      final token = serviceConfig.authToken;
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login first.');
      }

      final fileIdMatch = RegExp(r'/files/(\d+)/').firstMatch(url);
      final fileId = fileIdMatch?.group(1) ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final tempDir = await getTemporaryDirectory();
      final fileName = 'epub_$fileId.epub';
      final localPath = '${tempDir.path}/$fileName';

      // Check if file already exists (cached)
      final cachedFile = File(localPath);
      if (await cachedFile.exists()) {
        final fileSize = await cachedFile.length();
        if (fileSize > 0) {
          debugPrint('Using cached EPUB: $localPath ($fileSize bytes)');
          loadingProgress.value = 1.0;
          return localPath;
        }
      }

      debugPrint('Downloading EPUB from: $url');

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/epub+zip';

        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode == 200) {
          final contentLength = streamedResponse.contentLength ?? 0;
          final List<int> bytes = [];
          int downloaded = 0;

          await for (final chunk in streamedResponse.stream) {
            bytes.addAll(chunk);
            downloaded += chunk.length;

            if (contentLength > 0) {
              loadingProgress.value =
                  (downloaded / contentLength).clamp(0.0, 0.99);
            }
          }

          final file = File(localPath);
          await file.writeAsBytes(bytes);
          loadingProgress.value = 1.0;
          return localPath;
        } else {
          debugPrint(
              'Download failed with status ${streamedResponse.statusCode}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error downloading EPUB: $e');
      return null;
    }
  }

  /// Download file from public URL
  Future<String?> _downloadPublicFile(String url) async {
    try {
      loadingProgress.value = 0.0;

      final tempDir = await getTemporaryDirectory();
      final fileName = 'epub_${DateTime.now().millisecondsSinceEpoch}.epub';
      final localPath = '${tempDir.path}/$fileName';

      debugPrint('Downloading public EPUB from: $url');

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode == 200) {
          final contentLength = streamedResponse.contentLength ?? 0;
          final List<int> bytes = [];
          int downloaded = 0;

          await for (final chunk in streamedResponse.stream) {
            bytes.addAll(chunk);
            downloaded += chunk.length;

            if (contentLength > 0) {
              loadingProgress.value =
                  (downloaded / contentLength).clamp(0.0, 0.99);
            }
          }

          final file = File(localPath);
          await file.writeAsBytes(bytes);
          loadingProgress.value = 1.0;
          return localPath;
        } else {
          debugPrint(
              'Download failed with status ${streamedResponse.statusCode}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error downloading EPUB: $e');
      return null;
    }
  }

  Future<void> loadEpub() async {
    await _initializeReader();
  }

  Future<void> _parseEpub() async {
    try {
      final file = File(_resolvedFilePath!);
      if (!await file.exists()) {
        throw Exception('EPUB file not found');
      }

      final bytes = await file.readAsBytes();
      epubBook = await epub.EpubReader.readBook(bytes);

      if (epubBook == null) {
        throw Exception('Failed to parse EPUB');
      }

      // Extract language and update font families
      _extractLanguageAndUpdateFonts();

      // Extract chapters
      _extractChapters();

      // Load first chapter
      if (chapters.isNotEmpty) {
        await loadChapter(0);
      }
    } catch (e) {
      throw Exception('Failed to parse EPUB: $e');
    }
  }

  /// Extract language from epub metadata and update available fonts
  void _extractLanguageAndUpdateFonts() {
    String? language;

    try {
      if (epubBook?.Schema?.Package?.Metadata?.Languages != null &&
          epubBook!.Schema!.Package!.Metadata!.Languages!.isNotEmpty) {
        language = epubBook!.Schema!.Package!.Metadata!.Languages!.first;
      }
    } catch (e) {
      debugPrint('Error extracting epub language: $e');
    }

    // If no language from EPUB metadata, use book language from database model
    if ((language == null || language.isEmpty) && bookLanguage != null) {
      language = _mapLanguageNameToCode(bookLanguage!);
      debugPrint(
          'Using book language from database: $bookLanguage -> $language');
    }

    // Extract language code (e.g., 'en-US' -> 'en', 'hi-IN' -> 'hi')
    if (language != null && language.isNotEmpty) {
      final langCode = language.split('-').first.toLowerCase();
      epubLanguage.value = langCode;

      if (languageFonts.containsKey(langCode)) {
        fontFamilies.value = ['Default', ...languageFonts[langCode]!];
      } else {
        fontFamilies.value = ['Default', ...languageFonts['en']!];
      }
    } else {
      epubLanguage.value = 'en';
      fontFamilies.value = ['Default', ...languageFonts['en']!];
    }

    if (!fontFamilies.contains(fontFamily.value)) {
      fontFamily.value = 'Default';
    }
  }

  /// Map language name to ISO 639-1 code
  String _mapLanguageNameToCode(String languageName) {
    final name = languageName.toLowerCase().trim();
    const nameToCode = {
      'english': 'en',
      'hindi': 'hi',
      'bengali': 'bn',
      'tamil': 'ta',
      'telugu': 'te',
      'marathi': 'mr',
      'gujarati': 'gu',
      'kannada': 'kn',
      'malayalam': 'ml',
      'punjabi': 'pa',
      'odia': 'or',
      'oriya': 'or',
      'sanskrit': 'sa',
      'arabic': 'ar',
      'urdu': 'ur',
      'chinese': 'zh',
      'japanese': 'ja',
      'korean': 'ko',
      'thai': 'th',
      'vietnamese': 'vi',
      'russian': 'ru',
      'german': 'de',
      'french': 'fr',
      'spanish': 'es',
      'portuguese': 'pt',
      'italian': 'it',
    };
    return nameToCode[name] ?? name;
  }

  void _extractChapters() {
    chapters.clear();

    if (epubBook?.Chapters == null) return;

    int index = 0;
    for (final chapter in epubBook!.Chapters!) {
      _addChapter(chapter, index, 0);
      index++;
    }

    totalChapters.value = chapters.length;
  }

  void _addChapter(epub.EpubChapter chapter, int index, int depth) {
    chapters.add(ChapterInfo(
      index: chapters.length,
      title: chapter.Title ?? 'Chapter ${index + 1}',
      depth: depth,
      contentFileName: chapter.ContentFileName,
    ));

    if (chapter.SubChapters != null) {
      int subIndex = 0;
      for (final subChapter in chapter.SubChapters!) {
        _addChapter(subChapter, subIndex, depth + 1);
        subIndex++;
      }
    }
  }

  Future<void> loadChapter(int index) async {
    if (index < 0 || index >= chapters.length) return;

    try {
      currentChapterIndex.value = index;
      currentChapterTitle.value = chapters[index].title;

      if (chapterContents.containsKey(index)) {
        currentChapterHtml.value = chapterContents[index]!;
        _updateProgress();
        return;
      }

      final chapter = _findChapterByIndex(index);
      if (chapter == null) {
        currentChapterHtml.value = '<p>Chapter content not found</p>';
        return;
      }

      String htmlContent = chapter.HtmlContent ?? '';
      htmlContent = _processChapterContent(htmlContent);

      chapterContents[index] = htmlContent;
      currentChapterHtml.value = htmlContent;

      _updateProgress();
    } catch (e) {
      debugPrint('Error loading chapter: $e');
      currentChapterHtml.value = '<p>Error loading chapter</p>';
    }
  }

  epub.EpubChapter? _findChapterByIndex(int targetIndex) {
    if (epubBook?.Chapters == null) return null;

    int currentIndex = 0;
    return _findChapterRecursive(
        epubBook!.Chapters!, targetIndex, currentIndex);
  }

  epub.EpubChapter? _findChapterRecursive(
    List<epub.EpubChapter> chapters,
    int targetIndex,
    int currentIndex,
  ) {
    for (final chapter in chapters) {
      if (currentIndex == targetIndex) {
        return chapter;
      }
      currentIndex++;

      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        final found = _findChapterRecursive(
          chapter.SubChapters!,
          targetIndex,
          currentIndex,
        );
        if (found != null) return found;
        currentIndex += _countSubChapters(chapter.SubChapters!);
      }
    }
    return null;
  }

  int _countSubChapters(List<epub.EpubChapter> chapters) {
    int count = chapters.length;
    for (final chapter in chapters) {
      if (chapter.SubChapters != null) {
        count += _countSubChapters(chapter.SubChapters!);
      }
    }
    return count;
  }

  String _processChapterContent(String html) {
    if (!html.contains('<meta name="viewport"')) {
      html = html.replaceFirst(
        '<head>',
        '<head><meta name="viewport" content="width=device-width, initial-scale=1.0">',
      );
    }

    if (epubBook?.Content?.Images != null) {
      for (final entry in epubBook!.Content!.Images!.entries) {
        final imagePath = entry.key;
        final imageContent = entry.value;

        if (imageContent.Content != null) {
          final base64 = _encodeImageToBase64(imageContent.Content!);
          final mimeType = _getMimeType(imagePath);
          final dataUri = 'data:$mimeType;base64,$base64';

          html = html.replaceAll(imagePath, dataUri);
          html = html.replaceAll('../$imagePath', dataUri);
          html = html.replaceAll('./$imagePath', dataUri);
        }
      }
    }

    return html;
  }

  String _encodeImageToBase64(List<int> bytes) {
    return Uri.dataFromBytes(bytes).toString().split(',').last;
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  void _updateProgress() {
    if (totalChapters.value > 0) {
      progress.value = (currentChapterIndex.value + 1) / totalChapters.value;
    }
  }

  // ============= Navigation =============

  void goToNextChapter() {
    if (currentChapterIndex.value < chapters.length - 1) {
      loadChapter(currentChapterIndex.value + 1);
      scrollOffset.value = 0;
    }
  }

  void goToPreviousChapter() {
    if (currentChapterIndex.value > 0) {
      loadChapter(currentChapterIndex.value - 1);
      scrollOffset.value = 0;
    }
  }

  void goToChapter(int index) {
    loadChapter(index);
    scrollOffset.value = 0;
  }

  // ============= Controls =============

  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _startControlsHideTimer();
    } else {
      _controlsHideTimer?.cancel();
    }
  }

  void _startControlsHideTimer() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 4), () {
      showControls.value = false;
    });
  }

  void toggleToc() {
    showToc.value = !showToc.value;
  }

  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
    if (isFullscreen.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void toggleKeepScreenOn() {
    keepScreenOn.value = !keepScreenOn.value;
    savePreferences();
  }

  // ============= Auto-scroll =============

  void toggleAutoScroll() {
    isAutoScrolling.value = !isAutoScrolling.value;
    if (isAutoScrolling.value) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void setAutoScrollInterval(int seconds) {
    autoScrollIntervalSeconds.value = seconds.clamp(15, 600);
    savePreferences();
    if (isAutoScrolling.value) {
      _stopAutoScroll();
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    autoScrollProgress.value = 0.0;
    final intervalMs = autoScrollIntervalSeconds.value * 1000;

    _autoScrollProgressTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) {
      autoScrollProgress.value =
          (autoScrollProgress.value + (100 / intervalMs)).clamp(0.0, 1.0);
    });

    _autoScrollTimer =
        Timer.periodic(Duration(seconds: autoScrollIntervalSeconds.value), (_) {
      if (currentChapterIndex.value < totalChapters.value - 1) {
        goToNextChapter();
        autoScrollProgress.value = 0.0;
      } else {
        toggleAutoScroll();
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollProgressTimer?.cancel();
    autoScrollProgress.value = 0.0;
  }

  // ============= Settings =============

  void setDarkMode(bool value) {
    isDarkMode.value = value;
    savePreferences();
  }

  void setFontSize(double size) {
    fontSize.value = size.clamp(12.0, 32.0);
    savePreferences();
  }

  void increaseFontSize() {
    setFontSize(fontSize.value + 2);
  }

  void decreaseFontSize() {
    setFontSize(fontSize.value - 2);
  }

  void setFontFamily(String family) {
    fontFamily.value = family;
    savePreferences();
  }

  void setLineHeight(double height) {
    lineHeight.value = height.clamp(1.0, 3.0);
    savePreferences();
  }

  void setMarginSize(double size) {
    marginSize.value = size.clamp(8.0, 48.0);
    savePreferences();
  }

  void _loadPreferences() {
    // Follow external theme if provided, otherwise use stored preference
    if (externalDarkMode != null) {
      isDarkMode.value = externalDarkMode!.value;
    } else {
      final savedDarkMode = _storage.read<bool>('epub_dark_mode');
      if (savedDarkMode != null) isDarkMode.value = savedDarkMode;
    }

    final savedFontSize = _storage.read<double>('epub_font_size');
    if (savedFontSize != null) fontSize.value = savedFontSize;

    final savedFontFamily = _storage.read<String>('epub_font_family');
    if (savedFontFamily != null) fontFamily.value = savedFontFamily;

    final savedLineHeight = _storage.read<double>('epub_line_height');
    if (savedLineHeight != null) lineHeight.value = savedLineHeight;

    final savedAutoScrollInterval =
        _storage.read<int>('epub_auto_scroll_interval');
    if (savedAutoScrollInterval != null) {
      autoScrollIntervalSeconds.value = savedAutoScrollInterval.clamp(15, 600);
    }

    final savedKeepScreenOn = _storage.read<bool>('epub_keep_screen_on');
    if (savedKeepScreenOn != null) keepScreenOn.value = savedKeepScreenOn;

    final savedFullscreen = _storage.read<bool>('epub_fullscreen');
    if (savedFullscreen != null) isFullscreen.value = savedFullscreen;
  }

  void savePreferences() {
    _storage.write('epub_dark_mode', isDarkMode.value);
    _storage.write('epub_font_size', fontSize.value);
    _storage.write('epub_font_family', fontFamily.value);
    _storage.write('epub_line_height', lineHeight.value);
    _storage.write(
        'epub_auto_scroll_interval', autoScrollIntervalSeconds.value);
    _storage.write('epub_keep_screen_on', keepScreenOn.value);
    _storage.write('epub_fullscreen', isFullscreen.value);
  }

  // ============= Session & Progress =============

  void _startReadingSession() {
    _sessionStartTime = DateTime.now();
  }

  Future<void> _loadSavedPosition() async {
    final savedChapter = _storage.read<int>('epub_chapter_$_bookIdForStorage');
    final savedScroll = _storage.read<double>('epub_scroll_$_bookIdForStorage');

    if (savedChapter != null && savedChapter < chapters.length) {
      await loadChapter(savedChapter);
      if (savedScroll != null) {
        scrollOffset.value = savedScroll;
      }
    }
  }

  Future<void> _endReadingSession() async {
    if (isSamplePreview || _sessionStartTime == null) return;

    final duration = DateTime.now().difference(_sessionStartTime!);
    if (duration.inSeconds < 10) return;

    try {
      await saveProgress();

      if (serviceConfig.isLoggedIn &&
          serviceConfig.onSessionEnd != null &&
          _bookIdForStorage > 0) {
        await serviceConfig.onSessionEnd!(
          _bookIdForStorage,
          duration.inSeconds,
          currentChapterIndex.value + 1,
          totalChapters.value,
        );
      }
    } catch (e) {
      debugPrint('Error ending reading session: $e');
    }
  }

  Future<void> saveProgress() async {
    if (isSamplePreview) return;

    try {
      _storage.write(
          'epub_chapter_$_bookIdForStorage', currentChapterIndex.value);
      _storage.write('epub_scroll_$_bookIdForStorage', scrollOffset.value);
      _storage.write('epub_progress_$_bookIdForStorage', progress.value);

      if (serviceConfig.isLoggedIn &&
          serviceConfig.onProgressSync != null &&
          _bookIdForStorage > 0) {
        await serviceConfig.onProgressSync!(
          _bookIdForStorage,
          progress.value * 100,
          currentChapterIndex.value + 1,
          totalChapters.value,
        );
      }
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  void updateScrollOffset(double offset) {
    scrollOffset.value = offset;
  }

  // ============= Bookmarks =============

  Future<void> _loadBookmarks() async {
    if (_bookIdForStorage <= 0) {
      debugPrint('Skipping bookmarks API - no valid book ID');
      return;
    }

    try {
      if (serviceConfig.isLoggedIn && serviceConfig.onBookmarksLoad != null) {
        final apiBookmarks =
            await serviceConfig.onBookmarksLoad!(_bookIdForStorage);
        if (apiBookmarks != null) {
          bookmarks.value = apiBookmarks
              .where(
                  (b) => b['cfi'] != null || b['progress_percent'] != null)
              .map((b) => BookmarkInfo(
                    chapterIndex: b['page_number'] ?? 0,
                    chapterTitle: b['label'] ?? 'Bookmark',
                    scrollOffset:
                        (b['progress_percent'] ?? 0).toDouble(),
                    createdAt: b['created_at'] != null
                        ? DateTime.tryParse(b['created_at']) ?? DateTime.now()
                        : DateTime.now(),
                  ))
              .toList();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading bookmarks from API: $e');
    }

    final localBookmarks =
        _storage.read<List<dynamic>>('epub_bookmarks_$_bookIdForStorage');
    if (localBookmarks != null) {
      bookmarks.value =
          localBookmarks.map((b) => BookmarkInfo.fromJson(b)).toList();
    }
  }

  Future<void> addBookmark() async {
    final bookmark = BookmarkInfo(
      chapterIndex: currentChapterIndex.value,
      chapterTitle: currentChapterTitle.value,
      scrollOffset: scrollOffset.value,
      createdAt: DateTime.now(),
    );

    bookmarks.add(bookmark);
    _saveBookmarksLocally();

    if (serviceConfig.isLoggedIn &&
        serviceConfig.onBookmarksSync != null &&
        _bookIdForStorage > 0) {
      try {
        await serviceConfig.onBookmarksSync!(
          _bookIdForStorage,
          bookmarks.map((b) => b.toJson()).toList(),
        );
      } catch (e) {
        debugPrint('Error syncing bookmark: $e');
      }
    }

    _showMessage('Bookmark added', ViewerMessageType.success);
  }

  Future<void> removeBookmark(int index) async {
    if (index < 0 || index >= bookmarks.length) return;

    bookmarks.removeAt(index);
    _saveBookmarksLocally();

    _showMessage('Bookmark removed', ViewerMessageType.success);
  }

  void _saveBookmarksLocally() {
    _storage.write(
      'epub_bookmarks_$_bookIdForStorage',
      bookmarks.map((b) => b.toJson()).toList(),
    );
  }

  void goToBookmark(BookmarkInfo bookmark) {
    loadChapter(bookmark.chapterIndex);
    scrollOffset.value = bookmark.scrollOffset;
  }

  bool isCurrentPositionBookmarked() {
    return bookmarks.any((b) =>
        b.chapterIndex == currentChapterIndex.value &&
        (b.scrollOffset - scrollOffset.value).abs() < 100);
  }

  // ============= Highlights =============

  void addHighlight(String text, int startOffset, int endOffset) {
    final highlight = HighlightInfo(
      chapterIndex: currentChapterIndex.value,
      text: text,
      startOffset: startOffset,
      endOffset: endOffset,
      color: Colors.yellow.toARGB32(),
      createdAt: DateTime.now(),
    );

    highlights.add(highlight);
    _saveHighlightsLocally();
    _showMessage('Highlight added', ViewerMessageType.success);
  }

  void removeHighlight(int index) {
    if (index < 0 || index >= highlights.length) return;
    highlights.removeAt(index);
    _saveHighlightsLocally();
  }

  void _saveHighlightsLocally() {
    _storage.write(
      'epub_highlights_$_bookIdForStorage',
      highlights.map((h) => h.toJson()).toList(),
    );
  }

  // ============= Notes =============

  void addNote(String text, String noteText) {
    final note = NoteInfo(
      chapterIndex: currentChapterIndex.value,
      selectedText: text,
      noteText: noteText,
      scrollOffset: scrollOffset.value,
      createdAt: DateTime.now(),
    );

    notes.add(note);
    _saveNotesLocally();
    _showMessage('Note added', ViewerMessageType.success);
  }

  void removeNote(int index) {
    if (index < 0 || index >= notes.length) return;
    notes.removeAt(index);
    _saveNotesLocally();
  }

  void _saveNotesLocally() {
    _storage.write(
      'epub_notes_$_bookIdForStorage',
      notes.map((n) => n.toJson()).toList(),
    );
  }

  // ============= Search =============

  void enterSearchMode() {
    isSearchMode.value = true;
    showControls.value = true;
    _controlsHideTimer?.cancel();
  }

  void exitSearchMode() {
    isSearchMode.value = false;
    searchQuery.value = '';
    searchResults.clear();
    currentSearchIndex.value = 0;
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    searchQuery.value = query;
    searchResults.clear();
    currentSearchIndex.value = 0;

    final results = searchInBook(query);
    searchResults.addAll(results);
  }

  void goToSearchResult(int index) {
    if (index < 0 || index >= searchResults.length) return;
    currentSearchIndex.value = index;
    final result = searchResults[index];
    goToChapter(result.chapterIndex);
  }

  void nextSearchResult() {
    if (searchResults.isEmpty) return;
    final next = (currentSearchIndex.value + 1) % searchResults.length;
    goToSearchResult(next);
  }

  void previousSearchResult() {
    if (searchResults.isEmpty) return;
    final prev = (currentSearchIndex.value - 1 + searchResults.length) %
        searchResults.length;
    goToSearchResult(prev);
  }

  List<SearchResult> searchInBook(String query) {
    final results = <SearchResult>[];
    if (query.isEmpty || epubBook == null) return results;

    final queryLower = query.toLowerCase();

    for (int i = 0; i < chapters.length; i++) {
      final content = chapterContents[i];
      if (content == null) continue;

      final plainText = content.replaceAll(RegExp(r'<[^>]*>'), ' ');

      int startIndex = 0;
      while (true) {
        final index = plainText.toLowerCase().indexOf(queryLower, startIndex);
        if (index == -1) break;

        final contextStart = (index - 50).clamp(0, plainText.length);
        final contextEnd =
            (index + query.length + 50).clamp(0, plainText.length);
        final context = plainText.substring(contextStart, contextEnd);

        results.add(SearchResult(
          chapterIndex: i,
          chapterTitle: chapters[i].title,
          context: '...$context...',
          matchIndex: index,
        ));

        startIndex = index + 1;
      }
    }

    return results;
  }

  // ============= Annotations =============

  void toggleAnnotationToolbar() {
    showAnnotationToolbar.value = !showAnnotationToolbar.value;
    if (!showAnnotationToolbar.value) {
      annotationController.selectTool(null);
    }
  }

  PageAnnotations getPageAnnotations(int chapterIndex) {
    return pageAnnotations[chapterIndex] ??
        PageAnnotations(pageNumber: chapterIndex);
  }

  void addStroke(int chapterIndex, DrawingStroke stroke) {
    final annotations = getPageAnnotations(chapterIndex);
    final newAnnotations = PageAnnotations(
      pageNumber: chapterIndex,
      strokes: [...annotations.strokes, stroke],
      notes: annotations.notes,
    );

    _undoStack.add({
      'type': 'addStroke',
      'chapter': chapterIndex,
      'stroke': stroke.toJson(),
    });
    _redoStack.clear();

    pageAnnotations[chapterIndex] = newAnnotations;
    _syncAnnotationsToServer();
  }

  void removeStroke(int chapterIndex, int strokeIndex) {
    final annotations = getPageAnnotations(chapterIndex);
    if (strokeIndex < 0 || strokeIndex >= annotations.strokes.length) return;

    final removedStroke = annotations.strokes[strokeIndex];
    final newStrokes = List<DrawingStroke>.from(annotations.strokes);
    newStrokes.removeAt(strokeIndex);

    _undoStack.add({
      'type': 'removeStroke',
      'chapter': chapterIndex,
      'strokeIndex': strokeIndex,
      'stroke': removedStroke.toJson(),
    });
    _redoStack.clear();

    pageAnnotations[chapterIndex] = PageAnnotations(
      pageNumber: chapterIndex,
      strokes: newStrokes,
      notes: annotations.notes,
    );
    _syncAnnotationsToServer();
  }

  /// Remove a stroke by ID
  void removeStrokeById(int chapterIndex, String strokeId) {
    final annotations = getPageAnnotations(chapterIndex);
    final strokeIndex = annotations.strokes.indexWhere((s) => s.id == strokeId);
    if (strokeIndex == -1) return;
    removeStroke(chapterIndex, strokeIndex);
  }

  /// Add a position-based note to a chapter (for annotation canvas)
  void addPositionNote(int chapterIndex, TextNote note) {
    addTextAnnotation(chapterIndex, note);
  }

  /// Update a position-based note by ID
  void updatePositionNote(int chapterIndex, TextNote updatedNote) {
    final annotations = getPageAnnotations(chapterIndex);
    final noteIndex =
        annotations.notes.indexWhere((n) => n.id == updatedNote.id);
    if (noteIndex >= 0) {
      updateTextAnnotation(chapterIndex, noteIndex, updatedNote.text);
    }
  }

  /// Remove a position-based note by ID
  void removePositionNote(int chapterIndex, String noteId) {
    final annotations = getPageAnnotations(chapterIndex);
    final noteIndex = annotations.notes.indexWhere((n) => n.id == noteId);
    if (noteIndex >= 0) {
      removeTextAnnotation(chapterIndex, noteIndex);
    }
  }

  void addTextAnnotation(int chapterIndex, TextNote note) {
    final annotations = getPageAnnotations(chapterIndex);
    final newAnnotations = PageAnnotations(
      pageNumber: chapterIndex,
      strokes: annotations.strokes,
      notes: [...annotations.notes, note],
    );

    _undoStack.add({
      'type': 'addNote',
      'chapter': chapterIndex,
      'note': note.toJson(),
    });
    _redoStack.clear();

    pageAnnotations[chapterIndex] = newAnnotations;
    _syncAnnotationsToServer();
  }

  void updateTextAnnotation(int chapterIndex, int noteIndex, String newText) {
    final annotations = getPageAnnotations(chapterIndex);
    if (noteIndex < 0 || noteIndex >= annotations.notes.length) return;

    final oldNote = annotations.notes[noteIndex];
    final newNote = TextNote(
      id: oldNote.id,
      x: oldNote.x,
      y: oldNote.y,
      text: newText,
      createdAt: oldNote.createdAt,
    );

    _undoStack.add({
      'type': 'updateNote',
      'chapter': chapterIndex,
      'noteIndex': noteIndex,
      'oldText': oldNote.text,
      'newText': newText,
    });
    _redoStack.clear();

    final newNotes = List<TextNote>.from(annotations.notes);
    newNotes[noteIndex] = newNote;

    pageAnnotations[chapterIndex] = PageAnnotations(
      pageNumber: chapterIndex,
      strokes: annotations.strokes,
      notes: newNotes,
    );
    _syncAnnotationsToServer();
  }

  void removeTextAnnotation(int chapterIndex, int noteIndex) {
    final annotations = getPageAnnotations(chapterIndex);
    if (noteIndex < 0 || noteIndex >= annotations.notes.length) return;

    final removedNote = annotations.notes[noteIndex];
    final newNotes = List<TextNote>.from(annotations.notes);
    newNotes.removeAt(noteIndex);

    _undoStack.add({
      'type': 'removeNote',
      'chapter': chapterIndex,
      'noteIndex': noteIndex,
      'note': removedNote.toJson(),
    });
    _redoStack.clear();

    pageAnnotations[chapterIndex] = PageAnnotations(
      pageNumber: chapterIndex,
      strokes: annotations.strokes,
      notes: newNotes,
    );
    _syncAnnotationsToServer();
  }

  void clearChapterAnnotations(int chapterIndex) {
    final annotations = getPageAnnotations(chapterIndex);
    if (annotations.strokes.isEmpty && annotations.notes.isEmpty) return;

    _undoStack.add({
      'type': 'clearChapter',
      'chapter': chapterIndex,
      'strokes': annotations.strokes.map((s) => s.toJson()).toList(),
      'notes': annotations.notes.map((n) => n.toJson()).toList(),
    });
    _redoStack.clear();

    pageAnnotations[chapterIndex] = PageAnnotations(pageNumber: chapterIndex);
    _syncAnnotationsToServer();
  }

  void undoAnnotation() {
    if (_undoStack.isEmpty) return;

    final action = _undoStack.removeLast();
    final type = action['type'] as String;
    final chapter = action['chapter'] as int;

    switch (type) {
      case 'addStroke':
        final annotations = getPageAnnotations(chapter);
        if (annotations.strokes.isNotEmpty) {
          final newStrokes = List<DrawingStroke>.from(annotations.strokes);
          newStrokes.removeLast();
          pageAnnotations[chapter] = PageAnnotations(
            pageNumber: chapter,
            strokes: newStrokes,
            notes: annotations.notes,
          );
        }
        break;
      case 'removeStroke':
        final stroke = DrawingStroke.fromJson(action['stroke']);
        final strokeIndex = action['strokeIndex'] as int;
        final annotations = getPageAnnotations(chapter);
        final newStrokes = List<DrawingStroke>.from(annotations.strokes);
        newStrokes.insert(strokeIndex.clamp(0, newStrokes.length), stroke);
        pageAnnotations[chapter] = PageAnnotations(
          pageNumber: chapter,
          strokes: newStrokes,
          notes: annotations.notes,
        );
        break;
      case 'addNote':
        final annotations = getPageAnnotations(chapter);
        if (annotations.notes.isNotEmpty) {
          final newNotes = List<TextNote>.from(annotations.notes);
          newNotes.removeLast();
          pageAnnotations[chapter] = PageAnnotations(
            pageNumber: chapter,
            strokes: annotations.strokes,
            notes: newNotes,
          );
        }
        break;
      case 'removeNote':
        final note = TextNote.fromJson(action['note']);
        final noteIndex = action['noteIndex'] as int;
        final annotations = getPageAnnotations(chapter);
        final newNotes = List<TextNote>.from(annotations.notes);
        newNotes.insert(noteIndex.clamp(0, newNotes.length), note);
        pageAnnotations[chapter] = PageAnnotations(
          pageNumber: chapter,
          strokes: annotations.strokes,
          notes: newNotes,
        );
        break;
      case 'updateNote':
        final noteIndex = action['noteIndex'] as int;
        final oldText = action['oldText'] as String;
        final annotations = getPageAnnotations(chapter);
        if (noteIndex < annotations.notes.length) {
          final note = annotations.notes[noteIndex];
          final newNotes = List<TextNote>.from(annotations.notes);
          newNotes[noteIndex] = TextNote(
            id: note.id,
            x: note.x,
            y: note.y,
            text: oldText,
            createdAt: note.createdAt,
          );
          pageAnnotations[chapter] = PageAnnotations(
            pageNumber: chapter,
            strokes: annotations.strokes,
            notes: newNotes,
          );
        }
        break;
      case 'clearChapter':
        final strokes = (action['strokes'] as List)
            .map((s) => DrawingStroke.fromJson(s))
            .toList();
        final notes =
            (action['notes'] as List).map((n) => TextNote.fromJson(n)).toList();
        pageAnnotations[chapter] = PageAnnotations(
          pageNumber: chapter,
          strokes: strokes,
          notes: notes,
        );
        break;
    }

    _redoStack.add(action);
    _syncAnnotationsToServer();
  }

  void redoAnnotation() {
    if (_redoStack.isEmpty) return;

    final action = _redoStack.removeLast();
    final type = action['type'] as String;
    final chapter = action['chapter'] as int;

    switch (type) {
      case 'addStroke':
        final stroke = DrawingStroke.fromJson(action['stroke']);
        final annotations = getPageAnnotations(chapter);
        pageAnnotations[chapter] = PageAnnotations(
          pageNumber: chapter,
          strokes: [...annotations.strokes, stroke],
          notes: annotations.notes,
        );
        break;
      case 'removeStroke':
        final strokeIndex = action['strokeIndex'] as int;
        final annotations = getPageAnnotations(chapter);
        if (strokeIndex < annotations.strokes.length) {
          final newStrokes = List<DrawingStroke>.from(annotations.strokes);
          newStrokes.removeAt(strokeIndex);
          pageAnnotations[chapter] = PageAnnotations(
            pageNumber: chapter,
            strokes: newStrokes,
            notes: annotations.notes,
          );
        }
        break;
      case 'addNote':
        final note = TextNote.fromJson(action['note']);
        final annotations = getPageAnnotations(chapter);
        pageAnnotations[chapter] = PageAnnotations(
          pageNumber: chapter,
          strokes: annotations.strokes,
          notes: [...annotations.notes, note],
        );
        break;
      case 'removeNote':
        final noteIndex = action['noteIndex'] as int;
        final annotations = getPageAnnotations(chapter);
        if (noteIndex < annotations.notes.length) {
          final newNotes = List<TextNote>.from(annotations.notes);
          newNotes.removeAt(noteIndex);
          pageAnnotations[chapter] = PageAnnotations(
            pageNumber: chapter,
            strokes: annotations.strokes,
            notes: newNotes,
          );
        }
        break;
      case 'updateNote':
        final noteIndex = action['noteIndex'] as int;
        final newText = action['newText'] as String;
        final annotations = getPageAnnotations(chapter);
        if (noteIndex < annotations.notes.length) {
          final note = annotations.notes[noteIndex];
          final newNotes = List<TextNote>.from(annotations.notes);
          newNotes[noteIndex] = TextNote(
            id: note.id,
            x: note.x,
            y: note.y,
            text: newText,
            createdAt: note.createdAt,
          );
          pageAnnotations[chapter] = PageAnnotations(
            pageNumber: chapter,
            strokes: annotations.strokes,
            notes: newNotes,
          );
        }
        break;
      case 'clearChapter':
        pageAnnotations[chapter] = PageAnnotations(pageNumber: chapter);
        break;
    }

    _undoStack.add(action);
    _syncAnnotationsToServer();
  }

  Future<void> _loadAnnotations() async {
    final validBookId = _bookIdForStorage;
    if (validBookId <= 0) return;

    try {
      if (serviceConfig.isLoggedIn &&
          serviceConfig.onAnnotationsLoad != null) {
        final response = await serviceConfig.onAnnotationsLoad!(validBookId);
        if (response != null && response['annotations'] != null) {
          final annotationsData = response['annotations'] as List;
          for (var data in annotationsData) {
            final pageNum = data['page_number'] ?? data['chapter_index'] ?? 0;
            final strokes = <DrawingStroke>[];
            final notes = <TextNote>[];

            if (data['strokes'] != null) {
              for (var strokeData in data['strokes']) {
                strokes.add(DrawingStroke.fromJson(strokeData));
              }
            }
            if (data['notes'] != null) {
              for (var noteData in data['notes']) {
                notes.add(TextNote.fromJson(noteData));
              }
            }

            if (strokes.isNotEmpty || notes.isNotEmpty) {
              pageAnnotations[pageNum] = PageAnnotations(
                pageNumber: pageNum,
                strokes: strokes,
                notes: notes,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load annotations: $e');
    }
  }

  Future<void> _syncAnnotationsToServer() async {
    final validBookId = _bookIdForStorage;
    if (validBookId <= 0) return;

    if (!serviceConfig.isLoggedIn || serviceConfig.onAnnotationsSync == null) {
      return;
    }

    try {
      final annotationsData = pageAnnotations.entries.map((entry) {
        return {
          'page_number': entry.key,
          'chapter_index': entry.key,
          'strokes': entry.value.strokes.map((s) => s.toJson()).toList(),
          'notes': entry.value.notes.map((n) => n.toJson()).toList(),
        };
      }).toList();

      await serviceConfig.onAnnotationsSync!(validBookId, {
        'annotations': annotationsData,
      });
    } catch (e) {
      debugPrint('Failed to sync annotations: $e');
    }
  }
}

// ============= Data Classes =============

class ChapterInfo {
  final int index;
  final String title;
  final int depth;
  final String? contentFileName;

  ChapterInfo({
    required this.index,
    required this.title,
    required this.depth,
    this.contentFileName,
  });
}

class BookmarkInfo {
  final int chapterIndex;
  final String chapterTitle;
  final double scrollOffset;
  final DateTime createdAt;

  BookmarkInfo({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.scrollOffset,
    required this.createdAt,
  });

  factory BookmarkInfo.fromJson(Map<String, dynamic> json) {
    return BookmarkInfo(
      chapterIndex: json['chapter_index'] ?? json['chapterIndex'] ?? 0,
      chapterTitle: json['title'] ?? json['chapterTitle'] ?? '',
      scrollOffset:
          (json['scroll_offset'] ?? json['scrollOffset'] ?? 0).toDouble(),
      createdAt:
          DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'chapterIndex': chapterIndex,
        'chapterTitle': chapterTitle,
        'scrollOffset': scrollOffset,
        'createdAt': createdAt.toIso8601String(),
      };
}

class HighlightInfo {
  final int chapterIndex;
  final String text;
  final int startOffset;
  final int endOffset;
  final int color;
  final DateTime createdAt;

  HighlightInfo({
    required this.chapterIndex,
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'chapterIndex': chapterIndex,
        'text': text,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };
}

class NoteInfo {
  final int chapterIndex;
  final String selectedText;
  final String noteText;
  final double scrollOffset;
  final DateTime createdAt;

  NoteInfo({
    required this.chapterIndex,
    required this.selectedText,
    required this.noteText,
    required this.scrollOffset,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'chapterIndex': chapterIndex,
        'selectedText': selectedText,
        'noteText': noteText,
        'scrollOffset': scrollOffset,
        'createdAt': createdAt.toIso8601String(),
      };
}

class SearchResult {
  final int chapterIndex;
  final String chapterTitle;
  final String context;
  final int matchIndex;

  SearchResult({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.context,
    required this.matchIndex,
  });
}
