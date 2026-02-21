/// Message types for viewer notifications
enum ViewerMessageType {
  success,
  error,
  warning,
  info,
}

/// Callback type for displaying messages (toast/snackbar)
typedef MessageCallback = void Function(String message, ViewerMessageType type);

/// Callback for bookmark sync (EPUB bookmarks include chapter info)
typedef EpubBookmarksSyncCallback = Future<void> Function(
    int bookId, List<Map<String, dynamic>> bookmarks);

/// Callback for loading bookmarks from server
typedef EpubBookmarksLoadCallback = Future<List<Map<String, dynamic>>?> Function(
    int bookId);

/// Callback for highlights sync
typedef HighlightsSyncCallback = Future<void> Function(
    int bookId, List<Map<String, dynamic>> highlights);

/// Callback for notes sync
typedef NotesSyncCallback = Future<void> Function(
    int bookId, List<Map<String, dynamic>> notes);

/// Callback for annotation sync
typedef AnnotationsSyncCallback = Future<Map<String, dynamic>?> Function(
    int bookId, Map<String, dynamic> annotations);

/// Callback for loading annotations from server
typedef AnnotationsLoadCallback = Future<Map<String, dynamic>?> Function(
    int bookId);

/// Callback for reading session start
typedef SessionStartCallback = Future<void> Function(int bookId);

/// Callback for reading session end
typedef SessionEndCallback = Future<void> Function(
    int bookId, int durationSeconds, int currentChapter, int totalChapters);

/// Callback for syncing reading progress
typedef ProgressSyncCallback = Future<void> Function(
    int bookId, double progressPercent, int currentChapter, int totalChapters);

/// Configuration for optional server-side services.
///
/// All callbacks are optional. When not provided, the viewer works
/// fully offline with local storage only.
///
/// Instead of built-in authentication, provide [httpHeaders] for
/// authenticated file downloads and callbacks for data sync.
/// The presence of a callback indicates the feature is enabled.
class EpubViewerServiceConfig {
  /// Custom HTTP headers for file downloads (e.g. Authorization, API keys).
  /// Example: `{'Authorization': 'Bearer your-token', 'X-Api-Key': 'key'}`
  final Map<String, String>? httpHeaders;

  /// Called when bookmarks should be synced to the server.
  final EpubBookmarksSyncCallback? onBookmarksSync;

  /// Called to load bookmarks from the server.
  final EpubBookmarksLoadCallback? onBookmarksLoad;

  /// Called when highlights should be synced to the server.
  final HighlightsSyncCallback? onHighlightsSync;

  /// Called when notes should be synced to the server.
  final NotesSyncCallback? onNotesSync;

  /// Called when annotations should be synced to the server.
  final AnnotationsSyncCallback? onAnnotationsSync;

  /// Called to load annotations from the server.
  final AnnotationsLoadCallback? onAnnotationsLoad;

  /// Called when a reading session starts.
  final SessionStartCallback? onSessionStart;

  /// Called when a reading session ends.
  final SessionEndCallback? onSessionEnd;

  /// Called when reading progress should be synced to the server.
  final ProgressSyncCallback? onProgressSync;

  /// Called to display a message to the user.
  final MessageCallback? onMessage;

  const EpubViewerServiceConfig({
    this.httpHeaders,
    this.onBookmarksSync,
    this.onBookmarksLoad,
    this.onHighlightsSync,
    this.onNotesSync,
    this.onAnnotationsSync,
    this.onAnnotationsLoad,
    this.onSessionStart,
    this.onSessionEnd,
    this.onProgressSync,
    this.onMessage,
  });

  /// A default config with no server sync (offline only).
  static const EpubViewerServiceConfig offline = EpubViewerServiceConfig();
}
