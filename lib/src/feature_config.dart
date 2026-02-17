/// Feature flags for enabling/disabling EPUB viewer functionalities.
///
/// All features are enabled by default. Set to `false` to disable.
class EpubViewerFeatureConfig {
  /// Enable/disable bookmarks functionality.
  final bool enableBookmarks;

  /// Enable/disable highlights functionality.
  final bool enableHighlights;

  /// Enable/disable notes functionality.
  final bool enableNotes;

  /// Enable/disable annotations (drawing, position-based notes).
  final bool enableAnnotations;

  /// Enable/disable text search within the book.
  final bool enableSearch;

  /// Enable/disable text selection.
  final bool enableTextSelection;

  /// Enable/disable table of contents drawer.
  final bool enableTableOfContents;

  /// Enable/disable auto-scroll (auto chapter advance).
  final bool enableAutoScroll;

  /// Enable/disable dark mode toggle.
  final bool enableDarkModeToggle;

  /// Enable/disable fullscreen toggle.
  final bool enableFullscreen;

  /// Enable/disable font size adjustment.
  final bool enableFontSizeControl;

  /// Enable/disable font family selection.
  final bool enableFontFamilyControl;

  /// Enable/disable line height adjustment.
  final bool enableLineHeightControl;

  /// Enable/disable margin size adjustment.
  final bool enableMarginControl;

  /// Enable/disable DRM screen protection (screenshot/recording prevention).
  final bool enableScreenProtection;

  /// Enable/disable keep-screen-on option.
  final bool enableKeepScreenOn;

  /// Enable/disable reading session tracking.
  final bool enableSessionTracking;

  /// Enable/disable settings bottom sheet.
  final bool enableSettings;

  /// Enable/disable chapter navigation arrows.
  final bool enableChapterNavigation;

  const EpubViewerFeatureConfig({
    this.enableBookmarks = true,
    this.enableHighlights = true,
    this.enableNotes = true,
    this.enableAnnotations = true,
    this.enableSearch = true,
    this.enableTextSelection = true,
    this.enableTableOfContents = true,
    this.enableAutoScroll = true,
    this.enableDarkModeToggle = true,
    this.enableFullscreen = true,
    this.enableFontSizeControl = true,
    this.enableFontFamilyControl = true,
    this.enableLineHeightControl = true,
    this.enableMarginControl = true,
    this.enableScreenProtection = true,
    this.enableKeepScreenOn = true,
    this.enableSessionTracking = true,
    this.enableSettings = true,
    this.enableChapterNavigation = true,
  });

  /// All features enabled (default).
  static const EpubViewerFeatureConfig allEnabled = EpubViewerFeatureConfig();

  /// Minimal viewer — only reading, no extras.
  static const EpubViewerFeatureConfig minimal = EpubViewerFeatureConfig(
    enableBookmarks: false,
    enableHighlights: false,
    enableNotes: false,
    enableAnnotations: false,
    enableSearch: false,
    enableTextSelection: false,
    enableTableOfContents: false,
    enableAutoScroll: false,
    enableDarkModeToggle: false,
    enableFullscreen: false,
    enableFontSizeControl: false,
    enableFontFamilyControl: false,
    enableLineHeightControl: false,
    enableMarginControl: false,
    enableScreenProtection: false,
    enableKeepScreenOn: false,
    enableSessionTracking: false,
    enableSettings: false,
    enableChapterNavigation: true,
  );

  /// Read-only viewer — reading with navigation and display settings, no editing.
  static const EpubViewerFeatureConfig readOnly = EpubViewerFeatureConfig(
    enableBookmarks: false,
    enableHighlights: false,
    enableNotes: false,
    enableAnnotations: false,
    enableSearch: true,
    enableTextSelection: true,
    enableTableOfContents: true,
    enableAutoScroll: true,
    enableDarkModeToggle: true,
    enableFullscreen: true,
    enableFontSizeControl: true,
    enableFontFamilyControl: true,
    enableLineHeightControl: true,
    enableMarginControl: true,
    enableScreenProtection: false,
    enableKeepScreenOn: true,
    enableSessionTracking: false,
    enableSettings: true,
    enableChapterNavigation: true,
  );
}
