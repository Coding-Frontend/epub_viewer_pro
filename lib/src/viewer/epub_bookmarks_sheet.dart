import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'epub_reader_controller.dart';

/// Bookmarks bottom sheet for EPUB reader
class EpubBookmarksSheet extends GetView<EpubReaderController> {
  const EpubBookmarksSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Obx(() {
        final isDark = controller.isDarkMode.value;
        final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtitleColor = isDark ? Colors.white60 : Colors.black54;
        final dividerColor = isDark ? Colors.white12 : Colors.black12;
        final primaryColor = Theme.of(context).primaryColor;

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Annotations',
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

                // Tab bar
                TabBar(
                  labelColor: primaryColor,
                  unselectedLabelColor: subtitleColor,
                  indicatorColor: primaryColor,
                  dividerColor: dividerColor,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bookmark, size: 18),
                          const SizedBox(width: 4),
                          Text('${controller.bookmarks.length}'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.highlight, size: 18),
                          const SizedBox(width: 4),
                          Text('${controller.highlights.length}'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.note, size: 18),
                          const SizedBox(width: 4),
                          Text('${controller.notes.length}'),
                        ],
                      ),
                    ),
                  ],
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      _BookmarksTab(
                        bookmarks: controller.bookmarks,
                        isDarkMode: isDark,
                        primaryColor: primaryColor,
                        onTap: (bookmark) {
                          controller.goToBookmark(bookmark);
                          Get.back();
                        },
                        onDelete: controller.removeBookmark,
                      ),
                      _HighlightsTab(
                        highlights: controller.highlights,
                        isDarkMode: isDark,
                        primaryColor: primaryColor,
                        onDelete: controller.removeHighlight,
                      ),
                      _NotesTab(
                        notes: controller.notes,
                        isDarkMode: isDark,
                        primaryColor: primaryColor,
                        onDelete: controller.removeNote,
                      ),
                    ],
                  ),
                ),

                // Add bookmark button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isCurrentPositionBookmarked()
                          ? null
                          : () {
                              controller.addBookmark();
                              Get.back();
                            },
                      icon: Icon(
                        controller.isCurrentPositionBookmarked()
                            ? Icons.bookmark
                            : Icons.bookmark_add,
                      ),
                      label: Text(
                        controller.isCurrentPositionBookmarked()
                            ? 'Position Bookmarked'
                            : 'Add Bookmark',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            isDark ? Colors.white12 : Colors.grey[200],
                        disabledForegroundColor: subtitleColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _BookmarksTab extends StatelessWidget {
  final List<BookmarkInfo> bookmarks;
  final bool isDarkMode;
  final Color primaryColor;
  final Function(BookmarkInfo) onTap;
  final Function(int) onDelete;

  const _BookmarksTab({
    required this.bookmarks,
    required this.isDarkMode,
    required this.primaryColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return _buildEmptyState(
        Icons.bookmark_border,
        'No bookmarks yet',
        'Add bookmarks to save your reading position',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => Divider(
        color: isDarkMode ? Colors.white12 : Colors.black12,
        height: 1,
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return _AnnotationItem(
          icon: Icons.bookmark,
          title: bookmark.chapterTitle,
          subtitle: 'Chapter ${bookmark.chapterIndex + 1}',
          timestamp: bookmark.createdAt,
          isDarkMode: isDarkMode,
          primaryColor: primaryColor,
          onTap: () => onTap(bookmark),
          onDelete: () => onDelete(index),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: subtitleColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightsTab extends StatelessWidget {
  final List<HighlightInfo> highlights;
  final bool isDarkMode;
  final Color primaryColor;
  final Function(int) onDelete;

  const _HighlightsTab({
    required this.highlights,
    required this.isDarkMode,
    required this.primaryColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return _buildEmptyState(
        Icons.highlight,
        'No highlights yet',
        'Select text to add highlights',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: highlights.length,
      separatorBuilder: (_, __) => Divider(
        color: isDarkMode ? Colors.white12 : Colors.black12,
        height: 1,
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final highlight = highlights[index];
        return _AnnotationItem(
          icon: Icons.highlight,
          title: highlight.text,
          subtitle: 'Chapter ${highlight.chapterIndex + 1}',
          timestamp: highlight.createdAt,
          isDarkMode: isDarkMode,
          primaryColor: Color(highlight.color),
          onTap: () {},
          onDelete: () => onDelete(index),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: subtitleColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final List<NoteInfo> notes;
  final bool isDarkMode;
  final Color primaryColor;
  final Function(int) onDelete;

  const _NotesTab({
    required this.notes,
    required this.isDarkMode,
    required this.primaryColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return _buildEmptyState(
        Icons.note,
        'No notes yet',
        'Add notes to remember important passages',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notes.length,
      separatorBuilder: (_, __) => Divider(
        color: isDarkMode ? Colors.white12 : Colors.black12,
        height: 1,
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _NoteItem(
          note: note,
          isDarkMode: isDarkMode,
          primaryColor: primaryColor,
          onDelete: () => onDelete(index),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: subtitleColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnotationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final bool isDarkMode;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AnnotationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isDarkMode,
    required this.primaryColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$subtitle • ${_formatDate(timestamp)}',
        style: TextStyle(fontSize: 12, color: subtitleColor),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        color: subtitleColor,
        iconSize: 20,
        onPressed: onDelete,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NoteItem extends StatelessWidget {
  final NoteInfo note;
  final bool isDarkMode;
  final Color primaryColor;
  final VoidCallback onDelete;

  const _NoteItem({
    required this.note,
    required this.isDarkMode,
    required this.primaryColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.format_quote, color: primaryColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.selectedText,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: subtitleColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: subtitleColor,
                iconSize: 18,
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              note.noteText,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
