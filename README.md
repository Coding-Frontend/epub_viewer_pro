# epub_viewer_pro

A full-featured EPUB viewer for Flutter with chapter-based navigation, bookmarks, highlights, notes, annotations, dark/light/sepia themes, multi-language Google Fonts support, and DRM protection.

## Features

- 📖 **EPUB parsing** via epubx with HTML rendering (flutter_widget_from_html)
- 🔖 **Bookmarks** — add, remove, sync with server
- 🖍️ **Highlights** — text highlighting with color options
- 📝 **Notes** — inline note annotations
- ✏️ **Annotations** — pen drawing, eraser with undo/redo
- 📑 **Table of Contents** — hierarchical drawer with progress
- 🔍 **Search** — across all chapters
- 🌙 **Dark/Light/Sepia** theme support
- 🔤 **Multi-language fonts** — 25+ language-specific Google Fonts
- ⏩ **Auto-scroll** with configurable interval
- 📊 **Reading progress** — chapter and scroll position persistence
- 🔐 **DRM protection** — screenshot prevention
- 🔒 **Authenticated downloads** — token-based file access
- 📤 **Server sync** — optional bookmark/annotation/session sync via callbacks

## Getting Started

```yaml
dependencies:
  epub_viewer_pro: ^0.0.1
```

## Usage

### Basic

```dart
import 'package:epub_viewer_pro/epub_viewer_pro.dart';

EpubViewerScreen(
  filePath: '/path/to/book.epub',
  title: 'My Book',
);
```

### With Server Sync

```dart
EpubViewerScreen(
  filePath: '/path/to/book.epub',
  title: 'My Book',
  bookId: 123,
  serviceConfig: EpubViewerServiceConfig(
    authToken: 'your-jwt-token',
    isLoggedIn: true,
    onBookmarksSync: (bookId, bookmarks) async { /* sync */ },
    onMessage: (msg, type) { /* show toast */ },
  ),
);
```

## License

MIT License
