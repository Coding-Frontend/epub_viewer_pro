import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../service_config.dart';
import '../viewer_theme_config.dart';
import '../feature_config.dart';
import 'epub_reader_controller.dart';
import 'epub_toc_drawer.dart';
import 'epub_settings_sheet.dart';
import 'epub_bookmarks_sheet.dart';

/// Main EPUB Viewer Screen
/// Uses epubx for parsing and flutter_widget_from_html for rendering
class EpubViewerScreen extends StatefulWidget {
  final String? filePath;
  final String? fileUrl;
  final String title;
  final int? bookId;
  final String? bookLanguage;
  final bool isSamplePreview;
  final EpubViewerServiceConfig serviceConfig;
  final EpubViewerThemeConfig themeConfig;
  final EpubViewerFeatureConfig featureConfig;
  final RxBool? externalDarkMode;

  const EpubViewerScreen({
    super.key,
    this.filePath,
    this.fileUrl,
    required this.title,
    this.bookId,
    this.bookLanguage,
    this.isSamplePreview = false,
    this.serviceConfig = const EpubViewerServiceConfig(),
    this.themeConfig = const EpubViewerThemeConfig(),
    this.featureConfig = const EpubViewerFeatureConfig(),
    this.externalDarkMode,
  });

  @override
  State<EpubViewerScreen> createState() => _EpubViewerScreenState();
}

class _EpubViewerScreenState extends State<EpubViewerScreen>
    with SingleTickerProviderStateMixin {
  late EpubReaderController controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Initialize controller
    controller = Get.put(EpubReaderController(
      filePath: widget.filePath,
      fileUrl: widget.fileUrl,
      title: widget.title,
      bookId: widget.bookId,
      bookLanguage: widget.bookLanguage,
      isSamplePreview: widget.isSamplePreview,
      serviceConfig: widget.serviceConfig,
      themeConfig: widget.themeConfig,
      featureConfig: widget.featureConfig,
      externalDarkMode: widget.externalDarkMode,
    ));

    // Listen to scroll position
    _scrollController.addListener(_onScroll);

    // Scroll to top when chapter changes
    ever(controller.currentChapterIndex, (_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    Get.delete<EpubReaderController>();
    super.dispose();
  }

  void _onScroll() {
    controller.updateScrollOffset(_scrollController.offset);
  }

  void _toggleControls() {
    controller.toggleControls();
    _updateSystemUI();
  }

  void _updateSystemUI() {
    if (controller.showControls.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else if (controller.isFullscreen.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _showSettingsSheet() {
    Get.bottomSheet(
      const EpubSettingsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showBookmarksSheet() {
    Get.bottomSheet(
      const EpubBookmarksSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showSearchSheet() {
    controller.enterSearchMode();
    final isDark = controller.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final searchController = TextEditingController();

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subtitleColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search in book...',
                  hintStyle: TextStyle(color: subtitleColor),
                  prefixIcon: Icon(Icons.search, color: subtitleColor),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close, color: subtitleColor),
                    onPressed: () {
                      searchController.clear();
                      controller.performSearch('');
                    },
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  controller.performSearch(value);
                },
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  controller.performSearch(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            // Results
            Expanded(
              child: Obx(() {
                if (controller.searchQuery.value.isEmpty) {
                  return Center(
                    child: Text(
                      'Enter a search term',
                      style: TextStyle(color: subtitleColor),
                    ),
                  );
                }

                if (controller.searchResults.isEmpty) {
                  return Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(color: subtitleColor),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final result = controller.searchResults[index];
                    final isSelected =
                        controller.currentSearchIndex.value == index;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        result.chapterTitle,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        result.context,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        'Ch. ${result.chapterIndex + 1}',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        controller.goToSearchResult(index);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
            // Navigation buttons
            Obx(() {
              if (controller.searchResults.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: controller.previousSearchResult,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                    ),
                    Text(
                      '${controller.currentSearchIndex.value + 1} / ${controller.searchResults.length}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: controller.nextSearchResult,
                      icon: const Text('Next'),
                      label: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      controller.exitSearchMode();
    });
  }

  void _toggleFullscreen() {
    controller.toggleFullscreen();
    _updateSystemUI();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final isSepia = controller.isSepiaMode.value;
      final bgColor = isDark
          ? (widget.themeConfig.darkBackgroundColor)
          : isSepia
              ? (widget.themeConfig.sepiaBackgroundColor ?? const Color(0xFFF5E6C8))
              : (widget.themeConfig.lightBackgroundColor);
      final textColor = isDark
          ? widget.themeConfig.darkTextColor
          : isSepia
              ? const Color(0xFF5C4033)
              : widget.themeConfig.lightTextColor;
      final isFullscreen = controller.isFullscreen.value;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: bgColor,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgColor,
          drawer: const EpubTocDrawer(),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // Content with fullscreen support
                if (isFullscreen)
                  // Fullscreen mode - content fills entire screen
                  GestureDetector(
                    onTap: _toggleControls,
                    onDoubleTap: _toggleFullscreen,
                    child: _buildFullscreenContent(isDark, textColor, bgColor),
                  )
                else
                  // Normal mode
                  _buildContent(isDark, textColor, bgColor),

                // Loading overlay
                if (controller.isLoading.value) _buildLoadingOverlay(isDark),

                // Error overlay
                if (controller.error.value.isNotEmpty)
                  _buildErrorOverlay(isDark),

                // Fullscreen exit button
                if (isFullscreen)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 8,
                    child: _buildFullscreenExitButton(isDark),
                  ),

                // Floating bookmark indicator (always visible when controls are hidden)
                if (!controller.showControls.value && !isFullscreen)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    right: 12,
                    child: _buildFloatingBookmarkIndicator(isDark, textColor),
                  ),

                // Controls overlay (only in non-fullscreen mode)
                if (controller.showControls.value && !isFullscreen) ...[
                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopBar(isDark, textColor),
                  ),

                  // Bottom bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomBar(isDark, textColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Build a floating bookmark indicator that shows when controls are hidden
  Widget _buildFloatingBookmarkIndicator(bool isDark, Color textColor) {
    final isBookmarked = controller.isCurrentPositionBookmarked();
    final accentColor = isDark ? Colors.white : Theme.of(context).primaryColor;
    
    return GestureDetector(
      onTap: () {
        if (!isBookmarked) {
          controller.addBookmark();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: isBookmarked ? accentColor : textColor.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color textColor, Color bgColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: _toggleControls,
          child: Obx(() {
            final html = controller.currentChapterHtml.value;
            if (html.isEmpty) {
              return SizedBox(
                height: constraints.maxHeight,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            }

            final fontSize = controller.fontSize.value;
            final fontFamily = _getFontFamily(controller.fontFamily.value);
            final lineHeight = controller.lineHeight.value;
            final margin = controller.marginSize.value;

            return Stack(
              children: [
                // EPUB Content with text selection
                SelectionArea(
                  contextMenuBuilder: (context, selectableRegionState) {
                    return _buildTextSelectionMenu(
                      context,
                      selectableRegionState,
                      isDark,
                      textColor,
                    );
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      margin,
                      MediaQuery.of(context).padding.top + 60 + margin,
                      margin,
                      MediaQuery.of(context).padding.bottom + 100 + margin,
                    ),
                    child: HtmlWidget(
                      html,
                      // Use key to force rebuild when settings change
                      key: ValueKey('epub_html_${fontSize}_${fontFamily}_${lineHeight}_${controller.currentChapterIndex.value}'),
                      textStyle: TextStyle(
                        fontSize: fontSize,
                        fontFamily: fontFamily,
                        height: lineHeight,
                        color: textColor,
                      ),
                      customStylesBuilder: (element) {
                        // Apply custom styles based on element type
                        if (element.localName == 'h1') {
                          return {
                            'font-size': '${fontSize * 1.8}px',
                            'font-weight': 'bold',
                            'margin-top': '24px',
                            'margin-bottom': '16px',
                          };
                        }
                        if (element.localName == 'h2') {
                          return {
                            'font-size': '${fontSize * 1.5}px',
                            'font-weight': 'bold',
                            'margin-top': '20px',
                            'margin-bottom': '12px',
                          };
                        }
                        if (element.localName == 'h3') {
                          return {
                            'font-size': '${fontSize * 1.3}px',
                            'font-weight': 'bold',
                            'margin-top': '16px',
                            'margin-bottom': '8px',
                          };
                        }
                        if (element.localName == 'p') {
                          return {
                            'margin-bottom': '${fontSize * 0.8}px',
                          };
                        }
                        if (element.localName == 'blockquote') {
                          return {
                            'border-left':
                                '4px solid ${isDark ? "#555" : "#ccc"}',
                            'padding-left': '16px',
                            'margin': '16px 0',
                            'font-style': 'italic',
                          };
                        }
                        return null;
                      },
                      onTapUrl: (url) {
                        // Handle internal links or external URLs
                        debugPrint('Tapped URL: $url');
                        return true;
                      },
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  /// Builds the fullscreen content without padding for bars
  Widget _buildFullscreenContent(bool isDark, Color textColor, Color bgColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final html = controller.currentChapterHtml.value;
          if (html.isEmpty) {
            return SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            );
          }
          final fontSize = controller.fontSize.value;
          final fontFamily = _getFontFamily(controller.fontFamily.value);
          final lineHeight = controller.lineHeight.value;
          final margin = controller.marginSize.value;

          return SelectionArea(
            contextMenuBuilder: (context, selectableRegionState) {
              return _buildTextSelectionMenu(
                context,
                selectableRegionState,
                isDark,
                textColor,
              );
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                margin,
                MediaQuery.of(context).padding.top + margin,
                margin,
                MediaQuery.of(context).padding.bottom + margin,
              ),
              child: HtmlWidget(
                html,
                textStyle: TextStyle(
                  fontSize: fontSize,
                  fontFamily: fontFamily,
                  height: lineHeight,
                  color: textColor,
                ),
                customStylesBuilder: (element) {
                  if (element.localName == 'h1') {
                    return {
                      'font-size': '${fontSize * 1.8}px',
                      'font-weight': 'bold',
                      'margin-top': '24px',
                      'margin-bottom': '16px',
                    };
                  }
                  if (element.localName == 'h2') {
                    return {
                      'font-size': '${fontSize * 1.5}px',
                      'font-weight': 'bold',
                      'margin-top': '20px',
                      'margin-bottom': '12px',
                    };
                  }
                  if (element.localName == 'h3') {
                    return {
                      'font-size': '${fontSize * 1.3}px',
                      'font-weight': 'bold',
                      'margin-top': '16px',
                      'margin-bottom': '8px',
                    };
                  }
                  if (element.localName == 'p') {
                    return {
                      'margin-bottom': '${fontSize * 0.8}px',
                    };
                  }
                  if (element.localName == 'blockquote') {
                    return {
                      'border-left': '4px solid ${isDark ? "#555" : "#ccc"}',
                      'padding-left': '16px',
                      'margin': '16px 0',
                      'font-style': 'italic',
                    };
                  }
                  return null;
                },
                onTapUrl: (url) {
                  debugPrint('Tapped URL: $url');
                  return true;
                },
              ),
            ),
          );
        });
      },
    );
  }

  /// Builds the fullscreen exit button
  Widget _buildFullscreenExitButton(bool isDark) {
    return AnimatedOpacity(
      opacity: controller.showControls.value ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: Icon(
            Icons.fullscreen_exit,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: _toggleFullscreen,
          tooltip: 'Exit fullscreen',
        ),
      ),
    );
  }

  String? _getFontFamily(String family) {
    switch (family) {
      case 'Default':
        return null;
      case 'Serif':
        return 'Georgia, serif';
      case 'Sans-serif':
        return 'Arial, sans-serif';
      case 'Monospace':
        return 'Courier, monospace';
      default:
        // Google Font - return the font name directly
        // Note: Google Fonts are loaded dynamically
        return family;
    }
  }

  Widget _buildTextSelectionMenu(
    BuildContext context,
    SelectableRegionState selectableRegionState,
    bool isDark,
    Color textColor,
  ) {
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final primaryColor = Theme.of(context).primaryColor;

    return AdaptiveTextSelectionToolbar(
      anchors: selectableRegionState.contextMenuAnchors,
      children: [
        // Copy button
        _buildSelectionButton(
          icon: Icons.copy,
          label: 'Copy',
          color: textColor,
          bgColor: bgColor,
          onPressed: () {
            selectableRegionState.copySelection(SelectionChangedCause.toolbar);
          },
        ),
        // Highlight button - uses clipboard for selected text
        _buildSelectionButton(
          icon: Icons.highlight,
          label: 'Highlight',
          color: primaryColor,
          bgColor: bgColor,
          onPressed: () async {
            // Copy selection to clipboard first
            selectableRegionState.copySelection(SelectionChangedCause.toolbar);
            // Read from clipboard
            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
            final selectedText = clipboardData?.text ?? '';
            if (selectedText.isNotEmpty) {
              controller.addHighlight(selectedText, 0, selectedText.length);
              selectableRegionState.hideToolbar();
              Get.snackbar(
                'Highlighted',
                'Text has been highlighted',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
                backgroundColor: bgColor,
                colorText: textColor,
              );
            }
          },
        ),
        // Note button
        _buildSelectionButton(
          icon: Icons.note_add,
          label: 'Note',
          color: primaryColor,
          bgColor: bgColor,
          onPressed: () async {
            // Copy selection to clipboard first
            selectableRegionState.copySelection(SelectionChangedCause.toolbar);
            // Read from clipboard
            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
            final selectedText = clipboardData?.text ?? '';
            if (selectedText.isNotEmpty) {
              selectableRegionState.hideToolbar();
              _showTextNoteDialog(selectedText, isDark, textColor);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSelectionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextNoteDialog(String selectedText, bool isDark, Color textColor) {
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final noteController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Note',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$selectedText"',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              autofocus: true,
              maxLines: 4,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Enter your note...',
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              final noteText = noteController.text.trim();
              if (noteText.isNotEmpty) {
                // Close dialog first
                Get.back();
                // Then add note (this shows its own snackbar)
                controller.addNote(selectedText, noteText);
              }
            },
            child: Text('Save',
                style: TextStyle(color: Theme.of(Get.context!).primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color textColor) {
    final isSepia = controller.isSepiaMode.value;
    final bgColor = isDark
        ? widget.themeConfig.darkBackgroundColor
        : isSepia
            ? (widget.themeConfig.sepiaBackgroundColor ?? const Color(0xFFF5E6C8))
            : widget.themeConfig.lightBackgroundColor;
    final subtitleColor = isDark ? Colors.white60 : isSepia ? const Color(0xFF8B6957) : Colors.black54;

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Get.back(),
                ),

                // Title
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (controller.currentChapterTitle.value.isNotEmpty)
                        Text(
                          controller.currentChapterTitle.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Action buttons
                // Theme toggle (always visible)
                Obx(() {
                  final isDark = controller.isDarkMode.value;
                  final isSepia = controller.isSepiaMode.value;
                  IconData themeIcon;
                  if (isDark) {
                    themeIcon = Icons.wb_sunny_outlined;
                  } else if (isSepia) {
                    themeIcon = Icons.dark_mode_outlined;
                  } else {
                    themeIcon = Icons.auto_stories_outlined;
                  }
                  return IconButton(
                    icon: Icon(themeIcon, color: textColor),
                    onPressed: controller.toggleReadingTheme,
                    tooltip: 'Toggle theme',
                  );
                }),
                if (controller.featureConfig.enableTableOfContents)
                IconButton(
                  icon: Icon(Icons.list, color: textColor),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  tooltip: 'Table of Contents',
                ),
                if (controller.featureConfig.enableSearch)
                IconButton(
                  icon: Icon(Icons.search, color: textColor),
                  onPressed: () => _showSearchSheet(),
                  tooltip: 'Search',
                ),
                if (controller.featureConfig.enableBookmarks)
                IconButton(
                  icon: Icon(Icons.bookmarks_outlined, color: textColor),
                  onPressed: _showBookmarksSheet,
                  tooltip: 'Bookmarks',
                ),
                if (controller.featureConfig.enableSettings)
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: textColor),
                  onPressed: _showSettingsSheet,
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),

          // Progress bar
          LinearProgressIndicator(
            value: controller.progress.value,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, Color textColor) {
    final isSepia = controller.isSepiaMode.value;
    final bgColor = isDark
        ? widget.themeConfig.darkBackgroundColor
        : isSepia
            ? (widget.themeConfig.sepiaBackgroundColor ?? const Color(0xFFF5E6C8))
            : widget.themeConfig.lightBackgroundColor;
    final subtitleColor = isDark ? Colors.white60 : isSepia ? const Color(0xFF8B6957) : Colors.black54;
    // Use white accent in dark mode for better visibility (matching PDF reader)
    final accentColor = isDark ? Colors.white : isSepia ? const Color(0xFF8B4513) : Theme.of(context).primaryColor;
    final disabledColor = isDark ? Colors.white24 : Colors.black26;

    final canGoPrev = controller.currentChapterIndex.value > 0;
    final canGoNext =
        controller.currentChapterIndex.value < controller.chapters.length - 1;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chapter info (only chapter number)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Text(
              'Chapter ${controller.currentChapterIndex.value + 1} / ${controller.totalChapters.value}',
              style: TextStyle(
                fontSize: 13,
                color: subtitleColor,
              ),
            ),
          ),

          // Chapter slider (in the middle)
          if (controller.totalChapters.value > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: accentColor,
                  inactiveTrackColor: subtitleColor.withValues(alpha: 0.3),
                  thumbColor: accentColor,
                  overlayColor: accentColor.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: controller.currentChapterIndex.value.toDouble(),
                  min: 0,
                  max: (controller.totalChapters.value - 1).toDouble(),
                  divisions: controller.totalChapters.value > 1
                      ? controller.totalChapters.value - 1
                      : 1,
                  onChanged: (value) {
                    controller.goToChapter(value.toInt());
                  },
                ),
              ),
            ),

          // Progress percentage
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${(controller.progress.value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Navigation buttons
          if (controller.featureConfig.enableChapterNavigation ||
              controller.featureConfig.enableBookmarks)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (controller.featureConfig.enableChapterNavigation)
                    TextButton.icon(
                      onPressed:
                          canGoPrev ? controller.goToPreviousChapter : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color: canGoPrev ? accentColor : disabledColor,
                      ),
                      label: Text(
                        'Previous',
                        style: TextStyle(
                          color: canGoPrev ? accentColor : disabledColor,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Bookmark button
                  if (controller.featureConfig.enableBookmarks)
                    IconButton(
                      onPressed: () {
                        if (!controller.isCurrentPositionBookmarked()) {
                          controller.addBookmark();
                        }
                      },
                      icon: Icon(
                        controller.isCurrentPositionBookmarked()
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: controller.isCurrentPositionBookmarked()
                            ? accentColor
                            : textColor,
                      ),
                      tooltip: 'Bookmark',
                    ),

                  if (controller.featureConfig.enableChapterNavigation)
                    TextButton.icon(
                      onPressed: canGoNext ? controller.goToNextChapter : null,
                      icon: Text(
                        'Next',
                        style: TextStyle(
                          color: canGoNext ? accentColor : disabledColor,
                        ),
                      ),
                      label: Icon(
                        Icons.chevron_right,
                        color: canGoNext ? accentColor : disabledColor,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Obx(() {
      final progress = controller.loadingProgress.value;
      final primaryColor = Theme.of(context).primaryColor;

      return Container(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show progress indicator with percentage when downloading
              if (progress > 0 && progress < 1)
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor:
                            isDark ? Colors.white24 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation(primaryColor),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download,
                            size: 24,
                            color: primaryColor,
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                progress > 0 && progress < 1
                    ? 'Downloading EPUB...'
                    : 'Loading EPUB...',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildErrorOverlay(bool isDark) {
    return Container(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to load EPUB',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.error.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => controller.loadEpub(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
