import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart' as epub;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// A simple, lightweight EPUB viewer widget for view-only scenarios.
///
/// This widget provides basic EPUB viewing with chapter navigation,
/// without annotations, bookmarks, or other advanced features.
///
/// Use this for sample previews, simple document viewing, etc.
/// For full book reading experience, use [EpubViewerScreen] instead.
///
/// Usage:
/// ```dart
/// // From file path
/// SimpleEpubViewer.file('/path/to/document.epub')
///
/// // From bytes
/// SimpleEpubViewer.data(epubBytes, title: 'My Book')
/// ```
class SimpleEpubViewer extends StatefulWidget {
  final String? _filePath;
  final Uint8List? _data;
  final String title;
  final Color? backgroundColor;
  final double initialFontSize;

  const SimpleEpubViewer._({
    super.key,
    String? filePath,
    Uint8List? data,
    required this.title,
    this.backgroundColor,
    this.initialFontSize = 16.0,
  })  : _filePath = filePath,
        _data = data;

  /// Create an EPUB viewer from file path
  factory SimpleEpubViewer.file(
    String path, {
    Key? key,
    String title = '',
    Color? backgroundColor,
    double initialFontSize = 16.0,
  }) {
    return SimpleEpubViewer._(
      key: key,
      filePath: path,
      title: title,
      backgroundColor: backgroundColor,
      initialFontSize: initialFontSize,
    );
  }

  /// Create an EPUB viewer from bytes data
  factory SimpleEpubViewer.data(
    Uint8List data, {
    Key? key,
    String title = '',
    Color? backgroundColor,
    double initialFontSize = 16.0,
  }) {
    return SimpleEpubViewer._(
      key: key,
      data: data,
      title: title,
      backgroundColor: backgroundColor,
      initialFontSize: initialFontSize,
    );
  }

  @override
  State<SimpleEpubViewer> createState() => _SimpleEpubViewerState();
}

class _SimpleEpubViewerState extends State<SimpleEpubViewer> {
  epub.EpubBook? _book;
  List<epub.EpubChapter> _chapters = [];
  int _currentChapterIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<int> bytes;
      if (widget._data != null) {
        bytes = widget._data!;
      } else if (widget._filePath != null) {
        final file = File(widget._filePath!);
        bytes = await file.readAsBytes();
      } else {
        throw Exception('No EPUB source provided');
      }

      _book = await epub.EpubReader.readBook(bytes);
      _chapters = _book?.Chapters?.where((c) => c.HtmlContent != null).toList() ?? [];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF1a1a1a) : Colors.white);
    final textColor = isDark ? Colors.white : Colors.black87;

    if (_isLoading) {
      return Container(
        color: bgColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        color: bgColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Failed to load EPUB',
                  style: TextStyle(color: textColor, fontSize: 16)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadEpub,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chapters.isEmpty) {
      return Container(
        color: bgColor,
        child: Center(
          child: Text('No readable content found',
              style: TextStyle(color: textColor)),
        ),
      );
    }

    final chapter = _chapters[_currentChapterIndex];

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Chapter content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: HtmlWidget(
                chapter.HtmlContent ?? '',
                textStyle: TextStyle(
                  fontSize: widget.initialFontSize,
                  color: textColor,
                  height: 1.6,
                ),
              ),
            ),
          ),
          // Bottom navigation
          if (_chapters.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _currentChapterIndex > 0
                        ? () => setState(() => _currentChapterIndex--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                  ),
                  Text(
                    '${_currentChapterIndex + 1} / ${_chapters.length}',
                    style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                  ),
                  TextButton.icon(
                    onPressed: _currentChapterIndex < _chapters.length - 1
                        ? () => setState(() => _currentChapterIndex++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
