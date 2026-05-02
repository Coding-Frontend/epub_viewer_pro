# epub_viewer_pro

[![pub.dev](https://img.shields.io/pub/v/epub_viewer_pro.svg)](https://pub.dev/packages/epub_viewer_pro)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-green)](https://pub.dev/packages/epub_viewer_pro)
[![Publisher](https://img.shields.io/badge/publisher-codingfrontend.in-blue)](https://pub.dev/publishers/codingfrontend.in)

A full-featured EPUB viewer for Flutter **(Android & iOS)** with chapter-based navigation, bookmarks, highlights, notes, annotations, dark/light/sepia themes, multi-language Google Fonts support, DRM protection, and server sync.

## Platform Support

| Android | iOS |
|:-------:|:---:|
|    ✅    |  ✅  |

## Features

- 📖 **EPUB parsing** via epubx with HTML rendering (flutter_widget_from_html)
- 🔖 **Bookmarks** — add, remove, sync with server
- 📝 **Highlights** — text highlighting with color options
- 📝 **Notes** — attach text notes to highlighted passages
- ✏️ **Annotations** — pen drawing, eraser with undo/redo
- 🔍 **Search** — full-text search across all chapters
- 📒 **Table of Contents** — hierarchical TOC drawer
- 🔤 **Text Selection** — select and copy text
- 🌙 **Dark/Light/Sepia** themes
- 📱 **Multi-language fonts** — 25+ language-specific Google Fonts
- ⏩ **Auto-scroll** with configurable interval
- 🔒 **DRM protection** — screenshot/screen-recording prevention
- ☀️ **Keep screen on** while reading
- 📊 **Session tracking** — reading duration and progress
- 🔗 **Authenticated downloads** via custom HTTP headers
- ☁️ **Server sync** via callbacks (bookmarks, highlights, notes, progress)
- 💾 **Custom storage** — pluggable storage backend

## Getting Started

```yaml
dependencies:
  epub_viewer_pro: ^0.0.2
```

## Basic Usage

```dart
import 'package:epub_viewer_pro/epub_viewer_pro.dart';

// Open from file path
Navigator.push(context, MaterialPageRoute(
  builder: (_) => EpubViewerScreen(
    filePath: '/path/to/book.epub',
    title: 'My Book',
  ),
));

// Open from URL
Navigator.push(context, MaterialPageRoute(
  builder: (_) => EpubViewerScreen(
    fileUrl: 'https://example.com/book.epub',
    title: 'My Book',
  ),
));
```

## Feature Configuration

```dart
EpubViewerScreen(
  filePath: '/path/to/book.epub',
  title: 'My Book',
  bookId: 42,                       // For bookmarks/notes persistence
  bookLanguage: 'ta',               // For font selection (Tamil, Hindi, etc.)
  isSamplePreview: false,           // Limit to sample chapters
  featureConfig: EpubViewerFeatureConfig(
    enableBookmarks: true,
    enableHighlights: true,
    enableNotes: true,
    enableAnnotations: true,
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
    enableSessionTracking: true,
    enableSettings: true,
    enableChapterNavigation: true,
  ),
);
```

## Built-in Presets

```dart
// All features enabled
featureConfig: EpubViewerFeatureConfig.fullFeatures

// View-only (no annotations/bookmarks)
featureConfig: EpubViewerFeatureConfig.readOnly

// Bare minimum (TOC + chapter nav only)
featureConfig: EpubViewerFeatureConfig.minimal
```

## Theme Customization

```dart
themeConfig: EpubViewerThemeConfig(
  primaryColor: Colors.deepPurple,
  lightBackgroundColor: Colors.white,
  darkBackgroundColor: Color(0xFF121212),
  sepiaBackgroundColor: Color(0xFFF5E6C8),
  cardBorderRadius: 12.0,
),
```

## Server Sync

```dart
serviceConfig: EpubViewerServiceConfig(
  // Sync bookmarks with your server
  onBookmarksSync: (bookId, bookmarks) async {
    await myApi.saveBookmarks(bookId, bookmarks);
  },
  onBookmarksLoad: (bookId) async {
    return await myApi.loadBookmarks(bookId);
  },
  // Track reading sessions
  onSessionStart: (bookId) async {
    await myApi.startSession(bookId);
  },
  onSessionEnd: (bookId, durationSeconds, chapter, totalChapters) async {
    await myApi.endSession(bookId, durationSeconds);
  },
  // Authenticated file access
  httpHeaders: {'Authorization': 'Bearer $token'},
),
```